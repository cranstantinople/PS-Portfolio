$VisProfiles = @{}
$VisProfiles.All = Import-Csv 'C:\TEMP\_viscosity\VisProfiles.csv'
$VisProfiles.Process = $VisProfiles.All | Where-Object Process -eq TRUE
$Path = 'C:\TEMP\_viscosity\profiles'

$VisProfiles.Process | Add-Member -MemberType NoteProperty "Path" -Value $Null -Force
$VisProfiles.Process | Add-Member -MemberType NoteProperty "Settings" -Value $Null -Force

ForEach ($Profile in $VisProfiles.Process) {
    $Profile.Path = "$($Path)\$($Profile.Domain)"
    $Profile.Settings = "$($Profile.Path)\settings.yml"
    New-Item $Profile.Settings -Force
    Set-Content $Profile.Settings -Value "license_count: $($Profile.LicenseCount)
    mac_license: $($Profile.MacKey)
    windows_license: $($Profile.WindowsKey)"
}