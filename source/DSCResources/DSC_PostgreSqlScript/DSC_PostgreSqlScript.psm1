$script:ParentModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:ParentModulePath -ChildPath 'Modules'

$script:CommonHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.Common'
Import-Module $script:CommonHelperModulePath -ErrorAction Stop

$script:localizedData = Get-LocalizedData -DefaultUICulture en-US

<#
    .SYNOPSIS
        Returns the current state of what the Get-script returns.
    .PARAMETER DatabaseName
        Specifies the name of the PostgreSQL database.
    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.
    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.
    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error is evaluated to true.
    .PARAMETER Credential
        The credentials to authenticate with, using PostgreSQL Authentication.
    .PARAMETER PsqlLocation
        Location of the psql executable.  Defaults to "C:\Program Files\PostgreSQL\12\bin\psql.exe".
    .OUTPUTS
        Hash table containing key 'GetResult' which holds the value of the result from the SQL script that was ran from the parameter 'GetFilePath'.
#>

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $PsqlLocation = 'C:\Program Files\PostgreSQL\12\bin\psql.exe'
    )

    $env:PGPASSWORD = $Credential.GetNetworkCredential().Password
    $env:PGUSER = $Credential.UserName

    try
    {
        Write-Verbose -Message ($script:localizedData.ExecutingGetScript -f $GetFilePath,$DatabaseName)
        $getResult = Invoke-Command -ScriptBlock {
            & $PsqlLocation -d $DatabaseName -f $GetFilePath
        }
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        Write-Verbose -Message ($script:localizedData.PsqlNotFound -f $PsqlLocation)
    }
    catch
    {
        Write-Verbose -Message $_.exception.message
    }

    $returnValue = @{
        DatabaseName = $DatabaseName
        SetFilePath  = $SetFilePath
        GetFilePath  = $GetFilePath
        TestFilePath = $TestFilePath
        GetResult    = [System.String[]] $getResult
    }

    return $returnValue
}


<#
    .SYNOPSIS
        Executes the set-script.
    .PARAMETER DatabaseName
        Specifies the name of the PostgreSQL database.
    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.
    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the `GetResult` property.
    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error is evaluated to true.
    .PARAMETER Credential
        The credentials to authenticate with, using PostgreSQL Authentication.
    .PARAMETER PsqlLocation
        Location of the psql executable.  Defaults to "C:\Program Files\PostgreSQL\12\bin\psql.exe".
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $PsqlLocation = 'C:\Program Files\PostgreSQL\12\bin\psql.exe'
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    $env:PGPASSWORD = $Credential.GetNetworkCredential().Password
    $env:PGUSER = $Credential.UserName

    try
    {
        Write-Verbose -Message ($script:localizedData.ExecutingSetScript -f $SetFilePath,$DatabaseName)
        Invoke-Command -ScriptBlock {
            & $PsqlLocation -d $DatabaseName -f $SetFilePath 2>&1
        }
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        Write-Verbose -Message ($script:localizedData.PsqlNotFound -f $PsqlLocation)
        throw $_
    }
    catch
    {
        throw $_
    }
    finally
    {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

<#
    .SYNOPSIS
        Evaluates the value returned from the Test-script.
    .PARAMETER DatabaseName
        Specifies the name of the PostgreSQL database.
    .PARAMETER SetFilePath
        Path to the T-SQL file that will perform Set action.
    .PARAMETER GetFilePath
        Path to the T-SQL file that will perform Get action.
        Any values returned by the T-SQL queries will also be returned by the cmdlet Get-DscConfiguration through the 'GetResult' property.
    .PARAMETER TestFilePath
        Path to the T-SQL file that will perform Test action.
        Any script that does not throw an error is evaluated to true.
    .PARAMETER Credential
        The credentials to authenticate with, using PostgreSQL Authentication.
    .PARAMETER PsqlLocation
        Location of the psql executable.  Defaults to "C:\Program Files\PostgreSQL\12\bin\psql.exe".
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $PsqlLocation = 'C:\Program Files\PostgreSQL\12\bin\psql.exe'
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    $env:PGPASSWORD = $Credential.GetNetworkCredential().Password
    $env:PGUSER = $Credential.UserName

    try
    {
        Write-Verbose -Message ($script:localizedData.ExecutingTestScript -f $TestFilePath,$DatabaseName)
        $null = Invoke-Command -ScriptBlock {
            & $PsqlLocation -d $DatabaseName -f $TestFilePath 2>&1
        }

        Write-Verbose -Message ($script:localizedData.ReturnValue -f $true)
        return $true
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        Write-Verbose -Message ($script:localizedData.PsqlNotFound -f $PsqlLocation)
        Write-Verbose -Message ($script:localizedData.ReturnValue -f $false)
        return $false
    }
    catch
    {
        Write-Verbose -Message $_.exception.message
        Write-Verbose -Message ($script:localizedData.ReturnValue -f $false)
        return $false
    }
    finally
    {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

Export-ModuleMember -Function *-TargetResource
