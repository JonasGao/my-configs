# Tests for Enable-SshConnectionReuse and Disable-SshConnectionReuse

Describe "Enable-SshConnectionReuse" {
    BeforeAll {
        # Import the module
        $modulePath = Join-Path $PSScriptRoot "Ssh.psm1"
        Import-Module $modulePath -Force
    }

    BeforeEach {
        # Setup test directory
        $testDir = Join-Path $TestDrive "ssh-test-$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # Mock SSH home directory based on platform
        $originalHome = $env:HOME
        $originalUserProfile = $env:USERPROFILE
        
        if ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT") {
            $env:USERPROFILE = $testDir
        } else {
            $env:HOME = $testDir
        }
        
        $script:testSshDir = Join-Path $testDir ".ssh"
        $script:testConfigFile = Join-Path $script:testSshDir "config"
        $script:testSocketsDir = Join-Path $script:testSshDir "sockets"
    }

    AfterEach {
        # Restore original environment
        $env:HOME = $originalHome
        $env:USERPROFILE = $originalUserProfile
    }

    Context "When SSH config doesn't exist" {
        It "Should create .ssh directory" {
            Enable-SshConnectionReuse -PersistMinutes 10
            
            $script:testSshDir | Should -Exist
        }

        It "Should create sockets directory" {
            Enable-SshConnectionReuse -PersistMinutes 10
            
            $script:testSocketsDir | Should -Exist
        }

        It "Should create SSH config file with ControlMaster settings" {
            Enable-SshConnectionReuse -PersistMinutes 15
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "Host \*"
            $configContent | Should -Match "ControlMaster auto"
            $configContent | Should -Match "ControlPath.*\.ssh\\sockets\\%r@%h-%p"
            $configContent | Should -Match "ControlPersist 15m"
        }

        It "Should use default PersistMinutes of 10" {
            Enable-SshConnectionReuse
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "ControlPersist 10m"
        }
    }

    Context "When SSH config already exists with content" {
        BeforeEach {
            New-Item -Path $script:testSshDir -ItemType Directory -Force | Out-Null
            @"
Host github.com
    User git
    IdentityFile ~/.ssh/id_rsa

"@ | Out-File -FilePath $script:testConfigFile -Encoding utf8 -Force
        }

        It "Should preserve existing config content" {
            Enable-SshConnectionReuse -PersistMinutes 10
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "Host github.com"
            $configContent | Should -Match "User git"
        }

        It "Should add ControlMaster settings" {
            Enable-SshConnectionReuse -PersistMinutes 10
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "Host \*"
            $configContent | Should -Match "ControlMaster auto"
        }

        It "Should not duplicate ControlMaster config without Force" {
            Enable-SshConnectionReuse -PersistMinutes 10
            Enable-SshConnectionReuse -PersistMinutes 20
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $controlMasterMatches = [regex]::Matches($configContent, "ControlMaster auto")
            $controlMasterMatches.Count | Should -Be 1
        }

        It "Should update ControlPersist with Force" {
            Enable-SshConnectionReuse -PersistMinutes 10
            Enable-SshConnectionReuse -PersistMinutes 20 -Force
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "ControlPersist 20m"
            $configContent | Should -Not -Match "ControlPersist 10m"
        }
    }

    Context "ControlMaster config format" {
        It "Should use backslashes in ControlPath on Windows" {
            # Skip on non-Windows
            if (-not ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT")) {
                Set-ItResult -Skipped -Because "Test only applies to Windows"
            }
            
            Enable-SshConnectionReuse -PersistMinutes 10
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "ControlPath.*\\.ssh\\.sockets\\%r@%h-%p"
        }

        It "Should use forward slashes in ControlPath on Linux/Mac" {
            # Skip on Windows
            if ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT") {
                Set-ItResult -Skipped -Because "Test only applies to Linux/Mac"
            }
            
            Enable-SshConnectionReuse -PersistMinutes 10
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "ControlPath.*\.ssh/sockets/%r@%h-%p"
        }
    }
}

Describe "Disable-SshConnectionReuse" {
    BeforeAll {
        # Import the module
        $modulePath = Join-Path $PSScriptRoot "Ssh.psm1"
        Import-Module $modulePath -Force
    }

    BeforeEach {
        # Setup test directory
        $testDir = Join-Path $TestDrive "ssh-test-$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # Mock SSH home directory based on platform
        $originalHome = $env:HOME
        $originalUserProfile = $env:USERPROFILE
        
        if ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT") {
            $env:USERPROFILE = $testDir
        } else {
            $env:HOME = $testDir
        }
        
        $script:testSshDir = Join-Path $testDir ".ssh"
        $script:testConfigFile = Join-Path $script:testSshDir "config"
        $script:testSocketsDir = Join-Path $script:testSshDir "sockets"
    }

    AfterEach {
        # Restore original environment
        $env:HOME = $originalHome
        $env:USERPROFILE = $originalUserProfile
    }

    Context "When ControlMaster config exists" {
        BeforeEach {
            New-Item -Path $script:testSshDir -ItemType Directory -Force | Out-Null
            @"
Host github.com
    User git
    IdentityFile ~/.ssh/id_rsa

Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 10m

Host server.com
    HostName 192.168.1.1
"@ | Out-File -FilePath $script:testConfigFile -Encoding utf8 -Force
        }

        It "Should remove ControlMaster config" {
            Disable-SshConnectionReuse
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Not -Match "Host \*"
            $configContent | Should -Not -Match "ControlMaster auto"
        }

        It "Should preserve other host configurations" {
            Disable-SshConnectionReuse
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "Host github.com"
            $configContent | Should -Match "Host server.com"
            $configContent | Should -Match "User git"
        }

        It "Should not remove socket files by default" {
            New-Item -Path $script:testSocketsDir -ItemType Directory -Force | Out-Null
            $socketFile = Join-Path $script:testSocketsDir "test@host-22"
            "dummy" | Out-File -FilePath $socketFile -Force
            
            Disable-SshConnectionReuse
            
            $socketFile | Should -Exist
        }

        It "Should remove socket files when RemoveSockets is specified" {
            New-Item -Path $script:testSocketsDir -ItemType Directory -Force | Out-Null
            $socketFile = Join-Path $script:testSocketsDir "test@host-22"
            "dummy" | Out-File -FilePath $socketFile -Force
            
            Disable-SshConnectionReuse -RemoveSockets
            
            $socketFile | Should -Not -Exist
        }

        It "Should remove sockets directory when empty after RemoveSockets" {
            New-Item -Path $script:testSocketsDir -ItemType Directory -Force | Out-Null
            
            Disable-SshConnectionReuse -RemoveSockets
            
            $script:testSocketsDir | Should -Not -Exist
        }
    }

    Context "When SSH config doesn't exist" {
        It "Should not throw error" {
            { Disable-SshConnectionReuse } | Should -Not -Throw
        }
    }

    Context "When config has no ControlMaster settings" {
        BeforeEach {
            New-Item -Path $script:testSshDir -ItemType Directory -Force | Out-Null
            @"
Host github.com
    User git
    IdentityFile ~/.ssh/id_rsa
"@ | Out-File -FilePath $script:testConfigFile -Encoding utf8 -Force
        }

        It "Should preserve existing config" {
            Disable-SshConnectionReuse
            
            $configContent = Get-Content $script:testConfigFile -Raw
            $configContent | Should -Match "Host github.com"
            $configContent | Should -Match "User git"
        }
    }
}