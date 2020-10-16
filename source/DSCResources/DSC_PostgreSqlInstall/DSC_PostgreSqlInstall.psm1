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
        $Prefix = "C:\Program Files\$ServiceName",

        [Parameter()]
        [System.UInt16]
        $Port = 5432,

        [Parameter()]
        [System.String]
        $DataDir = "$Prefix\Data",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ServiceAccount = (New-Object -TypeName PSCredential -ArgumentList ("NT AUTHORITY\NetworkService", (New-Object System.Security.SecureString))),

        [Parameter()]
        [System.String]
        $Features = 'server,pgAdmin,stackbuilder,commandlinetools'
    )

    $BuiltInAccounts = @('NT AUTHORITY\NetworkService')

    $ServiceName = $ServiceName.Replace(" ", "_")

    $Arguments = @(
        "--prefix `"$Prefix`""
        "--datadir `"$DataDir`""
        "--servicename $ServiceName"
        "--serviceaccount `"$($ServiceAccount.UserName)`""
        "--serverport $Port"
        "--enable-components $Features"
        "--unattendedmodeui none --node unattended"
    )
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
}
