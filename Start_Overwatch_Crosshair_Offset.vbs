Option Explicit
Dim shell, fso, scriptFile, psFile, command
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptFile = WScript.ScriptFullName
psFile = fso.BuildPath(fso.GetParentFolderName(scriptFile), "Overwatch_Res_Offset.ps1")
If Not fso.FileExists(psFile) Then
  MsgBox "Missing Overwatch_Res_Offset.ps1 in the same folder.", vbCritical, "Overwatch Clearer Crosshairs"
  WScript.Quit 1
End If
If Not IsOverwatchRunning() Then
  MsgBox "Please launch Overwatch in Windowed or Borderless Windowed mode first, then double-click this launcher.", vbInformation, "Overwatch Clearer Crosshairs"
  WScript.Quit 1
End If
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & Chr(34) & psFile & Chr(34)
shell.Run command, 0, False

Function IsOverwatchRunning()
  Dim wmi, processes
  Set wmi = GetObject("winmgmts:\\.\root\cimv2")
  Set processes = wmi.ExecQuery("Select ProcessId From Win32_Process Where Name = 'Overwatch.exe'")
  IsOverwatchRunning = (processes.Count > 0)
End Function
