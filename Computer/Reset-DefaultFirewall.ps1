    netsh advfirewall export "C:\TEMP\firewall-config.wfw"
    netsh advfirewall reset
    ipconfig /release
    ipconfig /flushdns
    ipconfig /renew
    netsh int ip reset
    netsh winsock reset
    shutdown /r /f

