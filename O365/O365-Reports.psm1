#REPORTS HASH TABLE
$O365.Reports = @{}
$O365.Reports.Export = @{}
$O365.Reports.Export.Csv = "C:\TEMP\O365-Report.csv"
$O365.Exchange.Addresses.Types.Contacts.Report = @{}
$O365.Exchange.Addresses.Types.Contacts.Report.Command = {
    
}
$O365.Exchange.Addresses.Types.UserMBs.Report = @{}
$O365.Exchange.Addresses.Types.UserMBs.Report.Command = {
    $Address.MSOnline = $O365.MSOnline.Users | Where-Object {$Address.ExternalDirectoryObjectId -eq $_.ObjectId}
    $Address.Exchange = Get-EXOMailboxStatistics $Address.ExternalDirectoryObjectId
    $Address.Type = $O365.Exchange.Addresses.Types.UserMBs.CsvMap
    $Address.TotalItemSize = $Address.Exchange.TotalItemSize
    $Address.ItemCount = $Address.Exchange.ItemCount
    $Address.LastLogonTime = $Address.MSOnline.LastLogonTime
    $Address.LastPasswordChangeTimeStamp = $Address.MSOnline.LastPasswordChangeTimeStamp
    $Address.MFA = ($Address.MSOnline.StrongAuthenticationRequirements.State)+"."+($Address.MSOnline.StrongAuthenticationMethods.MethodType -Join ",")
    $Address.LoginDisabled = $Address.MSOnline.BlockCredential
    $Address.ImmutableID = $Address.MSOnline.ImmutableID
    
    ForEach ($License in $O365.MSOnline.Licenses.Current){
        If ($Address.MSOnline.LicenseAssignmentDetails.AccountSku.SkuPartNumber -eq $License.SkuPartNumber) {
            $Address.($License.Name) = $True
        }
    }
}
$O365.Exchange.Addresses.Types.SharedMBs.Report = @{}
$O365.Exchange.Addresses.Types.SharedMBs.Report.Command = {
    $Address.Exchange = Get-EXOMailboxStatistics $Address.ExternalDirectoryObjectId
    $Address.Type = $O365.Exchange.Addresses.Types.SharedMBs.CsvMap
    $Address.TotalItemSize = $Address.Exchange.TotalItemSize
    $Address.ItemCount = $Address.Exchange.ItemCount
    $Address.Owners = (Get-MailboxPermission $Address.PrimarySmtpAddress | Where-Object {$_.AccessRights -match "FullAccess" -and $_.User -match "@"}).User -join ","
    $Address.SendAs = (Get-RecipientPermission $Address.PrimarySmtpAddress | Where-Object {$_.AccessRights -match "SendAs" -and $_.Trustee -match "@"}).Trustee -join ","
}
$O365.Exchange.Addresses.Types.DistGroups.Report = @{}
$O365.Exchange.Addresses.Types.DistGroups.Report.Command = {
    $Address.Exchange = $O365.Exchange.Groups | Where-Object {$Address.ExternalDirectoryObjectId -eq $_.ExternalDirectoryObjectId}
    $Address.Type = $O365.Exchange.Addresses.Types.DistGroups.CsvMap
    $Address.Owners = $Address.Exchange.ManagedBy -join ","
    $Address.Members = (Get-DistributionGroupMember $Address.PrimarySmtpAddress).PrimarySmtpAddress -join ","
    $Address.InternalOnly = $Address.Exchange.RequireSenderAuthenticationEnabled
    $Address.AcceptFrom = $Address.Exchange.AcceptMessagesOnlyFrom -join ","
    $Address.GALHide = $Address.Exchange.FromHiddenFromAddressListsEnabled
}
$O365.Exchange.Addresses.Types.O365Groups.Report = @{}
$O365.Exchange.Addresses.Types.O365Groups.Report.Command = {
    $Address.Exchange = $O365.Exchange.Groups | Where-Object {$Address.ExternalDirectoryObjectId -eq $_.ExternalDirectoryObjectId}
    If ($Address.Exchange.ResourceProvisioningOptions -match "Team") {
        $Address.Type = $O365.Exchange.Addresses.Types.O365Teams.O365Map
    } Else {
        $Address.Type = $O365.Exchange.Addresses.Types.O365Groups.CsvMap
    }
    $Address.Owners = (Get-UnifiedGroupLinks $Address.PrimarySmtpAddress -LinkType Owners) -join ","
    $Address.Members = (Get-UnifiedGroupLinks $Address.PrimarySmtpAddress -LinkType Members).PrimarySmtpAddress -join ","
    $Address.AcceptFrom = $Address.Exchange.AcceptMessagesOnlyFrom -join ","
    $Address.InternalOnly = $Address.Exchange.RequireSenderAuthenticationEnabled.ToString()

}
$O365.Exchange.Addresses.Types.O365Teams.Report = @{}
$O365.Exchange.Addresses.Types.O365Teams.Report.Command = {
    $Address.Type = $O365.Exchange.Addresses.Types.O365Teams.CsvMap
}
$O365.Exchange.Addresses.Types.MailSecurity.Report = @{}
$O365.Exchange.Addresses.Types.MailSecurity.Report.Command = {
    $Address.Exchange = $O365.Exchange.Groups | Where-Object {$Address.ExternalDirectoryObjectId -eq $_.ExternalDirectoryObjectId}
    $Address.Type = $O365.Exchange.Addresses.Types.MailSecurity.CsvMap
    $Address.Owners = $Address.Exchange.ManagedBy -join ","
    $Address.Members = (Get-DistributionGroupMember $Address.PrimarySmtpAddress).PrimarySmtpAddress -join ","
    $Address.InternalOnly = $Address.Exchange.RequireSenderAuthenticationEnabled
    $Address.AcceptFrom = $Address.Exchange.AcceptMessagesOnlyFrom -join ","
    $Address.GALHide = $Address.Exchange.FromHiddenFromAddressListsEnabled
}

Function O365-AddressReport {

    $PreCheck = @{}
    $PreCheck.Required = @(
            'O365-Common'
    )
    Pre-Check $PreCheck

    O365-Services -MSOnline -Exchange

    $O365.Reports.O365 = @{}
    $O365.Reports.O365.Properties = @(
        'Type'
        'DisplayName'
        'PrimarySMTPAddress'
        'SmtpAliases'
        'Owners'
        'Members'
        'SendAs'
        'FullAccess'
        'AcceptFrom'
        'InternalOnly'
        'GALHide'
        'LastLogonTime'
        'LoginDisabled'
        'MFA'
        'TotalItemSize'
        'ItemCount'
        'LastPasswordChangeTimeStamp'
        'ResetPasswordOnNextLogon'
        'ImmutableID'
        'ReportDate'
        'Errors'
        'MSOnline'
        'AzureAD'
        'Exchange'
    )
    Function O365-GetAddressDetails {

        #ADD LICENSES TO PROPERTIES
        ForEach ($License in $O365.MSOnline.Licenses.Current | Where-Object {$_.ConsumedUnits -gt 0}) {
            $O365.Reports.O365.Properties += $License.Name
        }

        #ADD REPORT PROPERTIES
        $O365.Exchange.Addresses.Existing.Report = $O365.Exchange.Addresses.Existing.All
        ForEach ($Property in ($O365.Reports.O365.Properties | Where-Object {$_ -notin ($O365.Exchange.Addresses.Existing.Report | Get-Member).Name})) {
            $O365.Exchange.Addresses.Existing.Report | Add-Member -MemberType NoteProperty -Name $Property -Value $null -Force
        }

        ForEach ($Address in $O365.Exchange.Addresses.Existing.Report) {
            $Address.Type = $Address.RecipientTypeDetails
            $Address.SmtpAliases = ($Address.EmailAddresses | Where-Object {$_ -match "smtp" -and $_ -notmatch $Address.PrimarySmtpAddress}) -join ","
            $Address.ReportDate = (Get-Date -Format "yyyy-MM-dd HH:mm K")
        }
        
        #ADD REPORT PROPERTIES
        ForEach ($Type in $O365.Exchange.Addresses.Types.Values) {
            $Type.Report.Addresses = $Type.All
            Write-Host "Getting Details for $($Type.Report.Addresses.Count) $($Type.Name)" -ForegroundColor Yellow
            ForEach ($Address in $Type.Report.Addresses) {
                Write-Host "    $($Address.PrimarySmtpAddress)"
                $Error.Clear()
                Invoke-Command $Type.Report.Command
                $Address.Errors = ($Error | Sort-Object | Get-Unique | ForEach-Object {($_ | Out-String).split([Environment]::NewLine) | Select-Object -First 1}) -join [Environment]::NewLine
            }
        }
    }
    
    O365-GetAddresses

    O365-GetAddressDetails

    $O365.Reports.Export.Report = $O365.Exchange.Addresses.Existing.Report | Select-Object $O365.Reports.O365.Properties
    
    Report-Export $O365.Reports.Export.Report $O365.Reports.Export.Csv

    O365-AddressReport
}