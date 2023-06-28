#Get network settings of active network adapters from all computers in OU

$OutputData = @()
$ErrList = @()
$Path1 = "C:\Temp\ServerNetworkSettings.csv"        #Output file with results
$Path2 = "C:\Temp\ServerConnectionErrors.csv"       #Output file with errors
$OUpath = "OU=servers,DC=domain,DC=net"             #Organization Unit in AD

#Get computers with OS Windows
Get-ADComputer -Filter { OperatingSystem -like "Windows*" } -SearchBase $OUpath | 
ForEach-Object { 
    Write-Output "================================================"
    Write-Output "Get network settings from "$_.name
    Write-Output "================================================"
    if (Test-Connection -ComputerName $_.name -Quiet) {
        if (Test-WSMan -ComputerName $_.name -ErrorAction SilentlyContinue) {
            #Do it if computer is available by WinRM
            $IFconfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ComputerName $_.name | 
            Where-Object { $_.IPEnabled -eq $True } | Select-Object *
            $Row = New-Object -TypeName PSObject -Property @{
                ServerName       = $_.name
                IFname           = $($IFconfig.Caption) -join ", "
                NetworkAdapter   = $($IFconfig.Description) -join ", "
                MACAddress       = $($IFconfig.MACAddress) -join ", "
                DHCPEnabled      = $($IFconfig.DHCPEnabled) -join ", "
                IPAddress        = $($IFconfig.IPAddress) -join ", "
                IPSubnet         = $($IFconfig.IPSubnet) -join ", "
                DefaultIPGateway = $($IFconfig.DefaultIPGateway) -join ", "
                DNS              = $($IFconfig.DNSServerSearchOrder) -join ", "
            }
            Write-Output $Row
            $OutputData += $Row
        }
        else {
            #Do it if computer is NOT available by WinRM
            $errortext = "Unavailable by WinRM"
            Write-Host $errortext -ForegroundColor Red
            $ErrRow = New-Object -TypeName PSObject -Property @{
                ServerName = $_.name
                Error      = $errortext
            }
            $ErrList += $ErrRow
        }
    }
    else {
        ##Do it if computer is NOT available by network
        $errortext = "Unavailable by network"
        Write-Host $errortext -ForegroundColor Red
        $ErrRow = New-Object -TypeName PSObject -Property @{
            ServerName = $_.name
            Error      = $errortext
        }
        $ErrList += $ErrRow
    }
    Write-Host ""
    Write-Host ""   
}

$OutputData | ConvertTo-Csv -NoTypeInformation -Delimiter ';' | Out-File -FilePath $Path1 -Encoding UTF8
$ErrList | ConvertTo-Csv -NoTypeInformation -Delimiter ';' | Out-File -FilePath $Path2 -Encoding UTF8