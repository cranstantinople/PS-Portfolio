$LogFile = 'C:\TEMP\TestLog.csv'
$TestHostsCsv = 'C:\TEMP\TestHosts.csv'
$TestHosts = Import-Csv $TestHostsCsv
$LogEvent = $True
$Count = '1'
$Frequency = '1'

$TestHosts | Add-Member -MemberType NoteProperty "Success" -Value $Null -Force
$TestHosts | Add-Member -MemberType NoteProperty "Time" -Value $Null -Force

Function Test-Hosts {
    While(1){
        ForEach ($TestHost in $TestHosts) {
            $TestHost.Time = (Get-Date)
            $TestHost.Success = (Test-Connection $TestHost.Host -Count $Count -Quiet)
            Write-Host $TestHost
            If ($TestHost.Success -match $TestHost.Log) {
                $TestHost | Export-Csv $LogFile -Append -NoTypeInformation
            }
        }
    sleep $Frequency
    }
}

Test-Hosts