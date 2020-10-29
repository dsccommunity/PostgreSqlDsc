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
    PathIsMissing = The path for the installation file does not exist: {0}.
    PostgreSqlFailed = PostgreSQL {0} failed with exit code {1}. A log file is created at the following path {2}.
    PostgreSqlSuccess = PostgreSql {0} successfully with exit code: {1}.
    PosgreSqlUninstall = Starting PostgreSql Uninstall.
    ParameterSetTo = Parameter {0} set to {1}.
    StartingInstall = Starting Install of PostgreSQL.
    InstallString = {0} with arguments {1}.
    MismatchSetting = Current setting {0} expected: {1}. Currently set to: {2}. Returning {3}.
    MissingFeature = {0} feature is missing.
    ExtraFeature = {0} feature is installed and should not be.
    MismatchWarning = Current setting {0} expected: {1}. Currently set to: {2}. Reinstall to change setting.
'@
