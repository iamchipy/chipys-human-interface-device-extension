Stop-Process -Name "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe"
if(Test-Path -Path "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe.old") {Remove-Item "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe.old"}
while(Test-Path -Path "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe"){
Rename-Item -Path "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe" -NewName "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe.old" -force
Write-Host "Waiting for .olding ..." 
start-sleep -seconds 1
}
while(-not(Test-Path -Path "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe-v1.0.10.zip")){
Write-Host "Waiting for download ..." 
start-sleep -seconds 0.5
}
Expand-Archive -Path "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe-v1.0.10.zip" -DestinationPath "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\" -Force 
while(-not(Test-Path -Path "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe")){
Write-Host "Waiting for unzip ..." 
start-sleep -seconds 0.5
}
& "G:\Dropbox\_SCRIPTS\chipys-human-interface-device-extension\chide.exe"