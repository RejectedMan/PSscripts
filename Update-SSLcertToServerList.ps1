#
# Script imports new SSL-certificate in PFX-format to each IIS-server from list
# and changes old certificate to new in configuration of each site. Need to input 
# Thumbprint-hash of old certificate in variable $OldCertThumbprint.
#

## IIS-server List
$ServerList = "srv01", "srv02", "192.168.0.10", "172.20.100.100"

#region Vars
$certStore = "Cert:\LocalMachine\My"                            # Certificate Storage on remote Host
$localFilePath = "C:\Temp\yourdomain.com.pfx"                   # Local Path to new PFX-certificate
$remoteFilePath = "C:\Temp\yourdomain.com.pfx"                  # Temporary path on remote server for copying PFX-file
$OldCertThumbprint = "807CB5126D2FE059D9279FA5004194EE5F0BE7B1" # Thumbprint of Old certificate which must be replaced
$friendlyName = "*.yourdomain.com"                              # Friendly Name for New Certificate
$certificatePassword = ConvertTo-SecureString -String "cErtP@55" -AsPlainText -Force   # Password for PFX-file
#endregion

## Put PFX to variable
$fileContent = [System.IO.File]::ReadAllBytes($localFilePath)

$ErrCount = 0

$Credential = Get-Credential  ## Getting Credentials to connect to remote servers

#region Main operations
foreach ($computer in $ServerList) {
    $err = $false
    Write-host "`nServer: "$computer -ForegroundColor Yellow "`n"
    $session = New-PSSession -ComputerName $computer -Credential $Credential    #Open PSsession
    if ($?) { 
        $ImportResult = Invoke-Command -Session $session -HideComputerName -ScriptBlock {
            param ($certStore, $remoteFilePath, [SecureString] $certificatePassword, $fileContent, $friendlyName, $OldCertThumbprint, $err, $BindingsResult)
            $err = $false
            $ResultOutput = ""
            ## Writing Certificate to PFX-file in temporary folder
            [System.IO.File]::WriteAllBytes($remoteFilePath, $fileContent)
            #region Importing certificate into local storage
            $ImportedCert = Import-PfxCertificate -FilePath $remoteFilePath -CertStoreLocation $certStore -Password $certificatePassword -Exportable
            if ($?) {
                $cert = Get-Item -Path ("Cert:\LocalMachine\My\" + $ImportedCert.Thumbprint[0])
                $cert.FriendlyName = $friendlyName
                $ResultOutput = "`n" + $cert + "`nFriendly Name : " + $cert.FriendlyName + "`nThumbprint    : " + $cert.Thumbprint + "`n`nCertificate has imported successfuly`n`n"
            }
            else {
                $ResultOutput = "Import Operation is failed"
                $err = $true
            }
            ## Deleting created PFX-file from temporary folder
            Remove-Item -Path $remoteFilePath
            #endregion
            If ($err -eq $false) {
                #region Updating site bindings
                $BindingsList = Get-WebBinding  -Protocol https | Where-Object { $_.certificateHash -eq $OldCertThumbprint }
                foreach ($SiteBinding in $BindingsList) {
                    $SiteBinding.RemoveSslCertificate()
                    $SiteBinding.AddSslCertificate($cert.Thumbprint, 'My')
                    $ResultOutput += "`nBinding has changed:" + $SiteBinding.bindingInformation 
                }
                $ResultOutput += "`n"
                ## Getting results        
                $ResultBindings = Get-WebBinding  -Protocol https | Select-object -Property ItemXPath, bindingInformation, protocol, sslFlags, certificateHash | Where-Object { $_.certificateHash -eq $cert.Thumbprint }
                #endregion
            }
            $err, $ResultOutput, $ResultBindings
        } -ArgumentList $certStore, $remoteFilePath, $certificatePassword, $fileContent, $friendlyName, $OldCertThumbprint
        $err, $ResultOutput, $ResultBindings = $ImportResult
        #Closing PSSession
        Remove-PSSession $session
        $ResultOutput
        if ($err) { $ErrCount++ } else { Write-Host "Site List:`n" -ForegroundColor Yellow; $ResultBindings }
    
    }
    else { Write-Host "Connection was failed" -ForegroundColor Red; $ErrCount++ }
}
Write-Host "======================================"
Write-Host "Operation complete."
Write-Host "Errors : "$ErrCount
#endregion