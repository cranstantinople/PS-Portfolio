#REPORTS HASH TABLE
$AD.Reports = @{}
$AD.Reports.Export = @{}

Function ADUsers-Report {

    $AD.Reports.User = @{}
    $AD.Reports.User.Name = "ADGroups-Report"
    $AD.Reports.User.Csv = "$($AD.Reports.Group.Name).csv"

    ADUsers-Existing
    
    $AD.Reports.User.Report = $AD.Users.Existing.All | Select-Object UserPrincipalName, SamAccountName, DisplayName, GivenName, SurName, Description, MobilePhone, OfficePhone, EmployeeID, HireDate, EmailAddress, SmtpAliases, ObjectGuid, ImmutableID, DistinguishedName, PathOU, PasswordNeverExpires, Enabled
    
    Report-Export $AD.Reports.User.Report $AD.Reports.User.Csv
}
Function ADGroups-Report {

    $AD.Reports.Group = @{}
    $AD.Reports.Group.Name = "ADGroups-Report"
    $AD.Reports.Group.Csv = "$($AD.Reports.Group.Name).csv"
    $AD.Reports.Group.Sort = "group", "user", "computer"

    #SCRIPT WORKFLOW
    Switch -Wildcard ( Read-Host "Report By Group, User or Spreadsheet ( [G]roup / [U]ser / [M]atrix )" ) {
        G* {
            ADGroups-Report-ByGroup
        }
        U* {
            ADGroups-Report-ByUser
        }
        M* {
            ADGroups-Report-Matrix
        }
    }
    Function ADGroups-Report-ByGroup {
        #STRUCTURE HASHTABLE
        $AD.Reports.Group.Properties = @(
            'Name'
            'Description'
            'Enabled'
            'ManagedBy'
            'Members'
        )

        ADGroups-Existing
        $AD.Groups.Existing.Members = ForEach ($Group in $AD.Groups.Existing.All) {
            Get-ADGroupMember $Group.Name | Get-ADUser -Properties * | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name GroupName -Value $Group.Name -Passthru -Force
                $_ | Add-Member -MemberType NoteProperty -Name GroupDescription -Value $Group.Description -Force
            }
        }
        $AD.Reports.Export = $AD.Groups.Existing.All | Select-Object $AD.Reports.Group.Properties
        $AD.Reports.Export | ForEach-Object {
            $_.Members = $_.Members.SamAccountName -Join ","
        }
    }
    Function ADGroups-Report-ByUser {
        #STRUCTURE HASHTABLE
        $AD.Reports.Group.Properties = @(
            'GroupName'
            'Name'
            'SamAccountName'
            'objectClass'
            'GroupDescription'
        )

        ADGroups-Existing
        ADUsers-Existing
        $UserGroups = ForEach ($User in $AD.Users.Existing.All) {
            Get-ADPrincipalGroupMembership $User | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name UserName -Value $User.Name -Passthru -Force
            }
        }
        $AD.Reports.Export = $UserGroups | Select-Object $AD.Reports.Group.Properties
    }
    Function ADGroups-Report-Matrix {
        #STRUCTURE HASHTABLE
        $AD.Reports.Group.Properties = @(
            'Name'
            'objectClass'
            'Enabled'
        )

        ADGroups-Existing

        #SPECIFY SORT ORDER
        Write-Host "Default Sort Order: $($AD.Reports.Group.Sort)"
        Write-Host "New Sort Order (Seperated by Commas[,])[Blank for Default]"
        If ($_ = Read-Host) {$AD.Reports.Group.Sort = $_}
        
        ForEach ($Group in $AD.Groups.Existing.All) {
            $Group | Add-Member -MemberType NoteProperty -Name Members -Value (Get-ADGroupMember $Group.Name) -Force
            $Group | Add-Member -MemberType NoteProperty -Name MemberName -Value ($Group.Name+" - "+$Group.GroupCategory) -Force
        }
        $AD.Groups.Existing.Members = $AD.Groups.Existing.All.Members | Sort-Object Name | Get-Unique | Sort-Object {$AD.Reports.Group.Sort.IndexOf($_.objectClass)}, Name
        ForEach ($Member in $AD.Groups.Existing.Members) {
            $Member | Add-Member -MemberType NoteProperty -Name Enabled -Value $true -Force
            If($Member.objectClass -eq "user") {
                $Member.Enabled = (Get-ADUser $Member.SamAccountName).Enabled
            }
            ForEach ($Group in $AD.Groups.Existing.All) {
                $IsMember = If ($Member.distinguishedName -in $Group.Members.distinguishedName) {"x"}
                $Member | Add-Member -MemberType NoteProperty -Name $Group.MemberName -Value $IsMember -Force
            }
        }
        $AD.Reports.Group.Report = $AD.Groups.Existing.Members | Select-Object ($AD.Reports.Group.Properties + $AD.Groups.Existing.All.MemberName)
    }
    Report-Export $AD.Reports.Group.Report $AD.Reports.Group.Csv
}
Function ADComputers-Report {

    $AD.Reports.Computer = @{}
    $AD.Reports.Computer.Name = "ADComputer-Report"
    $AD.Reports.Computer.Csv = "$($AD.Reports.Computer.Name).csv"
    $AD.Reports.Computer.Properties = @(
        'CN'
        'DNSHostName'
        'OperatingSystem'
        'IPv4Address'
        'LastLogonDate'
    )

    ADComputer-Existing

    $AD.Reports.Computer.Report = $AD.Computers.Existing.All | Select-Object $AD.Reports.Computer.Properties
    
    Report-Export $AD.Reports.Computer.Report $AD.Reports.Computer.Csv
}
