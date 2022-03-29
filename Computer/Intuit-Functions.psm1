Function Repair-QBO {

    <#
    .Synopsis
        Outputs tables from delaminated input with options for sub-delamination
    .DESCRIPTION
    .EXAMPLE
    .INPUTS
    .OUTPUTS
    .NOTES
        Author     : Clayton Tschirhart
        Requires   : 
    .COMPONENT
    .ROLE
    .FUNCTIONALITY
    #> 
    param (
        $Location
    )
       
    $QBO = @{}
    $QBO.Location = "$($env:USERPROFILE)\Downloads"

    $QBO.Files = @{}
    $QBO.Files.All = Get-ChildItem $QBO.Location -Recurse -Include *.qbo | Sort-Object LastWriteTime -Descending
    $QBO.Files.Old = $QBO.Files.All | Select-Object -Skip 1
    
    Set-Console -Top -Space 10
    Write-Host "The Following QBO Files Have been found in $($QBO.Location)" -ForegroundColor Green
    $QBO.Files.Current = Select-Options $QBO.Files.All -Timeout 10 -Default 1

    ForEach ($File in $QBO.Files.Current) {
        $File | Add-Member -MemberType NoteProperty -Name Date -Value $null -Force
        $File | Add-Member -MemberType NoteProperty -Name NewName -Value $null -Force
        $File | Add-Member -MemberType NoteProperty -Name Content -Value $null -Force
        $File | Add-Member -MemberType NoteProperty -Name Header -Value $null -Force
        $File | Add-Member -MemberType NoteProperty -Name OFX -Value $null -Force
        $File | Add-Member -MemberType NoteProperty -Name Output -Value $null -Force
    
        Write-Host "Getting $($File.Name) Data" -ForegroundColor Green

        $File.Date = Get-Date $File.LastWriteTime -Format "yyyy-MM-dd--HH-mm-ss"
        $File.Content = Get-Content $File.FullName -Raw
        $File.Header = ($File.Content -split '<OFX>')[0]

        $File.OFX = Get-ParsedData $File.Content

        Write-Host "Checking $($File.Name) Data for Errors" -ForegroundColor Yellow

        If ($File.OFX.OFX.CREDITCARDMSGSRSV1.CCSTMTTRNRS.CCSTMTRS.BANKTRANLIST.DTSTART.Length -lt 8) {
            Write-Host "Fixing OFX.CREDITCARDMSGSRSV1.CCSTMTTRNRS.CCSTMTRS.BANKTRANLIST.DTSTART" -ForegroundColor Yellow
            $File.OFX.OFX.CREDITCARDMSGSRSV1.CCSTMTTRNRS.CCSTMTRS.BANKTRANLIST.DTSTART = 
            "$(($File.OFX.OFX.CREDITCARDMSGSRSV1.CCSTMTTRNRS.CCSTMTRS.BANKTRANLIST.STMTTRN.DTPOSTED | Sort-Object | Select-Object -First 1).SubString(0,8))000000"
        }
        If ($File.OFX.OFX.CREDITCARDMSGSRSV1.CCSTMTTRNRS.CCSTMTRS.BANKTRANLIST.DTEND.Length -lt 8) {
            Write-Host "Fixing OFX.CREDITCARDMSGSRSV1.CCSTMTTRNRS.CCSTMTRS.BANKTRANLIST.DTEND" -ForegroundColor Yellow
            $File.OFX.OFX.CREDITCARDMSGSRSV1.CCSTMTTRNRS.CCSTMTRS.BANKTRANLIST.DTEND =
            "$(($File.OFX.OFX.CREDITCARDMSGSRSV1.CCSTMTTRNRS.CCSTMTRS.BANKTRANLIST.STMTTRN.DTPOSTED | Sort-Object | Select-Object -Last 1).SubString(0,8))235959"
        }

        Write-Host "Exporting Fixed File $($QBO.Location)\$($File.Date).qbo" -ForegroundColor Yellow
        Get-ParsedResult $File.OFX
        $File.Output = $File.Header
        $File.Output += $File.OFX.Output
        $File.Output | Out-File "$($QBO.Location)\$($File.Date).qbo"
       
        Write-Host "Would you like to Import File Now?" -ForegroundColor Green

        Switch -Wildcard (Read-Host "Import? ( [Y]es / [N]o ) " ) {
            Default {Return}
            Y* {
                Start-Process "$($QBO.Location)\$($File.Date).qbo"
            }
        }
    }

    Write-Host ($QBO.Files.Old | Select-Object Name,LastWriteTime | Out-String) -ForegroundColor Yellow
    Write-Host "Found $($QBO.Files.Old.Count) Old Files.  Would you like to remove these?" -ForegroundColor Red
    
    Switch -Wildcard (Read-Host "Delete? ( [Y]es / [N]o ) " ) {
        Default {Return}
        Y* {
            ForEach ($File in $QBO.Files.Old) {
                $File | Remove-Item
            }
        }
    }
}