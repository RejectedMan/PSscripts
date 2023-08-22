# Diactivate all users in Offboarding OU
# Change password
# Restrict change password
# Set Expiration date
# Remove from all AD Groups
# Save Logs and Sent it to email

# Vars
$LogPath = "C:\AutomationLogs"
$ADserver = "dc.yourdomain.com"
$PassCharset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+'   #Password charset
$PassLength = 28                                                                                #Password length
$OffboardingOU = "OU=Offboarding,OU=Users,DC=yourdomain,DC=com"                                 #OU with offboarding users

#SMTP settings
$smtpServer = "smtp.yourdomain.com"         # SMTP-server
$from = "alert@yourdomain.com"             # Sender
$to = "admin@yourdomain.com"       # Recipient
$subject = "Offboarding Automation Alert"   # Subject
$body = "Next Users has changed:`n`n"

$LogFile = $LogPath + "\" + ((get-date).ToString("yyyyMMdd")) + "_Offboarding.txt"
$OffboardingUsers = Get-ADUser -server $ADserver -SearchBase $OffboardingOU -Filter * -Properties SamAccountName, Enabled, MemberOf, CannotChangePassword, AccountExpirationDate
$FilteredUsers = $OffboardingUsers | 
Where-Object { $_.Enabled -eq $true -or $_.CannotChangePassword -eq $false -or ($_.MemberOf).Count -gt 0 -or $_.AccountExpirationDate -eq $false -or $_.AccountExpirationDate -gt (get-date) }

If (($FilteredUsers | Measure-Object).count -gt 0) {
    Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " RUNNING PROCESS") >> $LogFile
    foreach ($User in $FilteredUsers) {        
        If ($User.AccountExpirationDate) {
            $Expirationdate = $user.AccountExpirationDate.ToShortDateString()
        }
        else {
            $Expirationdate = "False"
        }
        
        Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " =====================================================") >> $LogFile
        Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " User: " + $User.SamAccountName + ", Enabled: " + $User.Enabled + ", Groups: " + ($User.MemberOf).Count + ", CannotChangePassword: " + $User.CannotChangePassword + ", Expirationdate: " + $Expirationdate) >> $LogFile
        $body = $body + ("`nUser: " + $User.SamAccountName + ", Enabled: " + $User.Enabled + ", Groups: " + ($User.MemberOf).Count + ", CannotChangePassword: " + $User.CannotChangePassword + ", Expirationdate: " + $Expirationdate)

        #Generating new random password
        $RandomPassword = ""
        for ($i = 0; $i -lt $PassLength; $i++) {
            $RandomPassword += $PassCharset.Substring([int](Get-Random -Minimum 1 -Maximum $PassCharset.Length), 1)
        }
        $SecurePassword = $RandomPassword | ConvertTo-SecureString -AsPlainText -Force
        Set-ADAccountPassword -server $ADserver -Identity $User.SamAccountName -Reset -NewPassword $SecurePassword
        Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " User password has changed") >> $LogFile

        #Deactivate user account
        if ($User.Enabled) {
            Disable-ADAccount -server $ADserver -Identity $User.SamAccountName
            Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " User has disabled") >> $LogFile
        }
   
        #Remove from all groups
        if (($User.MemberOf).Count -gt 0) {
            Get-ADUser -server $ADserver -Identity $User.SamAccountName -Properties MemberOf  | ForEach-Object { $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false }
            Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " Removing from all groups...") >> $LogFile
        }

        #Restrict password changing
        if ($User.CannotChangePassword -eq $false) {
            Set-ADUser -server $ADserver -Identity $User.SamAccountName -CannotChangePassword $true
            Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " Restricting password changing...") >> $LogFile
        }

        #Set Account Expiration Date
        if ($User.AccountExpirationDate) {
            if ($User.AccountExpirationDate -gt (get-date)) {
                # If date is later than today
                $newExpirationDate = Get-Date  # New date is Today
                Set-ADUser -server $ADserver -Identity $User.SamAccountName -AccountExpirationDate $newExpirationDate
                Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " Incorrect Expiration Date. Changing...") >> $LogFile
            }
        }
        else {
            $newExpirationDate = Get-Date # New date is Today
            Set-ADUser -server $ADserver -Identity $User.SamAccountName -AccountExpirationDate $newExpirationDate
            Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " Setting Expiration Date...") >> $LogFile
        }
    } 
    Write-Output (((get-date).ToString("yyyy.MM.dd hh:mm:ss")) + " END PROCESS") >> $LogFile

    $body = $body + "`n`nTotal number of Users: " + $FilteredUsers.count + "`n`nLogs are in attachment"
    # Sent message with attachment
    Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer $smtpServer -Attachments $LogFile
}

