Import-Module "$($env:USERPROFILE)\Sammy's, Inc\Sammy's Admin - Files\SysAdmin\PSRepo\PS-Common.psm1" -Force -DisableNameChecking

$PreCheck = @{}
$PreCheck.Required = @(
        'O365-SharePoint',
        'Posh-SSH'
)

Start-PreCheck $PreCheck

$Backup = @{}
$Backup.Location = "\\SINC\SysAdmin\Configs"
$Backup.Key = "\\SINC\SysAdmin\Configs\backup@sammysinc.com.pub.txt"
$Backup.Key = "C:\Users\clayt\backup@sammysinc.com.ppk"
$Backup.Devices = @{}
$Backup.Devices.Data = @{}

$Backup.Devices.Data.Path = "https://sammysinc.sharepoint.com/sites/SammysAdmin/SysAdmin"
$Backup.Devices.Data.Name = "Network Hosts"

$Backup.Devices.Data.Properties = @(                       
        'Name           |Maps           |Import*|Display*|Prompt*|Update* ',
        'HostName       |Title;Name     |True   |True   |       |       ',
        'IPAddress      |               |True   |True   |       |       ',
        'Role           |               |True   |True   |True   |True   ',
        'Brand          |               |True   |True   |       |       ',
        'Model          |               |True   |True   |       |       ',
        'Serial         |               |True   |True   |True   |True   ',
        'OS             |               |True   |True   |True   |True   ',
        'OSVersion      |               |True   |True   |True   |True   ',
        'BackupUser     |               |True   |True   |       |       ',
        'LastBackup     |               |True   |True   |       |True   ',
        'ID             |               |True   |       |       |       '
)

$Backup.Devices.Data.Properties = Get-DsvData $Backup.Devices.Data.Properties

$Backup.Devices.All = (Get-SPOLists -Site $Backup.Devices.Data.Path -Lists (Convert-HashObject $Backup.Devices.Data)).All

$Backup.Devices.Roles = @{}
$Backup.Devices.Roles.Routers = @{}
$Backup.Devices.Roles.Switches = @{}

$Backup.Devices.Roles.Routers.Cisco = @{}
$Backup.Devices.Roles.Routers.Cisco.Command = {
        terminal length 0
        show running-config
}

$Backup.Devices.Routers.All = $Backup.Devices.All | Where-Object {$_.Role -Match "Router"}

ForEach ($Device in $Backup.Devices.Routers.All) {

        $Device | Add-Member -MemberType NoteProperty -Name Credentials -Value $Null -Force
        $Device | Add-Member -MemberType NoteProperty -Name Session -Value $Null -Force
        $Device | Add-Member -MemberType NoteProperty -Name Stream -Value $Null -Force
        $Device | Add-Member -MemberType NoteProperty -Name Backups -Value $Null -Force
        $Device | Add-Member -MemberType NoteProperty -Name Config -Value $Null -Force
        $Device | Add-Member -MemberType NoteProperty -Name BackupDate -Value $Null -Force    
        $Device | Add-Member -MemberType NoteProperty -Name BackupName -Value $Null -Force

        $Device.BackupDate = (Get-Date -Format "yyyy-MM-dd--H-mm-ss")
        $Device.BackupName = "$($Device.HostName)--$($Device.BackupDate)"
        $Device.BackupUser = "backup@sammysinc.com"
        $Device.Credentials = New-Object System.Management.Automation.PSCredential($Device.BackupUser,(New-Object System.Security.SecureString))

        scp -i $Backup.Key "$($Device.BackupUser)@$($Device.IPAddress):running-config" "$($Backup.Location)$($Device.BackupName)"

        #Get-SCPItem $Device.IPAddress -Credential $Device.Credentials -KeyFile $Backup.Key -AcceptKey -Path "running-config" -PathType File -Destination $Backup.Location -NewName $Device.BackupName

        $Device.Session = New-SSHSession $Device.IPAddress -Credential $Device.Credentials -KeyFile $Backup.Key -AcceptKey
        $Device.Stream = New-SSHShellStream -Session $Device.Session

        $Device.Stream.Write($Backup.Devices.Routers.Cisco.Command)
        Start-Sleep 5
        $Device.Config = $Device.Stream.Read()

        New-Item -Path $Backup.Location -Name $Device.BackupName -Value $Device.Config

}


#Default Retention Policy in Days
$Backup.Retention = [Ordered]@{}
$Backup.Retention.Hourly = 3
$Backup.Retention.Daily = 10
$Backup.Retention.Weekly = 60
$Backup.Retention.Monthly = 365
$Backup.Retention.Yearly = (10*365)


$Volume.Retention.Hourly.Policy = {$_.SnapShotDays -lt $Volume.Retention.Hourly.Days}
$Volume.Retention.Hourly.Grouping = $Null
$Volume.Retention.Daily.Policy = {($_.SnapShotDays -ge $Volume.Retention.Hourly.Days) -and ($_.SnapShotDays -lt $Volume.Retention.Daily.Days)}
$Volume.Retention.Daily.Grouping = "SnapShotDate"
$Volume.Retention.Weekly.Policy = {($_.SnapShotDays -ge $Volume.Retention.Daily.Days) -and ($_.SnapShotDays -lt $Volume.Retention.Weekly.Days)}
$Volume.Retention.Weekly.Grouping = "SnapShotWeek"
$Volume.Retention.Monthly.Policy = {($_.SnapShotDays -ge $Volume.Retention.Daily.Days) -and ($_.SnapShotDays -lt $Volume.Retention.Monthly.Days)}
$Volume.Retention.Monthly.Grouping = "SnapShotMonth"
$Volume.Retention.Yearly.Policy = {($_.SnapShotDays -ge $Volume.Retention.Monthly.Days) -and ($_.SnapShotDays -lt $Volume.Retention.Yearly.Days)}
$Volume.Retention.Yearly.Grouping = "SnapShotYear"