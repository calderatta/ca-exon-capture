# Main
##### Exon-capture Sequence Processing
Last Updated:

***
## Overview
I. Download Raw Data
II. Merge Lanes
III. Trim Adapters
IV. Assemble
V. Filter Data Set
VI. Aligning
VII. Alignment Filtering
VIII. Summary Statistics
IX. Concatenated Alignments
X. RAxML Tree
XI. Remove contaminated samples and redo RAxML
XII. Select Clocklike Genes
XIII. Create Species Tree from Gene Trees
***

## I. Download Raw Data

##### 1. Download

1st Run: https://hiseq.dbi.udel.edu/Data/181130/rdtnf5OjDHDsXJX/181130_Tornabene.tar  
2nd Run: https://hiseq.dbi.udel.edu/Data/181207/ibqZDDRtFizMXI/181207_Tornebene.tar

Source:  
DNA Sequencing & Genotyping Center  
Delaware Biotechnology Institute  
University of Delaware  
Primary Contact: Brewster Kingham (brucek@udel.edu)  
Servicing: Illumina (HiSeq 2500, 150 PE)  

Save files in  `raw-data/`.

##### 2. Unzip

##### 3. Unzip individual .fastq files

In each folder containing .fastq files...  
`raw-data/181130_Tornebene/Atta_Pool1`  
`raw-data/181130_Tornebene/Atta_Pool2`  
`raw-data/181207_Tornebene/Atta_Pool1`  
`raw-data/181207_Tornebene/Atta_Pool2`

...run the following command:

    gunzip -k *.fasta.gz

***
## Assembly Pipeline
***

## II. Merge Lanes

This only needs to be done if samples were run on multiple lanes.

##### 1. Rename Files (temporarily)

!!! Only do this if lane numbers are the same in both the 1st and 2nd run. !!!
Merging requires files to be in the same directory, so they must have different names. Also, the merge command in step 3 needs to identify the lane number in the file name. Temporary lane numbers are as such:
L001 -> L003 (Pool1)
L002 -> L004 (Pool2)

In `raw-data/181207_Tornebene/Atta_Pool1/` run:

    rename 's/_L001/_L003/' *.fastq

In `raw-data/181207_Tornebene/Atta_Pool2/` run:

    rename 's/_L002/_L004/' *.fastq

##### 2. Move all .fastq files into one folder

##### 3. Merge files

Adapted merge command:

    (for i in *_L001_R1_001.fastq; do cat ${i%_L001_R1_001.fastq}_L001_R1_001.fastq ${i%_L001_R1_001.fastq}_L003_R1_001.fastq > ${i%_L001_R1_001.fastq}_R1.fastq; done)
    (for i in *_L001_R2_001.fastq; do cat ${i%_L001_R2_001.fastq}_L001_R2_001.fastq ${i%_L001_R2_001.fastq}_L003_R2_001.fastq > ${i%_L001_R2_001.fastq}_R2.fastq; done)

    (for i in *_L002_R1_001.fastq; do cat ${i%_L002_R1_001.fastq}_L002_R1_001.fastq ${i%_L002_R1_001.fastq}_L004_R1_001.fastq > ${i%_L002_R1_001.fastq}_R1.fastq; done)
    (for i in *_L002_R2_001.fastq; do cat ${i%_L002_R2_001.fastq}_L002_R2_001.fastq ${i%_L002_R2_001.fastq}_L004_R2_001.fastq > ${i%_L002_R2_001.fastq}_R2.fastq; done)
The first 2 commands merge the lanes for R1 and R2 files respectively for the 1st run. The latter 2 commands do the same for the 2nd run.

##### 4. Move merged files into merge folder

Move to `analysis/merge/`.

##### 5. (Optional) Return original files to their respective folders and restore lane names

In `raw-data/181207_Tornebene/Atta_Pool1/` run:

    rename 's/_L003/_L001/' *.fastq

In `raw-data/181207_Tornebene/Atta_Pool2/` run:

    rename 's/_L004/_L002/' *.fastq

## III. Trim Adapters

##### 1. Rename merged files as .fq

In `analysis/merge` run:

    (for file in *.fastq; do mv "$file" "$(basename "$file" .fastq).fq"; done)

##### 2. Trim adapters

Check the options for `trim_adaptor.pl`.

    trim_adaptor.pl -h

Run the following code as a job named `#PBS -N CA_trim`:

    trim_adaptor.pl \
    --raw_reads merge \
    --trimmed trimmed

## IV. Assemble

##### 1. Assemble

Run the following code as a job named `#PBS -N CA_assemble`:

    assemble.pl \
    --trimmed trimmed \
    --queryp /home/users/cli/ocean/reference_and_genome/Oreochromis_niloticus_17675/Oreochromis_niloticus_4434.aa.fas \
    --queryn /home/users/cli/ocean/reference_and_genome/Oreochromis_niloticus_17675/Oreochromis_niloticus_4434.dna.fas \
    --db /home/users/cli/ocean/reference_and_genome/Oreochromis_niloticus_17675/Oreochromis_niloticus.sm_genome.fa \
    --dbtype nucleo \
    --ref_name Oreochromis_niloticus \
    --outdir assemble_result
    
The sga_assemble step failed to we needed to re-run starting from that step. See `assemble.pl -h` for how to run from a part-way through the process.

Full runtime was about 6 days.

***
## Post-processing
***

## V. Filter Data Set

Before aligning, remove...  
(1) Samples represented by fewer than 500 genes  
(2) Genes captured in fewer then 80% of the samples

##### 1. Check genes counts per sample

Open and check in 'enriched_gene.txt'. All samples checked out.

##### 2. Check sample counts per gene

Option 1: Navigate to the folder and report sequence counts for each file:

    grep -c "^>" *.fas

This option is not the easiest to tell, so instead...

Option 2: Add sequences into Geneious (as lists) and check/sort by sequence counts.

If any genes (files) contain fewer than 80% of the samples, we need to remove them. By visually inspecting, about 45% of our genes need to be removed.

##### 2. Removing genes with a < 70% completeness level

We wanted to use a more relaxed completeness level to preserve more genes. We plotted the reads filtered using different completeness levels (this was done in excel), and decided to use 70% instead of 80% since we would get 500 more genes, and after 70% the number of genes begins to plateau.

At this point there is one file for each gene, and each file contains one sequence per samples + the reference (O. niloticus in this case). So we need to filter out the files with fewer sequences than 70% of the total taxa.

Total Samples = 122  
70% of Samples = 122 * 0.7 = 85.4

Run the following code as a job named `#PBS -N CA_minseq86`:

    pick_taxa.pl \
    --indir assemble_result/nf \
    --outdir nf_minseq86 \
    --min_seq 86

Edit -min_seq to change the completeness level.

## VI. Aligning

Run the following code as a job named `#PBS -N CA_align`:

    mafft_aln.pl \
    --dna_unaligned nf_minseq86 \
    --dna_aligned nf_aligned \
    --cpu 12

## VII. Alignment Filtering

Run the following code as a job named `#PBS -N CA_filter`:

    filter.pl \
    --indir nf_aligned \
    --filtered nf_filtered \
    --ref_taxa "Oreochromis_niloticus" \
    --cpu 12

## VIII. Summary Statistics

Run the following code as a job named `#PBS -N CA_stats`:

    statistics.pl \
    --nf_aligned nf_filtered \
    --f assemble_result/f

***
## Phylogenetic analysis
***

Overview:
1. Concatinated tree: Filter alignments -> concat_loci.pl (concatenate loci into master gene) -> RAxML
2. Select clocklick genes: Filter alignments + RAxML tree -> Filter clocklike
2. Gene tree to species tree: Filter alignments -> Gene trees -> Species tree
3. Time-calibrated tree: Filter clocklike + Species tree + Fossils -> Time-calibrated tree

## IX. Concatenated Alignments

    concat_loci.pl \
    --indir nf_filtered \
    --outfile concat

## X. RAxML Tree

Citation for using RAxML:

- A. Stamatakis: "RAxML Version 8: A tool for Phylogenetic Analysis and Post-Analysis of Large Phylogenies". Bioinformatics (2014) 30 (9): 1312-1313.

Code tried on SHOU Cluster:

    raxmlHPC-PTHREADS -T 12 -n raxml -y -f a -# 100 -p 12345 -x 12345 -m GTRCAT -s concat.phy
    
I couldn't get this to work on the cluster so I downloaded concat.phy and ran locally.
RAxML Download and Info:
https://github.com/stamatak/standard-RAxML  
https://cme.h-its.org/exelixis/resource/download/NewManual.pdf

To install RAxML, download GitHub repository, extract, navigate to the folder. Then use the code:

    make -f Makefile.gcc
    rm *.o

Code Ran:

    /Users/calderatta/Downloads/standard-RAxML-master/raxmlHPC -n raxml -y -f a -# 100 -p 12345 -x 12345 -m GTRCAT -s concat.phy

- dont use -q flag
- cipres (phylo.org)
https://github.com/stamatak/standard-RAxML

## XI. Remove contaminated samples and redo RAxML

Remove contaminated samples and do steps V - IX again.

##### 1. Remove contaminated samples and refilter aligned genes.

    #!/bin/bash

    #PBS -l nodes=1:ppn=24
    #PBS -l walltime=240:00:00
    #PBS -N CA_rm_contam
    #PBS -q avant

    cd /home/users/cli/ocean/Calder/

    pick_taxa.pl \
    --indir nf_minseq86 \
    --outdir rm_contam \
    --deselected_taxa 'LYOEXIL_UW155009_S98 LEPBILI_UW153236_S95 LIMASPE_UW151257_S36 LEPPOLY_UW119625_S27 HIPELAS_UW152926_S93 EMBBATH_UW119866_S94 INOISCH_UW025860_S53 HIPELAS_UW151449_S68 LEPPOLY_UW150842_S37 LIMPROB_UW150849_S54 PLEVERT_UW119938_S16 HIPSTOM_UW119884_S10'

    mafft_aln.pl \
    --dna_unaligned rm_contam \
    --dna_aligned rm_contam_aligned \
    --cpu 12

    filter.pl \
    --indir rm_contam_aligned \
    --filtered rm_contam_filtered \
    --ref_taxa "Oreochromis_niloticus" \
    --cpu 12

    statistics.pl \
    --nf_aligned rm_contam_filtered \
    --f assemble_result/f

    exit 0

##### 2. Remove O. nilioticus.

Atom crashed and I lost documentation for this. "Need to google how to remove sequences from multiple fasta files based on name."

##### 3. Remake concatinated RAxML tree

    #!/bin/bash

    #PBS -l nodes=1:ppn=24
    #PBS -l walltime=240:00:00
    #PBS -N CA_rm_contam_raxml
    #PBS -q avant

    cd /home/users/cli/ocean/Calder/
    
    concat_loci.pl \
    --indir rm_contam_filtered \
    --outfile rm_contam_concat
    
    raxmlHPC-PTHREADS -n raxml2 -y -f a -# 100 -p 12345 -x 12345 -m GTRCAT -s rm_contam_concat.phy -T 12

    exit 0

## XII. Select Clocklike Genes

##### 1. Run clocklikeness test on filtered alignments

    clocklikeness_test.pl --indir nf_filtered --besttree RAxML_bestTree.raxml.tre --clocklike clocklike_dir --cpu 4

Note: This also produces a folder clocklikeness_dir with filtered genes based on p-values, but we will not use these. The folder only contained 97 genes.

###### run_job.sh on SHOU cluster

    #PBS -l nodes=1:ppn=24
    #PBS -l walltime=240:00:00
    #PBS -N CA_clocklike
    #PBS -q avant

    cd /home/users/cli/ocean/Calder/

    clocklikeness_test.pl --indir rm_ORENILO --besttree RAxML_bipartitions.raxml3.new --clocklike clocklike_dir --cpu 4

    exit 0

The next two steps can be done on the cluster, but likelihood.txt must be examined locally in excel.

##### 2. Removing genes with a < 70% completeness level

We need to do this again since, the alignment filtering step removes poorly aligned sequences in each gene file. We can use the sequence length field in likelihood.txt to filter for sequences with at least 86 sequences.

- Examine likelihood.txt and make list of files to remove rm_ORENILO_maxseq86.txt.
- Create rm_ORENILO_minseq86 and copy files from rm_ORENILO.
- Navegate into rm_ORENILO_minseq86.

    rm -r `cat ../rm_ORENILO_maxseq86.txt`

This command removes files in the above text file (not copy made).

##### 3. Filter for most clocklike genes

In likelihood.txt, first check if the likelihood ratio (MCL) and sequence length correlate. If so, make a corrected MCL by dividing the ratio by length and filter for the lowest values. I checked a histogram of the corrected MCL and tried to remove the highest values ut miminize loss of genes. I also made sure all sequences in clocklikeness_dir were also included. I decided to make the cutoff at 1.9.

- Examine likelihood.txt and make list of files to keep clocklike_max1.9.txt.
- Create clocklike_max1.9.
- Navegate into directory above clocklike_max1.9.

    rsync -a rm_ORENILO_minseq86 --files-from=clocklike_max1.9.txt clocklike_max1.9

This command only keeps files in the above text file (copies from previous directory).
Compress clocklike_min1.9 and move to cluster.

## XIII. Create Species Tree from Gene Trees

##### 1. Construct gene tree for each loci (construct.pl)

    construct_tree.pl --indir clocklike_max1.9 --cpu 4

Input files: `clocklike_max1.9` (This can be any of the filtered alignments.)

Output files: `clocklike_max1.9_ml`
    
###### run_job.sh on SHOU cluster

    #PBS -l nodes=1:ppn=24
    #PBS -l walltime=240:00:00
    #PBS -N CA_genetree
    #PBS -q avant

    cd /home/users/cli/ocean/Calder/

    construct_tree.pl --indir clocklike_max1.9 --cpu 4

    exit 0

##### 2. Merge resulting gene trees into one file

Navigate into clocklike_max1.9_ml.

    cat *.tre > ../clocklike_merge.tre

##### 3. Construct species tree in ASTRAL

    java –jar astral.5.6.3.jar –i clocklike_merge.tre –o species.tre –t 2

You may need to navigate into the ASTRAL repository and change the paths for input and output files. Also, we can use a mapping file to force all individuals to map together using -a. (https://github.com/smirarab/ASTRAL/blob/master/astral-tutorial.md#astral-help)

I couldn't get this to work as an environmental variable, so I just navigated into the Astral directory, moved clocklike_merge.tre into test_data, and move everything back to my working directory after. Hand typing seems to help it run.

## VIII. Generate Time-calibrated Tree

If we ran this directly only on the clocklike genes, Beast would need to consider lengths as well as all possible topologies. So to constrain the computational workload, we will use the ASTRAL tree as a topology constraint.

                                                                
