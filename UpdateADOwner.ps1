
[CmdletBinding(DefaultParametersetName='None')]
Param(
    [Parameter(Mandatory=$false,ParameterSetName='Reload')]
    [Parameter(ParameterSetName='ChangeOwner')]
    [Switch]$ReloadData,

    [Parameter(Mandatory=$false,ParameterSetName='ChangeOwner')]
    [Switch]$ChangeOwner,

    [Parameter(Mandatory=$true,ParameterSetName='ChangeOwner')]
    [STRING]$OldOwner,

    [Parameter(Mandatory=$true,ParameterSetName='ChangeOwner')]
    [STRING]$NewOwner
)

<#
.SYNOPSIS
This script identifies AD Objects that have an owner that points to an orphanded AD user object.

.DESCRIPTION
This script identifies AD Objects that have an owner that points to an orphanded AD user object.
the second part of this script can change the orphanded owners to an existing user.

.PARAMETER ReloadData
This is a SWITCH parameter!
If this parameter is used, Acrtive Directory data will be reloaded.

.PARAMETER ChangeOwner
This is a SWITCH parameter!
If this parameter will be used, owner will bechanged for the objects.

.PARAMETER OldOwner
This paramater specifies the sAMAccountName or SID from changing owner

.PARAMETER NewOwner
This paramter specifies the sAMAccountName from the new owner

.EXAMPLE Default run
Start the script without parameter will first load all data and show a table with is grouped by object owner.

.EXAMPLE Change objects
-ChangeOwner -OldOwner 'sAMAccountName from old owner' -NewOwner 'sAMAccountName from new owner'

.EXAMPLE ReloadData
-ReloadData

.NOTES
Author: Arne Tiedemann
Company: infoWAN Datankommunikation GmbH
Email: Arne.Tiedemann@infowan.de

.LINK
https://github.com/atiedemann/ActiveDirectoryScripts

#>

###########################################################################
# Variables
###########################################################################
$PathLog = ('{0}\ObjectOwners.log' -f $PSScriptRoot)
if ($Global:ADObjects.Count -eq 0 -or $ReloadData -eq $true) {
    $Global:ADObjects = [System.Collections.Generic.List[PSObject]]::New()
}
$DateOfFinding = Get-Date -Format 'yyyy-MM-dd'
###########################################################################
# Functions
###########################################################################
function Set-Logging {
        Param(
        [Parameter(Mandatory=$true)]
        $Message,
        $Type = 'Information'
    )
    # Replace : with ; to define the object
    $Message = $Message -replace(': ',';')
    $Time = (Get-Date -Format 'HH:mm:ss')
    ('{0};{1};{2};{3} ' -f $Type, $DateOfFinding, $Time, $Message) | Out-File -FilePath $PathLog -Append

    if ($Debug) {
        Write-Host ('{0} {1} {2} {3}' -f $Type, $DateOfFinding, $Time, $Message)
    }
}
###########################################################################
# Script
###########################################################################
Set-Logging -Message 'Start identifying active directory objects'
Write-Host ('All logging information will be saved to this file: {0}' -f $PathLog)

'ChangeUser: ' + $ChangeOwner
'ReloadData: ' + $ReloadData
'ADObjects:' + $ADObjects.Count

if (($ChangeOwner -eq $false -and $ReloadData -eq $true) -or $ReloadData -eq $true -or $ADObjects.Count -eq 0) {
    Write-Host 'Getting Active Directory objects...'
    $Objects = Get-ADObject -Filter {((ObjectClass -eq 'user' -and ObjectClass -ne 'computer' -and ObjectClass -ne 'msDS-GroupManagedServiceAccount') -or (ObjectClass -eq 'group' -or ObjectClass -eq 'organizationalUnit'))} |
        Select-Object Name, ObjectClass, DistinguishedName

    foreach($Obj in $Objects)
    {
        # Write Log
        Set-Logging -Message ('Getting object information from {0} => ObjectClass {1}' -f $Obj.Name, $Obj.ObjectClass)
        # Get the acl from AD Object
        $Acl = $null
        $DN = ('{0}' -f $Obj.DistinguishedName)
        $Acl = Get-Acl -Path AD:"$($DN)"

        # Add object to arraylist
        $ADObjects.Add([PSCustomObject]@{
            Name = $Obj.Name
            DistinguishedName = $Obj.DistinguishedName
            ObjectClass = $Obj.ObjectClass
            Owner = $Acl.Owner
        })
    }
}

# Print group of owners
$Global:ADObjects | Group-Object -Property Owner | Select-Object Count, Name | Sort-Object Count

# if change owners is active, do it
if ($ChangeOwner -eq $true -and $ADObjects.Count -gt 0) {
    Write-Host 'Changing Active Directory objects...'
    # get basic variables
    $Domain = (Get-ADDomain).NetBIOSName

    # Check if new owner exists
    $Result = Get-ADObject -Filter {(sAMAccountName -eq $NewOwner -and (ObjectClass -eq 'user' -or ObjectClass -eq 'group'))}

    # Run only if new owner exists
    if ($Result.Name -eq $NewOwner) {
        $NewOwner = ('{0}\{1}' -f $Domain, $NewOwner)
        $Msg = ("Change owner`nfrom:{0}`nTo:{1}`n`n" -f $OldOwner, $NewOwner)
        Write-Host $Msg -ForegroundColor Yellow

        $Owner = New-Object System.Security.Principal.NTAccount($NewOwner)

        # Print table of users to change
        $ADObjects | Where-Object { $_.Owner -like ('*{0}*' -f $OldOwner) } | Format-Table -AutoSize

        # Update AD Object to new Owner
        $ADObjects | Where-Object { $_.Owner -like ('*{0}*' -f $OldOwner) } | ForEach-Object {
            # Set vars
            $DN = $_.DistinguishedName

            try {
                $Acl = $null
                $Acl = Get-Acl -Path AD:$DN -ErrorVariable Stop
                $Acl.SetOwner($Owner)

                # Set new ACL
                Set-Acl -Path AD:$DN -AclObject $Acl -ErrorVariable Stop

                Set-Logging -Message ('Update ACL for object {0} objectclass = {1}' -f $_.DistinguishedName, $_.ObjectClass)
            } catch {
                Set-Logging -Message ('Update ACL for object {0} objectclass = {1}' -f $_.DistinguishedName, $_.ObjectClass) -Type 'Error'
            }
        }
    } else {
        Write-Warning 'We do not find the new owner in Active Directory!'
    }
}
###########################################################################
# Finally
###########################################################################
# Cleaning Up the workspace

###########################################################################
# End
###########################################################################