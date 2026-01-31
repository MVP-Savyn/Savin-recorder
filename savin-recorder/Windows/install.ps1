# =========================================================
# SAVIN-RECORDER 3.2: CARRETE 🎞️ + ABRIR CARPETA (AltGr+O)
# =========================================================
$InstallDir = "$env:APPDATA\SavinRecorder"
$BinDir = "$InstallDir\bin"
$VidDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyVideos"), "SavinRecorder")
$FFmpegExe = "$BinDir\ffmpeg.exe"

Clear-Host
Write-Host "--- Instalando Savin-Recorder 3.2 (Final Custom) ---" -ForegroundColor Cyan

# 1. Preparar Entorno
New-Item -ItemType Directory -Path "$InstallDir", "$BinDir", "$VidDir\MP4", "$VidDir\GIFS" -Force | Out-Null

# 2. MOTOR C# (SavinEngine.exe)
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
        this.Paint += (s, e) => { if (drawing) { using (Pen pen = new Pen(Color.Red, 2)) e.Graphics.DrawRectangle(pen, selection); } };
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
    private Rectangle GetRect(Point p1, Point p2) { return Rectangle.FromLTRB(Math.Min(p1.X, p2.X), Math.Min(p1.Y, p2.Y), Math.Max(p1.X, p2.X), Math.Max(p1.Y, p2.Y)); }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" -OutputAssembly "$InstallDir\SavinEngine.exe" -OutputType WindowsApplication

# 4. SCRIPT DE EXPORTACIÓN (Notificación con Carrete 🎞️)
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

# NOTIFICACIÓN CON ICONO DE CARRETE (Index 170 de shell32)
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

[System.IO.File]::WriteAllLines("$InstallDir\export.ps1", $exportScript)

# 5. AutoHotkey v2 (Atajos: Win+Shift+R, AltGr+G, AltGr+H, AltGr+O)
$ahkPath = "$InstallDir\SavinHotkeys.ahk"
$ahkContent = @"
#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force

; Grabar Región
#+r::Run('"$InstallDir\SavinEngine.exe"')

; Exportar GIF
<^>!g::Run('powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "$InstallDir\export.ps1" gif', , "Hide")

; Exportar MP4
<^>!h::Run('powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "$InstallDir\export.ps1" mp4', , "Hide")

; ABRIR CARPETA DE VIDEOS
<^>!o::Run('explorer.exe "$VidDir"')
"@
[System.IO.File]::WriteAllText($ahkPath, $ahkContent)

# 6. Reinicio
Get-Process "SavinEngine" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process "AutoHotkey*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $ahkPath

Write-Host "V3.2 INSTALADA. Atajos: Win+Shift+R (Grabar), AltGr+H (MP4), AltGr+G (GIF), AltGr+O (Carpeta)." -ForegroundColor Green