@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'Sampler.psm1'

    # Version number of this module.
    ModuleVersion     = '0.108.0'

    # Supported PSEditions
    # CompatiblePSEditions = @('Desktop','Core') # Removed to support PS 5.0

    # ID used to uniquely identify this module
    GUID              = 'b59b8442-9cf9-4c4b-bc40-035336ace573'

    # Author of this module
    Author            = 'Gael Colas'

    # Company or vendor of this module
    CompanyName       = 'SynEdgy Limited'

    # Copyright statement for this module
    Copyright         = '(c) Gael Colas. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Sample Module with Pipeline scripts and its Plaster template to create a module following some of the community accepted practices.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        'Plaster'
    )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @()

    # Functions to export from this module
    FunctionsToExport = @('Add-Sample','New-SampleModule')

    # Cmdlets to export from this module
    CmdletsToExport   = ''

    # Variables to export from this module
    VariablesToExport = ''

    # Aliases to export from this module
    AliasesToExport   = '*'

    # List of all modules packaged with this module
    ModuleList        = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Extension for Plaster Template discoverability with `Get-PlasterTemplate -IncludeInstalledModules`
            Extensions   = @(
                @{
                    Module         = 'Plaster'
                    minimumVersion = '1.1.3'
                    Details        = @{
                        TemplatePaths = @(
                            'Templates\Classes'
                            'Templates\ClassResource'
                            'Templates\Composite'
                            'Templates\Enum'
                            'Templates\MofResource'
                            'Templates\PrivateFunction'
                            'Templates\PublicCallPrivateFunctions'
                            'Templates\PublicFunction'
                            'Templates\Sampler'
                        )
                    }
                }
            )

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Template', 'pipeline', 'plaster', 'DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource', 'Windows', 'MacOS', 'Linux')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/gaelcolas/Sampler/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/gaelcolas/Sampler'

            # A URL to an icon representing this module.
            IconUri      = ''

            # ReleaseNotes of this module
            ReleaseNotes = '## [0.108.0] - 2020-09-14

### Added

- Added GitHub config element template.
- Added vscode config element template.
- Added a new template file for azure-pipelines.yml when using the
  module type `''dsccommunity''`.
- Added a new template and configuration for Codecov.io when using
  module type `''dsccommunity''`.

### Changed

- Renamed the moduleType ''CompleteModule'' to CompleteSample.
- Updated changelog (removed folder creation on simple modules).
- Updated doc.
- Updated code style to match the DSC Community style guideline.
- Updated logic that handles the installation on PSDepend in the bootstrap
  file `Resolve-Dependency.ps1`.
- Updated year in LICENSE.
- Updated the template GitVersion.yml to use specific words to bump
  major version (previously it bumped if the word was found anywhere in
  the commit message even if it was part of for example a code variable).
- Updated the template file build.yaml to make it more clean when using
  the module type `''dsccommunity''`.
- Updated so that the module type `''dsccommunity''` will add a CHANGELOG.md.
- Updated so that the module type `''dsccommunity''` will add the GitHub templates.

### Fixed

- Fixed missing ''PSGallery'' in build files when the Plaster parameter
  `CustomRepo` is not assigned a value.
- Fixed a whitespace issue in the template file Resolve-Dependency.psd1.
- Rephrased comments in the template file build.yaml.

### Removed

- Removed the CompletModule_noBuild template as it''s unecessary and add complexity to the template.

'

            Prerelease   = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}




