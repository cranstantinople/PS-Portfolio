#FUNCTIONS HASH TABLE
Function Test-Hosts {

    $LogFile = 'C:\TEMP\TestLog.csv'
    $TestHostsCsv = 'C:\TEMP\TestHosts.csv'
    $TestHosts = Import-Csv $TestHostsCsv
    $LogEvent = $True
    $Count = '1'
    $Frequency = '1'

    $TestHosts | Add-Member -MemberType NoteProperty "Result" -Value $Null -Force
    $TestHosts | Add-Member -MemberType NoteProperty "Time" -Value $Null -Force

    While(1){
        ForEach ($TestHost in $TestHosts) {
            $TestHost.Time = (Get-Date)
            $TestHost.Success = (Test-Connection $TestHost.Host -Count $Count -Quiet)
            Write-Host $TestHost
            If ($TestHost.Success -match $TestHost.Log) {
                $TestHost | Export-Csv $LogFile -Append -NoTypeInformation
            }
        }
    Start-Sleep   $Frequency
    }
}
Function Get-ConnectionDetails {

    $Connections = @{}

    $Connections.All = Get-NetTCPConnection
    $Connections.Remote = @{}
    $Connections.Remote.Exclude = @('0.0.0.0','127.0.0.1','10.20.20.20','::')
    $Connections.Remote.All = $Connections.All.RemoteAddress | Sort-Object | Get-Unique | Where-Object {$_ -notin $Connections.Remote.Exclude}
    
    ForEach ($Address in $Connections.Remote.All) {
        $Address = [PSCustomObject]@{
            IPAddress   = $Address
            Request     = Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$Address"
            CountryCode = $Address.Request.countryCode
            Country     = $Address.Request.country
            RegionCode  = $Address.Request.region
            Region      = $Address.Request.regionName
            City        = $Address.Request.city
            Zip         = $Address.Request.zip
            Org         = $Address.Request.org
            ISP         = $Address.Request.isp
            AS          = $Address.Request.as
        }
    }
}