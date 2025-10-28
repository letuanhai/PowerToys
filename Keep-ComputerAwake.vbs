' VBScript launcher for Keep-ComputerAwake.ps1
' This script launches the PowerShell script without showing a window
'
' Usage: Double-click this file from Windows Explorer, or run:
'        wscript Keep-ComputerAwake.vbs [parameters]
'
' Examples:
'   wscript Keep-ComputerAwake.vbs
'   wscript Keep-ComputerAwake.vbs -TimeMinutes 30
'   wscript Keep-ComputerAwake.vbs -ScreenOff

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get the directory where this VBS script is located
strScriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Path to the PowerShell script
strPowerShellScript = objFSO.BuildPath(strScriptPath, "Keep-ComputerAwake.ps1")

' Check if the PowerShell script exists
If Not objFSO.FileExists(strPowerShellScript) Then
    MsgBox "Error: Keep-ComputerAwake.ps1 not found in the same directory as this script!" & vbCrLf & vbCrLf & "Expected location: " & strPowerShellScript, vbCritical, "Keep Computer Awake"
    WScript.Quit 1
End If

' Get command line arguments if any
strArguments = ""
If WScript.Arguments.Count > 0 Then
    For i = 0 To WScript.Arguments.Count - 1
        strArguments = strArguments & " " & WScript.Arguments(i)
    Next
End If

' Build the PowerShell command
' -WindowStyle Hidden keeps the PowerShell window hidden
' -ExecutionPolicy Bypass allows the script to run without execution policy restrictions
' -NoProfile speeds up launch by not loading profile
strCommand = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File """ & strPowerShellScript & """" & strArguments

' Run the command hidden (0 = hidden window, True = wait for completion = False for async)
objShell.Run strCommand, 0, False

Set objFSO = Nothing
Set objShell = Nothing
