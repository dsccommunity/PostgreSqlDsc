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

    .PARAMETER Path
        The path to the folder to retrieve.

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

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

        }
    } $uninstallRegistry.GetValue('UninstallString')
    # Placeholder to test Set-Target
    return @{
        ServiceName     = 'Postgres'
        InstallerPath   = 'C:\folder\file.exe'
        Prefix          = 'C:\Program Files\Postgres'
        Port            = 5432
        DataDir         = 'C:\Program Files\Postgres\Data'
        ServiceAccount  = 'NT AUTHORITY\NetworkSystem'
        Features        = 'server,pgAdmin,stackbuilder,commandlinetools'
    }
}

<#
    .SYNOPSIS
        Creates or removes the folder.

    .PARAMETER ServiceName
        The name of the windows service that postgres will run under.

    .PARAMETER InstallerPath
       The full path to the EDB Postgres installer.

    .PARAMETER Prefix
        The folder path that Postgre should be installed to.

    .PARAMETER Port
        The port that Postgres will listen on for incoming connections.

    .PARAMETER DataDir
        The path for all the data from this Postgres install.

    .PARAMETER ServiceAccount
        The account that will be used to run the service.

    .PARAMETER Features
        The Postgres features to install.
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

        $Arguments = @(
            "--unattendedmodeui none"
            "--mode unattended"
        )

        if (-not [string]::IsNullOrEmpty($ServiceName))
        {
            $finalServiceName = $ServiceName.Replace(" ", "_")
            $Arguments += "--servicename `"$finalServiceName`""
        }

        if (-not [string]::IsNullOrEmpty($Prefix))
        {
            $Arguments += "--prefix `"$Prefix`""
        }

        if (-not [string]::IsNullOrEmpty($DataDir))
        {
            $Arguments += "--datadir `"$DataDir`""
        }

        if (-not [string]::IsNullOrEmpty($Port))
        {
            $Arguments += "--serverport $Port"
        }

        if (-not [string]::IsNullOrEmpty($Features))
        {
            $Arguments += "--enable-components `"$Features`""
        }

        if (-not [string]::IsNullOrEmpty($OptionFile))
        {
            $Arguments += "--optionfile `"$OptionFile`""
        }

        $builtinAccounts = @('NT AUTHORITY\NetworkService', 'NT AUTHORITY\System', 'NT AUTHORITY\Local Service')
        if (-not ($null -eq $ServiceAccount))
        {
            $Arguments += "--serviceaccount `"$($ServiceAccount.UserName)`""
            if (-not ($ServiceAccount.UserName -in $builtinAccounts))
            {
                $Arguments += "--servicepassword $($ServiceAccount.GetNetworkCredential().Password)"
            }
        }

        if (-not ($null -eq $SuperAccount))
        {
            $Arguments += "--superaccount `"$($SuperAccount.UserName)`""
            $Arguments += "--superpassword `"$($SuperAccount.GetNetworkCredential().Password)`""
        }

        $process = Start-Process $InstallerPath -ArgumentList ($Arguments -join " ") -Wait -PassThru -NoNewWindow
        $exitCode = $process.ExitCode

        if ($exitCode -ne 0 -or $exitCode -ne 1641 -or $exitCode -ne 3010)
        {
            throw "PostgreSQL install failed with exit code $exitCode"
        }
        else
        {
            Write-Verbose -Message "PostgreSQL installed successfully with exit code: $exitCode"
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
            throw "PostgreSQL install failed with exit code $exitCode"
        }
        else
        {
            Write-Verbose -Message "PostgreSQL installed successfully with exit code: $exitCode"
        }
    }
}

<#
    .SYNOPSIS
        Creates or removes the folder.

    .PARAMETER Path
        The path to the folder to retrieve.

    .PARAMETER ReadOnly
       If the files in the folder should be read only.
       Not used in Get-TargetResource.

    .PARAMETER Hidden
        If the folder attribut should be hidden. Default value is $false.

    .PARAMETER Ensure
        Specifies the desired state of the folder. When set to 'Present', the folder will be created. When set to 'Absent', the folder will be removed. Default value is 'Present'.
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
