# Useful Commands
***

## Compressing and extracting folders (or files) using tar

To create and archive...

    tar -czvf name-of-archive.tar.gz /path/to/directory-or-file

To compress multiple items into one archive file, list additional items at the end.

To extract...

    tar -xzvf archive.tar.gz

## Get file (and folder) sizes

    du -sh /path/to/directory-or-file

## Renaming Files

    mv file_name.txt new_name.txt

This can also be used to move files.

To rename parts of a file by substituting characters, you can use.

    rename 's/old_text/new_text/' /path/to/directory-or-file

To delete a certain number of characters from the front end of a file, use.

    rename 's/^(.{number_of_characters})//' *

If you want to test the out put you can add the flags`-n -v` to preview what the output will look like.

## Substituting text in a file

    rename 's/_L001/_L002/' *.fastq

## Counting Fasta files in a directory

    ls -lR /path/to/dir/*.fasta | wc -l

## Counting Sequences in a Fasta file

    grep -c "^>" *.fas

Without -c will only report files that have "^>"

## Sequence lengths in a Fasta file

Reference: https://stackoverflow.com/questions/23992646/sequence-length-of-fasta-file

    awk '/^>/ {if (seqlen){print seqlen}; print ;seqlen=0;next; } { seqlen += length($0)}END{print seqlen}' file.fa

## Remove files based on names in a file

    rm -r `cat list_to_remove.txt`

## Move files listed in a text file

    rsync -a /source/directory --files-from=/full/path/to/listfile /destination/directory

## How to change directory permissions in Linux (for owner only)

https://www.pluralsight.com/blog/it-ops/linux-file-permissions

`chmod +rwx filename` to add permissions.
`chmod -rwx directoryname` to remove permissions.
`chmod +x filename` to allow executable permissions.
`chmod -wx filename` to take out write and executable permissions.
Note that “r” is for read, “w” is for write, and “x” is for execute. 

## Setting Environmental Variables (MAC)

Open up Terminal.
Run the following command: `sudo nano /etc/paths`.
Enter your password, when prompted.
Go to the bottom of the file, and enter the path you wish to add.
Hit control-x to quit.
Enter “Y” to save the modified buffer.
That's it! To test it, in new terminal window, type: `echo $PATH`.
