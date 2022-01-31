#FUNCTIONS HASH TABLE
$AD.Users.Import = @{}
$AD.Users.Import.Csv = "C:\TEMP\ADUsersImport.csv"
$AD.Users.Import.All = ""
$AD.Users.Import.New = ""
$AD.Users.Import.Existing = ""
$AD.Users.Export.Report = ""
$AD.Groups.Import = @{}
$AD.Groups.Import.Csv = "C:\TEMP\ADGroups.csv"
$AD.Groups.Import.All = ""
$AD.Groups.Import.New = ""
$AD.Groups.Import.Existing = ""
$AD.Groups.Process = @{}
$AD.Groups.Process.New = ""
$AD.Groups.Process.Existing = ""
$AD.Groups.Process.Export = @{}
$AD.Groups.Process.Export.All = ""
$AD.Groups.Process.Export.Csv = "C:\TEMP\ADGroups.csv"
$AD.Computers.Import = @{}
$AD.Computers.Import.Csv = "C:\TEMP\ADUsersImport.csv"
$AD.Computers.Import.All = ""
$AD.Computers.Import.New = ""
$AD.Computers.Import.Existing = ""



#Group Functions
Function ADGroups-Process {

    ADGroups-Import

    $AD.Groups.Import.All

    $Switch = Read-Host "Process All or Custom Select-Object? ( [A]ll / [C]ustom)"

    Switch -Wildcard ($Switch) {
        Default { }
        C* {for($i = 1; $i -le $AD.Groups.Import.All.count; $i++){
            Write-Host-Host "$($i): $($AD.Groups.Import.All[$i-1].Name)"
    }
    $CustomSelection = $AD.Groups.Import.All[((Read-Host -Prompt "`n Enter the Number of each Address to Custom Skip or Process seperated by a Comma [,]").split(",; ").Trim().ForEach-Object({$_-1}) | Sort | Get-Unique)]
    Write-Host "`nDo you want to Custom [S]kip -or- [P]rocess the following addresses:`n"
    $CustomSelection.Name
    Switch -Wildcard (Read-Host "`nSkip -or- Process Select-Objected Addresses? ( [S]kip / [P]rocess / [U]pdate) " ) {
        S* {Write-Host-host "Skipping..." $CustomSelection.Name "Processing Remaining Groups" ; $AD.Groups.Import.All | ForEach-Object {
            $_.Process = $true}; $CustomSelection | ForEach-Object {
                $_.Process = $false
            }
        }
        P* {Write-Host-Host "Processing..."$CustomSelection.Name "Skipping Remaining Groups"; $AD.Groups.Import.All | ForEach-Object {
            $_.Process = $false}; $CustomSelection | ForEach-Object {$_.Process = $true}}
        U* {}
    }
    ADGroups-Sort
    }
    }
    #PROCESS EXISTING ADDRESSES PROMPTS
    ForEach-Object ($Group in $AD.Groups.Process.Existing){
    Write-Host $Group.Name
    ADGroup-Update
    }
    #PROCESS NEW ADDRESSES PROMPTS
    ForEach-Object ($Group in $AD.Groups.Process.New){
    Write-Host $Group.Name
    ADGroup-New
    }
}
Function ADGroups-Import { 
    ADGroups-Existing
    #SPECIFY CSV IMPORT FILE
    If ($_ = Read-Host "`nDefault Import CSV:" $AD.Groups.Import.Csv "`n New Import CSV [Blank for Default]") {$AD.Groups.Import.Csv = $_}

    #IMPORT AND ORGANIZE ADDRESSES
    $AD.Groups.Import.All = Import-Csv $AD.Groups.Import.Csv | Sort Name

    #NORMALIZE GROUP MEMBER NAMES
    ForEach-Object ($Group in $AD.Groups.Import.All) { 
        $Group.Members = $Group.Members.split(“,;”).trim().tolower() | ForEach-Object {($_.split("@")[0])}
    }

    #MARK NEW AND EXISTING
    ForEach-Object ($Group in $AD.Groups.Import.All) {
        $Group | Add-Member -MemberType NoteProperty -Name Existing -Value $null -Force
        $Group | Add-Member -MemberType NoteProperty -Name Status -Value $null -Force
        $Group | Add-Member -MemberType NoteProperty -Name Process -Value $null -Force
        $Group.Existing = If ($Group.Name -in $AD.Groups.Existing.All.Name) {$True} Else {$False}
    }
    ADGroups-Sort
}
Function ADGroup-Update {
    Set-ADGroup $Group.Name -Description $Group.Description -ManagedBy $Group.ManagedBy -GroupScope Global
    Add-ADGroupMember $Group.Name -Members $Group.Members
    Remove-ADGroupMember $Group.Name -Members $Group.Members
}
Function ADGroup-New {
    New-ADGroup $Group.Name -Description $Group.Description -ManagedBy $Group.ManagedBy -Path $AD.Groups.GroupBase -GroupScope Global
    Add-ADGroupMember $Group.Name -Members $Group.Members
}
Function ADGroups-Process-Export {

    $AD.Groups.Process.Export.All = $AD.Groups.Existing.All | Select-Object Name, Description, Department, ManagedBy, Members

    ForEach-Object ($Group in $AD.Groups.Process.Export.All) {
    $Group.ManagedBy = (Get-ADuser $Group.ManagedBy).SamAccountName
    $Group.Members = $Group.Members.SamAccountName -Join ","
    }

    $AD.Groups.Process.Export.All | Export-Csv $AD.Groups.Process.Export.Csv -NoTypeInformation
}

#User Functions
Function ADUsers-Process {

    ADUsers-Import

    Write-Host $AD.Users.Import.All | Select-Object UserPrincipalName

    Switch -Wildcard (Read-Host "`n Process All or Custom Select-Object? ( [A]ll / [C]ustom) " ) {
    Default { }
    C* {for($i = 1; $i -le $AD.Users.Import.All.count; $i++){
    Write-Host-Host "$($i): $($AD.Users.Import.All[$i-1].Name)"
    }
    $CustomSelection = $AD.Users.Import.All[((Read-Host -Prompt "`n Enter the Number of each User to Custom Skip or Process seperated by a Comma [,]").split(",; ").Trim().ForEach-Object({$_-1}) | Sort | Get-Unique)]
    Write-Host "`nDo you want to Custom [S]kip -or- [P]rocess the following addresses:`n"
    $CustomSelection.Name
    Switch -Wildcard (Read-Host "`nSkip -or- Process Select-Objected Addresses? ( [S]kip / [P]rocess / [U]pdate) " ) {
    S* {Write-Host-host "Skipping..." $CustomSelection.Name "Processing Remaining Groups" ; $AD.Users.Import.All | ForEach-Object {$_.Process = $true}; $CustomSelection | ForEach-Object {$_.Process = $false}}
    P* {Write-Host-Host "Processing..."$CustomSelection.Name "Skipping Remaining Groups"; $AD.Users.Import.All | ForEach-Object {$_.Process = $false}; $CustomSelection | ForEach-Object {$_.Process = $true}}
    U* {}
    }
    ADUsers-Sort
    }
    }
    #PROCESS EXISTING ADDRESSES PROMPTS
    ForEach-Object ($User in $AD.Users.Import.All){
    Write-Host $User.UserPrincipalName
    ADUser-Update
    }
}
Function ADUsers-Import { 
    ADUsers-Existing
    #SPECIFY CSV IMPORT FILE
    If ($_ = Read-Host "`nDefault Import CSV:" $AD.Users.Import.Csv "`n New Import CSV [Blank for Default]") {$AD.Users.Import.Csv = $_}

    #IMPORT AND ORGANIZE ADDRESSES
    $AD.Users.Import.All = Import-Csv $AD.Users.Import.Csv | Sort Name

    #MARK NEW AND EXISTING
    ForEach-Object ($User in $AD.Users.Import.All) {
        $User | Add-Member -MemberType NoteProperty -Name SamAccountName -Value $null -Force
        $User | Add-Member -MemberType NoteProperty -Name EmailAddresses -Value $null -Force
        $User | Add-Member -MemberType NoteProperty -Name Existing -Value $null -Force
        $User | Add-Member -MemberType NoteProperty -Name Status -Value $null -Force
        $User | Add-Member -MemberType NoteProperty -Name Process -Value $null -Force
        $User.SamAccountName = $User.UserPrincipalName.split("@")[0]
        $User.EmailAddresses = $User.PrimarySmtpAddress + $User.SmtpAliases.split(",")
        $User.Existing = If ($User.UserPrincipalName -in $AD.Users.Existing.All.UserPrincipalName) {$True} Else {$False}
    }
    ADUsers-Sort
}
Function ADUser-Update {
    Set-ADUser $User.ObjectGUID -UserPrincipalName $User.UserPrincipalName
    Set-ADUser $User.ObjectGUID -DisplayName $User.DisplayName
    Set-ADUser $User.ObjectGUID -MobilePhone $User.MobilePhone
    Set-ADUser $User.ObjectGUID -Department $User.Department
    Set-ADUser $User.ObjectGUID -Title $User.JobTitle
    Set-ADUser $User.ObjectGUID -Company $User.Company
    Set-ADUser $User.ObjectGUID -EmployeeID $User.EmployeeID
    Set-ADUser $User.ObjectGUID -Description $User.Description
    Set-ADUser $User.ObjectGUID -State $User.State
    Set-ADUser $User.ObjectGUID -Title $User.Title
    Set-ADUser $User.ObjectGUID -Enabled $User.Enabled
    Set-ADUser $User.ObjectGUID -replace @{ProxyAddresses=$User.EmailAddresses}
}

#Domain Controller Functions
Function Replicate-AllDCs {
    (Get-ADDomainController -Filter *).Name | Foreach-Object {
        repadmin /syncall $_ (Get-ADDomain).DistinguishedName /e /A | Out-Null};
        Start-Sleep 10; Get-ADReplicationPartnerMetadata -Target "$env:userdnsdomain" -Scope Domain | Select-Object Server,LastReplicationSuccess
}


Write-Host "Convert objectGUID $objectGUID to ImmutableID " -NoNewline
[system.convert]::ToBase64String(([GUID]$objectGUID).ToByteArray())
Write-Host "Convert ImmutableID $ImmutableID to objectGUID " -NoNewline
([GUID][System.Convert]::FromBase64String($ImmutableID)).Guid
