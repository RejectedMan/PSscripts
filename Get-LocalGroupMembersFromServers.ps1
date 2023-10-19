# Getting members from local groups in computers in particular OU

$Groups = "Administrators", "Remote Desktop Users"                      ## Group List
$OUpath = "OU=Servers,DC=yourdomain,DC=com"                             ## OU path 
$ExceptionNameWords = "DHCP|DFS"                                        ## Words in ComputerName for exception
$ExceptionGroupNames = "GR-RemoteDesktopUsers-|GR-ServerLocalAdmin-"    ## Words in GroupName for exception
$CSVpath = "C:\Temp\LocalGroupMembers.csv"                              ## Path for results

$MemberList = @()       ## Array for result
$ErrorList = @()
# Get computer list
$ServerList = Get-ADComputer -Filter { OperatingSystem -like "Windows*"  -and Enabled -eq $true } -SearchBase $OUpath 
if ($ExceptionNameWords -ne "") { $ServerList = $ServerList | Where-Object { $_.Name -notmatch $ExceptionNameWords } }
# Get data from each server
foreach ($server in $ServerList) {
    ## test connection
    if (Test-Connection $server.name -Count 1 -Quiet) {
        $WinRMCheck = [bool](Test-NetConnection -ComputerName $server.name -CommonTCPPort "WINRM" -InformationLevel Quiet)
        if ($WinRMCheck) {
            write-host $server.Name -ForegroundColor Green
            foreach ($GroupName in $Groups) {
                Write-Host "Members from "$GroupName" group" -ForegroundColor Yellow
                ## Get data from remote computer
                $GetList = Invoke-Command -ComputerName $server.Name -ArgumentList $GroupName -ScriptBlock {
                    Param($GroupName)
                    Get-LocalGroupMember $GroupName | Select-Object -ExpandProperty Name
                }
                ## Print results on screen
                Write-Output $GetList
                write-host "----------------------------------------------"
                ## Add data to result array
                foreach ($member in $GetList) {
                    $MemberList += [PSCustomObject]@{ Server = $server.Name; Group = $GroupName; Member = $member }
                }
            }
        }
        else { Write-Host $server.Name": WinRM connection is unavailable" -ForegroundColor Red; $ErrorList += $server.Name }
    }
    else { write-host "Server"$server.Name" is unavailable" -ForegroundColor Red; $ErrorList += $server.Name }

}
# Output data to CSV-file with exception
$MemberList | Where-Object { $_.Member -notmatch $ExceptionGroupNames } | 
Export-Csv -Path $CSVpath -NoTypeInformation -Delimiter ";"

write-host "`nError server list:" -ForegroundColor Red
$ErrorList
write-host "`nOperation is completed." -ForegroundColor Green