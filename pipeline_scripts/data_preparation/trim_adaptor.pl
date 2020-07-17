#!/opt/local/bin/perl

use Getopt::Long; 
use warnings;
use strict;
use Parallel::ForkManager;

# dir of raw reads, dir of trimmed reads, R1 adaptor, R2 adaptor,path to cutadapt
my ($dir, $outdir, $index, $indexpair, $oria, $oria2, $cutadapt, $help); 
$oria = "AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC";
$oria2 = "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT";
my $reads_bases_cnt = "trimmed_reads_bases_count.txt";  # file summarized with number of bp and reads in raw and trimmed reads
my $process = 1; # number of process used in default

my @ARGVoptions = @ARGV;

my $opt = GetOptions( 'raw_reads:s', \$dir,
                      'inline_index:s',\$index,
                      'index_pair:s', \$indexpair,
                      'adapter_R1:s', \$oria,
                      'adapter_R2:s', \$oria2,
                      'cutadapt_path:s', \$cutadapt,
                      'trimmed:s', \$outdir,
                      'cpu:s', \$process,
                      'help|h!', \$help) or die "\nERROR: Found unknown options. Use -h or --help for more information on usage\n\n";

# print help if no options or -h is specified
if ((@ARGVoptions == 0)||($help)) {
usage();
}

# check missing options
my @essential;
if (($index)||($indexpair)) {
@essential = qw/raw_reads trimmed inline_index index_pair/;
} else {
@essential = qw/raw_reads trimmed/;
}
check_option(\@essential, \@ARGVoptions);

# check whether trim_galore and cutadapt properly installed
`trim_galore -v` or die "\nERROR: Cannot find trim_galore under \$PATH\n\n";
`cutadapt --version` or die "\nERROR: Cannot find cutadapt under \$PATH\n\n" if (! $cutadapt);

# initiate multi-process
my $pm = Parallel::ForkManager->new($process);

# get the name of read R1
opendir DIR, $dir or die ("\nERROR: Cannot find input directory \"$dir\", please check --raw_reads ($!)\n\n");
my @reads = grep {$_ !~ /^\./} readdir DIR;
@reads = grep {$_ =~ /\S+_R1.fq/} @reads;
closedir DIR;

# mkdir if output dir don't exist
if (!(-e $outdir)){
mkdir $outdir or die "\nERROR: Cannot create output directory \"$outdir\", please check --trimmed ($!)\n\n";
}

# trim adaptor
if (($index)&&($indexpair)) { # if inline index file and index pair file are specified, then cut adapt according to inline index
inlineadapt($dir, $outdir, $index, $indexpair, $cutadapt, $oria, $oria2);
} else { # else cut it according to normal R1 and R2
adapt($dir, $outdir, $cutadapt, $oria, $oria2);
}

# mv log to trimming report
if (!(-e "trimming_report")){
mkdir "trimming_report" or die "\nERROR: Cannot create output directory of trimming_report \"trimming_report\"\n\n";
}
`mv -f ./$outdir/*trimming_report* ./trimming_report`;

# rename outfile
my @outfile = glob("$outdir/*");
map {
my $ori = $_;
$_ =~ s/_val_\d//;
`mv $ori $_`;
} @outfile;

# summary sample statistics from trimming_report
open READS_BASES_COUNT, ">$reads_bases_cnt";

print READS_BASES_COUNT "Sample\tReads num. of raw reads\tBases num. of raw reads (bp)\tReads num. of cleaned reads\tBases num. of cleaned reads (bp)\n";

# get name of R1 reads in output dir
opendir OUTDIR, $outdir;
my @outdir_reads = grep {$_ !~ /^\./} readdir OUTDIR;
@outdir_reads = grep {$_ =~ /\S+_R1.fq/} @outdir_reads;
closedir OUTDIR;

# summary statistics for each reads file
foreach my $R1 (@outdir_reads) {
my ($prefix) = $R1 =~ /(\S+)\_R1.fq/;

# summary number and bp of raw reads from trimming report
my $trimming_report_R1 = "trimming_report/${prefix}_R1.fq_trimming_report.txt";
my $trimming_report_R2 = "trimming_report/${prefix}_R2.fq_trimming_report.txt";

my ($R1_all_bases, $R1_all_reads) = all_reads_bases($trimming_report_R1);
my ($R2_all_bases, $R2_all_reads) = all_reads_bases($trimming_report_R2);

# summary number and bp of trimmed reads from trimmed reads
my $path_R1 = "$outdir/${prefix}_R1.fq";
my $path_R2 = "$outdir/${prefix}_R2.fq";

my ($R1_trimmed_bases, $R1_trimmed_reads) = trimmed_reads_bases($path_R1);
my ($R2_trimmed_bases, $R2_trimmed_reads) = trimmed_reads_bases($path_R2);

# sum up number of read and bases
my $all_bases = $R1_all_bases+$R2_all_bases;
my $all_reads = $R1_all_reads+$R2_all_reads;

my $trimmed_bases = $R1_trimmed_bases+$R2_trimmed_bases;
my $trimmed_reads = $R1_trimmed_reads+$R2_trimmed_reads;

print READS_BASES_COUNT "$prefix\t$all_reads\t$all_bases\t$trimmed_reads\t$trimmed_bases\n";
}
close READS_BASES_COUNT;

######################################################
# Subroutines
######################################################

# Subroutine to trim adaptor with inline index
sub inlineadapt {
	my $dir = shift; # dir with demultiplexed raw reads
	my $outdir = shift; # output dir
	my $index = shift; # index file 
	my $indexpair = shift; # index pair file
	my $cutadapt = shift; # path to cutadapt
	my $oria = shift; # normal R1 adaptor
	my $oria2 = shift; # normal R2 adaptor
	
	# hash of inline index and corresponding adaptor, unexpected same index
	my (%index, %same_index);
	my $line_cnt = 0; # line counter
	
	# open index file
	open INDEX, $index or die ("\nERROR: Cannot find inline index file \"$index\" ($!), please check --inline_index \n\n");
	chomp(my $first_line = <INDEX>);
	
	$line_cnt++;
	
	# check whether first line is header or index sequence
	my @first_line = $first_line =~ /(\S+)/g; # get chars in first line
	my @nucleo = $first_line[0] =~ /A|T|C|G/g; # get ATCG in first element 
	if (@nucleo == length($first_line[0])) { # if first element is totally consist of "ATCG", then it is a sequence
		
		# read index information
		my ($indexnum) = $first_line[1] =~ /(\d+$)/; # last number in second element is index order
		if ($indexnum) {		
		$index{$indexnum}->{"index"} = $first_line[0]; # index order -> index seq
		
		# get adaptor sequence to be trimmed on R2 side
		$first_line[2] =~ s/\*//g;
		$first_line[2] = uc($first_line[2]);
		$first_line[2] =~ tr/ATCG/TAGC/;
		$first_line[2] = reverse($first_line[2]);
		
		# get adaptor sequence to be trimmed on R1 side
		$first_line[4] =~ s/\*//g;
		$first_line[4] = uc($first_line[4]);
		$first_line[4] =~ tr/ATCG/TAGC/;
		$first_line[4] = reverse($first_line[4]);

		$index{$indexnum}->{a} = $first_line[4];
		$index{$indexnum}->{a2} = $first_line[2];
		
		# collect the number of same index
		$same_index{$indexnum}++;
		} else { 
		die "\nERROR: Cannot extract number of index from second columns at line $line_cnt in $index\n\n";
		}
	}
	
	# extract following inline index information
	while (my $line = <INDEX>) {
		my @line = $line =~ /(\S+)/g;
		my ($indexnum) = $line[1] =~ /(\d+$)/;
		if ($indexnum) {
		$index{$indexnum}->{"index"} = $line[0];
	
		$line[2] =~ s/\*//g;
		$line[2] = uc($line[2]);
		$line[2] =~ tr/ATCG/TAGC/;
		$line[2] = reverse($line[2]);
	
		$line[4] =~ s/\*//g;
		$line[4] = uc($line[4]);
		$line[4] =~ tr/ATCG/TAGC/;
		$line[4] = reverse($line[4]);
	
		$index{$indexnum}->{a} = $line[4];
		$index{$indexnum}->{a2} = $line[2];
		
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
	
	# specify the normal index if adaptor is not specified
	if (($oria)&&($oria2)) {
	$index{na}->{a} = $oria;
	$index{na}->{a2} = $oria2;
	}
	
	# save info of index pair
	my (%indexpair, $undmtpl);
	open INDEXPAIR, $indexpair or die ("\nERROR: Cannot find index pair file \"$indexpair\", please check --index_pair ($!)\n\n");
	while (my $line = <INDEXPAIR>) {
	# check whether column lost in index pair file
	my @space = $line =~ /(\s+)/g;
    die "\nERROR: Some columns may missed in \"$indexpair\", please check --index_pair ($!)\n\n" if (@space < 3);
	
	my @line = $line =~ /(\S+)/g;
	$indexpair{$line[-3]} = "$line[-2].$line[-1]"; # indexpair{sample name} = "IS1 index.IS3 index"
	}
	close INDEXPAIR;
        
        # trim adaptor in parallel
		DATA_LOOP: foreach my $read (@reads) {
		$pm->start and next DATA_LOOP;
		# get the name of sample name
		my ($speciesname) = $read =~ /(\S+)_R1.fq/;
		
		say STDOUT "Start to trim adaptors and low quality bases in reads of $speciesname";

		# get the index num, then get its adaptor
		my ($inline1, $inline2) = $indexpair{$speciesname} =~ /(\S+)\.(\S+)/;
		
		# lowercase if find "na"
		$inline1 = lc $inline1 if ($inline1 =~ /^na$/i);
		$inline2 = lc $inline2 if ($inline2 =~ /^na$/i);
		
		my $a = $index{$inline1}->{a} or die ("\nERROR: index R1 of $speciesname($1) do not exist\n\n");
		my $a2 = $index{$inline2}->{a2} or die ("\nERROR: index R2 of $speciesname($2) do not exist\n\n");
			# cut adapt
			if ($cutadapt) { # if path to cutadapt is specified
			`trim_galore -a $a -a2 $a2 --paired $dir/${speciesname}_R1.fq $dir/${speciesname}_R2.fq --path_to_cutadapt $cutadapt -o $outdir`;
			} else { # if cutadapt is in $PATH
			`trim_galore -a $a -a2 $a2 --paired $dir/${speciesname}_R1.fq $dir/${speciesname}_R2.fq -o $outdir`;
			}
		
		say STDOUT "Reads of $speciesname has been trimmed";
		
		$pm->finish;
		}
		$pm->wait_all_children();
}

# subroutine to normal cut adaptor
sub adapt {
my $dir = shift; # dir containing raw reads
my $outdir = shift; # output dir
my $cutadapt = shift; # path to cutadapt
my $a = shift; # R1 adaptor
my $a2 = shift; # R2 adaptor

# cut adaptor samples in parallel
DATA_LOOP: foreach my $read (@reads) {
$pm->start and next DATA_LOOP;
my ($speciesname) = $read =~ /(\S+)_R1.fq/;

say STDOUT "Start to trim adaptors and low quality bases in reads of $speciesname";

	if ($cutadapt) { # specify --path_to_cutadapt if have $cutadapt
	`trim_galore -a $a -a2 $a2 --paired $dir/${speciesname}_R1.fq $dir/${speciesname}_R2.fq --path_to_cutadapt $cutadapt -o $outdir`;
	} else {
	`trim_galore -a $a -a2 $a2 --paired $dir/${speciesname}_R1.fq $dir/${speciesname}_R2.fq -o $outdir`;
	}

say STDOUT "Reads of $speciesname has been trimmed";

$pm->finish;
}
$pm->wait_all_children();
}

# count number of reads and bases from trimming report
sub all_reads_bases {
my $trimming_report = shift; # trimming report

my ($all_reads, $all_bases);
open TRIMMING_REPORT, $trimming_report;
while (my $all_reads_line = <TRIMMING_REPORT>) {
	if ($all_reads_line =~ /Processed\sreads:/) { # find the line with "Processed reads:"
	my @all_reads = $all_reads_line =~ /\S+/g;
	$all_reads = $all_reads[2]; # the second char is the number of reads
	
	my $all_bases_line = <TRIMMING_REPORT>; # next line havinh number of bases
	my @all_bases = $all_bases_line =~ /\S+/g;
	$all_bases = $all_bases[2]; # the second char is the number of bases
	
	last;
	}
}
close TRIMMING_REPORT;

# return number of bases and reads
return($all_bases, $all_reads);
}

# count number of reads and bases from trimmed reads
sub trimmed_reads_bases {
my $file = shift; # trimmed reads file

# initial number of read and base
my $base_cnt = 0;
my $read_cnt = 0;

# count number of reads and bases
open READS, $file;
while (my $line = <READS>){
	if ($line =~ /^\@\S+\s*\S*/){ # if find @, which is the beginning line of a read
	chomp(my $seq = <READS>); # sequence
	<READS>; # plus
	<READS>; # quality
	$base_cnt += length($seq); # add number of bases
	$read_cnt ++; # add number of reads
	}
}
close READS;

# return number of bases and reads
return ($base_cnt, $read_cnt);
}

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
Script name: trim_adaptor.pl

This is a script to trim low quality bases and adaptor from 3\' end of reads

Dependencies:
(1) trim_galore v0.4.1 or higher
(2) cutadapt v1.2.1 or higher

Example usage:
(1) When inline index are involved in samples

	perl trim_adaptor.pl --raw_reads demultiplexed --inline_index inlineindex.txt --index_pair indexpair.txt --trimmed trimmed

(2) When no inline index are involved in samples

	perl trim_adaptor.pl --raw_reads demultiplexed --trimmed trimmed	

Input files: 
(1) demultiplexed
(2) inlineindex.txt (if --inline_index is specified)
(3) indexpair.txt (if --index_pair is specified)

Output files:
(1) trimmed
(2) trimmed_reads_bases_count.txt (file summarized number of reads and bases in raw and trimmed reads)

Options:
--raw_reads
  Directory containing demultiplexed reads
--inline_index
  Inline index file, please refer to inlineindex.txt for its detailed format
--index_pair
  Inline index pair for each sample, please refer to indexpair.txt for its detailed format
--adapter_R1
  Adaptor to be trimmed on R1 side for non inline-indexed reads, 'AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC' in default
--adapter_R2
  Adaptor to be trimmed on R2 side for non inline-indexed reads, 'AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT' in default
--cutadapt_path
  Specify a path to the Cutadapt executable, else it is assumed that Cutadapt is in \$PATH
--trimmed
  Directory containing reads without adaptor and low quality bases
--cpu
  Limit the number of CPUs, $process in default
--help , -h
  Show this help message and exit

Author: Hao Yuan                                                                     
        Shanghai Ocean University                                               
        Shanghai, China, 201306                                                               
                                                                                         
Created by: 20 Nov, 2018                                                              
                                                                                         
Last modified by: 
";
exit;
}