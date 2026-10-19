# =====================================================================================================
#  Smode MaximizeFix  V1.0  (18/10/2026)  -  Guillaume (gyomh)
#
#  With the Windows taskbar at the top (or on the left) of a screen, Smode's maximized window draws as if
#  the taskbar were not there: its client area starts at the corner of the screen (seen: (0,0) 3200x2080
#  instead of (0,80) 3200x1920), so every click lands about the height of the taskbar away from what is
#  shown. A normal (not maximized) window covering the work area is handled correctly by Smode.
#
#  This tool turns a maximized Smode window back into a normal window that covers the work area of its
#  screen. Event driven, no polling: Windows tells the tool when a window is shown or moved; it only acts on
#  maximized windows of Smode.exe on a screen whose taskbar is at the top or on the left. Nothing runs inside
#  Smode (no Script, no frame cost).
#
#  Icon in the notification area: state, pause, fit Smode now, start with Windows, quit (menu in French when
#  Windows is in French, in English otherwise).
#  Launched hidden by Smode_MaximizeFix.vbs. Log: maximizefix.log next to this file (start, stop, corrections).
#
#  HISTORY
#  V1.0 - 18/10/2026 - First version.
# =====================================================================================================
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# One instance only
$created = $false
$mutex = New-Object System.Threading.Mutex($false, 'Local\SmodeMaximizeFix', [ref]$created)
if (-not $created) { exit }

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
public static class SmodeFix {
  delegate void WinEventProc(IntPtr hook, uint ev, IntPtr hwnd, int idObject, int idChild, uint thread, uint time);
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern IntPtr SetWinEventHook(uint min, uint max, IntPtr mod, WinEventProc fn, uint pid, uint tid, uint flags);
  [DllImport("user32.dll")] static extern bool UnhookWinEvent(IntPtr hook);
  [DllImport("user32.dll")] static extern bool IsZoomed(IntPtr h);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr h, uint flags);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern IntPtr MonitorFromWindow(IntPtr h, uint flags);
  [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr m, ref MONITORINFO mi);
  [DllImport("user32.dll")] static extern bool ShowWindowAsync(IntPtr h, int cmd);
  [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hh, uint flags);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc fn, IntPtr l);
  [DllImport("user32.dll")] static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
  [StructLayout(LayoutKind.Sequential)] struct RECT { public int left, top, right, bottom; }
  [StructLayout(LayoutKind.Sequential)] struct MONITORINFO { public int cbSize; public RECT monitor; public RECT work; public uint flags; }

  static WinEventProc keep;
  static IntPtr hookShow, hookMove;
  static readonly Dictionary<uint, bool> smodePids = new Dictionary<uint, bool>();
  public static bool Paused;
  public static int Fixed;
  public static string Last = "";
  public static string LogPath = "";

  public static void Start() {
    SetThreadDpiAwarenessContext(new IntPtr(-4));          // physical pixels on every screen (per monitor v2)
    keep = OnEvent;
    // Out of context (the callback runs in this thread's message loop), not for our own windows
    hookShow = SetWinEventHook(0x8002, 0x8002, IntPtr.Zero, keep, 0, 0, 0x0002);   // EVENT_OBJECT_SHOW
    hookMove = SetWinEventHook(0x800B, 0x800B, IntPtr.Zero, keep, 0, 0, 0x0002);   // EVENT_OBJECT_LOCATIONCHANGE
  }

  public static void Stop() {
    if (hookShow != IntPtr.Zero) UnhookWinEvent(hookShow);
    if (hookMove != IntPtr.Zero) UnhookWinEvent(hookMove);
  }

  static void OnEvent(IntPtr hook, uint ev, IntPtr hwnd, int idObject, int idChild, uint thread, uint time) {
    // Most events are cursors, carets or child objects: only a maximized window itself is looked at
    if (Paused || idObject != 0 || idChild != 0 || hwnd == IntPtr.Zero || !IsZoomed(hwnd)) return;
    Fix(hwnd);
  }

  static bool IsSmode(IntPtr hwnd) {
    if (GetAncestor(hwnd, 2) != hwnd || !IsWindowVisible(hwnd)) return false;      // top-level windows only
    uint pid;
    GetWindowThreadProcessId(hwnd, out pid);
    bool smode;
    if (!smodePids.TryGetValue(pid, out smode)) {
      try { smode = Process.GetProcessById((int)pid).ProcessName.Equals("Smode", StringComparison.OrdinalIgnoreCase); }
      catch { smode = false; }
      if (smodePids.Count > 200) smodePids.Clear();
      smodePids[pid] = smode;
    }
    return smode;
  }

  // A maximized Smode window on a screen whose taskbar is at the top / on the left: back to a normal window
  // covering the work area. Returns true when the window was changed.
  public static bool Fix(IntPtr hwnd) {
    if (!IsZoomed(hwnd) || !IsSmode(hwnd)) return false;
    var mi = new MONITORINFO();
    mi.cbSize = Marshal.SizeOf(mi);
    if (!GetMonitorInfo(MonitorFromWindow(hwnd, 2), ref mi)) return false;
    if (mi.work.top == mi.monitor.top && mi.work.left == mi.monitor.left) return false;   // Smode is right there
    ShowWindowAsync(hwnd, 9);                                                              // SW_RESTORE
    SetWindowPos(hwnd, IntPtr.Zero, mi.work.left, mi.work.top, mi.work.right - mi.work.left,
                 mi.work.bottom - mi.work.top, 0x0004 | 0x0010 | 0x4000);                 // NOZORDER NOACTIVATE ASYNC
    Fixed++;
    Last = DateTime.Now.ToString("HH:mm:ss");
    try {
      File.AppendAllText(LogPath, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " Smode window fitted to the work area (" +
                         mi.work.left + "," + mi.work.top + " " + (mi.work.right - mi.work.left) + "x" + (mi.work.bottom - mi.work.top) + ")\r\n");
    } catch { }
    return true;
  }

  public static int FixAll() {
    int n = 0;
    EnumWindows((h, l) => { if (Fix(h)) n++; return true; }, IntPtr.Zero);
    return n;
  }
}
'@

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$fr = (Get-UICulture).TwoLetterISOLanguageName -eq 'fr'
function T($french, $english) { if ($script:fr) { $french } else { $english } }
$logFile = Join-Path $here 'maximizefix.log'
function Log($msg) { try { Add-Content -Path $logFile -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $msg) -Encoding UTF8 } catch {} }

# ---------- start with Windows: a shortcut in the Startup folder ----------
$startupLnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Smode MaximizeFix.lnk'
function Set-Startup($on) {
  if ($on) {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($startupLnk)
    $lnk.TargetPath = Join-Path $env:WINDIR 'System32\wscript.exe'
    $lnk.Arguments = '"' + (Join-Path $here 'Smode_MaximizeFix.vbs') + '"'
    $lnk.WorkingDirectory = $here
    $lnk.Description = 'Smode MaximizeFix'
    $lnk.Save()
  } elseif (Test-Path $startupLnk) { Remove-Item $startupLnk -Force }
}

# ---------- icon: a small blue square with a white S and a frame ----------
function New-Icon($paused) {
  $bmp = New-Object System.Drawing.Bitmap 32, 32
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.TextRenderingHint = 'AntiAliasGridFit'
  $color = if ($paused) { [System.Drawing.Color]::FromArgb(120, 120, 120) } else { [System.Drawing.Color]::FromArgb(47, 129, 247) }
  $g.FillRectangle((New-Object System.Drawing.SolidBrush $color), 1, 1, 30, 30)
  $g.DrawRectangle((New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 2), 3, 3, 25, 25)
  $font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
  $g.DrawString('S', $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(0, 1, 32, 32)), $fmt)
  $g.Dispose()
  return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

# ---------- notification area ----------
[SmodeFix]::LogPath = $logFile
[SmodeFix]::Start()
Log 'started'
$iconOn = New-Icon $false
$iconOff = New-Icon $true
$ni = New-Object System.Windows.Forms.NotifyIcon
$ni.Icon = $iconOn
$ni.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$miState = $menu.Items.Add('')
$miState.Enabled = $false
[void]$menu.Items.Add('-')
$miPause = $menu.Items.Add((T 'Mettre en pause' 'Pause'))
$miFix = $menu.Items.Add((T 'Recaler Smode maintenant' 'Fit Smode now'))
$miStartup = New-Object System.Windows.Forms.ToolStripMenuItem (T 'Lancer au démarrage de Windows' 'Start with Windows')
[void]$menu.Items.Add($miStartup)
[void]$menu.Items.Add('-')
$miQuit = $menu.Items.Add((T 'Quitter' 'Quit'))
$ni.ContextMenuStrip = $menu

function Update-State {
  $n = [SmodeFix]::Fixed
  $txt = if ([SmodeFix]::Paused) { T 'En pause' 'Paused' } else { T 'Actif' 'Active' }
  $txt += if ($n) { (T " - $n correction(s), dernière à " " - $n fix(es), last at ") + [SmodeFix]::Last } else { T ' - aucune correction' ' - no fix yet' }
  $miState.Text = $txt
  $miPause.Text = if ([SmodeFix]::Paused) { T 'Reprendre' 'Resume' } else { T 'Mettre en pause' 'Pause' }
  $miStartup.Checked = Test-Path $startupLnk
  $tip = 'Smode MaximizeFix : ' + $txt
  if ($tip.Length -gt 63) { $tip = $tip.Substring(0, 63) }      # limit of a notification icon text
  $ni.Text = $tip
  $ni.Icon = if ([SmodeFix]::Paused) { $iconOff } else { $iconOn }
}

$menu.add_Opening({ Update-State })
$miPause.add_Click({
  [SmodeFix]::Paused = -not [SmodeFix]::Paused
  Log ($(if ([SmodeFix]::Paused) { 'paused' } else { 'resumed' }))
  if (-not [SmodeFix]::Paused) { [void][SmodeFix]::FixAll() }
  Update-State
})
$miFix.add_Click({
  $n = [SmodeFix]::FixAll()
  Update-State
  $msg = if ($n) { T 'Fenêtre de Smode recalée sur la zone utile de l''écran.' 'Smode window fitted to the work area of the screen.' } else { T 'Aucune fenêtre de Smode agrandie à corriger.' 'No maximized Smode window to fix.' }
  $ni.ShowBalloonTip(2500, 'Smode MaximizeFix', $msg, 'Info')
})
$miStartup.add_Click({
  Set-Startup (-not (Test-Path $startupLnk))
  Update-State
})
$miQuit.add_Click({
  [SmodeFix]::Stop()
  Log ('stopped, ' + [SmodeFix]::Fixed + ' correction(s)')
  $ni.Visible = $false
  $ni.Dispose()
  [System.Windows.Forms.Application]::Exit()
})
$ni.add_MouseClick({ param($s, $e) if ($e.Button -eq 'Left') { Update-State; $ni.ShowBalloonTip(2000, 'Smode MaximizeFix', $miState.Text, 'Info') } })

# A Smode window already maximized when the tool starts
$first = [SmodeFix]::FixAll()
if ($first) { Log "fixed $first window(s) at start" }
Update-State

[System.Windows.Forms.Application]::Run()
$mutex.ReleaseMutex()
