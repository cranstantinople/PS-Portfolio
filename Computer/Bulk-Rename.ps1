Function Bulk-Rename {
    
    param (
        $Path,
        $Match,
        $
        [switch]$Directory
    )

    $Rename = @{}
    $Rename.Import = @{}
    $Rename.Import.Command = "Get-ChildItem -Path $Rename.Import.Path"

    ForEach ($Object in $Objects) {
        
        $Object | Add-Member -MemberType NoteProperty -Name NewName -Value $null -Force
    
        $Object.NewName = $Object.Name.Insert(4,"-").Insert(7,"-")
        Rename-Item -Path $Object.FullName -NewName $Object.NewName
    }

}

