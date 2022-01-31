#REPORTS HASH TABLE
$Computer.Reports = @{}
$Computer.Reports.Export = @{}
$Computer.Reports.Export.Csv = "C:\TEMP\Computer-Report.csv"
$Computer.Reports.FileTree = @{}
$Computer.Reports.Service = @{}


Function FileTree-Report {
    $Computer.Reports.Export.Csv = "C:\TEMP\FileTree-Report.csv"
    $Computer.Reports.FileTree.Objects = @{}
    $Computer.Reports.FileTree.DirectoryDepth = "1"
    $Computer.Reports.FileTree.SortOrder = "DomainGroup", "DomainUser", "Local", "Other"
    $Computer.Reports.FileTree.GroupsOverride = "Authenticated Users"
    $Computer.Reports.FileTree.UsersOverride = ""
    $Computer.Reports.FileTree.Properties = @{}
    $Computer.Reports.FileTree.Properties.All = @(
        'DirectoryPath'
        'Name'
        'Owner'
        'LastAccessTime'
        'LastWriteTime'
        'Type'
        'Size'
        'Unit'
    )

    #TEMPORARILY SET GLOBAL ERROR ACTION
    $ErrorActionPreference = "SilentlyContinue"

    #GET COMPUTER ENVIRONMENT INFORMATION
    If ($Computer.SystemInfo.PartOfDomain -eq $True) {
        Import-Module ActiveDirectory
        $Computer.Domain.Users = Get-ADUser -Filter *
        $Computer.Domain.Groups = Get-ADGroup -Filter *

        Write-Host "Default Sort Order: $($Computer.Reports.FileTree.SortOrder)"
        Write-Host "New Sort Order (Seperated by Commas[,])[Blank for Default]"
        If ($_ = Read-Host) {
            $Computer.Reports.FileTree.SortOrder = $_
        }
    }

    #VARIABLE PROMPTS
    $Computer.Reports.FileTree.Path = Get-Location
    Write-Host "Current Directory Path to Scan: $($Computer.Reports.FileTree.Path)"
    Write-Host "New Path [Blank for Default]" -ForegroundColor Green
    If ($_ = Read-Host) {
        $Computer.Reports.FileTree.Path = $_
    }
    Write-Host "Default Additional Directory Depth to Scan: $($Computer.Reports.FileTree.DirectoryDepth)"
    Write-Host "New Depth [Blank for Default]" -ForegroundColor Green
    If ($_ = Read-Host) {
        $Computer.Reports.FileTree.DirectoryDepth = $_
    }

    #BUILD COMMAND FOR CHILD OBJECTS
    $Computer.Reports.FileTree.Command = {
        Get-ChildItem -Path $Computer.Reports.FileTree.Path -Recurse -Depth $Computer.Reports.FileTree.DirectoryDepth -ErrorAction SilentlyContinue
    }

    $Computer.Reports.FileTree.Command = $Computer.Reports.FileTree.Command.ToString().Trim()
    Write-Host "Do you want to include files? ( [N]o / [Y]es )" -ForegroundColor Green
    Switch -Wildcard (Read-Host) {
        Default {
            $Computer.Reports.FileTree.Command += " -Directory"
        }
        Y* { 
        }
    }
    Write-Host "Do you want to include Hidden/System Objects? ( [N]o / [Y]es )" -ForegroundColor Green
    Switch -Wildcard (Read-Host) {
        Default {
        }
        Y* { 
            $Computer.Reports.FileTree.Command += " -Force"
        }
    }

    $Computer.Reports.FileTree.Command = [ScriptBlock]::Create($Computer.Reports.FileTree.Command)
    $Computer.Reports.FileTree.Objects.All = Invoke-Command $Computer.Reports.FileTree.Command

    #GET ACL INFO AND TEST
    ForEach ($Item in $Computer.Reports.FileTree.Objects.All) {
        $Error.Clear()
        Try {
            Write-Host "Getting ACL for $($Item.FullName)" -ForegroundColor Yellow
            $Item | Add-Member -MemberType NoteProperty -Name ACL -Value "" -Force
            $Item | Add-Member -MemberType NoteProperty -Name Errors -Value "" -Force
            $Item.ACL = $Item | Get-ACL
        } Catch {
            $Item.Errors = $Error -Join " | "
            Write-Host "Error Reading $($Item.FullName) ACL" -ForegroundColor Red
        }
    }

    #LIST ERRORS AND ATTEMPT TO FIX
    $Computer.Reports.FileTree.Objects.Errors = $Computer.Reports.FileTree.Objects.All | Where-Object { $_.Errors }

    If ($Computer.Reports.FileTree.Objects.Errors) {
        Write-Host "Could not Read ACL for the following..." -ForegroundColor Red
        ForEach ($ErrorItem in $Computer.Reports.FileTree.Objects.Errors) {
            Write-Host "    $($ErrorItem.FullName)" -ForegroundColor Yellow
        }
        Write-Host "Would you like to [C]ontinue or Attempt to [F]ix" -ForegroundColor Red
        Write-Host "([C]ontinue / [F]ix)" -ForegroundColor Yellow
        Switch -Wildcard (Read-Host) {
            Default {
            }
            F* { 
                
            }
        }
    }

    #SORT ACCESS IDS BY TYPE AND NUMBER OF PERMISSIONS
    $Computer.Reports.FileTree.AccessIDs = $Computer.Reports.FileTree.Objects.All.ACL.Access.IdentityReference | Group-Object Value
    
    ForEach ($AccessID in $Computer.Reports.FileTree.AccessIDs) {
        $AccessID | Add-Member -MemberType NoteProperty -Name IDCount -Value ($AccessID).count -Force
        $AccessID | Add-Member -MemberType NoteProperty -Name Type -Value "" -Force
        $AccessID | Add-Member -MemberType NoteProperty -Name FullName -Value ($AccessID.Name) -Force
        $AccessID | Add-Member -MemberType NoteProperty -Name Name -Value ($AccessID.Name.Split("\")[-1]) -Force
        $AccessID | Add-Member -MemberType NoteProperty -Name Domain -Value ($AccessID.Name.Split("\")[-2]) -Force
        $AccessID | Add-Member -MemberType NoteProperty -Name MemberName -Value ($AccessID.Name) -Force
        If ($AccessID.Name -in $Computer.Domain.Users.SamAccountName) {$AccessID.Type = "DomainUser"}
        If ($AccessID.Name -in $Computer.Domain.Groups.Name) {$AccessID.Type = "DomainGroup"}
        If ($AccessID.Domain -eq $Computer.HostName) {$AccessID.Type = "Local"}
        If ($AccessID.Name -in $Computer.Reports.FileTree.GroupsOverride.Split(",")) {$AccessID.Type = "DomainGroup"}
        If ($AccessID.Type -eq "") {$AccessID.Type = "Other"}
        If ($AccessID.Type -ne "Local") {$AccessID.MemberName = $AccessID.Name} 
    }

    $Computer.Reports.FileTree.AccessIDs = $Computer.Reports.FileTree.AccessIDs | Sort-Object {$Computer.Reports.FileTree.SortOrder.IndexOf($_.Type) }, @{e='IDCount';a=$false}
    
    #ADD PROPERTIES FOR EACH ACCESSID TO OBJECTS
    $Computer.Reports.FileTree.PermissionOrder = "F", "W", "R"
    $Computer.Reports.FileTree.Properties.All += $Computer.Reports.FileTree.AccessIDs.MemberName
    $Computer.Reports.FileTree.Properties.New = $Computer.Reports.FileTree.Properties.All | Where-Object {$_ -notin ($Computer.Reports.FileTree.Objects.All | Get-Member).Name}
    
    ForEach ($Property in $Computer.Reports.FileTree.Properties.New) {
        $Computer.Reports.FileTree.Objects.All | Add-Member -MemberType NoteProperty -Name $Property -Value ""
    }

    $Computer.Reports.FileTree.Properties.All += 'Errors'

    #GET ITEM INFO
    ForEach ($Item in $Computer.Reports.FileTree.Objects.All) {
        $Error.Clear()
        Try {  
            Write-Host "Getting Info for $($Item.FullName)" -ForegroundColor Yellow
            
            #GET ITEM SIZE
            $Item.Unit = "kb" 
            $Item.Size = ($Item | Get-ChildItem | Measure-Object -Sum Length).Sum / "1$($Item.Unit)"

            #GET ITEM PERMISSIONS
            $Item.DirectoryPath = $Item.Parent.FullName
            If ($Item.PSIsContainer -eq $True) {
                $Item.Type = "Directory"
            } Else {
                $Item.Type = $Item.Extension
            }
            $Item.Owner = $Item.ACL.Owner
            
            ForEach ($AccessID in $Computer.Reports.FileTree.AccessIDs) {
                $Accesses = $Item.ACL.Access | Where-Object {$_.IdentityReference -eq $AccessID.FullName}
                ForEach ($Access in $Accesses) {
                    $Access | Add-Member -MemberType NoteProperty -Name Permission -Value "" -Force
                    $Access | Add-Member -MemberType NoteProperty -Name CI -Value "" -Force
                    $Access | Add-Member -MemberType NoteProperty -Name OI -Value "" -Force
                    If ($Access.AccessControlType -eq "Allow") {
                        If ($Access.FileSystemRights -match "ReadAndExecute") {$Access.Permission = "R"}
                        If ($Access.FileSystemRights -match "Write") {$Access.Permission = "W"}
                        If ($Access.FileSystemRights -match "FullControl" -or $Access.FileSystemRights -match "Modify") {$Access.Permission = "F"}
                    }
                    If ($Access.AccessControlType -eq "Deny") {$Access.Permission = "D"}
                    If ($Access.Permission -ne "") {
                        If ($Access.InheritanceFlags -match "ContainerInherit") {$Access.CI = "c"}
                        If ($Access.InheritanceFlags -match "ObjectInherit") {$Access.OI = "o"}
                    }
                }
                $Item.($AccessID.MemberName) = ($Accesses | Sort-Object {$Computer.Reports.FileTree.PermissionOrder.IndexOf($_.Permission)} | ForEach-Object {
                    $_.Permission+$_.CI+$_.OI
                } | Get-Unique) -join " "
            }
        } Catch {
            $Item.Errors += $Error -Join " | "
            Write-Host "Error Reading $($Item.FullName)" -ForegroundColor Red
        }
    }

    $ErrorActionPreference = "Continue"

    #EXPORT REPORT
    $Computer.Reports.Export.Report = $Computer.Reports.FileTree.Objects.All | Select-Object $Computer.Reports.FileTree.Properties.All
    Report-Export $Computer.Reports.Export.Report $Computer.Reports.Export.Csv
}
Function Service-Report {

    $Computer.Reports.Export.Csv = "C:\TEMP\Computer-Service-Report.csv"
    $Computer.Reports.Service.Properties = @{}
    $Computer.Reports.Service.Properties.All = @(
        'Name'
        'State'
        'StartMode'
        'Status'
        'StartName'
        'ServiceType'
        'Description'
        'DisplayName'
    )

    $Computer.Reports.Service.Services = Get-WmiObject Win32_Service 
    
    $Computer.Reports.Export.Report = $Computer.Reports.Service.Services | Select-Object $Computer.Reports.Service.Properties.All

    Report-Export $Computer.Reports.Service.Services $Computer.Reports.Export.Csv

}