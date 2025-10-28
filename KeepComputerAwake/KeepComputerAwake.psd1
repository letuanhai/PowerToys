#
# Module manifest for module 'KeepComputerAwake'
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'KeepComputerAwake.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-47a8-b9c0-d1e2f3a4b5c6'

    # Author of this module
    Author = 'PowerToys Community'

    # Company or vendor of this module
    CompanyName = 'Microsoft'

    # Copyright statement for this module
    Copyright = '(c) Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Keeps computer awake using the same approach as PowerToys Awake. Prevents system and display sleep using Windows SetThreadExecutionState API with optional system tray icon.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @('Start-ComputerAwake', 'Stop-ComputerAwake')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PowerManagement', 'Awake', 'PowerToys', 'Sleep', 'Display', 'Windows', 'SystemTray')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/microsoft/PowerToys/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/microsoft/PowerToys'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.0.0
- Initial release
- Prevents system and display sleep using SetThreadExecutionState API
- System tray icon with status display and controls
- Toggle display mode (keep screen on/off)
- Timed or indefinite operation
- Clean shutdown handling
- Hidden console window support
- Based on PowerToys Awake implementation
'@
        }
    }
}
