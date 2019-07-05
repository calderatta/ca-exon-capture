# Exon-capture Sequence Processing
##### Calder Atta
Advisor: Luke Tornabene  
Collaborators: Alison Deary, Steven Roberts, Kerry Naish  
Program Start: Fall 2017  
Program End (predicted): Fall 2019 (9 quarters)  
(need to create GitHub repo)  
Latest Update: January 2019

***

## Description
The goal of this project is to generate a phylogenetic tree using exon-capture data from 122 specimens of flatfishes (Pleuronectidae). The workflow is modified from Kuang et al. 2018.
##### Workflow from Kuang et al. 2018:
1. Raw reads from Illumina sequencer
2. BCL to fastq format demultiplex
3. Remove adapter sequences and low quality score reads
4. Remove the duplicates from PCR, parse the reads to each locus
5. Assemble the filtered reads into contigs
6. Merge the loci containing more than one contigs
7. Retrieve orthology by pairwise alignment to corresponding baits sequence
8. Identify orthology by comparing the retrieved sequence to the genome of O. nilotics (bait source)
9. Multiple sequences alignment
10. Downstream analysis

### Objective:
Create a time calibrated phylogeny of the family Pleuronectidae using exon-capture data.

### Details
Project Directory Location:

- Local:  `/Users/calderatta/Desktop/pleuronectid_seq_data/`
- GitHub: (not created)

Contents:
- `analysis/` Results from various analyses
   - `merge/` (1)
   - `preads-bandp/` (4)
   - `preads-rmrep/` (3)
   - `trimgalore/`  (2)
   - `trinity/` (5)
- `raw_data/` Contains source .fastq files.
- `kuang-et-al-2018/` Contains publication and associated supplamentary material.
- `markers/` Contains reference markers for data.
- `README.md` You Are Here!
- `screenshots/`
- `scripts/` Contains scripts used for analyses and pipeline for using them.

### Lab Server Access
uwfc-nas1.fish.washington.edu
128.208.74.36
Username: luke
Password: !123FisH

### History
