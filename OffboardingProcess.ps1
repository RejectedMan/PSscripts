#region Description
##  Diactivate all users in Offboarding OU
##  Change password
##  Restrict change password
##  Set Expiration date
##  Remove from all AD Groups
##  Save Logs and Sent it by email
#endregion

#region Vars
$LogPath = "C:\AutomationLogs"
$ADserver = "dc.yourdomain.com"
$PassCharset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+'   ## Password charset
$PassLength = 28                                                                                ## Password length
$OffboardingOU = "OU=Offboarding,OU=Users,DC=yourdomain,DC=com"                                 ## OU with offboarding users
$dtf = "yyyy.MM.dd hh:mm:ss" 
#endregion

#region SMTP settings
$smtpServer = "smtp.yourdomain.com"         ## SMTP-server
$from = "alert@yourdomain.com"              ## Sender
$to = "admin@yourdomain.com"                ## Recipient
$subject = "Offboarding Automation Alert"   ## Subject
$body = "Next Users has changed:`n`n"
#endregion

#region Get Data
$LogFile = $LogPath + "\" + ((get-date).ToString("yyyyMMdd")) + "_Offboarding.txt"
$OffboardingUsers = Get-ADUser -server $ADserver -SearchBase $OffboardingOU -Filter * -Properties SamAccountName, Enabled, MemberOf, CannotChangePassword, AccountExpirationDate
$FilteredUsers = $OffboardingUsers | 
Where-Object { $_.Enabled -eq $true -or $_.CannotChangePassword -eq $false -or ($_.MemberOf).Count -gt 0 -or $_.AccountExpirationDate -eq $false -or $_.AccountExpirationDate -gt (get-date) }
#endregion

#region Set Properties, creat LogFile and send it by email
If (($FilteredUsers | Measure-Object).count -gt 0) {
    Write-Output (((get-date).ToString($dtf)) + " RUNNING PROCESS") >> $LogFile
    foreach ($User in $FilteredUsers) {        
        If ($User.AccountExpirationDate) {
            $Expirationdate = $user.AccountExpirationDate.ToShortDateString()
        }
        else {
            $Expirationdate = "False"
        }
        
        Write-Output (((get-date).ToString($dtf)) + " =====================================================") >> $LogFile
        Write-Output (((get-date).ToString($dtf)) + " User: " + $User.SamAccountName + ", Enabled: " + $User.Enabled + ", Groups: " + ($User.MemberOf).Count + ", CannotChangePassword: " + $User.CannotChangePassword + ", Expirationdate: " + $Expirationdate) >> $LogFile
        $body = $body + ("`nUser: " + $User.SamAccountName + ", Enabled: " + $User.Enabled + ", Groups: " + ($User.MemberOf).Count + ", CannotChangePassword: " + $User.CannotChangePassword + ", Expirationdate: " + $Expirationdate)

        ## Generating new random password
        $RandomPassword = ""
        for ($i = 0; $i -lt $PassLength; $i++) {
            $RandomPassword += $PassCharset.Substring([int](Get-Random -Minimum 1 -Maximum $PassCharset.Length), 1)
        }
        $SecurePassword = $RandomPassword | ConvertTo-SecureString -AsPlainText -Force
        Set-ADAccountPassword -server $ADserver -Identity $User.SamAccountName -Reset -NewPassword $SecurePassword
        Write-Output (((get-date).ToString($dtf)) + " User password has changed") >> $LogFile

        ## Deactivate user account
        if ($User.Enabled) {
            Disable-ADAccount -server $ADserver -Identity $User.SamAccountName
            Write-Output (((get-date).ToString($dtf)) + " User has disabled") >> $LogFile
        }
   
        ## Remove from all groups
        if (($User.MemberOf).Count -gt 0) {
            Get-ADUser -server $ADserver -Identity $User.SamAccountName -Properties MemberOf  | 
            ForEach-Object { $_.MemberOf | Remove-ADGroupMember -server $ADserver -Members $_.DistinguishedName -Confirm:$false }
            Write-Output (((get-date).ToString($dtf)) + " Removing from all groups...") >> $LogFile
        }

        ## Restrict password changing
        if ($User.CannotChangePassword -eq $false) {
            Set-ADUser -server $ADserver -Identity $User.SamAccountName -CannotChangePassword $true
            Write-Output (((get-date).ToString($dtf)) + " Restricting password changing...") >> $LogFile
        }

        ## Set Account Expiration Date
        $newExpirationDate = Get-Date ## New date is Today
        if ($User.AccountExpirationDate) {
            if ($User.AccountExpirationDate -gt (get-date)) {
                ## If date is later than today
                Set-ADUser -server $ADserver -Identity $User.SamAccountName -AccountExpirationDate $newExpirationDate
                Write-Output (((get-date).ToString($dtf)) + " Incorrect Expiration Date. Changing...") >> $LogFile
            }
        }
        else {
            Set-ADUser -server $ADserver -Identity $User.SamAccountName -AccountExpirationDate $newExpirationDate
            Write-Output (((get-date).ToString($dtf)) + " Setting Expiration Date...") >> $LogFile
        }
    } 
    Write-Output (((get-date).ToString($dtf)) + " END PROCESS") >> $LogFile

    $body = $body + "`n`nTotal number of Users: " + ($FilteredUsers | Measure-Object).count + "`n`nLogs are in attachment"
    ## Sent message with attachment
    Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer $smtpServer -Attachments $LogFile
}
#endregion