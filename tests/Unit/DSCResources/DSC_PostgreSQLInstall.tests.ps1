[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:dscModuleName   = 'PostgreSqlDsc'
$script:dscResourceName = 'DSC_PostgreSqlInstall'

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
        $moduleResourceName = 'PostgreSqlDsc - DSC_PostgreSqlInstall'

        $serviceCredeDomain = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'contoso\testaccount', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $serviceCredBuiltin = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'NT AUTHORITY\NetworkService', (ConvertTo-SecureString 'doesntmatter' -AsPlainText -Force)

        $superAccountCred = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'postgresqlAdmin', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $setAllParamsPresent = @{
            Ensure           = 'Present'
            Version          = '12'
            InstallerPath    = 'C:\postgresql-12.4-1-windows-x64.exe'
            ServiceName      = 'postgreSql_Test'
            InstallDirectory = 'C:\PostgreSQL'
            ServerPort       = '5432'
            DataDirectory    = 'C:\PostgreSQL\Data'
            Features         = 'commandlinetools','server','pgadmin','stackbuilder'
            ServiceAccount   = $serviceCredBuiltin
            SuperAccount     = $superAccountCred
        }

        $setParamsAbsent = @{
            Ensure           = 'Absent'
            Version          = '12'
            InstallerPath    = 'C:\postgresql-12.4-1-windows-x64.exe'
        }

        $mockStartProcess = @{
            exitcode = '0'
        }


        Describe "$moduleResourceName\Get-TargetResource" {
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location

            Context 'When retrieving client settings' {

                It 'Should return desired result' {
                    Mock -CommandName Get-CMAccount -MockWith { $cmAccounts }

                    $result = Get-TargetResource @getCmAccounts
                    $result                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode        | Should -Be -ExpectedValue 'Lab'
                    $result.Account         | Should -Be -ExpectedValue 'TestUser1'
                    $result.CurrentAccounts | Should -Be -ExpectedValue @('DummyUser1','DummyUser2')
                    $result.Ensure          | Should -Be -ExpectedValue 'Present'
                }

                It 'Should return desired result' {
                    Mock -CommandName Get-CMAccount -MockWith { $null }

                    $result = Get-TargetResource @getCmAccounts
                    $result                 | Should -BeOfType System.Collections.HashTable
                    $result.SiteCode        | Should -Be -ExpectedValue 'Lab'
                    $result.Account         | Should -Be -ExpectedValue 'TestUser1'
                    $result.CurrentAccounts | Should -Be -ExpectedValue $null
                    $result.Ensure          | Should -Be -ExpectedValue 'Present'
                }
            }
        }


        Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set'{
            New-Item -Path TestRegistry:\ -Name 'PostgreSql 12'
            New-ItemProperty -Path 'TestRegistry:\PostgreSql 12' -Name 'Name' -Value 'PostgreSql 12'
            New-ItemProperty -Path 'TestRegistry:\PostgreSql 12' -Name 'UninstallString' -Value 'C:\PostgreSQL\uninstall-postgresql.exe'


            $mockUninstallStringRegistry = Get-ChildItem -Path 'TestRegistry:\'

            Context 'When Set-TargetResource runs successfully' {
                It 'Should call expected commands when installing PostgreSql' {
                    #Mock -CommandName Test-Path -MockWith {$true}
                    Mock -CommandName Start-Process -MockWith {$mockStartProcess}

                    Set-TargetResource @setAllParamsPresent
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Start-Process -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when uninstalling PostgreSql' {
                    Mock -CommandName Get-ChildItem -MockWith {$mockUninstallStringRegistry}
                    #Mock -CommandName Test-Path -MockWith {$true}
                    Mock -CommandName Start-Process -MockWith {$mockStartProcess}

                    Set-TargetResource @setParamsAbsent
                    Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                    Assert-MockCalled Start-Process -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource runs unsuccessfully' {
                It 'Should throw with InstallerPath does not exists' {
                    #Mock -CommandName Test-Path -MockWith {$false}
                    Mock -CommandName Start-Process -MockWith {$mockStartProcess}

                    {Set-TargetResource @setAllParamsPresent} | Should throw
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {
            Mock -CommandName Set-Location

            Context 'When running Test-TargetResource where Postgres is installed' {
                Mock -CommandName Get-TargetResource -MockWith { $setAllParamsPresent }

                It 'Should return desired result true when ensure = present' {
                    Test-TargetResource @setAllParamsPresent | Should -Be $true
                }
            }

            Context 'When running Test-TargetResource where Postgres is not installed' {
                Mock -CommandName Get-TargetResource -MockWith { $setParamsAbsent }

                It 'Should return desired result false when ensure = present' {
                    Test-TargetResource @setAllParamsPresent | Should -Be $false
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
