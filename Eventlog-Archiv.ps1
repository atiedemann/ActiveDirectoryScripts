<#
.SYNOPSIS
This script move all eventlog archiv files to a specific location
.DESCRIPTION
This script move all eventlog archiv files to a specific location
#>

##################################################################################
# Variables
##################################################################################
$ZipDate = (Get-Date).AddDays(-1)
$ZipDate = Get-Date -Date $ZipDate -Format 'yyyy-MM-dd'

$PathLogs = 'C:\Windows\System32\winevt\Logs'
$PathRoot = ('C:\Temp\Archive\{0}' -f $env:COMPUTERNAME)
$PathTemp = ('{0}\{1}' -f $PathRoot, $ZipDate)
$PathDestination = '\\<Server>.<Tld>\EventLogArchiv$'
$ZipName = ('{0}\{1}_{2}.zip' -f $PathDestination, $ZipDate, $env:COMPUTERNAME)

##################################################################################
# Functions
##################################################################################
function ZipFiles( $Filename, $SourceFolder )
{
   Add-Type -Assembly System.IO.Compression.FileSystem
   $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceFolder,
        $Filename, $compressionLevel, $false)
}

##################################################################################
# Script
##################################################################################
# Get Files from Remote Server
$Files = Get-ChildItem -Path $PathLogs -Filter 'Archive-*' -File

if ($Files.Count -gt 0) {
    # Test Path for local Archive Files
    if (-not(Test-Path -Path $PathTemp -ErrorAction SilentlyContinue)) {
        $null = New-Item -Path $PathTemp -ItemType Directory -Force
    }
}

# Move all files to Destination
foreach($i in $Files) {
    Move-Item -Path $i.FullName -Destination $PathTemp -Force
}

# If folder exist make a zip file of this folder
if (Test-Path -Path $PathTemp -ErrorAction SilentlyContinue) {

    # Remove file if exists
    if (Test-Path -Path $ZipName -ErrorAction SilentlyContinue) {
        Remove-Item -Path $ZipName -Force
    }

    # Zip file
    ZipFiles -Filename $ZipName -SourceFolder $PathTemp

    # When successfully remove Dir
    if ($?) {
        Remove-Item -Path $PathTemp -Force -Recurse
    }
}
