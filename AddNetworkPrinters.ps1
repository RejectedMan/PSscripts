 установить все доступные принтеры на сервере печати на УДАЛЕННОМ компьютере пользователя:
$RemoteComputer = "ws00sr12"
$ServerName = "sn001sradhcpprt"
$Printers = Get-Printer -ComputerName $ServerName | Where-Object {$_.PrinterStatus -ne 'Offline' -and $_.Shared -eq 'True'}
foreach ($Printer in $Printers){
    $prt = "\\$ServerName\$($Printer.ShareName)"
    Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {
        Param($prt)
        Write-Output "Adding $prt"
        iex "RUNDLL32 PRINTUI.DLL,PrintUIEntry /ga /n""$prt"""
        } -ArgumentList $prt
}
Start-Sleep -Seconds 10
Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {
    Write-Output "Restart Print Spoller"
    Stop-Service -Name spooler -Force
    Start-Sleep -Seconds 5
    Start-Service -Name spooler
    }
