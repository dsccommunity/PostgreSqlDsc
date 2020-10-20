<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DSC_PostgreSqlInstall.
#>

ConvertFrom-StringData @'
    PostgreSqlFailed = PostgreSQL {0} failed with exit code {1}.
    PostgreSqlSuccess = PostgreSql {0} successfully with exit code: {1}.
    ParameterSetTo = Parameter {0} set to {1}.
    StartingInstall = Starting Install of PostgreSQL.
'@
