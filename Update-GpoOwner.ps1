<#
.SYNOPSIS
    This script will change file/directory and Gpo AD Object ownerchip

.DESCRIPTION
    This script will change file/directory and Gpo AD Object
    ownerchip to Domain Admins or BUILTIN\Administrators
    for securityy

.PARAMETER NewOwnerSelection
    Use this parameter only for unattend execution

.EXAMPLE .\Update-Gpo-Owner.ps1
    Run the script and ask for new owner account

.EXAMPLE .\Update-Gpo-Owner.ps1 -NewOwnerSelection 1
    Run in unattend mode and select Domain Admins as new owner

.EXAMPLE .\Update-Gpo-Owner.ps1 -NewOwnerSelection 2
    Run in unattend mode and select Adminstrators as new owner

.INPUTS

.OUTPUTS
    If select 0 the output is a table with existing owners

.NOTES

.LINK

.EXTERNALHELP
#>
<#
Author:			Arne Tiedemann Skaylink GmbH
E-Mail:			Arne.Tiedemann@skaylink.com
Date:			2026-02-09
Description:	This script will change file/directory and Gpo AD Object
                ownerchip to Domain Admins or BUILTIN\Administrators
                for security
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$NewOwnerSelection
)
###########################################################################
# dot source files
###########################################################################

###########################################################################
# Variables
###########################################################################
# Define SIDs and accounts
$domain = Get-ADDomain
$domainSID = $domain.DomainSID.Value
$domainAdminsSID = ('{0}-512' -f $domainSID)
$administratorsSID = 'S-1-5-32-544'

$domainAdminsAccount = (New-Object System.Security.Principal.SecurityIdentifier($domainAdminsSID)).Translate([System.Security.Principal.NTAccount])
$administratorsAccount = (New-Object System.Security.Principal.SecurityIdentifier($administratorsSID)).Translate([System.Security.Principal.NTAccount])


# Build SYSVOL\Policies path
$domainFQDN = $env:USERDNSDOMAIN
$sysvolRoot = ('\\{0}\SYSVOL\{0}\Policies' -f $domainFQDN)

###########################################################################
# Functions
###########################################################################

###########################################################################
# Script
###########################################################################
# Check SYSVOL path exists
if (-not (Test-Path $sysvolRoot)) {
    Write-Error "SYSVOL path not found: $sysvolRoot"
    return
}
Write-Host "Processing SYSVOL Policies folder: $sysvolRoot" -ForegroundColor Green

Write-Host '################################################################'
Write-Host 'Change Grouppolicy owner rights to:'
Write-Host '0: No Change, just show current owner'
Write-Host '1: Change to Domain Admins'
Write-Host '2: Change to Administrators'
Write-Host '################################################################'

# Check if predefined selection was made
if ($NewOwnerSelection -eq $false) {
    $choice = Read-Host 'Enter your choice (0, 1, or 2)'
} else {
    $choice = $NewOwnerSelection
}

# Select target owner
switch ($choice) {
    '0' {
        Write-Host 'No changes will be made. Displaying current owners...' -ForegroundColor Yellow
    }
    '1' {
        $newOwner = $domainAdminsAccount
        Write-Host 'Selected: Change owner to Domain Admins' -ForegroundColor Green
    }
    '2' {
        $newOwner = $administratorsAccount
        Write-Host 'Selected: Change owner to Administrators' -ForegroundColor Green
    }
    default {
        Write-Error 'Invalid choice. Please run the script again and select 0, 1, or 2.'
        return
    }
}

# Get all files and folders under Policies, including root
$gpos = Get-GPO -All
$report = [System.Collections.Generic.List[PSObject]]::New()

foreach ($gpo in $gpos) {
    # Check and update AD owner for Gpo object
    $adAcl = Get-Acl -Path AD:"$($gpo.Path)"
    # Validate owner
    if ($adAcl.Owner -ne $newOwner -and $choice -ne 0) {
        Write-Host ('Changing Gpo owner from {0} to {1} on: {2}' -f $adAcl.Owner, $newOwner.Value, $gpo.DisplayName) -ForegroundColor Cyan
        $adAcl.SetOwner($newOwner)

        try {
            # Update Owner
            Set-Acl -Path AD:"$($gpo.Path)" -AclObject $adAcl -ErrorAction Stop
        } catch {
            Write-Warning ('Failed changing Gpo owner for Gpo: {0}: {1}' -f $gpo.DisplayName, $_.Exception.Message)
        }

    }

    # Change owner on root directory
    # Get current owner
    $fileAcl = Get-Acl -Path "$($sysvolRoot)\{$($gpo.Id.guid)}"
    # Change owner only if it's not already Administrators
    if ($fileAcl.owner -ne $newOwner -and $choice -ne 0) {
        Write-Host ('Changing owner from {0} to {1} on: {2}' -f $fileAcl.owner, $newOwner.Value, "$($sysvolRoot)\{$($gpo.Id.guid)}") -ForegroundColor Yellow
        try {
            $fileAcl.SetOwner($newOwner)
            Set-Acl -Path "$($sysvolRoot)\{$($gpo.Id.guid)}" -AclObject $fileAcl -ErrorAction Stop
        } catch {
            Write-Warning ('Failed changing file ownerchip for Gpo: {0}: {1}' -f $gpo.DisplayName, $_.Exception.Message)
        }
    }

    # Change subdirectories
    try {
        if ($choice -ne 0) {
            foreach ($i in (Get-ChildItem -Path "$($sysvolRoot)\{$($gpo.Id.guid)}" -Recurse)) {
                # Get current owner
                $subAcl = Get-Acl $i.FullName

                if ($subAcl.Owner -ne $newOwner) {
                    Write-Host ('Changing owner from {0} to {1} on: {2}' -f $subAcl.owner, $newOwner.Value, $i.Name)
                    $subAcl.SetOwner($newOwner)
                    Set-Acl -Path $i.FullName -AclObject $subAcl -ErrorAction Stop
                }
            }
        }
    } catch {
        Write-Warning ('Failed changing subdirectory file ownerchips for Gpo: {0}: {1}' -f $gpo.DisplayName, $_.Exception.Message)
    }

    $report.Add([PSCustomObject]@{
            Name            = $gpo.DisplayName
            OwnerAdObject   = $adAcl.Owner
            OwnerFileObject = $fileAcl.Owner
        })
}

# Change root foldder
if ($choice -ne 0) {
    $gpo = Get-Item -Path $sysvolRoot # Include root folder
    # Get current owner
    $acl = Get-Acl $gpo.FullName
    $owner = $acl.Owner

    if ($owner -ne $newOwner) {
        Write-Host ('Changing owner from {0} to {1} on: {2}' -f $owner, $newOwner.Value, $gpo.FullName)
        $acl.SetOwner($newOwner)
        Set-Acl -Path $i.FullName -AclObject $acl
    }
}

# Display information
if ($choice -eq 0) {
    Write-Host 'Current GPO Owners:' -ForegroundColor Cyan
    $report | Format-Table -AutoSize
}

###########################################################################
# Finally
###########################################################################
# Cleaning Up the workspace

###########################################################################
# End
###########################################################################


