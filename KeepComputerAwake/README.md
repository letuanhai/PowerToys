# KeepComputerAwake PowerShell Module

A PowerShell module that prevents your computer and screen from sleeping, based on the same approach used by PowerToys Awake.

## Overview

This module uses the Windows `SetThreadExecutionState` API (from `kernel32.dll`) to keep your computer awake. This is the same method used by Microsoft's PowerToys Awake utility.

## Installation

### Method 1: Manual Installation

1. Copy the `KeepComputerAwake` folder to one of your PowerShell module paths:
   - **User modules**: `$HOME\Documents\PowerShell\Modules\` (PowerShell 7+) or `$HOME\Documents\WindowsPowerShell\Modules\` (Windows PowerShell 5.1)
   - **System modules**: `C:\Program Files\PowerShell\Modules\`

2. Import the module:
   ```powershell
   Import-Module KeepComputerAwake
   ```

### Method 2: Import from Custom Location

```powershell
Import-Module "C:\Path\To\KeepComputerAwake\KeepComputerAwake.psd1"
```

### Method 3: Add to PowerShell Profile (Auto-load)

Add this line to your PowerShell profile (`$PROFILE`):
```powershell
Import-Module "C:\Path\To\KeepComputerAwake\KeepComputerAwake.psd1"
```

## Usage

### Basic Commands

```powershell
# Import the module
Import-Module KeepComputerAwake

# Keep computer and screen awake indefinitely
Start-ComputerAwake

# Keep awake for 30 minutes
Start-ComputerAwake -TimeMinutes 30

# Keep computer awake but allow screen to turn off
Start-ComputerAwake -ScreenOff

# Keep awake with hidden console window
Start-ComputerAwake -HideConsole

# Run without system tray icon
Start-ComputerAwake -NoTray

# Stop the awake state (reset to normal)
Stop-ComputerAwake
```

### Function Reference

#### Start-ComputerAwake

Keeps the computer awake with optional screen on using Windows SetThreadExecutionState API.

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `-TimeMinutes` | Integer | Duration in minutes to keep awake. Omit for indefinite operation. |
| `-ScreenOff` | Switch | Allows the screen to turn off while keeping the system awake. |
| `-NoTray` | Switch | Runs without creating a system tray icon. |
| `-HideConsole` | Switch | Hides the PowerShell console window. Only effective with system tray icon. |

**Examples:**

```powershell
# Indefinite with tray icon
Start-ComputerAwake

# 60 minutes with hidden console
Start-ComputerAwake -TimeMinutes 60 -HideConsole

# System awake, screen can sleep, no tray
Start-ComputerAwake -ScreenOff -NoTray
```

#### Stop-ComputerAwake

Stops the computer awake state and returns to normal power settings.

**Examples:**

```powershell
# Reset to normal power settings
Stop-ComputerAwake
```

## Features

- **Keep System Awake**: Prevents the computer from entering sleep mode
- **Keep Screen On**: Optionally keeps the display on (default) or allows it to turn off
- **System Tray Icon**: Provides a system tray icon with:
  - Status display
  - Toggle display mode (keep screen on/off)
  - Right-click context menu
  - Tooltip with remaining time
  - Easy exit option
- **Timed or Indefinite**: Run indefinitely or for a specific duration
- **Hidden Console**: Option to hide the PowerShell console window
- **Clean Shutdown**: Properly resets power settings when exiting
- **Module Architecture**: Well-organized, reusable PowerShell module

## Requirements

- Windows operating system
- PowerShell 5.1 or higher
- Administrator privileges (may be required in some environments)

## Advanced Usage

### Using in Scripts

```powershell
# Import the module
Import-Module KeepComputerAwake

# Start awake mode in a background job
Start-Job -ScriptBlock {
    Import-Module KeepComputerAwake
    Start-ComputerAwake -TimeMinutes 120 -HideConsole
}

# Stop awake mode from another script
Import-Module KeepComputerAwake
Stop-ComputerAwake
```

### Combining with Other Tasks

```powershell
Import-Module KeepComputerAwake

# Keep computer awake while running a long operation
try {
    Start-Job -ScriptBlock {
        Import-Module KeepComputerAwake
        Start-ComputerAwake -NoTray
    }

    # Your long-running task here
    Start-Process "C:\LongTask.exe" -Wait
}
finally {
    Stop-ComputerAwake
}
```

## Technical Details

### API Usage

The module uses P/Invoke to call the Windows API:

```csharp
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern ExecutionState SetThreadExecutionState(ExecutionState esFlags);
```

### Execution State Flags

```csharp
[Flags]
public enum ExecutionState : uint
{
    ES_AWAYMODE_REQUIRED = 0x00000040,
    ES_CONTINUOUS = 0x80000000,
    ES_DISPLAY_REQUIRED = 0x00000002,
    ES_SYSTEM_REQUIRED = 0x00000001
}
```

### State Management

- **Keep Display On**: `ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED | ES_CONTINUOUS`
- **Allow Display Off**: `ES_SYSTEM_REQUIRED | ES_CONTINUOUS`
- **Reset State**: `ES_CONTINUOUS` (clears all previous flags)

## Troubleshooting

### Module Not Found

```powershell
# Check module paths
$env:PSModulePath -split ';'

# Verify module location
Get-Module -ListAvailable -Name KeepComputerAwake

# Force import with full path
Import-Module "C:\Full\Path\To\KeepComputerAwake\KeepComputerAwake.psd1" -Force
```

### Cannot Load Assembly Errors

Ensure you're running on Windows and have .NET Framework installed:

```powershell
# Check PowerShell version
$PSVersionTable

# Verify assemblies can load
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
```

### Function Not Available After Import

```powershell
# Verify functions are exported
Get-Command -Module KeepComputerAwake

# Reimport the module
Remove-Module KeepComputerAwake -ErrorAction SilentlyContinue
Import-Module KeepComputerAwake -Force
```

## Comparison with PowerToys Awake

| Feature | KeepComputerAwake Module | PowerToys Awake |
|---------|--------------------------|-----------------|
| Keep System Awake | ✓ | ✓ |
| Keep Display On | ✓ | ✓ |
| System Tray Icon | ✓ | ✓ |
| Hidden Console Window | ✓ | ✓ |
| Timed Operation | ✓ | ✓ |
| Toggle Display Mode | ✓ | ✓ |
| Module Architecture | ✓ | ✗ |
| Scriptable API | ✓ | Limited |
| Integration with PowerToys | ✗ | ✓ |
| Settings Persistence | ✗ | ✓ |
| Process Binding | ✗ | ✓ |
| Expirable Mode | ✗ | ✓ |

## Version History

### Version 1.0.0
- Initial release
- Prevents system and display sleep using SetThreadExecutionState API
- System tray icon with status display and controls
- Toggle display mode (keep screen on/off)
- Timed or indefinite operation
- Clean shutdown handling
- Hidden console window support
- Based on PowerToys Awake implementation

## License

This module is provided as-is for educational and practical purposes. The implementation approach is based on the open-source PowerToys project by Microsoft.

## Credits

- Implementation approach based on [Microsoft PowerToys Awake](https://github.com/microsoft/PowerToys)
- Uses the same Windows API (`SetThreadExecutionState`) as PowerToys Awake
