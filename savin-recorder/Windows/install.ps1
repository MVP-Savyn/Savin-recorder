# =========================================================
# SAVIN-RECORDER 3.2: INSTALADOR COMPLETO + AUTODECHECK
# =========================================================
$InstallDir = "$env:APPDATA\SavinRecorder"
$BinDir = "$InstallDir\bin"
$VidDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyVideos"), "SavinRecorder")
$FFmpegExe = "$BinDir\ffmpeg.exe"
$AHKScript = "$InstallDir\SavinHotkeys.ahk"

Clear-Host
Write-Host "--- Instalando Savin-Recorder 3.2 (Final Custom) ---" -ForegroundColor Cyan

# 1. PREPARAR ENTORNO (Debe ser lo primero para poder mover archivos)
New-Item -ItemType Directory -Path "$InstallDir", "$BinDir", "$VidDir\MP4", "$VidDir\GIFS" -Force | Out-Null

# 2. COMPROBACIÓN Y DESCARGA DE PAQUETES
Write-Host "[*] Comprobando paquetes..." -ForegroundColor Yellow

if (Get-Command winget -ErrorAction SilentlyContinue) {
    # Comprobar/Instalar FFmpeg
    if (!(Get-Command ffmpeg.exe -ErrorAction SilentlyContinue)) {
        Write-Host "[!] FFmpeg no detectado. Instalando..."
        winget install --id GYAN.FFmpeg --silent --accept-package-agreements --accept-source-agreements
    }

    # Comprobar/Instalar AutoHotkey v2
    if (!(Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue)) {
        Write-Host "[!] AutoHotkey v2 no detectado. Instalando..."
        winget install --id AutoHotkey.AutoHotkey --version 2.0.11 --silent --accept-package-agreements
    }
} else {
    Write-Host "[!] Winget no disponible. Verifica FFmpeg y AHK manualmente." -ForegroundColor Red
}

# 3. SINCRONIZAR FFMPEG A BIN LOCAL
if (!(Test-Path $FFmpegExe)) {
    $sysFF = (Get-Command ffmpeg.exe -ErrorAction SilentlyContinue).Source
    if ($sysFF) { 
        Copy-Item $sysFF $FFmpegExe -Force 
        Write-Host "[+] FFmpeg vinculado a bin local." -ForegroundColor Green
    }
}

# 4. MOTOR C# (SavinEngine.exe)
$source = @"
using System;
using System.Drawing;
using System.Windows.Forms;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class SavinRecorder : Form {
    private Point startPos;
    private Rectangle selection = Rectangle.Empty;
    private bool drawing = false;

    [DllImport("shell32.dll", SetLastError = true)]
    private static extern void SetCurrentProcessExplicitAppUserModelID([MarshalAs(UnmanagedType.LPWStr)] string AppID);

    [STAThread]
    public static void Main() {
        SetCurrentProcessExplicitAppUserModelID("Savin.Recorder.v3");
        Application.EnableVisualStyles();
        Application.Run(new SavinRecorder());
    }

    public SavinRecorder() {
        // 1. CONFIGURACIÓN VISUAL
        Rectangle totalArea = SystemInformation.VirtualScreen;
        this.StartPosition = FormStartPosition.Manual;
        this.Location = new Point(totalArea.Left, totalArea.Top);
        this.Size = new Size(totalArea.Width, totalArea.Height);
        this.FormBorderStyle = FormBorderStyle.None;
        this.BackColor = Color.Black;
        this.Opacity = 0.30;
        this.TopMost = true;
        this.ShowInTaskbar = false;
        this.KeyPreview = true;
        this.Cursor = Cursors.Cross;

        // 2. ELIMINAR PARPADEO (Double Buffer)
        this.SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.DoubleBuffer, true);
        this.UpdateStyles();

        // 3. EVENTOS
        this.KeyDown += (s, e) => { if (e.KeyCode == Keys.Escape) this.Close(); };
        this.MouseDown += (s, e) => { startPos = e.Location; drawing = true; };
        this.MouseMove += (s, e) => { if (drawing) { selection = GetRect(startPos, e.Location); this.Invalidate(); } };
        this.MouseUp += (s, e) => { 
            selection = GetRect(startPos, e.Location);
            if (selection.Width > 10 && selection.Height > 10) {
                selection.Offset(this.Location);
                StartGrabbing(selection);
            }
            this.Close(); 
        };

        // 4. DIBUJO DEL RECUADRO (Estilo ShareX)
        this.Paint += (s, e) => { 
            if (drawing) { 
                using (Pen pen = new Pen(Color.Cyan, 3)) { 
                    pen.DashStyle = System.Drawing.Drawing2D.DashStyle.Dash; 
                    e.Graphics.DrawRectangle(pen, selection); 
                } 
            } 
        };
    }

    private void StartGrabbing(Rectangle rect) {
        int w = rect.Width % 2 == 0 ? rect.Width : rect.Width - 1;
        int h = rect.Height % 2 == 0 ? rect.Height : rect.Height - 1;
        string ffmpegPath = "$($FFmpegExe.Replace('\','\\'))";
        string videoPath = "$($InstallDir.Replace('\','\\'))\\temp.mkv";
        string args = string.Format("-y -thread_queue_size 512 -f gdigrab -framerate 60 -offset_x {0} -offset_y {1} -video_size {2}x{3} -draw_mouse 1 -i desktop -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p \"{4}\"", rect.X, rect.Y, w, h, videoPath);
        Process p = new Process();
        p.StartInfo = new ProcessStartInfo { FileName = ffmpegPath, Arguments = args, UseShellExecute = false, CreateNoWindow = true };
        p.Start();
        p.PriorityClass = ProcessPriorityClass.AboveNormal; 
    }

    private Rectangle GetRect(Point p1, Point p2) { 
        return Rectangle.FromLTRB(Math.Min(p1.X, p2.X), Math.Min(p1.Y, p2.Y), Math.Max(p1.X, p2.X), Math.Max(p1.Y, p2.Y)); 
    }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -OutputAssembly "$InstallDir\SavinEngine.exe" -OutputType WindowsApplication
# 5. SCRIPT DE EXPORTACIÓN (Notificación con Carrete 🎞️)
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
`$def = '
using System;
using System.Runtime.InteropServices;
using System.Drawing;
public class IconLoader {
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr ExtractIcon(IntPtr hInst, string lpszExeFileName, int nIconIndex);
}'
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

# 6. AUTOHOTKEY v2 (Atajos)
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

# 7. REINICIO Y EJECUCIÓN (Búsqueda Exhaustiva)
Get-Process "SavinEngine" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process "AutoHotkey*" -ErrorAction SilentlyContinue | Stop-Process -Force

# Intentar localizar el ejecutable en múltiples rutas
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
    Write-Host "[+] AutoHotkey localizado en: $AHKPath" -ForegroundColor Gray
    Start-Process $AHKPath "`"$AHKScript`""
    Write-Host "V3.2 INSTALADA Y ACTIVA." -ForegroundColor Green
} else {
    Write-Host "--- AVISO ---" -ForegroundColor Yellow
    Write-Host "La instalacion de AHK es muy reciente. Por favor, cierra y abre de nuevo VS Code"
    Write-Host "o la terminal para refrescar las rutas de Windows."
    # Intento desesperado: usar el alias registrado
    Start-Process "AutoHotkey64.exe" "`"$AHKScript`"" -ErrorAction SilentlyContinue
}