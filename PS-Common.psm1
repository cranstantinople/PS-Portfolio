<#
.Synopsis
   Common shared functions for other modules
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
Function Start-PreCheck {
<#
.Synopsis
   Pre Checks Functions for Required Modules/Features/Scripts
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
    $PreCheck.Variables = @{}

    $PreCheck.Scripts.Locations = @{}
    $PreCheck.Scripts.Locations.All = @(
        "$($env:USERPROFILE)\Sammy's, Inc\Sammy's Admin - Files\SysAdmin\PSRepo\",
        "\\SINC\IT\PSRepo\"
    )

    $PreCheck.Force = $Force
    $PreCheck.Input = $PreCheckInput
    $PreCheck.Date = (Get-Date).Date    

    #Last check
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
    $PreCheck.Variables.Required = @()
    ForEach ($Required in $PreCheck.Input.Required) {
        $NewObject = New-Object PSCustomObject
        $NewObject | Add-Member NoteProperty -Name Name -Value $null
        $NewObject | Add-Member NoteProperty -Name Type -Value $null
        $NewObject | Add-Member NoteProperty -Name Location -Value $null
        $NewObject | Add-Member NoteProperty -Name Command -Value $null
        $NewObject | Add-Member NoteProperty -Name Match -Value $null
        If ($Required.Name) {
            $NewObject.Name = $Required.Name
        } Else {
            $NewObject.Name = $Required.Split(";")[0]
            $NewObject.Command = $Required.Split(";")[1]
        }
        $PreCheck.Required += $NewObject
    }
    #Determine Type
    ForEach ($Required in $PreCheck.Required) {
        #Check if Variable
        If ($Required.Name -match '\$') {
            $Required.Type = "Variable"
            $PreCheck.Variables.Required += $Required
        } Else {
            #Check if Script
            $Required.Match = $PreCheck.Scripts.Locations.Items | Where-Object {$_.Name -Match $Required.Name} | Select-Object -First 1
            If ($Required.Match) {
                $Required.Type = "Script"
                $Required.Location = $Required.Match.PSPath
                $PreCheck.Scripts.Required += $Required
            } Else {
                #Check if Module
                $Required.Match = Find-Module -Name $Required.Name
                If ($Required.Match) {
                    $Required.Type = "Module"
                    $Required.Location = $Required.Match.Repository
                    $PreCheck.Modules.Required += $Required
                } Else {
                #Check if Feature
                $Required.Match = Get-WindowsOptionalFeature -Online -FeatureName $Required.Name
                If ($Required.Match) {
                    $Required.Type = "Feature"
                    $PreCheck.Features.Required += $Required
                } Else {
                        $Required.Type = "Not Found"
                        $PreCheck.NotFound += $Required
                    }
                }
            }
        }
    }
    
    Function Verify-Module {
        #Check if module loaded.
        Write-Host "Checking for $($Module.Name) Module" -ForegroundColor Yellow
        $Module.Current = Get-Module $Module.Name
        If ($Module.Current -like $null) {
            Write-Host "$($Module.Name) Module Not Loaded." -ForegroundColor Red
            $Module.Status = "NotLoaded"
            Write-Host "Checking if Missing Modules Installed" -ForegroundColor Yellow
            If (!$PreCheck.Modules.Installed) {
                $PreCheck.Modules.Installed = Get-Module -ListAvailable
            }
            #Check if Module Installed
            If ($Module.Name -in $PreCheck.Modules.Installed.Name) {
            Write-Host "$($Module.Name) Module Installed... Importing" -ForegroundColor Yellow
            Import-Module $Module.Name -DisableNameChecking
            $Module.Current = Get-Module $Module.Name
            $Module.Status = "Loaded"
            } Else {
                Write-Host "$($Module.Name) Module Not Installed" -ForegroundColor Red
                $Module.Status = "NotInstalled"
                Install-Module $Module.Name -Force
                Write-Host "$($Module.Name) Module Installed... Importing" -ForegroundColor Yellow
                Import-Module $Module.Name -DisableNameChecking
                $Module.Status = "Loaded"
                $Module.Current = Get-Module $Module.Name
            }
            #Check if Module up-to-date.
            If ($Module.Current.Version -ne $Module.Repo.Version) {
                Write-Host "$($Module.Name) Out of Date" -ForegroundColor Yellow
                $Module.Status = "OutOfDate"
                
                If ((Select-Options -Timeout 10 -Options "[U]pdate(Yellow)" -Continue "C" -Default Continue).Name -eq "Update") {
                    Write-Host "$($Module.Name) Removing Module" -ForegroundColor Yellow
                    Remove-Module $Module.Name -Force
                    Uninstall-Module $Module.Name -AllVersions -Force
                    Write-Host "$($Module.Name) Updating Module from Repository" -ForegroundColor Yellow
                    Install-Module $Module.Name -Force
                    Write-Host "$($Module.Name) Module Updated... Importing" -ForegroundColor Yellow
                    Import-Module $Module.Name -DisableNameChecking
                    $Module.Status = "Loaded"
                    Verify-Module
                }
            }
        } Else {
            $Module.Status = "Loaded"
        }
        $Module.Current = Get-Module $Module.Name
        Write-Host "$($Module.Name) Version $($Module.Current.Version) Loaded." -ForegroundColor Green
    }

    #Verify Scripts
    ForEach ($Script in $PreCheck.Scripts.Required) {
        Write-Host "Importing Required Script: $($Script.Name)" -ForegroundColor Yellow
        Write-Host $Script.Match.FullName
        Import-Module $Script.Match.FullName -Force -Global -DisableNameChecking
    }
    #Verify Features
    ForEach ($Feature in $PreCheck.Feature.Required) {
        If ($Feature.State -ne "Enabled") {
            Write-Host "Installing Required Feature: $($Feature.Name)" -ForegroundColor Yellow
            Start-Process PowerShell -verb runas -argument "Enable-WindowsOptionalFeature -Online -FeatureName $($Feature.Name)"
        }
    }
    #Verify Modules
    $PreCheck.Modules.Repo = Get-PSRepository
    ForEach ($Module in $PreCheck.Modules.Required) {
        $Module | Add-Member NoteProperty -Name Current -Value $null
        $Module | Add-Member NoteProperty -Name Repo -Value $null
        $Module | Add-Member NoteProperty -Name Status -Value $null
        $Module.Repo = $Module.Match
        Verify-Module
    }
    #Verify Variables
    ForEach ($Variable in $PreCheck.Variables.Required) {
        If (Invoke-Expression $Variable.Name) {
            Write-Host "$($Required.Name) Exists" -ForegroundColor Green
        } Else {
            Write-Host "$($Variable.Name) Does Not Exist" -ForegroundColor Yellow
            Invoke-Expression $Variable.Command
        }
    }

    If ($Results) {
        Return $PreCheck
    }
}
Function Get-ParsedData {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object] 
        $Data
    )

    #Get Sections
    Function Get-Section {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [object] 
            $Data,
            $Depth
        )

        $Object = [Ordered]@{}
        $Object.Data = @{}
        $Object.Data.Input = $Data
        $Object.Data.Depth = $Depth
        $Object.Data.Sections = ($Object.Data.Input | Select-String "(?smi)\<(?<Name>.+)\>(?<Value>.+?)\</\k<Name>\>" -AllMatches).Matches

        ForEach ($Section in $Object.Data.Sections) {
            $Section | Add-Member NoteProperty Name $null -Force
            $Section | Add-Member NoteProperty Value $null -Force
            $Section.Name = ($Section.Groups | Where-Object {$_.Name -eq "Name"}).Value
            $Section.Value = ($Section.Groups | Where-Object {$_.Name -eq "Value"}).Value
        }
        $Object.Data.Sections = $Object.Data.Sections | Select-Object Name,Value,Groups | Group-Object Name

        ForEach ($Section in $Object.Data.Sections) { 
            $Object.($Section.Name) = @{}
            $Object.($Section.Name).Data  = @{}
            $Object.($Section.Name).Data.Input = ($Section.Group.Groups | Where-Object {$_.Name -eq "Value"}).Value
            $Object.($Section.Name) = Get-Section $Object.($Section.Name).Data.Input -Depth ($Object.Data.Depth+1)
            $Object.($Section.Name).Data.Name = $Section.Name
        } 
        Return $Object
    }
    $Object = Get-Section $Data
    #Get Section Data
    Function Get-SectionData {
        
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [object] 
            $Section
        )
        
        Write-Host "$("`t"*$Section.Data.Depth)$($Section.Data.Name)"
        $Section.Data.Fields = $Section.Data.Input
        ForEach ($SubSection in $Section.Data.Sections) { 
            #Get Fields
            $Section.Data.Fields = $Section.Data.Fields -Replace "(?smi)\<$($SubSection.Name)\>.+\</$($SubSection.Name)\>",""
        }
        Function Get-FieldData {

            [CmdletBinding()]
            Param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [object] 
                $FieldInput
            )

            $Fields = @{}
            $Fields.Input = $FieldInput
                            
            $Fields.Fields = ($Fields.Input | Select-String '\<(?<Name>.+)\>(?<Value>.*)' -AllMatches).Matches

            ForEach ($Field in $Fields.Fields) {
                $Field | Add-Member NoteProperty Name $null -Force
                $Field | Add-Member NoteProperty Value $null -Force
                $Field.Name = ($Field.Groups | Where-Object {$_.Name -eq "Name"}).Value
                $Field.Value = ($Field.Groups | Where-Object {$_.Name -eq "Value"}).Value
            }
            $Fields.Result = $Fields.Fields | Select-Object Name,Value
            Return $Fields.Result
        }
        $Section.Data.Fields = Get-FieldData $Section.Data.Fields
        
        ForEach ($Field in $Section.Data.Fields) {
            $Section.($Field.Name) = $Field.Value
            Write-Host "$("`t"*($Section.Data.Depth+1))$($Field.Name):$($Field.Value)"
        }

        If ($Section.Data.Objects) {
            ForEach ($Object in $Section.Data.Objects) {
                $Object | Add-Member NoteProperty Object $null -Force
                $Object.Object = New-Object -TypeName PSCustomObject
                ForEach ($Field in Get-FieldData $Object.Value) {
                    $Object.Object | Add-Member NoteProperty $Field.Name $Field.Value -Force
                }
            }
        }

        If ($Section.Data.Sections) {
            ForEach ($SubSection in $Section.Data.Sections) {
                If ($SubSection.Count -gt 1) {
                    $Section.($SubSection.Name).Data.Objects = $SubSection.Group
                }
                Get-SectionData $Section.($SubSection.Name)
                If ($Section.($SubSection.Name).Data.Objects) {
                    $Section.($SubSection.Name) = $Section.($SubSection.Name).Data.Objects.Object
                }
            }
        }
    }
    Get-SectionData $Object

    Get-ParsedResult $Object

    Return $Object
}
Function Get-ParsedResult {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object] 
        $Object
    )

    $Object.Remove("Result")
    $Object.Remove("Output")
    $Object.Data.Depth = 0
    $Object.Output = @()
    Function Get-SectionResult {

        [CmdletBinding()]
        Param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [object] 
            $Section,
            $Depth
        )

        $Section.Data.Result = [Ordered]@{}
        $Section.Data.Depth = $Depth

        ForEach ($Key in $Section.Keys | Where-Object {$_ -notin @("Data","Output")}) {
            If ($Section.$($Key).GetType().Name -match "String") {
                $Section.Data.Result.($Key) = $Section.($Key)
                $Object.Output += "$("`t"*($Section.Data.Depth))<$($Key)>$($Section.($Key))"
            }
        }
        
        ForEach ($Key in $Section.Keys | Where-Object {$_ -notin @("Data","Output")} ) {
            If ($Section.$($Key).GetType().BaseType.Name -in @("Array")) {
                $Section.Data.Result.$($Key) = $Section.$($Key)
                ForEach ($SectionObject in $Section.$($Key)) {
                    $Object.Output += "$("`t"*($Section.Data.Depth))<$($Key)>"
                    ForEach ($Property in ($SectionObject | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).Name) {
                        $Object.Output += "$("`t"*($Section.Data.Depth+1))<$($Property)>$($SectionObject.$Property)"  
                    }
                    $Object.Output += "$("`t"*($Section.Data.Depth))</$($Key)>"
                }
            }

            If ($Section.$($Key).GetType().Name -in @("Hashtable","OrderedDictionary")) {
                $Object.Output += "$("`t"*($Section.Data.Depth))<$($Key)>"
                $Section.Data.Result.($Key) = Get-SectionResult $Section.($Key) -Depth ($Section.Data.Depth+1)
                $Object.Output += "$("`t"*($Section.Data.Depth))</$($Key)>"
            }
        }
        Return $Section.Data.Result
    }
    $Object.Result = Get-SectionResult $Object
    $Object.Output = $Object.Output -Join "`n"
}
Function Convert-ParsedString {
    param (
        $StringInput,
        $Tags,
        $Delimiters
    )

    $Parse = @{}
    $Parse.Tags = @{}
    $Parse.Delimiters = @{}

    $Parse.Input = $StringInput

    $Parse.Tags.Input = $Tags
    $Parse.Tags.Match = ($Tags | Select-String '#([a-z]+|\[.*\][a-z])+' -AllMatches).Matches

    $Parse.Tags.All = ForEach ($Tag in $Parse.Tags.Match) {
        $NewObject = New-Object PSCustomObject
        $NewObject | Add-Member NoteProperty -Name Name -Value $null
        $NewObject | Add-Member NoteProperty -Name Value -Value $null
        $NewObject | Add-Member NoteProperty -Name RegEx -Value $null
        $NewObject | Add-Member NoteProperty -Name Open -Value $null
        $NewObject | Add-Member NoteProperty -Name Close -Value $null
        $NewObject | Add-Member NoteProperty -Name Variables -Value $null

        $NewObject.Name = $Tag.Value.Replace("#","") -Replace "\[.*\]",""
        $NewObject.Value = $Tag.Value
        $NewObject.RegEx = [regex]::Escape($Tag.Value)
        $NewObject.Open = "(.)$($NewObject.RegEx)"
        $NewObject.Open = ($Parse.Tags.Input | Select-String $NewObject.Open).Matches -Replace $NewObject.RegEx,"" | Select-Object
        
        $NewObject.Close = "$($NewObject.RegEx)(.)"
        $NewObject.Close = ($Parse.Tags.Input | Select-String $NewObject.Close).Matches -Replace $NewObject.RegEx,"" | Select-Object
        $NewObject.Variables = ($NewObject.Value | Select-String '\[[a-z]*\]').Matches.Value -Replace "\[|\]",""
        $NewObject
    }

    $Parse.Result = $Parse.Input -Split "," | ForEach-Object {
        $NewObject = New-Object PSCustomObject
        $NewObject | Add-Member NoteProperty -Name Input -Value $null
        $NewObject | Add-Member NoteProperty -Name RegEx -Value $null
        $NewObject.Input = $_

        ForEach ($Tag in $Parse.Tags.All) {
            $NewObject | Add-Member NoteProperty -Name $Tag.Name -Value $null
            $NewObject.RegEx = "\$($Tag.Open).*\$($Tag.Close)"
            $NewObject.$($Tag.Name) = ($NewObject.Input | Select-String $NewObject.RegEx).Matches -Replace "\$($Tag.Open)|\$($Tag.Close)","" | Select-Object
            If ($Tag.Variables) {
                Write-Host "$($Tag.Name) is Using $($Tag.Variables)"
                $NewObject.$($Tag.Name) = ".*\$($Tag.Close)"
                $NewObject.$($Tag.Name) = ($NewObject.Input | Select-String $NewObject.$($Tag.Name)).Matches -Replace "\$($Tag.Open)|\$($Tag.Close)","" | Select-Object
                $NewObject.$($Tag.Name) = $NewObject.$($Tag.Name).Replace("[","")
            }
        }
        $NewObject
    }
    Return $Parse.Result | Select-Object $Parse.Tags.All.Name
}
Function Select-Options {
<#
.Synopsis
   Takes in input to display menu options and returns selection
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
    param (
        $Options,
        $Prompt,
        $Timeout,
        $Property,
        [ArgumentCompleter({@('AnyKey',[char[]](65..90))})]
        $Continue,
        [ArgumentCompleter({@('AnyKey',[char[]](65..90))})]
        $Back,
        [ArgumentCompleter({@('AnyKey',[char[]](65..90))})]
        $Exit,
        [ArgumentCompleter({@('Continue',[char[]](65..90))})]
        $Default
    )
    
    #Set defaults
    $Select = @{}

    $Select.Options = @{}

    $Select.Functions = [Ordered] @{}
    $Select.Functions.Continue = @{}
    $Select.Functions.Continue.Active = $True
    $Select.Functions.Continue.Name = "Continue"
    $Select.Functions.Continue.Option = "C"
    $Select.Functions.Continue.Color = "Green"
    $Select.Functions.Continue.NewLine = $null
    $Select.Functions.Continue.Command = {
        Write-Host "Continuing" -ForegroundColor Green
        Return
    }
    $Select.Functions.Back = @{}
    $Select.Functions.Back.Active = $False
    $Select.Functions.Back.Name = "Back"
    $Select.Functions.Back.Option = "B"
    $Select.Functions.Back.Color = "Yellow"
    $Select.Functions.Back.NewLine = $null
    $Select.Functions.Back.Command = {
    }

    $Select.Functions.Exit = @{}
    $Select.Functions.Exit.Active = $True
    $Select.Functions.Exit.Name = "Exit"
    $Select.Functions.Exit.Option = "AnyKey"
    $Select.Functions.Exit.Color = "Red"
    $Select.Functions.Exit.Command = {
        Write-Host "Exiting" -ForegroundColor Red
        Exit
    }
    $Select.Options.Properties = @(
        "Active",
        "Name",
        "Option",
        "Tip",
        "Color",
        "Return",
        "Command"
    )

    $Select.Options.Default = $Select.Functions.Exit
    
    #Set parameters
    If ($Timeout) {
        $Select.Timeout = $Timeout
    }
    If ($Continue) {
        $Select.Functions.Continue.Active = $True
        $Select.Functions.Continue.Option = $Continue
        If ($Select.Functions.Continue.Option = "AnyKey") {
            $Select.Functions.Exit.Option = "X"
        }
    }
    If ($Exit) {
        $Select.Functions.Exit.Active = $True
        $Select.Functions.Exit.Option = $Exit
    }
    If ($Back) {
        $Select.Functions.Back.Active = $True
        $Select.Functions.Back.Command = $Back.Command
    }

    If ($Options) {
        If ($Options.GetType().Name -eq "String") {
            #Options
            $Select.Options.Options = @()
            ForEach ($Option in $Options -Split ",") {
                $Select.Options.Options = Convert-ParsedString $Option -Tags "[#Option]#[Option]Name(#Color)"
            }
        } Else {
            #Menu
            $Select.Functions.Exit.Option = "X"
            $Select.Functions.Continue.Active = $False
            If ($Options.Options.Values) {
                    $Select.Options = $Options
            } Else {
                $Select.Options.Input = $Options
                $Select.Options.Prompt = $Prompt
                $Select.Options.Options = [Ordered] @{}
                $o = 1
                ForEach ($Option in $Select.Options.Input) {
                    $Select.Options.Options.Add("o$($o)", @{})
                    $Select.Options.Options."o$($o)".Return = $Option
                    If ($Property) {
                        $Select.Options.Options."o$($o)".Name = $Option.$Property
                    } Else {
                        $Select.Options.Options."o$($o)".Name = $Option
                    }
                    $o += 1
                }
            }
            #Definie Options
            $o = 1
            ForEach ($Option in $Select.Options.Options.Values) {
                If (!$Option.Option) {
                    $Option.Option = $o
                }
                $o += 1
            }
            $Select.Options.Menu = $True
            $Select.Options.Options = Convert-HashObject $Select.Options.Options.Values | Select-Object $Select.Options.Properties
        }
    }

    #Get All Options
    $Select.Options.All = @()
    $Select.Options.All += $Select.Options.Options | Select-Object $Select.Options.Properties
    $Select.Options.All += Convert-HashObject $Select.Functions.Values | Select-Object $Select.Options.Properties

    #Determine Defaults
    If ($Default) {
        $Select.Options.Default = $Select.Options.All | Where-Object {$_.Option -eq $Default -or $_.Name -eq $Default}
    }
    $Select.Options.AnyKey = $Select.Options.All | Where-Object {$_.Option -eq "AnyKey" -and $_.Active -eq $True}
    
    Function Select-FromOptions {
        Add-Type -AssemblyName System.Windows.Forms
        #Display Menu
        Write-Host $Select.Options.Prompt -ForegroundColor Green
        If ($Select.Options.Menu) {
            ForEach ($Option in $Select.Options.Options) {
                Write-Host "     [$($Option.Option)] $($Option.Name)" -NoNewline  
                If ($Option.Option -eq $Select.Options.Default.Option) {
                    Write-Host " [DEFAULT]" -ForegroundColor Yellow
                } Else {
                    Write-Host
                }
                If ($Option.Tip) {
                    Write-Host "        --$($Option.Tip)" -ForegroundColor Yellow
                }
            }
            Write-Host "Please Make a Selection:" -ForegroundColor Green
        } Else {
            ForEach ($Option in $Select.Options.Options) {
                Write-Host "[$($Option.Option)] $($Option.Name)" -NoNewline
                If ($Option.Option -eq $Select.Options.Default.Option) {
                    Write-Host " [DEFAULT]" -ForegroundColor Yellow -NoNewline
                }
                Write-Host "   " -NoNewline
            }
        }
        #Display Function Options
        ForEach ($Function in $Select.Functions.Values) {
            If ($Function.Active) {
                Write-Host "[$($Function.Option)] $($Function.Name)" -ForegroundColor $Function.Color -NoNewline
                If ($Function.Option -eq $Select.Options.Default.Option) {
                    Write-Host " (default)" -NoNewLine -ForegroundColor $Function.Color 
                }
                If ($Function.NewLine -eq $False) {
                    Write-Host "    " -NoNewline
                } Else {
                    Write-Host 
                }
            }
        }
        $Select.Selection = $null
        #Display countdown until input or timeout
        If ($Select.Timeout) {
            $Select.Timer = New-Object system.diagnostics.stopwatch
            $Select.Timer | Add-Member NoteProperty -Name TimeRemaining -Value $null -Force
            $Select.Timer | Add-Member NoteProperty -Name PercentRemaining -Value $null -Force
            $Select.Timer.PercentRemaining = 100
            $Select.Timer.TimeRemaining = $Select.Timeout
            $Select.Timer.Start()
            while ((!$Host.UI.RawUI.KeyAvailable) -and ($Select.Timer.PercentRemaining -gt 0)) {
                $Select.Timer.TimeRemaining = $Select.Timeout - $Select.Timer.Elapsed.Seconds
                Write-Progress -Activity "Waiting for Input" -SecondsRemaining ($Select.Timer.TimeRemaining) -PercentComplete ($Select.Timer.PercentRemaining)
                Start-Sleep -Milliseconds 100
                $Select.Timer.PercentRemaining = 100-100*($Select.Timer.Elapsed.TotalMilliseconds/($Select.Timeout*1000))
            }

            #Process defaults if timeout
            Write-Progress -Activity "Waiting for Input" -Completed
            If (!$Host.UI.RawUI.KeyAvailable) {
                #Continue if Default
                $Select.Selection = $Select.Options.Default
                Write-Host "No Selection Made. Using Default" -ForegroundColor Yellow
            }
        }   
        #Read Selection
        If (!$Select.Selection) {
            $Select.Input = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
            If ($Select.Input -in $Select.Options.All.Option) {
                $Select.Selection = $Select.Options.All | Where-Object {$_.Option -eq $Select.Input}
            } ElseIf ($Select.Options.AnyKey){
                $Select.Selection = $Select.Options.AnyKey
            }
        }
        If (!$Select.Selection) {
            [System.Windows.Forms.SendKeys]::SendWait($Select.Input)
            $Select.Input = (Read-Host) -split ","
            #Verify Selection
            If ((Compare-Object $Select.Input $Select.Options.All.Option).SideIndicator -notcontains "<=") {
                $Select.Selection = $Select.Options.All | Where-Object {$_.Option -in $Select.Input}
            } Else {
                Write-Host "Invalid Selection. Please Make a Valid Selection" -ForegroundColor Red
                Set-Console -Top -Space 10
                Select-FromOptions
            }
        }
        #Execute Function
        If ($Select.Selection.Name -in $Select.Functions.Values.Name) {
            Invoke-Command $Select.Selection.Command
        }
    }
    Select-FromOptions
    #Return Selection
    If ($Select.Selection.Name -notin $Select.Functions.Values.Name) {
        If ($Select.Selection.Return) {
                return $Select.Selection.Return
        } Else {
                return $Select.Selection
        }  
    }
}
Function App-Flow {
<#
.Synopsis
   Creates Application Flow and Returns Values
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
<#
.Synopsis
    Converts Object to Hashtable or Hastable to Object
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
        $Convert.Properties.Return = Convert-Dsv $Convert.Properties.Return -Headers "Name"
    }
    #Convert Objects
    Function Convert-ToObject {
        [cmdletbinding()]
        param(
            [parameter(Mandatory= $true, ValueFromPipeline = $true)]
            $Object
        )
        $NewObject = New-Object PSCustomObject
        ForEach ($Property in $Convert.Properties.Return) {
            $NewObject | Add-Member NoteProperty -Name $Property.Name -Value $null
            $NewObject.($Property.Name) = &{
                If ($Property.Maps) {
                        $Object.($Property.Maps | Where-Object {$_ -in $Convert.Properties.All} | Select-Object -First 1)
                } Else {
                        $Object.($Property.Name)
                }
            }
        }
        Return $NewObject
    }

    Function Convert-ToHash {
        [cmdletbinding()]
        param(
            [parameter(Mandatory= $true, ValueFromPipeline = $true)]
            $Object
        )
        $NewObject = @{}
        ForEach ($Property in $Convert.Properties.Return) {
            $NewObject | Add-Member NoteProperty -Name $Property.Name -Value $null
            $NewObject.($Property.Name) = &{
                If ($Property.Maps) {
                        $Object.($Property.Maps | Where-Object {$_ -in $Convert.Properties.All} | Select-Object -First 1)
                } Else {
                        $Object.($Property.Name)
                }
            }
        }
        Return $NewObject
    }

    $Convert.Result = @()
    ForEach ($Object in $Convert.Input.Input) {
        $Convert.Result += $Object | Convert-ToObject
    }
    Return $Convert.Result    
}
Function Export-Report {
<#
.Synopsis
    Provides export options for various types of input.
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
    param (
        [parameter(Mandatory=$true)]
        $ReportInput,
        $Export,
        $Default,
        $Email
        )

    $Report = @{}
    $Report.Report = $ReportInput
    $Report.Export = @{}
    $Report.Export.Path = "C:\TEMP"
    $Report.Export.Name = "Report"
    $Report.Export.Extension = "csv"

    $Report.Export = Get-FullPath $Export $Report.Export
        
    $Report.Menu = @{}
    $Report.Menu.Options = [Ordered]@{}
    $Report.Menu.Prompt = "[V]iew or [E]xport?"
    $Report.Menu.Options.o1 = @{}
    $Report.Menu.Options.o1.Name = "View"
    $Report.Menu.Options.o1.Option = "V"
    $Report.Menu.Options.o1.Command = {
        $Report.Report | Out-GridView
    }
    $Report.Menu.Options.o2 = @{}
    $Report.Menu.Options.o2.Name = "Export"
    $Report.Menu.Options.o2.Option = "E"
    $Report.Menu.Options.o2.Command = {
        $Report.Export = Get-FullPath $Export $Report.Export -Update
        $Report.Report | Export-Csv $Report.Export.FullPath -NoTypeInformation
        Start-Process $Report.Export.FullPath
    }
    $Report.Menu.Options.o3 = @{}
    $Report.Menu.Options.o3.Name = "Email"
    $Report.Menu.Options.o3.Option = "M"
    $Report.Menu.Options.o3.Command = {
        $Report.Export
    }
    $Report.Menu.Selection = Select-Options $Report.Menu -Default "V"
    Invoke-Command $Report.Menu.Selection.Command
    
    Export-Report $ReportInput $Export
}
Function Out-Multi {
<#
.Synopsis
   Allows for multiple outputs with various options from a single input similar to "Tee-Object"
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
<#
.Synopsis
    Outputs tables from delaminated input with options for sub-delamination
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
    param (
        [parameter(Mandatory=$true)]
        $DataInput,
        $Headers,
        $Delimiter,
        [Switch]$Details
    )
    
    #Delimiters
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

    #Sort Input
    $Dsv.Input = @{}
    $Dsv.Input.Data = $DataInput
    If ($Headers) {
        $Dsv.Input.Headers = $Headers
    } Else {
        $Dsv.Input.Headers = $Dsv.Input.Data | Select-Object -First 1
        $Dsv.Input.Data = $Dsv.Input.Data | Select-Object -Skip 1
    }
    $Dsv.Input.Headers = ($Dsv.Input.Headers -Split $Dsv.Delimiters.d1.Regex).Trim($Dsv.Trim)

    #Table Layout
    $Dsv.Table = @{}
    $Dsv.Table.Headers = @()
    $Dsv.Table.Result = @{}
    ForEach ($Header in $Dsv.Input.Headers) {
        $NewHeader = New-Object PSCustomObject
        $NewHeader | Add-Member NoteProperty -Name Name -Value $null -Force
        $NewHeader | Add-Member NoteProperty -Name Sort -Value $null -Force
        
        $NewHeader.Name = $Header.Replace("*","")
        If ($Header -match "\*") {
            $NewHeader.Sort = $true
            $Dsv.Table.Result.($NewHeader.Name) = @()
        }
        $Dsv.Table.Headers += $NewHeader 
    }
    #Results
    $Dsv.Table.Result.All = @()
    ForEach ($Entry in $Dsv.Input.Data) {
        If ($Entry.Replace($Dsv.Delimiters.d1.Regex,"").Length -gt 0) {
            $NewEntry = New-Object PSCustomObject
            ForEach ($Header in $Dsv.Table.Headers) {
                $NewEntry | Add-Member NoteProperty -Name $Header.Name -Value $null -Force
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
Function Get-DsvData {
<#
.Synopsis
    Workflow to get Delmanated data from
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
    $DsvData = @{}
    $DsvData.Input = @{}
    $DsvData.Import = @{}
    $DsvData.Import.File = @{}

    $DsvData.Input.Delimiter = "|;"

    $DsvData.Import.File.Path = "C:\TEMP"
    $DsvData.Import.File.Name = "Dsv-Import"
    $DsvData.Import.File.Extension = "csv"
    $DsvData.Import.Delimiter = ","
    
    #Set Delimiter if Specified
    If ($Delimiter) {
        $DsvData.Input.Delimiter = $Delimiter
    }

    #Get Default Import Path
    $DsvData.Import.File = Get-FullPath $Path -Defaults $DsvData.Import.File

    Function Import-Data {
        Write-Host "Checking for $($DsvData.Import.File.FullPath)" -ForegroundColor Yellow
        
        $DsvData.Import.File.Exists = Test-Path $DsvData.Import.File.FullPath
        
        #Test if File Exists
        $DsvData.Import.File.Pass = $null
        If ($DsvData.Import.File.Exists -eq $True) {
            Write-Host "$($DsvData.Import.File.FullPath) Exists" -ForegroundColor Green
            $DsvData.Import.Table = Get-Content $DsvData.Import.File.FullPath
            $DsvData.Import.Table = Convert-Dsv $DsvData.Import.Table -Details
            #Test if Headers Match
            If (Compare-Object $DsvData.Input.Table.Headers.Name $DsvData.Import.Table.Headers.Name) {
                Write-Host "$($DsvData.Import.File.FullPath) Headers Do Not Match" -ForegroundColor Red
                $DsvData.Import.File.Pass = $False
            }
            #Test if Contains Data
            If ($DsvData.Import.Table.Result.All.Count -eq 0) {
                Write-Host "$($DsvData.Import.File.FullPath) Does Not Contain Any Data" -ForegroundColor Red
                Write-Host "Please Enter Data in $($DsvData.Import.File.FullPath) and Press any Key to Continue" -ForegroundColor Yellow
                Read-Host
                $DsvData.Import.File.Pass = $False
                Import-Data
            }
        } Else {
            Write-Host "$($DsvData.Import.File.FullPath) Does Not Exist" -ForegroundColor Red
            $DsvData.Import.File.Pass = $False
        }

        If ($DsvData.Import.File.Pass -eq $False -or $Update) {
            Write-Host "Would you like to [E]xport File to Enter Data or [U]pdate Path to an Existing File" -ForegroundColor Green
            Switch -Wildcard (Read-Host "[E]xport / [U]pdate") {
                E* {
                    Write-Host "Exporting $($DsvData.Import.File.FullPath)" -ForegroundColor Yellow
                    "" | Select-Object $DsvData.Input.Table.Headers.Name | Export-Csv -Path $DsvData.Import.File.FullPath -NoTypeInformation
                }
                U* {
                    $DsvData.Import.File = Get-FullPath $Path $DsvData.Import.File -Update
                }
            }
            Import-Data
        }
        Write-Host "Importing Data..." -ForegroundColor Green
        $DsvData.Result = $DsvData.Import.Table.Result.All
        $DsvData.Result | Out-Host
    }
    Function Enter-Data {
        $DsvData.Result = @()
        do {
            $NewObject = New-Object PSCustomObject
            ForEach ($Header in $DsvData.Input.Table.Headers) {
                $NewObject | Add-Member NoteProperty -Name $Header -Value $null
                $NewObject.$Header = Read-Host "$($Header)"
            }
            $DsvData.Result += $NewObject
            $DsvData.Result | Format-Table
            Write-Host 'Press Enter to Add Another or [F] to Finish' -ForegroundColor Green
            $Action = Read-Host
        } until ($Action -match "F.*")
    }

    #Resolve Input Data
    $DsvData.Input.Table = Convert-Dsv $DataInput -Delimiter $DsvData.Input.Delimiter -Details
    
    #If Input Full Table Return
    If ($DsvData.Input.Table.Result.All) {
        $DsvData.Result = $DsvData.Input.Table.Result
    }

    #Get Data If No Result or Update Switch is Selected
    If (-not $DsvData.Result -or $Update) {
        $DsvData.Result | Format-Table
        Write-Host "Would you like to [I]mport from File or [E]nter Data" -ForegroundColor Green
        Switch -Wildcard (Read-Host "[I]mport / [E]nter") {
            Default {
                Import-Data
            }
            E* {
                If ($DsvData.Result) {
                    $DsvData.Result
                    Write-Host "Data Already Exists" -ForegroundColor Yellow
                    Write-Host "Would you like to [A]dd to Existing Data or [C]lear and Enter New" -ForegroundColor Green
                    Switch -Wildcard (Read-Host "[A]dd / [C]lear") {
                        Default {
                        }
                        C* {
                            $DsvData.Result = $null
                        }
                    }
                }
                Enter-Data
            }
        }
    }

    Return $DsvData.Result 
    
    #| Sort-Object | Get-Unique | Select-Object | Where-Object {$_ -notlike $null}
}
Function Get-FullPath {
<#
.Synopsis
    Validates and returns full path from input.
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
<#
.Synopsis
    Formats file size input with various options.
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
    Param (
        [int64]$size
        )
    If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
    Else                   {""}
}
Function Set-Console {
    param (
        [switch]$Top,
        [switch]$Clear,
        $Space,
        $BackgroundColor,
        $ForegroundColor,
        $ErrorForegroundColor,
        $ErrorBackgroundColor,
        $WarningForegroundColor,
        $WarningBackgroundColor,
        $DebugForegroundColor,
        $DebugBackgroundColor,
        $VerboseForegroundColor,
        $VerboseBackgroundColor,
        $ProgressForegroundColor,
        $ProgressBackgroundColor
    )

    $Global:Console = @{}
    If (-Not $Console.Default) {
        $Console.Default = $Host.UI.RawUI
    }

    $Console.Colors = {
        $Host.UI.RawUI.BackgroundColor = $BackgroundColor
        $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    If ($Host.UI.RawUI -ne $Console.Default){
        Invoke-Command $Console.Colors
    }

    If ($Top) {
        [System.Console]::SetWindowPosition(0,[System.Console]::CursorTop)
        If ($Space) {
            Write-Host "$("`n"*$Space)"
        }
    }
}

Function Get-PageNumbers {
    param(
        [parameter(Mandatory=$true)]
        $Page,
        [parameter(Mandatory=$true)]
        $SetCount,
        [parameter(Mandatory=$true)]
        $TotalPages
    )

    $Pages = @{}

    $Pages.Current = $Page
    $Pages.Result = @()

    While ($Pages.Current -lt $TotalPages) {
        $Pages.Result += $Pages.Current
        $Pages.Current += $SetCount
    }
    Return $Pages.Result -join ","
}
