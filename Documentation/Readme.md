# Lift & Shift



### When the script is triggered it will do the following steps:

1. Initialize the Parameters.Json file into memory.
1. Start a powershell Transcript.
1. Create a new log file if necessary.
1. Start running through the 'module' functions where each module contains the following steps:
   1. Define parameters used within the function.
   1. Check whether the source directory contains a flag file OR Check if the source directory is empty.
   1. Check whether or not the legacy destination will be used.
   1. Loop through each Source and Destination doing the following steps:
      1. Copy each file from the current source to the current destination
      1. Check if the copy action was successful by comparing MD5 hashes of the source and destination files.
      1. Delete either the source files when everything went according to plan or remove the destination files if the copy has failed.
 1. Exit

**_Each of the above steps is logged into the log file with with a timestamp_
 

## Usage
You can run the following commands in a Powershell terminal;
```powershell
#get your terminal to the correct directory by replacing $location with the path of the script folder
##for production env:
cd ./$location/DWHLiftNShiftPRD
##for acceptation env:
cd ./$location/DWHLiftNShiftACC


#dot source the script from the directory
##for production env:
./main-prd.ps1
##for acceptation env:
./main-acc.ps1
```

## Contributing
The script is hosted in the following AzureDevops [Repository]()
  
If you want to contribute to the script, feel free to open a new feature branch.

When adding new module functions; please refer to the template functions to copy the correct template, after which you can change the name and the first word of the parameter key to something unique to that new function

## Troubleshooting
When troubleshooting the best course of action is to open the application within vscode, use the shortcut to fold all and then use find to unfold the method functions that had error logging in the log file. from there you can place break points and run a debug session.


## Tips
- Use the following VSCode extension: [Better Comments](https://marketplace.visualstudio.com/items?itemName=aaron-bond.better-comments) To have a nicer experience when reading the script
 




### Created by Dave Wolfs for Obvion N.V.
