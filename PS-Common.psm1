Function Pre-Check {
    
    param (
        $PreCheckInput,
        $Locations,
        [switch]$Force,
        [switch]$Results
    )

    #STRUCTURE
    $PreCheck = @{}
    $PreCheck.Scripts = @{}
    $PreCheck.Modules = @{}
    $PreCheck.Features = @{}

    $PreCheck.Scripts.Locations = @{}
    $PreCheck.Scripts.Locations.All = @(
        "$($env:USERPROFILE)\Sammy's, Inc\Sammy's Admin - Files\SysAdmin\PSRepo\",
        "\\SINC\IT\PSRepo\"
    )

    $PreCheck.Force = $Force
    $PreCheck.Input = $PreCheckInput
    $PreCheck.Date = (Get-Date).Date

    #VERIFY LAST CHECKED
    If ($PreCheck.Input.Result.Date -eq $PreCheck.Date -and $PreCheck.Force -ne $true) {
        Return
    }

    $PreCheck.Scripts.Locations.Items = ForEach ($Location in $PreCheck.Scripts.Locations.All) {
        If (Test-Path $Location) {
            Get-ChildItem $Location -Recurse
        }
    }
    
    #DETERMINE REQUIRED DETAILS
    $PreCheck.Required = @()
    $PreCheck.Scripts.Required = @()
    $PreCheck.Features.Required = @()
    $PreCheck.Modules.Required = @()
    ForEach ($Required in $PreCheck.Input.Required) {
        $NewObject = New-Object PSCustomObject
        $NewObject | Add-Member -MemberType NoteProperty -Name Name -Value $null
        $NewObject | Add-Member -MemberType NoteProperty -Name Type -Value $null
        $NewObject | Add-Member -MemberType NoteProperty -Name Location -Value $null
        $NewObject | Add-Member -MemberType NoteProperty -Name Match -Value $null
        If ($Required.Name) {
            $NewObject.Name = $Required.Name
        } Else {
            $NewObject.Name = $Required
        }
        $PreCheck.Required += $NewObject
    }
    #Determine Type
    ForEach ($Required in $PreCheck.Required) {
        #Check if Script
        $Required.Match = $PreCheck.Scripts.Locations.Items | Where-Object {$_.Name -Match $Required.Name} | Select-Object -First 1
        If ($Required.Match) {
            $Required.Type = "Script"
            $Required.Location = $Required.Match.PSPath
            $PreCheck.Scripts.Required += $Required
        } Else {
            #Check if Feature
            $Required.Match = Get-WindowsOptionalFeature -Online -FeatureName $Required.Name
            If ($Required.Match) {
                $Required.Type = "Feature"
                $PreCheck.Features.Required += $Required
            } Else {
                #Check if Module
                $Required.Match = Find-Module -Name $Required.Name
                If ($Required.Match) {
                    $Required.Type = "Module"
                    $Required.Location = $Required.Match.Repository
                    $PreCheck.Modules.Required += $Required
                } Else {
                    $Required.Type = "Not Found"
                    $PreCheck.NotFound += $Required
                }
            }
        }
    }

    Function Verify-Scripts {
        ForEach ($Script in $PreCheck.Scripts.Required) {
            Write-Host "Importing Required Script: $($Script.Name)" -ForegroundColor Yellow
            Write-Host $Script.Match.FullName
            Import-Module $Script.Match.FullName -Force -Global
        }
    }
    Function Verify-Features {
        ForEach ($Feature in $PreCheck.Feature.Required) {
            If ($Feature.State -ne "Enabled") {
                Write-Host "Installing Required Feature: $($Feature.Name)" -ForegroundColor Yellow
                Start-Process PowerShell -verb runas -argument "Enable-WindowsOptionalFeature -Online -FeatureName $($Feature.Name)"
            }
        }
    }
    Function Verify-Modules {
        
        #VERIFY MODULES
        $PreCheck.Modules.Repo = Get-PSRepository

        #CHECK IF MODULE LOADED
        ForEach ($Module in $PreCheck.Modules.Required) {
            Write-Host "Checking for $($Module.Name) Module" -ForegroundColor Yellow
            $Module | Add-Member -MemberType NoteProperty -Name Current -Value $null
            $Module | Add-Member -MemberType NoteProperty -Name Repo -Value $null
            $Module | Add-Member -MemberType NoteProperty -Name Status -Value $null
            $Module.Current = Get-Module $Module.Name
            $Module.Repo = $Module.Match
            If ($Module.Current -like $null) {
                Write-Host "$($Module.Name) Module Not Loaded." -ForegroundColor Red
                $Module.Status = "NotLoaded"
            } Else {
                Write-Host "$($Module.Name) Version $($Module.Current.Version) Loaded." -ForegroundColor Green
                $Module.Status = "Loaded"
            }
        }
        #CHECK IF MODULES INSTALLED
        If ($PreCheck.Modules.Required -match "NotLoaded") {
            Write-Host "Checking if Missing Modules Installed" -ForegroundColor Yellow
            $PreCheck.Modules.Installed = Get-Module -ListAvailable
        }
        ForEach ($Module in $PreCheck.Modules.Required) {
            If ($Module.Status -eq "NotLoaded") {
                If ($Module.Name -in $PreCheck.Modules.Installed.Name) {
                Write-Host "$($Module.Name) Module Installed... Importing" -ForegroundColor Yellow
                Import-Module $Module.Name
                $Module.Current = Get-Module $Module.Name
                $Module.Status = "Loaded"
                } Else {
                    Write-Host "$($Module.Name) Module Not Installed" -ForegroundColor Red
                    $Module.Status = "NotInstalled"
                    Install-Module $Module.Name -Force
                    Write-Host "$($Module.Name) Module Installed... Importing" -ForegroundColor Yellow
                    Import-Module $Module.Name
                    $Module.Status = "Loaded"
                    $Module.Current = Get-Module $Module.Name
                }
            }
        }
        #UPDATE MODULES
        ForEach ($Module in $PreCheck.Modules.Required) {
            If ($Module.Current.Version -ne $Module.Repo.Version) {
                Write-Host "$($Module.Name) Out of Date" -ForegroundColor Yellow
                $Module.Status = "OutOfDate"
                Write-Host "$($Module.Name) Module Updating from Repository" -ForegroundColor Yellow
                Remove-Module $Module.Name -Force
                Install-Module $Module.Name -Force
                Write-Host "$($Module.Name) Module Updated... Importing" -ForegroundColor Yellow
                Import-Module $Module.Name
                $Module.Current = Get-Module $Module.Name
                $Module.Status = "Loaded"
            }
        }
    }
    Verify-Scripts
    Verify-Modules
    If ($Results) {
        Return $PreCheck
    }
}
Function Menu-Select {

    param (
    [parameter(Mandatory=$true)]
    $MenuInput,
    $Prompt,
    $Property
    )
    
    If ($MenuInput.Options.Values) {
            $Menu = $MenuInput
    } Else {
            $Menu = @{}
            $Menu.Prompt = $Prompt
            $Menu.Options = [Ordered] @{}
            $o = 1
            ForEach ($Option in $MenuInput) {
                    $Menu.Options.Add("o$($o)", @{})
                    If ($Property) {
                            $Menu.Options."o$($o)".Name = $Option.$Property
                            $Menu.Options."o$($o)".Return = $Option
                    } Else {
                            $Menu.Options."o$($o)".Name = $Option
                            $Menu.Options."o$($o)".Return = $Option
                    }
                    $o += 1
            }
    }
    #DEFINE OPTIONS
    $o = 1
    ForEach ($Option in $Menu.Options.Values) {
            $Option.Option = $o
            $o += 1
    } 

    Function Select-MenuOption {
        #DISPLAY MENU   
        Write-Host $Menu.Prompt -ForegroundColor Green
        ForEach ($Option in $Menu.Options.Values) {
                Write-Host "    [$($Option.Option)] $($Option.Name)"
        }
        Write-Host "    [X] to Exit" -ForegroundColor Yellow
        Write-Host "Please Make a Selection:" -ForegroundColor Green
        $Menu.Selection = Read-Host 
        $Menu.Selection = $Menu.Selection -split ","
        If ($Menu.Selection -eq "x") {
                Exit
        }
        If ((Compare-Object $Menu.Selection $Menu.Options.Values.Option).SideIndicator -notcontains "<=") {
                $Menu.Selection = $Menu.Options.Values | Where-Object {$_.Option -in $Menu.Selection}
        } Else {
                Write-Host "Invalid Selection. Please Make a Valid Selection" -ForegroundColor Red
                Select-MenuOption
        }
    }
    Select-MenuOption
    #RETURN SELECTION
    If ($Menu.Selection.Return) {
            return $Menu.Selection.Return
    } Else {
            return $Menu.Selection
    }
    
}
Function App-Flow {

    param (
    [parameter(Mandatory=$true)]
    $AppInput,
    $Prompt,
    $Property
    )
    
    If ($MenuInput.Options.Values) {
            $Menu = $MenuInput
    } Else {
            $Menu = @{}
            $Menu.Prompt = $Prompt
            $Menu.Options = [Ordered] @{}
            $o = 1
            ForEach ($Option in $MenuInput) {
                    $Menu.Options.Add("o$($o)", @{})
                    If ($Property) {
                            $Menu.Options."o$($o)".Name = $Option.$Property
                            $Menu.Options."o$($o)".Return = $Option
                    } Else {
                            $Menu.Options."o$($o)".Name = $Option
                            $Menu.Options."o$($o)".Return = $Option
                    }
                    $o += 1
            }
    }
    #DEFINE OPTIONS
    $o = 1
    ForEach ($Option in $Menu.Options.Values) {
            $Option.Option = $o
            $o += 1
    } 

    Function Select-MenuOption {
        #DISPLAY MENU   
        Write-Host $Menu.Prompt -ForegroundColor Green
        ForEach ($Option in $Menu.Options.Values) {
                Write-Host "    [$($Option.Option)] $($Option.Name)"
        }
        Write-Host "    [X] to Exit" -ForegroundColor Yellow
        Write-Host "Please Make a Selection:" -ForegroundColor Green
        $Menu.Selection = Read-Host 
        $Menu.Selection = $Menu.Selection -split ","
        If ($Menu.Selection -eq "x") {
                Exit
        }
        If ((Compare-Object $Menu.Selection $Menu.Options.Values.Option).SideIndicator -notcontains "<=") {
                $Menu.Selection = $Menu.Options.Values | Where-Object {$_.Option -in $Menu.Selection}
        } Else {
                Write-Host "Invalid Selection. Please Make a Valid Selection" -ForegroundColor Red
                Select-MenuOption
        }
    }
    Select-MenuOption
    #RETURN SELECTION
    If ($Menu.Selection.Return) {
            return $Menu.Selection.Return
    } Else {
            return $Menu.Selection
    }
    
}
Function Convert-HashObject {

    param (
        [parameter(Mandatory=$true)]
        $ConvertInput,
        $OutputType,
        $Properties,
        $ReturnOriginal
        )

    $Convert = @{}
    $Convert.Input = @{}
    $Convert.Input.Input = $ConvertInput

    #DETERMINE PROPERTIES
    $Convert.Properties = @{}
    $Convert.Properties.Input = $Properties
    $Convert.Properties.All = &{
        If ($Convert.Input.Input.Values) {
            $Convert.Input.Input.Keys | Sort-Object | Get-Unique
            $Convert.Input.Type = "Hashtable"
        } Else {
            $Convert.Properties.All = ($Convert.Input.Input | Get-Member | Where-Object {$_.MemberType -match "Property"}).Name
            $Convert.Input.Type = "Array"
        }
    }
    $Convert.Properties.Return = &{
        If ($Convert.Properties.Input) {
            $Convert.Properties.Input
        } Else {
            $Convert.Properties.All
        }
    }
    If (-not $Convert.Properties.Return.Name) {
        $Convert.Properties.Return = Convert-Dsv $Convert.Properties.Return
    }

    $Convert.Result = @()
    ForEach ($Object in $Convert.Input.Input) {
            $NewObject = New-Object PSCustomObject
            ForEach ($Property in $Convert.Properties.Return) {
                    $NewObject | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $null
                    $NewObject.($Property.Name) = &{
                            If ($Property.Maps) {
                                    $Object.($Property.Maps | Where-Object {$_ -in $Convert.Properties.All} | Select-Object -First 1)
                            } Else {
                                    $Object.($Property.Name)
                            }
                    }
            }
            $Convert.Result += $NewObject
    }
    Return $Convert.Result    
}
Function Report-Export {

    param (
        [parameter(Mandatory=$true)]
        $ReportInput,
        $Export
        )

    $Report = @{}
    $Report.Report = $ReportInput
    $Report.Export = @{}
    $Report.Export.Path = "C:\TEMP"
    $Report.Export.Name = "Report"
    $Report.Export.Extension = "csv"

    $Report.Export = Define-FullPath $Export $Report.Export
    
    Write-Host "View or Export ( [V]iew / [E]xport / [B]ack / [Q]uit )" -ForegroundColor Green
    Switch -Wildcard (Read-Host) {
        Default {
            $Report.Report | Out-GridView
        }
        E* {
            $Report.Export = Define-FullPath $Export $Report.Export -Update
            $Report.Report | Export-Csv $Report.Export.FullPath -NoTypeInformation
        }
        B* {
            Return
        }
        Q* {
            Exit
        }
    }
    Report-Export $ReportInput $Export
}
Function Out-Multi {
          
    param (
        [Parameter(ValueFromPipeline=$true)]
        $Message,
        $OutHost,
        $OutVar,
        $BackgroundColor,
        $OutFile,
        [Switch]$Append
    )
    
    $MultiOut = @{}
    $MultiOut.Input = $Message

    $MultiOut.Host = @{}
    $MultiOut.Host.Host = $OutHost
    $MultiOut.Host.BackgroundColor = $BackgroundColor

    $MultiOut.Var = @{}
    $MultiOut.Var.Var = $OutVar

    $MultiOut.File = @{}
    $MultiOut.File.File = $OutFile

    $MultiOut.Host.Command = {
        Write-Host $MultiOut.Input
    }
    $MultiOut.Var.Command = {
    }
    $MultiOut.File.Command = {
    }

    #Output to Host
    If ($MultiOut.Host.Host) {
        If ($MultiOut.Host.Host) {

        }
    }

    #Output to Variable
    If ($MultiOut.Var.Var) {
        
    }
}
Function Convert-Dsv {
    param (
        [parameter(Mandatory=$true)]
        $DataInput,
        $Headers,
        $Delimiter,
        [Switch]$Details
    )
    
    #Determine Table Layout
    $Dsv = @{}
    $Dsv.Delimiters = @{}
    $Dsv.Delimiters.d1 = @{}
    $Dsv.Delimiters.d2 = @{}

    $Dsv.Trim = @('"'," ")
    $Dsv.Delimiters.d1.Delimiter = ","
    $Dsv.Delimiters.d2.Delimiter = ";"

    If ($Delimiter) {
        $Dsv.Delimiters.d1.Delimiter = $Delimiter[0]
        $Dsv.Delimiters.d2.Delimiter = $Delimiter[1]
    }

    $Dsv.Delimiters.RegEx = '(?=([^\"]*\"[^\"]*\")*[^\"]*$)'
    $Dsv.Delimiters.d1.Regex = "\$($Dsv.Delimiters.d1.Delimiter)"+$Dsv.Delimiters.RegEx
    $Dsv.Delimiters.d2.Regex = "\$($Dsv.Delimiters.d2.Delimiter)"+$Dsv.Delimiters.RegEx

    $Dsv.Table = @{}
    $Dsv.Table.Headers = @()
    
    $Dsv.Table.Result = @{}
    $Dsv.Table.Result.All = @()
    ForEach ($Header in (($DataInput | Select-Object -First 1) -Split $Dsv.Delimiters.d1.Regex).Trim($Dsv.Trim)) {
        $NewHeader = New-Object PSCustomObject
        $NewHeader | Add-Member -MemberType NoteProperty -Name Name -Value $null -Force
        $NewHeader | Add-Member -MemberType NoteProperty -Name Sort -Value $null -Force
        
        $NewHeader.Name = $Header.Replace("*","")
        If ($Header -match "\*") {
            $NewHeader.Sort = $true
            $Dsv.Table.Result.($NewHeader.Name) = @()
        }
        $Dsv.Table.Headers += $NewHeader 
    }
    $Dsv.Table.Data = $DataInput | Select-Object -Skip 1
    ForEach ($Entry in $Dsv.Table.Data) {
        If ($Entry.Replace($Dsv.Delimiters.d1.Regex,"").Length -gt 0) {
            $NewEntry = New-Object PSCustomObject
            ForEach ($Header in $Dsv.Table.Headers) {
                $NewEntry | Add-Member -MemberType NoteProperty -Name $Header.Name -Value $null -Force
                $NewEntry.($Header.Name) = (($Entry -Split $Dsv.Delimiters.d1.Regex)[$Dsv.Table.Headers.Name.IndexOf($Header.Name)]).Trim($Dsv.Trim) | Select-Object
                
                #Split into Array if SubDelimiter
                If ($Dsv.Delimiters.d2.Delimiter -and $NewEntry.($Header.Name) -match $Dsv.Delimiters.d2.Delimiter) {
                    $NewEntry.($Header.Name) = ($NewEntry.($Header.Name) -Split $Dsv.Delimiters.d2.Regex).Trim($Dsv.Trim) | Select-Object
                }
                
                #Add to Sort Groups if Sorting is Applicable
                If ($Header.Sort -eq $True -and $NewEntry.($Header.Name) -eq $True) {
                    $Dsv.Table.Result.($Header.Name) += $NewEntry
                }
            }
            $Dsv.Table.Result.All += $NewEntry
        }
    }
    #Return Results
    If ($Details) {
        Return $Dsv.Table
    } Else {
        Return $Dsv.Table.Result.All
    }
    
}
Function Get-TableData {

    param (
        [parameter(Mandatory=$true)]
        $DataInput,
        $Path,
        $TableExport,
        $Delimiter,
        [Switch]$Update,
        [Switch]$Sort
        )

    #Hash Structure and Defaults
    $TableData = @{}
    $TableData.Input = @{}
    $TableData.Import = @{}
    $TableData.Import.File = @{}

    $TableData.Input.Delimiter = "|;"

    $TableData.Import.File.Path = "C:\TEMP"
    $TableData.Import.File.Name = "Table-Import"
    $TableData.Import.File.Extension = "csv"
    $TableData.Import.Delimiter = ","
    
    #Change Delimiter if Specified
    If ($Delimiter) {
        $TableData.Input.Delimiter = $Delimiter
    }

    #Get Default Import Path
    $TableData.Import.File = Define-FullPath $Path -Defaults $TableData.Import.File

    Function Import-Data {
        Write-Host "Checking for $($TableData.Import.File.FullPath)" -ForegroundColor Yellow
        
        $TableData.Import.File.Exists = Test-Path $TableData.Import.File.FullPath
        
        #Test if File Exists
        $TableData.Import.File.Pass = $null
        If ($TableData.Import.File.Exists -eq $True) {
            Write-Host "$($TableData.Import.File.FullPath) Exists" -ForegroundColor Green
            $TableData.Import.Table = Get-Content $TableData.Import.File.FullPath
            $TableData.Import.Table = Convert-Dsv $TableData.Import.Table -Details
            #Test if Headers Match
            If (Compare-Object $TableData.Input.Table.Headers.Name $TableData.Import.Table.Headers.Name) {
                Write-Host "$($TableData.Import.File.FullPath) Headers Do Not Match" -ForegroundColor Red
                $TableData.Import.File.Pass = $False
            }
            #Test if Contains Data
            If ($TableData.Import.Table.Result.All.Count -eq 0) {
                Write-Host "$($TableData.Import.File.FullPath) Does Not Contain Any Data" -ForegroundColor Red
                Write-Host "Please Enter Data in $($TableData.Import.File.FullPath) and Press any Key to Continue" -ForegroundColor Yellow
                Read-Host
                $TableData.Import.File.Pass = $False
                Import-Data
            }
        } Else {
            Write-Host "$($TableData.Import.File.FullPath) Does Not Exist" -ForegroundColor Red
            $TableData.Import.File.Pass = $False
        }

        If ($TableData.Import.File.Pass -eq $False -or $Update) {
            Write-Host "Would you like to [E]xport File to Enter Data or [U]pdate Path to an Existing File" -ForegroundColor Green
            Switch -Wildcard (Read-Host "[E]xport / [U]pdate") {
                E* {
                    Write-Host "Exporting $($TableData.Import.File.FullPath)" -ForegroundColor Yellow
                    "" | Select-Object $TableData.Input.Table.Headers.Name | Export-Csv -Path $TableData.Import.File.FullPath -NoTypeInformation
                }
                U* {
                    $TableData.Import.File = Define-FullPath $Path $TableData.Import.File -Update
                }
            }
            Import-Data
        }
        Write-Host "Importing Data..." -ForegroundColor Green
        $TableData.Result = $TableData.Import.Table.Result.All
        $TableData.Result | Out-Host
    }
    Function Enter-Data {
        $TableData.Result = @()
        do {
            $NewObject = New-Object PSCustomObject
            ForEach ($Header in $TableData.Input.Table.Headers) {
                $NewObject | Add-Member -MemberType NoteProperty -Name $Header -Value $null
                $NewObject.$Header = Read-Host "$($Header)"
            }
            $TableData.Result += $NewObject
            $TableData.Result | Format-Table
            Write-Host 'Press Enter to Add Another or [F] to Finish' -ForegroundColor Green
            $Action = Read-Host
        } until ($Action -match "F.*")
    }

    #Resolve Input Data
    $TableData.Input.Table = Convert-Dsv $DataInput -Delimiter $TableData.Input.Delimiter -Details
    
    #If Input Full Table Return
    If ($TableData.Input.Table.Result.All) {
        $TableData.Result = $TableData.Input.Table.Result
    }

    #Get Data If No Result or Update Switch is Selected
    If (-not $TableData.Result -or $Update) {
        $TableData.Result | Format-Table
        Write-Host "Would you like to [I]mport from File or [E]nter Data" -ForegroundColor Green
        Switch -Wildcard (Read-Host "[I]mport / [E]nter") {
            Default {
                Import-Data
            }
            E* {
                If ($TableData.Result) {
                    $TableData.Result
                    Write-Host "Data Already Exists" -ForegroundColor Yellow
                    Write-Host "Would you like to [A]dd to Existing Data or [C]lear and Enter New" -ForegroundColor Green
                    Switch -Wildcard (Read-Host "[A]dd / [C]lear") {
                        Default {
                        }
                        C* {
                            $TableData.Result = $null
                        }
                    }
                }
                Enter-Data
            }
        }
    }

    Return $TableData.Result 
    
    #| Sort-Object | Get-Unique | Select-Object | Where-Object {$_ -notlike $null}
}
Function Define-FullPath {

    param (
        $PathInput,
        $Defaults,
        [Switch]$Update
    )

    $FullPath = @{}
    $FullPath.Defaults = @{}
    $FullPath.Defaults.Path = "C:\TEMP"
    $FullPath.Defaults.Name = "File"
    $FullPath.Defaults.Extension = "txt"

    #SET INPUT DEFAULTS OR USE GLOBAL DEFAULTS
    If ($Defaults) {
        $FullPath.Defaults = $Defaults
    }
    Function Resolve-FullPath {
        #DETERMINE IF INPUT IS FULL PATH
        If ($PathInput) {
            $FullPath.Input = @{}
            $FullPath.Input.Path = $PathInput | Split-Path
            $FullPath.Input.Name = ($PathInput | Split-Path -Leaf).Split(".")[0]
            $FullPath.Input.Extension = ($PathInput | Split-Path -Leaf).ToLower().Split(".")[1]
        } Else {
            $FullPath.Input = $FullPath.Defaults
        }

        #SET OUTPUT
        $FullPath.Output = @{}
        ForEach ($PathPart in $FullPath.Input.Keys) {
            $FullPath.Output.$PathPart = If ($FullPath.Input.$PathPart) {
                $FullPath.Input.$PathPart
            } Else {
                $FullPath.Defaults.$PathPart
            }
        }
        $FullPath.OutPut.FullPath = "$($FullPath.OutPut.Path)\$($FullPath.OutPut.Name).$($FullPath.OutPut.Extension)"
    }
    Function Update-FullPath {
        Write-Host "Current Path: $($FullPath.Output.FullPath) " -ForegroundColor Yellow
        Write-Host "New Path [Blank for Current]" -ForegroundColor Green
        If ($_ = Read-Host) {
            $PathInput = $_
        }
        Resolve-FullPath
        Write-Host "New Path: $($FullPath.Output.FullPath)" -ForegroundColor Yellow
    }

    Resolve-FullPath

    If ($Update) {
        Update-FullPath
    }
    Return $FullPath.Output
}
Function Format-FileSize() {
    Param ([int64]$size)
    If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
    Else                   {""}
}