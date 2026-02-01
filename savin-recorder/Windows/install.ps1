# =========================================================
# SAVIN-RECORDER 3.4: AUTO-AUDIO (DIRECT DOWNLOAD)
# =========================================================
$InstallDir = "$env:APPDATA\SavinRecorder"
$BinDir = "$InstallDir\bin"
$VidDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyVideos"), "SavinRecorder")
$FFmpegExe = "$BinDir\ffmpeg.exe"
$AHKScript = "$InstallDir\SavinHotkeys.ahk"

Clear-Host
Write-Host "--- Instalando Savin-Recorder 3.4 (Auto-Audio) ---" -ForegroundColor Cyan

# 1. PREPARAR ENTORNO
New-Item -ItemType Directory -Path "$InstallDir", "$BinDir", "$VidDir\MP4", "$VidDir\GIFS" -Force | Out-Null

# 2. COMPROBACIÓN Y DESCARGA DE PAQUETES
$NecesitaReinicio = $false
Write-Host "[*] Comprobando paquetes..." -ForegroundColor Yellow

if (Get-Command winget -ErrorAction SilentlyContinue) {
    if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "[!] FFmpeg no detectado. Instalando..."
        winget install --id GYAN.FFmpeg --silent --accept-package-agreements --accept-source-agreements
        # --- REFRESCAR PATH PARA ESTA SESIÓN ---
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    if (!(Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue)) {
        Write-Host "[!] AutoHotkey v2 no detectado. Instalando..."
        winget install --id AutoHotkey.AutoHotkey --version 2.0.11 --silent --accept-package-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
}

# MÉTODO AUTOMÁTICO PARA EL DRIVER DE AUDIO (v0.13.3)
# Usamos el comando completo para evitar el error si el PATH fallara
$ffmpegCmd = if (Get-Command ffmpeg -ErrorAction SilentlyContinue) { "ffmpeg" } else { "ffmpeg.exe" }

$driverCheck = & $ffmpegCmd -list_devices true -f dshow -i dummy 2>&1 | Select-String "virtual-audio-capturer"

if (!$driverCheck) {
    Write-Host "[!] Driver de Audio no detectado. Descargando..." -ForegroundColor Cyan
    $Url = "https://github.com/rdp/screen-capture-recorder-to-video-windows-free/releases/download/v0.13.3/Setup.Screen.Capturer.Recorder.v0.13.3.exe"
    $Dest = "$env:TEMP\audio_driver.exe"
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.DownloadFile($Url, $Dest)
        
        if (Test-Path $Dest) {
            Write-Host "[*] Instalando driver en segundo plano..." -ForegroundColor Yellow
            Start-Process -FilePath $Dest -ArgumentList "/S" -Wait
            Remove-Item $Dest
            $NecesitaReinicio = $true
            Write-Host "[+] Driver instalado correctamente." -ForegroundColor Green
        }
    } catch {
        Write-Host "[!] Error crítico en descarga: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 3. SINCRONIZAR FFMPEG A BIN LOCAL
if (!(Test-Path $FFmpegExe)) {
    $sysFF = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
    if ($sysFF) { 
        Copy-Item $sysFF $FFmpegExe -Force 
        Write-Host "[+] FFmpeg vinculado a bin local." -ForegroundColor Green
    } else {
        Write-Host "[!] Error: No se pudo localizar ffmpeg en el sistema para vincularlo." -ForegroundColor Red
    }
}
# 4. MOTOR C# (SavinEngine.exe) - GUIONES ESTÁTICOS (SIN MOVIMIENTO)
$source = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class SavinRecorder : Form {
    private Point startPos;
    private Rectangle selection = Rectangle.Empty;
    private bool drawing = false;

    [STAThread]
    public static void Main() {
        Application.EnableVisualStyles();
        Application.Run(new SavinRecorder());
    }

    public SavinRecorder() {
        this.DoubleBuffered = true;
        this.FormBorderStyle = FormBorderStyle.None;
        this.StartPosition = FormStartPosition.Manual;
        this.Location = new Point(SystemInformation.VirtualScreen.Left, SystemInformation.VirtualScreen.Top);
        this.Size = new Size(SystemInformation.VirtualScreen.Width, SystemInformation.VirtualScreen.Height);
        
        this.BackColor = Color.Black;
        this.Opacity = 0.50; 
        this.TopMost = true;
        this.ShowInTaskbar = false;
        this.Cursor = Cursors.Cross;

        this.KeyDown += (s, e) => { if (e.KeyCode == Keys.Escape) this.Close(); };
        this.MouseDown += (s, e) => { startPos = e.Location; drawing = true; };
        this.MouseMove += (s, e) => { 
            if (drawing) { 
                selection = GetRect(startPos, e.Location); 
                ActualizarAgujero();
                this.Invalidate(); 
            } 
        };
        this.MouseUp += (s, e) => { 
            drawing = false;
            if (selection.Width > 10 && selection.Height > 10) { StartGrabbing(selection); }
            this.Close(); 
        };
    }

    private void ActualizarAgujero() {
        Region r = new Region(new Rectangle(0, 0, this.Width, this.Height));
        if (selection.Width > 0 && selection.Height > 0) {
            r.Exclude(selection);
        }
        this.Region = r;
    }

    protected override void OnPaint(PaintEventArgs e) {
        if (drawing && selection.Width > 0 && selection.Height > 0) {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.None; 

            using (Pen pen = new Pen(Color.White, 2)) {
                pen.DashStyle = DashStyle.Dash;
                pen.DashPattern = new float[] { 8, 8 };
                
                // EL TRUCO: Fijamos el desfase a 0 para que los puntos no "bailen"
                pen.DashOffset = 0;

                // Dibujamos las 4 líneas por separado para control total
                int x = selection.X - 1;
                int y = selection.Y - 1;
                int w = selection.Width + 1;
                int h = selection.Height + 1;

                g.DrawLine(pen, x, y, x + w, y);         // Arriba
                g.DrawLine(pen, x, y + h, x + w, y + h); // Abajo
                g.DrawLine(pen, x, y, x, y + h);         // Izquierda
                g.DrawLine(pen, x + w, y, x + w, y + h); // Derecha
            }

            string resText = string.Format("{0} x {1}", selection.Width, selection.Height);
            using (Font font = new Font("Segoe UI", 9, FontStyle.Bold)) {
                Size textSize = TextRenderer.MeasureText(resText, font);
                int posX = selection.Right - textSize.Width;
                int posY = selection.Bottom + 5;
                if (posY + textSize.Height > this.Height) posY = selection.Top - textSize.Height - 5;
                
                g.FillRectangle(Brushes.Black, new Rectangle(posX, posY, textSize.Width, textSize.Height));
                g.DrawString(resText, font, Brushes.White, new Point(posX, posY));
            }
        }
    }

    private void StartGrabbing(Rectangle rect) {
        int w = rect.Width % 2 == 0 ? rect.Width : rect.Width - 1;
        int h = rect.Height % 2 == 0 ? rect.Height : rect.Height - 1;
        string ffmpegPath = "$($FFmpegExe.Replace('\','\\'))";
        string videoPath = "$($InstallDir.Replace('\','\\'))\\temp.mkv";
        string args = string.Format("-y -rtbufsize 150M -f gdigrab -framerate 60 -offset_x {0} -offset_y {1} -video_size {2}x{3} -draw_mouse 1 -i desktop -f dshow -i audio=\"virtual-audio-capturer\" -af \"aresample=44100,volume=0.9\" -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -ar 44100 -ac 2 \"{4}\"", rect.X, rect.Y, w, h, videoPath);
        Process p = new Process();
        p.StartInfo = new ProcessStartInfo { FileName = ffmpegPath, Arguments = args, UseShellExecute = false, CreateNoWindow = true };
        p.Start();
    }

    private Rectangle GetRect(Point p1, Point p2) { return Rectangle.FromLTRB(Math.Min(p1.X, p2.X), Math.Min(p1.Y, p2.Y), Math.Max(p1.X, p2.X), Math.Max(p1.Y, p2.Y)); }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -OutputAssembly "$InstallDir\SavinEngine.exe" -OutputType WindowsApplication

# 5. EXPORTACIÓN
$exportScript = @"
taskkill /IM ffmpeg.exe /T /F 2>`$null
`$TempMKV = "$InstallDir\temp.mkv"
if (!(Test-Path `$TempMKV)) { exit }
`$Stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
`$format = `$args[0]

if (`$format -eq "gif") {
    `$OutputFile = "$VidDir\GIFS\rec_`$Stamp.gif"
    & "$FFmpegExe" -i `$TempMKV -vf "mpdecimate,fps=12,scale=800:-1:flags=lanczos,palettegen" -y "$InstallDir\palette.png"
    & "$FFmpegExe" -i `$TempMKV -i "$InstallDir\palette.png" -lavfi "mpdecimate,fps=12,scale=800:-1:flags=lanczos [x]; [x][1:v] paletteuse" -y `$OutputFile
} else {
    `$OutputFile = "$VidDir\MP4\rec_`$Stamp.mp4"
    & "$FFmpegExe" -i `$TempMKV -r 60 -c:v libx264 -crf 18 -pix_fmt yuv420p -profile:v baseline -level 3.0 -movflags +faststart -y `$OutputFile
}

`$Link = curl.exe -F "file=@`$OutputFile" https://0x0.st
Set-Clipboard -Value `$Link

Add-Type -AssemblyName System.Windows.Forms
`$def = 'using System; using System.Runtime.InteropServices; using System.Drawing; public class IconLoader { [DllImport("shell32.dll", CharSet = CharSet.Auto)] public static extern IntPtr ExtractIcon(IntPtr hInst, string lpszExeFileName, int nIconIndex); }'
if (!([System.Management.Automation.PSTypeName]'IconLoader').Type) { Add-Type -TypeDefinition `$def -ReferencedAssemblies "System.Drawing" }
`$iconPtr = [IconLoader]::ExtractIcon(0, "shell32.dll", 170)
`$cinemaIcon = [System.Drawing.Icon]::FromHandle(`$iconPtr)
`$notification = New-Object System.Windows.Forms.NotifyIcon
`$notification.Icon = `$cinemaIcon
`$notification.BalloonTipTitle = "Savin-Recorder"
`$notification.BalloonTipText = "Link copiado al portapapeles"
`$notification.Visible = `$true
`$notification.ShowBalloonTip(3000)
Start-Sleep -Seconds 3
`$notification.Dispose()
"@
[System.IO.File]::WriteAllText("$InstallDir\export.ps1", $exportScript)

# 6. ATAJOS
$ahkContent = @"
#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force
#+r::Run('"$InstallDir\SavinEngine.exe"')
<^>!g::Run('powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "$InstallDir\export.ps1" gif', , "Hide")
<^>!h::Run('powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "$InstallDir\export.ps1" mp4', , "Hide")
<^>!o::Run('explorer.exe "$VidDir"')
"@
[System.IO.File]::WriteAllText($AHKScript, $ahkContent)

# 7. REINICIO Y EJECUCIÓN
Get-Process "SavinEngine" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process "AutoHotkey*" -ErrorAction SilentlyContinue | Stop-Process -Force

$AHKPath = (Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue).Source
if (!$AHKPath) {
    $CommonPaths = @(
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
        "$env:ProgramFiles\AutoHotkey\AutoHotkey64.exe",
        "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
    )
    foreach ($Path in $CommonPaths) {
        if (Test-Path $Path) { $AHKPath = $Path; break }
    }
}

if ($AHKPath) {
    Start-Process $AHKPath "`"$AHKScript`""
    Write-Host "V3.4 INSTALADA CON AUDIO AUTOMÁTICO." -ForegroundColor Green
} else {
    Start-Process "AutoHotkey64.exe" "`"$AHKScript`"" -ErrorAction SilentlyContinue
}

# 8. REINICIO FINAL (SOLO SI ES NECESARIO)
if ($NecesitaReinicio) {
    Add-Type -AssemblyName System.Windows.Forms
    $msg = "Se ha instalado el driver de audio. Es necesario reiniciar para que el sistema lo reconozca.`n`n¿Deseas reiniciar ahora?"
    $title = "Savin-Recorder: Reinicio Requerido"
    $result = [System.Windows.Forms.MessageBox]::Show($msg, $title, "YesNo", "Question")
    
    if ($result -eq "Yes") {
        Restart-Computer -Force
    } else {
        Write-Host "[!] Reinicio pospuesto. El audio no funcionará hasta que reinicies manualmente." -ForegroundColor Yellow
    }
} else {
    Write-Host "V3.4 INSTALADA. Driver ya presente, no hace falta reiniciar." -ForegroundColor Green
}