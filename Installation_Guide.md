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
- Perl
- Pipeline Scripts
- Pipeline Dependencies

***
## Pipeline Perl Scripts
***


***
## Setting environmental variables ($PATH)
***

## Windows


## MAC
1. Open up Terminal.
2. Run the following command:

    sudo nano /etc/paths.
    
3. Enter your password, when prompted.
4. Go to the bottom of the file, and enter the path you wish to add.
5. Hit control-x to quit.
6. Enter “Y” to save the modified buffer. Hit Enter.
7. That's it! To test it, in new terminal window, type:

    echo $PATH

***
## Perl
***
You must have Perl installed to use this pipeline. Mac computers come with Perl already installed. To test if Perl is installed run:

    perl --version

If you receve a message with the version, then perl is installed. If you get an error saying that perl cannot be found then you need to install it.

perl.prg/geet.html#win32

If perl gives you an error saying "Can't locate XXX in @INC" you may need to change the @INC array. @INC works like $PATH, but for Perl. See this page for help: perlmaven.com/how-to-change-inc-to-find-perl-modules-in-non-standard-locations

@INC on OVert computer:
@INC = C:\Program Files\Git\
eg. @INC\usr\share\perl5\core_perl = C:\Program Files\Git\usr\share\perl5\core_perl


***
## Pipeline Script Dependencies
***

## PAUP

http://phylosolutions.com/paup-test/

Download the binary version.
Navigate to the file and expand with:

    gunzip paupa***
    
Rename as `paup`
You will probably need to give permissions in order to excturee this file.

    chmod a+x paup

Move to $PATH

## Perl Modules
To install use:

    cpan Parallel::ForkManager

I tried this but I'm not sure if it worked. Instead I downloaded each module directly from mata:cpan. - CA

- Parallel::ForkManager (https://metacpan.org/pod/Parallel::ForkManager)
- Moo (https://metacpan.org/pod/Moo)
- Sub::Quote (https://metacpan.org/pod/Sub::Quote)
- Bio::Seq (https://metacpan.org/pod/Bio::Seq)
- Statistics::Distributions (https://metacpan.org/release/Statistics-Distributions)

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
