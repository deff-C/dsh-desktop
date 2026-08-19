' DSH desktop launcher - double-click to open the app in a window.
' Runs the PowerShell launcher fully hidden (no console window).
' Resolves its own folder, so the whole DSH folder can be moved freely.
Set fso = CreateObject("Scripting.FileSystemObject")
base = fso.GetParentFolderName(WScript.ScriptFullName)
script = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & base & "\launcher.ps1"""
CreateObject("WScript.Shell").Run script, 0, False
