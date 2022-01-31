Function LE-Init {
    
    $PreCheck = @{}
    $PreCheck.Required = @(
        'Posh-ACME',
        'Posh-ACME.Deploy'
    )
    Pre-Check $PreCheck
    
    $LE = @{}
    $LE.Certificate = @{}
    $LE.Certificates = @{}

    Return $LE

}
Function LE-New {

    Set-PAServer $LE.Server
    New-PAAccount -Contact $LE.Contact -AcceptTOS
    Set-PAAccount -Contact $LE.Contact -AcceptTOS

    New-PACertificate $LE.DNSName -Plugin Cloudflare -PluginArgs $LE.DNSAuth

    Set-PAOrder $LE.DNSName -Plugin Cloudflare -PluginArgs $LE.DNSAuth
}

Function Get-LECertificates {
    
    Write-Host "Getting Existing Certificates" -ForegroundColor Green

    $LE.Date = Get-Date
    $LE.Certificates.PA = @{}
    $LE.Certificates.Store = @{}

    $LE.Certificates.PA.current = Get-PACertificate
    $LE.Certificates.RenewDate = Get-Date $LE.Certificates.PA.current.NotAfter.AddDays(-30) -Day 1
    
    If ($LE.Date -ge $LE.Certificates.RenewDate) {
        $LE.Certificates.Renew = $true
    } Else {
        $LE.Certificates.Renew = $false
        $LE.Certificates.PA.new = $LE.Certificates.PA.current
        $LE.Certificates.Store.new = $LE.Certificates.PA.current
    }

    return $LE.Certificates

}
Function LE-Renew {
    Write-Host "Renewing Certificates" -ForegroundColor Green
    Submit-Renewal $LE.DNSName

    Write-Host "Installing Certificates" -ForegroundColor Green
    Install-PACertificate $LE.DNSName

    $LE.Certificates.PA.new = Get-PACertificate
    $LE.Certificates.Store.New = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -match $($LE.Certificates.PA.new).Thumbprint}
}
Function LE-Verify {

    Write-Host "Verifying Certificates..." -ForegroundColor Green
    $LE.Certificates.IIS.new = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -match $($LE.Certificates.IIS.bindings).CertficateHash}
    $LE.Certificates.RRAS.new = (Get-RemoteAccess).SslCertificate | Select-Object Subject,NotAfter,Thumbprint
    $LE.Certificates.RDS.new = Get-RDCertificate | Select-Object Role,Subject,ExpiresOn,Thumbprint
    $LE.Certificates.RDS.new += Get-RDWebClientBrokerCert | Select-Object Role,Subject,NotAfter,Thumbprint

    Write-Host "Previous Certificates" -ForegroundColor Yellow
    
    Write-Host "Let's Encrypt" -ForegroundColor DarkYellow
    $LE.Certificates.PA.current | Format-Table
    Write-Host "Certificate Store" -ForegroundColor DarkYellow
    $LE.Certificates.Store.current | Format-Table
    Write-Host "IIS" -ForegroundColor DarkYellow
    $LE.Certificates.IIS.current | Format-Table
    Write-Host "Routing and Remote Access" -ForegroundColor DarkYellow
    $LE.Certificates.RRAS.current | Format-Table
    Write-Host "Remote Desktop Services" -ForegroundColor DarkYellow
    $LE.Certificates.RDS.current | Format-Table
    
    Write-Host "New Certificates" -ForegroundColor Green
    $LE.Certificates.PA.new | Format-Table
    $LE.Certificates.Store.new | Format-Table
    $LE.Certificates.IIS.new | Format-Table
    $LE.Certificates.RRAS.new | Format-Table
    $LE.Certificates.RDS.new | Format-Table

}