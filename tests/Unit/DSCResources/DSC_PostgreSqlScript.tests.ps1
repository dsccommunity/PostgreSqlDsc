[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:dscModuleName   = 'PostgreSqlDsc'
$script:dscResourceName = 'DSC_PostgreSqlScript'

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

try
{
    InModuleScope $script:dscResourceName {
        $moduleResourceName = 'PostgreSqlDsc - DSC_PostgreSqlScript'

        $superAccountCred = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'postgresqlAdmin', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $scriptParams = @{
            DatabaseName     = 'testdb'
            SetFilePath      = 'C:\set.sql'
            GetFilePath      = 'C:\get.sql'
            TestFilePath     = 'C:\test.sql'
            Credential       = $superAccountCred
        }

        $psqlListResults = @(
            ' postgres      | postgres | UTF8 ',
            ' template0      | postgres | UTF8 '
            )

        Describe "$moduleResourceName\Get-TargetResource" -Tag 'Get' {
            Context 'When Get-TargetResource runs successfully' {
                It 'Should invoke psql and return expected results' {
                    Mock Invoke-Command {return "<Script Output Sample>"}

                    $dscResult = Get-TargetResource @scriptParams

                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It

                    $dscResult.DatabaseName | Should -Be $scriptParams.DatabaseName
                    $dscResult.SetFilePath | Should -Be "C:\set.sql"
                    $dscResult.GetFilePath | Should -Be "C:\get.sql"
                    $dscResult.TestFilePath | Should -Be "C:\test.sql"
                    $dscResult.GetResult | Should -Be "<Script Output Sample>"
                }
            }

            Context 'When Get-TargetResource fails' {
                It 'Should return a null result when psql is not found' {
                    $invalidParams = $scriptParams.Clone()
                    $invalidParams.PsqlLocation = "does-not-exist.exe"

                    $dscResult = Get-TargetResource @invalidParams
                    $dscResult.DatabaseName | Should -Be $invalidParams.DatabaseName
                    $dscResult.GetResult | Should -Be $null
                }
            }
        }


        Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set'{
            Context 'When Set-TargetResource runs successfully' {
                BeforeAll {
                    Mock -CommandName Invoke-Command -MockWith {}
                }
                Context 'When database does not exist' {
                    BeforeEach {
                        Mock Invoke-Command -Verifiable -ParameterFilter {$ScriptBlock -match '-lqt 2>&1'} -MockWith { return $psqlListResults }
                    }
                    It 'Should invoke psql and call CREATE DATABASE by default' {
                        Mock -CommandName Invoke-Command -Verifiable -MockWith {return ""} -ParameterFilter {$ScriptBlock -match 'CREATE DATABASE'}

                        Set-TargetResource @scriptParams
                        Assert-VerifiableMock
                        Assert-MockCalled Invoke-Command -Exactly -Times 3 -Scope It
                    }

                    It 'Should invoke psql and not create database when CreateDatabase parameter is false' {
                        $NoCreateParams = $scriptParams.Clone()
                        $NoCreateParams.CreateDatabase = $false

                        Set-TargetResource @NoCreateParams
                        Assert-VerifiableMock
                        Assert-MockCalled Invoke-Command -Exactly -Times 2 -Scope It
                        Assert-MockCalled Invoke-Command -Times 0 -Scope It -ParameterFilter {$ScriptBlock -match "CREATE DATABASE"}
                    }
                }

                Context 'When database exists' {
                    It 'Should not call CREATE DATABASE' {
                        $psqlListResultsWithDatabase = @(" $($scriptParams.DatabaseName)      | postgres | UTF8")
                        Mock Invoke-Command -Verifiable -ParameterFilter {$ScriptBlock -match '-lqt 2>&1'} -MockWith { return $psqlListResultsWithDatabase }

                        Set-TargetResource @scriptParams
                        Assert-VerifiableMock
                        Assert-MockCalled Invoke-Command -Exactly -Times 2 -Scope It
                        Assert-MockCalled Invoke-Command -Times 0 -Scope It -ParameterFilter {$ScriptBlock -match "CREATE DATABASE"}
                    }
                }
            }

            Context 'When Set-TargetResource fails' {
                It 'Should throw when psql is not found' {
                    $invalidParams = $scriptParams.Clone()
                    $invalidParams.PsqlLocation = "Z:\does-not-exist.exe"

                    {Set-TargetResource @invalidParams } | Should -Throw -ExpectedMessage "is not recognized as the name of a cmdlet, function"
                }

                It 'Should re-throw errors from psql' {
                    Mock Invoke-Command -MockWith {throw [System.Management.Automation.RemoteException]}

                    {Set-TargetResource @scriptParams} | Should -Throw
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" -Tag 'Test' {
            Context 'When running Test-TargetResource is true' {
                It 'Should return True when script returns "true"' {
                    Mock Invoke-Command {return "true"}

                    Test-TargetResource @scriptParams | Should -Be $true
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                It 'Should return False when script returns ""' {
                    Mock Invoke-Command {return ""}

                    Test-TargetResource @scriptParams | Should -Be $false
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                it 'Should return False when script returns $null' {
                    Mock Invoke-Command {return $null}

                    Test-TargetResource @scriptParams | Should -Be $false
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }

                it 'Should return False when script returns "False"' {
                    Mock Invoke-Command {return "False"}

                    Test-TargetResource @scriptParams | Should -Be $false
                    Assert-MockCalled Invoke-Command -Exactly -Times 1 -Scope It
                }
            }

            Context 'When running Test-TargetResource is false' {
                BeforeEach {
                    $invalidParams = $scriptParams.Clone()
                }

                It 'Should return false when psql is not found' {
                    $invalidParams.PsqlLocation = "Z:\does-not-exist.exe"

                    Test-TargetResource @invalidParams | Should -Be $false
                }

                It 'Should return false when invalid script path is passed' {
                    $invalidParams.TestFilePath = "Z:\does-not-exist.sql"

                    Test-TargetResource @invalidParams | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
