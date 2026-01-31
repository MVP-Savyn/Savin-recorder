$InstallDir = "$env:APPDATA\SavinRecorder"
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
Get-Process "AutoHotkey*" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process "ffmpeg" -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item "$StartupFolder\SavinRecorder.lnk" -ErrorAction SilentlyContinue
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Remove-ItemProperty -Path $regPath -Name "DisabledHotkeys" -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force
Remove-Item -Recurse -Force $InstallDir -ErrorAction SilentlyContinue
Write-Host "Savin-Recorder eliminado correctamente." -ForegroundColor Yellow