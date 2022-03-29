Function Install-WindowsAdminCenter {
    
    param (
        $Certificate,
        $Port, 
        $Download,
        $InstallerPath
    )
    
    #requires -runasadministrator

    #WINDOWS ADMIN CENTER DOCs
    #https://docs.microsoft.com/en-us/windows-server/manage/windows-admin-center/deploy/install

    #DEFINE DEFAULTS
    $WAC = @{}
    $WAC.Installer = @{}
    $WAC.Installer.Uri = "http://aka.ms/WACDownload"
    $WAC.Installer.Location = "\\SINC\SysAdmin\Software\Windows Admin Center\"
    $WAC.Port = 8443

    $WAC.Installer.Name = (Invoke-WebRequest -Uri  $WAC.Installer.Uri -Method Head).BaseResponse.ResponseUri.Segments[-1]
    $WAC.Installer.FullPath = Join-Path $WAC.Installer.Location $WAC.Installer.Name
    If ((Test-Path $WAC.Installer.FullPath) -eq $False) {
        Write-Output "Downloading Windows Admin Center..."
        Invoke-WebRequest -Uri $WAC.Installer.Uri -OutFile $WAC.Installer.FullPath
    }
    
    If ($WAC.Installed){
        Write-Output "Updating Windows Admin Center..."
    } Else {
        Write-Output "Installing Windows Admin Center..."
    }

    #GET CERTIFICATE
    If ($Certificate) {
        $WAC.Certificate = $Certificate
        If ($WAC.Certificate.Thumbprint) {
            $WAC.Certificate = $WAC.Certificate.Thumbprint
        }
    }
    #if CertificateThumbprint is defined and installed on the system will be used during the installation
    if ($WAC.Certificate){
        msiexec /i "$($WAC.Installer.FullPath)" SME_PORT=$($WAC.Port) SME_THUMBPRINT=$($WAC.Certificate) SSL_CERTIFICATE_OPTION=installed /qr /L*v c:\TEMP\WAC-Log.txt  
    }
    else{
        msiexec /i $WAC.Installer /qn SME_PORT=$WAC.Port SSL_CERTIFICATE_OPTION=generate
    }

    #Post Installation Checks
    do {
        if ((Get-Service ServerManagementGateway).status -ne "Running"){
            Write-Output "Starting Windows Admin Center (ServerManagementGateway) Service"
            Start-Service ServerManagementGateway
        }
        Start-sleep -Seconds 5
    } until ((Test-NetConnection -ComputerName "localhost" -port $WAC.Port).TcpTestSucceeded)

    Write-Output "Installation completed and Windows Admin Center is running as expected."

}
Function Get-RoleCertificates {

    param (
        $Version
    )

    If (-not $Version) {
        $Version = "Current"
    }
    
    $Server.Certificates.Store.All = Get-ChildItem Cert: -Recurse

    $Server.Roles.All.IIS.Certificate.Command = {
        $Server.Roles.All.IIS.Bindings = Get-WebBinding | Where-Object {$_.protocol -eq "https"}
        $Server.Certificates.Store.All | Where-Object {$_.Thumbprint -in ($Server.Roles.All.IIS.Bindings).certificateHash}
    }
    $Server.Roles.All.RRAS.Certificate.Command = {
        (Get-RemoteAccess).SslCertificate | Select-Object Subject,NotAfter,Thumbprint
    }
    $Server.Roles.All.RDS.Certificate.Command = {
        Get-RDCertificate | Select-Object Role,Subject,ExpiresOn,Thumbprint
    }

    $Server.Roles.All.WAC.Certificate.Command = {
        Get-ChildItem IIS:\SslBindings | Where-Object {$_.Port -eq $Server.Roles.All.WAC.Port} | Select-Object *
    }
    
    ForEach ($Role in $Server.Roles.Installed.Values | Where-Object {$_.Certificate.Command}) {
        Write-Host "Retrieving $($Role.Name) Certificate..." -ForegroundColor Yellow
            $Role.Certificate.$Version = Invoke-Command $Role.Certificate.Command
        Write-Host "$($Role.Name) Certificate:" -ForegroundColor Green
        $Role.Certificate.$Version
    }
}
Function Check-ServerCertificates {

    Import-Module "\\SINC\IT\PSRepo\PS-Common.psm1" -DisableNameChecking
    
    $PreCheck = @{}
    $PreCheck.Required = @(
        'LetsEncrypt',
        'Server-Common',
        'Server-Functions'
    )
    Start-PreCheck $PreCheck
    
    $Server = Initialize-Server
    $LE = Initialize-LetsEncrypt

    $LE.Certificates = Get-LECertificates
    $LE.Certificate = $LE.Certificates | Where-Object {$_.Name -eq $LE.Certificate.DNSName}

    If ($LE.Certificate.Renew -eq $true) {
        Get-RoleCertificates -Version Previous
        Update-LECertificate
        Update-RoleCertificates -Certificate $LE.Certificates.Store.New -PfxCert $LE.Certificates.PA.New.PfxFile -PfxPass $LE.Certificates.PA.New.PfxPass
        Get-RoleCertificates -Version New
    }


}
Function Update-RoleCertificates {

    param (
        $Certificate,
        $PfxCert,
        $PfxPass,
        $Roles
    )

    $Server.Roles.All.IIS.Certificate.Update = @{}
    $Server.Roles.All.RRAS.Certificate.Update = @{}
    $Server.Roles.All.RDS.Certificate.Update = @{}
    $Server.Roles.All.RDWeb.Certificate.Update = @{}
    $Server.Roles.All.WAC.Certificate.Update = @{}
    
    $Server.Roles.All.IIS.Certificate.Update.Command = {
        ForEach ($Binding in $Server.Roles.All.IIS.Bindings) {
            $Binding.AddSslCertificate($Certificate.GetCertHashString(), "My")
        }
    }

    $Server.Roles.All.RRAS.Certificate.Update.Command = {
        Import-Module RemoteAccess
        Stop-Service RemoteAccess -Verbose
        Set-RemoteAccess -SslCertificate $Certificate -Verbose
        Start-Sleep 1
        Start-Service RemoteAccess -Verbose
    }
    
    $Server.Roles.All.RDS.Certificate.Update.Command = {
        Set-RDCertificate RDGateway -ImportPath $PfxCert -Password $PfxPass -Force -Verbose
        Set-RDCertificate RDWebAccess -ImportPath $PfxCert -Password $PfxPass -Force -Verbose
        Set-RDCertificate RDRedirector -ImportPath $PfxCert -Password $PfxPass -Force -Verbose
        Set-RDCertificate RDPublishing -ImportPath $PfxCert -Password $PfxPass -Force -Verbose
    }

    $Server.Roles.All.RDWeb.Certificate.Update.Command = {
        Import-RDWebClientBrokerCert -Path $PfxCert -Password $PfxPass -Verbose
        Publish-RDWebClientPackage -Type Production -Latest -Verbose
    }

    $Server.Roles.All.WAC.Certificate.Update.Command = { 
        Get-Service ServerManagementGateway | Stop-Service -Verbose
        Set-ItemProperty $Server.Roles.All.WAC.Certificate.Previous.PSPath -Name Thumbprint -Value $Certificate.Thumbprint -Verbose
        Get-Service ServerManagementGateway | Start-Service -Verbose
    }

    $Server.Roles.Update = @{}
    If ($Roles) {
        ForEach ($Role in $Roles) {
            $Server.Roles.Update[$Role] += $Server.Roles.Installed[$Role]
        }
    } Else {
        $Server.Roles.Update = $Server.Roles.Installed
    }

    #Update Certificates
    ForEach ($Role in $Server.Roles.Update.Values | Where-Object {$_.Certificate.Update}) {
        Write-Host "Updating $($Role.Name) Certificate..." -ForegroundColor Yellow
        Try {
            Invoke-Command $Role.Certificate.Update.Command -ErrorAction Stop
            Write-Host "$($Role.Name) Success..." -ForegroundColor Green
            $Role.Result = "Success"
        } Catch {
            $Role.Result = $_
            Write-Host "$($Role.Name) Failed..." -ForegroundColor Red
            Write-Host $Role.Result -ForegroundColor Red
        }

    }
}
Function Get-ServerDHCP {
    
    $Server.Roles.All.DHCP.Scopes = @{}

    $Server.Roles.All.DHCP.All = Get-DhcpServerv4Scope
    
    $Server.Roles.All.DHCP.Export = $Server.Roles.All.DHCP.All | Where-Object {$_.ScopeId -match "30"}

    Export-DhcpServer -ScopeId $Server.Roles.All.DHCP.Export.ScopeId -File "C:\TEMP\DHCP-Export.xml" -Leases

}