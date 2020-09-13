function Get-NetFirewallLogs
{
    Param (
        [Parameter(mandatory=$true)]
        $ComputerName,
        $GroupComputer = $false,
        $LastLines = 100
    )

    Write-Host "Computer: $($ComputerName) " -NoNewline
    if (Test-Connection -Count 1 -ComputerName $ComputerName -Quiet) {
        Write-Host "is accesable!" -ForegroundColor Green

        # Define Path
        $LogFirewall = ('\\{0}\Admin$\System32\LogFiles\Firewall\pfirewall.log' -f $ComputerName)

        # Check if Firewall.log is available
        try {
            # Get File
            $null = Get-Item -Path $LogFirewall -ErrorAction Stop

            # Get Header of Firewall Log
            #Fields: date time action protocol src-ip dst-ip src-port dst-port size tcpflags tcpsyn tcpack tcpwin icmptype icmpcode info path
            $Headers = (Get-Content -Path $LogFirewall -TotalCount 5 | Where-Object {$_ -like '#Fields*'}) -replace('#Fields: ') -split(' ')
            $SelectObjects = "date", "time", "action", "protocol", "src-ip", "src-port", "dst-ip", "dst-port"

            Write-Host 'Information:' -ForegroundColor Yellow
            Write-Host 'We only display Firewall entries that do not match the following types!'
            Write-Host "- Broadcasts (255.255.255.255)`n- Multicats (224.0.0.252) and`n- Service discovery protocol (239.255.255.250)" -ForegroundColor Yellow


            # If GroupComputer is TRUE
            if ($GroupComputer) {
                # Read Firewall Log
                Import-Csv -Header $Headers -Path $LogFirewall -Delimiter ' ' |
                    Select-Object -Skip 5 |
                    Select-Object -Property $SelectObjects |
                    Where-Object {(($_.'dst-ip' -ne '239.255.255.250') -and ($_.'dst-ip' -ne '255.255.255.255') -and ($_.'dst-ip' -ne '224.0.0.252'))} |
                    Group-Object -Property src-ip,dst-port, action |
                    Select-Object Name, Count | Out-GridView
            } else {
                Import-Csv -Header $Headers -Path $LogFirewall -Delimiter ' '|
                    Select-Object -Skip 5 -Property $SelectObjects -Last $LastLines |
                    Where-Object {(($_.'dst-ip' -ne '239.255.255.250') -and ($_.'dst-ip' -ne '255.255.255.255') -and ($_.'dst-ip' -ne '224.0.0.252'))} |
                    Out-GridView

            }
        } catch {
            Write-Warning "Path to Firewall Log is not available...!"
        }

    } else {
        Write-Host "is not accesable!" -ForegroundColor Red
    }
}