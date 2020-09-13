function Add-DHCPv4Reservation
{
<#
.SYNOPSIS
This Cmdlet add an dhcp reservation on both dhcp servers

.DESCRIPTION
This Cmdlet add an dhcp reservation on both dhcp servers

.PARAMETER ScopeID
Defines the DHCP Scope where you want to add the reservation

.PARAMETER IPv4Address
Defines the IP v4 Address for the new DHCP reservation

.PARAMETER MACAddress
Defines the MAC Address for the new reservation


Format:
001122334455
00:11:22:33:44:55
00-11-22-33-44-55

.PARAMETER Server
Define one or multible server 

.EXAMPLE
Add-DHCPv4Reservation -ScopeID 172.16.0.0 -IPv4Address 172.16.0.4 -MACAddress 005056b02078 -Name Server1

#>
    Param(
        [Parameter(Mandatory=$true)]
        [STRING]$ScopeID,

        [Parameter(Mandatory=$true)]
        [STRING]$IPv4Address,

        [Parameter(Mandatory=$true)]
        [STRING]$MACAddress,

        [Parameter(Mandatory=$true)]
        [STRING]$Name,

        [Parameter(Mandatory=$true)]
        $Server
    )

    # Convrtz MAC Address
    if ($MACAddress.Length -eq 12 -and $MACAddress -notmatch ':' -and $MACAddress -notmatch '-') {
        $MACAddress = $MACAddress -replace "([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])", '$1$2-$3$4-$5$6-$7$8-$9$10-$11$12'
    }

    if ($MACAddress -match ':') {
        $MACAddress = $MACAddress -replace(':','-')
    }


    foreach($S in $Server) {
        $Reservation = $false
        # Get reservation from Server
        $Reservation = Get-DhcpServerv4Reservation -ScopeId $ScopeID -ComputerName $S -ErrorAction SilentlyContinue | 
            Where-Object { $_.IPAddress -eq $IPv4Address -or $_.ClientID -eq $MACAddress }

        if ($Reservation) {
            Write-Host ('Reservation exists on Server {2}: IPv4Address ({0}) and MAC ({1})' -f $IPv4Address, $MACAddress, $S)
        } else {
            Add-DhcpServerv4Reservation -ComputerName $S -ScopeId $ScopeID -IPAddress $IPv4Address -ClientId $MACAddress -Name $Name -Type Both

            if ($?) {
                Write-Host ('Reservation added on Server {2}: IPv4Address ({0}) and MAC ({1})' -f $IPv4Address, $MACAddress, $S)
            }
        }
    }
}

function Remove-DHCPv4Reservation
{
<#
.SYNOPSIS
This Cmdlet add an dhcp reservation on both dhcp servers

.DESCRIPTION
This Cmdlet add an dhcp reservation on both dhcp servers

.PARAMETER ScopeID
Defines the DHCP Scope where you want to add the reservation

.PARAMETER MACAddress
Defines the MAC Address for the new reservation

Format:
001122334455
00:11:22:33:44:55
00-11-22-33-44-55

.PARAMETER Server
Define one or multible server 

.EXAMPLE
Add-DHCPv4Reservation -ScopeID 172.16.0.0 -IPv4Address 172.16.0.4 -MACAddress 005056b02089 -Name Server1

#>
    Param(
        [Parameter(Mandatory=$true)]
        [STRING]$ScopeID,

        [Parameter(Mandatory=$true)]
        [STRING]$MACAddress,
        
        [Parameter(Mandatory=$true)]
        $Server
    )

    # Convrtz MAC Address
    if ($MACAddress.Length -eq 12 -and $MACAddress -notmatch ':' -and $MACAddress -notmatch '-') {
        $MACAddress = $MACAddress -replace "([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])", '$1$2-$3$4-$5$6-$7$8-$9$10-$11$12'
    }

    if ($MACAddress -match ':') {
        $MACAddress = $MACAddress -replace(':','-')
    }

    foreach($S in $Server) {
        $Reservation = $false
        # Get reservation from Server
        $Reservation = Get-DhcpServerv4Reservation -ScopeId $ScopeID -ComputerName $S -ErrorAction SilentlyContinue | ? { $_.ClientID -eq $MACAddress }

        if ($Reservation) {
            Write-Host 'Switch Delete was specified! We try to delete the Reservation: ' -NoNewline
            try {
                $Reservation | Remove-DhcpServerv4Reservation -ComputerName $S
                Write-Host 'successfully' -ForegroundColor Green
            } catch {
                Write-Host 'failed' -ForegroundColor Yellow
            }
        }
    }
}

function Get-DhcpLog
{
    Param(
        [Parameter(Mandatory=$false)]
        $MinutesBack = 15,

        [Parameter(Mandatory=$true)]
        $Server        
    )


    $PathLogfile = ('DHCPSrvLog-{0}.log' -f (Get-Date -UFormat "%A").SubString(0,3))
    $Logfiles = foreach($Srv in $ServerDHCP) { '\\{0}\admin$\System32\dhcp\{1}' -f $Srv, $PathLogfile }

    $CsvHeader = 'ID','Datum','Zeit','Beschreibung','IP-Adresse','Hostname','MAC-Adresse','Benutzername','Transaktions-ID',' QErgebnis','Probezeit','Korrelations-ID','DHCID','Herausgeberklasse(Hex)','Herausgeberklasse(ASCII)','Benutzerklasse(Hex)','Benutzerklasse(ASCII)','Relay-Agent-Informationen','DNS-Registrierungsfehler'
    $CsvSkip = 34

    $LogDHCP = @()

    foreach($Log in $Logfiles)
    {
        # Identify the Server Address
        $Server = $Log.SubString(2,7)
        Write-Host 'Getting logfiles from Server: ' -NoNewline
        Write-Host $Server -ForegroundColor Green


        $LogDHCP += Import-Csv -Path $Log -Header $CsvHeader -Delimiter ',' -Encoding UTF8 |
            Where-Object { $_.'IP-Adresse' -notlike '' } |
            Select-Object -Skip $CsvSkip -Property `
                @{Name="Date"; Expression = {Get-Date -Date $_.Datum -Format 'MM/dd/yy'}}, `
                @{Name="Time"; Expression = {Get-Date -Date $_.'Zeit' -Format 'HH:mm:ss'}}, `
                @{Name="ServerDHCP"; Expression = { $Server.ToUpper() } },
                'Beschreibung','IP-Adresse','Hostname','MAC-Adresse','DNS-Registrierungsfehler' |
            Where-Object { (Get-Date  -Date $_.Time) -gt (Get-Date).AddMinutes(-$MinutesBack) }

    }

    $LogDHCP | Sort-Object -Property Date,Time | Out-GridView

}