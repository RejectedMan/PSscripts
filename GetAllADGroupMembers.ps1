# Getting information about members in all groups of particular OU

#Variables
$DC = "DC.company.com"
$OU = "OU=users,DC=company,DC=com"
$CSVpath = "C:\Temp\ADGroupMembers.csv"

# Get Group List from OU
$groups = Get-ADGroup -Filter * -Properties Members -SearchBase $OU -Server $DC
# Get Group's and User's data
$AllUsers = Get-ADUser -Filter * -Properties sAMAccountName, DisplayName, Description, Title, Office -Server $DC
$AllGroups = Get-ADGroup -Filter * -Properties CN, Description -Server $DC

# Empty Array for Results
$result = @()

#region: Get Group members and add data to array $result
foreach ($group in $groups) {
    $groupMembers = Get-ADGroupMember -Identity $group.DistinguishedName -Server $DC
    foreach ($member in $groupMembers) {
        $type = $member.ObjectClass
        if ($type -eq "group") {
            # if member type is 'group'
            $GroupDetails = $AllGroups | Where-Object { $_.Name -eq $member.name }
            $result += [PSCustomObject]@{
                Group       = $group.Name
                Member      = $member.name
                MemberType  = "Group"
                DisplayName = $GroupDetails.cn
                Description = $GroupDetails.Description
                Title       = ""
                Office      = ""            
            }
        }
        elseif ($type -eq "user") {
            # if member type is 'user'
            $UserDetails = $AllUsers | Where-Object { $_.DistinguishedName -eq $member }
            $result += [PSCustomObject]@{
                Group       = $group.Name
                Member      = $UserDetails.SamAccountName
                MemberType  = "User"
                DisplayName = $UserDetails.DisplayName
                Description = $UserDetails.Description
                Title       = $UserDetails.Title
                Office      = $UserDetails.Office            
            }
        }
        # print result to a screen (add # if you don't need that)
        write-host ($result | Select-Object -Last 1)
    }
}
#endregion

# Export $results to CSV-file
$result | Export-Csv -Path $CSVpath -NoTypeInformation -Delimiter ";"
