
$DISM = @{}
$DISM.Wim =@{}

$DISM.Wim.Path = "\\SINC\Software\Images\Server2019\sources\"
$DISM.Wim.File = "install"
$DISM.Wim.Index = "2"
$DISM.Wim.Dir = "C:\TEMP\offline"
$DISM.Wim.TargetEdition = "ServerStandard"

DISM /Get-WimInfo /WimFile:"$($DISM.Wim.Path)$($DISM.Wim.File).wim"

DISM /Mount-Wim /WimFile:"$($DISM.Wim.Path)$($DISM.Wim.File).wim" /index:$($DISM.Wim.Index) /MountDir:$($DISM.Wim.Dir)

DISM /Image:$($DISM.Wim.Dir) /Set-Edition:$($DISM.Wim.TargetEdition)

DISM /Get-MountedWimInfo

DISM /Unmount-Wim /MountDir:$($DISM.Wim.Dir) /Commit
