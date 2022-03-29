Function Initialize-Server {
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
    $Server.Roles.All.IIS.Certificate = @{}
    $Server.Roles.All.RRAS = @{}
    $Server.Roles.All.RRAS.Name = "Routing and Remote Service"
    $Server.Roles.All.RRAS.Certificate = @{}
    $Server.Roles.All.RDS = @{}
    $Server.Roles.All.RDS.Name = "Remote Desktop Service Deployment"
    $Server.Roles.All.RDS.Certificate = @{}
    $Server.Roles.All.RDWeb = @{}
    $Server.Roles.All.RDWeb.Name = "Remote Desktop Web Deployment"
    $Server.Roles.All.RDWeb.Certificate = @{}
    $Server.Roles.All.WAC = @{}
    $Server.Roles.All.WAC.Name = "Windows Admin Center"
    $Server.Roles.All.WAC.Port = "8443"
    $Server.Roles.All.WAC.Certificate = @{}

    $Server.SystemInfo = (Get-WmiObject -Class Win32_ComputerSystem)
    $Server.HostName = $Server.SystemInfo.Name
    $Server.Domain.Name = $Server.SystemInfo.Domain
    $Server.DNSName = "$($Server.SystemInfo.Name).$($Server.SystemInfo.Domain)"

    $Server.Certificates = @{}
    $Server.Certificates.Store = @{}

    $Server.Roles.All.IIS.Certificate = @{}

    $Server.Roles.Installed = $Server.Roles.All

    Return $Server
}