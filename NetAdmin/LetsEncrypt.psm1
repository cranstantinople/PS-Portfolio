Function Initialize-LetsEncrypt  {
    
    $PreCheck = @{}
    $PreCheck.Required = @(
        'Posh-ACME',
        'Posh-ACME.Deploy'
    )
    Start-PreCheck $PreCheck
    
    $LE = @{}
    $LE.Account = Get-PAAccount
    $LE.Certificate = @{}
    $LE.Certificates = @{}
    $LE.Certificates.Renew = 30

    Return $LE

}
Function New-LECertificate {

    Set-PAServer $LE.Server
    New-PAAccount -Contact $LE.Contact -AcceptTOS
    Set-PAAccount -Contact $LE.Contact -AcceptTOS

    New-PACertificate $LE.Certificate.DNSName -Plugin Cloudflare -PluginArgs $LE.DNSAuth
    Install-PACertificate $LE.Certificate.DNSName

    Set-PAOrder $LE.Certificate.DNSName -Plugin Cloudflare -PluginArgs $LE.DNSAuth
}
Function Get-LECertificates {

    $LE.Date = Get-Date
    $LE.Certificates.All = Get-PACertificate
    $LE.Orders = Get-PAOrder

    ForEach ($Certificate in $LE.Certificates.All) {
        $Certificate | Add-Member -MemberType NoteProperty -Name Name -Value $null
        $Certificate | Add-Member -MemberType NoteProperty -Name Order -Value $null
        $Certificate | Add-Member -MemberType NoteProperty -Name Expires -Value $null
        $Certificate | Add-Member -MemberType NoteProperty -Name Store -Value $null

        $Certificate.Name = $LE.Subject -replace "CN=",""
        $Certificate.Order = $LE.Orders | Where-Object {$_.Name -in $Certificate.AllSANs}
        $Certificate.Expires = $Certificate.NotBefore

        Write-Host "Getting $($Certificate.Name)" -ForegroundColor Green
        $Certificate.Store = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -match $Certificate.Thumbprint}
        Write-Host "$($Certificate | Select-Object Name,Thumbprint,Expires)" -ForegroundColor Yellow
    }
    return $LE.Certificates
}
Function Update-LECertificate {
    Write-Host "Renewing Certificates" -ForegroundColor Green
    Submit-Renewal $LE.Certificate.DNSName
    $LE.Certificate.new = Get-PACertificate

    Write-Host "Installing Certificates" -ForegroundColor Green
    Install-PACertificate $LE.Certificate.new

    $LE.Certificate.Store.New = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -match $($LE.Certificates.new).Thumbprint}
}