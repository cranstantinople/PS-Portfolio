Import-Module ActiveDirectory

$SearchString = "String"
$ExportFile = "C:\TEMP\LogExport.csv"

Function Search-Logs {

    $ADCs = Get-ADDomainController -Filter * 

    ForEach ($ADC in $ADCs) {
        $Logs += Get-EventLog -Computer $ADC.HostName -LogName Security | Where-Object {$_.Message -match $SearchString}
    }

    ForEach ($Entry in $Logs) {
        $Entry | Add-Member -MemberType NoteProperty -Name DateTime -Value $Entry.TimeGenerated
        $Entry | Add-Member -MemberType NoteProperty -Name Event -Value $null
        $Entry | Add-Member -MemberType NoteProperty -Name UserAccount -Value $null
        $Entry | Add-Member -MemberType NoteProperty -Name SourceIPAd -Value $null

        $Entry.UserAccount = ($Entry.Message.Split([Environment]::NewLine) | Where-Object {$_ -Match "Account Name"}) | ForEach-Object {$_.Split(":")[-1].Trim()} | Where-Object {$_ -ne $null -and $_ -ne "-" -and $_ -notcontains "$"} | Select -First 1
        $Entry.SourceIPAd = ($Entry.Message.Split([Environment]::NewLine) | Where-Object {$_ -Match "Address"}) | ForEach-Object {$_.Split(":")[-1].Trim()} | Where-Object {$_ -ne $null -and $_ -ne "-"} | Select -First 1
        #$Entry.SourceName = ([System.Net.Dns]::GetHostbyAddress($Entry.SourceIP)).HostName
        If($Entry.ID -eq "4624") {$Entry.Event = "Log On"} 
        If($Entry.ID -eq "4634") {$Entry.Event = "Log Off"}
    }
}

Function Search-TextLogs {

    $Entry.Account = ($Entry.Message.Split([Environment]::NewLine) | Where-Object {$_ -Match "Account Name"}) | ForEach-Object {$_.Split(":")[-1].Trim()} | Where-Object {$_ -ne $null -and $_ -ne "-" -and $_ -notcontains "$"} | Select-Object -First 1
    $Entry.SourceIP = ($Entry.Message.Split([Environment]::NewLine) | Where-Object {$_ -Match "Address"}) | ForEach-Object {$_.Split(":")[-1].Trim()} | Where-Object {$_ -ne $null -and $_ -ne "-"} | Select-Object -First 1
    $Entry.SourceName = ([System.Net.Dns]::GetHostbyAddress($Entry.SourceIP)).HostName

    $Logs = Select-String -Pattern $SearchString C:\TEMP\*.log
    $Logs | Select-Line | Export-Csv $ExportFile -NoTypeInformation

}


Function Export-Logs {

    $Logs | Where-Object {$_.ID -eq "4624" -or $_.ID -eq "4634"} | Select TimeCreated, UserAccount, MachineName, SourceIPAd, SourceName, Event | Export-Csv $ExportFile -NoTypeInformation

}