#! for more readable comments please use the following VSCode extension: aaron-bond.better-comments
#! also for readability you might want to consider pressing "CTRL + K + 0" to fold all functions.

#? the corresponding documentation can either be found in the Readme.md file or in confluence: https://itility.atlassian.net/wiki/spaces/ICCF/pages/3682336977/WIP+-+O+DWH+Lift+Shift

#* ========================================================[ GLOBAL VARIABLES ]======================================================== *#
$ParamPath = ".\Input\Parameters.json"      #this is the location of the 'Parameters.json' file
$Mistake = $false                           #this determines that the default state is that a module made no mistake
$global:DestinationFlag = $true             #this flag determines whether or not source files will be copied to both the A and B destinations


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
            Copy-Item $_ -Destination $Destination              #if not it copies from a source path to a destination path
        }
    }
    
}
function Compare-Files{
    #? the following function is used to compare source and destination files through hash checksums, using the MD5 algorithm
    param (
        [string]$Source,                                                                                        #this is the location of the source folder
        [string]$Destination                                                                                    #this is the destination path
    )

    $SourceFiles = @()                                                                                          #here it builds an empty array for the source paths
    $SourceHashes = @()                                                                                         #here it builds an empty array for the source hashes
    $DestinationFiles = @()                                                                                     #here it builds an empty array for the destination paths
    $DestinationHashes = @()                                                                                    #here it builds an empty array for the destination hashes

    try{
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
    }
    catch [System.IO.IOException]{
        (Get-ChildItem -path $Source).FullName | ForEach-Object {                                               #here it will take all the files in the source directory and loop through them 
            $Hash = (Get-FileHash -Path $_ -Algorithm MD5).Hash.ToLower()                                       #here it will convert every file to an MD5 hash code
            $SourceHashes += $Hash                                                                              #here it will add that hash to an array so both locations can be compared
            $SourceFiles += $_                                                                                  #here it adds the file to an array for later usage
        }
        
        (Get-ChildItem -path $Destination).FullName | ForEach-Object {                                          #here it will take all the files in the destination directory and loop through them
            $Hash = (Get-FileHash -Path $_ -Algorithm MD5).Hash.ToLower()                                       #here it will convert every file to an MD5 hash code
            $DestinationHashes += $Hash                                                                         #here it will add that hash to an array so both locations can be compared
            $DestinationFiles += $_                                                                             #here it adds the file to an array for later usage
        }
    }

    if ($SourceHashes -eq $DestinationHashes) {                                                                 #here it checks whether there is a difference between the source files and the destination files to see if a file has been corrupted or otherwise
        $Check = $true                                                                                          #when successful it will turn the check bool true
        return @($Check)                                                                                        #and then return it in an array with the check bool on index 0
    }
    

    else {                                                                                                      #here it will start looking which files differ between source and destination                  
        $OkFiles = @()                                                                                          #here it builds an empty array for the non-corrupt files
        $CorruptFiles = @()                                                                                     #here it builds an empty array for the corrupt files                                                                                           
        foreach ($File in $DestinationFiles) {                                                                  #here it will iterate through all the destination files
            $Index = $DestinationFiles.IndexOf($File)                                                           #then take the index of each path
            if ($SourceHashes[$Index] -ne $DestinationHashes[$Index]) {                                         #using that index to compare the source and destination hashes
                $CorruptFiles += $File                                                                          #a file that does not have two identical hashes will then be added to an array for later removal
            }
            else {
                $OkFiles += $SourceFiles[$Index]                                                                #here it adds the source path of a non-corrupt file
            }
        }
        return @($Check, $CorruptFiles, $OkFiles)                                                               #it will then return an array with the check bool and an array of corrupt files
    }
}

function Remove-Files {
    #? the following function is used to remove all left over files from the source directory when a copy action went ok
    param (
        [string]$Source,                                                #this is the location of the source folder
        [array]$OkFiles,
        [array]$CorruptFiles,
        [bool]$Mistake
    )
    
    if($Mistake -eq $false) {
        (Get-ChildItem -path $Source).FullName | ForEach-Object {       #it will iterate over every file in the source directory                                           
                Remove-Item $_                                          #and then remove the file from the location
        }
    }
    else {
        foreach ($File in $CorruptFiles) {                              #it will iterate over every corrupt file in the array                                           
            Remove-Item $File                                           #and then remove the file from the location
        }
        foreach ($File in $OkFiles) {                                   #it will iterate over every corrupt file in the array                                           
            Remove-Item $File                                           #and then remove the file from the location
        }
    }
    
}

#flag functions
function Find-Flag {
    #? the following function is used to find flag files in the source directory
    param (
        [array]$Sources                                             #this is the location of the source folder
    )
    
    foreach ($Source in $Sources) {
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
    
}


#* ========================================================[ LOGGING FUNCTIONS ]======================================================== *#

function Write-Log {
    #? The following function takes in the parameters that together build the text for the upcoming log
    param (
        [string]$LogText                   #this is the content of the log file
    )
   
    $Log = $(Get-Date).ToString() + ': log: ' + $LogText   #here it builds the text for the logging
    
    return $Log                             #here it returns the text so it can be appended to the log file
}

function Start-Logging {
    #? The following function starts the logging procedure
    param (
        [string]$LogPath                    #this is an object filled with all the locations in 'Params.json'
    )

    $LogText = $(Get-Date).ToString() + ': Script initiated...'
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
        [System.Object]$Params                                                      #This is an object filled with all the locations in 'Params.json'
    )
    
    $LogText = $(Get-Date).ToString() + ": Initiate Test Module"
    Add-Log $LogText $Params.LogPath                                                #it will now log that it has started a new module
    $Source = $Params.TestSourcePath                                                #here it loads the file path for the source destination into a variable
    $DestinationB = $Params.TestDestinationPathB                                    #here it tries to load the file path for destination B if possible
    $count = 0
    #! this bit is errorhandling that will check whether or not the module can be skipped due to the source directory being empty
    if ((Get-ChildItem -Path $Source -Force | Measure-Object).Count -eq 0) {        #here it checks if there are files in the source directory 
        $count += 1                                                                 #it will now log that it has not found (enough) flag files
    } 
    if ($count -gt 0) {                                                             #if the source directories are empty it wil cancell the module
        $LogText = $(Get-Date).ToString() +  ": Source files not found...     `n" + $(Get-Date).ToString() + ": Cancelling module operation.."
        Add-Log $LogText $Params.LogPath
    }
    else {
        if ($DestinationFlag -eq $false){                                           #here it checks whether the A destination has been disabled
            $Destinations = @($DestinationB )                                       #here it builds an array based on both the given destinations
        }
        else{                                                                       #otherwise it will use both destination A and B
            $DestinationA = $Params.TestDestinationPathA                            #here it loads the file path for destination A into a variable
            $Destinations = @($DestinationA, $DestinationB)                         #here it builds an array based on both the given destinations
        }
        $LogText = $(Get-Date).ToString() + ': Trying to copy all files from source ' + $Source + ' to Destinations ' + $Destinations
        Add-Log $LogText $Params.LogPath                                            #here it writes down a log that it is going to do a copy move
        foreach ($Destination in $Destinations){                                    #here it loops through every possible destination to perfom a copy, compare and remove action
            Copy-Files $Source $Destination                                         #here it initializes copying all files from the source to the given destinations
            $LogText = $(Get-Date).ToString() + ": Finished Copying from " + $Source + " towards "   + $Destination + " `n" + $(Get-Date).ToString() + ": Initialising MD5 security check"
            Add-Log $LogText $Params.LogPath                                        #here it writes down the log that it finished the copy job and will start to check if the files are not corrupted
            $Ok = Compare-Files $Source $Destination                                #here it will initialize a compare functions that will test for corrupt files
            if ($Ok[0] -eq $true) {
                $LogText = $(Get-Date).ToString() + ": MD5 security check successful! `n" + $(Get-Date).ToString() + ": Now starting the removal of source files"
                Add-Log $LogText $Params.LogPath                                    #it will now log that it was successful and that it will purge the remaining source files
            }        
            else{
                $CorruptFiles = $Ok[1]                                              #it will log all the paths of the corrupt files into a new array
                $OkFiles = $Ok[2]                                                   #it will log all the paths of the non-corrupt files into a new array
                $Mistake = $true                                                    #here it will change the bool to signify mistakes were made, so the removal can procees accordingly
                $LogText = $(Get-Date).ToString() + ": MD5 security check unsuccessful! `n" + $(Get-Date).ToString() + ": There were " + $CorruptFiles.Count + " corrupt files found `n" 
                Add-Log $LogText $Params.LogPath                                    #after which it will then log that the check was unsuccessful and how many corrupt files there were. and that it will remove them
            }    
        }
        $LogText = $(Get-Date).ToString() + ": Now starting the removal of corrupt files"
        Add-Log $LogText $Params.LogPath                                            #after which it will then log that it will remove files
        Remove-Files $Source $OkFiles $CorruptFiles $Mistake                        #this will initiate the removal of all source material  
        $LogText = $(Get-Date).ToString() + ": Cleanup successful! `n" + $(Get-Date).ToString() + ": Module Complete"
        Add-Log $LogText $Params.LogPath                                            #it will now log that it has finished the module 
    }
}

function Invoke-Flag {
    #? the following function is used to run testing on folders that use flagging
    param (
        [System.Object]$Params                                                      #This is an object filled with all the parameters                                           
    )

    $LogText =  $(Get-Date).ToString() + ": Initiate Flag Test Module"
    Add-Log $LogText $Params.LogPath                                                #it will now log that it has started a new module
    $Source = $Params.FlagSourcePath                                                #here it loads the file path for the source destination into a variable                                     
    $FindFlag = Find-Flag $Sources                                                  #here it will initiate a search for flag files in the source directory 

    if ($FindFlag -eq $false) {                                                     #if there is no flag found it will end the module after the next log
        $LogText = $(Get-Date).ToString() + ": Flag files not found...     `n" + $(Get-Date).ToString() + ": Cancelling module operation.."
        Add-Log $LogText $Params.LogPath                                            #it will now log that it has not found (enough) flag files
    }

    else {                                                                          #if flags are found it is allowed to proceed the module
        $DestinationB = $Params.FlagDestinationPathB                                #here it loads the file path for destination B into a variable
        if ($DestinationFlag -eq $false) {                                          #here it checks whether the A destination has been disabled
            $Destinations = @($DestinationB)                                        #here it builds an array based on both the given destinations
        }
        else {                                                                      #otherwise it will use both destination A and B
            $DestinationA = $Params.FlagDestinationPathA                            #here it tries to load the file path for destination A if possible
            $Destinations = @($DestinationA, $DestinationB)                         #here it builds an array based on both the given destinations   
        }
        $LogText =  $(Get-Date).ToString() + ': Trying to copy all files from source ' + $Source + ' to Destinations ' + $Destinations
        Add-Log $LogText $Params.LogPath                                            #here it writes down a log that it is going to do a copy move   
        foreach ($Destination in $Destinations){                                    #here it loops through every possible destination to perfom a copy, compare and remove action
            Copy-Files $Source $Destination                                         #here it initializes copying all files from the source to the given destinations
            $LogText =  $(Get-Date).ToString() + ": Finished Copying from " + $Source + " towards "   + $Destination + " `n" + $(Get-Date).ToString() + ": Initialising MD5 security check"
            Add-Log $LogText $Params.LogPath                                        #here it writes down the log that it finished the copy job and will start to check if the files are not corrupted
            $Ok = Compare-Files $Source $Destination                                #here it will check whether or not the sync was successful
            if ($Ok[0] -eq $true) {
                $LogText =  $(Get-Date).ToString() + ": MD5 security check successful! `n" + $(Get-Date).ToString() + ": Now starting the removal of source files"
                Add-Log $LogText $Params.LogPath                                    #it will now log that it was successful and that it will purge the remaining source files
            }        
            else{
                $CorruptFiles = $Ok[1]                                              #it will log all the paths of the corrupt files into a new array
                $OkFiles = $Ok[2]                                                   #it will log all the paths of the non-corrupt files into a new array
                $Mistake = $true                                                    #here it will change the bool to signify mistakes were made, so the removal can procees accordingly
                $LogText = $(Get-Date).ToString() + ": MD5 security check unsuccessful! `n" + $(Get-Date).ToString() + ": There were " + $CorruptFiles.Count + " corrupt files found `n" 
                Add-Log $LogText $Params.LogPath                                    #after which it will then log that the check was unsuccessful and how many corrupt files there were. and that it will remove them
            }    
        }
        $LogText = $(Get-Date).ToString() + ": Now starting the removal of corrupt files"
        Add-Log $LogText $Params.LogPath                                            #after which it will then log that it will remove files
        Remove-Files $Source $OkFiles $CorruptFiles $Mistake                        #this will initiate the removal of all source material
    
        $LogText = $(Get-Date).ToString() +  ": Cleanup successful! `n" + $(Get-Date).ToString() + ": Module Complete"
        Add-Log $LogText $Params.LogPath                                            #it will now log that it has finished the module 
    }
}

function Invoke-Multi {
    #? the following function is used to run testing on normal folders
    param (
        [System.Object]$Params                                                      #This is an object filled with all the locations in 'Params.json'
    )
    
    $LogText = $(Get-Date).ToString() + ": Initiate Multi Test Module"
    Add-Log $LogText $Params.LogPath                                                #it will now log that it has started a new module
    $PotentialSources = @($Params.MultiSourcePathA, $Params.MultiSourcePathB)                #here it loads the file path for the source destination into a variable
    $DestinationB = $Params.MultiDestinationPathB                                   #here it tries to load the file path for destination B if possible
    $count = 0
    $Sources = @()
    #! this bit is errorhandling that will check whether or not the module can be skipped due to the source directory being empty
    foreach ($Source in $PotentialSources) {                                        #here it will iterate over each source directory
        if ((Get-ChildItem -Path $Source -Force | Measure-Object).Count -eq 0) {    #here it checks if there are files in the source directory 
            $count += 1                                                             #it will now log that it has not found (enough) files
        } 
        else {
            $Sources += $source
        }
    }
    if ($count -gt $Sources.Count) {                                                             #if the source directories are empty it wil cancell the module
        $LogText = $(Get-Date).ToString() +  ": Source files not found...     `n" + $(Get-Date).ToString() + ": Cancelling module operation.."
        Add-Log $LogText $Params.LogPath
    }
    else {
        if ($DestinationFlag -eq $false){                                           #here it checks whether the A destination has been disabled
            $Destinations = @($DestinationB )                                       #here it builds an array based on both the given destinations
        }
        else{                                                                       #otherwise it will use both destination A and B
            $DestinationA = $Params.MultiDestinationPathA                           #here it loads the file path for destination A into a variable
            $Destinations = @($DestinationA, $DestinationB)                         #here it builds an array based on both the given destinations
        }
        $LogText = $(Get-Date).ToString() + ': Trying to copy all files from source ' + $Source + ' to Destinations ' + $Destinations
        Add-Log $LogText $Params.LogPath                                            #here it writes down a log that it is going to do a copy move
        foreach ($Source in $Sources) {
            foreach ($Destination in $Destinations){                                #here it loops through every possible destination to perfom a copy, compare and remove action
                Copy-Files $Source $Destination                                     #here it initializes copying all files from the source to the given destinations
                $LogText = $(Get-Date).ToString() + ": Finished Copying from " + $Source + " towards "   + $Destination + " `n" + $(Get-Date).ToString() + ": Initialising MD5 security check"
                Add-Log $LogText $Params.LogPath                                    #here it writes down the log that it finished the copy job and will start to check if the files are not corrupted
                $Ok = Compare-Files $Source $Destination                            #here it will initialize a compare functions that will test for corrupt files
                if ($Ok[0] -eq $true) {
                    $LogText = $(Get-Date).ToString() + ": MD5 security check successful! `n" + $(Get-Date).ToString() + ": Now starting the removal of source files"
                    Add-Log $LogText $Params.LogPath                                #it will now log that it was successful and that it will purge the remaining source files
                }        
                else{
                    $CorruptFiles = $Ok[1]                                          #it will log all the paths of the corrupt files into a new array
                    $OkFiles = $Ok[2]                                               #it will log all the paths of the non-corrupt files into a new array
                    $Mistake = $true                                                #here it will change the bool to signify mistakes were made, so the removal can procees accordingly
                    $LogText = $(Get-Date).ToString() + ": MD5 security check unsuccessful! `n" + $(Get-Date).ToString() + ": There were " + $CorruptFiles.Count + " corrupt files found `n" 
                    Add-Log $LogText $Params.LogPath                                #after which it will then log that the check was unsuccessful and how many corrupt files there were. and that it will remove them
                }    
            }
            $LogText = $(Get-Date).ToString() + ": Now starting the removal of corrupt files"
            Add-Log $LogText $Params.LogPath                                        #after which it will then log that it will remove files
            Remove-Files $Source $OkFiles $CorruptFiles $Mistake                    #this will initiate the removal of all source material
        }   
        $LogText = $(Get-Date).ToString() + ": Cleanup successful! `n" + $(Get-Date).ToString() + ": Module Complete"
        Add-Log $LogText $Params.LogPath                                            #it will now log that it has finished the module 
    }
}

function Invoke-Modules {
    #? the following function is used to start every module in sequence
    param (
        [System.Object]$Params      #This is an object filled with all the parameters
        
    )                                     
    Invoke-Test $Params             #here it initializes moving the files move template for normal cases
    Invoke-Flag $Params             #here it initializes moving the files move template for cases that include flag files
    Invoke-Multi $Params            #here it initializes moving the files move template for cases that include multiple source directories     
}


#* ========================================================[ MAIN ]======================================================== *#

#? The script will start by loading in all the parameters 
$Params = Get-Params $ParamPath                              #firstly all parameters get loaded into memory

#? It will then start a transcript and a log file
$TranscriptPath = $Params.TranscriptPath                     #here it selects the right location used for the transcript file
Start-Transcript -Path $TranscriptPath -Append -Force        #here it starts writing a transcript
Start-Logging $Params.LogPath                                #doing routine tasks to check in the logfile

#? After which it will start going through the modules
Invoke-Modules $Params                                       #here it starts the modules that will dictate the movement of the files

#? when finished it will make one last log message
$LogText =  $(Get-Date).ToString() +  ": Script finished `n"                    
Add-Log $LogText $Params.LogPath                             #when finished with all the modules it will log that it has finished running and stamp on an end time