Function VSS-Retention {

    param (
        $Volumes,
        $Log
    )

    $VSS = @{}

    #Default Retention Policy in Days
    $VSS.Retention = [Ordered]@{}
    $VSS.Retention.Hourly = 3
    $VSS.Retention.Daily = 10
    $VSS.Retention.Weekly = 60
    $VSS.Retention.Monthly = 365
    $VSS.Retention.Yearly = (10*365)

    #Default Report Settings
    $VSS.Report = @{}
    $VSS.Report.MailRecipient = ""
    $VSS.Report.MailSender = ""
    $VSS.Report.MailServer = ""
    $VSS.Report.LogFile = "C:\Logs\VSSResult.txt"
    $VSS.Report.Log = $True
    $VSS.Report.Email = $False
 
    #Timeout Before Deletion (Seconds)
    $VSS.Timeout = 10
    $VSS.Date = Get-Date
    $VSS.SnapShots = @{}
    $VSS.SnapShots.All = Get-WmiObject Win32_ShadowCopy
    
    #Get VSS Volumes
    $VSS.Volumes = @(Get-WmiObject Win32_Volume | Where-Object DeviceID -in $VSS.SnapShots.All.VolumeName)
    
    #Determine VSS Volume Retention Policies
    ForEach ($Volume in $VSS.Volumes) {
        $Volume | Add-Member -MemberType NoteProperty -Name Retention -Value $Null
        $Volume.Retention = [Ordered]@{}
        ForEach ($Policy in $VSS.Retention.Keys) {
            $Volume.Retention.$Policy = @{
                Days = $VSS.Retention.$Policy
            }
        }
    }

    ForEach ($Snapshot in $VSS.SnapShots.All) {
        $SnapShot | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($VSS.Volumes.Values.Volume | Where-Object DeviceID -eq $SnapShot.VolumeName).DriveLetter
        $SnapShot | Add-Member -MemberType NoteProperty -Name DateTime -Value $Snapshot.ConvertToDateTime($SnapShot.InstallDate)
        $SnapShot | Add-Member -MemberType NoteProperty -Name SnapShotTime -Value (Get-Date $SnapShot.DateTime -Format "HH:mm:ss")
        $SnapShot | Add-Member -MemberType NoteProperty -Name SnapShotDate -Value (Get-Date $SnapShot.DateTime -Format "yyyy-MM-dd")
        $SnapShot | Add-Member -MemberType NoteProperty -Name SnapShotDay -Value $SnapShot.DateTime.DayOfWeek.value__
        $SnapShot | Add-Member -MemberType NoteProperty -Name SnapShotWeek -Value (Get-Date $SnapShot.DateTime -UFormat %V)
        $SnapShot | Add-Member -MemberType NoteProperty -Name SnapShotMonth -Value $SnapShot.DateTime.Month
        $SnapShot | Add-Member -MemberType NoteProperty -Name SnapShotYear -Value $SnapShot.DateTime.Year
        $SnapShot | Add-Member -MemberType NoteProperty -Name SnapShotDays -Value ($VSS.Date - $SnapShot.DateTime).days
        $SnapShot | Add-Member -MemberType NoteProperty -Name Retention -Value Retain
    }

    #Process Retention Policy for Each VSS Volume
    ForEach ($Volume in $VSS.Volumes) {

        $Volume.Retention.Hourly.Policy = {$_.SnapShotDays -lt $Volume.Retention.Hourly.Days}
        $Volume.Retention.Hourly.Grouping = $Null
        $Volume.Retention.Daily.Policy = {($_.SnapShotDays -ge $Volume.Retention.Hourly.Days) -and ($_.SnapShotDays -lt $Volume.Retention.Daily.Days)}
        $Volume.Retention.Daily.Grouping = "SnapShotDate"
        $Volume.Retention.Weekly.Policy = {($_.SnapShotDays -ge $Volume.Retention.Daily.Days) -and ($_.SnapShotDays -lt $Volume.Retention.Weekly.Days)}
        $Volume.Retention.Weekly.Grouping = "SnapShotWeek"
        $Volume.Retention.Monthly.Policy = {($_.SnapShotDays -ge $Volume.Retention.Daily.Days) -and ($_.SnapShotDays -lt $Volume.Retention.Monthly.Days)}
        $Volume.Retention.Monthly.Grouping = "SnapShotMonth"
        $Volume.Retention.Yearly.Policy = {($_.SnapShotDays -ge $Volume.Retention.Monthly.Days) -and ($_.SnapShotDays -lt $Volume.Retention.Yearly.Days)}
        $Volume.Retention.Yearly.Grouping = "SnapShotYear"
       
        $Volume | Add-Member -MemberType NoteProperty -Name SnapShots -Value $Null
        $Volume.SnapShots = [Ordered]@{}

        $Volume.SnapShots.All = $VSS.SnapShots.All | Where-Object { ($_.ClientAccessible -eq $True) -and ($_.DriveLetter -eq $Volume.Volume.DriveLetter) }    
        
        #Mark SnapShots for Retention
        ForEach ($Policy in $Volume.Retention.Keys) {
            $Volume.SnapShots.$Policy = @{}
            $Volume.SnapShots.$Policy.All = $Volume.SnapShots.All | Where-Object $Volume.Retention.$Policy.Policy | Group-Object $Volume.Retention.$Policy.Grouping
            $Volume.SnapShots.$Policy.Retain = $Volume.SnapShots.$Policy.All | ForEach-Object { 
                $_.group | Select-Object -First 1
            } | ForEach-Object {
                $_.Retention = $Policy
                $_ | Select-Object
            }
        }

        #Mark SnapShots for Deletion
        $Volume.SnapShots.DELETE = $Volume.SnapShots.All | Where-Object {
            $_.Retention -notin $Volume.Retention.Keys
        } | ForEach-Object {
            $_.Retention = "DELETE"
            $_ | Select-Object
        }

        #Results

        "============================= SnapShots by Retention ==============================" #| Out-Multi -OutHost Green -OutVar "VSS.Report.Result" -Append
        $Volume.SnapShots.All | Group-Object Retention | Sort-Object {$Volume.Retention.Keys.IndexOf($_.Name)} #| Out-Multi -OutHost -OutVar VSS.Report.Result -Append

        "=========================== Retained SnapShots by Date ============================" #| Out-Multi -OutHost Green -OutVar "VSS.Report.Result" -Append
        $Volume.SnapShots.All | Group-Object SnapShotDate | Sort-Object Name -Descending #| Out-Multi -OutHost -OutVar VSS.Report.Result -Append

        "========================== SnapShots Marked for Deletion ==========================" #| Out-Multi -OutHost Red -OutVar "VSS.Report.Result" -Append
        If ($Volume.SnapShots.DELETE) {
            $Volume.SnapShots.DELETE | Group-Object SnapShotDate #| Out-Multi -OutHost -OutVar "VSS.Report.Result" -Append

            Write-Host "Deleting in 10 Seconds" -ForegroundColor Red
            Start-Sleep 10

        } Else {
            "NONE" #| Out-Multi -OutHost Red -OutVar "VSS.Report.Result" -Append
        }
        $VSS.Report.Result += $Result

        ForEach ($SnapShot in $Volume.SnapShots.DELETE) {
            "Removing $($SnapShot.SnapShotDate) - $($SnapShot.SnapShotTime)" #| Out-Multi -OutHost Red -OutVar "VSS.Report.Result" -Append
            $SnapShot | Remove-WmiObject
        }
    }

    If ($VSS.Report.Log = $True) {
        $VSS.Report.Result | Out-File $VSS.Report.LogFile -Force -Append
    }
    If ($VSS.Report.Email = $True) {
        Send-MailMessage -SmtpServer "$VSS.Report.MailServer" -To "$VSS.Report.MailRecipient" -From "$VSS.Report.MailSender" -Subject "Reboot time of target servers" -Body $VSS.Report.Result 
    }
}

VSS-Retention