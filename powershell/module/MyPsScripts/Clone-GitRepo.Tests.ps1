# Tests for Clone-GitRepo and clone mappings

# Module must be loaded before discovery so InModuleScope blocks can find it.
Import-Module (Join-Path $PSScriptRoot "Git.psm1") -Force

Describe "Resolve-GitRepoUrl" {
    InModuleScope Git {
        It "parses https URL into segments" {
            $r = Resolve-GitRepoUrl -Url "https://github.com/Octocat/Hello-World.git"
            $r.Host | Should -Be "github.com"
            $r.Segments | Should -Be @("github.com", "octocat", "hello-world")
        }

        It "parses codeup multi-level URL" {
            $r = Resolve-GitRepoUrl -Url "git@codeup.aliyun.com:6098a93e58f98c96956644dc/xxx/qingbaozhongxin/info-center.git"
            $r.Host | Should -Be "codeup.aliyun.com"
            $r.Segments | Should -Be @("codeup.aliyun.com", "6098a93e58f98c96956644dc", "xxx", "qingbaozhongxin", "info-center")
        }

        It "parses scp-like ssh URL" {
            $r = Resolve-GitRepoUrl -Url "git@github.com:Octocat/Hello-World.git"
            $r.Host | Should -Be "github.com"
            $r.Segments | Should -Be @("github.com", "octocat", "hello-world")
        }

        It "parses ssh:// URL" {
            $r = Resolve-GitRepoUrl -Url "ssh://git@codeup.aliyun.com/6098.../xxx/repo.git"
            $r.Host | Should -Be "codeup.aliyun.com"
            $r.Segments | Should -Be @("codeup.aliyun.com", "6098...", "xxx", "repo")
        }

        It "strips www. from host" {
            $r = Resolve-GitRepoUrl -Url "https://www.github.com/octocat/hello-world"
            $r.Host | Should -Be "github.com"
        }

        It "ignores query strings" {
            $r = Resolve-GitRepoUrl -Url "https://github.com/octocat/hello-world?tab=readme"
            $r.Segments | Should -Be @("github.com", "octocat", "hello-world")
        }

        It "ignores trailing slash" {
            $r = Resolve-GitRepoUrl -Url "https://github.com/octocat/hello-world/"
            $r.Segments | Should -Be @("github.com", "octocat", "hello-world")
        }

        It "parses shorthand owner/repo implying github.com" {
            $r = Resolve-GitRepoUrl -Url "octocat/hello-world"
            $r.Host | Should -Be "github.com"
            $r.Segments | Should -Be @("github.com", "octocat", "hello-world")
        }

        It "parses shorthand with .git suffix" {
            $r = Resolve-GitRepoUrl -Url "octocat/hello-world.git"
            $r.Segments | Should -Be @("github.com", "octocat", "hello-world")
        }

        It "parses URL with port" {
            $r = Resolve-GitRepoUrl -Url "https://codeup.aliyun.com:8443/group/repo.git"
            $r.Host | Should -Be "codeup.aliyun.com"
            $r.Segments | Should -Be @("codeup.aliyun.com", "group", "repo")
        }

        It "throws on single segment" {
            { Resolve-GitRepoUrl -Url "https://github.com/octocat" } |
                Should -Throw "Unable to determine repository from URL: https://github.com/octocat"
        }

        It "throws on garbage input" {
            { Resolve-GitRepoUrl -Url "not a url at all" } |
                Should -Throw "Unsupported git URL: not a url at all"
        }
    }
}

Describe "GitCloneMapping persistence" {
    InModuleScope Git {
        BeforeEach {
            Mock Get-CloneMappingsFile { Join-Path $TestDrive "clone-mappings.json" }
        }

        AfterEach {
            Remove-Item (Join-Path $TestDrive "clone-mappings.json") -Force -ErrorAction SilentlyContinue
        }

        It "returns empty list when no file exists" {
            Get-GitCloneMapping | Should -BeNullOrEmpty
        }

        It "persists and reads back a mapping" {
            Set-GitCloneMapping -Prefix @("codeup.aliyun.com", "6098a93e58f98c96956644dc") -Root (Join-Path $TestDrive "codeup") | Out-Null
            $m = @(Get-GitCloneMapping)
            $m.Count | Should -Be 1
            $m[0].prefix | Should -Be @("codeup.aliyun.com", "6098a93e58f98c96956644dc")
            $m[0].root | Should -Be (Join-Path $TestDrive "codeup")
        }

        It "resolves relative root against HOME" {
            Set-GitCloneMapping -Prefix @("github.com") -Root "repos/github" | Out-Null
            $m = @(Get-GitCloneMapping)
            $m[0].root | Should -Be (Join-Path $HOME "repos/github")
        }

        It "normalizes trailing separator of absolute root" {
            Set-GitCloneMapping -Prefix @("github.com") -Root "$TestDrive\github\" | Out-Null
            $m = @(Get-GitCloneMapping)
            $m[0].root | Should -Be (Join-Path $TestDrive "github")
        }

        It "updates an existing mapping with same prefix" {
            Set-GitCloneMapping -Prefix @("github.com") -Root (Join-Path $TestDrive "a") | Out-Null
            Set-GitCloneMapping -Prefix @("github.com") -Root (Join-Path $TestDrive "b") | Out-Null
            $m = @(Get-GitCloneMapping)
            $m.Count | Should -Be 1
            $m[0].root | Should -Be (Join-Path $TestDrive "b")
        }

        It "warns on overlapping prefix but keeps both" {
            Set-GitCloneMapping -Prefix @("codeup.aliyun.com") -Root (Join-Path $TestDrive "codeup") | Out-Null
            { Set-GitCloneMapping -Prefix @("codeup.aliyun.com", "6098a93e58f98c96956644dc") -Root (Join-Path $TestDrive "aliyun") } |
                Should -Not -Throw
            (Get-GitCloneMapping).Count | Should -Be 2
        }

        It "filters by prefix" {
            Set-GitCloneMapping -Prefix @("github.com") -Root (Join-Path $TestDrive "github") | Out-Null
            Set-GitCloneMapping -Prefix @("codeup.aliyun.com") -Root (Join-Path $TestDrive "codeup") | Out-Null
            $m = @(Get-GitCloneMapping -Prefix @("github.com"))
            $m.Count | Should -Be 1
            $m[0].prefix | Should -Be @("github.com")
        }

        It "removes a mapping" {
            Set-GitCloneMapping -Prefix @("github.com") -Root (Join-Path $TestDrive "github") | Out-Null
            Remove-GitCloneMapping -Prefix @("github.com") | Out-Null
            Get-GitCloneMapping | Should -BeNullOrEmpty
        }

        It "warns when removing unknown prefix" {
            { Remove-GitCloneMapping -Prefix @("gitlab.com") } |
                Should -Not -Throw
        }
    }
}

Describe "Find-CloneMapping" {
    InModuleScope Git {
        BeforeEach {
            Mock Get-CloneMappingsFile { Join-Path $TestDrive "clone-mappings.json" }
            Set-GitCloneMapping -Prefix @("github.com") -Root (Join-Path $TestDrive "github") | Out-Null
            Set-GitCloneMapping -Prefix @("codeup.aliyun.com", "6098a93e58f98c96956644dc") -Root (Join-Path $TestDrive "codeup") | Out-Null
        }

        It "returns null when nothing matches" {
            Find-CloneMapping -Segments @("gitlab.com", "a", "b") | Should -BeNullOrEmpty
        }

        It "matches host-level prefix" {
            $m = Find-CloneMapping -Segments @("github.com", "octocat", "hello-world")
            $m.root | Should -Be (Join-Path $TestDrive "github")
        }

        It "picks longest prefix on codeup URL" {
            $m = Find-CloneMapping -Segments @("codeup.aliyun.com", "6098a93e58f98c96956644dc", "xxx", "qingbaozhongxin", "info-center")
            $m.root | Should -Be (Join-Path $TestDrive "codeup")
            @($m.prefix).Count | Should -Be 2
        }

        It "falls back to shorter prefix when deeper one does not match" {
            $m = Find-CloneMapping -Segments @("codeup.aliyun.com", "other-id", "xxx", "repo")
            $m | Should -BeNullOrEmpty
        }
    }
}

Describe "Clone-GitRepo" {
    InModuleScope Git {
        BeforeEach {
            Mock Get-CloneMappingsFile { Join-Path $TestDrive "clone-mappings.json" }
            Push-Location $TestDrive
            # Clean everything from the previous test (repos dirs + mappings file).
            # The previous test may have switched the location into the tree, so
            # clean here (after pushing), not in AfterEach.
            Get-ChildItem -Path $TestDrive -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Set-GitCloneMapping -Prefix @("github.com") -Root (Join-Path $TestDrive "github") | Out-Null
            Set-GitCloneMapping -Prefix @("codeup.aliyun.com", "6098a93e58f98c96956644dc") -Root (Join-Path $TestDrive "codeup") | Out-Null
            $script:gitCalls = @()
            Mock git {
                $global:LASTEXITCODE = 0
                $script:gitCalls += ,@($args)
                $target = $args[-1]
                New-Item -ItemType Directory -Path $target -Force | Out-Null
            }
        }

        AfterEach {
            Pop-Location
        }

        It "clones GitHub repo into mapping root with lowercased directory names" {
            $result = Clone-GitRepo -Url "https://github.com/Octocat/Hello-World"

            $result | Should -Be (Join-Path $TestDrive "github/octocat/hello-world")
            (Get-Location).Path | Should -Be (Join-Path $TestDrive "github/octocat/hello-world")
            Should -Invoke git -Times 1
        }

        It "creates nested directories for codeup path under mapping root" {
            $result = Clone-GitRepo -Url "git@codeup.aliyun.com:6098a93e58f98c96956644dc/xxx/qingbaozhongxin/info-center.git"

            $expected = Join-Path $TestDrive "codeup/xxx/qingbaozhongxin/info-center"
            $result | Should -Be $expected
            Test-Path -Path (Join-Path $TestDrive "codeup/xxx/qingbaozhongxin") -PathType Container | Should -BeTrue
            (Get-Location).Path | Should -Be $expected
        }

        It "clones directly under root when mapping covers all but the repo" {
            $result = Clone-GitRepo -Url "https://github.com/octocat/hello-world"
            $result | Should -Be (Join-Path $TestDrive "github/octocat/hello-world")
        }

        It "clones with full-coverage mapping whose prefix includes the repo name" {
            Set-GitCloneMapping -Prefix @("github.com", "octocat", "hello-world") -Root (Join-Path $TestDrive "exact-root") | Out-Null

            $result = Clone-GitRepo -Url "https://github.com/octocat/hello-world"

            $result | Should -Be (Join-Path $TestDrive "exact-root/hello-world")
        }

        It "uses ssh clone URL with -UseSsh" {
            Clone-GitRepo -Url "https://github.com/Octocat/Hello-World" -UseSsh | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone",
                "git@github.com:Octocat/Hello-World.git",
                (Join-Path $TestDrive "github/octocat/hello-world")
            )
        }

        It "uses ssh clone URL with -UseSsh for codeup" {
            Clone-GitRepo -Url "https://codeup.aliyun.com/6098a93e58f98c96956644dc/xxx/qingbaozhongxin/info-center" -UseSsh | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone",
                "git@codeup.aliyun.com:6098a93e58f98c96956644dc/xxx/qingbaozhongxin/info-center.git",
                (Join-Path $TestDrive "codeup/xxx/qingbaozhongxin/info-center")
            )
        }

        It "keeps ssh URL unchanged with -UseSsh" {
            Clone-GitRepo -Url "git@github.com:octocat/hello-world.git" -UseSsh | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone",
                "git@github.com:octocat/hello-world.git",
                (Join-Path $TestDrive "github/octocat/hello-world")
            )
        }

        It "passes --depth 1 with -Shallow" {
            Clone-GitRepo -Url "https://github.com/octocat/hello-world" -Shallow | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone", "--depth", "1",
                "https://github.com/octocat/hello-world",
                (Join-Path $TestDrive "github/octocat/hello-world")
            )
        }

        It "passes -b with -Branch" {
            Clone-GitRepo -Url "https://github.com/octocat/hello-world" -Branch "dev" | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone", "-b", "dev",
                "https://github.com/octocat/hello-world",
                (Join-Path $TestDrive "github/octocat/hello-world")
            )
        }

        It "skips when target directory exists and is non-empty" {
            $target = Join-Path $TestDrive "github/octocat/hello-world"
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $target "README.md") -Force | Out-Null

            $result = Clone-GitRepo -Url "https://github.com/octocat/hello-world"

            $result | Should -Be $target
            Should -Invoke git -Times 0
        }

        It "clones into an existing empty directory" {
            $target = Join-Path $TestDrive "github/octocat/hello-world"
            New-Item -ItemType Directory -Path $target -Force | Out-Null

            Clone-GitRepo -Url "https://github.com/octocat/hello-world" | Out-Null

            Should -Invoke git -Times 1
            (Get-Location).Path | Should -Be $target
        }

        It "asks interactively for unmapped URL and persists the mapping" {
            # NOTE: variable must not be named $mapping - inside the mock it would
            # resolve to Clone-GitRepo's own local $mapping (null at that point).
            $fakeMapping = @{
                prefix = @("gitlab.com", "group")
                root   = Join-Path $TestDrive "gitlab-root"
            }
            Mock Select-CloneMappingInteractive { $fakeMapping }

            $result = Clone-GitRepo -Url "https://gitlab.com/group/project"

            $result | Should -Be (Join-Path $TestDrive "gitlab-root/project")
            $saved = @(Get-GitCloneMapping -Prefix @("gitlab.com", "group"))
            $saved[0].root | Should -Be (Join-Path $TestDrive "gitlab-root")
        }

        It "throws when git clone fails" {
            Mock git { $global:LASTEXITCODE = 128 }
            { Clone-GitRepo -Url "https://github.com/octocat/hello-world" } |
                Should -Throw "git clone failed with exit code 128: https://github.com/octocat/hello-world"
        }
    }
}

Describe "Select-CloneMappingInteractive" {
    InModuleScope Git {
        It "falls back to numbered menu when Out-GridView is unavailable" {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq "Out-GridView" }
            Mock Read-Host {
                if ($Prompt -like "Enter a number*") { return "2" }
                if ($Prompt -like "Root directory name*") { return "" }
            }
            Mock Write-Host { }

            $m = Select-CloneMappingInteractive -Segments @("codeup.aliyun.com", "6098a93e58f98c96956644dc", "xxx", "qingbaozhongxin", "info-center")

            $m.prefix | Should -Be @("codeup.aliyun.com", "6098a93e58f98c96956644dc")
            $m.root | Should -Be (Join-Path $HOME "6098a93e58f98c96956644dc")
        }

        It "accepts absolute root path" {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq "Out-GridView" }
            Mock Read-Host {
                if ($Prompt -like "Enter a number*") { return "1" }
                if ($Prompt -like "Root directory name*") { return $TestDrive }
            }
            Mock Write-Host { }

            $m = Select-CloneMappingInteractive -Segments @("github.com", "octocat", "hello-world")

            $m.prefix | Should -Be @("github.com")
            $m.root | Should -Be $TestDrive
        }

        It "throws on invalid menu selection" {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq "Out-GridView" }
            Mock Read-Host { return "99" }
            Mock Write-Host { }

            { Select-CloneMappingInteractive -Segments @("github.com", "octocat", "hello-world") } |
                Should -Throw "Invalid selection: 99"
        }
    }
}
