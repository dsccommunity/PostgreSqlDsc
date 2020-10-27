@{

# Script module or binary module file associated with this manifest.
#RootModule = 'PostgreSqlDsc.psm1'

# Version number of this module.
ModuleVersion = '0.0.1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '446a0449-43fd-4e6d-991d-1e9df3b49be3'

# Author of this module
Author = 'DSC Community'

# Company or vendor of this module
CompanyName = 'DSC Community'

# Copyright statement for this module
Copyright = 'Copyright the DSC Community contributors. All rights reserved.'

# Description of the functionality provided by this module
Description = 'DSC module to install and configure PostgreSQL on Windows'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @()

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
DscResourcesToExport = @(
    'PostgreSqlInstall'
)

RequiredAssemblies = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            Prerelease = ''

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('DesiredStateConfiguration', 'DSC','PostgreSQL')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/dsccommunity/PostgreSqlDsc/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/dsccommunity/PostgreSqlDsc'

            # A URL to an icon representing this module.
            IconUri = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
