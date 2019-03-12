<#
Author:			Arne Tiedemann
E-Mail:			Arne.Tiedemann@posh-samples.com
Date:			2019-03-12
Description:
#>
###########################################################################
# Variables
###########################################################################
$PathLAPS = '\\DomainControllerFQDN\Path2CsvFolder'
$PathLAPSCsv = 'ComputerPasswords.csv'
###########################################################################
# Functions
###########################################################################

function Get-LapsPasswordHistory {
    param (
        [Parameter(Mandatory=$true)]
        [STRING]$Computername
    )

    $T0Credential = Get-Credential

    if ($?) {
        # Add PsDrive with Domain Admin authentication
        $null = New-PSDrive -Credential $T0Credential -Name LAPSHistory -PSProvider FileSystem -Root $PathLAPS

        Write-Host 'Getting computer password from password history for: ' -NoNewline -ForegroundColor Yellow
        $Computername

        try {
            # Try to get content from DC
            Get-Content -Path LAPSHistory:$PathLAPSCsv |
                ConvertFrom-Csv |
                Where-Object { $_.ComputerName -eq $Computername } | Sort-Object -Property Date | Format-Table -AutoSize
        } catch {
            $_.Exception.Message
        }
    }

    # Finally remove PsDrive
    $null = Remove-PSDrive -Name LAPSHistory -Force
}
###########################################################################
# Script
###########################################################################

###########################################################################
# Finally
###########################################################################
# Cleaning Up the workspace

###########################################################################
# End
###########################################################################

