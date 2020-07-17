# Exon-capture Data Collection and Analysis

##### Tornabene Lab of Systematics and Biodiversity  
School of Aquatic and Fisheriese Science (SAFS)  
University of Washington

Author:  
   Calder Atta  
   University of Washington  
   School of Aquatic and Fisheries Science  
   calderatta@gmail.com  

This repository contains instructions and resources needed to perform exon-capture as used by the Tornabene Lab of Systematics and Biodiversity at SAFS. Computational processing follows that Assexon method from Yuan et al. (2019).

Reference: Yuan H, Atta C, Tornabene L, Li C. (2019) Assexon: Assembling Exon Using Gene Capture Data. Evolutionary Bioinformatics 15: 1–13. doi.org/10.1177/1176934319874792.

## How to use this repository

##### Starting from the beginning
If you are starting from scratch you will want to read up on what exon-capture is, what it does, and how it differs from other sequencing methods. There is a lot of information included in the `reference/` folder, but in short, exon-capture collects a massive abount of sequence data (4434 protein-coding genes in our case) for a relatively small time and material cost.

##### Lab Work
IMPORTANT: Consider the timeline for doing this. A double-hybridization run for 100 samples may take two months to complete. Make sure you have ALL materials ready and available before starting. You can use the Quickguide-and-Mixtures spreadsheet to calculate how much of each reagent you will need.

After you've collected the tissue samples you want to sequence and have extracted DNA (see the lab protocol for how to do this) follow the TargetEnrichment instructions contained in `lab_protocol/`. Quickguide-and-Mixtures provides a complete step-by-step protocol for the entire process and has allows you to calculate reagent amounts quickly, but the other documents contain more detailed instructions. Start with the SPRI document to test your SPRI beads and determine the best ratio of beads to sample. The rest of the Quickguide follows the protocol in LibPrep and capture documentation. In general, you will want to do 2 rounds of hybridization to maximize the amount of captured DNA fragments.

NOTE: If any steps differ between the Quickguide and detailed-protocol, we found the Quickguide version to be better suited for our needs in the lab.

##### Assembly Pipeline
Once you've recieved your sequence data, follow the pipeline protocol in `Exon_Capture_Pipeline.md` process your data. See `Installation_Guide.md` for instructions on how to install all software used in the pipeline.

NOTE: Some of the steps in this pipeline take a lot of computational power and can run for days. It is best to run the pipeline on a supercomputer. See `Mox_Hyak/` for information on using the UW supercomputer.

## Contents

- `references/` Information for understanding the method
- `lab_protocol/` Resources for preparing samples for sequencing
- `Exon_Capture_Pipeline.md` Full protocol for processing raw sequence data
- `Installation_Guide.md` Directions for installing software related to pipline
- `useful_commands.md` Miscelaneous commands that can be helpful to know during processing
- `pipeline_scripts/` Package of perl scripts from Yuan et al. (2019) that are used for the pipeline
- `perl_modules/` Modules used in the pipeline that are not usually contained in base Perl
- `tutourial/` Test data and instructions from Yuan et al.
- `Mox_Hyak/` Resources for using the UW supercomputer (NOTE: As of July 2020 the lab is not yet set up on the cluster)
 (2019) for analysis to practice the pipeline using perl scripts
- `images/` Images used in Github repo
- `README.md` You Are Here!
