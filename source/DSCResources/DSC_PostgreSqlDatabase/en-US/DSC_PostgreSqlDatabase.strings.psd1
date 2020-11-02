<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        resource DSC_PostgreSqlScript.
#>

ConvertFrom-StringData @'
    CheckingIfDatabaseIsPresent = Checking status of {0} database.
    ListingDatabases = Listing Databases with command 'psql.exe -lqt'.
    FoundDatabase = Found {0} database.
    CreatingDatabase = Creating database with command 'CREATE DATABASE {0}'.
    DeletingDatabase = Deleting database with command 'DROP DATABASE {0}'.
    ExpectedPresentButAbsent = Expected database to be Present but is Absent.
    ExpectedAbsentButPresent = Expected database to be Absent but is Present.
    TestReturn = Test-TargetResource returned {0}.
    PsqlNotFound = Command line executable psql.exe not found at location {0}.  Please ensure commandline option was installed from the PostgreSQL EDB installer.
'@
