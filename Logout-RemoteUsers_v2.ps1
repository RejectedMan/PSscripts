# Get information about active sessions from Remote Desktop Connection Broker server
# Logout ALL or DISCONNECTED sessions (There is able to chose)

$RDCBserver = "RDCB-SERVER.yourcompany.com"      #RD Connection Broker server name

$ActiveSessions = Get-RDUserSession -ConnectionBroker $RDCBserver  #Get all active sessions
$DisconnectedUsers = $ActiveSessions |  Where-Object { $_.SessionState -eq 'STATE_DISCONNECTED' } #Filter only diconnected

#Print session list
$ActiveSessions | Sort-Object { $_.Username } | Format-Table Username, HostServer, UnifiedSessionID, SessionState
Write-Host '=========================================='
Write-Host  "Active Sessions      : " $ActiveSessions.Count
Write-Host  "Disconnected Sessions: " $DisconnectedUsers.Count

#Confirm process of logout
$ConfirmAnswer = Read-Host "Do you want to Logout sessions? (Yes/No)"

if ($ConfirmAnswer -eq "Yes" -or $ConfirmAnswer -eq "yes" -or $ConfirmAnswer -eq "Y" -or $ConfirmAnswer -eq "y") {
    $AllOrDisc = Read-Host "Do you want to logout ALL exist sessions or DISCONNECTED only? ( input A for ALL (Default)/ input D for DISCONNECTED only)"
    if ($AllOrDisc -eq "D" -or $AllOrDisc -eq "d") {
        $SessionList = $DisconnectedUsers
        Write-host "Logout disconnected sessions..."
    }
    elseif ($AllOrDisc -eq "A" -or $AllOrDisc -eq "A" -or $AllOrDisc -eq "") {
        $SessionList = $ActiveSessions
        Write-host "Logout all sessions..."
    }
    else { 
        Write-Host "Incorrect input! Operation was canceled" -ForegroundColor Red
        exit #End script without actions
    }

    $LogoffCount = 0
    $ErrCount = 0
    foreach ($ActiveSession in $SessionList) {
        Write-Host "Logoff User "$ActiveSession.Username" from "$ActiveSession.HostServer
        # Logout session
        Invoke-RDUserLogoff -HostServer $ActiveSession.HostServer -UnifiedSessionID $ActiveSession.UnifiedSessionId -Force
        # Error check
        if ($?) { $LogoffCount++ } else { $ErrCount++ }
    }
    Write-Host "======================================"
    Write-Host "Operation complete."
    Write-Host "Disconnected : "$LogoffCount" sessions"
    Write-Host "Errors : "$ErrCount
}
elseif ($ConfirmAnswer -eq "No" -or $ConfirmAnswer -eq "no" -or $ConfirmAnswer -eq "N" -or $ConfirmAnswer -eq "n") {
    Write-Host "Operation was canceled"
}
else {
    Write-Host "Incorrect input! Operation was canceled" -ForegroundColor Red
}