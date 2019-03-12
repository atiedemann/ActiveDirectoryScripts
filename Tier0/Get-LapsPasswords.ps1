<#
Author:			Arne Tiedemann
E-Mail:			Arne.Tiedemann@posh-samples.com
Date:			2019-03-12
Description:	This script get all computers from ad that have
                ms-Mcs-AdmPwd attribute set and export these objects
                to an csv file

                These script should run on an Domain Controller and save the
                contents to a folder that is not accesseble from authenticated
                users. Access should only be acepted from Domains Admins
#>

###########################################################################
# Variables
###########################################################################
$PathExport = 'Path2CsvFolder'
$CsvComputer = ('{0}\ComputerPasswords.csv' -f $PathExport)
$Date = Get-Date -Format 'yyyy-MM-dd'
$AdAttribute = 'ms-Mcs-AdmPwd'
###########################################################################
# Functions
###########################################################################

###########################################################################
# Script
###########################################################################
if (-not(Test-Path -Path $PathExport -ErrorAction SilentlyContinue)) {
    $null = New-Item -Path $PathExport -ItemType Directory
}

if (Test-Path -Path $CsvComputer) { $Computers = Import-Csv -Path $CsvComputer -Encoding UTF8 }
else { $Computers = @() }

# Get all Computers with LAPS passwords
foreach($Computer in (Get-ADComputer -Properties $AdAttribute -Filter {($AdAttribute -like '*')})) {

    <#
        Validate the password of the computer
        if changed add new row
    #>
    if (-not(($Computers | Where-Object { $_.Computername -eq $Computer.Name -and $_.Password -eq $Computer.$AdAttribute }).ComputerName -eq $Computer.Name)) {
        $Computers += [PSCustomObject]@{
            ComputerName = $Computer.Name
            Password = $Computer.$AdAttribute
            Date = $Date
        }
    }
}
###########################################################################
# Finally
###########################################################################
# Export Csv
$Computers = $Computers | Sort-Object Computername, Date
$Computers | Export-Csv -NoTypeInformation -Path $CsvComputer -Encoding UTF8

# Cleaning Up the workspace
Remove-Variable -Name Computer -ErrorAction SilentlyContinue
Remove-Variable -Name Computers -ErrorAction SilentlyContinue

###########################################################################
# End
###########################################################################