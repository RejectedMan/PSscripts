#Get active usre sessions from remote servers

$RemoteServers = "server1", "server2"  #List of remote servers
$ActiveUsers = @()

Write-Host 'Requesting data... wait'
foreach ($server in $RemoteServers) {
    $sessions = Invoke-Expression -Command "quser /server:$server" | Select-Object -Skip 1
    foreach ($session in $sessions) {
        $user = $session.Substring(1, 18).Trim()
        $sessionId = $session.Substring(42, 2).Trim()

        $userObject = [PSCustomObject]@{
            Username   = $user
            SessionID  = $sessionId
            ServerName = $server
        }

        $ActiveUsers += $userObject
    }
}
Clear-Host
Write-Host '=========================================='
$ActiveUsers | Format-Table
Write-Host '=========================================='
$CountUsers = "Total :" + $ActiveUsers.Length
Write-Host $CountUsers