# Tests for ProxyHelpers.psm1

# Detect whether [System.Net.Http.HttpClient]::DefaultProxy exists.
# This property is available in PowerShell 7+ / .NET 5+, but not in Windows PowerShell 5.1.
$script:httpClientProxySupported = $false
try {
    $null = [System.Net.Http.HttpClient]::DefaultProxy
    $script:httpClientProxySupported = $true
}
catch {
    $script:httpClientProxySupported = $false
}

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "ProxyHelpers.psm1"
    Import-Module $modulePath -Force

    $script:proxyEnvNames = @(
        'HTTP_PROXY', 'http_proxy',
        'HTTPS_PROXY', 'https_proxy',
        'ALL_PROXY', 'all_proxy',
        'NO_PROXY', 'no_proxy'
    )

    function Save-ProxyEnvVars {
        $table = @{}
        foreach ($name in $script:proxyEnvNames) {
            $path = "Env:$name"
            if (Test-Path -LiteralPath $path) {
                $table[$name] = (Get-Item -LiteralPath $path).Value
            }
            else {
                $table[$name] = $null
            }
        }
        return $table
    }

    function Restore-ProxyEnvVars {
        param ([hashtable]$Snapshot)
        foreach ($name in $script:proxyEnvNames) {
            $path = "Env:$name"
            $value = $Snapshot[$name]
            if ($null -eq $value) {
                Remove-Item -LiteralPath $path -ErrorAction SilentlyContinue
            }
            else {
                Set-Item -LiteralPath $path -Value $value
            }
        }
    }

    function Normalize-ProxyUrl {
        param ([string]$Url)
        return $Url.TrimEnd('/')
    }

    function Clear-ProxyEnvVarsTestHelper {
        foreach ($name in $script:proxyEnvNames) {
            Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
        }
    }
}

Describe "Get-EnvProxy" {
    BeforeEach {
        $script:originalEnvSnapshot = Save-ProxyEnvVars
        Clear-ProxyEnvVarsTestHelper
    }

    AfterEach {
        Restore-ProxyEnvVars -Snapshot $script:originalEnvSnapshot
    }

    It "Should return null when no proxy env vars are set" {
        $result = Get-EnvProxy
        $result | Should -BeNullOrEmpty
    }

    It "Should return proxy settings when env vars are set" {
        Set-EnvProxy -Url 'http://proxy.example.com:7890' -NoProxy 'localhost'

        $result = Get-EnvProxy
        $result.HTTP_PROXY | Should -Be 'http://proxy.example.com:7890'
        $result.NO_PROXY | Should -Be 'localhost'
    }
}

Describe "Set-DotNetProxy and Get-DotNetProxy" {
    BeforeEach {
        $script:originalWebRequestProxy = [System.Net.WebRequest]::DefaultWebProxy
        $script:originalHttpClientProxy = $null
        if ($script:httpClientProxySupported) {
            $script:originalHttpClientProxy = [System.Net.Http.HttpClient]::DefaultProxy
        }
    }

    AfterEach {
        [System.Net.WebRequest]::DefaultWebProxy = $script:originalWebRequestProxy
        if ($script:httpClientProxySupported) {
            [System.Net.Http.HttpClient]::DefaultProxy = $script:originalHttpClientProxy
        }
    }

    Context "Set-DotNetProxy" {
        It "Should set both WebRequest and HttpClient proxies" {
            Set-DotNetProxy -Url 'http://test-proxy.example.com:7890'

            $webProxy = [System.Net.WebRequest]::DefaultWebProxy
            $webProxy | Should -Not -BeNullOrEmpty
            (Normalize-ProxyUrl -Url $webProxy.Address.ToString()) | Should -Be (Normalize-ProxyUrl -Url 'http://test-proxy.example.com:7890')

            if ($script:httpClientProxySupported) {
                $httpProxy = [System.Net.Http.HttpClient]::DefaultProxy
                $httpProxy | Should -Not -BeNullOrEmpty
                (Normalize-ProxyUrl -Url $httpProxy.Address.ToString()) | Should -Be (Normalize-ProxyUrl -Url 'http://test-proxy.example.com:7890')
            }
        }

        It "Should clear proxies when given empty string" {
            Set-DotNetProxy -Url 'http://test-proxy.example.com:7890'
            Set-DotNetProxy -Url ''

            [System.Net.WebRequest]::DefaultWebProxy | Should -BeNullOrEmpty

            if ($script:httpClientProxySupported) {
                [System.Net.Http.HttpClient]::DefaultProxy | Should -BeNullOrEmpty
            }
        }

        It "Should trim whitespace from URL" {
            Set-DotNetProxy -Url '  http://test-proxy.example.com:7890  '

            $webProxy = [System.Net.WebRequest]::DefaultWebProxy
            (Normalize-ProxyUrl -Url $webProxy.Address.ToString()) | Should -Be (Normalize-ProxyUrl -Url 'http://test-proxy.example.com:7890')
        }
    }

    Context "Get-DotNetProxy" {
        It "Should return both proxy sources" {
            Set-DotNetProxy -Url 'http://test-proxy.example.com:7890'

            $result = Get-DotNetProxy
            (Normalize-ProxyUrl -Url $result.WebRequestProxy) | Should -Be (Normalize-ProxyUrl -Url 'http://test-proxy.example.com:7890')

            if ($script:httpClientProxySupported) {
                (Normalize-ProxyUrl -Url $result.HttpClientProxy) | Should -Be (Normalize-ProxyUrl -Url 'http://test-proxy.example.com:7890')
            }
        }

        It "Should return null values when no proxies are set" {
            Set-DotNetProxy -Url ''

            $result = Get-DotNetProxy
            $result.WebRequestProxy | Should -BeNullOrEmpty

            if ($script:httpClientProxySupported) {
                $result.HttpClientProxy | Should -BeNullOrEmpty
            }
        }

        It "Should handle different proxy values for WebRequest and HttpClient" {
            [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy 'http://web-proxy.example.com'

            if ($script:httpClientProxySupported) {
                [System.Net.Http.HttpClient]::DefaultProxy = New-Object System.Net.WebProxy 'http://http-proxy.example.com'

                $result = Get-DotNetProxy
                (Normalize-ProxyUrl -Url $result.WebRequestProxy) | Should -Be (Normalize-ProxyUrl -Url 'http://web-proxy.example.com')
                (Normalize-ProxyUrl -Url $result.HttpClientProxy) | Should -Be (Normalize-ProxyUrl -Url 'http://http-proxy.example.com')
            }
        }
    }
}
