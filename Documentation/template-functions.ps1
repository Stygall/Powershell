#! standard module:
<# json variables
    "TestSourcePath"            :   "../Source/Test/*",
    "TestDestinationPathA"      :   "../Destination/A/Test/",
    "TestDestinationPathB"      :   "../Destination/B/Test/",
#>
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
#! flag module:
<# json variables
    "FlagSourcePath"            :   "../Source/FlagTest/*",
    "FlagDestinationPathA"      :   "../Destination/A/FlagTest/",
    "FlagDestinationPathB"      :   "../Destination/B/FlagTest/",
#>
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
#! Multi source module:
<# json variables
    "MultiSourcePathA"            :   "../Source/MultiTest/A/",
    "MultiSourcePathB"            :   "../Source/MultiTest/B/",
    "MultiDestinationPathA"      :   "../Destination/A/MultiTest/",
    "MultiDestinationPathB"      :   "../Destination/B/MultiTest/"
#>
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