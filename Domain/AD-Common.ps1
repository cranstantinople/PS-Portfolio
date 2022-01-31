Function AD-Init {
    #STRUCTURE HASHTABLE
    $AD = @{}
    $AD.Users = @{}
    $AD.Users.Existing = @{}
    $AD.Groups = @{}
    $AD.Groups.Existing = @{}
    $AD.Groups.Export = @{}
    $AD.Servers = @{}
    $AD.Computers = @{}
    $AD.Computers.Existing = @{}

    #DEFINE DEFAULTS
    $AD.Domain = Get-ADDomain
    $AD.DomainOU = @(Get-ADObject -Filter * -SearchScope 0 -Properties *)
    $AD.OUs = Get-ADObject -Filter 'ObjectClass -eq "organizationalUnit"' -Properties *
    $AD.Users.OUBase = $AD.DomainOU
    $AD.Groups.OUBase = $AD.DomainOU
    $AD.Computers.OUBase = $AD.DomainOU
    $AD.Servers.OUBase = $AD.DomainOU

    $AD.OUs = $AD.DomainOU + $AD.OUs

}

Function Select-ObjectOU {
    
    param (
        [parameter(Mandatory=$true)]
        $OUInput
    )

    Write-Host "Current $($OUInput) OU:" -ForegroundColor Yellow
    Write-Host "$($AD.$OUInput.OUBase.CanonicalName)"
    Write-Host "Would you like to update the OU? [C]urrent Location, [U]pdate Location" -ForegroundColor Yellow
    Write-Host "Current [Default], Update ( [C]urrent / [U]pdate)" -ForegroundColor Green

    Switch -Wildcard ( Read-Host ) {
        Default { }
        U* {
            $AD.$OUInput.OUBase = Menu-Select $AD.OUs -Property CanonicalName
            Write-Host "New $($OUInput) OU:" -ForegroundColor Yellow
            Write-Host "$($AD.$OUInput.OUBase.CanonicalName)"
        }
    }
}
Function ADGroups-Sort {
    #SORT NEW AND EXISTING
    $AD.Groups.Import.Existing = $AD.Groups.Import.All | Where-Object Existing -eq $True
    $AD.Groups.Import.New = $AD.Groups.Import.All | Where-Object Existing -eq $False
    $AD.Groups.Process.Existing = $AD.Groups.Import.Existing | Where-Object Process -eq $True
    $AD.Groups.Process.New = $AD.Groups.Import.New | Where-Object Process -eq $True
}
Function ADGroups-Existing {

    Select-ObjectOU Groups

    #IMPORT AND ORGANIZE ADDRESSES
    $AD.Groups.Existing.All = Get-ADGroup -SearchBase $AD.Groups.OUBase.DistinguishedName -Filter * -Properties * | Sort-Object Name
    ForEach ($Group in $AD.Groups.Existing.All) {
        Write-Host "Getting Details for $($Group.Name)"
        $Group | Add-Member -MemberType NoteProperty -Name Members -Value (Get-ADGroupMember $Group.DistinguishedName) -Force
    }
}
Function ADUsers-Sort {
    #SORT NEW AND EXISTING
    $AD.Users.Import.Existing = $AD.Users.Import.All | Where-Object Existing -eq True
    $AD.Users.Import.New = $AD.Users.Import.All | Where-Object Existing -eq False
}
Function ADUsers-Existing {

    Select-ObjectOU Users

    #IMPORT AND ORGANIZE USERS
    $AD.Users.Existing.All = Get-ADUser -SearchBase $AD.Users.OUBase.DistinguishedName -Filter * -Properties * | Sort-Object Name
    ForEach ($User in $AD.Users.Existing.All) {
        Write-Host "Getting Details for $($User.Name)"
        $User | Add-Member -MemberType NoteProperty -Name SmtpAliases -Value ($User.ProxyAddresses -Join ",") -Force
        $User | Add-Member -MemberType NoteProperty -Name ImmutableID -Value ([system.convert]::ToBase64String(($User.ObjectGuid).ToByteArray())) -Force
        $User | Add-Member -MemberType NoteProperty -Name PathOU -Value $User.CanonicalName.Substring(0, $User.CanonicalName.LastIndexOf('/')) -Force
    }
}
Function ADComputers-Existing {

    Select-ObjectOU Computers

    #IMPORT AND ORGANIZE USERS
    $AD.Computers.Existing.All = Get-ADComputer -SearchBase $AD.Computers.OUBase -Filter * -Properties * | Sort-Object Name
    ForEach ($Computer in $AD.Computers.Existing.All) {
        Write-Host "Getting Details for $($Computer.Name)"
    }
}
Function ADServers-Existing {
    
    Select-ObjectOU Servers

    #IMPORT AND ORGANIZE USERS
    $AD.Servers.Existing.All = Get-ADUser -SearchBase $AD.Users.OUBase -Filter * -Properties * | Sort-Object Name
    ForEach ($Server in $AD.Servers.Existing.All) {
        Write-Host "Getting Details for $($Server.Name)"
        $Server | Add-Member -MemberType NoteProperty -Name SmtpAliases -Value ($User.ProxyAddresses -Join ",") -Force
        $Server | Add-Member -MemberType NoteProperty -Name ImmutableID -Value ([system.convert]::ToBase64String(($User.ObjectGuid).ToByteArray())) -Force
        $Server | Add-Member -MemberType NoteProperty -Name PathOU -Value $User.CanonicalName.Substring(0, $User.CanonicalName.LastIndexOf('/')) -Force
    }
}