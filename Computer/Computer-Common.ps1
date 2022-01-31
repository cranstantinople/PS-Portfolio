#COMMON HASH TABLE
$Computer = @{}
$Computer.Domain = @{}
$Computer.Drives = @{}

$Computer.SystemInfo = (Get-WmiObject -Class Win32_ComputerSystem)
$Computer.HostName = $Computer.SystemInfo.Name
$Computer.Domain.Name = $Computer.SystemInfo.Domain
$Computer.DNSName = "$($Computer.SystemInfo.Name).$($Computer.SystemInfo.Domain)"

