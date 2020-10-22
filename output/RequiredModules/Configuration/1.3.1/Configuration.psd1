@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = '.\Configuration.psm1'

# Version number of this module.
ModuleVersion = '1.3.1'

# ID used to uniquely identify this module
GUID = 'e56e5bec-4d97-4dfd-b138-abbaa14464a6'

# Author of this module
Author = @('Joel Bennett')

# Company or vendor of this module
CompanyName = 'HuddledMasses.org'

# HelpInfo URI of this module
# HelpInfoURI = ''

# Copyright statement for this module
Copyright = 'Copyright (c) 2014-2017 by Joel Bennett, all rights reserved.'

# Description of the functionality provided by this module
Description = 'A module for storing and reading configuration values, with full PS Data serialization, automatic configuration for modules and scripts, etc.'

# We explicitly name the functions we want to be visible, but we export everything with '*'
FunctionsToExport = 'Import-Configuration','Export-Configuration','Get-StoragePath','Add-MetadataConverter',
                    'ConvertFrom-Metadata','ConvertTo-Metadata','Export-Metadata','Import-Metadata',
                    'Update-Manifest','Get-ManifestValue','*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all files packaged with this module
FileList = @('.\Configuration.psd1','.\Configuration.psm1','.\Metadata.psm1','.\en-US\about_Configuration.help.txt')

PrivateData = @{
    # Allows overriding the default paths where Configuration stores it's configuration
    # Within those folders, the module assumes a "powershell" folder and creates per-module configuration folders
    PathOverride = @{
        # Where the user's personal configuration settings go.
        # Highest presedence, overrides all other settings.
        # Defaults to $Env:LocalAppData on Windows
        # Defaults to $Env:XDG_CONFIG_HOME elsewhere ($HOME/.config/)
        UserData       = ''
        # On some systems there are "roaming" user configuration stored in the user's profile. Overrides machine configuration
        # Defaults to $Env:AppData on Windows
        # Defaults to $Env:XDG_CONFIG_DIRS elsewhere (or $HOME/.local/share/)
        EnterpriseData = ''
        # Machine specific configuration. Overrides defaults, but is overriden by both user roaming and user local settings
        # Defaults to $Env:ProgramData on Windows
        # Defaults to /etc/xdg elsewhere
        MachineData    = ''
    }
    # PSData is module packaging and gallery metadata embedded in PrivateData
    # It's for the PoshCode and PowerShellGet modules
    # We had to do this because it's the only place we're allowed to extend the manifest
    # https://connect.microsoft.com/PowerShell/feedback/details/421837
    PSData = @{
        # Keyword tags to help users find this module via navigations and search.
        Tags = @('Development','Configuration','Settings','Storage')

        # The web address of this module's project or support homepage.
        ProjectUri = "https://github.com/PoshCode/Configuration"

        # The web address of this module's license. Points to a page that's embeddable and linkable.
        LicenseUri = "http://opensource.org/licenses/MIT"

        # Release notes for this particular version of the module
        ReleaseNotes = '
        v1.3.1: Use GetPureExpression().Value to support older versions of PowerShell

        v1.3.0: Bump version to hide 1.2 and justify the change to the save paths.
                Rename Get-StoragePath to Get-ConfigurationPath (old name is aliased)
        v1.2.0: Add Support for Linux and MacOS
                Stop using `mkdir -Force` because it does not work on Linux
                Add default paths for posix systems based on XDG standards
                Add logic for overriding the default paths in the Manifest
                Fix a bug in PSObject serialization (from v1.1.1)
                Fix bug with special property names (like PSObject) caused by dot notation
                Fix tests so they run cross-platform
                ACCIDENTALLY changed default save paths:
                   Using "powershell" instead of WindowsPowerShell (even in WindowsPowerShell)
        v1.1.0: Added support for ScriptBlocks and SwitchParameters
                Added support for serializing objects as hashtables
        '

        # Indicates this is a pre-release/testing version of the module.
        IsPrerelease = 'False'
    }
}

}

















# SIG # Begin signature block
# MIIXzgYJKoZIhvcNAQcCoIIXvzCCF7sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9pXNFnCy2/YLXyrcjx+zXJVh
# W9OgghMBMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUwMIIEGKADAgECAhAECRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9v
# dCBDQTAeFw0xMzEwMjIxMjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNp
# Z25pbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4R
# r2d3B9MLMUkZz9D7RZmxOttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrw
# nIal2CWsDnkoOn7p0WfTxvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnC
# wlLyFGeKiUXULaGj6YgsIJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8
# y5Kh5TsxHM/q8grkV7tKtel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM
# 0SAlI+sIZD5SlsHyDxL0xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6f
# pjOp/RnfJZPRAgMBAAGjggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1Ud
# DwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGsw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcw
# AoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Um9vdENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDov
# L2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBP
# BgNVHSAESDBGMDgGCmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoK
# o6XqcQPAYPkt9mV1DlgwHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8w
# DQYJKoZIhvcNAQELBQADggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+
# C2D9wz0PxK+L/e8q3yBVN7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119E
# efM2FAaK95xGTlz/kLEbBw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR
# 4pwUR6F6aGivm6dcIFzZcbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4v
# cn4c10lFluhZHen6dGRrsutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwH
# gfqL2vmCSfdibqFT+hKUGIUukpHqaGxEMrJmoecYpJpkUe8wggUwMIIEGKADAgEC
# AhALDZkX0sdOvwJhwzQTbV+7MA0GCSqGSIb3DQEBCwUAMHIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25p
# bmcgQ0EwHhcNMTgwNzEyMDAwMDAwWhcNMTkwNzE2MTIwMDAwWjBtMQswCQYDVQQG
# EwJVUzERMA8GA1UECBMITmV3IFlvcmsxFzAVBgNVBAcTDldlc3QgSGVucmlldHRh
# MRgwFgYDVQQKEw9Kb2VsIEguIEJlbm5ldHQxGDAWBgNVBAMTD0pvZWwgSC4gQmVu
# bmV0dDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMJb3Cf3n+/pFJiO
# hQqN5m54FpyIktMRWe5VyF8465BnAtzw3ivMyN+3k8IoXQhMxpCsY1TJbLyydNR2
# QzwEEtGfcTVnlAJdFFlBsgIdK43waaML5EG7tzNJKhHQDiN9bVhLPTXrit80eCTI
# RpOA7435oVG8erDpxhJUK364myUrmSyF9SbUX7uE09CJJgtB7vqetl4G+1j+iFDN
# Xi3bu1BFMWJp+TtICM+Zc5Wb+ZaYAE6V8t5GCyH1nlAI3cPjqVm8y5NoynZTfOhV
# bHiV0QI2K5WrBBboR0q6nd4cy6NJ8u5axi6CdUhnDMH20NN2I0v+2MBkgLAzxPrX
# kjnaEGECAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl6nEDwGD5LfZl
# dQ5YMB0GA1UdDgQWBBTiwur/NVanABEKwjZDB3g6SZN1mTAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOgMYYvaHR0cDov
# L2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwNaAzoDGG
# L2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3Js
# MEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8v
# d3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEFBQcBAQR4MHYw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBOBggrBgEFBQcw
# AoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3Vy
# ZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEL
# BQADggEBADNNHuRAdX0ddONqaUf3H3pwa1K016C02P90xDIyMvw+hiUb4Z/xewnY
# jyplspD0NQB9ca2pnNIy1KwjJryRgq8gl3epSiWTbViVn6VDK2h0JXm54H6hczQ8
# sEshCW53znNVUUUfxGsVM9kMcwITHYftciW0J+SsGcfuuAIuF1g47KQXKWOMcUQl
# yrP5t0ywotTVcg/1HWAPFE0V0sFy+Or4n81+BWXOLaCXIeeryLYncAVUBT1DI6lk
# peRUj/99kkn+hz1q4hHTtfNpMTOApP64EEFGKICKkJdvhs1PjtGa+QdAkhcInTxk
# t/hIJPUb1nO4CsKp1gaVsRkkbcStJ2kxggQ3MIIEMwIBATCBhjByMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBT
# aWduaW5nIENBAhALDZkX0sdOvwJhwzQTbV+7MAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTyOKJO
# SQFDHsqwuo/QCWLxyFHUYDANBgkqhkiG9w0BAQEFAASCAQAb/UFGyKhJFddLIQxJ
# VGu45ONnOoGPuo52v/4wYZSITIrPbD+av+vDAOXQ7CqBRKcdBKyfoiUADu7pTZ0o
# w5To9aA++C3RIq+warLgyU3Y51utbu/M/BN30zFFv3kjOW9O7RKoZq+VAZXe9sER
# ORxP9fLzoVyg24V95QIpMYf6ohRwoQ6jQa/u2KZ+bds+74LhqPxagmaAsc/YYXEi
# dXvI1eNeVjE9bsxm5DA4Z0iDOOr3pCwLxRqegCWRoQC+V/xXE02+zT0aXofMW0wm
# O08iTODfvrwSycsCuRiA0/CLJ+T6lVn/hoi/VZVk7R6hmHYPQjznwT8G5GYMKNrr
# ERuboYICCzCCAgcGCSqGSIb3DQEJBjGCAfgwggH0AgEBMHIwXjELMAkGA1UEBhMC
# VVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1h
# bnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzICEA7P9DjI/r81bgTY
# apgbGlAwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJ
# KoZIhvcNAQkFMQ8XDTE4MDcxMjA0Mzc0MlowIwYJKoZIhvcNAQkEMRYEFDgPGXET
# 3xQyw+EvGfFqOKKfD3l7MA0GCSqGSIb3DQEBAQUABIIBACnjvwKDcPnD1cqc2+xB
# LZuk/k4yQP9hOnCEjvI7y0lPUeqsA0UyA+OyOxZP5yBNK5bYfPDonZ+FKh2SPK0C
# q6MLaNC5+R2m2uS77UX58KoBXHHg3R8UHCSPuRVUvzBAewfMph0kvBm9QbjfyL/P
# VGdEv94UNXrWGHjQffJn+VZ1Upnr/Y0rcGE4ORlKsUm318JWD0hvaLnEWpMJlQq3
# QmlK2tfvXbUFIXnnGp+bctvhhn57DwEtb5/9gg9Loec/Pyt1yCcT7ME9Wewl/iKI
# 4IR5e/zL5saLrUwNfD0nkXbC/qhfb/eBs2NyO1B/0w8Cf4L1wva7UlPqDbYq5ZMy
# GBc=
# SIG # End signature block
