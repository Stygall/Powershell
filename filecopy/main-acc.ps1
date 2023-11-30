#! for more readable comments please use the following VSCode extension: aaron-bond.better-comments

#* ========================================================[ GLOBAL VARIABLES ]======================================================== *#
$Time = get-date                        #this gets the current date and time and turns it into a variable
$ParamPath = ".\Input\Parameters.json"    #this is the location of the 'Parameters.json' file


#* ========================================================[ DATA ACCESS LIBRARY ]======================================================== *#
function Get-Params {
    #? The following function converts the parameter file into a readable powershell object
    param (
        [string] $ParamPath                                 #this is the location of the parameter file
    )
    
    $Params = Get-Content $ParamPath | ConvertFrom-Json     #here it does the above

    return $Params                                          #here it returns the parameter object to be used by the script
}
function Approve-NewFile {
    #? the following function checks whether or not a new file needs to be created
    param (
        [string]$Path           #this is the supposed path of the log file
    )

    $File = Test-Path $Path     #here it checks whether or not there already is a log file

    return $file                #here it returns a boolean value where 'false' means the file doesn't exist yet. and 'true' means that a file already exists       
}

#logging CRUD   
function New-Log {
    #? The following function initializes a new logging document
    param (
        [string]$LogPath                            #this defines the location of the log file
    )
    
    New-Item $logPath                               #here it creates a log file
    Set-Content $logPath 'Initiated new log file'   #here it creates the first sentence of the logfile
}
function Add-Log {
    #? The following function appends the log file
    param (
        [string]$LogText,           #this is the content of the log file
        [string]$LogPath            #this defines the location of the log file
    )
    Add-Content $LogPath $LogText   #here it appends the text within the log file
}

#generic CRUD functions
function Copy-Files {
    #? the following function is used to sync files between two directories
    param (
        [string]$Source,                                        #this is the location of the source folder
        [string]$Destination                                    #this is the destination path
    )
    
    (Get-ChildItem -path $Source).FullName | ForEach-Object {   #here it loops through every source file to ready it for copying
        if ($_ -NotLike "*.flag" ) {                            #it will check if the file is a flag file
            Copy-Item $_ -Destination $Destination         #if not it copies from a source path to a destination path
        }
    }
    
}
function Compare-Files{
    #? the following function is used to compare source and destination files through hash checksums, using the MD5 algorithm
    param (
        [string]$Source,                                                                                    #this is the location of the source folder
        [string]$Destination                                                                                #this is the destination path
    )

    $SourceFiles = @()                                                                                      #here it builds an empty array for the source paths
    $SourceHashes = @()                                                                                     #here it builds an empty array for the source hashes
    $DestinationFiles = @()                                                                                 #here it builds an empty array for the destination paths
    $DestinationHashes = @()                                                                                #here it builds an empty array for the destination hashes

    (Get-ChildItem -path $Source).FullName | ForEach-Object {                                               #here it will take all the files in the source directory and loop through them 
        $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider                   #here it will establish what an MD5 hash is
        $Hash = [System.BitConverter]::ToString($MD5.ComputeHash([System.IO.File]::ReadAllBytes($_)))       #here it will convert every file to an MD5 hash code
        $SourceHashes += $Hash 
        $SourceFiles += $_                                                                                  #here it will add that hash to an array so both locations can be compared
    }
    
    (Get-ChildItem -path $Destination).FullName | ForEach-Object {                                          #here it will take all the files in the destination directory and loop through them
        $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider                   #here it will establish what an MD5 hash is
        $Hash = [System.BitConverter]::ToString($MD5.ComputeHash([System.IO.File]::ReadAllBytes($_)))       #here it will convert every file to an MD5 hash code
        $DestinationHashes += $Hash  
        $DestinationFiles += $_                                                                             #here it will add that hash to an array so both locations can be compared
    }

    if ($SourceHashes -eq $DestinationHashes) {                                                             #here it checks whether there is a difference between the source files and the destination files to see if a file has been corrupted or otherwise
        $Check = $true                                                                                      #when successful it will turn the check bool true
        return @($Check)                                                                                    #and then return it in an array with the check bool on index 0
    }
    
    elseif ($DestinationHashes.Length -eq $SourceHashes.Length ){       #here it checks if they do not match due to a difference in length, and if that difference is caused by a flag
        $Check = $true                                                                                      #when successful it will turn the check bool true
        return @($Check)
    }

    else {  
        $OkFiles = @()  
        $CorruptFiles = @()                                                                                              
        foreach ($File in $DestinationFiles) {                                                              #here it will iterate through all the destination files
            $Index = $DestinationFiles.IndexOf($File)                                                       #then take the index of each path
            if ($SourceHashes[$Index] -ne $DestinationHashes[$Index]) {                                     #using that index to compare the source and destination hashes
                $CorruptFiles += $File                                                                      #a file that does not have two identical hashes will then be added to an array for later removal
            }
            else {
                $OkFiles += $SourceFiles[$Index]                                                            #here it adds the source path of a non-corrupt file
            }
        }
        return @($Check, $CorruptFiles, $OkFiles)                                                           #it will then return an array with the check bool and an array of corrupt files
    }
}

function Remove-Source {
    #? the following function is used to remove all left over files from the source directory when a copy action went ok
    param (
        [string]$Source                                             #this is the location of the source folder
    )
    
    (Get-ChildItem -path $Source).FullName | ForEach-Object {       #it will iterate over every file in the source directory                                           
        Remove-Item $_                                              #and then remove the file from the location
    }
    
}

function Remove-Mistakes {
    #? the following function is used to remove all corrupt files
    param (
        [array]$CorruptFiles                #this is an array of files that have not been transfered correctly
    )

    foreach ($File in $CorruptFiles) {      #it will iterate over every corrupt file in the array                                           
        Remove-Item $File                   #and then remove the file from the location
    }
}

function Remove-Successes{
    #? the following function is used to remove all non-corrupt files
    param (
        [array]$OkFiles                #this is an array of files that have not been transfered correctly
    )

    foreach ($File in $OkFiles) {      #it will iterate over every corrupt file in the array                                           
        Remove-Item $File              #and then remove the file from the location
    }
}

#flag functions
function Find-Flag {
    #? the following function is used to find flag files in the source directory
    param (
        [string]$Source                                             #this is the location of the source folder
    )
    
    (Get-ChildItem -path $Source).FullName | ForEach-Object {       #iterate through the directory
        if ($_ -like "*.flag" ) {                                   #it will check if the memorised flag exists in the source directory
            $Counter += 1                                           #and return true if it does
        }
    }

    if ($Counter -gt 0) {                                           #here it checks if one or more flags have been found
        return $true                                                #if so it will return a true value
    }

    else {
        return $false                                               #otherwise it will return an false value
    }
    
}

function Remove-Flags {
    #? the following function is used to remove all flag files 
    param (
        [string]$Source,                                                #this is the location of the source folder
        [string]$Destination                                            #this is the location of the source folder
    )

    (Get-ChildItem -path $Source).FullName | ForEach-Object {           #iterate through the directory
        $FlagPath = $_ + "*.flag"                                       #identify what a flag looks like
        
        if (test-path $FlagPath) {                                      #check if the file is indeed a flag
            Remove-Item $FlagPath                                       #and then remove the flag from the location
        }
    }

    (Get-ChildItem -path $Destination).FullName | ForEach-Object {      #iterate through the directory
        $FlagPath = $_ + "*.flag"                                       #identify what a flag looks like
        
        if (test-path $FlagPath) {                                      #check if the file is indeed a flag
            Remove-Item $FlagPath                                       #and then remove the flag from the location
        }
    }
}


#* ========================================================[ LOGGING FUNCTIONS ]======================================================== *#

function Write-Log {
    #? The following function takes in the parameters that together build the text for the upcoming log
    param (
        [string]$LogText,                   #this is the content of the log file
        [string]$Time                       #this is the current time and date which will be the start of a log entry
    )
   
    $Log = $Time + '    log: ' + $LogText   #here it builds the text for the logging
    
    return $Log                             #here it returns the text so it can be appended to the log file
}

function Start-Logging {
    #? The following function starts the logging procedure
    param (
        [string]$LogPath,                   #this is an object filled with all the locations in 'Params.json'
        [string]$Time                       #This is the current time
    )

    $LogText = 'Script initiated...'        #here it initalises the creation of the first log text
    $NewFile = Approve-NewFile $LogPath     #here it checks if it needs to make a new log file

    if ( $NewFile -ne $true){               #if a log file has not already been created the script will create a new one
        New-log $LogPath                    #here it initialises creating a new log file
    }
    
    Add-Log $Time $LogPath                  #here it communicates when the script started to the log file
    Add-log $LogText $LogPath               #here it initialises appending the existing logfile

    return $LogPath
}


#* ========================================================[ MODULES ]======================================================== *#

function Invoke-Test {
    #? the following function is used to run testing on normal folders
    param (
        [System.Object]$Params,                                 #This is an object filled with all the locations in 'Params.json'
        [string]$Time,                                          #this is the current time and date which will be the start of a log entry
        [string]$LogPath                                        #this defines the location of the log file
    )
    
    $LogText = "Initiate Test Module"
    Add-Log $LogText $LogPath                                   #it will now log that it has started a new module
    $Source = $Params.TestSourcePath                            #here it loads the file path for the source destination into a variable
    $DestinationB = $Params.TestDestinationPathB                #here it tries to load the file path for destination B if possible

    #! this bit is errorhandling that will check whether or not the module can be skipped due to the source directory being empty
    if ((Get-ChildItem -Path $Source -Force | Measure-Object).Count -eq 0) {
        $LogText = "Source files not found...     `nCancelling module operation.."
        Add-Log $LogText $LogPath                               #it will now log that it has not found (enough) flag files
    } 

    else {
        if ($DestinationFlag -eq $false){                       #here it checks whether the A destination has been disabled
            $LogText = 'Trying to copy all files from source ' + $Source + ' to Destination ' + $DestinationB 
            Add-Log $LogText $LogPath                           #here it writes down a log that it is going to do a copy move
            Copy-Files $Source $DestinationB                    #here it initializes copying all files from the source to the given destinations
            $LogText = "Finished Copying from " + $Source + " towards "   + $Destination + " `nInitialising MD5 security check"
            Add-Log $LogText $LogPath                           #here it writes down the log that it finished the copy job and will start to check if the files are not corrupted
            $Ok = Compare-Files $Source $Destination
            
            if ($Ok[0] -eq $true) {
                $LogText = "MD5 security check successful! `nNow starting the removal of source files"
                Add-Log $LogText $LogPath                       #it will now log that it was successful and that it will purge the remaining source files
            }
            
            else{
                $CorruptFiles = $Ok[1]                          #it will log all the paths of the corrupt files into a new array
                $OkFiles = $Ok[2]                               #it will log all the paths of the non-corrupt files into a new array
                $LogText = "MD5 security check unsuccessful! `nThere were" + $CorruptFiles.Count + " corrupt files found `nNow starting the removal of corrupt files"
                Add-Log $LogText $LogPath                       #after which it will then log that the check was unsuccessful and how many corrupt files there were. and that it will remove them
            }
        }
        
        else{                                                   #otherwise it will use both destination A and B
            $DestinationA = $Params.TestDestinationPathA        #here it loads the file path for destination A into a variable
            $Destinations = $DestinationA, $DestinationB        #here it builds an array based on both the given destinations
            $LogText = 'Trying to copy all files from source ' + $Source + ' to Destinations ' + $Destinations
            Add-Log $LogText $LogPath                           #here it writes down a log that it is going to do a copy move
            
            foreach ($Destination in $Destinations){            #here it loops through every possible destination to perfom a copy, compare and remove action
                Copy-Files $Source $Destination                 #here it initializes copying all files from the source to the given destinations
                $LogText = "Finished Copying from " + $Source + " towards "   + $Destination + " `nInitialising MD5 security check"
                Add-Log $LogText $LogPath                       #here it writes down the log that it finished the copy job and will start to check if the files are not corrupted
                $Ok = Compare-Files $Source $Destination        #here it will initialize a compare functions that will test for corrupt files
                
                if ($Ok[0] -eq $true) {
                    $LogText = "MD5 security check successful! `nNow starting the removal of source files"
                    Add-Log $LogText $LogPath                   #it will now log that it was successful and that it will purge the remaining source files
                }
                
                else{
                    $CorruptFiles = $Ok[1]                      #it will log all the paths of the corrupt files into a new array
                    $OkFiles = $Ok[2]                           #it will log all the paths of the non-corrupt files into a new array
                    $LogText = "MD5 security check unsuccessful! `nThere were" + $CorruptFiles.Count + " corrupt files found `nNow starting the removal of corrupt files"
                    Add-Log $LogText $LogPath                   #after which it will then log that the check was unsuccessful and how many corrupt files there were. and that it will remove them
                }
            }   
        }

        if ($Ok[0] -eq $true){
            Remove-Source $Source                               #this will initiate the removal of all source material
        }

        else {
            Remove-Mistakes $CorruptFiles                       #this will initiate the removal of all corrupt files
            Remove-Successes $OkFiles                           #this will initiate the removal of all non-corrupt files
        }

        $LogText = "Cleanup successful! `nModule Complete"
        Add-Log $LogText $LogPath                               #it will now log that it has finished the module 
    }
}

function Invoke-FlagTest {
    #? the following function is used to run testing on folders that use flagging
    param (
        [System.Object]$Params,                                 #This is an object filled with all the parameters
        [string]$Time,                                          #this is the current time and date which will be the start of a log entry
        [string]$LogPath                                        #this defines the location of the log file
    )
    
    $LogText = "Initiate Flag Test Module"
    Add-Log $LogText $LogPath                                   #it will now log that it has started a new module
    $Source = $Params.TestFlagSourcePath                            #here it loads the file path for the source destination into a variable                                     
    $FindFlag = Find-Flag $Source $Target                       #here it will initiate a search for flag files in the source directory
    
    if ($FindFlag -eq $false) {                                 #if there is no flag found it will end the module after the next log
        $LogText = "Flag files not found...     `nCancelling module operation.."
        Add-Log $LogText $LogPath                               #it will now log that it has not found (enough) flag files
    }
    
    else {
        
        $DestinationB = $Params.TestFlagDestinationPathB            #here it loads the file path for destination B into a variable
        if ($DestinationFlag -eq $false) {                       #here it checks whether the A destination has been disabled
            $LogText = 'Trying to copy all files from source ' + $Source + ' to Destination ' + $DestinationB 
            Add-Log $LogText $LogPath                           #here it writes down a log that it is going to do a copy move
            Copy-Files $Source $DestinationB                    #here it initializes copying all files from the source to the given destinations
            $LogText = "Finished Copying from " + $Source + " towards "   + $DestinationB + " `nInitialising MD5 security check"
            Add-Log $LogText $LogPath                           #here it writes down the log that it finished the copy job and will start to check if the files are not corrupted
            $Ok = Compare-Files $Source $DestinationB
            
            if ($Ok[0] -eq $true) {
                $LogText = "MD5 security check successful! `nNow starting the removal of source files"
                Add-Log $LogText $LogPath                       #it will now log that it was successful and that it will purge the remaining source files
            }
            
            else{
                $CorruptFiles = $Ok[1]                          #it will log all the paths of the corrupt files into a new array
                $OkFiles = $Ok[2]                               #it will log all the paths of the non-corrupt files into a new array
                $LogText = "MD5 security check unsuccessful! `nThere were" + $CorruptFiles.Count + " corrupt files found `nNow starting the removal of corrupt files"
                Add-Log $LogText $LogPath                       #after which it will then log that the check was unsuccessful and how many corrupt files there were. and that it will remove them
            }
        }

        else {                                                   #otherwise it will use both destination A and B
            $DestinationA = $Params.TestFlagDestinationPathA        #here it tries to load the file path for destination A if possible
            $Destinations = $DestinationA, $DestinationB        #here it builds an array based on both the given destinations
            $LogText = 'Trying to copy all files from source ' + $Source + ' to Destinations ' + $Destinations
            Add-Log $LogText $LogPath                           #here it writes down a log that it is going to do a copy move
            
            foreach ($Destination in $Destinations){            #here it loops through every possible destination to perfom a copy, compare and remove action
                Copy-Files $Source $Destination                 #here it initializes copying all files from the source to the given destinations
                $LogText = "Finished Copying from " + $Source + " towards "   + $Destination + " `nInitialising MD5 security check"
                Add-Log $LogText $LogPath                       #here it writes down the log that it finished the copy job and will start to check if the files are not corrupted
                $Ok = Compare-Files $Source $Destination
                
                if ($Ok[0] -eq $true) {
                    $LogText = "MD5 security check successful! `nNow starting the removal of source files"
                    Add-Log $LogText $LogPath                   #it will now log that it was successful and that it will purge the remaining source files
                }
                else{
                    $CorruptFiles = $Ok[1]                      #it will log all the paths of the corrupt files into a new array
                    $OkFiles = $Ok[2]                           #it will log all the paths of the non-corrupt files into a new array
                    $LogText = "MD5 security check unsuccessful! `nThere were" + $CorruptFiles.Count + " corrupt files found `nNow starting the removal of corrupt files"
                    Add-Log $LogText $LogPath                   #after which it will then log that the check was unsuccessful and how many corrupt files there were. and that it will remove them            
                }
            }   
        }

        if ($Ok[0] -eq $true) {
            Remove-Source $Source                               #this will initiate the removal of all source material
            $LogText = "File removal successful! `nNow starting the removal of flags"
            Add-Log $LogText $LogPath                           #it will then log that it is done removing corrupt files, and that it will start removing the flags
            Remove-Flags $Source $DestinationB                  #this will start removing the flags
        }

        else {
            Remove-Mistakes $CorruptFiles                       #this will initiate the removal of all corrupt files
                    Remove-Successes $OkFiles                   #this will initiate the removal of all non-corrupt files
                    $LogText = "File removal successful! `nRemoval of flags will be skipped"
                    Add-Log $LogText $LogPath                   #it will then log that it is done removing corrupt files, and that it will not start removing the flags
        }

        $LogText = "Cleanup successful! `nModule Complete"
        Add-Log $LogText $LogPath                               #it will now log that it has finished the module 
    }
}

function Invoke-Modules {
    #? the following function is used to start every module in sequence
    param (
        [System.Object]$Params,              #This is an object filled with all the parameters
        [string]$LogPath,                    #this defines the location of the log file
        [string]$Time                        #this is the current time and date which will be the start of a log entry
    )                                     
    Invoke-Test $Params $Time $LogPath       #here it initializes moving the test files
    Invoke-FlagTest $Params $Time $LogPath   #here it initializes moving the test files which use flags
}


#* ========================================================[ MAIN ]======================================================== *#

#? The script will start by loading in all the parameters 
$Params = Get-Params $ParamPath                              #firstly all parameters get loaded into memory

#? And use them to create a couple flags
$DestinationFlag = $true                                     #this flag determines whether or not source files will be copied to both the A and B destinations

#? It will then start a transcript and a log file
$TranscriptPath = $Params.TranscriptPath                     #here it selects the right location used for the transcript file
Start-Transcript -Path $TranscriptPath -Append -Force        #here it starts writing a transcript

Start-Logging $Params.LogPath $Time                          #doing routine tasks to check in the logfile

#? After which it will start going through the modules
Invoke-Modules $Params $Params.LogPath $Time                 #here it starts the modules that will dictate the movement of the files

#? when finished it will make one last log message
$LogText = "Script finished `n" + $Time                     
Add-Log $LogText $Params.LogPath                             #when finished with all the modules it will log that it has finished running and stamp on an end time