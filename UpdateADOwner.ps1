<#
.SYNOPSIS
This script identifies AD Objects that have an owner that points to an orphanded AD user object.

.DESCRIPTION
This script identifies AD Objects that have an owner that points to an orphanded AD user object.
the second part of this script can change the orphanded owners to an existing user.

.PARAMETER ObjectType
This defines the objectclass that we want to get from Active Directory
Valid values are:
- Computer
- Group
- User
- OrganizationalUnit

Computer is the default objectType

.PARAMETER ReloadData
This is a SWITCH parameter!
If this parameter is used, Acrtive Directory data will be reloaded.

.PARAMETER ChangeOwner
This is a SWITCH parameter!
If this parameter will be used, owner will bechanged for the objects.

.PARAMETER OldOwner
This paramater specifies the sAMAccountName from changing owner

.PARAMETER NewOwner
This paramter specifies the sAMAccountName from the new owner

.PARAMETER ShowOwners
This will only get the object from Active Directory and show the output in a GridView

.EXAMPLE Default run
Start the script without parameter will first load all data and show a table with is grouped by object owner.

.EXAMPLE Change objects
-ChangeOwner -OldOwner 'sAMAccountName from old owner' -NewOwner 'sAMAccountName from new owner'

.EXAMPLE ReloadData
-ReloadData

.NOTES
Author: Arne Tiedemann
Company: Skaylink GmbH
Email: Arne.Tiedemann@Skaylink.com

.LINK
https://github.com/atiedemann/ActiveDirectoryScripts

#>
[CmdletBinding(DefaultParametersetName = 'ShowOwners')]
Param(
    [ValidateSet('User', 'Group', 'Computer', 'OrganizationalUnit')]
    [Parameter(ParameterSetName = 'ChangeOwner')]
    [Parameter(ParameterSetName = 'ShowOwners')]
    [string]$ObjectType = 'Computer',

    [Parameter(ParameterSetName = 'Reload')]
    [Parameter(ParameterSetName = 'ShowOwners')]
    [Parameter(ParameterSetName = 'ChangeOwner')]
    [Switch]$ReloadData = $false,

    [Parameter(Mandatory = $false, ParameterSetName = 'ChangeOwner')]
    [Switch]$ChangeOwner,


    [Parameter(Mandatory = $true, ParameterSetName = 'ChangeOwner')]
    [STRING]$OldOwner,

    [Parameter(Mandatory = $true, ParameterSetName = 'ChangeOwner')]
    [STRING]$NewOwner,

    [Parameter(ParameterSetName = 'ShowOwners')]
    [bool]$ShowOwners = $true,

    [ValidateSet('User', 'Group', 'Computer', 'OrganizationalUnit')]
    [Parameter(ParameterSetName = 'ChangeOwner')]
    [Parameter(ParameterSetName = 'ShowOwners')]
    [bool]$LogConsole = $false,

    [ValidateSet('User', 'Group', 'Computer', 'OrganizationalUnit')]
    [Parameter(ParameterSetName = 'ChangeOwner')]
    [Parameter(ParameterSetName = 'ShowOwners')]
    [bool]$LogFile = $true
)
###########################################################################
# Variables
###########################################################################
$PathLogfile = ('{0}\UpdateADOwner.log' -f $PSScriptRoot)
$ownerLogPath = ('{0}\{1}_UpdateADOwner_Owners_{2}.log' -f $PSScriptRoot, (Get-Date -Format 'yyyy-MM-dd_HHmmss'), $ObjectType)

$LogToConsole = $LogConsole
$LogFileOutput = $LogFile

if ($ReloadData -eq $true -or $ADObjects.Count -eq 0 -or $ObjectType -ne $ADObjects[0].objectClass) {
    $ADObjects = [System.Collections.Generic.List[PSObject]]::New()

    # Reload object
    $reloadObject = $true
} else { $reloadObject = $false }
###########################################################################
# Functions
###########################################################################
function Set-Logging {
    Param(
        [Parameter(Mandatory = $true)]
        $Message,
        $Severity = 'Information'
    )

    $Message = ('{0};{1};{2}' -f (Get-Date -Format 'yyyy-MM-dd;HH:mm:ss'), $Severity, $Message)

    # Output
    if ($LogFileOutput -eq $true) {
        try {
            $Message | Out-File -FilePath $PathLogfile -Append -ErrorAction Stop
        } catch {
            Write-Warning ('Error in Line: {0}' -f $_.InvocationInfo.ScriptLineNumber)
            Write-Warning ('Error Message: {0}' -f $_.Exception.Message)
        }
    }

    # Define output color
    switch ($Severity) {
        'Warning' {
            $Color = 'Yellow'
        }
        'Error' {
            $Color = 'Red'
        }
        Default {
            $Color = 'Green'
        }
    }

    # Split Message
    $Message = $Message.Split(';')
    $Color = @('White', 'White', $Color)
    # Console Output
    if ($LogToConsole -eq $true) {
        Write-Message -Text $Message -Colors $Color
    }
}

function Write-Message {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Text,

        [Parameter(Mandatory = $false)]
        $Colors
    )

    begin {
        $Count = $Text.Count - $Colors.Count
        for ($i = 0; $i -lt $Count; $i++) {
            $Colors += 'Gray'
        }

    }

    process {
        # Define the count
        $Count = 1
        foreach ($i in $Text) {
            if ($Count -eq $Text.Count) {
                # Last text
                Write-Host (' {0}' -f $i) -ForegroundColor $Colors[$Count - 1]
            } else {
                if ($Count -eq 1) {
                    Write-Host ('{0}' -f $i) -ForegroundColor $Colors[$Count - 1] -NoNewline
                } elseif ($Count -eq 3) {
                    Write-Host (' {0,12}' -f $i) -ForegroundColor $Colors[$Count - 1] -NoNewline
                } elseif ($Count -gt 1) {
                    Write-Host (' {0}' -f $i) -ForegroundColor $Colors[$Count - 1] -NoNewline
                } else {
                    Write-Host $i -ForegroundColor $Colors[$Count - 1] -NoNewline
                }
            }
            # Inkrement count
            $Count++
        }
    }

    end {
        # do nothing
    }
}
###########################################################################
# Script
###########################################################################
if ($LogToConsole -eq $false){
    # for logging we need logtoconsole
    $LogToConsole = $true

    Set-Logging -Message 'Information about log to console' -Severity 'Warning'
    Set-Logging -Message 'You will get no logging output to console!'
    Set-Logging -Message 'If you want output to console, use parameter -LogToConsole:$true'

    # But the user dont want to log to console
    $LogToConsole = $false
}

Set-Logging -Message 'Start identifying active directory objects'
if ($LogFileOutput -eq $true) {
    Set-Logging -Message ('All logging information will be saved to this file: {0}' -f $PathLogfile)
}

# Getting Data from Active Directory
if ($reloadObject -eq $true) {
    Set-Logging -Message '##########################################'
    Set-Logging -Message 'Getting Active Directory objects...'
    Set-Logging -Message '##########################################'
    # Get objects by type
    switch ($ObjectType) {
        Group {
            $objects = Get-ADGroup -Filter * | Select-Object Name, ObjectClass, DistinguishedName
        }
        User {
            $objects = Get-ADUser -Filter * | Select-Object Name, ObjectClass, DistinguishedName
        }
        OrganizationalUnit {
            $objects = Get-ADOrganizationalUnit -Filter * | Select-Object Name, ObjectClass, DistinguishedName
        }
        # Default is AD Computer
        Default {
            $objects = Get-ADComputer -Filter * | Select-Object Name, ObjectClass, DistinguishedName
        }
    }

    # Build object with owner information
    foreach ($Obj in $Objects) {
        # Write Log
        Set-Logging -Message ('Getting object information from {0}' -f $Obj.Name)
        # Get the acl from AD Object
        $Acl = $null
        try {
            $Acl = Get-Acl -Path ('Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/{0}' -f $Obj.DistinguishedName) -ErrorAction Stop
        } catch {
            Set-Logging -Message $_.Exception.Message -Severity 'Error'
            Set-Logging -Message ('Failed object: {0}' -f $Obj.DistinguishedName) -Severity 'Warning'
        }

        # Add object to arraylist
        $ADObjects.Add([PSCustomObject]@{
                Name              = $Obj.Name
                DistinguishedName = $Obj.DistinguishedName
                ObjectClass       = $Obj.ObjectClass
                Owner             = $Acl.Owner
            })
    }
}

# Only show an object list with group by owners
if ($ShowOwners -eq $true -and $ChangeOwner -eq $false) {
    $ADObjectsOutput = $ADObjects | Group-Object -Property Owner | Sort-Object -Property Count | Select-Object Count, Name | Out-GridView -PassThru

    # If select owners for output
    if ($ADObjectsOutput.Count -gt 0){
        $ADObjects | Where-Object { $_.Owner -in $ADObjectsOutput.Name } | Sort-Object -Property Name | Export-Csv -NoTypeInformation -Path ('{0}\UpdateADOwners_Export.csv' -f $PSScriptRoot)
    }
}

# if change owners is active, do it
if ($ChangeOwner -eq $true -and $ADObjects.Count -gt 0) {
    Set-Logging -Message 'Changing Active Directory objects...'
    # get basic variables
    $Domain = (Get-ADDomain).NetBIOSName

    # Check if new owner exists
    $Result = Get-ADObject -Filter { (sAMAccountName -eq $NewOwner -and (ObjectClass -eq 'user' -or ObjectClass -eq 'group')) }

    # Run only if new owner exists
    if ($Result.Name -eq $NewOwner) {
        $NewOwner = ('{0}\{1}' -f $Domain, $NewOwner)
        Set-Logging -Message 'Change owner' -Severity 'Warning'
        Set-Logging -Message ('From: {0}' -f $OldOwner) -Severity 'Warning'
        Set-Logging -Message ('To:   {0}' -f $NewOwner) -Severity 'Warning'

        # Set new owner object
        $Owner = New-Object System.Security.Principal.NTAccount($NewOwner)
        $processedObjects = [System.Collections.Generic.List[PSObject]]::New()

        # Define count
        $objCount = 0

        # Update AD Object to new Owner
        $ADObjects | Where-Object { $_.Owner -eq ('{0}\{1}' -f $Domain, $OldOwner) } | ForEach-Object {
            # Set vars
            $objCount++
            $item = $_
            $DN = $item.DistinguishedName

            try {
                $Acl = $null
                $Acl = Get-Acl -Path ('"Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/{0}' -f $DN) -ErrorVariable Stop
                $Acl.SetOwner($Owner)

                # Set new ACL
                $null = Set-Acl -Path AD:$DN -AclObject $Acl -ErrorVariable Stop

                $processedObjects.Add([PSCustomObject]@{
                    Name = $item.Name
                    DistinguishedName = $item.DistinguishedName
                    ObjectClass = $item.ObjectClass
                    OldOwner = $item.Owner
                    NewOwner = $NewOwner
                    Successful = $true
                })

                Set-Logging -Message ('Update ACL for object {0}' -f $item.DistinguishedName)
            } catch {
                Set-Logging -Message ('Update ACL for object {0}' -f $item.DistinguishedName) -Severity 'Error'
                Set-Logging -Message $_.Exception.Message -Severity 'Error'

                $processedObjects.Add([PSCustomObject]@{
                    Name = $item.Name
                    DistinguishedName = $item.DistinguishedName
                    ObjectClass = $item.ObjectClass
                    OldOwner = $item.Owner
                    NewOwner = $NewOwner
                    Successful = $false
                })
            }
        }

        # Log the found Objects
        $processedObjects | Export-Csv -Path $ownerLogPath -NoTypeInformation -Force

        $LogToConsole = $true
        # check if objects found
        if ($processedObjects -eq 0){
            Set-Logging -Message 'No object where found to update.' -Severity 'Warning'
        } else {
            Set-Logging -Message '################### Update Information ###################'
            Set-Logging -Message ('{0} object(s) updated successfully.' -f $processedObjects.Count)
            Set-Logging -Message '##########################################################'

            $processedObjects | ft -AutoSize
        }
    } else {
        Set-Logging -Message 'We do not find the new owner in Active Directory!' -Severity 'Warning'
    }
}
###########################################################################
# Finally
###########################################################################
# Cleaning Up the workspace

###########################################################################
# End
###########################################################################