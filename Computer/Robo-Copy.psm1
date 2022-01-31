Function Robo-Copy {
       
    param (
        $Items,
        $Log
    )

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
    
    $Copy.Items.Data = Get-TableData $Copy.Items.Table $Copy.Items.Source

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
