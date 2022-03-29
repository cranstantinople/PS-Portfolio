Function POS-Support {
<#
.Synopsis
        Provides support options for common Point of Sale problems
.DESCRIPTION
.EXAMPLE

.INPUTS
.OUTPUTS
.NOTES
    Author     : Clayton Tschirhart
    Requires   : 
.COMPONENT
.ROLE
.FUNCTIONALITY
#>
        #STRUCTURE HASHTABLE
        $POS = @{}

        $POS.Locations = [Ordered]@{}
        $POS.Locations.Loc1 = @{}
        $POS.Locations.Loc2 = @{}
        $POS.Locations.Loc1.Hardware = @{}
        $POS.Locations.Loc1.Hardware.Data = @{}
        $POS.Locations.Loc2.Hardware = @{}
        $POS.Locations.Loc2.Hardware.Data = @{}
        $POS.Locations.Loc1.POS = @{}
        $POS.Locations.Loc1.POS.Terminals = @{}
        $POS.Locations.Loc1.Payment = @{}
        $POS.Locations.Loc1.Payment.Terminals = @{}
        $POS.Locations.Loc2.POS = @{}
        $POS.Locations.Loc2.POS.Terminals = @{}
        $POS.Locations.Loc2.Payment = @{}
        $POS.Locations.Loc2.Payment.Terminals = @{}

        $POS.POS = @{}
        $POS.Payment = @{}
        
        #DEFINE OPTIONS
        $POS.POS.Phone = "1-800-888-8888"
        $POS.Payment.Phone = "1-888-999-9999"
        $POS.Locations.Loc1.Name = "Location 1"
        $POS.Locations.Loc1.Subnet = "10.20.60"

        $POS.Locations.Loc1.POS.Account = "XX-XXXXXXX"
        $POS.Locations.Loc1.Payment.Account = "XXXXXXXXXXXXXXXX"

        $POS.Locations.Loc2.Name = "Location 2"
        $POS.Locations.Loc2.Subnet = "10.30.60"

        $POS.Locations.Loc2.POS.Account = "XX-XXXXXXX"
        $POS.Locations.Loc2.Payment.Account = "XXXXXXXXXXXXXXXX"         
        
        #MENU STRUCTURE
        $POS.Menu = @{}
      
        #MENU PROMPT
        $POS.Menu.Prompt = "What Would You Like to Do?"
        #MENU OPTIONS
        $POS.Menu.Options = [ordered]@{}
        #Option 1
        $POS.Menu.Options.o1 = @{}
        $POS.Menu.Options.o1.Name = "Contact/Connect POS Support"
        $POS.Menu.Options.o1.Command = {
                Clear-Host
                Write-Host "This option would display the following information and open the POS support Website." -ForegroundColor Yellow
                Write-Host "Call POS at $($POS.POS.Phone)" -ForegroundColor Green
                Write-Host "They will provide you a Pin to get Connected"
                
        }
        #Option 2
        $POS.Menu.Options.o2 = @{}
        $POS.Menu.Options.o2.Name = "Contact Payment Support"
        $POS.Menu.Options.o2.Command = {
                Clear-Host
                Write-Host "This option would display the following information" -ForegroundColor Yellow
                Write-Host "$($POS.Location.Name)'s Merchant ID:" -ForegroundColor Yellow
                Write-Host "$($POS.Location.Payment.Account)" -ForegroundColor Green
                Write-Host "Call Payment at $($POS.Payment.Phone)." -ForegroundColor Yellow
                Write-Host "Press 3 for Terminal Support."
                Write-Host "Press 1 for Genius Support."
        }
        #Option 3
        $POS.Menu.Options.o3 = @{}
        $POS.Menu.Options.o3.Name = "Restart Credit Card and POS Host Services"
        $POS.Menu.Options.o3.Command = {
                Clear-Host
                Write-Host "This option would restart several services" -ForegroundColor Yellow
                Write-Host "Are you sure?  This will take 5-10 Minutes and POS will be unavailable" -ForegroundColor Red
                Switch -Wildcard (Read-Host "[Y]es / [N]o") {
                        Default { }
                        Y* {

                        }
                }
        }
        #Option 4
        $POS.Menu.Options.o4 = @{}
        $POS.Menu.Options.o4.Name = "Start POS Host Processor Log Screen"
        $POS.Menu.Options.o4.Command = {
                Write-Host "This option would start a program" -ForegroundColor Yellow
        }
        #Option 5
        $POS.Menu.Options.o5 = @{}
        $POS.Menu.Options.o5.Name = "View Payment Logs"
        $POS.Menu.Options.o5.Command = {
                Write-Host "This option would open the Log Files Folder" -ForegroundColor Yellow
                #Start-Process "C:\POS\Program\Drivers\PaymentLogs"           
        }
        #Option 6
        $POS.Menu.Options.o6 = @{}
        $POS.Menu.Options.o6.Name = "Re-Activate POS"
        $POS.Menu.Options.o6.Command = {
                Clear-Host
                Write-Host "This option run the web activation program and copy the Customer Number to the Clipboard" -ForegroundColor Yellow
                Write-Host "$($POS.Location.Name)'s Customer Number:" -ForegroundColor Yellow
                Write-Host "$($POS.Location.POS.Account)" -ForegroundColor Green
                Set-Clipboard $POS.Location.POS.Account
                Write-Host "Enter the Customer Number and Click WEB ACTIVATION"
                Write-Host "Click "ACTIVATE" After the Code is Generated"
                Write-Host "Contact POS with any issues" -ForegroundColor Red   
        }
        #Option 7
        $POS.Menu.Options.o7 = @{}
        $POS.Menu.Options.o7.Name = "Modify Credit Card Driver Settings"
        $POS.Menu.Options.o7.Command = {
                Write-Host "This option would run a POS specific program from Payment Driver Configuration" -ForegroundColor Yellow
        }
        $POS.Menu.Options.o8 = @{}
        $POS.Menu.Options.o8.Name = "Troubleshoot Printer"
        $POS.Menu.Options.o8.Command = {
                Write-Host "This option would run the Printer Troubleshooting Pack" -ForegroundColor Yellow
                Get-TroubleshootingPack "C:\Windows\diagnostics\system\Printer" | Invoke-TroubleshootingPack
        }
        $POS.Menu.Options.o9 = @{}
        $POS.Menu.Options.o9.Name = "Admin Menu"
        $POS.Menu.Options.o9.Tip = "This option would be default from Admin computers"
        $POS.Menu.Options.o9.Command = {
                Write-Host "Admin menu would run by default if not on POS Host and User was a Domain Admin" -ForegroundColor Yellow
                POS-Admin
        }
        $POS.Menu.Back = @{}
        $POS.Menu.Back.Command = {
                Start-Demo
        }

        $POS.IPAddress = (Get-NetIPAddress | Where-Object {$_.IPAddress -match "10\."}).IPAddress
        #$POS.Location = $POS.Locations.Values | Where-Object {$POS.IPAddress -match $_.Subnet}

        Write-Host "All Menu's Demonstrate a Function I created for simplified PowerShell Menu Creation and Execution"
        Write-Host "Please Select a Demo Location" -ForegroundColor Yellow
        $POS.Location = Select-Options $POS.Locations.Values -Property Name -Back $POS.Menu.Back
        
        If (-not $POS.Location) {
                POS-Admin
        }

        Clear-Host
        $POS.Menu.Selection = Select-Options $POS.Menu -Back $POS.Menu.Back
        Invoke-Command $POS.Menu.Selection.Command
        Write-Host "Press Any Key to Continue..." -ForegroundColor Yellow
        Read-Host
        POS-Support

return $POS
}

Function POS-Admin {
        
        Write-Host "Checking for required Variables, Modules, Scripts and Windows Features using Function I created to verify pre-requisites"
        Write-Host "This Function checks multiple locations and Repo's for prereq's and Installs/Updates them as necessary"

        $PreCheck = @{}
        $PreCheck.Required = @(
                'PnP.PowerShell'
        )
        Pre-Check $PreCheck 

        #Locations
        $POS.Locations.Loc1.POS.Server = "LOC1-POS"
        $POS.Locations.Loc1.DHCPServer = "LOC1-DC-1"
        $POS.Locations.Loc1.Hardware.Data.Path = "https://<tenant>.sharepoint.com/sites/Loc1Admin/SysAdmin"
        $POS.Locations.Loc1.Hardware.Data.Name = "Network Hosts"
        $POS.Locations.Loc2.POS.Server = "LOC2-POS"
        $POS.Locations.Loc2.DHCPServer = "LOC2-DC-1"
        $POS.Locations.Loc2.Hardware.Data.Path = "https://<tenant>.sharepoint.com/sites/Loc1Admin/SysAdmin"
        $POS.Locations.Loc2.Hardware.Data.Name = "Network Hosts"

        #Structure Hashtable
        $POS.Admin = @{}

        #Menu Hashtable
        $POS.Admin.Menu = @{}
        $POS.Admin.Menu.Options = [ordered]@{}
        $POS.Admin.Menu.Options.o1 = @{}
        $POS.Admin.Menu.Options.o2 = @{}
        $POS.Admin.Menu.Options.o1.Name = "Replace POS Terminal"
        $POS.Admin.Menu.Options.o2.Name = "Replace Payment Payment Terminal"
        $POS.Admin.Menu.Options.o1.Command = {
                Write-Host "In production this option would filter the hardware list for active POS Terminals"
                Write-Host "User would make a selection and be promted for the new MAC address, Make and Model of the hardware"
                Write-Host "DHCP and Hardware information would be updated where necessary"
                Write-Host "Updated information would be written to original source"
                #$POS.Location.POS.Terminals.All | Select-Object $POS.Location.Hardware.Properties.Display.Name | Format-Table
                #$POS.Location.POS.Terminals.Update = Menu-Select $POS.Location.POS.Terminals.All -Property HostName -Prompt "Please Select Which Terminal You Want to Update"
        }
        $POS.Admin.Menu.Options.o2.Command = {
                Write-Host "In production this option would filter the hardware list for active POS Terminals"
                Write-Host "User would make a selection and be promted for the new MAC address, Make and Model of the hardware"
                Write-Host "DHCP and Hardware information would be updated where necessary"
                Write-Host "Updated information would be written to original source"
                #$POS.Location.Payment.Terminals.All | Select-Object $POS.Location.Hardware.Properties.Display.Name | Format-Table
                #$POS.Location.Payment.Terminals.Update = Menu-Select $POS.Location.Payment.Terminals.All -Property HostName -Prompt "Please Select Which Terminal You Want to Update" 
        }

        #Prompts Hashtable
        $POS.Admin.Prompts = @{}
        $POS.Admin.Prompts = [ordered]@{}
        $POS.Admin.Prompts.p1 = @{}
        $POS.Admin.Prompts.p2 = @{}
        $POS.Admin.Prompts.p1.Name = "Serial"
        $POS.Admin.Prompts.p2.Name = "MACAddress"
        $POS.Admin.Prompts.p1.Prompt = "Please Enter the New Serial Number"
        $POS.Admin.Prompts.p2.Prompt = "Please Enter the New 12 Digit MAC Address [00-00-00-00-00-00]"
        $POS.Admin.Prompts.p1.Tip = "This can be found on the back of the Terminal"
        $POS.Admin.Prompts.p2.Tip = "This can be found on the back of the Terminal"
        $POS.Admin.Prompts.p2.Validate = {
                $Prompt.Result.Replace.Count -eq "12"
        }

        $POS.Location = Select-Options $POS.Locations.Values -Property Name -Back $POS.Menu.Back

        $POS.Location.Hardware.Properties = @(                       
                'Name           |Maps           |Import*|Display*|Prompt*|Update* ',
                'HostName       |Title;Name     |True   |True   |       |       ',
                'IPAddress      |               |True   |True   |       |       ',
                'MACAddress     |               |True   |True   |True   |True   ',
                'Host           |               |True   |True   |       |       ',
                'Brand          |               |True   |True   |       |       ',
                'Model          |               |True   |True   |       |       ',
                'Serial         |               |True   |True   |True   |True   ',
                'LastReplaced   |               |True   |True   |       |True   ',
                'ID             |               |True   |       |       |       '
        )

        $POS.Location.Hardware.Properties = Get-DsvData $POS.Location.Hardware.Properties

        Write-Host "In production, this would retrieve a list of POS hardware from either a SQL DataBase or a SharePoint Network Asset List..."

        #Connect-PnPOnline -Url $POS.Location.Hardware.Data.Path -UseWebLogin

        #$POS.Location.Hardware.Data.Import = (Get-PnPListItem $POS.Location.Hardware.Data.Name).FieldValues | Where-Object {$_.IPAddress -match $POS.Location.Subnet} 
        #$POS.Location.Hardware.All = Convert-HashObject $POS.Location.Hardware.Data.Import -Properties $POS.Location.Hardware.Properties.Import

        #Get LookUp Field Values
        #ForEach ($Object in $POS.Location.Hardware.All){
        #        ForEach ($Property in $Object.PSObject.Properties) {
        #               If ($Property.TypeNameOfValue -eq "Microsoft.SharePoint.Client.FieldLookupValue") {
        #                        $Object.($Property.Name) = $Object.($Property.Name).LookUpValue
        #                }
        #        }
        #}

        $POS.Location.POS.Terminals.All = $POS.Location.Hardware.All | Where-Object {$_.Brand -eq "POS"} | Sort-Object IPAddress
        $POS.Location.Payment.Terminals.All = $POS.Location.Hardware.All | Where-Object {$_.Brand -eq "Payment"} | Sort-Object IPAddress

        $POS.Admin.Menu.Selection = Menu-Select $POS.Admin.Menu

        Invoke-Command $POS.Admin.Menu.Selection.Command

        #ForEach ($Update in $POS.Location.Payment.Terminals.Update) {
                
        #        Write-Host "Please Enter the New Serial Number" -ForegroundColor Yellow
        #        $Update.Serial = Read-Host -Prompt "Serial"
        #       
        #        Write-Host "Please Enter the New 12 Digit MAC Address [00-00-00-00-00-00]" -ForegroundColor Yellow
        #        Write-Host "This can be found on the back of the Terminal"
        #        $Update.MACAddress = Read-Host -Prompt "MAC"
        #}

        #Set-DhcpServerv4Reservation -ComputerName $POS.Location.DHCPServer -IPAddress $POS.Location.Update.IPAddress -ClientId $POS.Location.Update.MACAddress

        #$Update.LastReplaced = (Get-Date).Date

        #Set-PnPListItem -List $POS.Location.Hardware.Data.Name -Identity $POS.Location.Update.ID -Values @{
        #        "MACAddress" = $Update.MACAddress;
        #        "Serial" = $Update.Serial;
        #        "LastReplaced" = $Update.LastReplaced;
        #}
}