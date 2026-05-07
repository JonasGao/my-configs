$script:_git_worktree_main = $null
$script:_git_worktree_path = $null

<#
 .Synopsis
  Create a git worktree and switch to it.

 .Description
  Creates a git worktree under $env:WORKTREES using naming pattern "repoName_branchName".
  After creation, switches to the new worktree directory and updates internal state
  so Switch-GitWorktreeMain can jump back to the main repository.

 .Parameter Branch
  The branch to checkout in the new worktree.

 .Parameter NewBranch
  When specified, creates a new branch based on the current HEAD of the main repository.

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

    [switch]$NewBranch,

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
  $worktreeName = "${repoName}_${Branch}"
  $worktreePath = Join-Path $worktreesRoot $worktreeName

  if (Test-Path -Path $worktreePath)
  {
    throw "Worktree path already exists: $worktreePath"
  }

  Push-Location $repoRoot
  try
  {
    if ($NewBranch)
    {
      git worktree add -b $Branch $worktreePath
    } else
    {
      git worktree add $worktreePath $Branch
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
