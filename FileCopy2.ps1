#requires -version 2
#requires -version 2

<#
.SYNOPSIS
  Kopieert bestanden van Bron naar Bestemming en maakt hier logging van

.DESCRIPTION
  Kopieert bestanden van Bron naar Bestemming en maakt hier logging van
  De Kopie wordt geveriveerd d.m.v. een Checksum (SHA256 Hash)

.INPUTS
  NONE

.OUTPUTS
  Inbeheername-info.log

.NOTES
  Version:        1.2
  Author:         Rob Hagman
  Company:         Centric Netherlands B.V.
  Website:         http://www.centric.eu

  Change Log
    v1.0 – 20181212 – RH – Initial version
    v1.2 – 20181218 – RH – Production version: improved Error checking and cleanup

#>


#---------------------------------------------------------[ Functions ]--------------------------------------------------------

<#
.Synopsis
   Write-Log writes a message to a specified log file with the current time stamp.
.DESCRIPTION
   The Write-Log function is designed to add logging capability to other scripts.
   In addition to writing output and/or verbose you can write to a log file for
   later debugging.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 11/24/2015 09:30:19 AM  

   Changelog:
    * Code simplification and clarification - thanks to @juneb_get_help
    * Added documentation.
    * Renamed LogPath parameter to Path to keep it standard - thanks to @JeffHicks
    * Revised the Force switch to work as it should - thanks to @JeffHicks

   To Do:
    * Add error handling if trying to create a log file in a inaccessible location.
    * Add ability to write $Message to $Verbose or $Error pipelines to eliminate
      duplicates.
.PARAMETER Message
   Message is the content that you wish to add to the log file. 
.PARAMETER Path
   The path to the log file to which you would like to write. By default the function will 
   create the path and file if it does not exist. 
.PARAMETER Level
   Specify the criticality of the log information being written to the log (i.e. Error, Warning, Informational)
.PARAMETER NoClobber
   Use NoClobber if you do not wish to overwrite an existing file.
.EXAMPLE
   Write-Log -Message 'Log message' 
   Writes the message to c:\Logs\PowerShellLog.log.
.EXAMPLE
   Write-Log -Message 'Restarting Server.' -Path c:\Logs\Scriptoutput.log
   Writes the content to the specified log file and creates the path and file specified. 
.EXAMPLE
   Write-Log -Message 'Folder does not exist.' -Path c:\Logs\Script.log -Level Error
   Writes the message to the specified log file as an error message, and writes the message to the error pipeline.
.LINK
   https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
#>



function Write-Log
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path='C:\Logs\PowerShellLog.log',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
                }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
                }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
                }
            }
        
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}

#---------------------------------------------------------[ Initialisations ]--------------------------------------------------------
$Now = get-date -format "ddMMyyyy"
Start-Transcript -Path "D:\LOGS\stater\$now azure acceptatie.log" -Append -Force

$env:path+=';C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy'
$User = "SVC-OBV-SCR-ST-A"
$File = ".\SVC-OBV-SCR-ST-A_Encrypted.xml"
$date = get-date -Format "yyyyMMdd"
$Srcdrivename = 'FTPStater'
$Srcdrivepath1 = '\\obv-box-ftp01-A\SFTP_Data$\Stater\bestanden\in\Obvion Datawarehouse\ACC\shs'
$Srcdrivepath2 = '\\obv-box-ftp01-A\SFTP_Data$\Stater\bestanden\in\Obvion Datawarehouse\ACC\tmn'

$Destdrivename = "FTPInergy"
$Destdrivepath1 = '\\obv-box-ftp01-A\SFTP_Data$\DWH\Stater\ACC\shs'
$Destdrivepath2 = '\\obv-box-ftp01-A\SFTP_Data$\DWH\Stater\ACC\tmn'

$blobstore1 = 'https://obvsa00007.blob.core.windows.net/obvionblob/ObvionSftp/Stater/Obvion Datawarehouse/ACC/shs/'
$blobstore2 = 'https://obvsa00007.blob.core.windows.net/obvionblob/ObvionSftp/Stater/Obvion Datawarehouse/ACC/tmn/'
$blobkey = ""

$scripttemp = 'D:\SCRIPTS\SCHEDULED_SCRIPTS\Stater - Azure (ACC)\temp\'
$COPYFAILED = $FALSE
$itemcount = 0 

#----------------------------------------------------------[ Declarations ]---------------------------------------------------------- 
Set-Location -path $PSScriptRoot
$MyCredential=Import-Clixml $file
$fulltimeanddate = Get-Date -Format 'yyyyMMddHHmm'
$Loglocation = '\\obvion.local\Applicaties\Stater - Acceptatie\Logfiles'
$Logname = "Stater_Azure_$date.log"
$Logpath = $Loglocation + '\' + $Logname
$AzCopylogname = "Stater_AzCopy_$date.log"
$AzLogpath = [CHAR]34 + $Loglocation + '\'+$AzCopylogname +[CHAR]34

$storageAccountName = 'obvsa00007'
$keyVaultName = 'obvkv00001'
$tenantId = '2cc31016-500f-4c0a-9865-9b423021db81'
$applicationId = 'f3d8aaa0-af1b-4f01-8e57-0b20619c5269'
$certThumbprint = '3AAEB15411FF1929E6D3937803AA35BD112092C8'
$Secrets=$null

#-----------------------------------------------------------[ Main ]-----------------------------------------------------------------

Write-Log -Message "********** Start new Processing run **********" -Path $Logpath -Level Info


# Map PSDrive to Source And Destination
$Logpath

Write-Log -Message "Mounting PSDrives on Source and Destination" -Path $Logpath -Level Info

New-PSDrive -Name 'V' -PSProvider FileSystem -Root $Srcdrivepath1 -Credential $MyCredential
New-PSDrive -Name 'W' -PSProvider FileSystem -Root $Destdrivepath1 -Credential $MyCredential

New-PSDrive -Name 'X' -PSProvider FileSystem -Root $Srcdrivepath2 -Credential $MyCredential
New-PSDrive -Name 'Y' -PSProvider FileSystem -Root $Destdrivepath2 -Credential $MyCredential

Write-Log -Message "Start Copy for SHS" -Path $Logpath -Level Info
Write-Log -Message "Searching $Srcdrivepath1 for files" -Path $Logpath -Level Info

$items2copy = Get-childItem -path "V:\" -File  -filter "*.zip"|
        select name,fullname,basename

$itemcount = $items2copy|measure -Property name|select -ExpandProperty count


IF ($itemcount -gt 0 ){

    Write-Log -Message "Found $itemcount files that are ready for processing" -Path $Logpath -Level Info
    
    Foreach($sourcefile in $items2copy ){
        $hashfile = ""
        $sourcehash = ""
        $retry =1
        $COPYFAILED = $FALSE
        $tempfile = $("W:\temp_{0}_Inprogress.tmp" -f $date )
        $INdonefile = $("v:\{0}.don" -f $sourcefile.basename)
        $AZdonefile = $("v:\{0}.azd" -f $sourcefile.basename)   

         Write-Log -Message "Processing $($sourcefile|select -ExpandProperty name)" -Path $Logpath -Level Info
         $hashfile = $("v:\{0}.hash" -f $sourcefile.basename)
         
    ### Checking Prereq  SHS ###
         
         IF (test-path $hashfile) {
            $sourcehash = Get-Content -path $hashfile -Force
            Write-Log -Message "Hashfile: $hashfile contains $sourcehash " -Path $Logpath -Level info
            }ELSE{
            Write-Log -Message "File not found: $hashfile" -Path $Logpath -Level Warn
            $retry = 0 
            $COPYFAILED = $TRUE
            }


        IF ( $sourcehash.length -le 10 ){
            Write-Log -Message $("Failed to find Checksum for Sourcefile {0} retry next run" -f$($sourcefile|select -expandproperty fullname)) -Path $Logpath -Level warn
            $retry = 0 
            $COPYFAILED = $TRUE
            }

    IF($retry -ge 1){
            Write-Log -Message "Start processing" -Path $Logpath -Level Info
            Write-Log -Message $("Name: {0}" -f $($sourcefile|select -ExpandProperty fullname)) -Path $Logpath -Level Info
            Write-Log -Message $("Checksum: {0}" -f $sourcehash) -Path $Logpath -Level Info
    } ELSE {Write-Log -Message "Pre-Check failed skipping copy to Ingergy DWH - SHS" -Path $Logpath -Level WARN}

    IF (test-path $INdonefile) {
            Write-Log -Message "Copy to Inergy DWH already succesfuly completed, skipping to Azure copy" -Path $Logpath -Level info
            $retry = 0
            }


    ### Copy for SHS ### 
   
    While($retry -ge 1){
        
        Write-Log -Message "Start Copy SHS to Inergy DWH - SHS" -Path $Logpath -Level Info
        
        $sourceSize = (Get-Item $sourcefile.FullName).Length
        Write-Log -Message "Source File Size: $($sourceSize / 1KB) KB" -Path $Logpath -Level Info

        Copy-Item -Path $sourcefile.fullname -Destination "$tempfile" -Force 
        
        Write-Log -Message "Copy to Inergy DWH - SHS finished, Checking File Checksum" -Path $Logpath -Level Info
        
        $destinationSize = (Get-Item $tempfile).Length
        Write-Log -Message "Destination File Size: $($destinationSize / 1KB) KB" -Path $Logpath -Level Info

        Write-Log -Message $("Checksum Sourcefile: {0}" -f $sourcehash) -Path $Logpath -Level Info
        
        $Destfile = $Destdrivepath1 + "\" + $sourcefile.name
        $Errfile = $($Destfile + ".err")
         
        $CheckHash1 = Get-FileHash -Path $tempfile -Algorithm SHA256|select -ExpandProperty hash
        Write-Log -Message "Checksum Destination file: $CheckHash1" -Path $Logpath -Level Info

        IF($CheckHash1 -eq $sourcehash){
            $retry = 0
            rename-item -Path $tempfile -NewName $sourcefile.name -Force
            IF (test-path $tempfile ){ Write-Log -Message "Rename failed" -Path $Logpath -Level Warn }
            IF(!(test-path $INdonefile)){new-item -Path $INdonefile -ItemType File -Force}
            Write-Log -Message "Copy succesfull File Checksum Matched Source" -Path $Logpath -Level Info
            
            } ELSE {

            Write-Log -Message "Copy to Inergy DWH failed with Checksum Mismatch error: Retrying Copy" -Path $Logpath -Level Warn
            Write-Log -Message "Source Hash: $sourcehash" -Path $Logpath -Level warn
            Write-Log -Message "Destination Hash: $CheckHash1" -Path $Logpath -Level warn
            $retry++
            
            }
           
        IF($retry -gt 3){
            $retry =0
            Write-Log -Message "Copy failed File Checksum Mismatch even after retry" -Path $Logpath -Level Error
            Write-Log -Message "Source Hash: $sourcehash" -Path $Logpath -Level Error
            Write-Log -Message "Destination Hash: $CheckHash1" -Path $Logpath -Level Error
            $COPYFAILED = $TRUE
            }

         }

   IF($COPYFAILED -eq $False ){ $retry = 1}

        IF ( $sourcehash.length -le 10 ){
        Write-Log -Message $("Failed to get Checksum for Sourcefile {0} retry AZCopy next run" -f$($sourcefile|select -expandproperty fullname)) -Path $Logpath -Level warn
        $retry = 0 
        $COPYFAILED = $TRUE
        }

            
        IF ($COPYFAILED -eq $False){
                Write-Log -Message "Both Copies succesfull, Starting cleanup" -Path $Logpath -Level Info
                
                While (test-path $( "{0}\{1}" -f $Srcdrivepath1,$sourcefile.name ) ){
                Remove-Item -Path $($Srcdrivepath1 + "\" +$sourcefile.name) -Force
                IF (!(test-path $($Srcdrivepath1 + "\" +$sourcefile.name))){Write-Log -Message "Sourcefile Deleted" -Path $Logpath -Level Info}
                }

                Remove-Item -Path $($hashfile) -Force
                IF (!(test-path $hashfile )){Write-Log -Message "Hash file Deleted" -Path $Logpath -Level Info}
                
                Remove-Item -Path $($Scripttemp + $sourcefile.name) -Force
                IF (!(test-path $($Scripttemp +$sourcefile.name))){Write-Log -Message "Temp file Deleted" -Path $Logpath -Level Info}

                IF (!(test-path $($Scripttemp + $sourcefile.name)) -and !(test-path $sourcefile.fullname) ){Remove-Item -Path $($INdonefile) -Force}
                IF(!(test-path $INdonefile)){Write-Log -Message "INDone file Deleted" -Path $Logpath -Level Info}

                IF (!(test-path $($Scripttemp + $sourcefile.name)) -and !(test-path $sourcefile.fullname) ){Remove-Item -Path $($AZdonefile) -Force}
                IF(!(test-path $AZdonefile)){Write-Log -Message "AZDone file Deleted" -Path $Logpath -Level Info}

                test-path $INdonefile

                IF (test-path $Errfile){ Remove-Item -Path $Errfile -Force
                    IF (!(test-path $Errfile)){Write-Log -Message "Temp error file Deleted" -Path $Logpath -Level Info}
                    }
                } ELSE {
                    Write-Log -Message "One or more copies failed, not deleting sourcefiles" -Path $Logpath -Level Warn

        
        
            }
        }
        
    }ELSE{
    
    Write-Log -Message "No files found, nothing to process for SHS" -Path $Logpath -Level Info
    
    }


### Copy for TMN ###

Write-Log -Message "Start Copy for TMN" -Path $Logpath -Level Info
$filecount = 0

# Look for ready to copy copy touchfile

Write-Log -Message "Searching $Srcdrivepath2 for files to process" -Path $Logpath -Level Info

IF(test-path "X:\*.flag"){
   
    Write-Log -Message "Touch file found" -Path $Logpath -Level Info
    Write-Log -Message "Collecting File info" -Path $Logpath -Level Info

    Get-childItem -file -path "X:\"|Select basename,Extension

    $items2copy = Get-childItem -path "X:\" -filter "*.flag" |select basename,
    @{n='filename';e={$_.basename +".zip" }},
    @{n='fullname';e={"X:\"+$_.basename + ".zip"}},
    @{n='HASH';e={Get-FileHash -Path $("X:\" +$_.basename +".zip") -Algorithm SHA256|select -ExpandProperty hash }}

    $Filecount = $items2copy|measure -Property basename |Select -expandproperty count

    Write-Log -Message "Found $Filecount files that are ready for processing" -Path $Logpath -Level Info
    
    foreach($item in $items2copy ){
    $hashfile =""
    $Sourcehash = ""
    $tempfile = $("Y:\temp_{0}_Inprogress.tmp" -f $date )
    $INdonefile = $("X:\{0}.don" -f $item.basename)
    $AZdonefile = $("X:\{0}.azd" -f $item.basename) 
    $retry =1
    $COPYFAILED = $FALSE
    $hashfile = "x:\" +$item.basename + ".hash"
    $flagfile = "X:\" +$item.basename + ".flag"

    If (test-path $hashfile){
        Write-Log -Message "$hashfile found" -Path $Logpath -Level Info
        $Sourcehash = get-content $hashfile
        Write-Log -Message "Content $Sourcehash" -Path $Logpath -Level Info
    } Else {
        Write-Log -Message "$hashfile Not found, trying to calculate hash from sourcefile directly" -Path $Logpath -Level Warn
        $Sourcehash = Get-FileHash -Path $item.fullname|select -ExpandProperty hash 
    }
    
    
    IF(!(test-path $($item.fullname))){
        Write-Log -Message $("No Sourcefile corresponding to touch file {0}.FLAG Found, retry next run" -f$($item|select -expandproperty basename)) -Path $Logpath -Level Info
        $retry = 0
        $COPYFAILED = $TRUE 
        }

    IF ( $sourcehash.length -le 10){
        Write-Log -Message $("Failed to calculate Checksum for Sourcefile {0} retry next run" -f$($item|select -expandproperty fullname)) -Path $Logpath -Level Info
        $retry = 0 
        $COPYFAILED = $TRUE
        }

    IF ($retry -ge 1){
            Write-Log -Message "Start Copy to Inergy DWH - TMN" -Path $Logpath -Level Info
            Write-Log -Message $("Name: {0}" -f $($item|select -expandproperty fullname)) -Path $Logpath -Level Info
            Write-Log -Message $("Checksum: {0}" -f $Sourcehash) -Path $Logpath -Level Info
      }ELSE{Write-Log -Message "Pre-Check failed, skipping Copy to Inergy DWH - TMN" -Path $Logpath -Level WARN}
    
    IF (test-path $INdonefile) {
            Write-Log -Message "Copy to Inergy DWH - TMN already succesfuly completed, skipping to Azure copy" -Path $Logpath -Level info
            $retry = 0
            $COPYFAILED = $False
       }

    
    While($retry -ge 1){


        
        Write-Log -Message "Copy to Inergy DWH -  TMN" -Path $Logpath -Level Info
        
        $sourceSize = (Get-Item $sourcefile.FullName).Length
        Write-Log -Message "Source File Size: $($sourceSize / 1KB) KB" -Path $Logpath -Level Info

        Copy-Item -Path $item.fullname -Destination "Y:\"
        
        Write-Log -Message "Copy to Inergy finished, Checking File Checksum" -Path $Logpath -Level Info
        
        $destinationSize = (Get-Item $tempfile).Length
        Write-Log -Message "Destination File Size: $($destinationSize / 1KB) KB" -Path $Logpath -Level Info
        
        
        $Destfile = $Destdrivepath2 + "\" + $item.filename
         
        $CheckHash1 = Get-FileHash -Path $Destfile -Algorithm SHA256 |Select -expandproperty hash
        Write-Log -Message $("Destination Hash: {0}"-f $CheckHash1) -Path $Logpath -Level Info

        IF($CheckHash1 -eq $Sourcehash){
            $retry = 0
            rename-item -Path $tempfile -NewName $item.filename -Force
            # New-Item -ItemType File -Path $flagfile
            IF(!(test-path $INdonefile)){new-item -Path $INdonefile -ItemType File -Force}
            Write-Log -Message "Copy succesfull File Checksum Matched Source" -Path $Logpath -Level Info
            } ELSE {
            Write-Log -Message "Copy failed File Checksum Mismatch Retry Copy" -Path $Logpath -Level Warn
            $retry++
            }
           
        IF($retry -gt 3){
            $retry =0
            Write-Log -Message "Copy failed File Checksum Mismatch even after retry" -Path $Logpath -Level Warn
            Write-Log -Message $("Source Hash: {0}" -f $Sourcehash.hash) -Path $Logpath -Level Warn
            Write-Log -Message $("Destination Hash: {0}" -f $CheckHash1) -Path $Logpath -Level Warn
            $COPYFAILED = $TRUE
            }

         }


     Write-Log -Message "Start Copy to Azure" -Path $Logpath -Level Info

    $retry = 1
   

    IF(!(test-path $($item|select -expandproperty fullname))){
        Write-Log -Message $("No Sourcefile corresponding to touch file {0}.FLAG Found, retry next run" -f$($item|select -expandproperty basename)) -Path $Logpath -Level Info
        $retry = 0
        $COPYFAILED = $TRUE 
        }
 }
            
        IF ($COPYFAILED -eq $False){
                Write-Log -Message "Both Copies succesfull, Starting cleanup" -Path $Logpath -Level Info
                
                
                Remove-Item -Path $($Srcdrivepath2 + "\" +$item.filename) -Force
                IF (!(test-path $($Srcdrivepath2 + "\" +$item.filename))){Write-Log -Message "Sourcefile Deleted" -Path $Logpath -Level Info}
               
                IF (!(test-path $item.fullname)){
                    Remove-Item -Path $($flagfile) -Force
                    IF(!(test-path $flagfile)){Write-Log -Message "flagfile Deleted" -Path $Logpath -Level Info}

                    Remove-Item -Path $($hashfile) -Force
                    IF (!(test-path $hashfile )){Write-Log -Message "Hash file Deleted" -Path $Logpath -Level Info}
                
                    Remove-Item -Path $($Scripttemp + $item.filename) -Force
                    IF (!(test-path $($Scripttemp +$item.filename))){Write-Log -Message "Temp file 1 Deleted" -Path $Logpath -Level Info}

                    Remove-Item -Path $($INdonefile) -Force
                    IF(!(test-path $INdonefile)){Write-Log -Message "INDone file Deleted" -Path $Logpath -Level Info}

                    Remove-Item -Path $($AZdonefile) -Force
                    IF(!(test-path $AZdonefile)){Write-Log -Message "AZDone file Deleted" -Path $Logpath -Level Info}
                  }
                
                } ELSE {
                    Write-Log -Message "One or more copies failed, not deleting sourcefiles" -Path $Logpath -Level Warn                        
                        }
        
        
        }ELSE {
Write-Log -Message "No files found, nothing to process for TMN" -Path $Logpath -Level Info
}


$now = get-date

$cutoff = $now.adddays(-28)

Get-ChildItem -Path $loglocation|Where-Object {$_.LastWriteTime -lt $cutoff}|Select fullname|foreach{Remove-Item $_.fullname -Force}




Remove-PSDrive -Name 'V' -PSProvider FileSystem -Force
Remove-PSDrive -Name 'W' -PSProvider FileSystem -Force

Remove-PSDrive -Name 'X' -PSProvider FileSystem -Force 
Remove-PSDrive -Name 'Y' -PSProvider FileSystem -Force

stop-transcript
