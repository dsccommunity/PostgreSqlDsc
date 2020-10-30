<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DSC_PostgreSqlScript.
#>

ConvertFrom-StringData @'
    PsqlNotFound = Command line executable psql.exe not found at location {0}.  Please ensure commandline option was installed from the PostgreSQL EDB installer.
    ExecutingGetScript = Executing the Get script from the file path '{0}' on database '{1}'.
    ExecutingSetScript = Executing the Set script from the file path '{0}' on database '{1}'.
    ExecutingTestScript = Executing the Test script from the file path '{0}' on database '{1}'.
    ReturnValue = Returning value '{0}'.
'@
