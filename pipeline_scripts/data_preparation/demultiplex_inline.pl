#!/home/users/cli/bin/perl

use Getopt::Long;
use Parallel::ForkManager;
use warnings;
# use strict;

# dir of undemultiplexed reads, dir of demultiplexed reads, inline index file, inline index pair file
my ($dir, $outdir, $index, $indexpair, $help);
my $unpairdir = "unpaired_reads"; # dir for unpaired reads
my $paired_summary = "paired_summary.txt"; # file summerized number and pct of paired reads, number of all reads for each undemultiplexed sample 
my $process = 1; # number of used process

my @ARGVoptions = @ARGV;

my $opt = GetOptions( 'undemultiplexed:s', \$dir,
                      'demultiplexed:s', \$outdir, 
                      'unpair:s', \$unpairdir,
                      'inline_index:s',\$index,
                      'index_pair:s', \$indexpair,
                      'cpu:s', \$process,
                      'help|h!', \$help) or die "\nERROR: Found unknown options. Use -h or --help for more information on usage\n\n";

# print help if no options or -h is specified
if ((@ARGVoptions == 0)||($help)) {
usage();
}

# check missing options
my @essential = qw/undemultiplexed demultiplexed inline_index index_pair/;
check_option(\@essential, \@ARGVoptions);

# hash of 6-char index seq and index order, unexpected same index
my (%index, %same_index);
my $line_cnt = 0; # line counter

# open inline index file
open INDEX, $index or die "\nERROR: Cannot open file of inline index \"$index\", please check --inline_index ($!)\n\n";
chomp(my $first_line = <INDEX>);

$line_cnt++;

# check whether first line is header or index sequence
my @first_line = $first_line =~ /(\S+)/g; # get chars in first line
my @nucleo = $first_line[0] =~ /A|T|C|G/g; # get ATCG in first element 
if (@nucleo == length($first_line[0])) { # if first element is totally consist of "ATCG", then it is a sequence
	
	# read index information
	my ($indexnum) = $first_line[1] =~ /(\d+$)/; # last number in second element is index order
	if ($indexnum) {
	$index{$first_line[0]}->{num} = $indexnum; # index seq -> index order
	$same_index{$indexnum}++; # same index
	} else { 
	die "\nERROR: Cannot extract number of index from second columns at line $line_cnt in $index\n\n";
	}
}

# extract following index information
while (my $line = <INDEX>) {
$line_cnt++;
my @line = $line =~ /(\S+)/g;
my ($indexnum) = $line[1] =~ /(\d+$)/; # get index order
	if ($indexnum) {
	$index{$line[0]}->{num} = $indexnum; # index seq -> index order
	$same_index{$indexnum}++;
	} else {
	die "\nERROR: Cannot extract number of index from second columns at line $line_cnt in $index\n\n";
	}
}
close INDEX;

# check whether exists identical index number
my @identical_index = grep {$same_index{$_} >= 2} keys %same_index;
if (@identical_index) {
die "\nERROR: Identical number of indexs are found (index number: @identical_index) in $index\n\n";
}

# open get info of inline pair
# hash of inline index pair and sample name, name of undemultiplexed reads
my (%indexpair, $undmtpl);

open INDEXPAIR, $indexpair or die ("\nERROR: Cannot open file of inline index \"$indexpair\", please check --index_pair ($!)\n\n");
while (my $line = <INDEXPAIR>) {
# check whether column lost in index pair file
my @space = $line =~ /(\s+)/g;
die "\nERROR: Some columns may missed in \"$indexpair\", please check --index_pair ($!)\n\n" if (@space < 3);

# correlate name of undemultiplexed reads, demultiplexed sample and corresponding index order of IS1 IS3
my @line = $line =~ /(\S+)/g;
$undmtpl = $line[0] if (@line == 4);
$indexpair{$undmtpl}->{"$line[-2].$line[-1]"} = $line[-3]; # undemultiplexed_set->{index1.index2} = sample name
}
close INDEXPAIR;

# create output dir
if (!(-e $outdir)) {
mkdir $outdir or die "\nERROR: Cannot create output directory for demultiplexed reads \"$outdir\", please check --demultiplexed ($!)\n\n";
}
# create dir of unpaired reads
if (!(-e $unpairdir)) {
mkdir $unpairdir or die "\nERROR: Cannot create output directory for unpaired reads \"$unpairdir\", please check --unpair ($!)\n\n";
}

# get name of all R1
opendir DIR, $dir or die ("\nERROR: Cannot open input directory \"$dir\", please check --undemultiplexed ($!)\n\n");
my @sampleR1 = grep {$_ !~ /^\./} readdir DIR;
@sampleR1 = grep {$_ =~ /\S+_R1.f\S*q/} @sampleR1;
closedir DIR;

# initiate multi-process
my $pm = Parallel::ForkManager->new($process);

# demultiplex in parallel

# callback number of paired and all reads in demultiplexed sample
my %paired_reads;
$pm->run_on_finish(
	sub {
	my $reads_num = $_[-1];
	$paired_reads{$reads_num->[0]}->{paired} = $reads_num->[1];
	$paired_reads{$reads_num->[0]}->{all} = $reads_num->[2];
	}
);

DATA_LOOP: foreach my $sampleR1 (@sampleR1) {
$pm->start and next DATA_LOOP;
	# get sample name and suffix
    my ($samplename, $fqorfastq) = $sampleR1 =~ /(\S+)_R1\.(f\S*q)/;
    
    my $paired_reads = 0;
    my $all_reads = 0;
    
    # skip if find unknown undemultiplexed read name
    if (!(exists $indexpair{$samplename})) {
    print STDERR "WARNING: Cannot find reads of $samplename under $dir, please check whether the name of undemultiplexed reads in \"$indexpair\" are correct\n";
	$pm->finish;
    next DATA_LOOP;
    }
    
    say STDOUT "Start to demultiplex reads of $samplename";
    
    my @all_key = sort keys %{$indexpair{$samplename}};
    my @NA_key = grep {$_ =~ /^na\.na$/i} @all_key;
    my $NA_key = $NA_key[0];
    
    # demultiplex
	if (@NA_key > 0) { # if there's no inline index in this sample
		my $oriname = $indexpair{$samplename}->{$NA_key};
		
		# copy to outdir
		`cp $dir/${samplename}_R1.$fqorfastq $outdir/${oriname}_R1.fq
		 cp $dir/${samplename}_R2.$fqorfastq $outdir/${oriname}_R2.fq`;
	} else { # if there's inline index in this sample
		# create file for unpaired reads
		open UNPAIR1, ">$unpairdir/${samplename}_UNPAIR_R1.fq" or die ("\nERROR: Cannot write $unpairdir/${samplename}_UNPAIR_R1.fq ($!)\n\n");
		open UNPAIR2, ">$unpairdir/${samplename}_UNPAIR_R2.fq" or die ("\nERROR: Cannot write $unpairdir/${samplename}_UNPAIR_R2.fq ($!)\n\n");
		
		# read paired reads
		my %open;
		open R1, "$dir/${samplename}_R1.$fqorfastq" or die ("\nERROR: Cannot open $dir/${samplename}_R1.$fqorfastq ($!)\n\n");
		open R2, "$dir/${samplename}_R2.$fqorfastq" or die ("\nERROR: Cannot open $dir/${samplename}_R2.$fqorfastq ($!)\n\n");
		
		while (my $line1 = <R1>) {
			if ($line1 =~ /\@(\S+)\s\S+/) { # beginning line of a read R1
			my $header1 = $1; # header of R1
			my $line2 = <R2>; # beginning line of a read R2
			my ($header2) = $line2 =~ /\@(\S+)\s\S+/; # header of R2
				if ($header1 eq $header2) { # if header is paired
				# get sequence and quality sequence of R1 and R2
				chomp(my $seq1 = <R1>); # sequence
				<R1>; # plus
				chomp(my $qua1 = <R1>); # quality sequence
				chomp(my $seq2 = <R2>);
				<R2>;
				chomp(my $qua2 = <R2>);	
				
				# count number of all reads in undemultiplexed reads
				$all_reads += 2;
				
					# demultiplex reads if sequences are at least longer than 6-char inline index
					if ((length($seq1) > 6) && (length($qua1) > 6) && (length($seq2) > 6) && (length($qua2) > 6)) {
						# inline index of R1 and R2
						my $index1 = substr $seq1, 0, 6;
						my $index2 = substr $seq2, 0, 6;
						
						# if index is exist in the index list, and this pair is also found
						if ((exists $index{$index1})&&(exists $index{$index2})&&(exists $indexpair{$samplename}->{"$index{$index1}->{num}.$index{$index2}->{num}"})) {
						# trimmed seq and quality seq from 7th char
						
						# count number of paired reads in undemultiplexed reads
						$paired_reads += 2;
						
						my $trm_seq1 = substr $seq1, 6;
						my $trm_qua1 = substr $qua1, 6;
						my $trm_seq2 = substr $seq2, 6;
						my $trm_qua2 = substr $qua2, 6;
						
							# define filehandle	
							my $speciesname = $indexpair{$samplename}->{"$index{$index1}->{num}.$index{$index2}->{num}"};
							my $PAIR1 = "${speciesname}_R1";
							my $PAIR2 = "${speciesname}_R2";
							
							# create unpair reads file if it doesn't exist
							if (!(exists $open{$speciesname})) {
							open $PAIR1, ">$outdir/$PAIR1.fq" or die ("\nERROR: Cannot write $outdir/$PAIR1.fq ($!)\n\n");
							open $PAIR2, ">$outdir/$PAIR2.fq" or die ("\nERROR: Cannot write $outdir/$PAIR2.fq ($!)\n\n");
							$open{$speciesname} = "";
							}
							
							# print to outfile
							print $PAIR1 "$line1$trm_seq1\n+\n$trm_qua1\n";
							print $PAIR2 "$line2$trm_seq2\n+\n$trm_qua2\n";
						} else { # print to unpaired if it's unrecognized index or pair
						print UNPAIR1 "$line1$seq1\n+\n$qua1\n";
						print UNPAIR2 "$line2$seq2\n+\n$qua2\n";
						}
					}
				} else { # die if header is paired
				die ("\nERROR: $header1 and $header2 in $dir/$samplename are unpaired\n\n");
				}
			}
		}
		close R1;
		close R2;
		close UNPAIR1;
		close UNPAIR2;
	
		# close opened filehandle
		foreach my $speciesname (sort keys %open) {
		my $PAIR1 = "${speciesname}_R1";
		my $PAIR2 = "${speciesname}_R2";
		close $PAIR1;
		close $PAIR2;
		}
	}
	
	say STDOUT "Reads of $samplename has been demultiplexed";

$pm->finish(0, [$samplename, $paired_reads, $all_reads]);
}
$pm->wait_all_children();

# write out undemultiplexed sample name, number of paired reads, number of all reads, pct of paired read for each sample
open PAIRED_SUMMARY, ">$paired_summary";
print PAIRED_SUMMARY "undemultiplexed_sample\tpaired reads\tall reads\tpaired percentage(%)\n";
foreach my $sample (sort keys %paired_reads) {
	my $paired = $paired_reads{$sample}->{paired};
	my $all = $paired_reads{$sample}->{all};

	if ($all > 0) {
	my $pct = sprintf("%.2f", $paired/$all*100);
	print PAIRED_SUMMARY "$sample\t$paired\t$all\t$pct\n";
	} elsif ($all == 0) {
	print PAIRED_SUMMARY "$sample\tNA\tNA\tNA\n";
	}
}
close PAIRED_SUMMARY;

######################################################
# Subroutines
######################################################

# Subroutine to check missing option
sub check_option {
my $essential = shift; # mandatory options
my $ARGVoptions = shift; # input options

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
Script name: demultiplex_inline.pl

This is a script to demultiplex reads from undemultipxed samples according to inline index

Example usage:

	perl demultiplex_inline.pl --undemultiplexed gunzipped_raw_data --demultiplexed demultiplexed --inline_index inlineindex.txt --index_pair indexpair.txt

Input files: 
(1) gunzipped_raw_data
(2) inlineindex.txt
(3) indexpair.txt

Output files:
(1) demultiplexed
(2) $paired_summary (file summerized number and pct of paired reads, number of all reads for each undemultiplexed sample)

Options:
--undemultiplexed
  Directory with expanded undemultiplexed fq files
--demultiplexed
  Directory containing demultiplexed reads
--unpair
  Directory containing reads pair not existed in provided inline pair, named '$unpairdir' in default
--inline_index
  Inline index file, please refer to inlineindex.txt for its detailed format
--index_pair
  Inline index pair for each demultiplexed sample, please refer to indexpair.txt for its detailed format
--cpu
  Limit the number of CPUs. $process in default
--help , -h
  Show this help message and exit

Author: Hao Yuan                                                                     
        Shanghai Ocean University                                               
        Shanghai, China, 201306                                                               
                                                                                         
Created by: Nov 20, 2018                                                              
                                                                                         
Last modified by:
";
exit;
}
