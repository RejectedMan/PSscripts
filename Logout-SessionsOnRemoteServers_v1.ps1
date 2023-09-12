#Get active user sessions from remote servers and logout it

$RemoteServers = "server1", "server1"   #List of remote servers
$UserMask = "user*"                     #Select users by mask
$ActiveUsers = @()

#Get data from servers
Clear-Host
Write-Host 'Requesting data... wait'
foreach ($server in $RemoteServers) {
    $sessions = Invoke-Expression -Command "quser /server:$server" | Select-Object -Skip 1
    foreach ($session in $sessions) {
        $user = $session.Substring(1, 18).Trim()
        $sessionId = $session.Substring(42, 2).Trim()
        $sessionstatus = $session.Substring(45, 7).Trim()

        $userObject = [PSCustomObject]@{
            Username   = $user
            SessionID  = $sessionId
            ServerName = $server
            Status     = $sessionstatus
        }

        $ActiveUsers += $userObject
    }
}
#Apply the mask
$ActiveUsers = $ActiveUsers | Where-Object { $_.Username -like $UserMask }
#Print seesion list
Clear-Host
Write-Host '=========================================='
$ActiveUsers | Format-Table -AutoSize
Write-Host '=========================================='
$CountActive = $ActiveUsers | Where-Object { $_.Status -eq "Active" } | Measure-Object | Select-Object -ExpandProperty Count
$CountActive = "Active : " + $CountActive
$CountUsers = "Total : " + $ActiveUsers.Length
Write-Host $CountActive
Write-Host $CountUsers

#Confirm process of logout
$ConfirmAnswer = Read-Host "Do you want to Logout sessions? (Yes/No)"

if ($ConfirmAnswer -eq "Yes" -or $ConfirmAnswer -eq "yes" -or $ConfirmAnswer -eq "Y" -or $ConfirmAnswer -eq "y") {
    $AllOrDisc = Read-Host "Do you want to logout ALL exist sessions or DISCONNECTED only? ( input A for ALL (Default)/ input D for DISCONNECTED only)"
    if ($AllOrDisc -eq "D" -or $AllOrDisc -eq "d") {
        $ActiveUsers = $ActiveUsers | Where-Object { $_.Status -eq "Disc" }
        Write-host "Logout disconnected sessions..."
    }
    elseif ($AllOrDisc -eq "A" -or $AllOrDisc -eq "A" -or $AllOrDisc -eq "") {
        Write-host "Logout all sessions..."
    }
    else { 
        Write-Host "Incorrect input! Operation was canceled" -ForegroundColor Red
        exit 
    }

    foreach ($ActiveSession in $ActiveUsers) {
        $msg = "Logout " + $ActiveSession.Username
        $logoutcmd = "logoff " + $ActiveSession.SessionID + " /server:" + $ActiveSession.ServerName
        Write-Host $msg
        Invoke-Expression -Command $logoutcmd
    }
    $CountDisconnected = "Disconnected : " + $ActiveUsers.Length + " sessions"
    Write-Host "======================================"
    Write-Host "Operation complete."
    Write-Host $CountDisconnected
}
elseif ($ConfirmAnswer -eq "No" -or $ConfirmAnswer -eq "no" -or $ConfirmAnswer -eq "N" -or $ConfirmAnswer -eq "n") {
    Write-Host "Operation was canceled"
}
else {
    Write-Host "Incorrect input! Operation was canceled" -ForegroundColor Red
}