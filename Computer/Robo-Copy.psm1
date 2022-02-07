Function Robo-Copy {
<#
.Synopsis
    Uses robocopy to keep multiple locations in sync.
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
        $Items,
        $Log
    )
    #Set Defaults for RoboCopy
    $Copy = @{}
    $Copy.Items = @{}
    $Copy.Items.Table = @(
        'Source|Destination|Exceptions|CopySec'
    )
    $Copy.Log =@{}
    $Copy.Log.Name = "Robo-Copy-$(Get-Date -Format "yyyy-mm-dd--HH:mm").log"
    $Copy.Log = Define-FullPath $Copy.Log.Name

    $Copy.Items.Source = "Copy-Items.csv"

    If ($Items) {
        $Copy.Items.Table = $Items
    }
    #Import or enter items for sync.
    $Copy.Items.Data = Get-DsvData $Copy.Items.Table $Copy.Items.Source

    ForEach ($CopyItem in $Copy.Items.Data.All) {
        $CopyItem | Add-Member -MemberType NoteProperty -Name IsRoot -Value $null -Force
        $CopyItem | Add-Member -MemberType NoteProperty -Name Command -Value $null -Force
        $CopyItem | Add-Member -MemberType NoteProperty -Name Arguments -Value $null -Force
        $CopyItem | Add-Member -MemberType NoteProperty -Name ExcludeItems -Value $null -Force
        $CopyItem | Add-Member -MemberType NoteProperty -Name ExcludeDirectories -Value $null -Force
        $CopyItem | Add-Member -MemberType NoteProperty -Name ExcludeFiles -Value $null -Force
        
        $CopyItem.ExcludeItems = Get-ChildItem $CopyItem.Source -Recurse -Force | Where-Object {$_.Name -in $CopyItem.Exclusions}
        $CopyItem.ExcludeDirectories = $CopyItem.ExcludeItems | Where-Object {$_.PSIsContainer -eq $True} #| ForEach-Object {' "'+$($_.FullName)+'"'}) -Join " "
        $CopyItem.ExcludeFiles = $CopyItem.ExcludeItems | Where-Object {$_.PSIsContainer -eq $False} #| ForEach-Object {'"'+$($_.FullName)+'"'})
    }
    #Confirm
    Write-Host "Items to Sync" -ForegroundColor Yellow
    $Copy.Items.Data.All | Select-Object Source,Destination,CopySec,ExcludeDirectories,ExcludeFiles | Format-Table

    Select-Options -Timeout 10 -Continue "C" -Default Continue

    #Initiate
    ForEach ($CopyItem in $Copy.Items.Data.All) {
        $CopyItem.Command = 'robocopy """$($CopyItem.Source) """ """$($CopyItem.Destination) """ /mir /zb /XD $CopyItem.ExcludeDirectories /XF $($CopyItem.ExcludeFiles)'

        #Copy Security
        If ($CopyItem.CopySec -eq $True) {
            $CopyItem.Command += ' /CopyAll'
        }
        
        #Logging
        If ($Copy.Log) {
            $CopyItem.Command += ' /tee /log+:$($Copy.Log.FullPath)'
        }
        
        Invoke-Expression $CopyItem.Command

    }
}
