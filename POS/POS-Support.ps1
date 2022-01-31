
Function POS-Support {
        
        #STRUCTURE HASHTABLE
        $POS = @{}

        $POS.Locations = @{}
        $POS.Locations.Loc1 = @{}
        $POS.Locations.Loc2 = @{}
        $POS.Locations.Loc1.Hardware = @{}
        $POS.Locations.Loc1.Hardware.Data = @{}
        $POS.Locations.Loc2.Hardware = @{}
        $POS.Locations.Loc2.Hardware.Data = @{}
        $POS.Locations.Loc1.POS = @{}
        $POS.Locations.Loc1.POS.Terminals = @{}
        $POS.Locations.Loc1.Cayan = @{}
        $POS.Locations.Loc1.Cayan.Terminals = @{}
        $POS.Locations.Loc2.POS = @{}
        $POS.Locations.Loc2.POS.Terminals = @{}
        $POS.Locations.Loc2.Cayan = @{}
        $POS.Locations.Loc2.Cayan.Terminals = @{}

        $POS.POS = @{}
        $POS.Cayan = @{}
        
        #DEFINE OPTIONS
        $POS.POS.Phone = "1-800-288-8160"
        $POS.Cayan.Phone = "1-888-249-3220"
        $POS.Locations.Loc1.Name = "Location 1"
        $POS.Locations.Loc1.Subnet = "10.20.60"

        $POS.Locations.Loc1.POS.Account = "XX-XXXXXXX"
        $POS.Locations.Loc1.Cayan.Account = "XXXXXXXXXXXXXXXX"

        $POS.Locations.Loc2.Name = "Location 2"
        $POS.Locations.Loc2.Subnet = "10.30.60"

        $POS.Locations.Loc2.POS.Account = "XX-XXXXXXX"
        $POS.Locations.Loc2.Cayan.Account = "XXXXXXXXXXXXXXXX"         
        
        #MENU STRUCTURE
        $POS.Menu = @{}
        $POS.Menu.Options = [ordered]@{}
        $POS.Menu.Options.o1 = @{}
        $POS.Menu.Options.o2 = @{}
        $POS.Menu.Options.o3 = @{}
        $POS.Menu.Options.o4 = @{}
        $POS.Menu.Options.o5 = @{}
        $POS.Menu.Options.o6 = @{}
        $POS.Menu.Options.o7 = @{}
        $POS.Menu.Options.o8 = @{}
        #DEFINE MENU PROMPT
        $POS.Menu.Prompt = "What Would You Like to Do?"
        #DEFINE MENU OPTIONS
        $POS.Menu.Options.o1.Name = "Contact/Connect POS Support"
        $POS.Menu.Options.o2.Name = "Contact Cayan Support"
        $POS.Menu.Options.o3.Name = "Restart Credit Card and POS Host Services"
        $POS.Menu.Options.o4.Name = "Start POS Host Processor Log Screen"
        $POS.Menu.Options.o5.Name = "View Cayan Logs"
        $POS.Menu.Options.o6.Name = "Re-Activate POS"
        $POS.Menu.Options.o7.Name = "Modify Credit Card Driver Settings"
        $POS.Menu.Options.o8.Name = "Troubleshoot Printer"
        $POS.Menu.Options.o1.Command = {
                Clear-Host
                Write-Host "Call POS at $($POS.POS.Phone)" -ForegroundColor Green
                Write-Host "They will provide you a Pin to get Connected" 
                Start-Process "http://remote.POSsystems.com/"
        }
        $POS.Menu.Options.o2.Command = {
                Write-Host "$($POS.Location.Name)'s Merchant ID:" -ForegroundColor Yellow
                Write-Host "$($POS.Location.Cayan.Account)" -ForegroundColor Green
                Write-Host "Call Cayan at $($POS.Cayan.Phone)." -ForegroundColor Yellow
                Write-Host "Press 3 for Terminal Support."
                Write-Host "Press 1 for Genius Support."
                Set-Clipboard $POS.Location.Cayan.Account
        }
        $POS.Menu.Options.o3.Command = {
                Write-Host "Are you sure?  This will take 5-10 Minutes" -ForegroundColor Red
                Switch -Wildcard (Read-Host "[Y]es / [N]o") {
                        Default { }
                        Y* { 
                                Stop-Service POSHostService
                                Stop-Service CayanService
                                Start-Sleep 10
                                Start-Service CayanService
                                Start-Service POSHostService
                                }
                        }
        }
        $POS.Menu.Options.o4.Command = {
                Start-Process "C:\POS\Program\HPLS.exe"
        }
        $POS.Menu.Options.o5.Command = {
                Start-Process "C:\POS\Program\Drivers\CayanLogs"           
        }
        $POS.Menu.Options.o6.Command = {
                Clear-Host
                Start-Process "C:\POS\Program\ActivatorNet.exe"
                Write-Host "$($POS.Location.Name)'s Customer Number:" -ForegroundColor Yellow
                Write-Host "$($POS.Location.POS.Account)" -ForegroundColor Green
                Set-Clipboard $POS.Location.POS.Account
                Write-Host "Enter the Customer Number and Click WEB ACTIVATION"
                Write-Host "Click "ACTIVATE" After the Code is Generated"
                Write-Host "Contact POS with any issues" -ForegroundColor Red   
        }
        $POS.Menu.Options.o7.Command = {
                Start-Process "C:\POS\Program\drvcfg.exe"
        }
        $POS.Menu.Options.o8.Command = {
                Get-TroubleshootingPack "C:\Windows\diagnostics\system\Printer" | Invoke-TroubleshootingPack
        }   

        $POS.IPAddress = (Get-NetIPAddress | Where-Object {$_.IPAddress -match "10\."}).IPAddress
        $POS.Location = $POS.Locations.Values | Where-Object {$POS.IPAddress -match $_.Subnet}

        If (-not $POS.Location) {
                POS-Admin
        }

        Clear-Host
        $POS.Menu.Selection = Menu-Select $POS.Menu
        Invoke-Command $POS.Menu.Selection.Command
        Write-Host "Press Any Key to Continue..." -ForegroundColor Yellow
        Read-Host
        POS-Support

return $POS
}

Function POS-Admin {
        
        $PreCheck = @{}
        $PreCheck.Required = @(
                'PnP.PowerShell'
        )
        Pre-Check $PreCheck 

        $POS.Locations.Loc1.POS.Server = "LOC1-POS"
        $POS.Locations.Loc1.DHCPServer = "LOC1-DC-1"
        $POS.Locations.Loc1.Hardware.Data.Path = "https://<tenant>.sharepoint.com/sites/Loc1Admin/SysAdmin"
        $POS.Locations.Loc1.Hardware.Data.Name = "Network Hosts"
        $POS.Locations.Loc2.POS.Server = "LOC2-POS"
        $POS.Locations.Loc2.DHCPServer = "LOC2-DC-1"
        $POS.Locations.Loc2.Hardware.Data.Path = "https://<tenant>.sharepoint.com/sites/Loc1Admin/SysAdmin"
        $POS.Locations.Loc2.Hardware.Data.Name = "Network Hosts"

        #STRUCTURE HASHTABLE
        $POS.Admin = @{}
        $POS.Admin.Menu = @{}
        $POS.Admin.Menu.Options = [ordered]@{}
        $POS.Admin.Menu.Options.o1 = @{}
        $POS.Admin.Menu.Options.o2 = @{}
        $POS.Admin.Menu.Options.o1.Name = "Replace POS Terminal"
        $POS.Admin.Menu.Options.o2.Name = "Replace Cayan Payment Terminal"
        $POS.Admin.Menu.Options.o1.Command = {
                $POS.Location.POS.Terminals.All | Select-Object $POS.Location.Hardware.Properties.Display.Name | Format-Table
                $POS.Location.POS.Terminals.Update = Menu-Select $POS.Location.POS.Terminals.All -Property HostName -Prompt "Please Select Which Terminal You Want to Update"
        }
        $POS.Admin.Menu.Options.o2.Command = {
                $POS.Location.Cayan.Terminals.All | Select-Object $POS.Location.Hardware.Properties.Display.Name | Format-Table
                $POS.Location.Cayan.Terminals.Update = Menu-Select $POS.Location.Cayan.Terminals.All -Property HostName -Prompt "Please Select Which Terminal You Want to Update" 
        }

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

        $POS.Location = Menu-Select $POS.Locations.Values -Property Name

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

        $POS.Location.Hardware.Properties = Get-TableData $POS.Location.Hardware.Properties

        Connect-PnPOnline -Url $POS.Location.Hardware.Data.Path -UseWebLogin

        $POS.Location.Hardware.Data.Import = (Get-PnPListItem $POS.Location.Hardware.Data.Name).FieldValues | Where-Object {$_.IPAddress -match $POS.Location.Subnet} 
        $POS.Location.Hardware.All = Convert-HashObject $POS.Location.Hardware.Data.Import -Properties $POS.Location.Hardware.Properties.Import

        #Get LookUp Field Values
        ForEach ($Object in $POS.Location.Hardware.All){
                ForEach ($Property in $Object.PSObject.Properties) {
                        If ($Property.TypeNameOfValue -eq "Microsoft.SharePoint.Client.FieldLookupValue") {
                                $Object.($Property.Name) = $Object.($Property.Name).LookUpValue
                        }
                }
        }

        $POS.Location.POS.Terminals.All = $POS.Location.Hardware.All | Where-Object {$_.Brand -eq "POS"} | Sort-Object IPAddress
        $POS.Location.Cayan.Terminals.All = $POS.Location.Hardware.All | Where-Object {$_.Brand -eq "Cayan"} | Sort-Object IPAddress

        $POS.Admin.Menu.Selection = Menu-Select $POS.Admin.Menu

        Invoke-Command $POS.Admin.Menu.Selection.Command

        ForEach ($Update in $POS.Location.Cayan.Terminals.Update) {
                
                Write-Host "Please Enter the New Serial Number" -ForegroundColor Yellow
                $Update.Serial = Read-Host -Prompt "Serial"
                
                Write-Host "Please Enter the New 12 Digit MAC Address [00-00-00-00-00-00]" -ForegroundColor Yellow
                Write-Host "This can be found on the back of the Terminal"
                $Update.MACAddress = Read-Host -Prompt "MAC"
        }

        Set-DhcpServerv4Reservation -ComputerName $POS.Location.DHCPServer -IPAddress $POS.Location.Update.IPAddress -ClientId $POS.Location.Update.MACAddress

        $Update.LastReplaced = (Get-Date).Date

        Set-PnPListItem -List $POS.Location.Hardware.Data.Name -Identity $POS.Location.Update.ID -Values @{
                "MACAddress" = $Update.MACAddress;
                "Serial" = $Update.Serial;
                "LastReplaced" = $Update.LastReplaced;
        }
}

POS-Support