#Create shorcuts for managed folders on User Desktop
#
# CSV contain netx fields: city;location;fileserver;sharefolder

$CSVFileName = "\\yourdomain.com\NETLOGON\ServerList.csv"   #Source CSV-file wich is contain FileShares-list
$FolderName = "ManagedFolder"         #Name of folder
$username = $env:USERNAME

Import-CSV $CSVFileName -Delimiter ';' | ForEach-Object {        
    $FileServer = $_.fileserver
    $ShareName = $_.sharefolder
    $targetPath = "\\" + $FileServer + "\" + $ShareName + "\" + $FolderName 
    $linkPath = $env:USERPROFILE + "\Desktop\" + $_.City + ".lnk"       #Create shortcuts on user's Desktop. Name = "city"
    
    if (Test-Path -Path $targetPath -PathType Container) {
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($linkPath)
        $link.TargetPath = $targetPath
        $link.Save()
    }
}