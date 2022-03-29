Function O365-Init {
	#COMMON HASH TABLE
	$global:O365 = @{}
	$O365.Tenant = ""
	$O365.Account = ""
	$O365.Service = @{}

	$O365.Service.Graph = @{}
	$O365.Service.Graph.Name = "Microsoft Graph"
	$O365.Service.Graph.Module = @{}
	$O365.Service.Graph.Module.Name = "Microsoft.Graph"

	$O365.Service.AzureAD = @{}
	$O365.Service.AzureAD.Name = "Azure AD"
	$O365.Service.AzureAD.Module = @{}
	$O365.Service.AzureAD.Module.Name = "AzureAD"

	$O365.Service.MSOnline = @{}
	$O365.Service.MSOnline.Name = "Microsoft Online"
	$O365.Service.MSOnline.Module = @{}
	$O365.Service.MSOnline.Module.Name = "MSOnline"

	$O365.Service.Exchange = @{}
	$O365.Service.Exchange.Name = "Exchange Online"
	$O365.Service.Exchange.Module = @{}
	$O365.Service.Exchange.Module.Name = "ExchangeOnlineManagement"

	$O365.Service.SecComp = @{}
	$O365.Service.SecComp.Name = "Security and Compliance"
	$O365.Service.SecComp.Module = @{}
	$O365.Service.SecComp.Module.Name = "ExchangeOnlineManagement"

	$O365.Service.Teams = @{}
	$O365.Service.Teams.Name = "Microsoft Teams"
	$O365.Service.Teams.Module = @{}
	$O365.Service.Teams.Module.Name = "MicrosoftTeams"

	$O365.Service.SharePoint = @{}
	$O365.Service.SharePoint.Name = "SharePoint Online"
	$O365.Service.SharePoint.Module = @{}
	$O365.Service.SharePoint.Module.Name = "Microsoft.Online.SharePoint.PowerShell"

	$O365.Service.SharePointPnP = @{}
	$O365.Service.SharePointPnP.Name = "SharePoint PnP"
	$O365.Service.SharePointPnP.Module = @{}
	$O365.Service.SharePointPnP.Module.Name = "PnP.Powershell"

	$O365.Services = @{}
	$O365.Modules = @{}

	$O365.MSOnline = @{}
	$O365.MSOnline.Users = ""
	$O365.MSOnline.Licenses = @{}
	$O365.MSOnline.Licenses.Sku = @{
		"O365_BUSINESS_ESSENTIALS"		     = "Office 365 Business Essentials"
		"O365_BUSINESS_PREMIUM"			     = "Office 365 Business Premium"
		"DESKLESSPACK"					     = "Office 365 (Plan K1)"
		"DESKLESSWOFFPACK"				     = "Office 365 (Plan K2)"
		"LITEPACK"						     = "Office 365 (Plan P1)"
		"EXCHANGESTANDARD"				     = "Office 365 Exchange Online Only"
		"STANDARDPACK"					     = "Enterprise Plan E1"
		"STANDARDWOFFPACK"				     = "Office 365 (Plan E2)"
		"ENTERPRISEPACK"					 = "Enterprise Plan E3"
		"ENTERPRISEPACKLRG"				     = "Enterprise Plan E3"
		"ENTERPRISEWITHSCAL"				 = "Enterprise Plan E4"
		"STANDARDPACK_STUDENT"			     = "Office 365 (Plan A1) for Students"
		"STANDARDWOFFPACKPACK_STUDENT"	     = "Office 365 (Plan A2) for Students"
		"ENTERPRISEPACK_STUDENT"			 = "Office 365 (Plan A3) for Students"
		"ENTERPRISEWITHSCAL_STUDENT"		 = "Office 365 (Plan A4) for Students"
		"STANDARDPACK_FACULTY"			     = "Office 365 (Plan A1) for Faculty"
		"STANDARDWOFFPACKPACK_FACULTY"	     = "Office 365 (Plan A2) for Faculty"
		"ENTERPRISEPACK_FACULTY"			 = "Office 365 (Plan A3) for Faculty"
		"ENTERPRISEWITHSCAL_FACULTY"		 = "Office 365 (Plan A4) for Faculty"
		"ENTERPRISEPACK_B_PILOT"			 = "Office 365 (Enterprise Preview)"
		"STANDARD_B_PILOT"				     = "Office 365 (Small Business Preview)"
		"VISIOCLIENT"					     = "Visio Pro Online"
		"POWER_BI_ADDON"					 = "Office 365 Power BI Addon"
		"POWER_BI_INDIVIDUAL_USE"		     = "Power BI Individual User"
		"POWER_BI_STANDALONE"			     = "Power BI Stand Alone"
		"POWER_BI_STANDARD"				     = "Power-BI Standard"
		"PROJECTESSENTIALS"				     = "Project Lite"
		"PROJECTCLIENT"					     = "Project Professional"
		"PROJECTONLINE_PLAN_1"			     = "Project Online"
		"PROJECTONLINE_PLAN_2"			     = "Project Online and PRO"
		"ProjectPremium"					 = "Project Online Premium"
		"ECAL_SERVICES"					     = "ECAL"
		"EMS"							     = "Enterprise Mobility Suite"
		"RIGHTSMANAGEMENT_ADHOC"			 = "Windows Azure Rights Management"
		"MCOMEETADV"						 = "PSTN conferencing"
		"SHAREPOINTSTORAGE"				     = "SharePoint storage"
		"PLANNERSTANDALONE"				     = "Planner Standalone"
		"CRMIUR"							 = "CMRIUR"
		"BI_AZURE_P1"					     = "Power BI Reporting and Analytics"
		"INTUNE_A"						     = "Windows Intune Plan A"
		"INTUNE_A_D"						 = "Microsoft Intune Device"
		"PROJECTWORKMANAGEMENT"			     = "Office 365 Planner Preview"
		"ATP_ENTERPRISE"					 = "Exchange Online Advanced Threat Protection"
		"EQUIVIO_ANALYTICS"				     = "Office 365 Advanced eDiscovery"
		"AAD_BASIC"						     = "Azure Active Directory Basic"
		"RMS_S_ENTERPRISE"				     = "Azure Active Directory Rights Management"
		"AAD_PREMIUM"					     = "Azure Active Directory Premium"
		"MFA_PREMIUM"					     = "Azure Multi-Factor Authentication"
		"STANDARDPACK_GOV"				     = "Microsoft Office 365 (Plan G1) for Government"
		"STANDARDWOFFPACK_GOV"			     = "Microsoft Office 365 (Plan G2) for Government"
		"ENTERPRISEPACK_GOV"				 = "Microsoft Office 365 (Plan G3) for Government"
		"ENTERPRISEWITHSCAL_GOV"			 = "Microsoft Office 365 (Plan G4) for Government"
		"DESKLESSPACK_GOV"				     = "Microsoft Office 365 (Plan K1) for Government"
		"ESKLESSWOFFPACK_GOV"			     = "Microsoft Office 365 (Plan K2) for Government"
		"EXCHANGESTANDARD_GOV"			     = "Microsoft Office 365 Exchange Online (Plan 1) only for Government"
		"EXCHANGEENTERPRISE_GOV"			 = "Microsoft Office 365 Exchange Online (Plan 2) only for Government"
		"SHAREPOINTDESKLESS_GOV"			 = "SharePoint Online Kiosk"
		"EXCHANGE_S_DESKLESS_GOV"		     = "Exchange Kiosk"
		"RMS_S_ENTERPRISE_GOV"			     = "Windows Azure Active Directory Rights Management"
		"OFFICESUBSCRIPTION_GOV"			 = "Office ProPlus"
		"MCOSTANDARD_GOV"				     = "Lync Plan 2G"
		"SHAREPOINTWAC_GOV"				     = "Office Online for Government"
		"SHAREPOINTENTERPRISE_GOV"		     = "SharePoint Plan 2G"
		"EXCHANGE_S_ENTERPRISE_GOV"		     = "Exchange Plan 2G"
		"EXCHANGE_S_ARCHIVE_ADDON_GOV"	     = "Exchange Online Archiving"
		"EXCHANGE_S_DESKLESS"			     = "Exchange Online Kiosk"
		"SHAREPOINTDESKLESS"				 = "SharePoint Online Kiosk"
		"SHAREPOINTWAC"					     = "Office Online"
		"YAMMER_ENTERPRISE"				     = "Yammer Enterprise"
		"EXCHANGE_L_STANDARD"			     = "Exchange Online (Plan 1)"
		"MCOLITE"						     = "Lync Online (Plan 1)"
		"SHAREPOINTLITE"					 = "SharePoint Online (Plan 1)"
		"OFFICE_PRO_PLUS_SUBSCRIPTION_SMBIZ" = "Office ProPlus"
		"EXCHANGE_S_STANDARD_MIDMARKET"	     = "Exchange Online (Plan 1)"
		"MCOSTANDARD_MIDMARKET"			     = "Lync Online (Plan 1)"
		"SHAREPOINTENTERPRISE_MIDMARKET"	 = "SharePoint Online (Plan 1)"
		"OFFICESUBSCRIPTION"				 = "Office ProPlus"
		"YAMMER_MIDSIZE"					 = "Yammer"
		"DYN365_ENTERPRISE_PLAN1"		     = "Dynamics 365 Customer Engagement Plan Enterprise Edition"
		"ENTERPRISEPREMIUM_NOPSTNCONF"	     = "Enterprise E5 (without Audio Conferencing)"
		"ENTERPRISEPREMIUM"				     = "Enterprise E5 (with Audio Conferencing)"
		"MCOSTANDARD"					     = "Skype for Business Online Standalone Plan 2"
		"PROJECT_MADEIRA_PREVIEW_IW_SKU"	 = "Dynamics 365 for Financials for IWs"
		"STANDARDWOFFPACK_IW_STUDENT"	     = "Office 365 Education for Students"
		"STANDARDWOFFPACK_IW_FACULTY"	     = "Office 365 Education for Faculty"
		"EOP_ENTERPRISE_FACULTY"			 = "Exchange Online Protection for Faculty"
		"EXCHANGESTANDARD_STUDENT"		     = "Exchange Online (Plan 1) for Students"
		"OFFICESUBSCRIPTION_STUDENT"		 = "Office ProPlus Student Benefit"
		"STANDARDWOFFPACK_FACULTY"		     = "Office 365 Education E1 for Faculty"
		"STANDARDWOFFPACK_STUDENT"		     = "Microsoft Office 365 (Plan A2) for Students"
		"DYN365_FINANCIALS_BUSINESS_SKU"	 = "Dynamics 365 for Financials Business Edition"
		"DYN365_FINANCIALS_TEAM_MEMBERS_SKU" = "Dynamics 365 for Team Members Business Edition"
		"FLOW_FREE"						     = "Microsoft Flow Free"
		"POWER_BI_PRO"					     = "Power BI Pro"
		"O365_BUSINESS"					     = "Office 365 Business"
		"DYN365_ENTERPRISE_SALES"		     = "Dynamics Office 365 Enterprise Sales"
		"RIGHTSMANAGEMENT"				     = "Rights Management"
		"PROJECTPROFESSIONAL"			     = "Project Professional"
		"VISIOONLINE_PLAN1"				     = "Visio Online Plan 1"
		"EXCHANGEENTERPRISE"				 = "Exchange Online Plan 2"
		"DYN365_ENTERPRISE_P1_IW"		     = "Dynamics 365 P1 Trial for Information Workers"
		"DYN365_ENTERPRISE_TEAM_MEMBERS"	 = "Dynamics 365 For Team Members Enterprise Edition"
		"CRMSTANDARD"					     = "Microsoft Dynamics CRM Online Professional"
		"EXCHANGEARCHIVE_ADDON"			     = "Exchange Online Archiving For Exchange Online"
		"EXCHANGEDESKLESS"				     = "Exchange Online Kiosk"
		"SPZA_IW"						     = "App Connect"
		"WINDOWS_STORE"					     = "Windows Store for Business"
		"MCOEV"							    = "Microsoft Phone System"
		"VIDEO_INTEROP"					    = "Polycom Skype Meeting Video Interop for Skype for Business"
		"SPE_E5"							= "Microsoft 365 E5"
		"SPE_E3"							= "Microsoft 365 E3"
		"ATA"							    = "Advanced Threat Analytics"
		"MCOPSTN2"						    = "Domestic and International Calling Plan"
		"FLOW_P1"						    = "Microsoft Flow Plan 1"
		"FLOW_P2"						    = "Microsoft Flow Plan 2"
		"CRMSTORAGE"						= "Microsoft Dynamics CRM Online Additional Storage"
		"SMB_APPS"						    = "Microsoft Business Apps"
		"MICROSOFT_BUSINESS_CENTER"		    = "Microsoft Business Center"
		"DYN365_TEAM_MEMBERS"				= "Dynamics 365 Team Members"
		"STREAM"							= "Microsoft Stream Trial"
		"EMSPREMIUM"						= "ENTERPRISE MOBILITY + SECURITY E5"
		
	}

	$O365.AzureAD = @{}
	$O365.AzureAD.Users = ""

	$O365.Exchange = @{}
	$O365.Exchange.Groups = @{}
	$O365.Exchange.Addresses = @{}
	$O365.Exchange.Addresses.Existing = @{}
	$O365.Exchange.Addresses.Existing.All = ""
	$O365.Exchange.Addresses.Existing.Selection = ""
	$O365.Exchange.Addresses.Existing.Delete = @{}
	$O365.Exchange.Addresses.Types = [ordered]@{}
	$O365.Exchange.Addresses.Types.Contacts = @{}
	$O365.Exchange.Addresses.Types.Contacts.Name = "Contacts"
	$O365.Exchange.Addresses.Types.Contacts.CsvMap = "Contact"
	$O365.Exchange.Addresses.Types.Contacts.O365Mapping = "MailContact"
	$O365.Exchange.Addresses.Types.UserMBs = @{}
	$O365.Exchange.Addresses.Types.UserMBs.Name = "User Mailboxes"
	$O365.Exchange.Addresses.Types.UserMBs.CsvMap = "User Mailbox"
	$O365.Exchange.Addresses.Types.UserMBs.O365Map = "UserMailbox"
	$O365.Exchange.Addresses.Types.SharedMBs = @{}
	$O365.Exchange.Addresses.Types.SharedMBs.Name = "Shared Mailboxes"
	$O365.Exchange.Addresses.Types.SharedMBs.CsvMap = "Shared Mailbox"
	$O365.Exchange.Addresses.Types.SharedMBs.O365Map = "SharedMailbox"
	$O365.Exchange.Addresses.Types.DistGroups = @{}
	$O365.Exchange.Addresses.Types.DistGroups.Name = "Distribution Groups"
	$O365.Exchange.Addresses.Types.DistGroups.CsvMap = "Distribution Group"
	$O365.Exchange.Addresses.Types.DistGroups.O365Map = "MailUniversalDistributionGroup"
	$O365.Exchange.Addresses.Types.O365Groups = @{}
	$O365.Exchange.Addresses.Types.O365Groups.Name = "Office 365 Groups"
	$O365.Exchange.Addresses.Types.O365Groups.CsvMap = "Office 365 Group"
	$O365.Exchange.Addresses.Types.O365Groups.O365Map = "GroupMailbox"
	$O365.Exchange.Addresses.Types.O365Teams = @{}
	$O365.Exchange.Addresses.Types.O365Teams.Name = "Office 365 Teams"
	$O365.Exchange.Addresses.Types.O365Teams.CsvMap = "Office 365 Team"
	$O365.Exchange.Addresses.Types.O365Teams.O365Map = "O365Team"
	$O365.Exchange.Addresses.Types.MailSecurity = @{}
	$O365.Exchange.Addresses.Types.MailSecurity.Name = "Mail Security Groups"
	$O365.Exchange.Addresses.Types.MailSecurity.CsvMap = "Mail Security Group"
	$O365.Exchange.Addresses.Types.MailSecurity.O365Map = ""
	$O365.Exchange.Addresses.Delete = @{}
	$O365.Exchange.Addresses.Delete.Name = "Delete"
	$O365.Exchange.Addresses.Delete.CsvMap = "Delete"

}
Function O365-Services {

	param (
		[switch]$Graph,
		[switch]$AzureAD,
		[switch]$MSOnline,
		[switch]$Exchange,
		[switch]$SecComp,
		[switch]$Teams,
		[switch]$Sharepoint,
		[switch]$SharepointPnP,
        [switch]$Force
    )

	$O365.Service.Graph.Test = {  }
    $O365.Service.Graph.Connect = { Connect-MgGraph -Scope "User.Read.All","Group.ReadWrite.All" }
    $O365.Service.AzureAD.Test = { Get-AzureADTenantDetail }
    $O365.Service.AzureAD.Connect = { Connect-AzureAD }
    $O365.Service.MSOnline.Test = { Get-MsolDomain -ErrorAction Stop }
    $O365.Service.MSOnline.Connect = { Connect-MsolService }
    $O365.Service.Exchange.Test = { Get-PSSession | Where-Object {$_.Name -match "ExchangeOnline" -and ($_.State -eq "Opened" -or $_.State -eq "Broken")} }
    $O365.Service.Exchange.Connect = { Get-PSSession | Remove-PSSession; Connect-ExchangeOnline -UserPrincipalName $O365.Account.UserName }
    $O365.Service.SecComp.Test = {}
    $O365.Service.SecComp.Connect = { Connect-IPPSSession -Credential $O365.Account }
    $O365.Service.Teams.Test = { Get-CsTenant }
    $O365.Service.Teams.Connect = { Connect-MicrosoftTeams }
    $O365.Service.SharePoint.Test = { Get-SPOTenant }
    $O365.Service.SharePoint.Connect = { Connect-SPOService -Url https://$($O365.Tenant)-admin.sharepoint.com }
	$O365.Service.SharePointPNP.Test = { }
    $O365.Service.SharePointPNP.Connect = { Connect-SPOService -Url https://$($O365.Tenant)-admin.sharepoint.com }

	$O365.Service.Graph.Status = $Graph
	$O365.Service.AzureAD.Status = $AzureAD
	$O365.Service.MSOnline.Status = $MSOnline
	$O365.Service.Exchange.Status = $Exchange
	$O365.Service.SecComp.Status = $SecComp
	$O365.Service.Teams.Status = $Teams
	$O365.Service.SharePoint.Status = $SharePoint
	$O365.Service.SharePointPnP.Status = $SharePointPnP

    $O365.Services = @{}
    $O365.Services.Connect = $O365.Service.Values | Where-Object {$_.Status -eq $True}

	Function O365-TestConnections { 
		ForEach ($Service in $O365.Services.Connect) {
			#TEST FOR CONNECTION
			O365-TestConnection
			If ($Force) {
				$Service.Status = "Connect"
			}
		}
		If ("Connect" -in $O365.Services.Connect.Status) {
			O365-Connect
		}
	}
	Function O365-TestConnection {
        Try {
            $Service.Connection = Invoke-Command $Service.Test -ErrorAction Stop
        } Catch {
            $Service.Status = "Connect"
        }  
        If ($Service.Connection -notlike $null) {
            Write-Host "$($Service.Name) Connected" -ForegroundColor Green
            $Service.Status = "Connected"
        } Else {
            Write-Host "$($Service.Name) Not Connected" -ForegroundColor Red
            $Service.Status = "Connect"
        }
    }
	Function O365-Connect { 
		
		$PreCheck = @{}
		$PreCheck.Required = $O365.Services.Connect.Module
		Pre-Check $PreCheck
		
		If ($O365.Service.SharePoint.Status -eq $True) {    
			Write-Host "Enter the Tenant Name (<tenant>-admin.onmicrosoft.com)" -ForegroundColor Green
			$O365.Tenant = Read-Host
		}
	
		Write-Host "Please Enter the Account to Connect to Office 365" -ForegroundColor Green
		$O365.Account = Get-Credential

		ForEach ($Service in $O365.Services.Connect) {
			
			#CONNECT IF NOT CONNECTED
			If ($Service.Status -eq "Connect") {
				Write-Host "Connecting to $($Service.Name)" -ForegroundColor Yellow
				Write-Host "Please Check for Sign-In Windows" -ForegroundColor DarkYellow
				$Service.Connection = Invoke-Command $Service.Connect
				O365-TestConnection
			}
		}
	}
	O365-TestConnections
}
Function O365-GetMSOnline {
	$O365.MSOnline.LastImport = Get-Date
	Write-Host "Retrieving O365 Users"
    $O365.MSOnline.Users = Get-MsolUser -All
	Write-Host "Retrieving O365 Licenses"
    $O365.MSOnline.Licenses.Current = Get-MsolAccountSku | Select-Object SkuPartNumber,ActiveUnits,ConsumedUnits,SkuId,SubscriptionID | Sort-Object ConsumedUnits
    ForEach ($License in $O365.MSOnline.Licenses.Current) {
        $License | Add-Member -MemberType NoteProperty -Name Name -Value $null -Force
        $License.Name = $O365.MSOnline.Licenses.Sku.($License.SkuPartNumber)
    }
}
Function O365-GetEXOAddresses {
	$O365.Exchange.LastImport = Get-Date
	Write-Host "Retrieving Exchange Addresses"
	$O365.Exchange.Addresses.Existing.All = Get-EXORecipient -ResultSize Unlimited
	Write-Host "Retrieving Exchange Groups"
	$O365.Exchange.Groups = Get-DistributionGroup
	$O365.Exchange.Groups += Get-UnifiedGroup
}
Function O365-GetAZAD {
    $O365.AzureAD.Users = Get-AzureADUser
}
Function Get-O365ServicePlans {

    $O365.MSOnline.Licenses.Import = @{}
    $O365.MSOnline.Licenses.Import.Properties = @(
        'Product',
        'ProductID',
        'GUID',
        'ServiceID',
        'ServiceGUID',
        'Service'
    )
	$O365.MSOnline.Licenses.Report.Properties = @(
        'Product',
        'ProductID',
        'GUID'
    )
	$O365.MSOnline.Licenses.ServicePlans.Report.Properties = @(
        'Service',
        'ServiceID',
        'GUID'
    )

    $O365.MSOnline.Licenses.Import.Location = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"

	#Download license info from Microsoft.
	$O365.MSOnline.Licenses.Import.All = Invoke-RestMethod $O365.MSOnline.Licenses.Import.Location | ConvertFrom-Csv -Header $O365.MSOnline.Licenses.Import.Properties | Select-Object -Skip 1

	#Normalize the data.
	ForEach ($Import in $O365.MSOnline.Licenses.Import.All) {
		$Import.GUID = $Import.GUID -Replace "\(|\)| ",""
		$Import.ProductID = $Import.ProductID.ToUpper() -Replace "\(|\)| ",""
		$Import.Product = (Get-Culture).TextInfo.ToTitleCase($Import.Product.Trim().ToLower())
		$Import.ServiceGUID = $Import.ServiceGUID -Replace "\(|\)| ",""
		$Import.ServiceID = $Import.ServiceID.ToUpper() -Replace "\(|\)| ",""
		$Import.Service = (Get-Culture).TextInfo.ToTitleCase($Import.Service.Trim().ToLower())
	}

    $O365.MSOnline.Licenses.All = $O365.MSOnline.Licenses.Import.All | Select-Object Product,ProductID,GUID -Unique
	$O365.MSOnline.Licenses.ServicePlans = @{}
	$O365.MSOnline.Licenses.ServicePlans.All = $O365.MSOnline.Licenses.Import.All | Sort-Object ServiceGUID | Select-Object ServiceGUID -Unique

	#Get all services.
	ForEach ($Service in $O365.MSOnline.Licenses.ServicePlans.All) {

		$Service | Add-Member -MemberType NoteProperty -Name GUID -Value $Null -Force
		$Service | Add-Member -MemberType NoteProperty -Name ServiceID -Value $Null -Force
		$Service | Add-Member -MemberType NoteProperty -Name Service -Value $Null -Force
		$Service | Add-Member -MemberType NoteProperty -Name Matches -Value $Null -Force
		$Service | Add-Member -MemberType NoteProperty -Name Total -Value $Null -Force
		
		$Service.GUID = $Service.ServiceGUID
		$Service.Matches = $O365.MSOnline.Licenses.Import.All | Where-Object {$_.ServiceGUID -eq $Service.GUID}
		$Service.Total = $Service.Matches.Count
		$Service.ServiceID = $Service.Matches.ServiceID | Where-Object {$_ -notcontains " "} | Sort-Object | Select-Object -Unique
		$Service.Service = $Service.Matches.Service | Where-Object {$_ -notin $Service.ServiceID} | Sort-Object | Select-Object -Unique
	}

	#Get included servcices for each license.
	ForEach ($License in $O365.MSOnline.Licenses.All) {

		$License | Add-Member -MemberType NoteProperty -Name Matches -Value $Null -Force
		$License | Add-Member -MemberType NoteProperty -Name Services -Value $Null -Force

		$License.Matches = $O365.MSOnline.Licenses.Import.All | Where-Object {$_.GUID -eq $License.GUID}
		$License.Services = $O365.MSOnline.Licenses.ServicePlans.All | Where-Object {$_.GUID -in $License.Matches.ServiceGUID}
	}

	$O365.MSOnline.Licenses.ServicePlans.All = $O365.MSOnline.Licenses.ServicePlans.All | Sort-Object Total -Descending

	$O365.MSOnline.Licenses.ServicePlans.Report
	$O365.MSOnline.Licenses.Report = $O365.MSOnline.Licenses.ServicePlans.All | Select-Object 

}
Function O365-SortAddresses {
	ForEach ($Type in $O365.Exchange.Addresses.Types.Values) {
		$Type.All = $O365.Exchange.Addresses.Existing.All | Where-Object {$_.RecipientTypeDetails -eq $Type.O365Map}
	}
}
Function O365-GetAddresses {
	#CHECK IF ADDRESSES CURRENTLY LOADED
    If ($O365.Exchange.Addresses.Types.Values.All){
        Write-Host "O365 Last Import Date: $($O365.MSOnline.LastImport)" -ForegroundColor Yellow
        Write-Host "Exchange Last Import Date: $($O365.Exchange.LastImport)" -ForegroundColor Yellow
        Write-Host "Currently Loaded Addresses:" -ForegroundColor Yellow
        ForEach ($Type in $O365.Exchange.Addresses.Types.Values) {
            Write-Host "    $($Type.All.Count) $($Type.Name)'s Currently Loaded"
        }
		$Menu = @{}
		$Menu.Prompt = "[U]pdate from Office 365 or Use [E]xisting?"
		$Menu.Options = [Ordered]@{}
		$Menu.Options.o1 = @{}
		$Menu.Options.o1.Name = "Update"
		$Menu.Options.o1.Option = "U"
		$Menu.Options.o1.Command = {
			O365-Services -MSOnline -Exchange
			O365-GetMSOnline
			O365-GetEXOAddresses
			O365-SortAddresses	
		}
		$Menu.Options.o2 = @{}
		$Menu.Options.o2.Name = "Existing"
		$Menu.Options.o2.Option = "E"
		$Menu.Options.o2.Command = {
		}
		$Menu.Selection = Select-Options $Menu -Timeout 5 -Default "U"
		Invoke-Command $Menu.Selection.Command
	} Else {
		O365-Services -Graph -MSOnline -Exchange
		O365-GetMSOnline
		O365-GetEXOAddresses
		O365-SortAddresses	
	}
}