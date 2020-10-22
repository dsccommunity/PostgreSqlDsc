#Region './Private/ConvertTo-OrderedDictionary.ps1' 0
function ConvertTo-OrderedDictionary
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [CmdletBinding()]
    [outputType([System.Object])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [Object]
        $InputObject
    )

    if ($null -eq $InputObject)
    {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary])
    {
        $hashKeys = $InputObject.Keys
        # Making the Ordered Dict Case Insensitive
        $result = [ordered]@{ }
        foreach ($Key in $hashKeys)
        {
            $result[$Key] = ConvertTo-OrderedDictionary -InputObject $InputObject[$Key]
        }
        $result
    }
    elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isNot [string])
    {
        $collection = @(
            foreach ($object in $InputObject)
            {
                ConvertTo-OrderedDictionary -InputObject $object
            }
        )

        , $collection
    }
    elseif ($InputObject -is [PSCustomObject])
    {
        $result = [ordered]@{ }
        foreach ($property in $InputObject.PSObject.Properties)
        {
            $result[$property.Name] = ConvertTo-OrderedDictionary -InputObject $property.Value
        }

        $result
    }
    else
    {
        $InputObject
    }
}
#EndRegion './Private/ConvertTo-OrderedDictionary.ps1' 54
#Region './Private/Get-ClassResourceNameFromFile.ps1' 0
<#
    .SYNOPSIS
        Retrieves the name(s) of any DSC class resources from a PowerShell file.

    .PARAMETER FilePath
        The full path to the file to test.

    .EXAMPLE
        Get-ClassResourceNameFromFile -FilePath 'c:\mymodule\myclassmodule.psm1'

        This command will get any DSC class resource names from the myclassmodule module.
#>
function Get-ClassResourceNameFromFile
{
    [OutputType([String[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $FilePath
    )

    $classResourceNames = [String[]]@()

    if (Test-FileContainsClassResource -FilePath $FilePath)
    {
        $fileAst = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)

        $typeDefinitionAsts = $fileAst.FindAll( { $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
        foreach ($typeDefinitionAst in $typeDefinitionAsts)
        {
            if ($typeDefinitionAst.Attributes.TypeName.Name -ieq 'DscResource')
            {
                $classResourceNames += $typeDefinitionAst.Name
            }
        }
    }

    return $classResourceNames
}
#EndRegion './Private/Get-ClassResourceNameFromFile.ps1' 41
#Region './Private/Get-CurrentModuleBase.ps1' 0
function Get-CurrentModuleBase
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
    )

    return $MyInvocation.MyCommand.Module.ModuleBase
}
#EndRegion './Private/Get-CurrentModuleBase.ps1' 9
#Region './Private/Get-DscResourceTestConfiguration.ps1' 0
function Get-DscResourceTestConfiguration
{
    [cmdletBinding()]
    param
    (
        [Parameter()]
        [Alias('Path')]
        [Object]
        $Configuration = (Join-Path $PWD '.MetaTestOptIn.json')
    )

    if ($Configuration -is [System.Collections.IDictionary])
    {
        Write-Debug "Configuration Object is a Dictionary"
    }
    elseif ($Configuration -is [System.Management.Automation.PSCustomObject])
    {
        Write-Debug "Configuration Object is a PSCustomObject"
    }
    elseif ( $Configuration -is [System.String])
    {
        Write-Debug "Configuration Object is a String, probably a Path"
        $Configuration = Get-StructuredObjectFromFile -Path $Configuration
    }
    else
    {
        throw "Could not resolve Configuration parameter $Configuration of Type $($Configuration.GetType().ToString())"
    }

    $NormalizedConfigurationObject = ConvertTo-OrderedDictionary -InputObject $Configuration

    return $NormalizedConfigurationObject
}
#EndRegion './Private/Get-DscResourceTestConfiguration.ps1' 33
#Region './Private/Get-FileParseError.ps1' 0
<#
    .SYNOPSIS
        Retrieves the parse errors for the given file.

    .PARAMETER FilePath
        The path to the file to get parse errors for.
#>
function Get-FileParseError
{
    [OutputType([System.Management.Automation.Language.ParseError[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $FilePath
    )

    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref] $null, [ref] $parseErrors)

    return $parseErrors
}
#EndRegion './Private/Get-FileParseError.ps1' 23
#Region './Private/Get-FunctionDefinitionAst.ps1' 0
<#
    .SYNOPSIS
        Returns the function definition ASTs for a script file.

    .PARAMETER FullName
        Full path to the script file.
#>
function Get-FunctionDefinitionAst
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FullName
    )

    $tokens, $parseErrors = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $FullName,
        [ref] $tokens,
        [ref] $parseErrors
    )

    if ($parseErrors)
    {
        throw $parseErrors
    }

    $astFilter = {
        param
        (
            [Parameter()]
            [System.Management.Automation.Language.Ast]
            $Ast
        )

        $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }

    return $ast.FindAll($astFilter, $true)
}
#EndRegion './Private/Get-FunctionDefinitionAst.ps1' 42
#Region './Private/Get-ModuleScriptResourceName.ps1' 0

<#
    .SYNOPSIS
        Retrieves the names of all script resources for the given module.

    .PARAMETER ModulePath
        The path to the module to retrieve the script resource names of.
#>
function Get-ModuleScriptResourceName
{
    [OutputType([String[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $ModulePath
    )

    $scriptResourceNames = @()

    $dscResourcesFolderFilePath = Join-Path -Path $ModulePath -ChildPath 'DscResources'
    $mofSchemaFiles = Get-ChildItem -Path $dscResourcesFolderFilePath -Filter '*.schema.mof' -File -Recurse

    foreach ($mofSchemaFile in $mofSchemaFiles)
    {
        $scriptResourceName = $mofSchemaFile.BaseName -replace '.schema', ''
        $scriptResourceNames += $scriptResourceName
    }

    return $scriptResourceNames
}
#EndRegion './Private/Get-ModuleScriptResourceName.ps1' 32
#Region './Private/Get-Psm1FileList.ps1' 0
<#
    .SYNOPSIS
        Retrieves all .psm1 files under the given file path.

    .PARAMETER FilePath
        The root file path to gather the .psm1 files from.
#>
function Get-Psm1FileList
{
    [OutputType([Object[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $FilePath
    )

    return Get-ChildItem -Path $FilePath -Filter '*.psm1' -File -Recurse
}
#EndRegion './Private/Get-Psm1FileList.ps1' 20
#Region './Private/Get-PublishFileName.ps1' 0
<#
    .SYNOPSIS
        This command will return a filename without extension and without any
        starting numeric value followed by a dash (-).

    .PARAMETER Path
        The path to the example for which the filename should be returned.

    .OUTPUTS
        Returns a filename without extension and without any starting numeric
        value followed by a dash (-).
#>
function Get-PublishFileName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    # Get the filename without extension.
    $filenameWithoutExtension = (Get-Item -Path $Path).BaseName

    <#
        Resource modules using auto-documentation uses a numeric value followed
        by a dash ('-') to be able to control the order of the example in
        the documentation. That will not be used when publishing, so remove
        it here from the name that is compared to the configuration name.
    #>
    return $filenameWithoutExtension -replace '^[0-9]+-'
}
#EndRegion './Private/Get-PublishFileName.ps1' 34
#Region './Private/Get-RelativePathFromModuleRoot.ps1' 0

<#
    .SYNOPSIS
        This returns a string containing the relative path from the module root.

    .PARAMETER FilePath
        The file path to remove the module root path from.

    .PARAMETER ModuleRootFilePath
        The root path to remove from the file path.
#>
function Get-RelativePathFromModuleRoot
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleRootFilePath
    )

    <#
        Removing the module root path from the file path so that the path
        doesn't get so long in the Pester output.
    #>
    return ($FilePath -replace [Regex]::Escape($ModuleRootFilePath), '').Trim([io.path]::DirectorySeparatorChar)
}
#EndRegion './Private/Get-RelativePathFromModuleRoot.ps1' 30
#Region './Private/Get-StructuredObjectFromFile.ps1' 0
function Get-StructuredObjectFromFile
{
    [cmdletBinding()]
    param
    (
        [Parameter()]
        [String]
        $Path
    )

    $ioPath = [System.IO.FileInfo]($PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path))
    switch -regex ($ioPath.Extension)
    {
        '^\.psd1$'
        {
            $ObjectFromFile = Import-PowerShellDataFile -Path $ioPath -ErrorAction Stop
        }

        '^\.y[a]?ml$'
        {
            Import-Module Powershell-yaml -ErrorAction Stop
            $FileContent = Get-Content -Raw -Path $ioPath -ErrorAction Stop
            $ObjectFromFile = ConvertFrom-Yaml -Ordered -Yaml $FileContent -ErrorAction Stop
        }

        '^\.json$'
        {
            $FileContent = Get-Content -Raw -Path $ioPath -ErrorAction Stop
            $ObjectFromFile = ConvertFrom-Json -InputObject $FileContent -ErrorAction Stop
        }

        Default
        {
            throw "File extension $($ioPath.Extension) not recognized."
        }
    }

    return $ObjectFromFile
}
#EndRegion './Private/Get-StructuredObjectFromFile.ps1' 39
#Region './Private/Get-SuppressedPSSARuleNameList.ps1' 0


<#
    .SYNOPSIS
        Retrieves the list of suppressed PSSA rules in the file at the given path.

    .PARAMETER FilePath
        The path to the file to retrieve the suppressed rules of.
#>
function Get-SuppressedPSSARuleNameList
{
    [OutputType([String[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $FilePath
    )

    $suppressedPSSARuleNames = [String[]]@()

    $fileAst = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)

    # Overall file attributes
    $attributeAsts = $fileAst.FindAll( {$args[0] -is [System.Management.Automation.Language.AttributeAst]}, $true)

    foreach ($attributeAst in $attributeAsts)
    {
        if ([System.Diagnostics.CodeAnalysis.SuppressMessageAttribute].FullName.ToLower().Contains($attributeAst.TypeName.FullName.ToLower()))
        {
            $suppressedPSSARuleNames += $attributeAst.PositionalArguments.Extent.Text
        }
    }

    return $suppressedPSSARuleNames
}
#EndRegion './Private/Get-SuppressedPSSARuleNameList.ps1' 37
#Region './Private/Get-TextFilesList.ps1' 0

<#
    .SYNOPSIS
        Retrieves all text files under the given root file path.

    .PARAMETER Root
        The root file path under which to retrieve all text files.

    .NOTES
        Retrieves all files with the '.gitignore', '.gitattributes', '.ps1', '.psm1', '.psd1',
        '.json', '.xml', '.cmd', or '.mof' file extensions.
#>
function Get-TextFilesList
{
    [OutputType([System.IO.FileInfo[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $Root
    )

    $textFileExtensions = @('.gitignore', '.gitattributes', '.ps1', '.psm1', '.psd1', '.json', '.xml', '.cmd', '.mof', '.md', '.js', '.yml')

    return Get-ChildItem -Path $Root -File -Recurse | Where-Object { $textFileExtensions -contains $_.Extension }
}
#EndRegion './Private/Get-TextFilesList.ps1' 27
#Region './Private/Initialize-DscTestLcm.ps1' 0

<#
    .SYNOPSIS
        This command will initialize the Local Configuration Manager for Integration tests.
        It's meant to be used before running tests.

    .PARAMETER DisableConsistency
        This will switch off monitoring (consistency) for the Local Configuration
        Manager (LCM), setting ConfigurationMode to 'ApplyOnly', on the node
        running tests.

    .PARAMETER Encrypt
        This will switch on encryption for the Local Configuration
        Manager (LCM), setting CertificateId to the thumbprint stored in
        $env:DscCertificateThumbprint, on the node running tests.

        When using this parameter any configuration used for an integration
        test must have CertificateFile pointing to path stored in
        $env:DscPublicCertificatePath.
#>
function Initialize-DscTestLcm
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Switch]
        $DisableConsistency,

        [Parameter()]
        [Switch]
        $Encrypt
    )

    $disableConsistencyMofPath = Join-Path -Path $env:temp -ChildPath 'DscTestLCMConfiguration'
    if (-not (Test-Path -Path $disableConsistencyMofPath))
    {
        $null = New-Item -Path $disableConsistencyMofPath -ItemType Directory -Force
    }

    # Start of the metadata configuration
    $configurationMetadata = '
        Configuration LocalConfigurationManagerConfiguration
        {
            LocalConfigurationManager
            {
    '

    if ($DisableConsistency.IsPresent)
    {
        Write-Verbose -Message 'Setting Local Configuration Manager property ConfigurationMode to ''ApplyOnly'', disabling consistency check.'
        # Have LCM Apply only once.
        $configurationMetadata += '
            ConfigurationMode = ''ApplyOnly''
        '
    }

    if ($Encrypt.IsPresent)
    {
        Write-Verbose -Message ('Setting Local Configuration Manager property CertificateId to ''{0}'', enabling decryption of credentials.' -f $env:DscCertificateThumbprint)
        # Should use encryption.
        $configurationMetadata += ('
            CertificateId = ''{0}''
        ' -f $env:DscCertificateThumbprint)
    }

    # End of the metadata configuration
    $configurationMetadata += '
            }
        }
    '

    Invoke-Command -ScriptBlock ([scriptblock]::Create($configurationMetadata)) -NoNewScope

    $null = LocalConfigurationManagerConfiguration -OutputPath $disableConsistencyMofPath

    Set-DscLocalConfigurationManager -Path $disableConsistencyMofPath -Force -Verbose
    $null = Remove-Item -LiteralPath $disableConsistencyMofPath -Recurse -Force -Confirm:$false
}
#EndRegion './Private/Initialize-DscTestLcm.ps1' 79
#Region './Private/Set-EnvironmentVariable.ps1' 0
<#
    .SYNOPSIS
        This command will set the machine and session environment variable to
        a value.
    .PARAMETER Name
        The name of the variable to set.
    .PARAMETER Value
        The value of the variable to set. If this is set to $null or
        empty string ('') the environment variable will be removed.
    .PARAMETER Machine
        If present, the environment variable will be set machine wide.
        If not present, the environment variable will be set for the user.
#>
function Set-EnvironmentVariable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Value,

        [Parameter()]
        [Switch]
        $Machine
    )

    if ($Machine.IsPresent)
    {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'Machine')
        Set-Item -Path "env:\$Name" -Value $Value
    }
    else
    {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
        Set-Item -Path "env:\$Name" -Value $Value
    }
}
#EndRegion './Private/Set-EnvironmentVariable.ps1' 43
#Region './Private/Set-PSModulePath.ps1' 0

<#
    .SYNOPSIS
        The is a wrapper to set $env:PSModulePath both in current session and
        machine wide.
        This is needed to be able to mock the function in the unit tests.

    .PARAMETER Path
        A string with all the paths separated by semi-colons.

    .PARAMETER Machine
        If set the PSModulePath will be changed machine wide. If not set, only
        the current session will be changed.

    .EXAMPLE
        Set-PSModulePath -Path '<Path 1>;<Path 2>'

    .EXAMPLE
        Set-PSModulePath -Path '<Path 1>;<Path 2>' -Machine
#>
function Set-PSModulePath
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Parameter()]
        [Switch]
        $Machine
    )

    if ($Machine.IsPresent)
    {
        [System.Environment]::SetEnvironmentVariable('PSModulePath', $Path, [System.EnvironmentVariableTarget]::Machine)
    }
    else
    {
        $env:PSModulePath = $Path
    }
}
#EndRegion './Private/Set-PSModulePath.ps1' 45
#Region './Private/Test-ConfigurationName.ps1' 0
function Test-ConfigurationName
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    <#
        Resource modules using auto-documentation uses a numeric value followed by a dash ('-') to be able to control
        the order of the example in the documentation. That will not be used when publishing, so remove it here from
        the name that is compared to the configuration name.
    #>
    $publishFilename = (Get-Item -Path $Path).BaseName -replace '^[0-9]+-'

    $parseErrors = $null
    $definitionAst = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref] $null, [ref] $parseErrors)

    if ($parseErrors)
    {
        throw $parseErrors
    }

    $astFilter = {
        $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst]
    }

    $configurationDefinition = $definitionAst.Find($astFilter, $true)

    $isOfCorrectType = $configurationDefinition.ConfigurationType -eq [System.Management.Automation.Language.ConfigurationType]::Resource

    $configurationName = $configurationDefinition.InstanceName.Value
    $hasEqualName = $configurationName -eq $publishFilename

    <#
        The name can contain only letters, numbers, and underscores.
        The name must start with a letter, and it must end with a letter or a number.
    #>
    $hasCorrectNamingConvention = $configurationName -match '^[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$'

    if ($isOfCorrectType -and $hasEqualName -and $hasCorrectNamingConvention)
    {
        $result = $true
    }
    else
    {
        $result = $false
    }

    return $result
}
#EndRegion './Private/Test-ConfigurationName.ps1' 54
#Region './Private/Test-FileContainsClassResource.ps1' 0
<#
    .SYNOPSIS
        Tests if a PowerShell file contains a DSC class resource.

    .PARAMETER FilePath
        The full path to the file to test.

    .EXAMPLE
        Test-ContainsClassResource -ModulePath 'c:\mymodule\myclassmodule.psm1'

        This command will test myclassmodule for the presence of any class-based
        DSC resources.
#>
function Test-FileContainsClassResource
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $FilePath
    )

    $fileAst = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)

    foreach ($fileAttributeAst in $fileAst.FindAll( {$args[0] -is [System.Management.Automation.Language.AttributeAst]}, $false))
    {
        if ($fileAttributeAst.Extent.Text -ieq '[DscResource()]')
        {
            return $true
        }
    }

    return $false
}
#EndRegion './Private/Test-FileContainsClassResource.ps1' 36
#Region './Private/Test-FileHasByteOrderMark.ps1' 0

<#
    .SYNOPSIS
        Tests if a file contains Byte Order Mark (BOM).

    .PARAMETER FilePath
        The file path to evaluate.
#>
function Test-FileHasByteOrderMark
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath
    )

    $getContentParameters = @{
        Path       = $FilePath
        ReadCount  = 3
        TotalCount = 3
    }

    # Need to treat Windows Powershell and PowerShell Core different.
    if ($PSVersionTable.PSEdition -eq 'Core')
    {
        $getContentParameters['AsByteStream'] = $true
    }
    else
    {
        $getContentParameters['Encoding'] = 'Byte'
    }

    # This reads the first three bytes of the first row.
    $firstThreeBytes = Get-Content @getContentParameters

    # Check for the correct byte order (239,187,191) which equal the Byte Order Mark (BOM).
    return ($firstThreeBytes[0] -eq 239 `
            -and $firstThreeBytes[1] -eq 187 `
            -and $firstThreeBytes[2] -eq 191)
}
#EndRegion './Private/Test-FileHasByteOrderMark.ps1' 41
#Region './Private/Test-FileInUnicode.ps1' 0
<#
    .SYNOPSIS
        Tests if a file is encoded in Unicode.

    .PARAMETER FileInfo
        The file to test.
#>
function Test-FileInUnicode
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [System.IO.FileInfo]
        $FileInfo
    )

    $filePath = $FileInfo.FullName
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $zeroBytes = @( $fileBytes -eq 0 )

    return ($zeroBytes.Length -ne 0)
}
#EndRegion './Private/Test-FileInUnicode.ps1' 24
#Region './Private/Test-ModuleContainsClassResource.ps1' 0

<#
    .SYNOPSIS
        Tests if a module contains a class resource.

    .PARAMETER ModulePath
        The path to the module to test.
#>
function Test-ModuleContainsClassResource
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $ModulePath
    )

    $psm1Files = Get-Psm1FileList -FilePath $ModulePath

    foreach ($psm1File in $psm1Files)
    {
        if (Test-FileContainsClassResource -FilePath $psm1File.FullName)
        {
            return $true
        }
    }

    return $false
}
#EndRegion './Private/Test-ModuleContainsClassResource.ps1' 31
#Region './Private/Test-ModuleContainsScriptResource.ps1' 0

<#
    .SYNOPSIS
        Tests if a module contains a script resource.

    .PARAMETER ModulePath
        The path to the module to test.
#>
function Test-ModuleContainsScriptResource
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [String]
        $ModulePath
    )

    $dscResourcesFolderFilePath = Join-Path -Path $ModulePath -ChildPath 'DscResources'
    $mofSchemaFiles = Get-ChildItem -Path $dscResourcesFolderFilePath -Filter '*.schema.mof' -File -Recurse

    return ($null -ne $mofSchemaFiles)
}
#EndRegion './Private/Test-ModuleContainsScriptResource.ps1' 24
#Region './Private/Test-TestShouldBeSkipped.ps1' 0
function Test-TestShouldBeSkipped
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $TestNames,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Tag,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.String[]]
        $ExcludeTag
    )

    if ($ExcludeTag)
    {
        $IsTagExcluded = Compare-Object -ReferenceObject $TestNames -DifferenceObject $ExcludeTag -IncludeEqual -ExcludeDifferent
    }
    else
    {
        $IsTagExcluded = $false
    }

    if ($Tag)
    {
        $IsTagIncluded = Compare-Object -ReferenceObject $TestNames -DifferenceObject $Tag -IncludeEqual -ExcludeDifferent
    }

    # Should be skipped if It's excluded or Tags are in use and it's not included
    $ShouldBeSkipped = ($IsTagExcluded -or ($Tag -and -Not $isTagIncluded))

    if ($ShouldBeSkipped)
    {
        Write-Warning "The tests for $($TestNames -join ', ') is not being enforced. Please Opt-in!"
    }

    return $ShouldBeSkipped
}
#EndRegion './Private/Test-TestShouldBeSkipped.ps1' 45
#Region './Private/WhereModuleFileNotExcluded.ps1' 0
filter WhereModuleFileNotExcluded
{
    foreach ($ExclPath in $ExcludeModuleFile)
    {
        if ((($filename = $_.FullName) -or ($fileName = $_)) -and $filename -Match ([regex]::Escape($ExclPath)))
        {
            Write-Debug "Skipping $($_.FullName) because it matches $ExclPath"
            return
        }
    }
    $_
}
#EndRegion './Private/WhereModuleFileNotExcluded.ps1' 12
#Region './Private/WhereSourceFileNotExcluded.ps1' 0
filter WhereSourceFileNotExcluded
{
    foreach ($ExclPath in $ExcludeSourceFile)
    {
        if ((($filename = $_.FullName) -or ($fileName = $_)) -and $filename -Match ([regex]::Escape($ExclPath)))
        {
            Write-Debug "Skipping $($_.FullName) because it matches $ExclPath"
            return
        }
    }
    $_
}
#EndRegion './Private/WhereSourceFileNotExcluded.ps1' 12
#Region './Public/Clear-DscLcmConfiguration.ps1' 0
<#
    .SYNOPSIS
        Clear the DSC LCM by performing the following functions:
        1. Cancel any currently executing DSC LCM operations
        2. Remove any DSC configurations that:
            - are currently applied
            - are pending application
            - have been previously applied

        The purpose of this function is to ensure the DSC LCM is in a known
        and idle state before an integration test is performed that will
        apply a configuration.

        This is to prevent an integration test from being performed but failing
        because the DSC LCM is applying a previous configuration.

        This function should be called after each Describe block in an integration
        test to ensure the DSC LCM is reset before another test DSC configuration
        is applied.
    .EXAMPLE
        Clear-DscLcmConfiguration

        This command will Stop the DSC LCM and clear out any DSC configurations.
#>
function Clear-DscLcmConfiguration
{
    [CmdletBinding()]
    param ()

    if ($PSVersionTable.PSVersion.Major -gt 5)
    {
        Write-Verbose "The LCM is a Windows PowerShell version only"
        return
    }

    Write-Verbose -Message 'Stopping current LCM configuration and Clearing the DSC Configuration Documents'
    Stop-DscConfiguration -ErrorAction 'SilentlyContinue' -Force
    Remove-DscConfigurationDocument -Stage 'Current' -Force
    Remove-DscConfigurationDocument -Stage 'Pending' -Force
    Remove-DscConfigurationDocument -Stage 'Previous' -Force
}
#EndRegion './Public/Clear-DscLcmConfiguration.ps1' 41
#Region './Public/Initialize-TestEnvironment.ps1' 0
<#
    .SYNOPSIS
        Initializes an environment for running unit or integration tests
        on a DSC resource.

        This includes:
        1. Updates the $env:PSModulePath to ensure the correct module is tested.
        2. Imports the module to test.
        3. Sets the PowerShell ExecutionMode to Unrestricted.
        4. returns a test environment object to store the settings.

        The above changes are reverted by calling the Restore-TestEnvironment
        function with the returned object.

        Returns a test environment object which must be passed to the
        Restore-TestEnvironment function to allow it to restore the system
        back to the original state.

    .PARAMETER Module
        The name of the DSC Module containing the resource that the tests will be
        run on.

    .PARAMETER DscResourceName
        The full name of the DSC resource that the tests will be run on. This is
        usually the name of the folder containing the actual resource MOF file.

    .PARAMETER TestType
        Specifies the type of tests that are being initialized. It can be:
        Unit: Initialize for running Unit tests on a DSC resource.
        Integration: Initialize for running Integration tests on a DSC resource.
        All: Initialize for running end-to-end tests on a DSC resource. These
        tests will include both unit and integration type tests and so will
        initialize the DSC LCM as well as import the module.

    .PARAMETER ResourceType
        Specifies if the DscResource under test is mof-based or class-based.
        The default value is 'mof'.

        It can be:
        Mof: The test initialization assumes a Mof-based DscResource folder structure.
        Class: The test initialization assumes a Class-based DscResource folder structure.

    .PARAMETER ProcessExecutionPolicy
        Specifies the process' execution policy to set before running tests.
        If not specified, the command will not alter the current process' execution
        policy.

    .PARAMETER MachineExecutionPolicy
        Specifies the machine's execution policy to set before running tests.
        If not specified, the command will not alter the machine's execution policy.

    .EXAMPLE
        $TestEnvironment = Initialize-TestEnvironment `
            -DSCModuleName 'xNetworking' `
            -DSCResourceName 'MSFT_xFirewall' `
            -TestType Unit

        This command will initialize the test environment for Unit testing
        the MSFT_xFirewall mof-based DSC resource in the xNetworking DSC module.

    .EXAMPLE
        $TestEnvironment = Initialize-TestEnvironment `
            -DSCModuleName 'SqlServerDsc' `
            -DSCResourceName 'SqlAGDatabase' `
            -TestType Unit
            -ResourceType Class

        This command will initialize the test environment for Unit testing
        the SqlAGDatabase class-based DSC resource in the SqlServer DSC module.

    .EXAMPLE
        $TestEnvironment = Initialize-TestEnvironment `
            -DSCModuleName 'xNetworking' `
            -DSCResourceName 'MSFT_xFirewall' `
            -TestType Integration

        This command will initialize the test environment for Integration testing
        the MSFT_xFirewall DSC resource in the xNetworking DSC module.
#>
function Initialize-TestEnvironment
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('DscModuleName')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Module,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DscResourceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Unit', 'Integration', 'All')]
        [String]
        $TestType,

        [Parameter()]
        [ValidateSet('Mof', 'Class')]
        [String]
        $ResourceType = 'Mof',

        [Parameter()]
        [ValidateSet('AllSigned', 'Bypass','RemoteSigned','Unrestricted')]
        [String]
        $ProcessExecutionPolicy,

        [Parameter()]
        [ValidateSet('AllSigned', 'Bypass','RemoteSigned','Unrestricted')]
        [String]
        $MachineExecutionPolicy
    )

    Write-Verbose -Message "Initializing test environment for $TestType testing of $DscResourceName in module $Module"
    $ModuleUnderTest = Import-Module $Module -PassThru -ErrorAction Stop
    $moduleRootFilePath = $ModuleUnderTest.ModuleBase
    $moduleManifestFilePath = Join-Path -Path $moduleRootFilePath -ChildPath "$($ModuleUnderTest.Name).psd1"

    if (Test-Path -Path $moduleManifestFilePath)
    {
        Write-Verbose -Message "Module manifest $($ModuleUnderTest.Name).psd1 detected at $moduleManifestFilePath"
    }
    else
    {
        throw "Module manifest could not be found for the module $($ModuleUnderTest.Name) in the root folder $moduleRootFilePath"
    }

    # Import the module to test
    if ($TestType -in ('Unit','All'))
    {
        switch ($ResourceType)
        {
            'Mof'
            {
                $resourceTypeFolderName = 'DSCResources'
            }

            'Class'
            {
                $resourceTypeFolderName = 'DSCClassResources'
            }
        }

        $dscResourcesFolderFilePath = Join-Path -Path $moduleRootFilePath -ChildPath $resourceTypeFolderName
        $dscResourceToTestFolderFilePath = Join-Path -Path $dscResourcesFolderFilePath -ChildPath $DscResourceName

        $moduleToImportFilePath = Join-Path -Path $dscResourceToTestFolderFilePath -ChildPath "$DscResourceName.psm1"
    }
    else
    {
        $moduleToImportFilePath = $moduleManifestFilePath
    }

    Import-Module -Name $moduleToImportFilePath -Scope 'Global' -Force

    <#
        Set the PSModulePath environment variable so that the module path that includes the module
        we want to test appears first. LCM will then use this path to locate modules when
        integration tests are called. Placing the path we want first ensures the correct module
        will be tested.
    #>

    if ((Split-Path -Leaf $moduleRootFilePath) -as [version])
    {
        $moduleParentFilePath = Split-Path -Parent -Path (Split-Path -Parent -Path $moduleRootFilePath)
    }
    else
    {
        $moduleParentFilePath = Split-Path -Path $moduleRootFilePath -Parent
    }


    $oldPSModulePath = $env:PSModulePath

    if ($null -ne $oldPSModulePath)
    {
        $oldPSModulePathSplit = $oldPSModulePath.Split([io.path]::PathSeparator)
    }
    else
    {
        $oldPSModulePathSplit = $null
    }

    if ($oldPSModulePathSplit -ccontains $moduleParentFilePath)
    {
        # Remove the existing module path from the new PSModulePath
        $newPSModulePathSplit = $oldPSModulePathSplit | Where-Object { $_ -ne $moduleParentFilePath }
    }
    else
    {
        $newPSModulePath = $oldPSModulePath
    }

    $RequiredModulesPath = Join-Path -Path $moduleParentFilePath 'RequiredModules'
    if ($newPSModulePathSplit -cnotcontains $RequiredModulesPath)
    {
        $newPSModulePathSplit = @($RequiredModulesPath) + $newPSModulePathSplit
    }

    $newPSModulePathSplit = @($moduleParentFilePath) + $newPSModulePathSplit
    $newPSModulePath = $newPSModulePathSplit -join [io.Path]::PathSeparator

    Set-PSModulePath -Path $newPSModulePath

    if ($TestType -in ('Integration','All'))
    {
        <#
            Making sure setting up the LCM & Machine Path makes sense...

            $PSEdition does not exist prior to PS5.1 so we need to evaluate the
            version in $PSVersionTable too.
        #>
        if (($IsWindows -or $PSEdition -eq 'Desktop' -or $PSVersionTable.PSVersion -lt [System.Version] '5.1') -and
            ($Principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())) -and
            $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        )
        {
            if (!$script:MachineOldPSModulePath)
            {
                Write-Warning "This will change your Machine Environment Variable"
                $script:MachineOldPSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
            }

            # Preserve and set the execution policy so that the DSC MOF can be created
            $currentMachineExecutionPolicy = Get-ExecutionPolicy -Scope 'LocalMachine'
            if ($PSBoundParameters.ContainsKey('MachineExecutionPolicy'))
            {
                if ($currentMachineExecutionPolicy -ne $MachineExecutionPolicy)
                {
                    Set-ExecutionPolicy -ExecutionPolicy $MachineExecutionPolicy -Scope 'LocalMachine' -Force -ErrorAction Stop

                    <#
                        The variable $script:MachineOldExecutionPolicy should
                        only be set if it has not been set before. If it has been
                        set before then it means that we have already a value that
                        has not yet been reverted using Restore-TestEnvironment.

                        Should only be set after we actually changed the execution
                        policy because if $script:MachineOldExecutionPolicy is set
                        to a value `Restore-TestEnvironment` will try to revert
                        the value.
                    #>
                    if ($null -eq $script:MachineOldExecutionPolicy)
                    {
                        $script:MachineOldExecutionPolicy = $currentMachineExecutionPolicy
                    }

                    $currentMachineExecutionPolicy = $MachineExecutionPolicy
                }
            }

            Write-Verbose -Message ('The machine execution policy is set to ''{0}''' -f $currentMachineExecutionPolicy)

            <#
                For integration tests we have to set the machine's PSModulePath because otherwise the
                DSC LCM won't be able to find the resource module being tested or may use the wrong one.
            #>
            Set-PSModulePath -Path $newPSModulePath -Machine

            # Clear the DSC LCM & Configurations
            Clear-DscLcmConfiguration
            # Setup the Self signed Certificate for Integration tests & get the LCM ready
            $null = New-DscSelfSignedCertificate
            Initialize-DscTestLcm -DisableConsistency -Encrypt
        }
        else
        {
            Write-Warning "Setting up the DSC Integration Test Environment (LCM & Certificate) only works on Windows PS5+ as Admin"
        }
    }

    <#
        Preserve and set the execution policy so that the DSC MOF can be created.

        `Restore-TestEnvironment` will only revert the value if $oldExecutionPolicy
        differ from current execution policy. So we make to always set it to the
        current execution policy so that if we don't need to change it then
        `Restore-TestEnvironment` will not try to revert the value.
    #>
    $oldExecutionPolicy = Get-ExecutionPolicy -Scope 'Process'

    if ($PSBoundParameters.ContainsKey('ProcessExecutionPolicy'))
    {
        if ($oldExecutionPolicy -ne $ProcessExecutionPolicy)
        {
            Set-ExecutionPolicy -ExecutionPolicy $ProcessExecutionPolicy -Scope 'Process' -Force -ErrorAction Stop
        }
    }

    Write-Verbose -Message ('The process execution policy is set to ''{0}''' -f $oldExecutionPolicy)

    # Return the test environment
    return @{
        DSCModuleName      = $Module
        Module             = $ModuleUnderTest
        DSCResourceName    = $DscResourceName
        TestType           = $TestType
        ImportedModulePath = $moduleToImportFilePath
        OldPSModulePath    = $oldPSModulePath
        OldExecutionPolicy = $oldExecutionPolicy
    }
}
#EndRegion './Public/Initialize-TestEnvironment.ps1' 306
#Region './Public/Invoke-DscResourceTest.ps1' 0
<#
    .ForwardHelpTargetName Invoke-Pester
    .ForwardHelpCategory Function
#>
function Invoke-DscResourceTest
{
    [CmdletBinding(DefaultParameterSetName = 'ByProjectPath')]
    param (
        [Parameter(ParameterSetName = 'ByModuleNameOrPath', Position = 0)]
        [System.String]
        $Module,

        [Parameter(ParameterSetName = 'ByModuleSpecification', Position = 0)]
        [Microsoft.PowerShell.Commands.ModuleSpecification]
        $FullyQualifiedModule,

        [Parameter(ParameterSetName = 'ByProjectPath', Position = 0)]
        [System.String]
        $ProjectPath,

        [Parameter(Position = 1)]
        [Alias('Script', 'relative_path')]
        [System.Object[]]
        $Path,

        [Parameter(Position = 2)]
        [Alias('Name')]
        [System.String[]]
        $TestName,

        [Parameter(Position = 3)]
        [switch]
        $EnableExit,

        [Parameter(Position = 5)]
        [Alias('Tags','Tag')]
        [System.String[]]
        $TagFilter,

        [Parameter()]
        [Alias('ExcludeTag')]
        [System.String[]]
        $ExcludeTagFilter,

        [Parameter()]
        [System.String[]]
        $ExcludeModuleFile,

        [Parameter()]
        [System.String[]]
        $ExcludeSourceFile,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [System.Object[]]
        $CodeCoverage,

        [Parameter()]
        [System.String]
        $CodeCoverageOutputFile,

        [Parameter()]
        [ValidateSet('JaCoCo')]
        [System.String]
        $CodeCoverageOutputFileFormat,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Strict,

        [Parameter()]
        [System.String]
        $Output,

        [Parameter()]
        [System.String]
        $OutputFile,

        [Parameter()]
        [ValidateSet('NUnitXml', 'JUnitXml')]
        [System.String]
        $OutputFormat,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Quiet,

        [Parameter()]
        [System.Object]
        $PesterOption,

        [Parameter()]
        [Pester.OutputTypes]
        $Show,

        [Parameter()]
        [System.Collections.Hashtable]
        $Settings,

        [Parameter()]
        [System.String]
        $MainGitBranch = 'master'
    )

    begin
    {
        <#
            Make sure Invoke-DscResourceTest runs against the Built Module either:

            By $Module (Name, Path, ModuleSpecification): enables to run some tests on installed modules (even without source)
            By $ProjectPath (detect source from there based on .psd1): Target both the source when relevant and the expected files
        #>

        switch ($PSCmdlet.ParameterSetName)
        {
            'ByModuleNameOrPath'
            {
                Write-Verbose -Message 'Calling DscResource Test by Module Name (or Path).'

                if (-not $PSBoundParameters.ContainsKey('Path'))
                {
                    $PSBoundParameters['Path'] = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'Tests/QA'
                }

                $null = $PSBoundParameters.Remove('Module')

                $ModuleUnderTest = Import-Module -Name $Module -ErrorAction 'Stop' -Force -PassThru
            }

            'ByModuleSpecification'
            {
                Write-Verbose -Message 'Calling DscResource Test by Module Specification.'

                if (-not $PSBoundParameters.ContainsKey('Path'))
                {
                    $PSBoundParameters['Path'] = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'Tests/QA'
                }

                $null = $PSBoundParameters.Remove('FullyQualifiedModule')

                $ModuleUnderTest = Import-Module -FullyQualifiedName $FullyQualifiedModule -Force -PassThru -ErrorAction 'Stop'
            }

            'ByProjectPath'
            {
                Write-Verbose -Message 'Calling DscResource Test by Project Path.'

                if (-not $ProjectPath)
                {
                    $ProjectPath = $PWD.Path
                }

                try
                {
                    $null = $PSBoundParameters.Remove('ProjectPath')
                }
                catch
                {
                    Write-Debug -Message 'The function was called via default param set. Using $PWD for Project Path.'
                }

                if (-not $PSBoundParameters.ContainsKey('Path'))
                {
                    $PSBoundParameters['Path'] = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'Tests/QA'
                }

                # Find the Source Manifest under ProjectPath
                $SourceManifest = ((Get-ChildItem -Path "$ProjectPath\*\*.psd1").Where{
                        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                        $(
                            try
                            {
                                Test-ModuleManifest -Path $_.FullName -ErrorAction 'Stop'
                            }
                            catch
                            {
                                $false
                            }
                        )
                    }
                )

                $SourcePath = $SourceManifest.Directory.FullName
                $OutputPath = Join-Path -Path $ProjectPath -ChildPath 'output'

                $GetOutputModuleParams = @{
                    Path        = $OutputPath
                    Include     = $SourceManifest.Name
                    Name        = $true # Or it doesn't behave properly on PS5.1
                    Exclude     = 'RequiredModules'
                    ErrorAction = 'Stop'
                    Depth       = 3
                }

                Write-Verbose -Message (
                    "Finding Output Module with `r`n {0}" -f (
                        $GetOutputModuleParams | Format-Table -Property * -AutoSize | Out-String
                    )
                )

                $modulePsd1 = Join-Path -Path $OutputPath -ChildPath (
                    Get-ChildItem @GetOutputModuleParams |
                        Select-Object -First 1
                )

                <#
                    Importing the module psd1 ensures the filtered Import-Module
                    passthru returns only one PSModuleInfo Object: Issue #71
                #>
                $dataFileImport = Import-PowerShellDataFile -Path $modulePsd1

                Write-Verbose -Message "Loading $modulePsd1."

                $ModuleUnderTest = Import-Module -Name $modulePsd1 -ErrorAction 'Stop' -PassThru |
                    Where-Object -FilterScript {
                        $PSItem.Guid -eq $dataFileImport['GUID']
                    }
            }
        }

        $ExcludeSourceFile = foreach ($projectFileOrFolder in $ExcludeSourceFile)
        {
            if (-not [System.String]::IsNullOrEmpty($projectFileOrFolder) -and -not (Split-Path -IsAbsolute $projectFileOrFolder))
            {
                Join-Path -Path $SourcePath -ChildPath $projectFileOrFolder
            }
            elseif (-not [System.String]::IsNullOrEmpty($projectFileOrFolder))
            {
                $projectFileOrFolder
            }
        }

        if ($PSBoundParameters.ContainsKey('ExcludeSourceFile'))
        {
            $null = $PSBoundParameters.Remove('ExcludeSourceFile')
        }

        $ExcludeModuleFile = foreach ($moduleFileOrFolder in $ExcludeModuleFile)
        {
            if (-not [System.String]::IsNullOrEmpty($moduleFileOrFolder) -and -not (Split-Path -IsAbsolute $moduleFileOrFolder))
            {
                Join-Path -Path $ModuleUnderTest.ModuleBase -ChildPath $moduleFileOrFolder
            }
            elseif (-not [System.String]::IsNullOrEmpty($moduleFileOrFolder))
            {
                $moduleFileOrFolder
            }
        }

        if ($PSBoundParameters.ContainsKey('ExcludeModuleFile'))
        {
            $null = $PSBoundParameters.Remove('ExcludeModuleFile')
        }


        <#
            In case of ByProjectPath Opt-ins will be done by tags:
            The Describe Name will be one of the Tag for the Describe block
            If a Opt-In file is found, it will default to auto-populate -Tag
            (cumulative from Command parameters).
        #>
        if ($ProjectPath -and -not $PSBoundParameters.ContainsKey('TagFilter') -and -not $PSBoundParameters.ContainsKey('ExcludeTagFilter'))
        {
            $expectedMetaOptInFile = Join-Path -Path $ProjectPath -ChildPath '.MetaTestOptIn.json'

            if ($PSCmdlet.ParameterSetName -eq 'ByProjectPath' -and (Test-Path -Path $expectedMetaOptInFile))
            {
                Write-Verbose -Message "Loading OptIns from $expectedMetaOptInFile."

                $optIns = Get-StructuredObjectFromFile -Path $expectedMetaOptInFile -ErrorAction 'Stop'
            }

            # Opt-Outs should be preferred, and we can do similar ways with ExcludeTags
            $expectedMetaOptOutFile = Join-Path -Path $ProjectPath -ChildPath '.MetaTestOptOut.json'

            if ($PSCmdlet.ParameterSetName -eq 'ByProjectPath' -and (Test-Path -Path $expectedMetaOptOutFile))
            {
                Write-Verbose -Message "Loading OptOuts from $expectedMetaOptOutFile."

                $optOuts = Get-StructuredObjectFromFile -Path $expectedMetaOptOutFile -ErrorAction 'Stop'
            }
        }

        # For each Possible parameters, use BoundParameters if exists, or use $Settings.ParameterName if exists otherwise
        $possibleParamName = $PSCmdlet.MyInvocation.MyCommand.Parameters.Name

        foreach ($paramName in $possibleParamName)
        {
            if (
                -not $PSBoundParameters.ContainsKey($paramName) `
                -and ($paramValue = $Settings.($paramName))
            )
            {
                Write-Verbose -Message "Adding setting $paramName."

                $PSBoundParameters.Add($paramName, $paramValue)
            }
        }

        $newTag = @()
        $newExcludeTag = @()

        # foreach OptIns, add them to `-Tag`, unless in the ExcludeTags or already in Tag
        foreach ($optInTag in $optIns)
        {
            if (
                $optInTag -notin $PSBoundParameters['ExcludeTagFilter'] `
                -and $optInTag -notin $PSBoundParameters['TagFilter']
            )
            {
                Write-Debug -Message "Adding tag $optInTag."
                $newTag += $optInTag
            }
        }

        if ($newTag.Count -gt 0)
        {
            $PSBoundParameters['TagFilter'] = $newTag
        }

        # foreach OptOuts, add them to `-ExcludeTag`, unless in `-Tag`
        foreach ($optOutTag in $optOuts)
        {
            if (
                $optOutTag -notin $PSBoundParameters['TagFilter'] `
                -and $optOutTag -notin $PSBoundParameters['ExcludeTagFilter']
            )
            {
                Write-Debug -Message "Adding ExcludeTag $optOutTag."

                $newExcludeTag += $optOutTag
            }
        }

        if ($newExcludeTag.Count -gt 0)
        {
            $PSBoundParameters['ExcludeTagFilter'] = $newExcludeTag
        }

        <#
            This won't display the warning message for the skipped blocks
            But should save time by not running initialization code within a Describe Block
            And we can add such warning if we create a static list of the things we can opt-in
            I'd prefer to not keep anything static, and AST risks not to cover 100% (maybe...), and OptOut is preferred

            Most tests should run against the built module
            PSSA could be run against source, or against built module & convert lines/file
        #>

        $ModuleUnderTestManifest = Join-Path -Path $ModuleUnderTest.ModuleBase -ChildPath "$($ModuleUnderTest.Name).psd1"

        $isPester5 = (Get-Module -Name 'Pester').Version -ge '5.0.0'

        if (-not $isPester5)
        {
            $ScriptItems = foreach ($item in $PSBoundParameters['Path'])
            {
                if ($item -is [System.Collections.IDictionary])
                {
                    if ($item['Parameters'] -isNot [System.Collections.IDictionary])
                    {
                        $item['Parameters'] = @{ }
                    }
                    $item['Parameters']['ModuleBase'] = $ModuleUnderTest.ModuleBase
                    $item['Parameters']['ModuleName'] = $ModuleUnderTest.Name
                    $item['Parameters']['ModuleManifest'] = $ModuleUnderTestManifest
                    $item['Parameters']['ProjectPath'] = $ProjectPath
                    $item['Parameters']['SourcePath'] = $SourcePath
                    $item['Parameters']['SourceManifest'] = $SourceManifest.FullName
                    $item['Parameters']['Tag'] = $PSBoundParameters['TagFilter']
                    $item['Parameters']['ExcludeTag'] = $PSBoundParameters['ExcludeTagFilter']
                    $item['Parameters']['ExcludeModuleFile'] = $ExcludeModuleFile
                    $item['Parameters']['ExcludeSourceFile'] = $ExcludeSourceFile
                    $item['Parameters']['MainGitBranch'] = $MainGitBranch
                }
                else
                {
                    $item = @{
                        Path       = $item
                        Parameters = @{
                            ModuleBase         = $ModuleUnderTest.ModuleBase
                            ModuleName         = $ModuleUnderTest.Name
                            ModuleManifest     = $ModuleUnderTestManifest
                            ProjectPath        = $ProjectPath
                            SourcePath         = $SourcePath
                            SourceManifest     = $SourceManifest.FullName
                            Tag                = $PSBoundParameters['TagFilter']
                            ExcludeTag         = $PSBoundParameters['ExcludeTagFilter']
                            ExcludeModuleFile  = $ExcludeModuleFile
                            ExcludeSourceFile  = $ExcludeSourceFile
                            MainGitBranch      = $MainGitBranch
                        }
                    }
                }

                $item
            }

            $PSBoundParameters['Path'] = $ScriptItems
        }

        $invokePesterParameters = @{
            PassThru = $PSBoundParameters.PassThru
        }

        if ($isPester5)
        {
            $invokePesterParameters['Path'] = $PSBoundParameters.Path

            if ($PSBoundParameters.ContainsKey('TagFilter'))
            {
                $invokePesterParameters['TagFilter'] = $PSBoundParameters.TagFilter
            }

            if ($PSBoundParameters.ContainsKey('ExcludeTagFilter'))
            {
                $invokePesterParameters['ExcludeTagFilter'] = $PSBoundParameters.ExcludeTagFilter
            }

            if ($PSBoundParameters.ContainsKey('Output'))
            {
                $invokePesterParameters['Output'] = $PSBoundParameters.Output
            }

            if ($PSBoundParameters.ContainsKey('FullNameFilter'))
            {
                $invokePesterParameters['FullNameFilter'] = $PSBoundParameters.TestName
            }
        }
        else
        {
            $invokePesterParameters['Script'] = $PSBoundParameters.Path

            if ($PSBoundParameters.ContainsKey('TestName'))
            {
                $invokePesterParameters['TestName'] = $PSBoundParameters.TestName
            }

            if ($PSBoundParameters.ContainsKey('EnableExit'))
            {
                $invokePesterParameters['EnableExit'] = $PSBoundParameters.EnableExit
            }

            if ($PSBoundParameters.ContainsKey('TagFilter'))
            {
                $invokePesterParameters['Tag'] = $PSBoundParameters.TagFilter
            }

            if ($PSBoundParameters.ContainsKey('ExcludeTagFilter'))
            {
                $invokePesterParameters['ExcludeTag'] = $PSBoundParameters.ExcludeTagFilter
            }

            if ($PSBoundParameters.ContainsKey('OutputFile'))
            {
                $invokePesterParameters['OutputFile'] = $PSBoundParameters.OutputFile
            }

            if ($PSBoundParameters.ContainsKey('OutputFormat'))
            {
                $invokePesterParameters['OutputFormat'] = $PSBoundParameters.OutputFormat
            }

            if ($PSBoundParameters.ContainsKey('CodeCoverage'))
            {
                $invokePesterParameters['CodeCoverage'] = $PSBoundParameters.CodeCoverage
            }

            if ($PSBoundParameters.ContainsKey('CodeCoverageOutputFile'))
            {
                $invokePesterParameters['CodeCoverageOutputFile'] = $PSBoundParameters.CodeCoverageOutputFile
            }

            if ($PSBoundParameters.ContainsKey('CodeCoverageOutputFileFormat'))
            {
                $invokePesterParameters['CodeCoverageOutputFileFormat'] = $PSBoundParameters.CodeCoverageOutputFileFormat
            }

            if ($PSBoundParameters.ContainsKey('PesterOption'))
            {
                $invokePesterParameters['PesterOption'] = $PSBoundParameters.PesterOption
            }

            if ($PSBoundParameters.ContainsKey('Show'))
            {
                $invokePesterParameters['Show'] = $PSBoundParameters.Show
            }
        }

        # Below is default command proxy handling
        try
        {
            $outBuffer = $null

            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref] $outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = Get-Command -CommandType 'Function' -Name 'Invoke-Pester'

            $scriptCmd = {
                & $wrappedCmd @invokePesterParameters
            }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline()

            $steppablePipeline.Begin($PSCmdlet)
        }
        catch
        {
            throw
        }
    }

    process
    {
        try
        {
            $steppablePipeline.Process($_)
        }
        catch
        {
            throw
        }
    }

    end
    {
        try
        {
            $steppablePipeline.End()
        }
        catch
        {
            throw
        }
    }
}
#EndRegion './Public/Invoke-DscResourceTest.ps1' 542
#Region './Public/New-DscSelfSignedCertificate.ps1' 0

<#
    .SYNOPSIS
        This command will create a new self-signed certificate to be used to
        compile configurations.

    .OUTPUTS
        Returns the created certificate. Writes the path to the public
        certificate in the machine environment variable $env:DscPublicCertificatePath,
        and the certificate thumbprint in the machine environment variable
        $env:DscCertificateThumbprint.

    .NOTES
        If a certificate with subject 'DscEncryptionCert' already exists, that
        certificate will be returned instead of creating a new, and will assume
        that the existing certificate was created with this command.
#>
function New-DscSelfSignedCertificate
{
    $dscPublicCertificatePath = Join-Path -Path $env:temp -ChildPath 'DscPublicKey.cer'

    $certificateSubject = 'TestDscEncryptionCert'

    # Look if there already is an existing certificate.
    $certificate = Get-ChildItem -Path 'cert:\LocalMachine\My' |
        Where-Object -FilterScript {
            $_.Subject -eq "CN=$certificateSubject"
        } | Select-Object -First 1

    if (-not $certificate)
    {
        $getCommandParameters = @{
            Name        = 'New-SelfSignedCertificate'
            ErrorAction = 'SilentlyContinue'
        }

        $newSelfSignedCertificateCommand = Get-Command @getCommandParameters

        $hasNewSelfSignedCertificateCommand = $newSelfSignedCertificateCommand `
            -and $newSelfSignedCertificateCommand.Parameters.Keys -contains 'Type'

        if ($hasNewSelfSignedCertificateCommand)
        {
            $newSelfSignedCertificateParameters = @{
                Type          = 'DocumentEncryptionCertLegacyCsp'
                DnsName       = $certificateSubject
                HashAlgorithm = 'SHA256'
            }

            $certificate = New-SelfSignedCertificate @newSelfSignedCertificateParameters
        }
        else
        {
            <#
                There are build workers still on Windows Server 2012 R2 so let's
                use the alternate method of New-SelfSignedCertificate.
            #>
            # If you use this, declare PSPKI in RequiredModules, or install it
            Import-Module -Name PSPKI -ErrorAction Stop

            $newSelfSignedCertificateExParameters = @{
                Subject            = "CN=$certificateSubject"
                EKU                = 'Document Encryption'
                KeyUsage           = 'KeyEncipherment, DataEncipherment'
                SAN                = "dns:$certificateSubject"
                FriendlyName       = 'DSC Credential Encryption certificate'
                Exportable         = $true
                StoreLocation      = 'LocalMachine'
                KeyLength          = 2048
                ProviderName       = 'Microsoft Enhanced Cryptographic Provider v1.0'
                AlgorithmName      = 'RSA'
                SignatureAlgorithm = 'SHA256'
            }

            $certificate = New-SelfSignedCertificateEx @newSelfSignedCertificateExParameters
        }

        Write-Verbose -Message ('Created self-signed certificate ''{0}'' with thumbprint ''{1}''.' -f $certificate.Subject, $certificate.Thumbprint)
    }
    else
    {
        Write-Verbose -Message ('Using self-signed certificate ''{0}'' with thumbprint ''{1}''.' -f $certificate.Subject, $certificate.Thumbprint)
    }

    # Export the public key certificate
    Export-Certificate -Cert $certificate -FilePath $dscPublicCertificatePath -Force

    # Update a machine and session environment variable with the path to the public certificate.
    Set-EnvironmentVariable -Name 'DscPublicCertificatePath' -Value $dscPublicCertificatePath -Machine
    Write-Verbose -Message ('Environment variable $env:DscPublicCertificatePath set to ''{0}''' -f $env:DscPublicCertificatePath)

    # Update a machine and session environment variable with the thumbprint of the certificate.
    Set-EnvironmentVariable -Name 'DscCertificateThumbprint' -Value $certificate.Thumbprint -Machine
    Write-Verbose -Message ('Environment variable $env:DscCertificateThumbprint set to ''{0}''' -f $env:DscCertificateThumbprint)

    return $certificate
}
#EndRegion './Public/New-DscSelfSignedCertificate.ps1' 97
#Region './Public/Restore-TestEnvironment.ps1' 0
<#
    .SYNOPSIS
        Restores the environment after running unit or integration tests
        on a DSC resource.

        This restores the following changes made by calling
        Initialize-TestEnvironment:
        1. Restores the $env:PSModulePath if it was changed.
        2. Restores the PowerShell execution policy.
        3. Resets the DSC LCM if running Integration tests.

    .PARAMETER TestEnvironment
        The hashtable created by the Initialize-TestEnvironment.

    .EXAMPLE
        Restore-TestEnvironment -TestEnvironment $TestEnvironment
#>
function Restore-TestEnvironment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $TestEnvironment
    )

    Write-Verbose -Message "Cleaning up Test Environment after $($TestEnvironment.TestType) testing of $($TestEnvironment.DSCResourceName) in module $($TestEnvironment.DSCModuleName)."

    if ($TestEnvironment.TestType -in ('Integration','All'))
    {
        # Clear the DSC LCM & Configurations
        Clear-DscLcmConfiguration
    }

    # Restore PSModulePath
    if ($TestEnvironment.OldPSModulePath -ne $env:PSModulePath)
    {
        Set-PSModulePath -Path $TestEnvironment.OldPSModulePath

        if ($TestEnvironment.TestType -in ('Integration','All'))
        {
            # Restore the machine PSModulePath for integration tests.
            Set-PSModulePath -Path $TestEnvironment.OldPSModulePath -Machine
        }
    }

    # Restore the Execution Policy
    if ($TestEnvironment.OldExecutionPolicy -ne (Get-ExecutionPolicy))
    {
        Set-ExecutionPolicy -ExecutionPolicy $TestEnvironment.OldExecutionPolicy -Scope 'Process' -Force
    }

    if ($script:MachineOldPSModulePath)
    {
        [System.Environment]::SetEnvironmentVariable('PSModulePath', $script:MachineOldPSModulePath, 'Machine')
    }

    if ($script:MachineOldExecutionPolicy)
    {
        Set-ExecutionPolicy -ExecutionPolicy $script:MachineOldExecutionPolicy -Scope LocalMachine -Force -ErrorAction Stop

        $script:MachineOldExecutionPolicy = $null
    }
}
#EndRegion './Public/Restore-TestEnvironment.ps1' 66
