<#
.SYNOPSIS
    Keeps the computer awake with screen on using Windows SetThreadExecutionState API.
    Based on PowerToys Awake implementation.

.DESCRIPTION
    This script prevents the computer and display from sleeping by using the same
    Windows API approach as PowerToys Awake (SetThreadExecutionState). It includes
    a system tray icon for easy control and monitoring.

.PARAMETER TimeMinutes
    Duration in minutes to keep the computer awake. If not specified, runs indefinitely.

.PARAMETER ScreenOff
    If specified, allows the screen to turn off while keeping the system awake.

.PARAMETER NoTray
    If specified, runs without system tray icon.

.EXAMPLE
    .\Keep-ComputerAwake.ps1
    Keeps computer and screen awake indefinitely with system tray icon.

.EXAMPLE
    .\Keep-ComputerAwake.ps1 -TimeMinutes 30
    Keeps computer and screen awake for 30 minutes.

.EXAMPLE
    .\Keep-ComputerAwake.ps1 -ScreenOff
    Keeps computer awake indefinitely but allows screen to turn off.

.NOTES
    Author: Based on PowerToys Awake implementation
    Requires: PowerShell 5.1 or higher, Windows OS
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$TimeMinutes,

    [Parameter(Mandatory = $false)]
    [switch]$ScreenOff,

    [Parameter(Mandatory = $false)]
    [switch]$NoTray
)

# Ensure we're running on Windows
if ($PSVersionTable.PSVersion.Major -lt 5 -or -not $IsWindows -and $PSVersionTable.PSVersion.Major -ge 6) {
    Write-Error "This script requires Windows operating system."
    exit 1
}

# Add Windows Forms and Drawing assemblies for system tray support
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Hide the PowerShell console window
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WindowHelper
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    public const int SW_HIDE = 0;
    public const int SW_SHOW = 5;
}
"@

# Hide the console window immediately if not in NoTray mode
if (-not $NoTray) {
    $consolePtr = [WindowHelper]::GetConsoleWindow()
    [WindowHelper]::ShowWindow($consolePtr, [WindowHelper]::SW_HIDE) | Out-Null
}

# Define the SetThreadExecutionState P/Invoke signature
# This is the same approach used by PowerToys Awake
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class PowerManagement
{
    [FlagsAttribute]
    public enum ExecutionState : uint
    {
        ES_AWAYMODE_REQUIRED = 0x00000040,
        ES_CONTINUOUS = 0x80000000,
        ES_DISPLAY_REQUIRED = 0x00000002,
        ES_SYSTEM_REQUIRED = 0x00000001
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern ExecutionState SetThreadExecutionState(ExecutionState esFlags);
}
"@

# Global variables
$script:keepAwakeActive = $true
$script:keepDisplayOn = -not $ScreenOff
$script:startTime = Get-Date
$script:endTime = $null

if ($TimeMinutes) {
    $script:endTime = $script:startTime.AddMinutes($TimeMinutes)
}

# Function to set the awake state
function Set-AwakeState {
    param(
        [bool]$KeepDisplayOn
    )

    try {
        if ($KeepDisplayOn) {
            # Keep both system and display awake
            $state = [PowerManagement+ExecutionState]::ES_SYSTEM_REQUIRED -bor
                     [PowerManagement+ExecutionState]::ES_DISPLAY_REQUIRED -bor
                     [PowerManagement+ExecutionState]::ES_CONTINUOUS
        }
        else {
            # Keep only system awake, allow display to sleep
            $state = [PowerManagement+ExecutionState]::ES_SYSTEM_REQUIRED -bor
                     [PowerManagement+ExecutionState]::ES_CONTINUOUS
        }

        $result = [PowerManagement]::SetThreadExecutionState($state)

        if ($result -eq 0) {
            Write-Warning "Failed to set thread execution state."
            return $false
        }

        return $true
    }
    catch {
        Write-Error "Error setting awake state: $_"
        return $false
    }
}

# Function to reset the awake state (return to normal power settings)
function Reset-AwakeState {
    try {
        $state = [PowerManagement+ExecutionState]::ES_CONTINUOUS
        [void][PowerManagement]::SetThreadExecutionState($state)
        Write-Host "Awake state reset. System returning to normal power settings."
    }
    catch {
        Write-Error "Error resetting awake state: $_"
    }
}

# Function to get formatted time remaining
function Get-TimeRemaining {
    if ($null -eq $script:endTime) {
        return "Indefinite"
    }

    $remaining = $script:endTime - (Get-Date)

    if ($remaining.TotalSeconds -le 0) {
        return "Expired"
    }

    $hours = [math]::Floor($remaining.TotalHours)
    $minutes = $remaining.Minutes
    $seconds = $remaining.Seconds

    if ($hours -gt 0) {
        return "{0:D2}:{1:D2}:{2:D2}" -f $hours, $minutes, $seconds
    }
    else {
        return "{0:D2}:{1:D2}" -f $minutes, $seconds
    }
}

# Function to check if time has expired
function Test-TimeExpired {
    if ($null -eq $script:endTime) {
        return $false
    }

    return (Get-Date) -ge $script:endTime
}

# Function to create and manage system tray icon
function Start-SystemTray {
    # Create the notification icon
    $script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon

    # Create icon (using a simple built-in icon)
    # In a production environment, you'd want to use a custom .ico file
    $iconStream = [System.Reflection.Assembly]::GetExecutingAssembly().GetManifestResourceStream('System.Drawing.Icon')
    $script:notifyIcon.Icon = [System.Drawing.SystemIcons]::Shield

    # Set initial text
    $displayStatus = if ($script:keepDisplayOn) { "Screen ON" } else { "Screen OFF" }
    $timeStatus = if ($null -eq $script:endTime) { "Indefinite" } else { "$TimeMinutes minutes" }
    $script:notifyIcon.Text = "Keep Awake - $displayStatus - $timeStatus"
    $script:notifyIcon.Visible = $true

    # Create context menu
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

    # Add menu items
    $menuItemStatus = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuItemStatus.Text = "Status: Active"
    $menuItemStatus.Enabled = $false
    $contextMenu.Items.Add($menuItemStatus) | Out-Null

    $menuItemSeparator1 = New-Object System.Windows.Forms.ToolStripSeparator
    $contextMenu.Items.Add($menuItemSeparator1) | Out-Null

    $menuItemToggleDisplay = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuItemToggleDisplay.Text = if ($script:keepDisplayOn) { "Allow Screen OFF" } else { "Keep Screen ON" }
    $menuItemToggleDisplay.Add_Click({
        $script:keepDisplayOn = -not $script:keepDisplayOn
        Set-AwakeState -KeepDisplayOn $script:keepDisplayOn

        $this.Text = if ($script:keepDisplayOn) { "Allow Screen OFF" } else { "Keep Screen ON" }
        $displayStatus = if ($script:keepDisplayOn) { "Screen ON" } else { "Screen OFF" }
        $timeStatus = Get-TimeRemaining
        $script:notifyIcon.Text = "Keep Awake - $displayStatus - $timeStatus"

        $script:notifyIcon.ShowBalloonTip(2000, "Keep Awake", "Display mode changed to: $displayStatus", [System.Windows.Forms.ToolTipIcon]::Info)
    })
    $contextMenu.Items.Add($menuItemToggleDisplay) | Out-Null

    $menuItemSeparator2 = New-Object System.Windows.Forms.ToolStripSeparator
    $contextMenu.Items.Add($menuItemSeparator2) | Out-Null

    $menuItemExit = New-Object System.Windows.Forms.ToolStripMenuItem
    $menuItemExit.Text = "Exit"
    $menuItemExit.Add_Click({
        $script:keepAwakeActive = $false
        $script:notifyIcon.Visible = $false
        $script:notifyIcon.Dispose()
        [System.Windows.Forms.Application]::Exit()
    })
    $contextMenu.Items.Add($menuItemExit) | Out-Null

    $script:notifyIcon.ContextMenuStrip = $contextMenu

    # Double-click to show status
    $script:notifyIcon.Add_DoubleClick({
        $displayStatus = if ($script:keepDisplayOn) { "Screen ON" } else { "Screen OFF" }
        $timeStatus = Get-TimeRemaining
        $elapsed = (Get-Date) - $script:startTime
        $elapsedStr = "{0:D2}:{1:D2}:{2:D2}" -f [int][math]::Floor($elapsed.TotalHours), [int]$elapsed.Minutes, [int]$elapsed.Seconds

        $message = "Status: Active`n" +
                   "Display: $displayStatus`n" +
                   "Time Remaining: $timeStatus`n" +
                   "Elapsed: $elapsedStr"

        [System.Windows.Forms.MessageBox]::Show($message, "Keep Awake Status",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    })

    # Show initial notification
    $script:notifyIcon.ShowBalloonTip(3000, "Keep Awake Started",
        "Computer will stay awake. Right-click icon for options.",
        [System.Windows.Forms.ToolTipIcon]::Info)

    # Create a timer to update the tooltip
    $script:timer = New-Object System.Windows.Forms.Timer
    $script:timer.Interval = 1000 # Update every second
    $script:timer.Add_Tick({
        if (Test-TimeExpired) {
            $script:notifyIcon.ShowBalloonTip(3000, "Keep Awake",
                "Time limit reached. Returning to normal power settings.",
                [System.Windows.Forms.ToolTipIcon]::Info)

            Start-Sleep -Seconds 3
            $script:keepAwakeActive = $false
            $script:notifyIcon.Visible = $false
            $script:notifyIcon.Dispose()
            [System.Windows.Forms.Application]::Exit()
        }
        else {
            $displayStatus = if ($script:keepDisplayOn) { "Screen ON" } else { "Screen OFF" }
            $timeStatus = Get-TimeRemaining
            $script:notifyIcon.Text = "Keep Awake - $displayStatus - $timeStatus"
        }
    })
    $script:timer.Start()

    # Run the application context
    [System.Windows.Forms.Application]::Run()
}

# Main execution
try {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Keep Computer Awake Script" -ForegroundColor Cyan
    Write-Host "  Based on PowerToys Awake implementation" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""

    # Set the initial awake state
    Write-Host "Setting awake state..." -ForegroundColor Yellow
    $success = Set-AwakeState -KeepDisplayOn $script:keepDisplayOn

    if (-not $success) {
        Write-Error "Failed to set awake state. Exiting."
        exit 1
    }

    $displayMode = if ($script:keepDisplayOn) { "ON" } else { "OFF" }
    Write-Host "Computer is now awake (Display: $displayMode)" -ForegroundColor Green

    if ($null -ne $script:endTime) {
        Write-Host "Duration: $TimeMinutes minutes (until $($script:endTime.ToString('HH:mm:ss')))" -ForegroundColor Green
    }
    else {
        Write-Host "Duration: Indefinite (until script is stopped)" -ForegroundColor Green
    }

    Write-Host ""

    if (-not $NoTray) {
        Write-Host "System tray icon created. Script is now running in the background." -ForegroundColor Yellow
        Write-Host "Right-click the tray icon for options, or press Ctrl+C to exit." -ForegroundColor Yellow
        Write-Host ""

        # Register cleanup on script termination
        $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
            try {
                Reset-AwakeState
            } catch {
                # Silently handle errors during exit
            }
        }

        # Start the system tray (this blocks until exit is clicked)
        Start-SystemTray
    }
    else {
        Write-Host "Running without system tray icon. Press Ctrl+C to exit." -ForegroundColor Yellow
        Write-Host ""

        # Keep the script running
        while ($script:keepAwakeActive) {
            if (Test-TimeExpired) {
                Write-Host "Time limit reached. Exiting..." -ForegroundColor Yellow
                break
            }

            Start-Sleep -Seconds 1
        }
    }
}
finally {
    # Clean up - reset the awake state
    # Suppress errors if pipeline has been stopped (e.g., Ctrl+C)
    try {
        Write-Host ""
        Write-Host "Cleaning up..." -ForegroundColor Yellow
    } catch {
        # Ignore if pipeline is stopped
    }

    # Unregister event handler
    try {
        Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
    } catch {
        # Ignore if event doesn't exist
    }

    # Reset awake state
    try {
        Reset-AwakeState
    } catch {
        # Silently reset if there's an error
        try {
            $state = [PowerManagement+ExecutionState]::ES_CONTINUOUS
            [void][PowerManagement]::SetThreadExecutionState($state)
        } catch {
            # Final attempt failed, ignore
        }
    }

    # Clean up timer
    try {
        if ($script:timer) {
            $script:timer.Stop()
            $script:timer.Dispose()
        }
    } catch {
        # Ignore disposal errors
    }

    # Clean up tray icon
    try {
        if ($script:notifyIcon) {
            $script:notifyIcon.Visible = $false
            $script:notifyIcon.Dispose()
        }
    } catch {
        # Ignore disposal errors
    }

    try {
        Write-Host "Script terminated. Computer returning to normal power settings." -ForegroundColor Green
    } catch {
        # Ignore if pipeline is stopped
    }
}
