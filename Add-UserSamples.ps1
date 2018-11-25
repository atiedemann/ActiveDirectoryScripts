<#

    Description:    This Script creates some users from an csv file
                    in format Lastname,Firstname
    Author:         Arne Tiedemann
    Date:           2018-11-25
#>
$OU = 'OU=User,OU=Company,dc=domain,dc=com'
$Users = Import-Csv -Path "Path2Csv\Namelist.csv" -Encoding UTF8
$UPNDomain = 'Domain.tld'
$Country = 'DE'

foreach($User in $Users) {
    #Check if givenName has special german characters
    $GivenName = $User.Firstname `
        -replace('ä','ae') `
        -replace('ö','oe') `
        -replace('ü','ue') `
        -replace('ß','ss')

    #Check if surname has special german characters
    $Surname = $User.Lastname `
        -replace('ä','ae') `
        -replace('ö','oe') `
        -replace('ü','ue') `
        -replace('ß','ss')

    # Build name
    $Name = ('{0}, {1}' -f $Surname, $GivenName) `

    # Build displayname
    $DisplayName = ('{0}, {1}' -f $User.LastName, $User.Firstname)

    # Build sAMAccountName and check if longer than 20 characters
    $sAMAccountName = ('{0}.{1}' -f $GivenName, $Surname)

    if ($sAMAccountName.Length -gt 20) {
        $sAMAccountName = $sAMAccountName.Substring(0,20)
    }

    # Build userPrincipalName
    $userPrincipalName = ('{0}.{1}@{2}' -f $GivenName, $Surname, $UPNDomain)

    # Build Password
    $newPassword = $null
    $rand = New-Object System.Random
    1..16 | ForEach-Object { $newPassword = $newPassword + [char]$rand.next(33,127) }

    # ConvertTo Accountpassword
    $AccountPassword = $newPassword | ConvertTo-SecureString -AsPlainText -Force

    # Try if user exists
    try {
        Get-ADUser -Identity $sAMAccountName -ErrorAction Stop
    } catch {
        # user does not we create this user
        New-ADUser `
            -Name $Name `
            -DisplayName $DisplayName `
            -GivenName $User.Firstname `
            -Surname $User.Lastname `
            -UserPrincipalName $userPrincipalName `
            -SamAccountName $sAMAccountName `
            -AccountPassword $AccountPassword `
            -Path $OU `
            -Enabled $true `
            -Country $Country
    }
}

