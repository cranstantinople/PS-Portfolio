Function Server-Init {
    #COMMON HASH TABLE
    $Server = @{}
    $Server.Domain = @{}
    $Server.Certificates = @{}
    $Server.Roles = @{}
    $Server.Drives = @{}
    $Server.Printers = @{}

    $Server.Roles.All = [Ordered]@{}
    $Server.Roles.All.DC = @{}
    $Server.Roles.All.DNS = @{}
    $Server.Roles.All.DHCP = @{}
    $Server.Roles.All.File = @{}
    $Server.Roles.All.IIS = @{}
    $Server.Roles.All.IIS.Name = "Internet and Information Service"
    $Server.Roles.All.RRAS = @{}
    $Server.Roles.All.RRAS.Name = "Routing and Remote Service"
    $Server.Roles.All.RDS = @{}
    $Server.Roles.All.RDS.Name = "Remote Desktop Service Deployment"
    $Server.Roles.All.RDWeb = @{}
    $Server.Roles.All.RDWeb.Name = "Remote Desktop Web Deployment"
    $Server.Roles.All.WAC = @{}
    $Server.Roles.All.WAC.Name = "Windows Admin Center"

    $Server.SystemInfo = (Get-WmiObject -Class Win32_ComputerSystem)
    $Server.HostName = $Computer.SystemInfo.Name
    $Server.Domain.Name = $Computer.SystemInfo.Domain
    $Server.DNSName = "$($Computer.SystemInfo.Name).$($Computer.SystemInfo.Domain)"

    $Server.Roles.Installed = $Server.Roles.All

    Return $Server

}