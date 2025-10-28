# Keep Computer Awake PowerShell Script

A PowerShell script that prevents your computer and screen from sleeping, based on the same approach used by PowerToys Awake.

## Overview

This script uses the Windows `SetThreadExecutionState` API (from `kernel32.dll`) to keep your computer awake. This is the same method used by Microsoft's PowerToys Awake utility.

## How It Works

### PowerToys Awake Implementation

The PowerToys Awake tool uses the following approach:

1. **Windows API**: Calls `SetThreadExecutionState` from `kernel32.dll`
2. **Execution State Flags**:
   - `ES_SYSTEM_REQUIRED (0x00000001)`: Prevents the system from entering sleep
   - `ES_DISPLAY_REQUIRED (0x00000002)`: Prevents the display from turning off
   - `ES_CONTINUOUS (0x80000000)`: Makes the effect continuous without requiring periodic calls
3. **State Combinations**:
   - **System + Display Awake**: `ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED | ES_CONTINUOUS`
   - **System Awake Only**: `ES_SYSTEM_REQUIRED | ES_CONTINUOUS`

**Key Files in PowerToys Awake**:
- `/src/modules/awake/Awake/Core/Manager.cs:119-124` - State computation logic
- `/src/modules/awake/Awake/Core/Native/Bridge.cs:24-25` - P/Invoke declaration
- `/src/modules/awake/Awake/Core/Models/ExecutionState.cs:9-17` - Execution state flags

## Features

- **Keep System Awake**: Prevents the computer from entering sleep mode
- **Keep Screen On**: Optionally keeps the display on (default) or allows it to turn off
- **Timed or Indefinite**: Run indefinitely or for a specific duration
- **System Tray Icon**: Provides a system tray icon with:
  - Status display
  - Toggle display mode (keep screen on/off)
  - Right-click context menu
  - Tooltip with remaining time
  - Easy exit option
- **Clean Shutdown**: Properly resets power settings when exiting

## Requirements

- Windows operating system
- PowerShell 5.1 or higher
- Administrator privileges (may be required in some environments)

## Usage

### Basic Usage

```powershell
# Keep computer and screen awake indefinitely with system tray icon
.\Keep-ComputerAwake.ps1

# Keep awake for 30 minutes
.\Keep-ComputerAwake.ps1 -TimeMinutes 30

# Keep computer awake but allow screen to turn off
.\Keep-ComputerAwake.ps1 -ScreenOff

# Run without system tray icon
.\Keep-ComputerAwake.ps1 -NoTray

# Combination: 60 minutes with screen off
.\Keep-ComputerAwake.ps1 -TimeMinutes 60 -ScreenOff
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-TimeMinutes` | Integer | Duration in minutes to keep awake. Omit for indefinite operation. |
| `-ScreenOff` | Switch | Allows the screen to turn off while keeping the system awake. |
| `-NoTray` | Switch | Runs without creating a system tray icon. |

### System Tray Features

When running with the system tray icon (default):

- **Tooltip**: Shows current status, display mode, and time remaining
- **Double-click**: Displays detailed status window
- **Right-click menu**:
  - View current status
  - Toggle display mode (keep screen on/off)
  - Exit the script

## Examples

### Example 1: Indefinite with Tray Icon
```powershell
.\Keep-ComputerAwake.ps1
```
- Keeps computer and screen awake indefinitely
- Shows system tray icon
- Can be controlled via tray icon

### Example 2: Timed Operation
```powershell
.\Keep-ComputerAwake.ps1 -TimeMinutes 120
```
- Keeps computer and screen awake for 2 hours
- Automatically exits when time expires
- Shows countdown in tray icon tooltip

### Example 3: System Awake, Screen Can Sleep
```powershell
.\Keep-ComputerAwake.ps1 -ScreenOff
```
- Keeps computer awake indefinitely
- Allows screen to turn off based on power settings
- Useful for downloads or background tasks

### Example 4: No Tray Icon
```powershell
.\Keep-ComputerAwake.ps1 -TimeMinutes 45 -NoTray
```
- Keeps awake for 45 minutes
- No system tray icon
- Must use Ctrl+C to exit early

## Technical Details

### API Usage

The script uses P/Invoke to call the Windows API:

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

## Cleanup

The script automatically resets the power state when:
- The time limit is reached
- You click "Exit" in the tray menu
- You press Ctrl+C
- The script is terminated

This ensures your computer returns to its normal power settings.

## Troubleshooting

### Script Doesn't Work
- Ensure you're running on Windows
- Check if group policies restrict power management
- Try running PowerShell as Administrator

### System Tray Icon Not Appearing
- Check if system tray is enabled in Windows
- Ensure Windows Forms assemblies can be loaded
- Try running without `-NoTray` parameter

### Screen Still Turns Off
- Verify you're not using the `-ScreenOff` parameter
- Check if display timeout is enforced by group policy
- Ensure the script is still running

## Comparison with PowerToys Awake

| Feature | PowerShell Script | PowerToys Awake |
|---------|------------------|-----------------|
| Keep System Awake | ✓ | ✓ |
| Keep Display On | ✓ | ✓ |
| System Tray Icon | ✓ | ✓ |
| Timed Operation | ✓ | ✓ |
| Integration with PowerToys | ✗ | ✓ |
| Settings Persistence | ✗ | ✓ |
| Process Binding | ✗ | ✓ |
| Expirable Mode | ✗ | ✓ |

## License

This script is provided as-is for educational and practical purposes. The implementation approach is based on the open-source PowerToys project by Microsoft.

## Credits

- Implementation approach based on [Microsoft PowerToys Awake](https://github.com/microsoft/PowerToys)
- Uses the same Windows API (`SetThreadExecutionState`) as PowerToys Awake
