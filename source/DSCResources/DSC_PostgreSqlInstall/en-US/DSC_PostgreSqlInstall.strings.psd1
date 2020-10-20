<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DSC_PostgreSqlInstall.
#>

ConvertFrom-StringData @'
    SearchingRegistry = Searching registry for Postgres keys for version {0}.
    NoVersionFound = No keys found for version specified.
    FoundKeysForVersion = Found keys for version {0}.
    CheckingForService = Checking registry for PostgreSQL service.
    CheckingConfig = Checking PostGreSQL configuration for current port.
    CheckingFeatures = Checking for installed licenses to determine what features are installed.
    PostgreSqlFailed = PostgreSQL {0} failed with exit code {1}.
    PostgreSqlSuccess = PostgreSql {0} successfully with exit code: {1}.
    ParameterSetTo = Parameter {0} set to {1}.
    StartingInstall = Starting Install of PostgreSQL.
'@
