# =========================================================
# SAVIN-RECORDER 3.4: DESINSTALADOR AUTOMÁTICO TOTAL
# =========================================================
Clear-Host
Write-Host "Iniciando desinstalacion..." -ForegroundColor Cyan

$InstallDir = "$env:APPDATA\SavinRecorder"
$VidDir = Join-Path ([Environment]::GetFolderPath("MyVideos")) "SavinRecorder"

# 1. DETENER PROCESOS (Liberar raton y teclado)
Write-Host "Deteniendo procesos activos..." -ForegroundColor Gray
taskkill /F /IM "SavinEngine*" /T 2>$null
taskkill /F /IM "ffmpeg.exe" /T 2>$null
taskkill /F /IM "AutoHotkey*" /T 2>$null

# 2. DESINSTALACION DE PAQUETES (WINGET)
Add-Type -AssemblyName System.Windows.Forms
$resDep = [System.Windows.Forms.MessageBox]::Show("¿Deseas desinstalar tambien FFmpeg y AutoHotkey?", "Savin-Recorder", "YesNo", "Question")

if ($resDep -eq "Yes") {
    Write-Host "Eliminando paquetes via Winget..." -ForegroundColor Yellow
    winget uninstall --id GYAN.FFmpeg --silent 2>$null
    winget uninstall --id AutoHotkey.AutoHotkey --silent 2>$null
}

# 3. ELIMINAR DRIVER DE AUDIO
$DriverUninst = "${env:ProgramFiles(x86)}\screen-capture-recorder\Uninstall.exe"
if (Test-Path $DriverUninst) {
    Write-Host "Eliminando driver de audio..." -ForegroundColor Yellow
    Start-Process -FilePath $DriverUninst -ArgumentList "/S" -Wait
}

# 4. RESTAURAR REGISTRO (Recuperar Win+Shift+R)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$regKey = Get-ItemProperty -Path $regPath -Name "DisabledHotkeys" -ErrorAction SilentlyContinue
if ($regKey -and $regKey.DisabledHotkeys -like "*R*") {
    Write-Host "Restaurando atajos de Windows..." -ForegroundColor Yellow
    $newValue = $regKey.DisabledHotkeys.Replace("R", "")
    if ([string]::IsNullOrWhiteSpace($newValue)) {
        Remove-ItemProperty -Path $regPath -Name "DisabledHotkeys" -Force
    } else {
        Set-ItemProperty -Path $regPath -Name "DisabledHotkeys" -Value $newValue
    }
    Stop-Process -Name explorer -Force
}

# 5. LIMPIEZA DE ARCHIVOS
if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir -ErrorAction SilentlyContinue
    Write-Host "Archivos de aplicacion eliminados." -ForegroundColor Green
}

# 6. GESTION DE VIDEOS
if (Test-Path $VidDir) {
    $resVid = [System.Windows.Forms.MessageBox]::Show("¿Deseas borrar tambien tus grabaciones?", "Savin-Recorder", "YesNo", "Question")
    if ($resVid -eq "Yes") {
        Remove-Item -Path $VidDir -Recurse -Force
        Write-Host "Grabaciones eliminadas." -ForegroundColor Green
    }
}

Write-Host "Desinstalacion completa. Sistema restaurado." -ForegroundColor Green
Start-Sleep -Seconds 2