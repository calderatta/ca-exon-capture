#!/home/users/cli/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Bio::AlignIO;
use Bio::Align::DNAStatistics;

my ($nonflank, $flank, $geneout, $individualout, $help);
$geneout = "loci_summary.txt";
$individualout = "sample_summary.txt";

my @ARGVoptions = @ARGV;

my $opt = GetOptions( 'nf_aligned:s', \$nonflank,
                      'f:s', \$flank,
                      'loci_stat:s', \$geneout,
                      'sample_stat:s', \$individualout,
                      'help|h!', \$help) or die "\nERROR: Found unknown options. Use -h or --help for more information on usage\n\n";

# print help if no options or -h is specified
if ((@ARGVoptions == 0)||($help)) {
usage();
}

# check missing options
my @essential = qw/nf_aligned/;
check_option(\@essential, \@ARGVoptions);

# check input folder of flanking sequences
if ($flank) {
	if (!(-e $flank)) {
	die "\nERROR: Cannot find input directory containing unaligned whole sequences with flanking regions \"$flank\", please check --f_unaligned ($!)\n\n";
	}
}

# get file name of coding sequences
opendir DIR, $nonflank or die "\nERROR: Cannot find input directory containing aligned full-coding sequences \"$nonflank\", please check --nf_aligned ($!)\n\n";
my @infile = grep {$_ !~ /^\./} readdir DIR;
@infile = grep {$_ =~ /fa$|fas$|fasta$/i} @infile;
closedir DIR;

# print header
open GENE, ">$geneout" or die "\nERROR: Cannot write table of summary statistics for each locus \"$geneout\", please check --loci_stat ($!)\n\n";
if ($flank) {
print GENE "Locus\tAver. coding region length(bp)\tAver. flanking region length(bp)\tAlignment length(bp)\tAver. GC content(%)\tMissing data(%)\tPairwise distance\n";
} else {
print GENE "Locus\tAver. coding region length(bp)\tAlignment length(bp)\tAver. GC content(%)\tMissing data(%)\tPairwise distance\n";
}

my $dir_copy = "${nonflank}_copy";
mkdir $dir_copy;

# summary statistics
my %individual;
LOOP: while (my $infile = shift @infile) {
	    
    my ($gene) = $infile =~ /(\S+)\.fa\S*$/; # get gene name 
	my $infilenf = "$nonflank/$infile"; # set file path
	
	# summary several statistics
	my %seq;
	my $totalgap = 0;
	
	my ($seqhash, $input_order, $aln_len) = readfas($infilenf);
	
	if (@$input_order == 0) {
	print STDERR "WARNING: Nothing found in $infilenf. Skip this file\n";
	next LOOP;
	}
	
	if ($aln_len eq "na") {
	print STDERR "WARNING: Number of characters among sequences are not the same in $infilenf. It may be not aligned. Skip this file\n";
	next LOOP;
	}
	
	my $copy_fas = "$dir_copy/$infile";
	open COPY_FAS, ">$copy_fas";
	
	foreach my $taxon (@$input_order) {
	my $seq = $seqhash->{$taxon};
	
	# print seq to copy
	print COPY_FAS ">$taxon\n$seq\n";
	
	my @gap = $seq =~ /-/g;
	$totalgap += @gap; # total number of gap in alignment
	
	$seq =~ s/-//g;
	$seq{$taxon}->{nflen} = length($seq); # coding sequence length
	
	my @gc = $seq =~ /([G|C])/g;
	$seq{$taxon}->{gc} = @gc/$seq{$taxon}->{nflen}; # gc percentage

	push @{$individual{$taxon}->{gc}}, $seq{$taxon}->{gc};
	}
	
	close COPY_FAS;

	my $gap = sprintf("%.2f", $totalgap/((scalar keys %seq)*$aln_len)*100); # gap percentage in alignment
		
	# calculate p-distance
	my $pdis = ave_pdis($copy_fas);
	
# 	ave coding length and gc
	my (@nflen, @gc);
	foreach my $taxon (sort keys %seq) {
	push @nflen, $seq{$taxon}->{nflen};
	push @gc, $seq{$taxon}->{gc};
	}
	my $aver_nflen = sprintf("%.2f", average(\@nflen)); # ave coding length
	my $aver_gc = sprintf("%.2f", average(\@gc)*100); # ave gc
    
#   statistics of flanking sequences
    my $aver_flen;
	if ($flank) {
		my $infilef = "$flank/$infile";
		
		if (-e $infilef) {
		my ($seqhash, $input_order, $aln_len) = readfas($infilef);

			if (@$input_order > 0) {
				foreach my $taxon (sort keys %$seqhash) {
					my $seq = $seqhash->{$taxon};
					if ($seq =~ /-/) {
					$seq =~ s/-//g;
					}
					my $wholelen = length($seq);
			
					if (exists $individual{$taxon}) {
					push @{$individual{$taxon}->{wlen}}, $wholelen; # whole length of flanking+non-flanking sequence
					}

					if (exists $seq{$taxon}) {
					$seq{$taxon}->{flen} = $wholelen-$seq{$taxon}->{nflen}; # length of flanking only sequence
					}
				}

			#   average of flanking length
				my @flen;
				foreach my $taxon (sort keys %seq) {
					if (exists $seq{$taxon}->{flen}) {
					push @flen, $seq{$taxon}->{flen}; 
					}
				}

				if (@flen) {
				$aver_flen = sprintf("%.2f", average(\@flen)); # ave flanking length
				} else {
				$aver_flen = "NA";
				}
			} else {
			$aver_flen = "NA";
			}
		} else {
		$aver_flen = "NA";
		}
	} 
	
# 	print statistics
	if ($flank) {
	print GENE "$gene\t$aver_nflen\t$aver_flen\t$aln_len\t$aver_gc\t$gap\t$pdis\n";
    } else {
    print GENE "$gene\t$aver_nflen\t$aln_len\t$aver_gc\t$gap\t$pdis\n";
    }   
}
close GENE;

# statistics for each sample
open INDIVIDUAL, ">$individualout" or die "\nERROR: Cannot write table of summary statistics for each sample \"$individualout\", please check --sample_stat ($!)\n\n";
if ($flank) {
	print INDIVIDUAL "Sample\tAver. captured length(bp)\tAver. GC content(%)\tCaptured loci number\n"; #header
	
	foreach my $sub (sort keys %individual) {
		my $inaverlen;
		if (exists $individual{$sub}->{wlen}) {
		$inaverlen = sprintf("%.2f", average($individual{$sub}->{wlen})); # ave whole length
		} else {
		$inaverlen = "NA";
		}
		my $inavergc = sprintf("%.2f", average($individual{$sub}->{gc}));  # ave gc
		my $genenum = scalar(@{$individual{$sub}->{gc}}); # enriched gene num
		print INDIVIDUAL "$sub\t$inaverlen\t$inavergc\t$genenum\n";
	} 
} else {
	print INDIVIDUAL "Sample\tAver. GC content(%)\tCaptured gene number\n";
	
	foreach my $sub (sort keys %individual) {
	my $inavergc = sprintf("%.2f", average(\@{$individual{$sub}->{gc}})); # ave gc 
	my $genenum = scalar(@{$individual{$sub}->{gc}}); # enriched gene num
	print INDIVIDUAL "$sub\t$inavergc\t$genenum\n";
	}
}
close INDIVIDUAL;

`rm -rf $dir_copy`;

#####################################################
# Subroutines
#####################################################

# subroutine to calculate average
sub average {
my $array = shift;

my @array = @$array;

my $total;
map {$total += $_} @array;
my $aver = $total/@array;
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

# subroutine to calculate average pdis
sub ave_pdis {
my $aln_file = shift;

my $stats = Bio::Align::DNAStatistics->new();
$stats->verbose(-1);

my $alignin = Bio::AlignIO->new(-format => 'fasta',
								-file   => $aln_file);
							
my $aln = $alignin->next_aln;
my $Uncorrected_matrix = $stats->distance(-align => $aln, 
								-method => 'Uncorrected');

my @names = @{$Uncorrected_matrix->{_names}}; 
my @distance = @{$Uncorrected_matrix->{_values}};

my $sum = 0;
my $entry_cnt = 0;
for (my $row = 0; $row < @distance; $row++) {
my @row_value = @{$distance[$row]};
my $row_name = $names[$row];

	for (my $col = $row+1; $col < @row_value; $col++) {
	my $col_name = $names[$col];
	my $entry_value = $row_value[$col];	
		if ($entry_value >= 0) {
		$sum += $entry_value;
		$entry_cnt++;
		}	
	}
}

my $ave;
if ($entry_cnt > 0) {
$ave = sprintf("%.2f", $sum/$entry_cnt);
} else {
$ave = "NA";
}

return $ave;
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

# subroutine to print usage
sub usage {
print STDERR "
Script name: statistics.pl

This script is used to summary statistics for each locus and sample from their alignments in fasta format. 
Summarized statistcis for each locus including:
(1) Average length of coding region
(2) Average length of flanking region
(3) Length of alignment
(4) Average GC content
(5) Percentage of Missing data
(6) Pairwise distance
Summarized statistcis for each sample including:
(1) Average length of captured sequences
(2) Average GC content
(3) Number of captured loci

Dependencies: 
(1) Perl module:
	1. Bio::AlignIO (included in Bioperl)
	2. Bio::Align::DNAStatistics (included in Bioperl)

Example Usage:
(1) Only summary statistics of full-coding (non-flanking) sequences under 'nf_aligned'. Summarized statistics are written to 'loci_summary.txt' and 'sample_summary.txt':

	perl statistics.pl --nf_aligned nf_aligned

(2) Summary statistics of full-coding (non-flanking) under 'nf_aligned' and whole sequences with flanking regions under 'f'. Summarized statistics are written to 'loci_summary.txt' and 'sample_summary.txt':

	perl statistics.pl --nf_aligned nf_aligned --f f

Input files:
(1) nf_aligned
(2) f (if --f_unaligned is specified)

Output files:
(1) loci_summary.txt
(2) sample_summary.txt

Option:
--nf_aligned
  Directory comprising aligned full-coding sequences
--f
  Directory comprising coding sequences with flanks
--loci_stat
  File name for tab delimited table of summarized statistics for each locus, named as '$geneout' in default
--sample_stat 
  File name for tab delimited table of summarized statistics for each sample, named as '$individualout' in default
--help , -h
  Show this page and exit

Author: Hao Yuan                                                                     
        Shanghai Ocean University                                               
        Shanghai, China, 201306                                                               
                                                                                         
Created by: June 27, 2018                                                              
                                                                                         
Last modified by:
";
exit;
}

