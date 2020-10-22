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

        $serviceCredDomain = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'contoso\testaccount', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $serviceCredBuiltin = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'NT AUTHORITY\NetworkService', (ConvertTo-SecureString 'doesntmatter' -AsPlainText -Force)

        $superAccountCred = New-Object `
        -TypeName System.Management.Automation.PSCredential `
        -ArgumentList 'postgresqlAdmin', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $getParams = @{
            Ensure           = 'Present'
            Version          = '12'
            InstallerPath    = 'X:\postgresql-12.4-1-windows-x64.exe'
        }

        $setAllParamsPresent = @{
            Ensure           = 'Present'
            Version          = '12'
            InstallerPath    = 'X:\postgresql-12.4-1-windows-x64.exe'
            ServiceName      = 'postgreSql_Test'
            InstallDirectory = 'TestDrive:\PostgreSql'
            ServerPort       = '5432'
            DataDirectory    = 'TestDrive:\PostgreSql\Data\'
            Features         = 'commandlinetools','server','pgadmin','stackbuilder'
            ServiceAccount   = $serviceCredBuiltin
            SuperAccount     = $superAccountCred
        }

        $setAllParamsPresentServicePassword = @{
            Ensure           = 'Present'
            Version          = '12'
            InstallerPath    = 'X:\postgresql-12.4-1-windows-x64.exe'
            ServiceName      = 'postgreSql_Test'
            InstallDirectory = 'TestDrive:\PostgreSql'
            ServerPort       = '5432'
            DataDirectory    = 'TestDrive:\PostgreSql\Data\'
            Features         = 'commandlinetools','server','pgadmin','stackbuilder'
            ServiceAccount   = $serviceCredDomain
            SuperAccount     = $superAccountCred
        }

        $setParamsAbsent = @{
            Ensure           = 'Absent'
            Version          = '12'
            InstallerPath    = 'C:\postgresql-12.4-1-windows-x64.exe'
        }

        $mockStartProcessNoError = @{
            exitcode = '0'
        }

        $mockStartProcessError = @{
            exitcode = '1704'
        }

        Describe "$moduleResourceName\Get-TargetResource" {
            # Create registry to mock the uninstall location HKLM:\\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
            New-Item -Path TestRegistry:\ -Name 'PostgreSql 12'
            New-ItemProperty -Path 'TestRegistry:\PostgreSql 12' -Name 'Name' -Value 'PostgreSql 12'
            New-ItemProperty -Path 'TestRegistry:\PostgreSql 12' -Name 'InstallLocation' -Value 'TestDrive:\PostgreSql'
            New-ItemProperty -Path 'TestRegistry:\PostgreSql 12' -Name 'DisplayVersion' -Value '12'
            New-ItemProperty -Path 'TestRegistry:\PostgreSql 12' -Name 'UninstallString' -Value 'TestDrive:\PostgreSQL\uninstall-postgresql.exe'

            $mockUninstallregistry = Get-ChildItem -Path 'TestRegistry:\'

            # Create registry to mock the services HKLM:\SYSTEM\CurrentControlSet\Services
            New-Item -Path TestRegistry:\ -Name 'Services'
            New-Item -Path TestRegistry:\Services -Name 'postgreSql'
            New-ItemProperty -Path 'TestRegistry:\Services\postgreSql' -Name 'DisplayName' -Value 'postgreSql - PostgreSQL Server 12'
            New-ItemProperty -Path 'TestRegistry:\Services\postgreSql' -Name 'ObjectName' -Value 'NT AUTHORITY\NetworkService'
            New-ItemProperty -Path 'TestRegistry:\Services\postgreSql' -Name 'ImagePath' -Value '"TestDrive:\PostgreSQL\bin\pg_ctl.exe" runservice -N "postgreSql_RPS" -D "TestDrive:\PostgreSql\Data" -w'

            $mockServicesRegistry = Get-ChildItem -Path 'TestRegistry:\Services'

            $postgreSqlConfig = 'TestDrive:\PostgreSql\Data\postgresql.conf'
            New-Item -Path 'TestDrive:\' -Name 'PostgreSql' -Type Directory
            New-Item -Path 'TestDrive:\PostgreSql\' -Name 'Data'-Type Directory
            New-Item -Path 'TestDrive:\PostgreSql\Data' -Name 'postgresql.conf' -Type File
            Set-Content $postgreSqlConfig -Value 'port = 5432                # (change requires restart)'

            #build Licenses
            Set-Content 'TestDrive:\PostgreSql\commandlinetools_3rd_party_licenses.txt' -Value 'license'
            Set-Content 'TestDrive:\PostgreSql\pgAdmin_license.txt' -Value 'license'
            Set-Content 'TestDrive:\PostgreSql\server_license.txt' -Value 'license'
            Set-Content 'TestDrive:\PostgreSql\StackBuilder_3rd_party_licenses.txt' -Value 'license'


            Context 'When getting current settings' {
                It 'Should return desired result when present' {
                    Mock -CommandName Get-ChildItem -MockWith { $mockUninstallregistry } -ParameterFilter {$Path -eq 'HKLM:\\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'}
                    Mock -CommandName Get-ChildItem -MockWith { $mockServicesRegistry } -ParameterFilter {$Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services'}



                    $result = Get-TargetResource @getParams
                    $result                  | Should -BeOfType System.Collections.HashTable
                    $result.Ensure           | Should -Be -ExpectedValue 'Present'
                    $result.Version          | Should -Be -ExpectedValue '12'
                    $result.InstallerPath    | Should -Be -ExpectedValue $getParams.InstallerPath
                    $result.InstallDirectory | Should -Be -ExpectedValue 'TestDrive:\PostgreSql'
                    $result.ServiceName      | Should -Be -ExpectedValue 'postgreSql'
                    $result.ServiceAccount   | Should -Be -ExpectedValue 'NT AUTHORITY\NetworkService'
                    $result.DataDirectory    | Should -Be -ExpectedValue 'TestDrive:\PostgreSql\Data'
                    $result.ServerPort       | Should -Be -ExpectedValue '5432'
                    $result.Features         | Should -Be -ExpectedValue 'commandlinetools,pgAdmin,server,stackbuilder'
                }


                It 'Should return desired result when absent' {
                    Mock -CommandName Get-ChildItem -MockWith { $null } -ParameterFilter {$Path -eq 'HKLM:\\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'}

                    $result = Get-TargetResource @getParams
                    $result                  | Should -BeOfType System.Collections.HashTable
                    $result.Ensure           | Should -Be -ExpectedValue 'Absent'
                    $result.InstallerPath    | Should -Be -ExpectedValue $getParams.InstallerPath
                    $result.Version          | Should -Be -ExpectedValue $getParams.Version
                    $result.InstallDirectory | Should -Be -ExpectedValue $null
                    $result.ServiceName      | Should -Be -ExpectedValue $null
                    $result.ServiceAccount   | Should -Be -ExpectedValue $null
                    $result.DataDirectory    | Should -Be -ExpectedValue $null
                    $result.ServerPort       | Should -Be -ExpectedValue $null
                    $result.Features         | Should -Be -ExpectedValue $null
                }
            }
        }


        Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set'{
            New-Item -Path TestRegistry:\ -Name 'PostgreSql 12'
            New-ItemProperty -Path 'TestRegistry:\PostgreSql 12' -Name 'Name' -Value 'PostgreSql 12'
            New-ItemProperty -Path 'TestRegistry:\PostgreSql 12' -Name 'UninstallString' -Value 'C:\PostgreSQL\uninstall-postgresql.exe'


            $mockUninstallStringRegistry = Get-ChildItem -Path 'TestRegistry:\'

            Context 'When Set-TargetResource runs successfully' {
                It 'Should call expected commands when installing PostgreSql with builtin service account' {
                    Mock -CommandName Test-Path -MockWith {$true}
                    Mock -CommandName Start-Process -MockWith {$mockStartProcessNoError}

                    Set-TargetResource @setAllParamsPresent
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Start-Process -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when installing PostgreSql with domain service account' {
                    Mock -CommandName Test-Path -MockWith {$true}
                    Mock -CommandName Start-Process -MockWith {$mockStartProcessNoError}

                    Set-TargetResource @setAllParamsPresentServicePassword
                    Assert-MockCalled Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled Start-Process -Exactly -Times 1 -Scope It
                }

                It 'Should call expected commands when uninstalling PostgreSql' {
                    Mock -CommandName Get-ChildItem -MockWith {$mockUninstallStringRegistry}
                    Mock -CommandName Test-Path -MockWith {$true}
                    Mock -CommandName Start-Process -MockWith {$mockStartProcessNoError}

                    Set-TargetResource @setParamsAbsent
                    Assert-MockCalled Test-Path -Exactly -Times 0 -Scope It
                    Assert-MockCalled Start-Process -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-ChildItem -Exactly -Times 1 -Scope It
                }
            }

            Context 'When Set-TargetResource runs unsuccessfully' {
                It 'Should throw when the InstallerPath does not exist for install' {
                    Mock -CommandName Test-Path -MockWith {$false}

                    {Set-TargetResource @setAllParamsPresent} | Should throw
                }

                It 'Should throw when the exit code is not 0 or null for uninstall' {
                    Mock -CommandName Get-ChildItem -MockWith {$mockUninstallStringRegistry}
                    Mock -CommandName Start-Process -MockWith {$mockStartProcessError}

                    {Set-TargetResource @setParamsAbsent} | Should throw
                }

                It 'Should throw when the exit code is not 0, 1641, 3010 for install' {
                    Mock -CommandName Test-Path -MockWith {$true}
                    Mock -CommandName Start-Process -MockWith {$mockStartProcessError}

                    {Set-TargetResource @setAllParamsPresent} | Should throw
                }
            }
        }

        Describe "$moduleResourceName\Test-TargetResource" {

            $getAllParamsPresent = $setAllParamsPresent.Clone()
            $getAllParamsPresent.ServiceAccount = 'NT AUTHORITY\NetworkService'
            $getAllParamsPresent.Features = $getAllParamsPresent.Features -join ","
            $getAllParamsPresent.Remove('SuperAccount')

            $getParamsMismatch = $getAllParamsPresent.Clone()
            $getParamsMismatch.Version = '10'
            $getParamsMismatch.ServiceName = 'Postgres_Sql_Wrong'
            $getParamsMismatch.InstallDirectory = 'Y:\Doesnt\Exist\'
            $getParamsMismatch.ServerPort = 1234
            $getParamsMismatch.DataDirectory = 'Y:\Doesnt\Exist\'
            $getParamsMismatch.ServiceAccount = 'LocalSystem'
            $getParamsMismatch.Features = 'commandlinetools,server,pgadmin'

            $setParamsExtraFeatures = $setAllParamsPresent.Clone()
            $setParamsExtraFeatures.Features = 'commandlinetools,server,pgadmin'



            Context 'When running Test-TargetResource where Postgres is installed' {

                It 'Should display warning when features are missing and return true' {
                    Mock -CommandName Get-TargetResource -MockWith { $getParamsMismatch }
                    Mock -CommandName Write-Warning

                    Test-TargetResource @setAllParamsPresent | Should -Be $true
                    Assert-MockCalled Write-Warning -Exactly -Times 7 -Scope It
                }

                It 'Should display warning when features are missing and return true' {
                    Mock -CommandName Get-TargetResource -MockWith { $getAllParamsPresent }
                    Mock -CommandName Write-Warning

                    Test-TargetResource @setParamsExtraFeatures | Should -Be $true
                    Assert-MockCalled Write-Warning -Exactly -Times 5 -Scope It
                }

                It 'Should return desired result true when ensure = present' {
                    Mock -CommandName Get-TargetResource -MockWith { $getAllParamsPresent }

                    Test-TargetResource @setAllParamsPresent | Should -Be $true
                }

                It 'Should return desired result false when ensure = absent' {
                    Mock -CommandName Get-TargetResource -MockWith { $getAllParamsPresent }

                    Test-TargetResource @setParamsAbsent | Should -Be $false
                }

            }

            Context 'When running Test-TargetResource where Postgres is not installed' {
                Mock -CommandName Get-TargetResource -MockWith { $setParamsAbsent }

                It 'Should return desired result false when ensure = present' {
                    Test-TargetResource @setAllParamsPresent | Should -Be $false
                }

                It 'Should return desired result true when ensure = absent' {
                    Test-TargetResource @setParamsAbsent | Should -Be $true
                }
            }

        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
