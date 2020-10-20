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
        [System.String]
        $Features,

        [Parameter()]
        [System.String]
        $OptionFile
    )

    $uninstallRegistry = Get-ChildItem -Path 'HKLM:\\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript {$_.Name -match "PostgreSQL $Version"}
    if ($null -eq $uninstallRegistry)
    {
        return @{
            Ensure          = "Absent"
            InstallerPath   = $null
            Version         = $null
        }
    }


    # Placeholder to test Set-Target
    return @{
        Ensure          = 'Present'
        Version         = $uninstallRegistry.GetValue('DisplayVersion')
        InstallerPath   = $uninstallRegistry.GetValue('UninstallString')
        ServiceName     = $uninstallRegistry.GetValue('DisplayName')
        Prefix          = $uninstallRegistry.GetValue('InstallLocation')
        ServiceAccount  = (Get-WmiObject win32_service | where {$_.DisplayName -match 'WLAN'} | Select-Object -ExpandProperty StartName)
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
        [System.String]
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
        [System.Management.Automation.PSCredential]
        $SuperAccount,

        [Parameter()]
        [System.String]
        $Features,

        [Parameter()]
        [System.String]
        $OptionFile
    )

    # Check for the correct registry key in Uninstall?
    $uninstallRegistry = Get-ChildItem -Path 'HKLM:\\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' | Where-Object -FilterScript {$_.Name -match "PostgreSQL $Version"}
    if ($null -eq $uninstallRegistry)
    {
        return $false
    }
    $Version = $uninstallRegistry.GetValue('DisplayVersion')
    if ($Version -in @('9', '10', '11', '12', '13'))
    {
        return $true
    }
}
