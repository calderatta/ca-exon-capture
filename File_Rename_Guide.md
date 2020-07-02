<<<<<<< HEAD
# File-Rename-Guide

##### Tornabene Lab of Systematics and Biodiversity

Author: Jennifer Gardner 
        University of Washington  
        School of Aquatic and Fisheries Sciences  
        jgardn92@uw.edu

Created: April 15, 2020

Last modified: ~

***
##To Remove the first N Characters from a Filename##
1. Test to see if rename is installed by running `rename -h`
	- If you need to install it run `sudo apt install rename` and input your terminal password
	- Run `rename -h` to make sure installation worked
2. Navigate to the directory you want and run the following `rename -n -v 's/^(.{26})//' *`
	- The `{26}` tells it to remove the first 26 characters
	- the `-n -v` tell it to just show you what it is going to do, aka a preview of how it will rename the files
3. Once you are satisfied that it will rename your files how you want you can run the code without `-v -n` So just run `rename 's/^(.{26})//'`

##To Replace any dashes (-) with underscores (_)##
Run this code:

    for file in *; do mv "$file" `echo $file | tr '-' '_'` ; done

Note: it will give you a list of the names it didn't change saying "filename1" and "filename1" are the same file because there was no dash in the name to change. This is fine.

##For Jenny's Files##
=======
# File-Rename-Guide

##### Tornabene Lab of Systematics and Biodiversity

Author: Jennifer Gardner 
        University of Washington  
        School of Aquatic and Fisheries Sciences  
        jgardn92@uw.edu

Created: April 15, 2020

Last modified: ~

***
##To Remove the first N Characters from a Filename##
1. Test to see if rename is installed by running `rename -h`
	- If you need to install it run `sudo apt install rename` and input your terminal password
	- Run `rename -h` to make sure installation worked
2. Navigate to the directory you want and run the following `rename -n -v 's/^(.{26})//' *`
	- The `{26}` tells it to remove the first 26 characters
	- the `-n -v` tell it to just show you what it is going to do, aka a preview of how it will rename the files
3. Once you are satisfied that it will rename your files how you want you can run the code without `-v -n` So just run `rename 's/^(.{26})//'`

##To Replace any dashes (-) with underscores (_)##
Run this code:

    for file in *; do mv "$file" `echo $file | tr '-' '_'` ; done

Note: it will give you a list of the names it didn't change saying "filename1" and "filename1" are the same file because there was no dash in the name to change. This is fine.

##For Jenny's Files##
>>>>>>> d94109d8f4297ba5fc3c4fd82933f2f1172d036a
Run the first line using rename first because then there will be far fewer dashes for second line to replace.