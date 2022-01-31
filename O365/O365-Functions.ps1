#FUNCTIONS HASH TABLE
$O365.Exchange.Addresses.Import = @{}
$O365.Exchange.Addresses.Import.Csv = "C:\TEMP\O365AddressImport.csv"
$O365.Exchange.Addresses.Import.All = ""
$O365.Exchange.Addresses.Import.Report = "C:\TEMP\O365AddressImportReport.csv"
$O365.Exchange.Addresses = @{}
$O365.Exchange.Addresses.Types.Contacts.CsvMap = "Contact"
$O365.Exchange.Addresses.Types.Contacts.New = @{}
$O365.Exchange.Addresses.Types.Contacts.New.Command = { Contact-New }
$O365.Exchange.Addresses.Types.Contacts.Existing = @{}
$O365.Exchange.Addresses.Types.Contacts.Existing.Command = { Contact-Update }
$O365.Exchange.Addresses.Types.UserMBs.New = @{}
$O365.Exchange.Addresses.Types.UserMBs.New.Command = { UserMB-New }
$O365.Exchange.Addresses.Types.UserMBs.Existing = @{}
$O365.Exchange.Addresses.Types.UserMBs.Existing.Command = { UserMB-Update }
$O365.Exchange.Addresses.Types.SharedMBs.New = @{}
$O365.Exchange.Addresses.Types.SharedMBs.New.Command = { SharedMB-New }
$O365.Exchange.Addresses.Types.SharedMBs.Existing = @{}
$O365.Exchange.Addresses.Types.SharedMBs.Existing.Command = { SharedMB-Update }
$O365.Exchange.Addresses.Types.DistGroups.New = @{}
$O365.Exchange.Addresses.Types.DistGroups.New.Command = { DistGroup-New }
$O365.Exchange.Addresses.Types.DistGroups.Existing = @{}
$O365.Exchange.Addresses.Types.DistGroups.Existing.Command = { DistGroup-Update }
$O365.Exchange.Addresses.Types.O365Groups.New = @{}
$O365.Exchange.Addresses.Types.O365Groups.New.Command ={ O365Group-New }
$O365.Exchange.Addresses.Types.O365Groups.Existing = @{}
$O365.Exchange.Addresses.Types.O365Groups.Existing.Command = { O365Group-Update }
$O365.Exchange.Addresses.Types.O365Teams.New = @{}
$O365.Exchange.Addresses.Types.O365Teams.New.Command = "O365Team-New"
$O365.Exchange.Addresses.Types.O365Teams.Existing = @{}
$O365.Exchange.Addresses.Types.O365Teams.Existing.Command = { O365Team-Update }
$O365.Exchange.Addresses.Types.MailSecurity.New = @{}
$O365.Exchange.Addresses.Types.MailSecurity.New.Command = ""
$O365.Exchange.Addresses.Types.MailSecurity.Existing = @{}
$O365.Exchange.Addresses.Types.MailSecurity.Existing.Command = ""
$O365.Exchange.Addresses.Delete.Command = { Address-Remove }
$O365.Exchange.Addresses.Delete.New = @{}
$O365.Exchange.Addresses.Delete.Existing = @{}
$O365.Exchange.Addresses.Export = @{}
$O365.Exchange.Addresses.Export.Csv = "C:\TEMP\AddressReport.csv"

#SUPPORT FUNCTIONS
Function CsvMappings-Get {
    Write-Host "Current CSV Mappings"
    $_ = ForEach ($Type in $O365.Exchange.Addresses.Types.Values){
    [PSCustomObject]@{
        MailboxType = $($Type.Name)
        CSVMapping = $($Type.CsvMap)
    }
    } $_ | Out-Host
}
Function CsvMappings-Prompt {
    Switch -Wildcard (Read-Host "Update CSV Mappings? ( y / n )") {
        Default {"Using Default Mappings"} 
        Y* {CsvMappings-Set;CsvMappings-Get;CsvMappings-Prompt} 
    }
}
Function CsvMappings-Set {
    ForEach ($Type in $O365.Exchange.Addresses.Types.Values){
        If ($_ = Read-Host "Current $($Type.Name) Mapping: $($Type.CsvMap) `n New $($Type.Name) Mapping [Blank for Current]") {
        $Type.CsvMap = $_
        }
    }
}

#PROCESS ADDRESSES
Function Addresses-Import {

    CsvMappings-Get
    CsvMappings-Prompt

    #SPECIFY CSV FILE
    If ($_ = Read-Host "Default CSV Location:" $O365.Exchange.Addresses.Import.Csv "`n New CSV File [Blank for Default]") {
        $O365.Exchange.Addresses.Import.Csv = $_
    }

    #IMPORT AND ORGANIZE ADDRESSES
    $O365.Exchange.Addresses.Import.All = Import-Csv $O365.Exchange.Addresses.Import.Csv

    #MERGE PRIMARY EMAIL ADDRESSES AND ALIASES
    ForEach ($Address in $O365.Exchange.Addresses.Import.All) { 
        $Address | Add-Member -MemberType NoteProperty -Name EmailAddresses -Value $null -Force 
        $Address.EmailAddresses = [array]$Address.PrimarySmtpAddress + $Address.SmtpAliases.split(",;").trim() | Where-Object {$_ -ne ""} | Get-Unique 
        $Address.Owners = $Address.Owners.split(",;").trim() 
        $Address.Members = $Address.Members.split(",;").trim() 
    }

    #ADD CONTACT ENTRIES FOR GROUP MEMBERS NOT IN TENANT 
        $O365.Exchange.Addresses.Properties = $O365.Exchange.Addresses.Import.All | Get-Member | Where-Object MemberType -eq NoteProperty
        $O365.Exchange.Addresses.Import.All += ($O365.Exchange.Addresses.Import.All | Where-Object { $_.Type -ne "Delete" }).Members | Where-Object { $_ -ne $null -and $_ -notin $O365.Exchange.Addresses.Import.All.PrimarySmtpAddress } | Sort-Object | Get-Unique | ForEach {
        $Contact = New-Object PSCustomObject
        ForEach ($Property in $O365.Exchange.Addresses.Properties) { 
            $Contact | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $null
            } 
        $Contact.Type = $O365.Exchange.Addresses.Types.Contacts.CsvMap
        $Contact.PrimarySmtpAddress = $_ 
        $Contact.DisplayName = $_ 
        $Contact.EmailAddresses = $_
        $Contact 
    }

    #MARK NEW AND EXISTING
    ForEach ($Address in $O365.Exchange.Addresses.Import.All) {
        $Address | Add-Member -MemberType NoteProperty -Name ID -Value $null -Force
        $Address | Add-Member -MemberType NoteProperty -Name Existing -Value $null -Force
        $Address | Add-Member -MemberType NoteProperty -Name Status -Value $null -Force
        $Address | Add-Member -MemberType NoteProperty -Name Process -Value $null -Force
        $Address.Existing = If ("SMTP:$($Address.PrimarySmtpAddress)" -in $O365.Exchange.Addresses.Existing.All.EmailAddresses) {$True} Else {$False}
        $Address.ID = $Address.PrimarySmtpAddress
        $Address.InternalOnly = If ($Address.InternalOnly -like "True") {$True} Else {$False}
        $Address.GalHide = If ($Address.GalHide -like "True") {$True} Else {$False}
    }
}
Function ImportAddress-Sort {
    $TypeStatus.All = $O365.Exchange.Addresses.Import.All | Where-Object {$_.Existing -eq $Existing -and $_.Type -eq $Type.CsvMap}
    $TypeStatus.Process = $TypeStatus.All | Where-Object {$_.Process -notlike $false}
    $TypeStatus.Skip = $TypeStatus.All  | Where-Object {$_.Process -like $false}
    $Type.All = $O365.Exchange.Addresses.Import.All | Where-Object {$_.Type -eq $Type.CsvMap}
}
Function AddressType-Prompt {
    if ($TypeStatus.All -ne $null) {
        Write-Host "`nWould you like to Process $($Status) $($Type.Name) Using Current Preferences Below?`n"
        Write-Host "$($Status) $($Type.Name) Addresses Currently set to PROCESS"
        If($TypeStatus.Process -ne $null) {$TypeStatus.Process | Format-Wide PrimarySmtpAddress -AutoSize} Else {"None`n"}
        Write-Host "$($Status) $($Type.Name) Addresses Currently set to SKIP`n"
        If($TypeStatus.Skip -ne $null) {$TypeStatus.Skip | Format-Wide PrimarySmtpAddress -AutoSize} Else {"None`n"}

        Switch -Wildcard (Read-Host "Keep current $($Status) $($Type.Name) settings? ( Keep / [S]kip All / [P]rocess All / [C]ustom)" ) {
            Default {
                Write-host "Confirmed"
            }
            S* {
                Write-Host "Skipping $($Status) $($Type.Name)"; $TypeStatus.All | ForEach {$_.Process = $false}
            }
            P* {
                Write-Host "Processing $($Status) $($Type.Name)"; $TypeStatus.All | ForEach {$_.Process = $true}
            }
            C* {
                for($i = 1; $i -le $TypeStatus.All.count; $i++){
                    Write-Host "$($i): $($TypeStatus.All[$i-1].PrimarySmtpAddress)"
                }
                $CustomSelection = $TypeStatus.All[((Read-Host -Prompt "`nEnter the Number of each Address to Custom Skip or Process seperated by a Comma [,]").split(",; ").Trim().ForEach({$_-1}) | Sort-Object | Get-Unique)]
                Write-Host "`nDo you want to Custom [S]kip -or- [P]rocess the following addresses:`n"
                $CustomSelection.PrimarySmtpAddress
                Switch -Wildcard (Read-Host "`nSkip -or- Process Selected Addresses? ( [S]kip / [P]rocess / [U]pdate) " ) {
                    S* {Write-host "Skipping..." $CustomSelection.PrimarySmtpAddress "Processing Remaining $($Type.Name)"; $TypeStatus.All | ForEach {$_.Process = $true}; $CustomSelection | ForEach {$_.Process = $false}}
                    P* {Write-Host "Processing..."$CustomSelection.PrimarySmtpAddress "Skipping Remaining $($Type.Name)"; $TypeStatus.All | ForEach {$_.Process = $false}; $CustomSelection | ForEach {$_.Process = $true}}
                    U* {AddressType-Prompt}
                }
            }
        }
    }
}
Function AddressType-Prompts {

    #PROCESS EXISTING ADDRESSES PROMPTS
    ForEach ($Type in $O365.Exchange.Addresses.Types.Values){
        $Existing = $True
        $Status = "EXISTING"
        $TypeStatus = $Type.$Status
        ImportAddress-Sort
        AddressType-Prompt
        ImportAddress-Sort
    }

    #PROCESS NEW ADDRESSES PROMPTS
    ForEach ($Type in $O365.Exchange.Addresses.Types.Values[-1]){
        $Existing = $False
        $Status = "NEW"
        $TypeStatus = $Type.$Status
        ImportAddress-Sort
        AddressType-Prompt
        ImportAddress-Sort
    }
}
Function Addresses-Process {

Function AddressType-Process {
    
    #PROCESS DELETE ADDRESSES
    $O365.Exchange.Addresses.Existing.Delete = $O365.Exchange.Addresses.Existing.All | Where-Object { $_.PrimarySmtpAddress -in $O365.Exchange.Addresses.Types.Delete.Existing.Process.PrimarySmtpAddress }
    
    Write-Host "The Following Addresses Will Be Deleted.  Continue?"
    
    $O365.Exchange.Addresses.Existing.Delete.PrimarySmtpAddress
    
    Switch -Wildcard (Read-Host "Proceed? ( y / n )") {
        Default { Return } 
        Y* { } 
    }
    
    ForEach ($Address in $O365.Exchange.Addresses.Existing.Delete){
        $Address.PrimarySMTPAddress
        Invoke-Expression $O365.Exchange.Addresses.Types.Delete.Command
    }
    
    #PROCESS EXISTING ADDRESSES
    ForEach ($Type in $O365.Exchange.Addresses.Types.Values){
        ForEach ($Address in $Type.Existing.Process){
            $Address.PrimarySMTPAddress
            Invoke-Expression $Type.Existing.Command
        }
    }
    
    #PROCESS NEW ADDRESSES
    ForEach ($Type in $O365.Exchange.Addresses.Types.Values){
        ForEach ($Address in $Type.New.Process){
            $Address.PrimarySMTPAddress
            Invoke-Expression $Type.New.Command
            }
        }
    }
    
    Function UserMB-New {
        New-Mailbox -Name $Address.ID -DisplayName $Address.DisplayName -EmailAddresses $Address.EmailAddresses
    }
    Function UserMB-Update {
    }
    
    Function SharedMB-New {
        New-Mailbox -Shared -Name $Address.Name -DisplayName $Address.DisplayName
        Set-Mailbox $Address.ID -EmailAddresses $Address.EmailAddresses
        ForEach ($User in $Address.Members) {
            Add-MailboxPermission $Address.ID -User $User -AccessRights FullAccess -Confirm
            Add-RecipientPermission $Address.ID -Trustee $User -AccessRights SendAs -Confirm
        }
    }
    Function SharedMB-Update {
        Set-Mailbox $Address.ID -EmailAddresses $Address.EmailAddresses
        ForEach ($User in $Address.Members) {
            Add-MailboxPermission $Address.ID -User $User -AccessRights FullAccess -Confirm
            Add-RecipientPermission $Address.ID -Trustee $User -AccessRights SendAs -Confirm
        }
    }
    
    Function DistGroup-New {
        New-DistributionGroup -Name $Address.ID -ManagedBy $Address.Owners -Members $Address.Members 
        Set-DistributionGroup $Address.ID -EmailAddresses $Address.EmailAddresses -RequireSenderAuthenticationEnabled $Address.InternalOnly 
    }
    Function DistGroup-Update {
        Set-DistributionGroup $Address.ID -EmailAddresses $Address.EmailAddresses
        Set-DistributionGroup $Address.ID -ManagedBy $Address.Owners
        Set-DistributionGroup $Address.ID -RequireSenderAuthenticationEnabled $Address.InternalOnly
        Set-DistributionGroup $Address.ID -HiddenFromAddressListsEnabled $Address.GalHide
        Update-DistributionGroupMember $Address.ID -Members $Address.Members -Confirm:$false
    }
    
    Function O365Group-New {
    }
    Function O365Group-Update {
     Set-UnifiedGroup $Address.ID -EmailAddresses $Address.EmailAddresses -RequireSenderAuthenticationEnabled $Address.InternalOnly -AutoSubscribeNewMembers:$True
    }
    
    Function O365Team-New {
    }
    Function O365Team-Update {
        Set-UnifiedGroup $Address.ID -EmailAddresses $Address.EmailAddresses -RequireSenderAuthenticationEnabled $Address.InternalOnly -AutoSubscribeNewMembers:$True
    }
    
    Function Contact-New {
        New-MailContact -Name $Address.ID -EmailAddresses $Address.PrimarySmtpAddress -HiddenFromAddressListsEnabled
        }
        Function Contact-Update {
        Set-MailContact $Address.ID -EmailAddresses $Address.PrimarySmtpAddress -HiddenFromAddressListsEnabled $true
    }
    
    Function Address-Remove {
        If ($Address.RecipientTypeDetails -eq "UserMailbox") { Remove-Mailbox $Address.PrimarySmtpAddress }
        If ($Address.RecipientTypeDetails -eq "SharedMailbox") { Remove-Mailbox $Address.PrimarySmtpAddress }
        If ($Address.RecipientTypeDetails -eq "MailUniversalDistributionGroup") { Remove-DistributionGroup $Address.PrimarySmtpAddress }
        If ($Address.RecipientTypeDetails -eq "GroupMailbox") { Remove-UnifiedGroup $Address.PrimarySmtpAddress }
        If ($Address.RecipientTypeDetails -eq "MailContact") { Remove-MailContact $Address.PrimarySmtpAddress }
    }
    
    
    Addresses-Existing
    Addresses-Import
    AddressType-Prompts
    AddressType-Process
    
    #CLEAN UP ERROR LOGS
    $O365.Exchange.Addresses.Import.All.Status | ForEach-Object {$_ | Sort-Object | Get-Unique | ForEach-Object {(($_ | Out-String).split([Environment]::NewLine) | Select-Object -First 1) -join [Environment]::NewLine}}
    
    #EXPORT REPORT
    $O365.Exchange.Addresses.Import.All | Select-Object PrimarySmtpAddress, Type, Status | Export-Csv $O365.Exchange.Addresses.Import.Report -NoTypeInformation
}

#DISABLE USERS
Function Disable-O365Users {
    $Users = Import-Csv "C:\TEMP\Diable-O365Users.csv"

    ForEach ($User in $Users) {
        If ($User.BlockCredential -eq $False) {
            Write-Host $User.UserPrincipalName
            Set-AzureADUser -ObjectID $User.UserPrincipalName -AccountEnabled $true
        }
    }
}

Function O365-SPO-MoveURL {

    Install-Module PnP.Powershell

    $OldURL = "https://sammysinc.sharepoint.com/sites/Sammys/Lists/Squirrel Issue Tracking/"
    $NewUrl = "https://sammysinc.sharepoint.com/sites/Sammys/Squirrel/Lists/Issue Tracking/"


    #Set Parameters
$SiteURL = "https://sammysinc.sharepoint.com/sites/Habys/Squirrel"
$ListName = "Issue Tracking"
$NewSiteURL = "https://sammysinc.sharepoint.com/sites/Habys/Squirrel"
$NewListName = "IssueTracking"
  
#Connect to PNP Online
Connect-PnPOnline -Url $SiteURL -UseWebLogin
 
#Get the List
$List = Get-PnPList -Identity $ListName -Includes RootFolder
 
#sharepoint online powershell change list url
$List.Rootfolder.MoveTo($NewListName)
Invoke-PnPQuery


#Read more: https://www.sharepointdiary.com/2017/09/sharepoint-online-change-list-document-library-url-using-powershell.html#ixzz79OWohEHU

    ForEach ($User in $Users) {
        If ($User.BlockCredential -eq $False) {
            Write-Host $User.UserPrincipalName
            Set-AzureADUser -ObjectID $User.UserPrincipalName -AccountEnabled $true
        }
    }
}


