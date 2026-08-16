# Tests for Clone-GitRepo

# Module must be loaded before discovery so InModuleScope blocks can find it.
Import-Module (Join-Path $PSScriptRoot "Git.psm1") -Force

Describe "Get-GitHubRepoParts" {
    InModuleScope Git {
        It "parses https URL with .git suffix" {
            $parts = Get-GitHubRepoParts -Url "https://github.com/Octocat/Hello-World.git"
            $parts.Owner | Should -Be "Octocat"
            $parts.Repo | Should -Be "Hello-World"
        }

        It "parses https URL without .git suffix" {
            $parts = Get-GitHubRepoParts -Url "https://github.com/octocat/hello-world"
            $parts.Owner | Should -Be "octocat"
            $parts.Repo | Should -Be "hello-world"
        }

        It "ignores trailing slash and extra path segments" {
            $parts = Get-GitHubRepoParts -Url "https://github.com/octocat/hello-world/tree/main"
            $parts.Owner | Should -Be "octocat"
            $parts.Repo | Should -Be "hello-world"
        }

        It "ignores query strings" {
            $parts = Get-GitHubRepoParts -Url "https://github.com/octocat/hello-world?tab=readme"
            $parts.Repo | Should -Be "hello-world"
        }

        It "parses scp-like ssh URL" {
            $parts = Get-GitHubRepoParts -Url "git@github.com:Octocat/Hello-World.git"
            $parts.Owner | Should -Be "Octocat"
            $parts.Repo | Should -Be "Hello-World"
        }

        It "parses ssh:// URL" {
            $parts = Get-GitHubRepoParts -Url "ssh://git@github.com/octocat/hello-world.git"
            $parts.Owner | Should -Be "octocat"
            $parts.Repo | Should -Be "hello-world"
        }

        It "parses www.github.com URL" {
            $parts = Get-GitHubRepoParts -Url "https://www.github.com/octocat/hello-world"
            $parts.Owner | Should -Be "octocat"
            $parts.Repo | Should -Be "hello-world"
        }

        It "parses shorthand owner/repo" {
            $parts = Get-GitHubRepoParts -Url "octocat/hello-world"
            $parts.Owner | Should -Be "octocat"
            $parts.Repo | Should -Be "hello-world"
        }

        It "parses shorthand owner/repo with .git suffix" {
            $parts = Get-GitHubRepoParts -Url "octocat/hello-world.git"
            $parts.Owner | Should -Be "octocat"
            $parts.Repo | Should -Be "hello-world"
        }

        It "throws on non-GitHub host" {
            { Get-GitHubRepoParts -Url "https://gitlab.com/octocat/hello-world" } |
                Should -Throw "Unsupported git host: gitlab.com"
        }

        It "throws on single segment" {
            { Get-GitHubRepoParts -Url "https://github.com/octocat" } |
                Should -Throw "Unable to determine owner/repository from URL: https://github.com/octocat"
        }

        It "throws on garbage input" {
            { Get-GitHubRepoParts -Url "not a url at all" } |
                Should -Throw "Unsupported git URL: not a url at all"
        }
    }
}

Describe "Get-GitHubCloneRoot" {
    AfterEach {
        Remove-Item Env:GITHUB_HOME -ErrorAction SilentlyContinue
    }

    InModuleScope Git {
        It "uses GITHUB_HOME when set" {
            $env:GITHUB_HOME = Join-Path $TestDrive "my-github"
            Get-GitHubCloneRoot | Should -Be $env:GITHUB_HOME
        }

        It "creates the directory when it does not exist" {
            $env:GITHUB_HOME = Join-Path $TestDrive "fresh-github"
            Get-GitHubCloneRoot | Should -Be $env:GITHUB_HOME
            Test-Path -Path $env:GITHUB_HOME -PathType Container | Should -BeTrue
        }

        It "normalizes trailing separator" {
            $env:GITHUB_HOME = "$TestDrive\my-github\"
            Get-GitHubCloneRoot | Should -Be (Join-Path $TestDrive "my-github")
        }

        It "normalizes relative paths" {
            $env:GITHUB_HOME = "rel-github"
            Push-Location $TestDrive
            try {
                Get-GitHubCloneRoot | Should -Be (Join-Path $TestDrive "rel-github")
            } finally {
                Pop-Location
            }
        }

        It "falls back to HOME\github when GITHUB_HOME is not set" {
            Remove-Item Env:GITHUB_HOME -ErrorAction SilentlyContinue
            Mock New-Item { } -ParameterFilter { $Path -eq (Join-Path $HOME "github") }
            Get-GitHubCloneRoot | Should -Be (Join-Path $HOME "github")
        }
    }
}

Describe "Clone-GitRepo" {
    InModuleScope Git {
        BeforeEach {
            $env:GITHUB_HOME = Join-Path $TestDrive "github"
            Push-Location $TestDrive
            # Clean state from the previous test (previous test may have left
            # its current location inside the tree, so clean before, not after)
            Remove-Item (Join-Path $TestDrive "github") -Recurse -Force -ErrorAction SilentlyContinue
            $script:gitCalls = @()
            Mock git {
                $global:LASTEXITCODE = 0
                $script:gitCalls += ,@($args)
                # Simulate a real clone creating the target directory
                $target = $args[-1]
                New-Item -ItemType Directory -Path $target -Force | Out-Null
            }
        }

        AfterEach {
            Remove-Item Env:GITHUB_HOME -ErrorAction SilentlyContinue
            Pop-Location
        }

        It "clones https URL into GITHUB_HOME\owner\repo with lowercased directory names" {
            $result = Clone-GitRepo -Url "https://github.com/Octocat/Hello-World"

            $result | Should -Be (Join-Path $env:GITHUB_HOME "octocat/hello-world")
            (Get-Location).Path | Should -Be (Join-Path $env:GITHUB_HOME "octocat/hello-world")
            Should -Invoke git -Times 1
        }

        It "creates the owner directory" {
            Clone-GitRepo -Url "https://github.com/octocat/hello-world" | Out-Null
            Test-Path -Path (Join-Path $env:GITHUB_HOME "octocat") -PathType Container | Should -BeTrue
        }

        It "uses ssh clone URL with -UseSsh" {
            Clone-GitRepo -Url "https://github.com/Octocat/Hello-World" -UseSsh | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone",
                "git@github.com:Octocat/Hello-World.git",
                (Join-Path $env:GITHUB_HOME "octocat/hello-world")
            )
        }

        It "keeps ssh URL unchanged with -UseSsh" {
            Clone-GitRepo -Url "git@github.com:octocat/hello-world.git" -UseSsh | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone",
                "git@github.com:octocat/hello-world.git",
                (Join-Path $env:GITHUB_HOME "octocat/hello-world")
            )
        }

        It "passes --depth 1 with -Shallow" {
            Clone-GitRepo -Url "https://github.com/octocat/hello-world" -Shallow | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone", "--depth", "1",
                "https://github.com/octocat/hello-world",
                (Join-Path $env:GITHUB_HOME "octocat/hello-world")
            )
        }

        It "passes -b with -Branch" {
            Clone-GitRepo -Url "https://github.com/octocat/hello-world" -Branch "dev" | Out-Null
            $script:gitCalls[0] | Should -Be @(
                "clone", "-b", "dev",
                "https://github.com/octocat/hello-world",
                (Join-Path $env:GITHUB_HOME "octocat/hello-world")
            )
        }

        It "skips when target directory exists and is non-empty" {
            $target = Join-Path $env:GITHUB_HOME "octocat/hello-world"
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $target "README.md") -Force | Out-Null

            $result = Clone-GitRepo -Url "https://github.com/octocat/hello-world"

            $result | Should -Be $target
            Should -Invoke git -Times 0
        }

        It "clones into an existing empty directory" {
            $target = Join-Path $env:GITHUB_HOME "octocat/hello-world"
            New-Item -ItemType Directory -Path $target -Force | Out-Null

            Clone-GitRepo -Url "https://github.com/octocat/hello-world" | Out-Null

            Should -Invoke git -Times 1
            (Get-Location).Path | Should -Be $target
        }

        It "throws on non-GitHub URL" {
            { Clone-GitRepo -Url "https://gitlab.com/a/b" } |
                Should -Throw "Unsupported git host: gitlab.com"
        }

        It "throws when git clone fails" {
            Mock git { $global:LASTEXITCODE = 128 }
            { Clone-GitRepo -Url "https://github.com/octocat/hello-world" } |
                Should -Throw "git clone failed with exit code 128: https://github.com/octocat/hello-world"
        }
    }
}
