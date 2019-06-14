# ActiveDirectoryScripts
This repository will host some usefull scripts for Active Directory and Domain Controller tasks

## Tier 0
This scripts should only be used in tier 0 environment.
Tier0 => only Domain Admins have access to this files

### Get LapsPassword
LAPS does not save password history to active directory. My script will do this for you and save the passwords to an csv file on an domain controller.

These script will get all computer objects from local domain that have an active directory attribute 'ms-Mcs-AdmPwd' set and export the objects, only name, password and date to an csv file. If a computer password was changed, the script will add an new row for this computer.

### Get-NoClientSiteNetworks.ps1
These file will collect from any Domain Controller the netlogon.log file and search for NO_CLIENT_SITE Clients and collect every IP from that. After collecting every data I remove the last octet from IP address and group the output ordered by count. As result, you will see a list of ip subnets that's are missing in Active Directory Sites and Services.

## Tier 1
This scripts can be executed on tier 1 systems
Tier 1 => Theses systems are member servers and admin users that do have access to tier 1 but not to tier 0 systems.

### Get LAPS Computer password history
The script in tier 0 will save all the computer objects with a LAPS password to an csv file. To get the history from the csv file as an tier 1 admin is complicated and I build these script.

This script will ask for tier 0 credentials and create an PS-Drive to the csv folder on the domain controller where the csv is genrated and connect to this folder with tier 0 credential. If the PS-Drive can succesfully created, we read the csv and search for the computername "parameter -ComputerName from script". If we find the name, we will show a table of all passwords from that computer.

## Eventlog Archiv move
The script Eventlog-Archiv.ps1 is for moving archive files from local system to a network destination and make an zip archiv from all files.


## Add-UserSamples.ps1
This Script creates a bunch of sample users in an organizational unit for testing purposes.
You need also the sample users csv file namelist.csv and make some changed in the PowerShell file:

$OU = 'OU=User,OU=Company,dc=domain,dc=com'
$Users = Import-Csv -Path "<Path2File>\Namelist.csv" -Encoding UTF8
$UPNDomain = 'domain.tld'
$Country = '<CountryCode>' # ISO Country code #2 Letters
