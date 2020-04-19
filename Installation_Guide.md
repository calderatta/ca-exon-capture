# Installation Guide for Exon Capture Data Processing

##### Tornabene Lab of Systematics and Biodiversity

Author: Calder Atta  
        University of Washington  
        School of Aquatic and Fisheriese Science  
        calderatta@gmail.com

Created: February 12, 2020

Last modified: ~

***
## Introduction
This document is meant to have all instructions for software relating to the exon-capture piptline from scratch. If there are any errors running any of the scripts or other programs, there may be solutions included. Update as needed.

## Overview
- Pipeline Scripts
- Perl
- Other Dependencies

***
## Pipeline Scripts
***

All scripts are located in this repository.

assemble/
- assemble.pl
- exonerate_best.pl
- merge.pl
- reblast.pl
- rmdup.pl
- sga_assemble.pl
- ubxandp.pl

data_preparation/
- demultiplex_inline.pl
- gunzip_Files.pl
- predict_frames.pl
- trim_adaptor.pl

postprocess/
- clocklikeness_test.pl
- concat_loci.pl
- consensus.pl
- construct_tree.pl
- count_reads_bases.pl
- detect_contamination.pl
- filter.pl
- flank_filter.pl
- get_orthologues.pl
- mafft_aln.pl
- map_statistics.pl
- merge_loci.pl
- monophyly_test.pl
- pick_taxa.pl
- statistics.pl
- unixlb_unwarp.pl
- vcftosnps.pl

***
## Setting environmental variables ($PATH)
***

Before starting, you will need to understand environmental variables. These are locations on a computer that are automatically searched when entering text into the command line. Programs located in the $PATH can be called without typing out their entire path. There are several scripts and programs in this pipeline that are dependent on others and require them to be available in the $PATH. See below for how to check and add $PATH variables.

It might be helpful to store all programs associated with this pipeline in one place and add that location to the $PATH.

## Windows
1. Right-click the Computer icon and choose Properties, or in Windows Control Panel, choose System.
2. Choose Advanced system settings. ...
3. On the Advanced tab, click Environment Variables. ...
4. Click New to create a new environment variable.

## MAC
1. Open up Terminal.
2. Run the following command: `sudo nano /etc/paths`
3. Enter your password, when prompted.
4. Go to the bottom of the file, and enter the path you wish to add.
5. Hit control-x to quit.
6. Enter “Y” to save the modified buffer. Hit Enter.
7. That's it! To test it, in new terminal window, type: `echo $PATH`

***
## Perl
***

## Installing Perl

You must have Perl installed to use this pipeline. Mac computers come with Perl already installed. To test if Perl is installed run:

    perl --version

If you receve a message with the version, then perl is installed. If you get an error saying that perl cannot be found then you need to install it.

If perl gives you an error saying "Can't locate XXX in @INC" you may need to change the @INC array. @INC works like $PATH, but for Perl. See this page for help: perlmaven.com/how-to-change-inc-to-find-perl-modules-in-non-standard-locations

@INC on OVert computer:  
@INC = C:\Program Files\Git\  
eg. @INC\usr\share\perl5\core_perl = C:\Program Files\Git\usr\share\perl5\core_perl

## Perl Modules

Not all modules required for this pipeline are automatically installed with Perl. If you run a script and get an error like the one below, you may need to download additional modules from https://metacpan.org.

Example Error:  
>Can't locate XXX.pm in @INC (you may need to install the XXX module) (@INC contains: /opt/local/lib/perl5/site_perl/5.26/darwin-thread-multi-2level /opt/local/lib/perl5/site_perl/5.26 /opt/local/lib/perl5/vendor_perl/5.26/darwin-thread-multi-2level /opt/local/lib/perl5/vendor_perl/5.26 /opt/local/lib/perl5/5.26/darwin-thread-multi-2level /opt/local/lib/perl5/5.26) at /opt/local/lib/perl5/5.26/XXX.pm line XXX.
>BEGIN failed--compilation aborted at /opt/local/lib/perl5/5.26/XXX.pm line XXX.
>Compilation failed in require at /opt/local/lib/perl5/5.26/XXX.pm line XXX.
>BEGIN failed--compilation aborted at /opt/local/lib/perl5/5.26/XXX.pm line XXX.
>Compilation failed in require at XXX.pl line XXX.
>BEGIN failed--compilation aborted at XXX.pl line XXX.

The following are modules that are known to be missing. Please add to this list if you find more. These modules are also stored on this repository.
- Parallel::ForkManager (https://metacpan.org/pod/Parallel::ForkManager)
- Moo (https://metacpan.org/pod/Moo)
- Sub::Quote (https://metacpan.org/pod/Sub::Quote)
- Bio::Seq (https://metacpan.org/pod/Bio::Seq)
- Statistics::Distributions (https://metacpan.org/release/Statistics-Distributions)
- Sys::Info (https://metacpan.org/pod/Sys::Info)
- Sys::Info::Constants (https://metacpan.org/pod/Sys::Info::Constants)

To install the modules, find the @INC directory that contains existing modules. Mine were in `/opt/local/lib/perl5/5.26`. Then just move the desired modules into this directory. If the required scripts are in folders, move the entire folder into the @INC directory. If the folder is already present, just add any of the missing files within that folder. The scripts should work on any operating system.

If you need to install modules from the website, seach for the module, download it, unzip it, and navigate into the unzipped folder. All the module files will be located in the `/lib/` folder. You may copy these files into the @INC directory as before or you can try running the following to automatically install.

    perl Makefile.PL && make test && make install

## Modify Pipeline Scripts to Call the Perl Interpreter

The first line of each script (the "shebang") shows where the file is trying to locate the perl interpreter on the computer. As downloaded, the location is for the SHOU supercompter, so we need to edit this to the path of `perl` locally. For me it was `#!opt/local/bin/perl`.

https://stackoverflow.com/questions/9009157/execute-perl-in-command-line-without-specifying-perl-in-unix

***
## Pipeline Script Dependencies
***

## PAUP

http://phylosolutions.com/paup-test/

Download the binary version.
Navigate to the file and expand with:

    gunzip paupa***
    
Rename as `paup`
You will probably need to give permissions in order to execute this file.

    chmod a+x paup

Move to $PATH

## Trimgalore
https://github.com/FelixKrueger/TrimGalore

## Cutadapt
https://github.com/marcelm/cutadapt

## USEARCH
https://www.drive5.com/usearch/download.html

Download the free 32-bit version for your computer and unzip it. Rename the binary file to just `usearch` and test it by navigating to it and calling the program in the command line: `./usearch`. Move the file to the $PATH. You may need to give permissions in order to execute it. To do so run: `chmod a+x usearch`

If you use a Mac 10.15 Catalina, you cannot run the 32-bit version, so you will either need to purchase a license (which is VERY expensive) or run the rmdup.pl step on a different computer.

## MAFFT
https://mafft.cbrc.jp/alignment/software/

Installation is pretty straight forward. Just download the appropriate version of the installer from the website and follow instructions.

## RAxML
https://github.com/stamatak/standard-RAxML

This one’s a little complicated. Check the README file before downloading to choose the right version. SSE3 will work on most newer computers and AVX for most recent (see read me for details), and PTHREADS is for running on any computer with more than one core processor (this should be almost all computers).

Download the repository from github, navigat einto the home folder and compile with the command for the right version. For most computers it’s:

    make -f Makefile.SSE3.PTHRADS.gcc

To call the program make sure to add a ./ if in a local directory (instead of from the path).

## ASTRAL
https://github.com/smirarab/ASTRAL

Installation instructions copied from GitHub site:

Download using one of two approaches:
1. You simply need to download the zip file and extract the contents to a folder of your choice.
2. Alternatively, you can clone the github repository. You then run make.sh to build the project or simply uncompress the zip file that is included with the repository.

ASTRAL is a java-based application, and should run in any environment (Windows, Linux, Mac, etc.) as long as java is installed. Java 1.5 or later is required. We have tested ASTRAL only on Linux and MAC. To test your installation, go to the place where you put the uncompressed ASTRAL, and run:

    java -jar astral.5.7.3.jar -i test_data/song_primates.424.gene.tre

Make sure to type which ever version you downloaded. This should quickly finish. There are also other sample input files under test_data/ that can be used.

ASTRAL can be run from any directory (e.g., /path/to/astral/). Then, you just need to run:

    java -jar /path/to/astral/astral.5.7.3.jar

Also, you can move astral.5.7.3.jar to any location you like and run it from there, but note that you need to move the lib directory with it as well.
