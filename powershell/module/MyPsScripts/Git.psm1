$script:_git_worktree_main = $null
$script:_git_worktree_path = $null

<#
 .Synopsis
  Create a git worktree and switch to it.

 .Description
  Creates a git worktree under $env:WORKTREES using naming pattern "repoName_branchName".
  If the branch does not exist locally, it is automatically created from the current HEAD.
  After creation, switches to the new worktree directory and updates internal state
  so Switch-GitWorktreeMain can jump back to the main repository.

 .Parameter Branch
  The branch to checkout in the new worktree.

 .Parameter MainRepo
  Path to the main git repository. Defaults to the current directory.
#>
function Add-GitWorktree
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Branch,

    [string]$MainRepo = $PWD
  )

  $worktreesRoot = if ($env:WORKTREES) { $env:WORKTREES } else { Join-Path $HOME "worktrees" }
  if (-not (Test-Path -Path $worktreesRoot -PathType Container))
  {
    New-Item -ItemType Directory -Path $worktreesRoot -Force | Out-Null
    Write-Host "Created default worktrees directory: $worktreesRoot"
  }

  $resolvedMain = Resolve-Path -Path $MainRepo -ErrorAction SilentlyContinue
  if (-not $resolvedMain)
  {
    throw "Main repository path does not exist: $MainRepo"
  }
  $mainPath = $resolvedMain.Path

  $repoRoot = & git -C $mainPath rev-parse --show-toplevel 2>$null
  if (-not $repoRoot)
  {
    throw "Not a git repository: $mainPath"
  }
  $repoRoot = $repoRoot | Convert-Path

  $repoName = Split-Path -Path $repoRoot -Leaf
  $safeBranch = $Branch -replace '[\/]', '_'
  $worktreeName = "${repoName}_${safeBranch}"
  $worktreePath = Join-Path $worktreesRoot $worktreeName

  if (Test-Path -Path $worktreePath)
  {
    $script:_git_worktree_main = $repoRoot
    $script:_git_worktree_path = (Resolve-Path -Path $worktreePath).Path
    Set-Location $script:_git_worktree_path
    Write-Host "Worktree already exists, switched to: $script:_git_worktree_path"
    return
  }

  $localBranch = & git -C $repoRoot branch --list $Branch 2>$null
  $remoteBranch = & git -C $repoRoot branch -r --list "origin/$Branch" 2>$null

  Push-Location $repoRoot
  try
  {
    if ($localBranch)
    {
      git worktree add $worktreePath $Branch
    }
    elseif ($remoteBranch)
    {
      git worktree add -b $Branch $worktreePath origin/$Branch
    }
    else
    {
      git worktree add -b $Branch $worktreePath
    }
    if ($LASTEXITCODE -ne 0)
    {
      throw "Git worktree add failed with exit code $LASTEXITCODE"
    }
  } finally
  {
    Pop-Location
  }

  $script:_git_worktree_main = $repoRoot
  $script:_git_worktree_path = (Resolve-Path -Path $worktreePath).Path

  Set-Location $script:_git_worktree_path
  Write-Host "Switched to worktree: $script:_git_worktree_path"
}

<#
 .Synopsis
  Toggle between the main repository and the current worktree.

 .Description
  If currently inside the tracked worktree, jumps to the main repository.
  If currently inside the tracked main repository, jumps back to the worktree.
  If no internal state is available, attempts to infer the main repository
  from the current git worktree.
#>
function Switch-GitWorktreeMain
{
  [CmdletBinding()]
  param()

  $currentPath = (Get-Location).Path

  if ($script:_git_worktree_path -and $currentPath -eq $script:_git_worktree_path)
  {
    Set-Location $script:_git_worktree_main
    Write-Host "Switched to main repository: $script:_git_worktree_main"
    return
  }

  if ($script:_git_worktree_main -and $currentPath -eq $script:_git_worktree_main)
  {
    if (-not $script:_git_worktree_path)
    {
      throw "No worktree path recorded. Use Add-GitWorktree first."
    }
    Set-Location $script:_git_worktree_path
    Write-Host "Switched to worktree: $script:_git_worktree_path"
    return
  }

  # No tracked state matched; try to infer from git
  $gitCommonDir = & git rev-parse --git-common-dir 2>$null
  if ($gitCommonDir)
  {
    $gitCommonDir = $gitCommonDir | Convert-Path
    # For non-bare repos, --git-common-dir points to the main repo's .git directory
    $inferredMain = Split-Path -Parent $gitCommonDir

    # Check if current directory is the main repo itself
    $currentTopLevel = & git rev-parse --show-toplevel 2>$null | Convert-Path
    if ($currentTopLevel -and $currentTopLevel -eq $inferredMain)
    {
      # We are in main repo but no worktree recorded
      throw "Currently in main repository but no worktree path recorded. Use Add-GitWorktree first."
    }

    # Current directory is a worktree; record and jump to main
    $script:_git_worktree_path = $currentPath
    $script:_git_worktree_main = $inferredMain
    Set-Location $script:_git_worktree_main
    Write-Host "Switched to main repository: $script:_git_worktree_main"
    return
  }

  throw "Not in a tracked git worktree or main repository. Use Add-GitWorktree first."
}

<#
 .Synopsis
  Remove the current git worktree and switch back to the main repository.

 .Description
  Must be run inside a git worktree (not the main repository).
  Removes the current worktree via 'git worktree remove' and then switches
  to the main repository. Fails if there are uncommitted changes unless -Force is used.

 .Parameter Force
  Force removal even if the worktree has uncommitted changes or untracked files.
#>
function Remove-GitWorktree
{
  [CmdletBinding()]
  param(
    [switch]$Force
  )

  $topLevel = & git rev-parse --show-toplevel 2>$null
  if (-not $topLevel)
  {
    throw "Not a git repository."
  }
  $topLevel = $topLevel | Convert-Path

  $gitDir = & git rev-parse --git-dir 2>$null | Convert-Path
  $gitCommonDir = & git rev-parse --git-common-dir 2>$null | Convert-Path

  if ($gitDir -eq $gitCommonDir)
  {
    throw "This command must be run inside a worktree, not the main repository."
  }

  $mainRepo = Split-Path -Parent $gitCommonDir

  if ($Force)
  {
    git worktree remove --force $topLevel
  } else
  {
    git worktree remove $topLevel
  }
  if ($LASTEXITCODE -ne 0)
  {
    throw "Failed to remove worktree: $topLevel"
  }

  $script:_git_worktree_main = $mainRepo
  $script:_git_worktree_path = $null
  Set-Location $mainRepo
  Write-Host "Removed worktree and switched to main repository: $mainRepo"
}

Register-ArgumentCompleter -CommandName Add-GitWorktree -ParameterName Branch -ScriptBlock {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

  $repoPath = if ($fakeBoundParameters.ContainsKey('MainRepo')) {
    $fakeBoundParameters['MainRepo']
  } else {
    $PWD
  }

  $repoRoot = & git -C $repoPath rev-parse --show-toplevel 2>$null
  if (-not $repoRoot) { return }

  $branches = & git -C $repoRoot branch -a --format='%(refname:short)' 2>$null |
    ForEach-Object { $_ -replace '^remotes/origin/', '' } |
    Sort-Object -Unique

  foreach ($branch in $branches)
  {
    if ($branch -like "$wordToComplete*")
    {
      [System.Management.Automation.CompletionResult]::new($branch, $branch, 'ParameterValue', $branch)
    }
  }
}

Export-ModuleMember -Function Add-GitWorktree
Export-ModuleMember -Function Switch-GitWorktreeMain
Export-ModuleMember -Function Remove-GitWorktree
