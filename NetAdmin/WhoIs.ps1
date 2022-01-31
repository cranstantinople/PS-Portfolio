$DNSServer = "8.8.8.8"		
$APIKey = "at_SDTcwewmObZswgn2bUaybfTMKrVhd"
$DomainsFile = "C:\TEMP\Domains.csv"

$Domains = Import-Csv $DomainsFile
    ForEach ($Domain in $Domains) {
    Write "Getting WhoIs for $($Domain.Name)"
    $Domain | Add-Member -MemberType NoteProperty -Name "WhoIs" -Value $null -Force
    $Domain.WhoIs = (Invoke-WebRequest -Uri "https://www.whoisxmlapi.com/whoisserver/WhoisService?apiKey=$($APIKey)&domainName=$($Domain.Name)&outputFormat=JSON" | ConvertFrom-Json).WhoisRecord
        $Domain | Add-Member -MemberType NoteProperty -Name Registrar -Value ($Domain.WhoIs.registryData.registrarName) -Force
        $Domain | Add-Member -MemberType NoteProperty -Name Registrant -Value ($Domain.WhoIs.registryData.registrant.organization) -Force
        $Domain | Add-Member -MemberType NoteProperty -Name Registration -Value ($Domain.WhoIs.registryData.createdDate) -Force
        $Domain | Add-Member -MemberType NoteProperty -Name Expiration -Value ($Domain.WhoIs.registryData.expiresDate) -Force
        $Domain | Add-Member -MemberType NoteProperty -Name NameServers -Value ($Domain.WhoIs.registryData.nameServers.hostNames -join ",") -Force
        $Domain | Add-Member -MemberType NoteProperty -Name TransferLock -Value ($Domain.WhoIs.registryData.status) -Force
        $Domain | Add-Member -MemberType NoteProperty -Name Hosting -Value (((Resolve-DnsName $Domain.Name -Server $DnsServer | Where {$_.type -eq "A"}).IPAddress | ForEach {$NameHost = (Resolve-DnsName $_ -Server $DNSServer).NameHost; "$($NameHost)($($_))"}) -join ",") -Force
}

$Domain | Export-Csv $DomainsFile -NoTypeInformation