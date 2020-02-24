# Using MOX HYAK (UW super computer)

Author: Calder Atta  
        University of Washington  
        School of Aquatic and Fisheries Science  
        calderatta@gmail.com

Created: February 21, 2020

Last modified: ~

##### Description
Most of the information was taken from a "Hyak training session!" workshop run by the RCC.

##### Overview
- How to log in to Hyak from all operating systems
- How to transfer data between Hyak, your local machine, and Lolo (Long term storage system)
- Introduction to the Slurm scheduler, and how to submit jobs
- Basic shell commands

***

### Resources

##### Research Computing Club (RCC)
The RCC is a resource for any UW student or postdoc looking to use Hyak. To use the cluster, you will neeed to register for the club and take an online quiz. Follow instructions here: https://depts.washington.edu/uwrcc/getting-started-2/.

The RCC offers workshops on using Hyak every quarter - typically one basic training and one more advanced training. Sign up for the listserve to receve notifications about these workshops. Office hours are also available in the eScience Institute (6th floor of the PAB). Check the calendar to see when these are held: http://depts.washington.edu/uwrcc/calendar/

Slack channel: https://uw-rcc.slack.com/  
Website: https://depts.washington.edu/uwrcc/  
Emails: hpcc@uw.edu or uwrcc@uw.edu  
Office hours: Alternating Tuesdays and Fridays from 1-3 pm  
 

##### Hyak Wiki
Hyak wiki: https://wiki.cac.washington.edu/display/hyakusers/WIKI+for+Hyak+users

The Hyak wiki contains all information on how the System works, is structured, and how to use it. Following pages are very useful and will need to be read before taking the RCC quiz.

File Management: https://wiki.cac.washington.edu/display/hyakusers/Managing+your+Files
Scheduler: https://wiki.cac.washington.edu/display/hyakusers/Hyak+mox+Overview

##### Steven Roberts Lab
The Roberts lab has purchaced nodes on Hyak and you might consider asking to work on their account since they are in the same building and work with similar data. Since we are not a part of their lab, you may need to go through RCC first to activate the computing service on your UW account.

To see who is a member: https://groups.uw.edu/group/de56c82ddfae43d0b847096b17e49a20/member

***

### Understanding supercomputing

##### Unix / Linux system and language
If you are unfamiliar with navigating computer systems using the command line, there are many online resources to get started including YouTube tutourials. Here is one suggestion: https://www.tutorialspoint.com/unix/index.htm

![image](../images/Basic_Bash_commands.pdf)

##### Parallel processing (Cores, Nodes, Threads, and CPUs)
One of the benefits of using a super computer is the ability to split thee workload of a certain task among several different systems. This is calleed parallel processing.

A thread is a single set of instructions, possibly running in parallel or concurrent with other threads.

The concept of 'cores' and 'CPUs' is a bit blurred. By convention, a 'CPU' is a physical device that contains one or more 'cores'.

Each CPU core can run one or more threads concurrently.

The idea of a 'node' is really application specific, but it's usually recognized as a single configured component in some kind of distributed application system. Unlike a CPU or core, a node is a virtual construct (not related to units of hardware) and is just a way to organize and partition computational resources. On Hyak, different groups such as the RCC and the Roberts Lab can purchase a certain number of nodes to use. When run each node uses up a portion of a grid that gets divided up into quarters.

It should be noted that there are different ways to parallelize (eg. running on 1 node but divided amongst 28 cores or running on 1 cores spread accross 4 nodes).

***

### Logging in

After activating Hyak and Lolo on your UW account via a group such as RCC, you should be able to log in using you UW NetID with the following command:

    ssh -X <netID>@mox.hyak.uw.edu

When you log in, you can 
- Loging into cluster using cluster -> you "land"  on a login node
- Want to send jobs from login node to computing node (no internet access)
- Build nodes are eused for things like compiling large software (access to internet)
- Build is similar to Computation node but reserved for software and access to internet

      ssh -X <netID>@mox.hyak.uw.edu

- -X forwards graphics to your computer

> ently added the ECDSA host key for IP address '198.48.92.25' to the list of known hosts.
>Password: 
>Enter passcode or select one of the following options:
>
> 1. Duo Push to iOS (XXX-XXX-2586)
> 2. Phone call to iOS (XXX-XXX-2586)
>
> Duo passcode or option [1-2]: 1
> Warning: untrusted X11 forwarding setup failed: xauth key data not generated
>          __  __  _____  __  _  ___   ___   _  __
>         |  \/  |/ _ \ \/ / | || \ \ / /_\ | |/ /
>         | |\/| | (_) >  <  | __ |\ V / _ \| ' < 
>         |_|  |_|\___/_/\_\ |_||_| |_/_/ \_\_|\_\
> 
>    This login node is meant for interacting with the job scheduler and 
>    transferring data to and from Hyak. Please work by requesting an 
>    interactive session on (or submitting batch jobs to) compute nodes.
> 
>    Visit the Hyak user wiki for more details:
>    http://wiki.hyak.uw.edu/Hyak+mox+Overview
> 
>    Questions? E-mail help@uw.edu with "hyak" in the subject.
> 
>    Run "scontrol show res" to see any reservations in place that will 
>    prevent your jobs from running with a "(ReqNodeNotAvail,*" error.
> Could not create directory '/usr/lusers/catta11/.ssh': No space left on device
> Saving key "/usr/lusers/catta11/.ssh/id_rsa" failed: No such file or directory
> cp: cannot stat ‘/usr/lusers/catta11/.ssh/id_rsa.pub’: No such file or directory

- now you are on node `mox2`

Transferring files

      scp path/to/file catta11@mox.hyak.uw.edu/put/desired/location/

- use -r for folders

Loading Software

- see what is available on MOX (this will be a giant list). contrib/ are ones ppl have added

      module avail

- search for specific program

      module 

- only want to use ones that you are specifically going to use. check what you have: ()

      module list

- to install new module: (a little complicated but can use website)

      module .......

- Can think about custom PATHs

      vi ~/.bash_profile
      call by using $CUSTOM_PATH

- Use `numba` for parallel Python

Accessing the Computing Node (submitting job)

- Slurm schedules everything including prioritizing jobs
- Check all jobs on stf

      squeue -p stf

- Check only your jobs

      squeue -u <netID> --long

- PD = pending (check nodes requested)
- R = running (check nodes using to guage for future)

- factors to decide how many nodes - more than that if parallel processing
- if not just 1 node and 1 CPU
- multiple types of parallelizing
  - 1 node and 28 cores
  - 
- Check all jobs queued on stf

      sinfo -p psicenter

- shows what nodes are available and not


#!/bin/bash 
## Job Name 
#SBATCH --job-name=test-job
## Allocation Definition
#SBATCH --account=MYSHORTGROUP <----- short (-a XXX)
#SBATCH --partition=MYSHORTGROUP <----- short (-p XXX)
## Resources 
## Nodes 
#SBATCH --nodes=2       
## Tasks per node (Slurm assumes you want to run 28 tasks, remove 2x # and adjust parameter if needed)
###SBATCH --ntasks-per-node=28 
## Walltime (two hours) 
#SBATCH --time=2:00:00 
# E-mail Notification, see man sbatch for options
 
##turn on e-mail notification
#SBATCH --mail-type=ALL
#SBATCH --mail-user=your_email_address

## Memory per node 
#SBATCH --mem=100G 
## Specify the working directory for this job 
#SBATCH --chdir=/gscratch/MYGROUP/MYUSER/MYRUN 

module load icc_<version>-impi_<VERSION> 
export OMP_NUM_THREADS=1 <----- this is not included in template
mpirun /gscratch/MYGROUP/MYMODEL/MYMODEL-BIN <----- need to use this if you are parallelizing over multiple nodes



## I. How to log in to Hyak from all operating systems

##### 1. 

## II. How to transfer data between Hyak, your local machine, and Lolo (Long term storage system)

## III. Introduction to the Slurm scheduler, and how to submit jobs

## IV. Basic shell commands

***

## I. Hyak tutorial


*** *THIS SECTION NEEDS TO BE UPDATED* ***
