##
## Getting information from Logs/Security about AD Croup changing and sending it to email
##

$smtpServer = "smtp.yourdomain.com"                                         # SMTP-server DNS-name/IP-address
$from = "AD Group Changing report<alert@yourdomain.com>"                   # Sender email address
$to = "admin@yourdomain.com"                                        # Reciever email address
$subject = "AD Group Changing Alert from " + $env:COMPUTERNAME               # Email subject
$htmlHeader = "<h><b>Next Security Groups have been changed:<b></h><br><br>" # Header of message


$OutputData = @()
$Time = (get-date) - (new-timespan -hour 24)
Get-WinEvent -FilterHashtable @{LogName = "Security"; ID = (4728, 4732, 4756); StartTime = $Time } | 
ForEach-Object {
    $evt = [xml]$_.ToXml()
    if ($evt) {
        $ADObject = Get-ADObject -Identity $evt.Event.EventData.Data[0]."#text" -Properties * 
        $AdminUser = Get-AdUser $evt.Event.EventData.Data[6]."#text"
        $Time = Get-Date $_.TimeCreated -UFormat "%Y-%m-%d %H:%M:%S"
        $OutputData += [PSCustomObject]@{ 
            Time = $Time; DC = $evt.Event.System.computer; ADGroupName = $evt.Event.EventData.Data[2]."#text"; 
            Type = $ADObject.ObjectClass; ObjectName = $ADObject.Name; sAMAccountName = $ADObject.sAMAccountName;  
            AdminUserName = $AdminUser.Name; AdminUserLogin = $AdminUser.SamAccountName
        }                
    }
}
$body = "`n<h1>" + $env:COMPUTERNAME + "</h1>`n`n"
$body += $OutputData | ConvertTo-Html -Fragment -PreContent $htmlHeader | Out-String

# Sending email
if ($OutputData) { 
    Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer $smtpServer -Encoding utf8 -BodyAsHtml 
}