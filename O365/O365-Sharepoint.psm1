$PreCheck = @{}
$PreCheck.Required = @(
    'O365-Common'
)
Start-PreCheck $PreCheck
Function Explore-SPOSite {

    O365-Services -Sharepoint

    $O365.Service.SharePoint.Sites.All = Get-SPOSite
    $O365.Service.SharePoint.Sites.Teams = $O365.Service.SharePoint.Sites.All | Where-Object {$_.IsTeamsConnected -eq $true}
}

Function Get-SPOLists {

    param (
		$Site,
        $Lists
    )

    $SharePoint = @{}
    $SharePoint.Site = $Site

    Connect-PnPOnline -Url $SharePoint.Site -UseWebLogin

    If ($Lists) {
        $SharePoint.Lists = $Lists
    } Else {
        $SharePoint.Lists = Get-PnPList | Where-Object {$_.Hidden -eq $False -and $_.IsApplicationList -eq $False}
    }

    ForEach ($List in $SharePoint.Lists) {

        If (-not $List.Name) {
            $List | Add-Member -MemberType NoteProperty -Name Name -Value $List.Title -Force
        }

        Write-Host "Getting List $($List.Name)"

        $List | Add-Member -MemberType NoteProperty -Name Import -Value $Null -Force
        $List | Add-Member -MemberType NoteProperty -Name All -Value $Null -Force

        $List.Import = (Get-PnPListItem $List.Name).FieldValues
        $List.All = Convert-HashObject $List.Import -Properties $List.Properties.All
    
        #Get LookUp Field Values
        Write-Host "Getting Lookup Values for Items in $($List.Name)"
        ForEach ($Object in $List.All){
            ForEach ($Property in $Object.PSObject.Properties) {
                If ($Property.TypeNameOfValue -eq "Microsoft.SharePoint.Client.FieldLookupValue") {
                        $Object.($Property.Name) = $Object.($Property.Name).LookUpValue
                }
            }
        }
    }
    Return $SharePoint.Lists
}