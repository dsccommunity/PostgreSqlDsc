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
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $ReadOnly
    )

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
        [System.String]
        $ServiceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallerPath,

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
        [System.String]
        $Features
    )



    $ServiceName = $ServiceName.Replace(" ", "_")
    if ($null -eq $Prefix) { $Prefix = "C:\Program Files\$ServiceName" }
    if ($null -eq $Port) { $Port = 5432 }
    if ($null -eq $DataDir) { $DataDir = "$Prefix\Data" }
    if ($null -eq $Features) { $Features = 'server,pgAdmin,stackbuilder,commandlinetools' }
    if ($null -eq $ServiceAccount)
    {
        $ServiceAccount = (New-Object -TypeName PSCredential -ArgumentList ("NT AUTHORITY\NetworkService", (New-Object System.Security.SecureString)))
    }

    $Arguments = @(
        "--prefix `"$Prefix`""
        "--datadir `"$DataDir`""
        "--servicename $ServiceName"
        "--serviceaccount `"$($ServiceAccount.UserName)`""
        "--serverport $Port"
        "--enable-components $Features"
        "--unattendedmodeui none --node unattended"
    )

    $BuiltInAccounts = @('NT AUTHORITY\NetworkService')
    if (-not ($ServiceAccount.UserName -in $BuiltInAccounts))
    {
        $Arguments += "--servicepassword $($ServiceAccount.GetNetworkCredential().Password)"
    }

    Start-Process $InstallerPath -ArgumentList ($Arguments.join(" ")) -Wait
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
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $ReadOnly,

        [Parameter()]
        [System.Boolean]
        $Hidden,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    # Check for the correct registry key in Uninstall?
    # Placeholder to test Set-Target
    return $false
}
