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
This document is meant to have all instractions for software relating to the exon-capture piptline. Update as needed.

## Overview
- Pipeline Scripts
- Pipeline Dependencies

***
## Pipeline Perl Scripts
***


***
## Pipeline Script Dependencies
***

## Parallel::ForkManager
To install use:

    cpan Parallel::ForkManager

I tried this but I'm not sure if it worked. Instead I downloaded each module directly from mata:cpan. - CA

- Parallel::ForkManager (https://metacpan.org/pod/Parallel::ForkManager)
- Moo (https://metacpan.org/pod/Moo)
- Sub::Quote (https://metacpan.org/pod/Sub::Quote)
- Bio::Seq (https://metacpan.org/pod/Bio::Seq)

Install each by downloading, unzipping, navigating into the extracted folder, and running:

    perl Makefile.PL && make test && make install

Copy all files in `/lib/` to `/opt/local/lib/peerl5/5.26/` or what ever directory is being searched by perl @INC. To check viable directories, run the one of perl scripts and see the error it gives. Example:

>Can't locate Moo/Role.pm in @INC (you may need to install the Moo::Role module) (@INC contains: /opt/local/lib/perl5/site_perl/5.26/darwin-thread-multi-2level /opt/local/lib/perl5/site_perl/5.26 /opt/local/lib/perl5/vendor_perl/5.26/darwin-thread-multi-2level /opt/local/lib/perl5/vendor_perl/5.26 /opt/local/lib/perl5/5.26/darwin-thread-multi-2level /opt/local/lib/perl5/5.26) at /opt/local/lib/perl5/5.26/Parallel/ForkManager/Child.pm line 12.
>BEGIN failed--compilation aborted at /opt/local/lib/perl5/5.26/Parallel/ForkManager/Child.pm line 12.
>Compilation failed in require at /opt/local/lib/perl5/5.26/Parallel/ForkManager.pm line 12.
>BEGIN failed--compilation aborted at /opt/local/lib/perl5/5.26/Parallel/ForkManager.pm line 12.
>Compilation failed in require at mafft_aln.pl line 6.
>BEGIN failed--compilation aborted at mafft_aln.pl line 6.

## MAFFT
https://mafft.cbrc.jp/alignment/software/


## RAxML
https://github.com/stamatak/standard-RAxML

This one’s a little complicated. Check the README file before downloading to choose the right version. SSE3 will work on most newer computers and AVX for most recent (see read me for details), and PTHREADS is for running on any computer with more than one core processor (this should be almost all computers).

Download the repository from github, navigat einto the home folder and compile with the command for the right version. For most computers it’s:

    make -f Makefile.SSE3.PTHRADS.gcc

To call the program make sure to add a ./ if in a local directory (instead of from the path).
