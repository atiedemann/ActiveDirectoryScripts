<#
Author:			Arne Tiedemann infoWAN Datenkommunikation GmbH
E-Mail:			Arne.Tiedemann@infowan.de
Date:			2020-09-15
Description:	
#>


###########################################################################
# Variables
###########################################################################
$GroupManageServiceAccount = @()
$Property = 'msDS-ManagedPasswordId'
###########################################################################
# Script
###########################################################################
Get-ADServiceAccount -Filter * -Properties $Property | ForEach-Object {

    $HexString = [System.Text.StringBuilder]::new($_.$Property.Length * 2)
    ForEach($byte in $_.$Property){
        $HexString.AppendFormat("{0:x2}-", $byte) | Out-Null
    }
    
    $HexString = $HexString.ToString().Split('-')
    $gMSAId = ('{0}{1}{2}{3}-{4}{5}-{6}{7}-{8}{9}-{10}{11}{12}{13}{14}{15}' -f `
    $HexString[27],$HexString[26],$HexString[25],$HexString[24], `
    $HexString[29],$HexString[28], `
    $HexString[31],$HexString[30], `
    $HexString[33],$HexString[32], `
    $HexString[34],$HexString[35],$HexString[36],$HexString[37],$HexString[38],$HexString[39])


    $GroupManageServiceAccount += [PSCustomObject]@{
        Name = $_.sAMAccountName
        GmsaId = $gMSAId
    }
}

###########################################################################
# Finally
###########################################################################
# Cleaning Up the workspace

$GroupManageServiceAccount | Sort-Object -Property GmsaId

###########################################################################
# End
###########################################################################