$script:ParentModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:ParentModulePath -ChildPath 'Modules'

$script:CommonHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.Common'
Import-Module $script:CommonHelperModulePath -ErrorAction Stop

$script:localizedData = Get-LocalizedData -DefaultUICulture en-US

<#
    .SYNOPSIS
        Returns the current state of the PostgreSql install.

    .PARAMETER Ensure
        Specify if PostgreSQL should be absent or present.

    .PARAMETER Version
        The version of PostgreSQL that is going to be install or uninstalled.

    .PARAMETER InstallerPath
        The full path to the EDB PostgreSql installer.
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
    $registryKeys = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript {$_.Name -eq "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PostgreSQL $Version"}

    if ($null -eq $registryKeys)
    {
        Write-Verbose -Message ($script:localizedData.NoVersionFound)

        $getResults =  @{
            Ensure           = 'Absent'
            InstallerPath    = $InstallerPath
            Version          = $Version
            InstallDirectory = $null
            ServiceName      = $null
            ServiceAccount   = $null
            DataDirectory    = $null
            ServerPort       = $null
            Features         = $null
        }
    }
    else
    {
        $prefixRegistry = $registryKeys.GetValue('InstallLocation')

        # Search Services for PostgreSQL so we can get the status of the service.
        Write-Verbose -Message ($script:localizedData.CheckingForService)
        $services = Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services'
        foreach ($service in $services)
        {
            $value = Get-ItemProperty -Path $service.PSPath -Name ImagePath -ErrorAction SilentlyContinue

            if ($value.ImagePath -like "*$prefixRegistry*")
            {
                $result = $service
            }
        }

        if ($result)
        {
            $serviceDisplayName = ($result.GetValue('DisplayName') -split ' - ')[0]
            $serviceLogon = $result.GetValue('ObjectName')
            $serviceDataDir = (($result.GetValue('ImagePath') -split ' -D')[1] -split ' -w')[0].Trim().Replace('"','')
        }

        # Open config to check port.
        Write-Verbose -Message ($script:localizedData.CheckingConfig)
        $conf = Get-Content -Path "$serviceDataDir\postgresql.conf"
        foreach ($line in $conf)
        {
            if ($line -like 'port =*')
            {
                $confPort = $line.Substring(7,8).Trim()
            }
        }

        # Check licenses that are in the install dir to see what features are installed.
        Write-Verbose -Message ($script:localizedData.CheckingFeatures)
        $files = Get-ChildItem -Path $prefixRegistry -Name '*license*'

        $installedFeatures = @()
        if ($files -contains 'commandlinetools_3rd_party_licenses.txt')
        {
            $installedFeatures += 'commandlinetools'
        }
        if ($files -contains 'pgAdmin_license.txt')
        {
            $installedFeatures += 'pgAdmin'
        }
        if ($files -contains 'server_license.txt')
        {
            $installedFeatures += 'server'
        }
        if ($files -contains 'StackBuilder_3rd_party_licenses.txt')
        {
            $installedFeatures += 'stackbuilder'
        }

        Write-Verbose -Message ($script:localizedData.FoundKeysForVersion -f $Version)

        $getResults = @{
            Ensure           = 'Present'
            Version          = $Version
            InstallerPath    = $InstallerPath
            InstallDirectory = $prefixRegistry
            ServiceName      = $serviceDisplayName
            ServiceAccount   = $serviceLogon
            DataDirectory    = $serviceDataDir
            ServerPort       = $confPort
            Features         = $installedFeatures
        }
    }

    return $getResults
}

<#
    .SYNOPSIS
        Installs or Uninstalls PostgreSQL.

    .PARAMETER Ensure
        Specify if PostgreSQL should be absent or present.

    .PARAMETER Version
        The version of PostgreSQL that is going to be installed or uninstalled.

    .PARAMETER InstallerPath
       The full path to the EDB PostgreSql installer.

    .PARAMETER ServiceName
        The name of the Windows service that PostgreSql will run under.

    .PARAMETER InstallationDirectory
        The folder path that PostgreSql should be installed to.

    .PARAMETER ServerPort
        The port that PostgreSql will listen on for incoming connections.

    .PARAMETER DataDirectory
        The path for all the data from this PostgreSql install.

    .PARAMETER ServiceAccount
        The account that will be used to run the service.

    .PARAMETER SuperAccount
        The account that will be the super account in PostgreSQL.

    .PARAMETER Features
        The PostgreSql features to install.

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
        [ValidateScript( {$_ -notmatch '\s'})]
        [System.String]
        $ServiceName,

        [Parameter()]
        [System.String]
        $InstallDirectory,

        [Parameter()]
        [System.UInt16]
        $ServerPort,

        [Parameter()]
        [System.String]
        $DataDirectory,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
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
        if (-not (Test-Path -Path $InstallerPath))
        {
            throw ($script:localizedData.PathIsMissing -f $InstallerPath)
        }

        $arguments = @(
            "--unattendedmodeui none"
            "--mode unattended"
        )

        $argumentParameters = @('servicename', 'InstallDirectory', 'DataDirectory', 'serverport', 'features', 'optionfile')

        foreach ($arg in $argumentParameters)
        {
            if (-not [string]::IsNullOrEmpty($PSBoundParameters[$arg]))
            {
                if ($arg -eq 'ServiceName')
                {
                    $arguments += '--servicename "{0}"' -f $ServiceName
                    Write-Verbose -Message ($script:localizedData.ParameterSetTo -f $arg, $ServiceName)
                }
                elseif ($arg -eq 'features')
                {
                    $featuresToString = ($PSBoundParameters[$arg] -join ',').ToLower()
                    $finalFeatureString = $featuresToString.Replace('pgadmin', 'pgAdmin')
                    $arguments += '--enable-components "{0}"' -f $finalFeatureString
                    Write-Verbose -Message ($script:localizedData.ParameterSetTo -f 'enable-components', $finalFeatureString)
                }
                elseif ($arg -eq 'DataDirectory')
                {
                    $arguments += '--datadir "{0}"' -f $($PSBoundParameters[$arg])
                    Write-Verbose -Message ($script:localizedData.ParameterSetTo -f 'datadir', $($PSBoundParameters[$arg]))
                }
                elseif ($arg -eq 'InstallDirectory')
                {
                    $arguments += '--prefix "{0}"' -f $($PSBoundParameters[$arg])
                    Write-Verbose -Message ($script:localizedData.ParameterSetTo -f 'prefix', $($PSBoundParameters[$arg]))
                }
                else
                {
                    $arguments += '--{0} "{1}"' -f $arg, $($PSBoundParameters[$arg])
                    Write-Verbose -Message ($script:localizedData.ParameterSetTo -f $arg, $($PSBoundParameters[$arg]))
                }
            }
        }

        $builtinAccounts = @('NT AUTHORITY\NetworkService', 'NT AUTHORITY\System', 'NT AUTHORITY\Local Service')
        if (-not ($null -eq $ServiceAccount))
        {
            $arguments += '--serviceaccount "{0}"' -f $($ServiceAccount.UserName)
            Write-Verbose -Message ($script:localizedData.ParameterSetTo -f 'serviceaccount', $($ServiceAccount.UserName))

            if (-not ($ServiceAccount.UserName -in $builtinAccounts))
            {
                $arguments += '--servicepassword "{0}"' -f $($ServiceAccount.GetNetworkCredential().Password)
            }
        }

        if (-not ($null -eq $SuperAccount))
        {
            $arguments += '--superaccount "{0}"' -f $($SuperAccount.UserName)
            Write-Verbose -Message ($script:localizedData.ParameterSetTo -f 'SuperAccount', $($SuperAccount.UserName))

            $arguments += '--superpassword "{0}"' -f $($SuperAccount.GetNetworkCredential().Password)
        }

        $displayArguments = $arguments.Clone()
        $i = 0
        foreach ($arg in $displayArguments)
        {
            if ($arg -match '--superpassword' -or $arg -match '--servicepassword')
            {
                $displayArguments[$i] = $arg.Split(' ')[0] + ' *******'
            }
            $i++
        }

        Write-Verbose -Message ($script:localizedData.StartingInstall)
        Write-Verbose -Message ($script:localizedData.InstallString -f $InstallerPath, $($displayArguments -join ' '))
        $process = Start-Process $InstallerPath -ArgumentList ($arguments -join ' ') -Wait -PassThru -NoNewWindow
        $exitCode = $process.ExitCode

        if ($exitCode -eq 0 -or $exitCode -eq 1641 -or $exitCode -eq 3010)
        {
            Write-Verbose -Message ($script:localizedData.PostgreSqlSuccess -f 'installed', $exitCode)
        }
        else
        {
            $logPath = "$env:TEMP\instabuilder_installer.log"
            throw ($script:localizedData.PostgreSqlFailed -f 'install', $exitCode, $logPath)
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SearchingRegistry -f $Version)
        $uninstallRegistry = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript {$_.Name -eq "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PostgreSQL $Version"}
        $uninstallString = $uninstallRegistry.GetValue('UninstallString')

        Write-Verbose -Message ($script:localizedData.PosgreSqlUninstall)
        Write-Verbose -Message ($script:localizedData.UninstallString -f $uninstallString, '--mode unattended')
        $process = Start-Process -FilePath $uninstallString -ArgumentList '--mode unattended' -Wait
        $exitCode = $process.ExitCode

        if ($exitCode -eq 0 -or $null -eq $exitCode)
        {
            Write-Verbose -Message ($script:localizedData.PostgreSqlSuccess -f 'uninstalled', $exitCode)
        }
        else
        {
            $logPath = "$env:TEMP\instabuilder_installer.log"
            throw  ($script:localizedData.PostgreSqlFailed -f 'uninstall', $exitCode, $logPath)
        }
    }
}

<#
    .SYNOPSIS
        Checks if the current status of PostgreSQL is the same as what is to be configured.

    .PARAMETER Ensure
        Specify if PostgreSQL should be absent or present.

    .PARAMETER Version
        The version of PostgreSQL that is going to be installed or uninstalled.

    .PARAMETER InstallerPath
       The full path to the EDB PostgreSql installer.

    .PARAMETER ServiceName
        The name of the Windows service that PostgreSql will run under.

    .PARAMETER InstallDirectory
        The folder path that PostgreSql should be installed to.

    .PARAMETER ServerPort
        The server port that PostgreSql will listen on for incoming connections.

    .PARAMETER DataDirectory
        The path for all the data from this PostgreSql install.

    .PARAMETER ServiceAccount
        The account that will be used to run the service.

    .PARAMETER SuperAccount
        The account that will be the super account in PostgreSQL.

    .PARAMETER Features
        The PostgreSql features to install.

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
        $InstallDirectory,

        [Parameter()]
        [System.UInt16]
        $ServerPort,

        [Parameter()]
        [System.String]
        $DataDirectory,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SuperAccount,

        [Parameter()]
        [System.String[]]
        $Features,

        [Parameter()]
        [System.String]
        $OptionFile
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
        else
        {
            if ($getTargetResourceResults.Version -ne $Version)
            {
                Write-Warning -Message ($script:localizedData.MismatchWarning -f 'Version', $Version, $getTargetResourceResults.Version)
            }
            if ($getTargetResourceResults.ServiceName -ne $ServiceName -and $null -ne $ServiceName)
            {
                Write-Warning -Message ($script:localizedData.MismatchWarning -f 'ServiceName', $ServiceName, $getTargetResourceResults.ServiceName)
            }
            if ($getTargetResourceResults.InstallDirectory -ne $InstallDirectory -and $null -ne $InstallDirectory)
            {
                Write-Warning -Message ($script:localizedData.MismatchWarning -f 'InstallDirectory', $InstallDirectory, $getTargetResourceResults.InstallDirectory)
            }
            if ($getTargetResourceResults.ServerPort -ne $ServerPort -and $null -ne $ServerPort)
            {
                Write-Warning -Message ($script:localizedData.MismatchWarning -f 'ServerPort', $ServerPort, $getTargetResourceResults.ServerPort)
            }
            if ($getTargetResourceResults.DataDirectory -ne $DataDirectory -and $null -ne $DataDirectory)
            {
            Write-Warning -Message ($script:localizedData.MismatchWarning -f 'DataDirectory', $DataDirectory, $getTargetResourceResults.DataDirectory)
            }
            if ($getTargetResourceResults.ServiceAccount -ne $ServiceAccount.UserName -and $null -ne $ServiceAccount)
            {
                Write-Warning -Message ($script:localizedData.MismatchWarning -f 'ServiceAccount', $ServiceAccount.UserName, $getTargetResourceResults.ServiceAccount)
            }
            if ($null -ne $getTargetResourceResults.Features)
            {
                $featureArray = $getTargetResourceResults.Features -Split ','
                foreach ($feature in $Features)
                {
                    if ($featureArray -notcontains $feature)
                    {
                        Write-Warning -Message ($script:localizedData.MissingFeature -f $feature)
                    }
                }

                foreach ($feature in $featureArray)
                {
                    if ($Features -notcontains $feature)
                    {
                        Write-Warning -Message ($script:localizedData.ExtraFeature -f $feature)
                    }
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

Export-ModuleMember -Function *-TargetResource
