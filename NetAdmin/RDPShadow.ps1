$Computers = Get-ADComputer -Filter *
$Sessions = ""
$Session = ""

Function Select-Computer {

for($i = 1; $i -le $Computers.count; $i++){
Write-Host "$($i): $($Computers[$i-1].Name)"
}
$Computer = ($Computers[(Read-Host -Prompt "`nEnter the number of the Computer")-1])

$Sessions = qwinsta.exe /server:$($Computer.Name) | ForEach-Object {
      $_.Trim() -replace '\s+',','
    } | ConvertFrom-Csv


for($i = 1; $i -le $Computer.Sessions.count; $i++){
Write-Host "$($i): $($Computer.Sessions[$i-1].DNSHostName)"
}
$Computer = ($Computers[(Read-Host -Prompt "`nEnter the number of the OU")-1]).DNSHostName
return $Computer


return $Computer
}

Function Select-Session {
}

Mstsc.exe /v:$Computer  /Shadow: /Control /noConsentPrompt 


$Sessions = (Get-CimInstance -ClassName Win32_LogonSession) | Select *
