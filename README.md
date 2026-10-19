# Smode MaximizeFix

*[Version française](README.fr.md)*

A small Windows tool for **Smode Compose** users who keep the **Windows taskbar at the top of the screen**
(StartAllBack, ExplorerPatcher, Windows 10...): when Smode is maximized, every click lands away from what is
shown (about the height of the taskbar). With this tool running, the maximize button simply works.

**This is not an official Smode Tech tool.** It does not change Smode in any way: it only moves Smode's window,
like you would by hand.

## The problem

With the taskbar at the top, maximizing Smode makes its interface react about one taskbar height away from where
you click. A normal (not maximized) window sized by hand to fill the screen below the taskbar works fine.

What happens (measured on a 3200x2000 screen at 200 %, taskbar 80 px high at the top): Windows places the
maximized window below the taskbar, but Smode draws as if the taskbar were not there: its drawing area starts at
the corner of the screen, `(0, 0)`, and is `3200 x 2080` px, instead of starting at `y = 80` (`3200 x 1920`). The
positions Smode reports to Windows accessibility are shifted the same way.

## What the tool does

When a Smode window is maximized on a screen whose taskbar is at the top or on the left, the tool turns it back
into a normal window that covers the whole work area of that screen (everything except the taskbar). You see a
full-screen Smode, and clicks land where they should.

- **Nothing runs inside Smode**: no Script, no cost on the frame rate.
- **No polling**: Windows notifies the tool when a window is shown or moved; it looks only at maximized windows of
  `Smode.exe` and does nothing on a screen whose taskbar is at the bottom or on the right.
- An **icon in the notification area** (blue square with an **S**, grey when paused) shows that it runs. Its menu:
  state (number of fixes), Pause / Resume, Fit Smode now, Start with Windows, Quit. The menu is in French when
  Windows is in French, in English otherwise.

## Tested with

- Smode Compose 15 (R15)
- Windows 11 (build 26200) with **StartAllBack**, taskbar at the top
- One screen, 3200 x 2000 at 200 % scaling

It should also work with other ways of putting the taskbar at the top or on the left (ExplorerPatcher, Windows 10,
...) and with several screens (each Smode window is fitted to the work area of its own screen), but these cases
were not tested. Feedback is welcome.

## Install

1. Copy `Smode_MaximizeFix.ps1` and `Smode_MaximizeFix.vbs` into a folder on a **local** disk, for example
   `%LOCALAPPDATA%\Smode MaximizeFix` (not on a removable disk if you want it to start with Windows).
2. Double-click `Smode_MaximizeFix.vbs`. The icon appears in the notification area (maybe among the hidden icons,
   under the `^` arrow).
3. Right-click the icon and tick **Start with Windows** if you want it to start with your session (this adds a
   shortcut named "Smode MaximizeFix" to your Startup folder).

Only one copy runs at a time. It uses Windows PowerShell 5.1, already part of Windows; the `.vbs` starts it
without any window, with `-ExecutionPolicy Bypass` for this script only.

## Uninstall

Right-click the icon, untick **Start with Windows**, then **Quit**, and delete the folder.

## Files

- `Smode_MaximizeFix.ps1` — the tool (PowerShell with a small C# part compiled at start). Saved as UTF-8 **with
  BOM**: keep the BOM if you edit it, Windows PowerShell 5.1 reads a file without it with the wrong encoding.
- `Smode_MaximizeFix.vbs` — starts the `.ps1` of the same folder without a console window.
- `maximizefix.log` — written next to the script: start, stop and each fix.

## License

MIT — see [LICENSE](LICENSE).
