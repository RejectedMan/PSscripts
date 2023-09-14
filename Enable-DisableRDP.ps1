# This script Enable/Disable RDP-connection on remote computer

$Computer = "PCname" #Input ComputerName here
$ErrCount = 0

# Check availability of computer by network
if (Test-Connection $Computer -Count 1 -Quiet) {
    
    # Get current status
    $RDPstatus = Invoke-Command -ComputerName $Computer -ScriptBlock {
        Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\' -Name "fDenyTSConnections" }
    
    # Assign values to variables depending on the current status 
    if ($RDPstatus.fDenyTSConnections) {
        $CurrentStatus = "Disabled"; $Action = "Enable" ; $RegValue = 0 
    }
    else {
        $CurrentStatus = "Enabled"; $Action = "Disable"; $RegValue = 1
    }

    $Confirm = Read-Host "RDP is"$CurrentStatus". Do you want to "$Action"? (Yes[Default]/No)" # Confirm action
    if ($Confirm.ToLower() -eq "yes" -or $Confirm.ToLower() -eq "y" -or $Confirm -eq "") {
        Invoke-Command -ComputerName $Computer -ArgumentList $RegValue, $Action -ScriptBlock {
            param ($RegValue, $Action)
            # Set registry value
            Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\' -Name "fDenyTSConnections" -Value $RegValue
            if ($? -eq $false) { $ErrCount++ } #check error
            # swicth FW rule
            if ($RegValue -eq 0) { Enable-NetFirewallRule -DisplayGroup "Remote Desktop" } else { Disable-NetFirewallRule -DisplayGroup "Remote Desktop" }
            if ($? -eq $false) { $ErrCount++ } #check error
            If ($ErrCount -gt 0) { write-host "Operation failed" } else { write-host "RDP was"$Action"d" } # Output results
        } 
    }
    elseif ($Confirm.ToLower() -eq "no" -or $Confirm.ToLower() -eq "n" ) { write-host "Operation was canceled."; exit } # Cancel the action
    else { write-host "Incorrect input. Aborted." }
}
else { write-host "Computer "$Computer" is not available" -ForegroundColor Red }