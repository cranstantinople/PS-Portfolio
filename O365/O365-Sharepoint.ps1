$PreCheck = @{}
$PreCheck.Required = @(
    'O365-Common'
)
Pre-Check $PreCheck
$O365.Service.SharePoint.Sites = @{}


Function Explore-SPOSite {

    O365-Services -Sharepoint

    $O365.Service.SharePoint.Sites.All = Get-SPOSite
    $O365.Service.SharePoint.Sites.Teams = $O365.Service.SharePoint.Sites.All | Where-Object {$_.IsTeamsConnected -eq $true}
}

Function Get-SPOList {

    O365-Services -Sharepoint

    $O365.Service.SharePoint.Sites.All = Get-SPOSite
    $O365.Service.SharePoint.Sites.Teams = $O365.Service.SharePoint.Sites.All | Where-Object {$_.IsTeamsConnected -eq $true}
}