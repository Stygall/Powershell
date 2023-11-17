#requires -version 2

<#
.SYNOPSIS
  Kopieert bestanden van Bron naar Bestemming en maakt hier logging van

.DESCRIPTION
  Kopieert bestanden van Bron naar Bestemming en maakt hier logging van


.INPUTS
  NONE

.OUTPUTS
  Inbeheername-info.log

.NOTES
  Version:        1.2
  Author:         Roestenburg, Peter
  Company:         Centric Netherlands B.V.
  Website:         http://www.centric.eu

  Change Log
    v1.0 – 20160712 – PR – Initial version

#>

    
#---------------------------------------------------------[ Initialisations ]--------------------------------------------------------
$Now = get-date -format "ddMMyyyy"
Start-Transcript -Path "D:\LOGS\stater\$now Acceptatie.log" -Append -Force
$loglocation = "D:\LOGS\stater\"
$User = "SVC-OBV-SCR-ST-A"
$File = ".\SVC-OBV-SCR-ST-A_Encrypted.xml"
$date = get-date -Format "yyyyMMdd"
$Srcdrivename = 'FTPStater'
$Srcdrivepath = '\\obv-box-ftp01-A\SFTP_Data$\Stater\bestanden\in'
$Destdrivename = 'FSstater'
$Destdrivepath = '\\obvion.local\Applicaties\Stater - Acceptatie'
$exludedir = [CHAR]34 + 'shs' +[CHAR]34 + " " + [CHAR]34 + 'tmn' +[CHAR]34 


#----------------------------------------------------------[ Declarations ]---------------------------------------------------------- 
Set-Location -path $PSScriptRoot
$MyCredential=Import-Clixml $file
$fulltimeanddate = Get-Date -Format 'yyyyMMddHHmm'
$Loglocation = '\\obvion.local\Applicaties\Stater - Acceptatie\logfiles'
$Logname = "Stater_Download_$date.log"
$Logpath = [CHAR]34 + $Loglocation + '\'+$Logname +[CHAR]34
$options = "/COPY:DAT /XD $exludedir"

#-----------------------------------------------------------[ Functions ]------------------------------------------------------------


#-----------------------------------------------------------[ Main ]-----------------------------------------------------------------
New-PSDrive -Name 'X' -PSProvider FileSystem -Root $Srcdrivepath -Credential $MyCredential
New-PSDrive -Name 'Y' -PSProvider FileSystem -Root $Destdrivepath # -Credential $MyCredential

# Copy from sFTP server obv-box-ftp01 to fileserver obv-box-fs01

$folders = Get-ChildItem -Directory -Path X:\ |Where {$_.name -notmatch "Obvion Datawarehouse"}|select -ExpandProperty name
foreach ($foldername in $folders){
$sourcepath = $Srcdrivepath +'\'+ $foldername
$DestinationPath = $Destdrivepath +'\' + $foldername
Robocopy $Sourcepath $DestinationPath *.* /MOV /S /COPY:DAT /XD $exludedir /MT:8 /R:1 /W:10 /NP /NS /NC /log+:$Logpath
}

# Copy from fileserver obv-box-fs01 to sFTP server obv-box-ftp01 

$Uploadfolders = Get-ChildItem '\\obvion.local\Applicaties\Stater - Acceptatie' -Directory -Recurse |Where {$_.name -match "(Aanlevering)|(.*OUT$)"}|%{$($_|Select -ExpandProperty fullname).replace('\\obvion.local\Applicaties\Stater - Acceptatie\','')}

foreach ($foldername in $Uploadfolders){
$sourcepath = '\\obv-box-ftp01-A\SFTP_Data$\Stater\bestanden\out'+'\'+ $foldername
$DestinationPath = $Destdrivepath +'\' + $foldername
Robocopy  $DestinationPath  $sourcepath *.* /MOV /S /COPY:DAT /MT:8 /R:1 /W:10 /NP /NS /NC /log+:$Logpath

}

$Now = Get-Date

$cutoff = $now.adddays(-14)

Get-ChildItem -Path $loglocation|Where-Object {$_.LastWriteTime -lt $cutoff}|Select fullname|foreach{Remove-Item $_.fullname -Force}

Remove-PSDrive -name 'X'
Remove-PSDrive -name 'Y'
Stop-Transcript
