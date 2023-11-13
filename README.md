# romgrabber
A simple script to download files from a web directory that matches certain criteria with exclusion words and filenames to ignore.  

Grouping right now is done by PS and not reliable for anything that requires more than one file (i.e. CD images like Disc 2).
However, on initial tests it looks like it's working well enough for cartridge based roms
```
================ Rom Grabber ================
URL - https://www.example.com/files/system/gg/
Download Directory - C:\\Downloads\\GG\\
Files online matched - 158
1: Press '1' to list files matched
2: Press '2' to download missing files
3: Press '3' cleanup download directory
Q: Press 'Q' to quit.
Please make a selection: q
```
Cleanup will update the download directory specified based on the current critera. It will take any files not meeting the criteria and place it in a folder named "other"
