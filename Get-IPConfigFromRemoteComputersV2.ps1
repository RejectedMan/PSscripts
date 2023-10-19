# Getting IP-configuration from active network adapters
# Computer list is gotten from AD

$OUpath = "OU=Computers,DC=yourdomain,DC=com"
$ExceptionNameWords = ""                    ## Can be empty
$CSVpath = "C:\Temp\IPconfigList.csv"       ## Output CSV-file

$IPConfigList = @()
$ErrorList = @()
Clear-Host

# Getting computer list
$ComputerList = Get-ADComputer -Filter { OperatingSystem -like "Windows*"  -and Enabled -eq $true } -SearchBase $OUpath 
if ($ExceptionNameWords -ne "") { $ComputerList = $ComputerList | Where-Object { $_.Name -notmatch $ExceptionNameWords } }

# Getting data from each computer
foreach ($computer in $ComputerList) {
    ## test connection
    if (Test-Connection $computer.name -Count 1 -Quiet) {
        $WinRMCheck = [bool](Test-NetConnection -ComputerName $computer.name -CommonTCPPort "WINRM" -InformationLevel Quiet)
        if ($WinRMCheck) {
            ## Getting data from remote computer
            $GetIPConfig = Invoke-Command -ComputerName $computer.Name -ScriptBlock {
                get-netIPConfiguration -InterfaceAlias Ethernet* -Detailed | Where-Object { $_.NetAdapter.Status -eq 'Up' }
            }

            ## Add data to result array
            foreach ($adapter in $GetIPConfig) {
                $IPConfigList += [PSCustomObject]@{ 
                    Computer           = $adapter.ComputerName
                    AdapterName        = $adapter.InterfaceAlias
                    AdapterDescription = $adapter.InterfaceDescription
                    MACAddress         = $adapter.NetAdapter.LinkLayerAddress
                    DHCP               = $adapter.NetIPv4Interface.DHCP
                    IPAddress          = $($adapter.IPv4Address.IPAddress) -join ", "
                    DefaultIPGateway   = $adapter.IPv4DefaultGateway.NextHop
                    DNS                = $($adapter.DNSServer.ServerAddresses) -join ", "
                }
                ## Print results on screen
                $IPConfigList[-1]
            }
        }
        else { Write-Host $computer.Name": WinRM connection is unavailable" -ForegroundColor Red; $ErrorList += $computer.Name }
    }
    else { write-host "Computer"$computer.Name" is unavailable" -ForegroundColor Red; $ErrorList += $computer.Name }

}
# Output data to CSV-file
$IPConfigList | Export-Csv -Path $CSVpath -NoTypeInformation -Delimiter ";"

write-host "`nError server list:" -ForegroundColor Red
$ErrorList
write-host "`nOperation is completed." -ForegroundColor Green
