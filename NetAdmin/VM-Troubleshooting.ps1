Import-Module "\\SINC\IT\PSRepo\PS-Common.ps1"
$PreCheck = @{}
$PreCheck.Required = @(
    'Microsoft-Hyper-V-Management-PowerShell'
)
Pre-Check $PreCheck
Function VM-Troubleshooting {
    
    param (
        $Hosts
    )
    
    $VM = @{}
    $VM.Hosts = @{}
    $VM.Hosts.All = $Hosts
    $VM.Guests = @{}
    
    $VM.Menu = @{}
    $VM.Menu.Options = [ordered]@{}
    $VM.Menu.Options.o1 = @{}
    $VM.Menu.Options.o2 = @{}
    $VM.Menu.Prompt = "What Would You Like to Do?"
    $VM.Menu.Options.o1.Name = "Get Virtual Machine Status"
    $VM.Menu.Options.o2.Name = "Start Virtual Machines"
    $VM.Menu.Options.o1.Command = {
        Get-VMGuestStatus
        $VM.Guests.Problem = "TEST"
    }
    $VM.Menu.Options.o2.Command = {
        Write-Host $VM.Guests.Problem 
        #ForEach ($Guest in $VM.Guests.Problem) {
        #    Write-Host $Guest | Start-VM | Out-Host
        #}
    }
    Function Get-VMGuestStatus {
        #Get VM Status
        ForEach ($VMHost in $VM.Hosts.All) {
            $VM.Hosts.$($VMHost) = @{}
            Write-Host "Getting VM Guests for $VMHost" -ForegroundColor Yellow
            $VM.Hosts.$($VMHost).Guests = Get-VM -ComputerName $VMHost | Where-Object { $_.ReplicationMode -eq "Primary" -or $_.ReplicationMode -eq "None" } | Select-Object *
            Foreach ($Guest in $VM.Hosts.$($VMHost).Guests) {
                $Guest.VMName
                $Guest | Add-Member -MemberType NoteProperty -Name NetworkStatus -Value $Guest.NetworkAdapters.Status
                $Guest | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Guest.NetworkAdapters.IPAddresses[0]
                $Guest | Add-Member -MemberType NoteProperty -Name MacAddress -Value $Guest.NetworkAdapters.MacAddress
            }
        }
        Clear-Host
        $VM.Hosts.Values.Guests | Select-Object ComputerName, VMName, State, Status, ReplicationHealth, IPAddress, NetworkStatus, MacAddress | Sort-Object IPAddress | Format-Table
        $VM.Guests.Problem = $VM.Hosts.Values.Guests | Where-Object { $_.State -ne "Running" -or $_.Status -ne "Operating normally" -or $_.NetworkStatus -ne "Ok"}
        #Display Problem VMs
        If ($VM.Guests.Problem){
            Write-Host "======================== Problem VMs ========================" -ForegroundColor Red
            $VM.Guests.Problem | Select-Object ComputerName, VMName, State, Status, ReplicationHealth, IPAddress, NetworkStatus, MacAddress | Format-Table | Out-String | Write-Host -ForegroundColor Red
        }
    }
    
    Do {
        Clear-Host
        $VM.Menu.Selection = Menu-Select $VM.Menu
        Clear-Host
        Invoke-Command $VM.Menu.Selection.Command
        Write-Host "Press Any Key to Continue"        
    } Until (
        Read-Host
        )
}

VM-Troubleshooting @('S-HV-1','S-HV-2','S-HV-3','H-HV-1','H-HV-2','H-HV-3')