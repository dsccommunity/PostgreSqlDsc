$script:ParentModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:ParentModulePath -ChildPath 'Modules'

$script:CommonHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.Common'
#$script:ResourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'Folder.Common'
Import-Module $script:CommonHelperModulePath -ErrorAction Stop
#Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'Folder.Common.psm1')

$script:localizedData = Get-LocalizedData -DefaultUICulture en-US

<#
    .SYNOPSIS
        Returns the current state of the folder.

    .PARAMETER Ensure
        Specify if PostgreSQL should be absent or present

    .PARAMETER Version
        The version of PostgreSQL that is going to be install or uninstalled.

    .PARAMETER InstallerPath
       The full path to the EDB Postgres installer.

    .NOTES
        The ReadOnly parameter was made mandatory in this example to show
        how to handle unused mandatory parameters.
        In a real scenario this parameter would not need to have the type
        qualifier Required in the schema.mof.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateSet('9', '10', '11', '12', '13')]
        [System.String]
        $Version,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallerPath
    )

    Write-Verbose -Message ($script:localizedData.SearchingRegistry -f $Version)
    $registryKeys = Get-ChildItem -Path 'HKLM:\\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript {$_.Name -match "PostgreSQL $Version"}
    if ($null -eq $registryKeys)
    {
        Write-Verbose -Message ($script:localizedData.NoVersionFound)
        $getResults =  @{
            Ensure          = "Absent"
            InstallerPath   = $InstallerPath
            Version         = $Version
        }
    }
    else
    {
        $prefixRegistry = $registryKeys.GetValue('InstallLocation')

        # Search Services for PostgreSQL so we can get the status of the service.
        Write-Verbose -Message ($script:localizedData.CheckingForService)
        $services = Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Services
        foreach ($service in $services)
        {
            $value = Get-ItemProperty -Path $service.PSPath -Name ImagePath -ErrorAction SilentlyContinue

            if($value.ImagePath -like "*$prefixRegistry*")
            {
                $result = $service
            }
        }
        if($result)
        {
            $serviceDisplayName = ($result.GetValue('DisplayName') -split ' - ')[0]
            $serviceLogon = $result.GetValue('ObjectName')
            $serviceDataDir = (($result.GetValue('ImagePath') -split ' -D')[1] -split ' -w')[0].Trim().Replace('"','')
        }

        #Open config to check port
        Write-Verbose -Message ($script:localizedData.CheckingConfig)
        $conf = Get-Content -Path $serviceDataDir\postgresql.conf
        foreach ($line in $conf)
        {
            if ($line -like 'port =*')
            {
                $confPort = $line.Substring(7,8).Trim()
            }
        }

        # Check licenses that are in the install dir to see what features are installed
        Write-Verbose -Message ($script:localizedData.CheckingFeatures)
        $files = Get-ChildItem 'C:\Program Files\PostgreSQL\12' -Name '*license*'

        $installedFeatures = @()
        if($files -match 'commandlinetools')
        {
            $installedFeatures += 'commandlinetools'
        }
        if($files -match 'pgAdmin')
        {
            $installedFeatures += 'pgAdmin'
        }
        if($files -match 'server')
        {
            $installedFeatures += 'server'
        }
        if($files -match 'StackBuilder')
        {
            $installedFeatures += 'stackbuilder'
        }

        Write-Verbose -Message ($script:localizedData.FoundKeysForVersion -f $Version)
        $getResults = @{
            Ensure          = 'Present'
            Version         = $registryKeys.GetValue('DisplayVersion')
            InstallerPath   = $InstallerPath
            Prefix          = $prefixRegistry
            ServiceName     = $serviceDisplayName
            ServiceAccount  = $serviceLogon
            DataDir         = $serviceDataDir
            Port            = $confPort
            Features        = $installedFeatures -join ','
        }
    }

    return $getResults
}

<#
    .SYNOPSIS
        Creates or removes the folder.

    .PARAMETER Ensure
        Specify if PostgreSQL should be absent or present

    .PARAMETER Version
        The version of PostgreSQL that is going to be install or uninstalled.

    .PARAMETER InstallerPath
       The full path to the EDB Postgres installer.

    .PARAMETER ServiceName
        The name of the windows service that postgres will run under.

    .PARAMETER Prefix
        The folder path that Postgre should be installed to.

    .PARAMETER Port
        The port that Postgres will listen on for incoming connections.

    .PARAMETER DataDir
        The path for all the data from this Postgres install.

    .PARAMETER ServiceAccount
        The account that will be used to run the service.

    .PARAMETER SuperAccount
        The account that will be the super account in PostgreSQL.

    .PARAMETER Features
        The Postgres features to install.

    .PARAMETER OptionFile
        The file that has options for the install.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateSet('9', '10', '11', '12', '13')]
        [System.String]
        $Version,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallerPath,

        [Parameter()]
        [System.String]
        $ServiceName,

        [Parameter()]
        [System.String]
        $Prefix,

        [Parameter()]
        [System.UInt16]
        $Port,

        [Parameter()]
        [System.String]
        $DataDir,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SuperAccount,

        [Parameter()]
        [System.String[]]
        $Features,

        [Parameter()]
        [System.String]
        $OptionFile
    )

    if ($Ensure -eq 'Present')
    {

        $arguments = @(
            "--unattendedmodeui none"
            "--mode unattended"
        )

        $argumentParameters = @('servicename', 'prefix', 'datair', 'port', 'features', 'optionfile')

        foreach ($arg in $argumentParameters)
        {
            if (-not [string]::IsNullOrEmpty($PSBoundParameters[$arg]))
            {
                if ($arg -eq 'ServiceName')
                {
                    $finalServiceName = $ServiceName.Replace(" ", "_")
                    $arguments += "--servicename `"$finalServiceName`""
                    Write-Verbose -Message ($script:localizedData.ParameterSetTo -f $arg, $finalServiceName)
                }
                else
                {
                    $arguments += "--$arg `"$($PSBoundParameters[$arg])`""
                    Write-Verbose -Message ($script:localizedData.ParameterSetTo -f $arg, $($PSBoundParameters[$arg]))
                }
            }
        }

        $builtinAccounts = @('NT AUTHORITY\NetworkService', 'NT AUTHORITY\System', 'NT AUTHORITY\Local Service')
        if (-not ($null -eq $ServiceAccount))
        {
            $arguments += "--serviceaccount `"$($ServiceAccount.UserName)`""
            Write-Verbose -Message ($script:localizedData.ParameterSetTo -f "serviceaccount", $($ServiceAccount.UserName))

            if (-not ($ServiceAccount.UserName -in $builtinAccounts))
            {
                $arguments += "--servicepassword $($ServiceAccount.GetNetworkCredential().Password)"
            }
        }

        if (-not ($null -eq $SuperAccount))
        {
            $arguments += "--superaccount `"$($SuperAccount.UserName)`""
            Write-Verbose -Message ($script:localizedData.ParameterSetTo -f "SuperAccount", $($SuperAccount.UserName))

            $arguments += "--superpassword `"$($SuperAccount.GetNetworkCredential().Password)`""
        }

        Write-Verbose -Message ($script:localizedData.StartingInstall)
        $process = Start-Process $InstallerPath -ArgumentList ($Arguments -join " ") -Wait -PassThru -NoNewWindow
        $exitCode = $process.ExitCode

        if ($exitCode -ne 0 -or $exitCode -ne 1641 -or $exitCode -ne 3010)
        {
            throw ($script:localizedData.PostgreSqlFailed -f "install", $exitCode)
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.PostgreSqlSuccess -f "installed", $exitCode)
        }
    }
    else
    {
        $uninstallRegistry = Get-ChildItem -Path 'HKLM:\\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript {$_.Name -match "PostgreSQL $Version"}
        $uninstallString = $uninstallRegistry.GetValue('UninstallString')

        $process = Start-Process -FilePath $uninstallString -ArgumentList '--mode unattended' -Wait
        $exitCode = $process.ExitCode

        if ($exitCode -ne 0)
        {
            throw  ($script:localizedData.PostgreSqlFailed -f "uninstall", $exitCode)
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.PostgreSqlSuccess -f "uninstalled", $exitCode)
        }
    }
}

<#
    .SYNOPSIS
        Creates or removes the folder.

    .PARAMETER Ensure
        Specify if PostgreSQL should be absent or present

    .PARAMETER Version
        The version of PostgreSQL that is going to be install or uninstalled.

    .PARAMETER InstallerPath
       The full path to the EDB Postgres installer.

    .PARAMETER ServiceName
        The name of the windows service that postgres will run under.

    .PARAMETER Prefix
        The folder path that Postgre should be installed to.

    .PARAMETER Port
        The port that Postgres will listen on for incoming connections.

    .PARAMETER DataDir
        The path for all the data from this Postgres install.

    .PARAMETER ServiceAccount
        The account that will be used to run the service.

    .PARAMETER SuperAccount
        The account that will be the super account in PostgreSQL.

    .PARAMETER Features
        The Postgres features to install.

    .PARAMETER OptionFile
        The file that has options for the install.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidateSet('9', '10', '11', '12', '13')]
        [System.String]
        $Version,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallerPath,

        [Parameter()]
        [System.String]
        $ServiceName,

        [Parameter()]
        [System.String]
        $Prefix,

        [Parameter()]
        [System.UInt16]
        $Port,

        [Parameter()]
        [System.String]
        $DataDir,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter()]
        [System.String[]]
        $Features
    )

    $getTargetResourceParameters = @{
        Ensure        = $Ensure
        Version       = $Version
        InstallerPath = $InstallerPath
    }

    $getTargetResourceResults = Get-TargetResource @getTargetResourceParameters
    $result = $true

    if ($Ensure -eq 'Present')
    {
        if ($getTargetResourceResults.Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($script:localizedData.MismatchSetting -f 'Ensure', $Ensure, $getTargetResourceResults.Ensure, 'false')
            $result = $false
        }
        if ($getTargetResourceResults.Version -ne $Version)
        {
            Write-Warning -Message ($script:localizedData.MismatchWarning -f "Version", $Version, $getTargetResourceResults.Version)
        }
        if ($getTargetResourceResults.ServiceName -ne $ServiceName)
        {
            Write-Warning -Message ($script:localizedData.MismatchWarning -f "ServiceName", $ServiceName, $getTargetResourceResults.ServiceName)
        }
        if ($getTargetResourceResults.Prefix -ne $Prefix)
        {
            Write-Warning -Message ($script:localizedData.MismatchWarning -f "Prefix", $Prefix, $getTargetResourceResults.Prefix)
        }
        if ($getTargetResourceResults.Port -ne $Port)
        {
            Write-Warning -Message ($script:localizedData.MismatchWarning -f "Port", $Port, $getTargetResourceResults.Port)
        }
        if ($getTargetResourceResults.DataDir -ne $DataDir)
        {
            Write-Warning -Message ($script:localizedData.MismatchWarning -f "DataDir", $DataDir, $getTargetResourceResults.DataDir)
        }
        if ($getTargetResourceResults.ServiceAccount -ne $ServiceAccount.UserName)
        {
            Write-Warning -Message ($script:localizedData.MismatchWarning -f "ServiceAccount", $ServiceAccount.UserName, $getTargetResourceResults.ServiceAccount)
        }
        if ($null -ne $getTargetResourceResults.Features)
        {
            foreach ($feature in $Features)
            {
                if ($getTargetResourceResults.Features -notcontains $feature)
                {
                    $result = $false
                }
            }
        }
    }
    else
    {
        if ($getTargetResourceResults.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.MismatchSetting -f 'Ensure', $Ensure, $getTargetResourceResults.Ensure, 'false')
            $result = $false
        }
    }

    return $result
}
