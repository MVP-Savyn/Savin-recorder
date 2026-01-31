# =========================================================
# SAVIN-RECORDER: DESINSTALADOR DE RESTAURACIÓN TOTAL
# =========================================================
Clear-Host
Write-Host "🚮 Iniciando desinstalación y restauración del sistema..." -ForegroundColor Cyan

$InstallDir = "$env:APPDATA\SavinRecorder"
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutPath = "$StartupFolder\SavinRecorder.lnk"

# 1. DETENER PROCESOS
Write-Host "🛑 Deteniendo grabaciones y atajos activos..." -ForegroundColor Gray
Get-Process ffmpeg -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process AutoHotkey* -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. RESTAURAR EL REGISTRO (Devolver Win+Shift+R a Windows)
Write-Host "🔓 Restaurando atajos originales de Windows..." -ForegroundColor Yellow
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$existing = (Get-ItemProperty -Path $regPath -Name "DisabledHotkeys" -ErrorAction SilentlyContinue).DisabledHotkeys
if ($existing -like "*R*") {
    $newValue = $existing.Replace("R", "")
    if ([string]::IsNullOrWhiteSpace($newValue)) {
        Remove-ItemProperty -Path $regPath -Name "DisabledHotkeys" -Force
    } else {
        Set-ItemProperty -Path $regPath -Name "DisabledHotkeys" -Value $newValue
    }
    Write-Host "✅ Registro restaurado. Reiniciando Explorer..." -ForegroundColor Green
    Stop-Process -Name explorer -Force
}

# 3. ELIMINAR INICIO AUTOMÁTICO
if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
    Write-Host "✅ Inicio automático eliminado." -ForegroundColor Green
}

# 4. LIMPIEZA DE ARCHIVOS
if (Test-Path $InstallDir) {
    # Borramos la carpeta de la app (scripts, binarios de ffmpeg, etc.)
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "✅ Archivos de la aplicación eliminados." -ForegroundColor Green
}

# 5. RESUMEN FINAL
Write-Host ""
Write-Host "✨ EL SISTEMA HA SIDO RESTAURADO ✨" -ForegroundColor Green
Write-Host "Nota: Se han conservado tus videos en 'Videos\SavinRecorder'." -ForegroundColor White
Write-Host "Nota: Si deseas quitar AutoHotkey por completo, hazlo desde 'Configuración > Aplicaciones'." -ForegroundColor Gray