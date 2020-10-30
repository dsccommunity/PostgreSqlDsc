[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:dscModuleName   = 'PostgreSqlDsc'
$script:dscResourceName = 'DSC_PostgreSqlDatabase'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup
# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $moduleResourceName = 'PostgreSqlDsc - DSC_PostgreSqlDatabase'

        $PostgresAccount = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'postgreSqlAdmin', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $presentParams = @{
            DatabaseName     = 'testdb1'
            Ensure           = 'Present'
            Credential       = $PostgresAccount
        }
        $absentParams = @{
            DatabaseName     = 'testdb1'
            Ensure           = 'Absent'
            Credential       = $PostgresAccount
        }
        $psqlListResultsPresent = @(
            ' postgres      | postgres | UTF8 ',
            ' template0      | postgres | UTF8 ',
            ' testdb1      | postgres | UTF8 '
        )

        $psqlListResultsAbsent = @(
            ' postgres      | postgres | UTF8 ',
            ' template0      | postgres | UTF8 '
        )

        Describe "$moduleResourceName\Get-TargetResource" -Tag 'Get' {
            Context 'When getting current status of the database' {
                It 'Should return present when database is present' {
                    Mock -CommandName Invoke-Command {return $psqlListResultsPresent}

                    $result = Get-TargetResource @presentParams
                    $result              | Should -BeOfType System.Collections.HashTable
                    $result              | Should -BeOfType System.Collections.HashTable
                    $result.DatabaseName | Should -Be -ExpectedValue $presentParams.DatabaseName
                    $result.Ensure       | Should -Be -ExpectedValue 'Present'
                    $result.PsqlLocation | Should -Be -ExpectedValue 'C:\Program Files\PostgreSQL\12\bin\psql.exe'
                }

                It 'Should return absent when database is absent' {
                    Mock -CommandName Invoke-Command {return $psqlListResultsAbsent}

                    $result = Get-TargetResource @absentParams
                    $result              | Should -BeOfType System.Collections.HashTable
                    $result.DatabaseName | Should -Be -ExpectedValue $presentParams.DatabaseName
                    $result.Ensure       | Should -Be -ExpectedValue 'Absent'
                    $result.PsqlLocation | Should -Be -ExpectedValue 'C:\Program Files\PostgreSQL\12\bin\psql.exe'
                }

                It 'Should enter warning catch when psql is not installed' {
                    $invalidParams = $presentParams.Clone()
                    $invalidParams.PsqlLocation = 'Z:\does-not-exist.exe'

                    Get-TargetResource @invalidParams -Verbose
                }
            }
        }

        Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set'{
            Context 'When Set-TargetResource runs successfully' {
                Mock -CommandName Invoke-Command

                It 'Should call expected commands when creating the database' {

                    Set-TargetResource @presentParams
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when deleting the database' {

                    Set-TargetResource @absentParams
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource runs unsuccessfully' {
                It 'Should throw when psql is not installed' {
                    $invalidParams = $presentParams.Clone()
                    $invalidParams.PsqlLocation = 'Z:\does-not-exist.exe'

                    {Set-TargetResource @invalidParams} | Should throw
                }

                It 'Should throw when error is recieved from psql' {
                    Mock -CommandName Invoke-Command -MockWith {throw [System.Management.Automation.RemoteException]}

                    {Set-TargetResource @pressentParams} | Should -Throw
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" -Tag 'Test' {
            Context 'When running Test-TargetResource' {

                It 'Should return true when database should exist and is present' {
                    Mock -CommandName Invoke-Command {return $psqlListResultsPresent}

                    Test-TargetResource @presentParams | Should -Be $true
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should return false when database should exist and is absent' {
                    Mock -CommandName Invoke-Command {return $psqlListResultsAbsent}

                    Test-TargetResource @presentParams | Should -Be $false
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should return true when database should not exist and is absent' {
                    Mock -CommandName Invoke-Command {return $psqlListResultsAbsent}

                    Test-TargetResource @absentParams | Should -Be $true
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should return false when database should not exist and is present' {
                    Mock -CommandName Invoke-Command {return $psqlListResultsPresent}

                    Test-TargetResource @absentParams | Should -Be $false
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
