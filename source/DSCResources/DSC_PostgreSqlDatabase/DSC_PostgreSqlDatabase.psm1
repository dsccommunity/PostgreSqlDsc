$script:ParentModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:ParentModulePath -ChildPath 'Modules'

$script:CommonHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.Common'
Import-Module $script:CommonHelperModulePath -ErrorAction Stop

$script:localizedData = Get-LocalizedData -DefaultUICulture en-US

<#
    .SYNOPSIS
        Returns the current state of the database.
    .PARAMETER DatabaseName
        Specifies the name of the PostgreSQL database.
    .PARAMETER Ensure
        Specifies if the database should be present or absent.
    .PARAMETER Credential
        The credentials to authenticate with, using PostgreSQL Authentication.
    .PARAMETER PsqlLocation
        Location of the psql executable.  Defaults to "C:\Program Files\PostgreSQL\12\bin\psql.exe".
    .OUTPUTS
        Hash table with the current satus of the database specified.
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
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $PsqlLocation = "$env:ProgramFiles\PostgreSQL\12\bin\psql.exe"
    )

    $env:PGPASSWORD = $Credential.GetNetworkCredential().Password
    $env:PGUSER = $Credential.UserName

    try
    {
        Write-Verbose -Message ($script:localizedData.CheckingIfDatabaseIsPresent -f $DatabaseName)
        Write-Verbose -Message ($script:localizedData.ListingDatabases)
        $databaseList = Invoke-Command -ScriptBlock { & $PsqlLocation -d postgres -lqt 2>&1 }
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        Write-Verbose -Message ($script:localizedData.PsqlNotFound -f $PsqlLocation)
    }

    $databaseExists = "Absent"
    foreach ($database in $databaseList)
    {
        if ($database.split("|")[0].trim() -eq $DatabaseName)
        {
            Write-Verbose -Message ($script:localizedData.FoundDatabase -f $DatabaseName)
            $databaseExists = "Present"
            continue
        }
    }

    $returnValue = @{
        DatabaseName = $DatabaseName
        Ensure       = $databaseExists
        PsqlLocation = $PsqlLocation
    }

    return $returnValue
}


<#
    .SYNOPSIS
        Creates or Deletes the database.
    .PARAMETER DatabaseName
        Specifies the name of the PostgreSQL database.
    .PARAMETER Ensure
        Specifies if the database should be present or absent.
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
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $PsqlLocation = "$env:ProgramFiles\PostgreSQL\12\bin\psql.exe"
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    $env:PGPASSWORD = $Credential.GetNetworkCredential().Password
    $env:PGUSER = $Credential.UserName

    try
    {
        if ($Ensure -eq 'Present')
        {
            $createDatabaseString = '"CREATE DATABASE ""{0}""' -f $DatabaseName
            Write-Verbose -Message ($script:localizedData.CreatingDatabase -f $DatabaseName)
            Invoke-Command -ScriptBlock {
                & $PsqlLocation -d 'postgres' -c $createDatabaseString
            }
        }
        else
        {
            $deleteDatabaseString = '"DROP DATABASE ""{0}""' -f $DatabaseName
            Write-Verbose -Message ($script:localizedData.DeletingDatabase -f $DatabaseName)
            Invoke-Command -ScriptBlock {
                & $PsqlLocation -d 'postgres' -c $deleteDatabaseString
            }
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
        Evaluates if the database is desired state.
    .PARAMETER DatabaseName
        Specifies the name of the PostgreSQL database.
    .PARAMETER Ensure
        Specifies if the database should be present or absent.
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
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $PsqlLocation = "$env:ProgramFiles\PostgreSQL\12\bin\psql.exe"
    )

    $getTargetResourceParameters = @{
        DatabaseName = $DatabaseName
        Ensure       = $Ensure
        PsqlLocation = $PsqlLocation
        Credential   = $Credential
    }

    $getTargetResourceResults = Get-TargetResource @getTargetResourceParameters
    $result = $true

    if ($Ensure -eq 'Present' -and $getTargetResourceResults.Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($script:localizedData.ExpectedPresentButAbsent)
        $result = $false
    }
    elseif ($Ensure -eq 'Absent' -and $getTargetResourceResults.Ensure -eq 'Present')
    {
        Write-Verbose -Message ($script:localizedData.ExpectedAbsentButPresent)
        $result = $false
    }

    Write-Verbose -Message ($script:localizedData.TestReturn -f $result)
    return $result
}

Export-ModuleMember -Function *-TargetResource
