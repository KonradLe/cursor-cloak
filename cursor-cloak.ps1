param([string]$Mode = "on")

# cursor-cloak: hides the REAL system cursor during screen recording, while showing
# a "ghost" arrow only the user can see (window excluded from capture via
# WDA_EXCLUDEFROMCAPTURE). Recorders still track mouse POSITION, so program-cursor
# overlays and auto-zoom keep working. Shape is a GDI window Region (no layered
# color-key transparency - that combo made the window locally invisible on this PC).
# Click-through trick: window sits +1px off the hotspot, so clicks land on the app.
# Usage:  cursor-cloak.ps1 on | off   (test/ghost/overlay* = internal/diagnostic)

$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cur = Join-Path $dir "blank.cur"

# --- generate a fully transparent 32x32 .cur once ---
if (-not (Test-Path $cur)) {
    $b = New-Object byte[] 326
    $b[2]=2; $b[4]=1                      # ICONDIR: type=cursor, count=1
    $b[6]=32; $b[7]=32; $b[8]=2           # entry: 32x32, 2 colors
    $b[14]=0x30; $b[15]=0x01              # bytesInRes = 304
    $b[18]=22                             # image data offset
    $b[22]=40; $b[26]=32; $b[30]=64       # BITMAPINFOHEADER: size=40, w=32, h=64(XOR+AND)
    $b[34]=1; $b[36]=1                    # planes=1, 1bpp
    $b[66]=255; $b[67]=255; $b[68]=255    # palette: black, white
    for($i=198; $i -lt 326; $i++){ $b[$i]=255 }   # AND mask all 1 => transparent
    [IO.File]::WriteAllBytes($cur, $b)
}

$src = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class CursorBlank {
    [DllImport("user32.dll")] static extern IntPtr LoadCursorFromFile(string path);
    [DllImport("user32.dll")] static extern bool SetSystemCursor(IntPtr hcur, uint id);
    [DllImport("user32.dll")] static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);
    // arrow, ibeam, hand, wait, appstarting, sizeall, sizenesw, sizens, sizenwse, sizewe, cross, no
    static uint[] ids = new uint[] {32512,32513,32649,32514,32650,32646,32643,32645,32642,32644,32515,32648};
    public static void Blank(string curPath) {
        foreach (uint id in ids) {
            IntPtr h = LoadCursorFromFile(curPath);
            if (h != IntPtr.Zero) SetSystemCursor(h, id);
        }
    }
    public static void Restore() { SystemParametersInfo(0x0057, 0, IntPtr.Zero, 0); } // SPI_SETCURSORS
}

public class CloakOverlay : Form {
    [DllImport("user32.dll")] static extern bool SetWindowDisplayAffinity(IntPtr hwnd, uint affinity);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    public static bool NoAffinity = false;  // diagnostic: skip capture-exclusion
    public static int Off = 1;              // offset from hotspot (1 = production, 24 = visible in tests)
    Timer t;
    static readonly Point[] pts = new Point[] {
        new Point(1,1), new Point(1,24), new Point(7,19), new Point(11,29),
        new Point(15,27), new Point(11,18), new Point(18,17)
    };
    public CloakOverlay() {
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.Manual;
        TopMost = true; ShowInTaskbar = false;
        Size = new Size(26, 36);
        BackColor = Color.Black;            // shows as the outline at region edges
        GraphicsPath gp = new GraphicsPath();
        gp.AddPolygon(pts);
        Region = new Region(gp);            // window IS the arrow shape (plain GDI, no layering)
        t = new Timer(); t.Interval = 10;
        t.Tick += delegate {
            Point p = Cursor.Position;
            // +Off so the hotspot stays OUTSIDE the window -> clicks/hover hit the app below
            SetWindowPos(Handle, HWND_TOPMOST, p.X + Off, p.Y + Off, 0, 0, 0x0001 | 0x0010); // NOSIZE|NOACTIVATE
        };
        t.Start();
    }
    protected override CreateParams CreateParams {
        // WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE
        get { CreateParams cp = base.CreateParams; cp.ExStyle |= 0x80 | 0x08000000; return cp; }
    }
    protected override void OnShown(EventArgs e) {
        base.OnShown(e);
        if (!NoAffinity) SetWindowDisplayAffinity(Handle, 0x11); // WDA_EXCLUDEFROMCAPTURE
    }
    protected override void OnPaint(PaintEventArgs e) {
        e.Graphics.FillPolygon(Brushes.White, pts);
        e.Graphics.DrawPolygon(new Pen(Color.Black, 2f), pts);
    }
}
"@
Add-Type -TypeDefinition $src -ReferencedAssemblies "System.Windows.Forms","System.Drawing"

function Get-OverlayProc {
    # match ONLY real overlay children: "...cursor-cloak.ps1 overlay[-x]" as launch args
    # (a loose 'overlay' match once killed the session that merely mentioned the word)
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
        Where-Object { $_.CommandLine -match 'cursor-cloak\.ps1[''"]?\s+overlay' }
}
function Start-Overlay([string]$SubMode) {
    Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File",$PSCommandPath,$SubMode
}

switch ($Mode) {
  "overlay" {          # production: capture-excluded, 1px offset
      [System.Windows.Forms.Application]::Run((New-Object CloakOverlay))
  }
  "overlay-test" {     # diagnostic: NOT excluded (screenshots see it), big offset
      [CloakOverlay]::NoAffinity = $true; [CloakOverlay]::Off = 24
      [System.Windows.Forms.Application]::Run((New-Object CloakOverlay))
  }
  "overlay-ghost" {    # diagnostic: excluded like production, but big offset (user-visibility check)
      [CloakOverlay]::Off = 24
      [System.Windows.Forms.Application]::Run((New-Object CloakOverlay))
  }
  "test"  { Start-Overlay "overlay-test";  Write-Output "TEST: widmo bez wykluczenia (widoczne dla zrzutow), offset 24px." }
  "ghost" { Start-Overlay "overlay-ghost"; Write-Output "GHOST: widmo z wykluczeniem z capture, offset 24px, kursor NIE ukryty." }
  "on" {
      if (-not (Get-OverlayProc)) {
          Start-Overlay "overlay"
          Start-Sleep -Milliseconds 900
      }
      if (Get-OverlayProc) {
          [CursorBlank]::Blank($cur)
          Write-Output "CLOAK ON: prawdziwy kursor ukryty, strzalka-widmo aktywna."
      } else {
          Write-Output "BLAD: nakladka nie wystartowala - kursora NIE ukrywam (bezpiecznik)."
      }
  }
  "off" {
      [CursorBlank]::Restore()
      Get-OverlayProc | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
      Write-Output "CLOAK OFF: systemowy kursor przywrocony."
  }
}
