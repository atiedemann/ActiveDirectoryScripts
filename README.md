# ActiveDirectoryScripts
This repository will host some usefull scripts for Active Directory and Domain Controller tasks

## Eventlog Archiv move
The script Eventlog-Archiv.ps1 is for moving archive files from local system to a network destination and make an zip archiv from all files.


## Add-UserSamples.ps1
This Script creates a bunch of sample users in an organizational unit for testing purposes.
You need also the sample users csv file namelist.csv and make some changed in the PowerShell file:

$OU = 'OU=User,OU=Company,dc=domain,dc=com'
$Users = Import-Csv -Path "<Path2File>\Namelist.csv" -Encoding UTF8
$UPNDomain = 'domain.tld'
$Country = '<CountryCode>' # ISO Country code #2 Letters
  

