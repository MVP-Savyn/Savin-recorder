# =========================================================
# SAVIN-RECORDER: INSTALADOR TOTAL (LIBERACIÓN DE HOTKEYS)
# =========================================================
$InstallDir = "$env:APPDATA\SavinRecorder"
$BinDir = "$InstallDir\bin"
$VidDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyVideos"), "SavinRecorder")
$FFmpegExe = "$BinDir\ffmpeg.exe"
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

Write-Host "🚀 Savin-Recorder: Configurando sistema..." -ForegroundColor Cyan

# 1. PARCHE REGISTRO (Libera Win+Shift+R - Nivel Pro)
Write-Host "🔓 Desactivando Recortes nativo para liberar Win+Shift+R..." -ForegroundColor Yellow

# Opción A: Bloqueo de teclas en Explorer
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $regPath -Name "DisabledHotkeys" -Value "R"

# Opción B: "Mudar" el atajo de la aplicación de recortes (Para Windows 11)
$recortesReg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel"
Set-ItemProperty -Path $recortesReg -Name "OpenedWithPrintScreenKey" -Value 0 -ErrorAction SilentlyContinue

# Reiniciar Explorer para aplicar
Stop-Process -Name explorer -Force
# 2. CREAR CARPETAS
New-Item -ItemType Directory -Path "$InstallDir", "$BinDir", "$VidDir\MP4", "$VidDir\GIFS" -Force | Out-Null

# 3. INSTALAR AUTOHOTKEY Y FFMPEG
if (!(Get-Command ahk2exe -ErrorAction SilentlyContinue) -and !(Test-Path "C:\Program Files\AutoHotkey")) {
    winget install --id AutoHotkey.AutoHotkey --silent --accept-source-agreements --accept-package-agreements | Out-Null
}
if (!(Test-Path $FFmpegExe)) {
    Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile "$env:TEMP\ffmpeg.zip"
    Expand-Archive -Path "$env:TEMP\ffmpeg.zip" -DestinationPath "$env:TEMP\ffmpeg_temp" -Force
    Get-ChildItem -Path "$env:TEMP\ffmpeg_temp" -Filter "ffmpeg.exe" -Recurse | Move-Item -Destination $BinDir -Force
    Remove-Item "$env:TEMP\ffmpeg.zip"; Remove-Item -Recurse "$env:TEMP\ffmpeg_temp"
}

# 4. SCRIPT SELECTOR DE ÁREA
@'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$form = New-Object Windows.Forms.Form
$form.TransparencyKey = $form.BackColor = [Drawing.Color]::White
$form.FormBorderStyle = 'None'; $form.TopMost = $true; $form.WindowState = 'Maximized'; $form.Cursor = [Windows.Forms.Cursors]::Cross
$selection = New-Object Drawing.Rectangle; $startPos = [Drawing.Point]::Empty
$form.Add_MouseDown({ $script:startPos = $$.Location; $form.BackColor = [Drawing.Color]::Black; $form.Opacity = 0.3 })
$form.Add_MouseUp({ 
    $endPos = $$.Location
    $script:selection = [Drawing.Rectangle]::FromLTRB([Math]::Min($startPos.X, $endPos.X), [Math]::Min($startPos.Y, $endPos.Y), [Math]::Max($startPos.X, $endPos.X), [Math]::Max($startPos.Y, $endPos.Y))
    $form.Close() 
})
$form.ShowDialog() | Out-Null
if ($selection.Width -gt 0) { Write-Output "$($selection.X),$($selection.Y),$($selection.Width),$($selection.Height)" }
'@ | Out-File "$InstallDir\selector.ps1" -Encoding utf8

# 5. SCRIPT DE GRABACIÓN (Audio Digital WASAPI + Micro)
$startScript = @"
`$area = powershell.exe -ExecutionPolicy Bypass -File "$InstallDir\selector.ps1"
if (!`$area) { exit }
`$c = `$area -split ','
& "$FFmpegExe" -y -f gdigrab -draw_mouse 1 -framerate 30 -offset_x `$c[0] -offset_y `$c[1] -video_size `$c[2]x`$c[3] -i desktop -f wasapi -i default -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p -movflags +faststart -c:a aac -b:a 192k "$VidDir\temp.mp4"
"@
$startScript | Out-File "$InstallDir\start.ps1" -Encoding utf8

# 6. SCRIPT DE EXPORTACIÓN Y SUBIDA
$exportScript = @"
Get-Process ffmpeg -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Milliseconds 800
`$TempFile = "$VidDir\temp.mp4"; if (!(Test-Path `$TempFile)) { exit }
`$Stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
`$format = `$args[0]
if (`$format -eq "gif") {
    `$OutputFile = "$VidDir\GIFS\recording_`$Stamp.gif"
    & "$FFmpegExe" -i `$TempFile -vf "mpdecimate,fps=12,scale=iw*0.8:-1:flags=lanczos,palettegen=max_colors=32" -y "$InstallDir\palette.png"
    & "$FFmpegExe" -i `$TempFile -i "$InstallDir\palette.png" -lavfi "mpdecimate,fps=12,scale=iw*0.8:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=1" -y `$OutputFile
} else {
    `$OutputFile = "$VidDir\MP4\recording_`$Stamp.mp4"
    Move-Item `$TempFile `$OutputFile -Force
}
`$Link = curl.exe -s -F "reqtype=fileupload" -F "time=72h" -F "fileToUpload=@`$OutputFile" https://litterbox.catbox.moe/resources/internals/api.php
Set-Clipboard -Value `$Link
(New-Object -ComObject WScript.Shell).Popup("Savin-Recorder: Link copiado", 2, "Hecho", 64)
"@
$exportScript | Out-File "$InstallDir\export.ps1" -Encoding utf8

# 7. ATAJOS (Versión v2 con Gancho Forzado)
$ahkPath = "$InstallDir\SavinHotkeys.ahk"
$ahkContent = "
#NoTrayIcon
#UseHook ; Fuerza a AHK a interceptar las teclas antes que Windows
$#+r::Run 'powershell.exe -WindowStyle Hidden -File ""$InstallDir\start.ps1""', , 'Hide'
<^>!g::Run 'powershell.exe -WindowStyle Hidden -File ""$InstallDir\export.ps1"" gif', , 'Hide'
<^>!h::Run 'powershell.exe -WindowStyle Hidden -File ""$InstallDir\export.ps1"" mp4', , 'Hide'
"
$ahkContent | Out-File $ahkPath -Encoding utf8

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$StartupFolder\SavinRecorder.lnk")
$Shortcut.TargetPath = $ahkPath
$Shortcut.Save()

Start-Process $ahkPath # Inicia los atajos ahora

Write-Host "`n✨ TODO LISTO Y LIBERADO ✨" -ForegroundColor Green
Write-Host "Usa Win+Shift+R para grabar. Windows ya no molestará."