# Guide to Using the Super Computer at SHOU
Last Updated: 2019-01-08

***

## Location

Lab directory:  `/home/users/cli/`
Personal directory:  `/home/users/cli/ocean/Calder/`

## Cyberduck Access

Cyberduck is a remotecomputing client that allows easy navigation, imspecting, uploading, and downloading of files. For easy use, drag and drop files. However, all commands must be run through the command line.

Name: cli - SFTP  
Address: 202.121.66.105  
Port: 38174  
User Name: cli  
Password: Li_08012012

## Commandline Access

##### Remote access via intermediate server (skip if logged in to SHOU network locally)

    ssh cli@58.198.131.182 -p 38174

Password: `friends2016`

You may recieve a promt asking if you want to continue. Enter `yes`. Enter the password.

##### Log in to computer

    ssh cli@hpca.fvcom.org

Password: `Li_08012012`

You may recieve a promt asking if you want to continue. Enter `yes`. Enter the password.

You should now be in the computer at `/home/users/cli/`.

## Running a job (for intensive tasks)

##### run_job.sh

Location: `cd /home/users/cli/ocean/Calder/`

    #!/bin/bash

    #PBS -l nodes=1:ppn=24
    #PBS -l walltime=240:00:00
    #PBS -N CA_trim
    #PBS -q avant

    cd /home/users/cli/ocean/Calder/

    [ENTER COMMAND HERE]

    exit 0

Use `#PBS -l nodes=1:ppn=24` to control how many nodes to run the job on. To do this change the ppn value. Wall time (change in `#PBS -l walltime=240:00:00`) is the maximum time a job is allowed to run. Change the name of the job using `#PBS -N [NAME]`. Select the size of the job with `#PBS -q avant`. `avant` is the largest size and has 24 cores. `small` uses 12 cores.

##### Edit command

Select `run_job.sh` and press `Edit`. Substitute `[ENTER COMMAND HERE]` with the desired command. Close.

##### Run the job

    cd /home/users/cli/ocean/Calder/
    qsub run_job.sh

## Check on a run

    qstat

Output will look something like:

    Job ID                    Name             User            Time Use S Queue
    ------------------------- ---------------- --------------- -------- - -----
    24174.mgma                 bwa-map          cli             00:00:39 R small
    24374.mgma                 ...rthologues.sh cli             00:31:10 R small
    24391.mgma                 hzw_red_0105     jlin            1072:25: R middle
    24404.mgma                 sbqt             hu_student      795:49:0 R small
    24409.mgma                 bwa-aln          cli             00:00:39 R small
    24410.mgma                 bwa-map          cli             00:00:20 R avant
    24412.mgma                 sbqt             hu_student      621:27:3 R small
    24425.mgma                 CA_assemble      cli             415:58:1 R avant

## Cancel a job

    qdel [job number]

eg. job number = 24425

## File Transfer (if Cyberduck is not working)

If you urgently need to download data, you can download file by the command `scp`, which can copy files from remote to local directory and vice versa. It is used like `cp`. For example:

##### Transfer from remote to local

First, log into intermediate server

    ssh cli@58.198.131.182 -p 38174

Password: `friends2016`  
Then copy "file.txt" to current directory:

    scp cli@hpca.fvcom.org:/home/users/cli/ocean/Calder/file.txt ./

Now it has been download to cli@58.198.131.182:/home/cli/.

Password: `Li_08012012`  
Then, open a new terminal and type in following command to download file from intermediate server to your laptop:

    scp -P 38174 cli@58.198.131.182:/home/cli/file.txt /your/local/path/

Password: `friends2016`  
Compress folders before downloading, and most importantly, remember to delete file on intermediate server!

##### Transfer from local to remote

Similar to above...

    scp -P 38174 /your/local/path/file.txt cli@58.198.131.182:/home/cli/
    ssh cli@58.198.131.182 -p 38174
    scp ./file.txt cli@hpca.fvcom.org:/home/users/cli/ocean/Calder/
    
