#
# BioPerl module for Bio::SearchIO::SearchResultEventBuilder
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::SearchIO::SearchResultEventBuilder - Event Handler for SearchIO events.

=head1 SYNOPSIS

# Do not use this object directly, this object is part of the SearchIO
# event based parsing system.

=head1 DESCRIPTION

This object handles Search Events generated by the SearchIO classes
and build appropriate Bio::Search::* objects from them.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/bioperl-live/issues

=head1 AUTHOR - Jason Stajich

Email jason-at-bioperl.org

=head1 CONTRIBUTORS

Sendu Bala, bix@sendu.me.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::SearchIO::SearchResultEventBuilder;
$Bio::SearchIO::SearchResultEventBuilder::VERSION = '1.7.7';
use strict;

use Bio::Factory::ObjectFactory;

use base qw(Bio::Root::Root Bio::SearchIO::EventHandlerI);

use vars qw($DEFAULT_INCLUSION_THRESHOLD
            $MAX_HSP_OVERLAP
);

# e-value threshold for inclusion in the PSI-BLAST score matrix model (blastpgp)
# NOTE: Executing `blastpgp -` incorrectly reports that the default is 0.005.
#       (version 2.2.2 [Jan-08-2002])
$DEFAULT_INCLUSION_THRESHOLD = 0.001;

$MAX_HSP_OVERLAP  = 2;  # Used when tiling multiple HSPs.

=head2 new

 Title   : new
 Usage   : my $obj = Bio::SearchIO::SearchResultEventBuilder->new();
 Function: Builds a new Bio::SearchIO::SearchResultEventBuilder object
 Returns : Bio::SearchIO::SearchResultEventBuilder
 Args    : -hsp_factory    => Bio::Factory::ObjectFactoryI
           -hit_factory    => Bio::Factory::ObjectFactoryI
           -result_factory => Bio::Factory::ObjectFactoryI
           -inclusion_threshold => e-value threshold for inclusion in the
                                   PSI-BLAST score matrix model (blastpgp)
           -signif      => float or scientific notation number to be used
                           as a P- or Expect value cutoff
           -score       => integer or scientific notation number to be used
                           as a blast score value cutoff
           -bits        => integer or scientific notation number to be used
                           as a bit score value cutoff
           -hit_filter  => reference to a function to be used for
                           filtering hits based on arbitrary criteria.

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub new {
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    my ($resultF, $hitF, $hspF) =
        $self->_rearrange([qw(RESULT_FACTORY
                              HIT_FACTORY
                              HSP_FACTORY)],@args);
    $self->_init_parse_params(@args);

    $self->register_factory('result', $resultF ||
                            Bio::Factory::ObjectFactory->new(
                                -type      => 'Bio::Search::Result::GenericResult',
                                -interface => 'Bio::Search::Result::ResultI'));

    $self->register_factory('hit', $hitF ||
                            Bio::Factory::ObjectFactory->new(
                                -type      => 'Bio::Search::Hit::GenericHit',
                                -interface => 'Bio::Search::Hit::HitI'));

    $self->register_factory('hsp', $hspF ||
                            Bio::Factory::ObjectFactory->new(
                                -type      => 'Bio::Search::HSP::GenericHSP',
                                -interface => 'Bio::Search::HSP::HSPI'));

    return $self;
}

# Initializes parameters used during parsing of reports.
sub _init_parse_params {

    my ($self, @args) = @_;
    # -FILT_FUNC has been replaced by -HIT_FILTER.
    # Leaving -FILT_FUNC in place for backward compatibility
    my($ithresh, $signif, $score, $bits, $hit_filter, $filt_func) =
           $self->_rearrange([qw(INCLUSION_THRESHOLD SIGNIF SCORE BITS
                                 HIT_FILTER FILT_FUNC
                                )], @args);

    $self->inclusion_threshold( defined($ithresh) ? $ithresh : $DEFAULT_INCLUSION_THRESHOLD);
    my $hit_filt = $hit_filter || $filt_func;
    defined $hit_filter && $self->hit_filter($hit_filt);
    defined $signif     && $self->max_significance($signif);
    defined $score      && $self->min_score($score);
    defined $bits       && $self->min_bits($bits);
}

=head2 will_handle

 Title   : will_handle
 Usage   : if( $handler->will_handle($event_type) ) { ... }
 Function: Tests if this event builder knows how to process a specific event
 Returns : boolean
 Args    : event type name

=cut

sub will_handle{
   my ($self,$type) = @_;
   # these are the events we recognize
   return ( $type eq 'hsp' || $type eq 'hit' || $type eq 'result' );
}

=head2 SAX methods

=cut

=head2 start_result

 Title   : start_result
 Usage   : $handler->start_result($resulttype)
 Function: Begins a result event cycle
 Returns : none
 Args    : Type of Report

=cut

sub start_result {
   my ($self,$type) = @_;
   $self->{'_resulttype'} = $type;
   $self->{'_hits'} = [];
   $self->{'_hsps'} = [];
   $self->{'_hitcount'} = 0;
   return;
}

=head2 end_result

 Title   : end_result
 Usage   : my @results = $parser->end_result
 Function: Finishes a result handler cycle
 Returns : A Bio::Search::Result::ResultI
 Args    : none

=cut

# this is overridden by IteratedSearchResultEventBuilder
# so keep that in mind when debugging

sub end_result {
    my ($self,$type,$data) = @_;

    if( defined $data->{'runid'} &&
        $data->{'runid'} !~ /^\s+$/ ) {

        if( $data->{'runid'} !~ /^lcl\|/) {
            $data->{"RESULT-query_name"} = $data->{'runid'};
        } else {
            ($data->{"RESULT-query_name"},
             $data->{"RESULT-query_description"}) =
                split(/\s+/,$data->{"RESULT-query_description"},2);
        }

        if( my @a = split(/\|/,$data->{'RESULT-query_name'}) ) {
            my $acc = pop @a ; # this is for accession |1234|gb|AAABB1.1|AAABB1
            # this is for |123|gb|ABC1.1|
            $acc = pop @a if( ! defined $acc || $acc =~ /^\s+$/);
            $data->{"RESULT-query_accession"}= $acc;
        }
        delete $data->{'runid'};
    }
    my %args = map { my $v = $data->{$_}; s/RESULT//; ($_ => $v); }
               grep { /^RESULT/ } keys %{$data};

    $args{'-algorithm'} =  uc(   $args{'-algorithm_name'}
                              || $data->{'RESULT-algorithm_name'}
                              || $type);
    ($self->isa('Bio::SearchIO::IteratedSearchResultEventBuilder')) ?
          ( $args{'-iterations'} = $self->{'_iterations'} )
        : ( $args{'-hits'}       = $self->{'_hits'} );

    my $result = $self->factory('result')->create_object(%args);
    $result->hit_factory($self->factory('hit'));

    ($self->isa('Bio::SearchIO::IteratedSearchResultEventBuilder')) ?
          ( $self->{'_iterations'} = [] )
        : ( $self->{'_hits'}       = [] );

    return $result;
}

=head2 start_hsp

 Title   : start_hsp
 Usage   : $handler->start_hsp($name,$data)
 Function: Begins processing a HSP event
 Returns : none
 Args    : type of element
           associated data (hashref)

=cut

sub start_hsp {
    my ($self,@args) = @_;
    return;
}

=head2 end_hsp

 Title   : end_hsp
 Usage   : $handler->end_hsp()
 Function: Finish processing a HSP event
 Returns : none
 Args    : type of event and associated hashref


=cut

sub end_hsp {
    my ($self,$type,$data) = @_;

    if( defined $data->{'runid'} &&
        $data->{'runid'} !~ /^\s+$/ ) {

        if( $data->{'runid'} !~ /^lcl\|/) {
            $data->{"RESULT-query_name"}= $data->{'runid'};
        } else {
            ($data->{"RESULT-query_name"},
             $data->{"RESULT-query_description"}) =
                 split(/\s+/,$data->{"RESULT-query_description"},2);
        }

        if( my @a = split(/\|/,$data->{'RESULT-query_name'}) ) {
            my $acc = pop @a ; # this is for accession |1234|gb|AAABB1.1|AAABB1
            # this is for |123|gb|ABC1.1|
            $acc = pop @a if( ! defined $acc || $acc =~ /^\s+$/);
            $data->{"RESULT-query_accession"}= $acc;
        }
        delete $data->{'runid'};
    }

    # this code is to deal with the fact that Blast XML data
    # always has start < end and one has to infer strandedness
    # from the frame which is a problem for the Search::HSP object
    # which expect to be able to infer strand from the order of
    # of the begin/end of the query and hit coordinates
    if( defined $data->{'HSP-query_frame'} && # this is here to protect from undefs
        (( $data->{'HSP-query_frame'} < 0 &&
           $data->{'HSP-query_start'} < $data->{'HSP-query_end'} ) ||
         $data->{'HSP-query_frame'} > 0 &&
         ( $data->{'HSP-query_start'} > $data->{'HSP-query_end'} ) )
        )
    {
        # swap
        ($data->{'HSP-query_start'},
         $data->{'HSP-query_end'}) = ($data->{'HSP-query_end'},
                                      $data->{'HSP-query_start'});
    }
    if( defined $data->{'HSP-hit_frame'} && # this is here to protect from undefs
        ((defined $data->{'HSP-hit_frame'} && $data->{'HSP-hit_frame'} < 0 &&
          $data->{'HSP-hit_start'} < $data->{'HSP-hit_end'} ) ||
         defined $data->{'HSP-hit_frame'} && $data->{'HSP-hit_frame'} > 0 &&
         ( $data->{'HSP-hit_start'} > $data->{'HSP-hit_end'} ) )
        )
    {
        # swap
        ($data->{'HSP-hit_start'},
         $data->{'HSP-hit_end'}) = ($data->{'HSP-hit_end'},
                                    $data->{'HSP-hit_start'});
    }
    $data->{'HSP-query_frame'} ||= 0;
    $data->{'HSP-hit_frame'} ||= 0;
    # handle Blast 2.1.2 which did not support data member: hsp_align-len
    $data->{'HSP-query_length'} ||= $data->{'RESULT-query_length'};
    $data->{'HSP-hit_length'}   ||= $data->{'HIT-length'};

    # If undefined lengths, calculate from alignment without gaps and separators
    if (not defined $data->{'HSP-query_length'}) {
        if (my $hsp_qry_seq = $data->{'HSP-query_seq'}) {
            $hsp_qry_seq =~ s/[-\.]//g;
            $data->{'HSP-query_length'} = length $hsp_qry_seq;
        }
        else {
            $data->{'HSP-query_length'} = 0;
        }
    }
    if (not defined $data->{'HSP-hit_length'}) {
        if (my $hsp_hit_seq = $data->{'HSP-hit_seq'}) {
            $hsp_hit_seq =~ s/[-\.]//g;
            $data->{'HSP-hit_length'} = length $hsp_hit_seq;
        }
        else {
            $data->{'HSP-hit_length'} = 0;
        }
    }
    $data->{'HSP-hsp_length'}   ||= length ($data->{'HSP-homology_seq'} || '');

    my %args = map { my $v = $data->{$_}; s/HSP//; ($_ => $v) }
               grep { /^HSP/ } keys %{$data};

    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} ||
                               $data->{'RESULT-algorithm_name'} || $type);
    # copy this over from result
    $args{'-query_name'} = $data->{'RESULT-query_name'};
    $args{'-hit_name'} = $data->{'HIT-name'};
    my ($rank) = scalar @{$self->{'_hsps'} || []} + 1;
    $args{'-rank'} = $rank;

    $args{'-hit_desc'} = $data->{'HIT-description'};
    $args{'-query_desc'} = $data->{'RESULT-query_description'};

    my $bits = $args{'-bits'};
    my $hsp = \%args;
    push @{$self->{'_hsps'}}, $hsp;

    return $hsp;
}

=head2 start_hit

 Title   : start_hit
 Usage   : $handler->start_hit()
 Function: Starts a Hit event cycle
 Returns : none
 Args    : type of event and associated hashref

=cut

sub start_hit{
    my ($self,$type) = @_;
    $self->{'_hsps'} = [];
    return;
}

=head2 end_hit

 Title   : end_hit
 Usage   : $handler->end_hit()
 Function: Ends a Hit event cycle
 Returns : Bio::Search::Hit::HitI object
 Args    : type of event and associated hashref

=cut

sub end_hit{
    my ($self,$type,$data) = @_;

    # Skip process unless there is HSP data or Hit Significance (e.g. a bl2seq with no similarity
    # gives a hit with the subject, but shows a "no hits found" message instead
    # of the alignment data and don't have a significance value).
    # This way, we avoid false positives
    my @hsp_data = grep { /^HSP/ } keys %{$data};
    return unless (scalar @hsp_data > 0 or exists $data->{'HIT-significance'});

    my %args = map { my $v = $data->{$_}; s/HIT//; ($_ => $v); } grep { /^HIT/ } keys %{$data};

    # I hate special cases, but this is here because NCBI BLAST XML
    # doesn't play nice and is undergoing mutation -jason
    if(exists $args{'-name'} && $args{'-name'} =~ /BL_ORD_ID/ ) {
        ($args{'-name'}, $args{'-description'}) = split(/\s+/,$args{'-description'},2);
    }
    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} ||
                               $data->{'RESULT-algorithm_name'} || $type);
    $args{'-hsps'}      = $self->{'_hsps'};
    $args{'-query_len'} =  $data->{'RESULT-query_length'};
    $args{'-rank'}      = $self->{'_hitcount'} + 1;
    unless( defined $args{'-significance'} ) {
        if( defined $args{'-hsps'} &&
            $args{'-hsps'}->[0] ) {
            # use pvalue if present (WU-BLAST), otherwise evalue (NCBI BLAST)
            $args{'-significance'} = $args{'-hsps'}->[0]->{'-pvalue'} || $args{'-hsps'}->[0]->{'-evalue'};
        }
    }
    my $hit = \%args;
    $hit->{'-hsp_factory'} = $self->factory('hsp');
    $self->_add_hit($hit);
    $self->{'_hsps'} = [];
    return $hit;
}

# Title   : _add_hit (private function for internal use only)
# Purpose : Applies hit filtering and store it if it passes filtering.
# Argument: Bio::Search::Hit::HitI object

sub _add_hit {
    my ($self, $hit) = @_;
    my $hit_signif   = $hit->{-significance};

    # Test significance using custom function (if supplied)
    my $add_hit = 1;

    my $hit_filter = $self->{'_hit_filter'};
    if($hit_filter) {
        # since &hit_filter is out of our control and would expect a HitI object,
        # we're forced to make one for it
        $hit     = $self->factory('hit')->create_object(%{$hit});
        $add_hit = 0 unless &$hit_filter($hit);
    }
    else {
        if($self->{'_confirm_significance'}) {
            $add_hit = 0 unless $hit_signif <= $self->{'_max_significance'};
        }
        if($self->{'_confirm_score'}) {
            my $hit_score = $hit->{-score} || $hit->{-hsps}->[0]->{-score};
            $add_hit = 0 unless $hit_score >= $self->{'_min_score'};
        }
        if($self->{'_confirm_bits'}) {
            my $hit_bits = $hit->{-bits} || $hit->{-hsps}->[0]->{-bits} || 0;
            $add_hit = 0 unless $hit_bits >= $self->{'_min_bits'};
        }
    }

    $add_hit && push @{$self->{'_hits'}}, $hit;;
    $self->{'_hitcount'} = scalar @{$self->{'_hits'}};
}

=head2 Factory methods

=cut

=head2 register_factory

 Title   : register_factory
 Usage   : $handler->register_factory('TYPE',$factory);
 Function: Register a specific factory for a object type class
 Returns : none
 Args    : string representing the class and
           Bio::Factory::ObjectFactoryI

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub register_factory{
   my ($self, $type,$f) = @_;
   if( ! defined $f || ! ref($f) ||
       ! $f->isa('Bio::Factory::ObjectFactoryI') ) {
       $self->throw("Cannot set factory to value $f".ref($f)."\n");
   }
   $self->{'_factories'}->{lc($type)} = $f;
}

=head2 factory

 Title   : factory
 Usage   : my $f = $handler->factory('TYPE');
 Function: Retrieves the associated factory for requested 'TYPE'
 Returns : a Bio::Factory::ObjectFactoryI
 Throws  : Bio::Root::BadParameter if none registered for the supplied type
 Args    : name of factory class to retrieve

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub factory{
   my ($self,$type) = @_;
   return $self->{'_factories'}->{lc($type)} ||
       $self->throw(-class=>'Bio::Root::BadParameter',
                    -text=>"No factory registered for $type");
}

=head2 inclusion_threshold

See L<Bio::SearchIO::blast::inclusion_threshold>.

=cut

sub inclusion_threshold {
    my $self = shift;
    return $self->{'_inclusion_threshold'} = shift if @_;
    return $self->{'_inclusion_threshold'};
}

=head2 max_significance

 Usage     : $obj->max_significance();
 Purpose   : Set/Get the P or Expect value used as significance screening cutoff.
             This is the value of the -signif parameter supplied to new().
             Hits with P or E-value at HIT level above this are skipped.
 Returns   : Scientific notation number with this format: 1.0e-05.
 Argument  : Number (sci notation, float, integer) (when setting)
 Throws    : Bio::Root::BadParameter exception if the supplied argument is
           : not a valid number.
 Comments  : Screening of significant hits uses the data provided on the
           : description line. For NCBI BLAST1 and WU-BLAST, this data
           : is P-value. for NCBI BLAST2 it is an Expect value.

=cut

sub max_significance {
    my $self = shift;
    if (@_) {
        my $sig = shift;
        if( $sig =~ /[^\d.e-]/ or $sig <= 0) {
            $self->throw(-class => 'Bio::Root::BadParameter',
                         -text  => "Invalid significance value: $sig\n"
                                 . "Must be a number greater than zero.",
                         -value => $sig);
        }
        $self->{'_confirm_significance'} = 1;
        $self->{'_max_significance'}     = $sig;
    }
    sprintf "%.1e", $self->{'_max_significance'};
}


=head2 signif

Synonym for L<max_significance()|max_significance>

=cut

sub signif { shift->max_significance }

=head2 min_score

 Usage     : $obj->min_score();
 Purpose   : Gets the Blast score used as screening cutoff.
             This is the value of the -score parameter supplied to new().
             Hits with scores at HIT level below this are skipped.
 Returns   : Integer (or undef if not set)
 Argument  : Integer (when setting)
 Throws    : Bio::Root::BadParameter exception if the supplied argument is
           : not a valid number.
 Comments  : Screening of significant hits uses the data provided on the
           : description line.

=cut

sub min_score {
    my $self = shift;
    if (@_) {
        my $score = shift;
        if( $score =~ /[^\de+]/ or $score <= 0) {
            $self->throw(-class => 'Bio::Root::BadParameter',
                         -text  => "Invalid score value: $score\n"
                                 . "Must be an integer greater than zero.",
                        -value  => $score);
        }
        $self->{'_confirm_score'} = 1;
        $self->{'_min_score'}     = $score;
    }
    return $self->{'_min_score'};
}

=head2 min_bits

 Usage     : $obj->min_bits();
 Purpose   : Gets the Blast bit score used as screening cutoff.
             This is the value of the -bits parameter supplied to new().
             Hits with bits score at HIT level below this are skipped.
 Returns   : Integer (or undef if not set)
 Argument  : Integer (when setting)
 Throws    : Bio::Root::BadParameter exception if the supplied argument is
           : not a valid number.
 Comments  : Screening of significant hits uses the data provided on the
           : description line.

=cut

sub min_bits {
    my $self = shift;
    if (@_) {
        my $bits = shift;
        if( $bits =~ /[^\de+]/ or $bits <= 0) {
            $self->throw(-class => 'Bio::Root::BadParameter',
                         -text  => "Invalid bits value: $bits\n"
                                 . "Must be an integer greater than zero.",
                        -value  => $bits);
        }
        $self->{'_confirm_bits'} = 1;
        $self->{'_min_bits'}     = $bits;
    }
    return $self->{'_min_bits'};
}

=head2 hit_filter

 Usage     : $obj->hit_filter();
 Purpose   : Set/Get a function reference used for filtering out hits.
             This is the value of the -hit_filter parameter supplied to new().
             Hits that fail to pass the filter at HIT level are skipped.
 Returns   : Function ref (or undef if not set)
 Argument  : Function ref (when setting)
 Throws    : Bio::Root::BadParameter exception if the supplied argument is
           : not a function reference.

=cut

sub hit_filter {
    my $self = shift;
    if (@_) {
        my $func = shift;
        if(not ref $func eq 'CODE') {
            $self->throw(-class => 'Bio::Root::BadParameter',
                         -text  => "Not a function reference: $func\n"
                                 . "The -hit_filter parameter must be function reference.",
                         -value => $func);
        }
        $self->{'_hit_filter'} = $func;
    }
    return $self->{'_hit_filter'};
}

1;
