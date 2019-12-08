$DCs = 1..5 | % { "DC0$_"}
$BindType = @('Simple','Unsigned')
$Users = @('User1','Ldapuser','FWUser1','LdapQuery')

$Array = [System.Collections.Generic.List[PSObject]]::New()

1..1112 | ForEach-Object {
    $Array.add([pscustomobject]@{
        DomainController = ($DCs[(Get-Random -Minimum 0 -Maximum ($DCs.Count))])
        IPAddress = ('192.168.200.{0}' -f (Get-Random -Minimum 1 -Maximum 100))
        Port = (Get-Random -Minimum 49152 -Maximum 65535)
        User = ($Users[(Get-Random -Minimum 0 -Maximum ($Users.Count))])
        BindType = ($BindType[(Get-Random -Minimum 0 -Maximum ($BindType.Count))])
    })
}

$Array | Export-Csv -Path $env:PUBLIC\Documents\InsecureLDAPBinds.csv -NoTypeInformation

$Array = [System.Collections.Generic.List[PSObject]]::New()

1..11 | ForEach-Object {
    $Array.add([pscustomobject]@{
        DomainController = ($DCs[(Get-Random -Minimum 0 -Maximum ($DCs.Count))])
        Count = (Get-Random -Minimum 0 -Maximum 30000)
    })
}

$Array | Export-Csv -Path $env:PUBLIC\Documents\InsecureLDAPCount.csv -NoTypeInformation