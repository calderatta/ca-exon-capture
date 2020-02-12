#!/home/users/cli/bin/perl

use Getopt::Long;
use warnings;
use strict;
use Bio::AlignIO;
use Bio::Align::DNAStatistics;
no warnings "experimental::smartmatch";

my ($dir, $same, $help);
my $thre_c = 0.002; # 2 sequences will be recognized as contaminating each other if their p-distance is lower than this value
my $conserve_trsd = 0.002; # if pdistance among all pairs of sequences are lower than this value, this loci will skip the contamination check
my $cov_trsd = 0.8; # minimum coverage required for 2 sequences to be deemed as contaminating each other
my $contaminated_trsd = 50; # minimum percentage of contaminated pair to deem pair of taxon as contaminating each other
my $all_cnt_trsd = 100; # minimum number of existing times of a pair of taxa required 
my $contaminated_stat = "contamination_stat.txt"; # summary of detected contamination 

my @ARGVoptions = @ARGV;

my $opt = GetOptions( 'indir:s', \$dir,
                      'same:s', \$same,
                      'contamination_stat:s', \$contaminated_stat,
                      'ct_limit:s', \$thre_c,
                      'conserve_pdis', \$conserve_trsd,
                      'help|h!', \$help) or die "\nERROR: Found unknown options. Use -h or --help for more information on usage\n\n";

# print help if no options or -h is specified
if ((@ARGVoptions == 0)||($help)) {
usage();
}

# check missing options
my @essential = qw/indir same/;
check_option(\@essential, \@ARGVoptions);

# load file for samples with same or quite similar sequences
my (@same, %same);
my $count = 0;
open SAME, $same or die "\nERROR: Cannot find file of closely related taxa group \"$same\", please check --same ($!)\n\n";
while (my $line = <SAME>) {
my @line = $line =~ /(\S+)/g;
next if (@line == 0);
push @same, \@line; # push close taxa group to a element
	foreach (@line) {
	$same{$_} = $count; # record the order of element of each taxon
	}
$count++;
}
close SAME;

# die if there's only one defined group
if ($count <= 1) {
die "\nERROR: at least 2 lines are required in the $same\n\n";
}

# get infile name
opendir DIR, $dir or die "\nERROR: Cannot find input directory \"$dir\", please check --indir ($!)\n\n";
my @infile = grep {$_ !~ /^\./} readdir DIR;
@infile = grep {$_ =~ /fa$|fas$|fasta$/i} @infile;
closedir DIR;

my $all_loci_num = @infile;

my $dir_copy = "${dir}_copy";
mkdir $dir_copy;

my %contaminated_matrix;
LOOP: while (my $infile = shift @infile) {

	# read sequences from file
	my $path = "$dir/$infile";
	my ($seqhash, $input_order, $aln_len) = readfas($path);
	
	# get the sequence number, skip if it's too low
	my $taxa_num = @$input_order;
	if ($taxa_num <= 2) {
	print STDERR "WARNING: At least 2 taxa are required. There are only $taxa_num in $path. Skip this file\n";
	next LOOP;
	}
	
	if ($aln_len eq "na") {
	print STDERR "WARNING: Length of sequences in $path are not the same. It may be not aligned. Skip this file\n";
	next LOOP;
	}
		
	# save %$seqhash to another hash
	my %seqh = %$seqhash;
	
	my $copy_path = "$dir_copy/$infile";
	open COPY_FAS, ">$copy_path";
	foreach my $taxon (@$input_order) {
	print COPY_FAS ">$taxon\n$seqh{$taxon}\n";
	}
	close COPY_FAS;
	
	my $stats = Bio::Align::DNAStatistics->new();
	$stats->verbose(-1);

	my $alignin = Bio::AlignIO->new(-format => 'fasta',
								    -file   => $copy_path);
						
	my $aln = $alignin->next_aln;
	my $Uncorrected_matrix = $stats->distance(-align => $aln, 
								              -method => 'Uncorrected');
		
	# save the order of each taxon
	my %names_order;
	my @names_order = @{$Uncorrected_matrix->{_names}};
	foreach (0..(@names_order-1)) {
	$names_order{$names_order[$_]} = $_;
	}

	# extract the taxa of close taxa group which occur in current gene
	my @same_infile;
	my $none_cnt = 0;
	foreach my $same (@same) {
	my @cur = grep {$_ ~~ @$same} @names_order;
	$none_cnt++ if (@cur == 0);
	push @same_infile, \@cur;
	}

	next if ((@same-$none_cnt) <= 1); # skip if number of extracted group is too low
	
	# pdis value matrix
	my @matrix = @{$Uncorrected_matrix->{_values}};
	
	# save p-distance matrix into @matrix, and find pair of contamination
	my %contaminated_candidate;
	
	my $non_conserve_block = 0;
	my %taxa_pair;
	for (my $row = 0; $row < (@matrix-1); $row++) {
	my @row_value = @{$matrix[$row]};
	my $row_name = $names_order[$row];
	
		for (my $col = $row+1; $col < @row_value; $col++) {
			my $col_name = $names_order[$col];
			my $pdis = $row_value[$col];
			
			$taxa_pair{"$row_name\|$col_name"} = "";
			if ($pdis <= $thre_c) { # if find a pair of contamination
				if ((exists $same{$row_name})&&(exists $same{$col_name})) {
				$contaminated_candidate{"$row_name\|$col_name"} = "" if ($same{$row_name} != $same{$col_name}); # if two sample lies in different closely related taxa group
				}
			}
			
			if ($pdis > $conserve_trsd) { 
			$non_conserve_block++;
			}
		}
	}
	
	# skip if alignment is too conserve
	if ($non_conserve_block) {
		foreach my $taxa_pair (sort keys %taxa_pair) {
		$contaminated_matrix{$taxa_pair}->{all_cnt}++; # record the occurence of this taxa pair
		}
	} else {
	next;
	}

	# determine the source and contaminated sequence base on their p-distance to its own group
	foreach my $contaminated_candidate (sort keys %contaminated_candidate) {
		my ($row_name, $col_name) = $contaminated_candidate =~ /(\S+)\|(\S+)/;
	
		my ($rowcov, $colcov) = coverage($seqh{$row_name}, $seqh{$col_name});
		if (($rowcov >= $cov_trsd) && ($colcov >= $cov_trsd)) { # deem this pair of sequence as contamination pair if both of their coverage is qualified 
		$contaminated_matrix{"$row_name\|$col_name"}->{contaminated_cnt}++; # record a time of contamination of this pair
		
			# determine the source and contaminated sequence
			my @same_row = @{$same_infile[$same{$row_name}]}; # get closely related group of row taxon
			my @same_col = @{$same_infile[$same{$col_name}]}; # get closely related group of col taxon
			
			my @same_row_exclude = grep {$_ ne $row_name} @same_row; # exclude contaminated or source taxon
			my @same_col_exclude = grep {$_ ne $col_name} @same_col;
			
			if ((@same_row_exclude >= 1)&&(@same_col_exclude >= 1)) { # if contaminated or source taxon is not the only remain taxa
			my $row_self_pdis = sprintf("%.2f", ave_pdis([$row_name], \@same_row_exclude, \@matrix, \%names_order)); # calculate the pdis to its own group
			my $col_self_pdis = sprintf("%.2f", ave_pdis([$col_name], \@same_col_exclude, \@matrix, \%names_order));
			
				if ($row_self_pdis > $col_self_pdis) { # if row taxon is further away from its group 
				$contaminated_matrix{"$row_name\|$col_name"}->{row_contaminated}++; # row taxon is contaminated
				} elsif ($col_self_pdis > $row_self_pdis) { # if col taxon is further away from its group 
				$contaminated_matrix{"$row_name\|$col_name"}->{col_contaminated}++; # col taxon is contaminated
				}
			}
		}
	}
}

# find the percentage of contaminated pair among all loci
open CONTAMINATED_STAT, ">$contaminated_stat" or die "\nERROR: Cannot write table of contamination status \"$contaminated_stat\", please check --contamination_stat($!)\n\n";
print CONTAMINATED_STAT "Contaminated sample\tContaminating source\tPercentage of contaminated pair(\%)\tContaminated pair\tAll pair\tContaminating source->Contaminated sample\tContaminated Sample->Contaminating Source\n";
foreach my $contaminated_pair (sort keys %contaminated_matrix) {
my ($row_name, $col_name) = $contaminated_pair =~ /(\S+)\|(\S+)/;
my $all_cnt = $contaminated_matrix{"$row_name\|$col_name"}->{all_cnt}; # occurence of this pair among all loci
my $contaminated_cnt = $contaminated_matrix{"$row_name\|$col_name"}->{contaminated_cnt}; # occurence of contamination of this pair among all loci
my $row_contaminated = $contaminated_matrix{"$row_name\|$col_name"}->{row_contaminated}; # times of row taxa contaminated
my $col_contaminated = $contaminated_matrix{"$row_name\|$col_name"}->{col_contaminated}; # times of col taxa contaminated

# 0 if it not exist
$contaminated_cnt = 0 if (! $contaminated_cnt);
$row_contaminated = 0 if (! $row_contaminated);
$col_contaminated = 0 if (! $col_contaminated);

my $contaminated_pct = sprintf("%.2f", $contaminated_cnt/$all_cnt*100); # percentage of contamination

	if (($contaminated_pct >= $contaminated_trsd)&&($all_cnt >= $all_cnt_trsd)) {
	say STDOUT "Potential contamination are detected between $row_name and $col_name ($contaminated_pct\% of contamination).\n$contaminated_cnt times of contamination are detected between this pair of taxa.\nThis pair of taxa occurred $all_cnt times among all loci ($all_loci_num).\n";
	}

	if ($row_contaminated > $col_contaminated) { # if times of row taxon is contaminated more time than col taxon, then col is the source and row is contaminated
	print CONTAMINATED_STAT "$row_name\t$col_name\t$contaminated_pct\t$contaminated_cnt\t$all_cnt\t$row_contaminated\t$col_contaminated\n";
	} elsif ($row_contaminated < $col_contaminated) { # vice versa
	print CONTAMINATED_STAT "$col_name\t$row_name\t$contaminated_pct\t$contaminated_cnt\t$all_cnt\t$col_contaminated\t$row_contaminated\n";
	} elsif (($row_contaminated == $col_contaminated)&&($contaminated_cnt > 0)){ # cannot determine if they are the same
	print CONTAMINATED_STAT "${row_name}\?\t${col_name}\?\t$contaminated_pct\t$contaminated_cnt\t$all_cnt\t$row_contaminated\t$col_contaminated\n";		
	}

}
close CONTAMINATED_STAT;

`rm -rf $dir_copy`;

##################################################
# subroutine
##################################################

# subroutine to calculate the coverage between 2 sequences
sub coverage {
    my($string1, $string2) = @_;

    # we assume that the strings have the same length
    my($length) = length($string1);
    my($position);
    my($count) = 0;
    my($lengthcount) = 0;

    for ($position=0; $position < $length ; ++$position) {
    ++$lengthcount if ( (substr($string1,$position,1) =~ /[A-Z?*]{1}/) && (substr($string2,$position,1) =~ /[A-Z?*]{1}/) );#ignore gaps and missing data
    }
    
    if ($lengthcount == 0){
    return (0, 0);
    }else{
    $string1 =~ s/-//g;
    $string2 =~ s/-//g;
    return ($lengthcount/length($string1), $lengthcount/length($string2));
    }
}

# subroutine to calculate average p-distance
sub ave_pdis {
my $row = shift;
my $col = shift;
my $matrix = shift;
my $names_order = shift;

my @row = @$row;
my @col = @$col;
my @matrix = @$matrix;
my %names_order = %$names_order;

my $cnt = 0;
my $pdis_sum = 0;
for (my $row_index=0; $row_index<@row; $row_index++) {
my $row_name = $row[$row_index];
	for (my $col_index=0; $col_index<@col; $col_index++) {
	my $col_name = $col[$col_index]; 
	my $pdis = $matrix->[$names_order{$row_name}]->[$names_order{$col_name}];
	$pdis_sum += $pdis;
	$cnt++;
	}
}

return($pdis_sum/$cnt);
}

# subroutine to split array in to several sub-array
sub split_array {
my $array = shift;
my $split = shift;
	
	$split++ if ($split == 0);
	my $block_num = int(@$array/$split);
	$block_num++ if ($block_num == 0);
	
	my @splited_array;
	my $size_cnt = 0;
	my $block_cnt = 0;
	
	while (my $file = shift @$array) {
		if ($size_cnt >= $block_num) {
		$size_cnt = 0;
		$block_cnt ++;
		}
	push @{$splited_array[$block_cnt]}, $file;
	$size_cnt ++;
	}

return(\@splited_array);
}

# subroutine to reformat input fasta file
sub readfas {
my $file = shift;

open INFILE, $file or die "\nERROR: Cannot find input file \"$file\" ($!)\n\n";

my (%seq, %seqlength, @input_order, $seq, $taxon, $lasttaxon, %taxa_cnt);

while (my $line = <INFILE>) {

	# remove enter
	$line =~ s/\r//g;
	chomp $line;
	
	# if find >
	if ($line =~ /^>(\S+)/) {
		$taxon = $1;
		
		# if find previous taxon name, and it hasn't recorded before
		if ($lasttaxon) {
			if (!(exists $seq{$lasttaxon})) {
				$seq =~ s/\s//g;
				$seq = uc $seq;
				my @strange_char = $seq =~ /[^A-Z?*\.\-]/g;
				my $length = length($seq);
				if (($length > 0)&&(@strange_char == 0)) {
				$seq{$lasttaxon} = $seq;
				push @input_order, $lasttaxon;
				$seqlength{$length} = ""; 
				} else {
					if ($length == 0) {
					print STDERR "WARNING: No nucleotide found sequence of $lasttaxon in $file. This taxon will be discarded.\n";
					}
					if (@strange_char > 0) {
					my $strange_char = join " ", @strange_char;
					print STDERR "WARNING: Found strange character \"$strange_char\" in sequence of $lasttaxon in $file. This taxon will be discarded.\n";					
					}
				} 
			} else {
			$taxa_cnt{$lasttaxon}++
			}
		}
		
		$seq = "";
		$lasttaxon = $taxon;
	} else {
	$seq .= $line;
	}
}

if ($lasttaxon) {
	if (!(exists $seq{$lasttaxon})) {
		$seq =~ s/\s//g;
		$seq = uc $seq;
		my @strange_char = $seq =~ /[^A-Z?*\.\-]/g;
		my $length = length($seq);
		if (($length > 0)&&(@strange_char == 0)) {
		$seq{$lasttaxon} = $seq;
		push @input_order, $lasttaxon;
		$seqlength{$length} = ""; 
		} else {
			if ($length == 0) {
			print STDERR "WARNING: No nucleotide found sequence of $lasttaxon in $file. This taxon will be discarded.\n";
			}
			if (@strange_char > 0) {
			my $strange_char = join " ", @strange_char;
			print STDERR "WARNING: Found strange character \"$strange_char\" in sequence of $lasttaxon in $file. This taxon will be discarded.\n";					
			}
		} 
	} else {
	$taxa_cnt{$lasttaxon}++
	}
}

close INFILE;

foreach my $taxon (sort keys %taxa_cnt) {
my $taxon_num = $taxa_cnt{$taxon};
$taxon_num++;
print STDERR "WARNING: Found $taxon_num \"$taxon\" in $file. Only first sequence named in \"$taxon\" will be kept\n";
}

my @seqlength = sort keys %seqlength;

my $aln_len;
if (@seqlength == 1) {
$aln_len = $seqlength[0];
} else {
$aln_len = "na";
}

return (\%seq, \@input_order, $aln_len);
}

# Subroutine to check missing option
sub check_option {
my $essential = shift;
my $ARGVoptions = shift;

	# get all arguments
	my %args;
	foreach my $args (@$ARGVoptions) {
		if ($args =~ /^--*(\S+)/) {
		$args{$1} = "";
		}
	}
	
	# find all missing arguments
	my @missing_option;
	foreach my $ess_arg (@$essential) {
		if (!(exists $args{$ess_arg})) {
		push @missing_option, "--$ess_arg";
		}
	}
	
	# print out all missing arguments
	if (@missing_option >= 1) {
	my $missing_option = join ", ", @missing_option;
	die "\nERROR: Missing option $missing_option\n\nUse -h or --help for more information on usage\n\n";
	}
}

sub usage {
print STDERR "
Script name: detect_contamination.pl

This script is used to detect source of contamination and contaminated samples from alignments of loci in fasta format.

Dependencies: 
(1) Perl module:
	1. Bio::AlignIO (included in Bioperl)
	2. Bio::Align::DNAStatistics (included in Bioperl)

Example Usage:
(1) Detect contamination from alignments under 'aligned'. Closely related groups are defined in 'same.txt'. Status of contamination will be written to 'contamination_stat.txt':

	perl detect_contamination.pl --indir aligned --same same.txt

Input files:
(1) aligned
(2) same.txt

Output files:
(1) contamination_stat.txt
(2) potentially contaminated pair of taxa in STDOUT

Note: only percentage of contamination between pair of taxa is higher than 50% and this pair occur at least 100 times will be reported in STDOUT

Option:
--indir
  Directory comprising all aligned sequences
--same
  Samples IDs which are belonging to the same taxon. We assume that samples within the taxon are close to each other, while different taxons should be distant away from each other. Please refer to same.txt for detailed format of input file 
--contamination_stat
  A tab delimited table describing contamination status of between pairs of samples, named as '$contaminated_stat' in default.
  Name of header and its meaning:
  (1) contaminated_sample: name of contaminated sample, \? after name means cannot detect the source of contamination
  (2) contaminating_source: name of contaminating source, \? after name means cannot detect the source of contamination
  (3) percentage of contaminated pair: percentage of times of detected contamination between a pair of sample. It\'s calculated by dividing times of detected contamination between a pair of sample by times of existence of that pair among all gene
  (4) contaminated pair: times of contamination between pair of samples
  (5) all pair: times of existence of pair of samples among all gene
  (6) contaminated_sample<-contaminating_source: times of contaminating source contaminated contaminated sample
  (7) contaminated_sample->contaminating_source: times of contaminated sample contaminated contaminating source
  Notice: We cannot determine which one is the contaminating source, if there\'s only one sample in defined group. As a result, (6)+(7) may smaller than (4).
--ct_limit
  Maximum average p-distance between contaminated sequences. If p-distance of sequences in different taxon is lower than this value, one of sequences in that pair will be marked as contaminated, $thre_c in default
--conserve_pdis
  If pdistance among all pairs of sequences among the alignment is lower than this value, this loci will skip contamination test, $conserve_trsd in default
--help , -h
  Show this page and exit

Author: Hao Yuan                                                                     
        Shanghai Ocean University                                               
        Shanghai, China, 201306                                                               
                                                                                         
Created by: Nov 20, 2018                                                              
                                                                                         
Last modified by: 
";
exit;
}