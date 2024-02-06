# Getting Bitlocker Recovery Key from AD when Recovery Key ID is known only

$IDSearchString = "4F34BA36"   # Part of Recovery Key ID from Bitlocker screen

$IDSearchString = "*" + $IDSearchString + "*"
$BLkey = Get-Item ("AD:\", (Get-ADObject -LDAPFilter "(objectClass=msFVE-RecoveryInformation)" | Where-Object { $_.name -like $IDSearchString }).distinguishedName -join "")  -properties msFVE-RecoveryPassword
If ($BLkey.name -ne $null) {
    Write-Host "ComputerName   : "($BLkey.distinguishedName | Select-String -Pattern '\,CN=(.*?)\,').Matches.Groups[1].Value
    Write-Host "Recovery Key ID: "($BLkey.Name | Select-String -Pattern '\{(.*?)\}').Matches.Groups[1].Value
    Write-Host "Recovery Key   : "$BLkey."msFVE-RecoveryPassword" -ForegroundColor Green
}
else {
    Write-Host "Recovery Key ID wasn't found" -ForegroundColor red
}

