# Reart all computers from list below
$ComputerList = "Computer1", "Computer2", "Computer3"

$RestartCount = 0
$ErrCount = 0

Clear-Host
Write-Host "Computer list:"
$ComputerList | ForEach-Object { Write-Host $_ }
Write-Host "======================================"
$Confirm = Read-Host "Do you want to restart its? (Yes/No)" # Confirm action
if ($Confirm.ToLower() -eq "yes" -or $Confirm.ToLower() -eq "y") {
    $Credential = Get-Credential
    foreach ($computer in $ComputerList) {
        Write-Host "Restarting"$computer
        Restart-Computer -ComputerName $computer -Credential $Credential -Force
        
        if ($?) { $RestartCount++ } else { $ErrCount++ } # Error check
    }
    Write-Host "======================================"
    Write-Host "Operation complete."
    Write-Host "Restarted : "$RestartCount
    Write-Host "Errors : "$ErrCount
}
elseif ($Confirm.ToLower() -eq "no" -or $Confirm.ToLower() -eq "n" ) { write-host "Operation was canceled."; exit } # Cancel the action
else { write-host "Incorrect input. Aborted." }