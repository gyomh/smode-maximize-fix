' Smode MaximizeFix - starts Smode_MaximizeFix.ps1 (same folder) without any window
Set sh = CreateObject("WScript.Shell")
dir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & dir & "\Smode_MaximizeFix.ps1""", 0, False
