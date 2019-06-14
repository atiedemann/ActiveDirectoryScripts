<#
Author:			Arne Tiedemann infoWAN Datenkommunikation GmbH
E-Mail:			Arne.Tiedemann@infowan.de
Date:			2018-06-14
Description:	This Script will get all Clients that communicate from ip sites
                thats are not configured in AD Sites and Services
#>

###########################################################################
# Variables
###########################################################################
Import-Module -Name ActiveDirectory
$OU = (Get-ADDomain).DomainControllersContainer
$DomainControllers = Get-ADComputer -Filter * -SearchBase $OU
$PathNetlogon = 'Admin$\debug\netlogon.log'
$Pattern = 'NO_CLIENT_SITE'
[Object]$Content = $null
###########################################################################
# Functions
###########################################################################

###########################################################################
# Script
###########################################################################
foreach ($DomainController in $DomainControllers) {

    # Define Path to search
    $Path = ('\\{0}\{1}' -f $DomainController.DNSHostName, $PathNetlogon)
    # Check Path
    if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
        Write-Host ('Getting logs from Server {0}:' -f $DomainController.Name) -ForegroundColor Green
        $Rows = Get-Content -Path $Path | Select-String -Pattern $Pattern
        # Add Lines to variable
        $Content += $Rows
    }
}

$Content | ConvertFrom-Csv -Delimiter ' ' -Header 'Date', 'Time', 'Id1', 'Domain', 'Type', 'Client', 'IPAddress' | Export-Csv -Delimiter ',' -Path $HOME\Documents\NO_CLIENT_SITE.csv -NoTypeInformation

# Convert IP field to Netzwork
$ExpClientIP = @{Name = 'IP'; Expression = { $(if ($_.IPAddress) { $IP = ''; $IP = $_.IPAddress.Split('.'); ('{0}.{1}.{2}' -f $IP[0], $IP[1], $IP[2]) }) } }
# Get all unique IP Networks
$Networks = Import-Csv -Path $HOME\Documents\NO_CLIENT_SITE.csv |
    Select-Object -Property $ExpClientIP |
    Where-Object { $_.IP -like '*' } |
    Group-Object -Property IP |
    Sort-Object Count

$Networks | Format-Table -AutoSize
###########################################################################
# Finally
###########################################################################
# Cleaning Up the workspace

###########################################################################
# End
###########################################################################


