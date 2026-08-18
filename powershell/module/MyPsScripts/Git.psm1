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

  $isRemoteRef = $Branch -match '^origin/'
  $branchForGit = $Branch
  $branchName = if ($isRemoteRef) { $Branch -replace '^origin/', '' } else { $Branch }
  $safeBranch = $branchName -replace '[\/]', '_'
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

  $localBranch = & git -C $repoRoot branch --list $branchName 2>$null
  $remoteBranch = & git -C $repoRoot branch -r --list $branchForGit 2>$null

  Push-Location $repoRoot
  try
  {
    if ($localBranch)
    {
      git worktree add $worktreePath $branchName
    }
    elseif ($remoteBranch)
    {
      git worktree add -b $branchName $worktreePath $branchForGit
    }
    else
    {
      git worktree add -b $branchName $worktreePath
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

  # Switch out of the worktree first so Windows does not lock the directory.
  Set-Location $mainRepo

  if ($Force)
  {
    git worktree remove --force $topLevel
  } else
  {
    git worktree remove $topLevel
  }
  if ($LASTEXITCODE -ne 0)
  {
    if (-not (Test-Path -Path $topLevel))
    {
      git worktree prune
      Write-Warning "Worktree directory was already removed; pruned stale worktree record."
    } else
    {
      throw "Failed to remove worktree: $topLevel"
    }
  }

  $script:_git_worktree_main = $mainRepo
  $script:_git_worktree_path = $null
  Write-Host "Removed worktree and switched to main repository: $mainRepo"
}

<#
 .Synopsis
  Resolve the path to the clone mappings JSON file.

 .Description
  Returns $env:LOCALAPPDATA\MyPsScripts\clone-mappings.json.
#>
function Get-CloneMappingsFile
{
  $dir = Join-Path $env:LOCALAPPDATA "MyPsScripts"
  return Join-Path $dir "clone-mappings.json"
}

<#
 .Synopsis
  Read all GitCloneMapping records from disk.

 .Description
  Returns a list of hashtables with 'prefix' (string array) and 'root'
  (absolute path). Returns an empty list when the file does not exist;
  returns an empty list and warns when the file is corrupted.
#>
function Read-CloneMappings
{
  $file = Get-CloneMappingsFile
  if (-not (Test-Path -Path $file -PathType Leaf))
  {
    return @()
  }
  try
  {
    $json = Get-Content -Path $file -Raw | ConvertFrom-Json
    if (-not $json.mappings)
    {
      return @()
    }
    # NOTE: output unrolls naturally (scalar for a single mapping, array for
    # several). All internal callers already handle both via @()/foreach.
    return @($json.mappings | ForEach-Object {
      [PSCustomObject]@{ prefix = @($_.prefix); root = $_.root }
    })
  }
  catch
  {
    Write-Warning "Failed to read clone mappings file: $file ($_)"
    return @()
  }
}

<#
 .Synopsis
  Persist GitCloneMapping records to disk.

 .Description
  Writes the given list of mapping hashtables to the clone mappings file,
  creating the parent directory when needed.
#>
function Write-CloneMappings
{
  param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    [object[]]$Mappings
  )

  $file = Get-CloneMappingsFile
  $dir = Split-Path -Path $file -Parent
  if (-not (Test-Path -Path $dir -PathType Container))
  {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  $payload = @{
    mappings = @($Mappings | ForEach-Object {
      @{ prefix = @($_.prefix); root = $_.root }
    })
  }
  $payload | ConvertTo-Json -Depth 5 | Set-Content -Path $file -Encoding UTF8
}

<#
 .Synopsis
  Parse a git URL into host and path segments.

 .Description
  Accepts https/ssh URLs (https://host/owner/group/repo.git,
  ssh://git@host/owner/repo), scp-like ssh URLs
  (git@host:owner/group/repo.git) and shorthand (owner/repo, implying
  github.com). Returns a hashtable with 'Host' (lowercased, www. stripped),
  'PathSegments' (segments after the host, original case) and 'Segments'
  (host + path segments; host lowercased). Query strings, trailing slashes
  and a single trailing .git are dropped. Throws for unparseable input.
#>
function Resolve-GitRepoUrl
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Url
  )

  $url = $Url.Trim()

  $hostName = $null
  $path = $null

  if ($url -match '^[^@/:]+@([^/:]+):(.+)$')
  {
    $hostName = $Matches[1]
    $path = $Matches[2]
  }
  elseif ($url -match '^(?:https?|ssh|git)://(?:[^/@]+@)?([^/:]+)(?::\d+)?/(.*)$')
  {
    $hostName = $Matches[1]
    $path = $Matches[2]
  }
  elseif ($url -match '^([^/]+)/([^/]+)$')
  {
    $hostName = 'github.com'
    $path = $url
  }
  else
  {
    throw "Unsupported git URL: $Url"
  }

  $hostName = $hostName -replace '^www\.', ''
  $path = ($path -split '[?#]')[0].TrimEnd('/')
  if ($path -match '\.git$')
  {
    $path = $path.Substring(0, $path.Length - 4)
  }

  $pathSegments = @($path -split '/' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($pathSegments.Count -lt 2)
  {
    throw "Unable to determine repository from URL: $Url"
  }

  return @{
    Host         = $hostName.ToLowerInvariant()
    PathSegments = $pathSegments
    Segments     = @($hostName.ToLowerInvariant()) + $pathSegments
  }
}

<#
 .Synopsis
  Test whether Prefix is a prefix of Segments (segment by segment).

 .Description
  Prefix is a prefix of Segments when Prefix has no more segments than
  Segments and every segment of Prefix equals the corresponding segment
  of Segments.
#>
function Test-PrefixOf
{
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Prefix,
    [Parameter(Mandatory = $true)]
    [string[]]$Segments
  )

  if ($Prefix.Count -gt $Segments.Count)
  {
    return $false
  }
  for ($i = 0; $i -lt $Prefix.Count; $i++)
  {
    if ($Prefix[$i] -ne $Segments[$i])
    {
      return $false
    }
  }
  return $true
}

<#
 .Synopsis
  Test whether Prefix exactly equals Segments.

 .Description
  True when both lists have the same number of segments and every
  segment matches.
#>
function Test-PrefixEquals
{
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Prefix,
    [Parameter(Mandatory = $true)]
    [string[]]$Segments
  )

  return ($Prefix.Count -eq $Segments.Count) -and (Test-PrefixOf -Prefix $Prefix -Segments $Segments)
}

<#
 .Synopsis
  Find the GitCloneMapping with the longest prefix matching the segments.

 .Description
  Returns the mapping whose prefix is a prefix of $Segments with the
  greatest length, or $null when nothing matches.
#>
function Find-CloneMapping
{
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Segments
  )

  $best = $null
  foreach ($m in Read-CloneMappings)
  {
    $p = @($m.prefix)
    if (Test-PrefixOf -Prefix $p -Segments $Segments)
    {
      if (-not $best -or $p.Count -gt @($best.prefix).Count)
      {
        $best = $m
      }
    }
  }
  return $best
}

<#
 .Synopsis
  Interactively ask the user to define a new GitCloneMapping.

 .Description
  Lists every prefix level from the host down to the second-to-last
  segment and lets the user pick one level to map to a local root
  directory. Uses Out-GridView when available and interactive, otherwise
  falls back to a numbered menu. The root directory name is asked with a
  default suggestion (the picked level's last segment, lowercased);
  relative names are resolved against $HOME, absolute paths are used as-is.
#>
function Select-CloneMappingInteractive
{
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Segments
  )

  if ($Segments.Count -lt 2)
  {
    throw "Unable to determine a mapping level from URL: $($Segments -join '/')"
  }

  $options = @()
  for ($i = 0; $i -lt $Segments.Count - 1; $i++)
  {
    $options += [PSCustomObject]@{
      Level  = $i + 1
      Prefix = ($Segments[0..$i] -join '/')
    }
  }

  $selected = $null
  if ((Get-Command Out-GridView -ErrorAction SilentlyContinue) -and [Environment]::UserInteractive)
  {
    $selected = $options | Out-GridView -Title 'Select the prefix level to map to a local root directory' -OutputMode Single
  }
  else
  {
    Write-Host 'No matching clone mapping. Select the prefix level to map to a local root directory:'
    for ($n = 0; $n -lt $options.Count; $n++)
    {
      Write-Host ("{0}) {1}" -f ($n + 1), $options[$n].Prefix)
    }
    $choice = Read-Host "Enter a number (1-$($options.Count))"
    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $options.Count)
    {
      throw "Invalid selection: $choice"
    }
    $selected = $options[$idx]
  }

  if (-not $selected)
  {
    throw 'No mapping level selected.'
  }

  $defaultName = $Segments[[int]$selected.Level - 1].ToLowerInvariant()
  $input = Read-Host "Root directory name for '$($selected.Prefix)' (default: $defaultName)"
  if ([string]::IsNullOrWhiteSpace($input))
  {
    $input = $defaultName
  }

  $root = if ([System.IO.Path]::IsPathRooted($input)) { $input } else { Join-Path $HOME $input }

  return [PSCustomObject]@{
    prefix = @($Segments[0..([int]$selected.Level - 1)])
    root   = $root
  }
}

<#
 .Synopsis
  Get the GitCloneMapping records.

 .Description
  Lists every stored mapping from prefix segments to local root path.
  Accepts -Prefix to filter; an empty result means no mapping exists.
  A single result is returned as a scalar; wrap with @() for array
  semantics.

 .Parameter Prefix
  Filter: return only mappings whose prefix is a prefix of this segment list.
#>
function Get-GitCloneMapping
{
  [CmdletBinding()]
  param(
    [Parameter()]
    [string[]]$Prefix
  )

  $mappings = Read-CloneMappings
  if ($Prefix)
  {
    $mappings = @($mappings | Where-Object { Test-PrefixOf -Prefix @($_.prefix) -Segments $Prefix })
  }
  # NOTE: output unrolls naturally (scalar for a single result); callers that
  # need array semantics should wrap with @().
  return $mappings
}

<#
 .Synopsis
  Create or update a GitCloneMapping record.

 .Description
  Maps the given prefix segment list to a local root path. Relative root
  paths are resolved against $HOME; absolute paths are stored as-is.
  A mapping with the exact same prefix is updated; overlapping prefixes
  are kept with a warning (longest match wins at clone time).

 .Parameter Prefix
  The segment list (starting from the host) this mapping applies to,
  e.g. @("codeup.aliyun.com", "6098a93e58f98c96956644dc").

 .Parameter Root
  Local root path for this prefix; relative paths resolve against $HOME.
#>
function Set-GitCloneMapping
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Prefix,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Root
  )

  $root = $Root.Trim().TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
  if (-not [System.IO.Path]::IsPathRooted($root))
  {
    $root = Join-Path $HOME $root
  }
  $root = [System.IO.Path]::GetFullPath($root)

  $mappings = @(Read-CloneMappings)
  $updated = $false
  $kept = @()

  foreach ($m in $mappings)
  {
    $p = @($m.prefix)
    if (Test-PrefixEquals -Prefix $p -Segments $Prefix)
    {
      $updated = $true
      $kept += [PSCustomObject]@{ prefix = $Prefix; root = $root }
    }
    else
    {
      if ((Test-PrefixOf -Prefix $p -Segments $Prefix) -or (Test-PrefixOf -Prefix $Prefix -Segments $p))
      {
        Write-Warning "New mapping prefix '$($Prefix -join '/')' overlaps existing mapping '$($p -join '/')'; longest match wins."
      }
      $kept += $m
    }
  }

  if (-not $updated)
  {
    $kept += [PSCustomObject]@{ prefix = $Prefix; root = $root }
  }

  Write-CloneMappings -Mappings $kept
  Write-Host "Mapping saved: $($Prefix -join '/') -> $root"
}

<#
 .Synopsis
  Remove a GitCloneMapping record.

 .Description
  Removes the mapping whose prefix exactly equals the given prefix list.
  Warns when no such mapping exists.

 .Parameter Prefix
  The exact segment list of the mapping to remove,
  e.g. @("github.com").
#>
function Remove-GitCloneMapping
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Prefix
  )

  $mappings = @(Read-CloneMappings)
  $kept = @($mappings | Where-Object {
    $p = @($_.prefix)
    -not (Test-PrefixEquals -Prefix $p -Segments $Prefix)
  })

  if ($kept.Count -eq $mappings.Count)
  {
    Write-Warning "No mapping found for prefix: $($Prefix -join '/')"
    return
  }

  Write-CloneMappings -Mappings $kept
  Write-Host "Mapping removed: $($Prefix -join '/')"
}

<#
 .Synopsis
  Clone a git repository from any hosting platform into a mapped root directory.

 .Description
  Parses the given URL into host and path segments, then finds the
  GitCloneMapping whose prefix matches the segments (longest prefix wins).
  On a hit, the remaining segments are created as directories under the
  mapping root (names lowercased) and the repository is cloned into the
  last one. When nothing matches, the user is interactively asked to
  define the mapping first. If the target directory already exists and is
  non-empty, cloning is skipped. After cloning (or skipping), switches to
  the target directory and outputs its path.

 .Parameter Url
  Git repository URL: https://host/owner/group/repo[.git], ssh forms
  (git@host:owner/group/repo.git, ssh://git@host/owner/group/repo) or
  shorthand owner/repo[.git] (implying github.com). Query strings and
  trailing slashes are ignored.

 .Parameter Shallow
  Perform a shallow clone (git clone --depth 1).

 .Parameter UseSsh
  Rewrite the clone URL to ssh form (git@host:path.git).

 .Parameter Branch
  Check out the given branch after cloning (git clone -b <branch>).
#>
function Clone-GitRepo
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Url,

    [switch]$Shallow,
    [switch]$UseSsh,
    [string]$Branch
  )

  $parsed = Resolve-GitRepoUrl -Url $Url
  $segments = $parsed.Segments

  $mapping = Find-CloneMapping -Segments $segments
  if (-not $mapping)
  {
    $mapping = Select-CloneMappingInteractive -Segments $segments
    Set-GitCloneMapping -Prefix $mapping.prefix -Root $mapping.root
    $mapping = Find-CloneMapping -Segments $segments
  }

  $prefixCount = @($mapping.prefix).Count
  $remaining = $segments[$prefixCount..($segments.Count - 1)]
  $repoName = $remaining[-1].ToLowerInvariant()

  New-Item -ItemType Directory -Path $mapping.root -Force | Out-Null
  $current = $mapping.root
  for ($i = 0; $i -lt $remaining.Count - 1; $i++)
  {
    $current = Join-Path $current $remaining[$i].ToLowerInvariant()
    New-Item -ItemType Directory -Path $current -Force | Out-Null
  }
  $target = Join-Path $current $repoName

  if (Test-Path -Path $target)
  {
    $hasContent = @(Get-ChildItem -Path $target -Force -ErrorAction SilentlyContinue).Count -gt 0
    if ($hasContent)
    {
      Write-Host "Directory already exists, skipping clone: $target"
      Set-Location $target
      return $target
    }
  }

  $cloneUrl = $Url
  if ($UseSsh)
  {
    $cloneUrl = "git@$($parsed.Host):$(($parsed.PathSegments) -join '/').git"
  }

  $gitArgs = @('clone')
  if ($Shallow)
  {
    $gitArgs += @('--depth', '1')
  }
  if ($Branch)
  {
    $gitArgs += @('-b', $Branch)
  }
  $gitArgs += $cloneUrl
  $gitArgs += $target

  & git @gitArgs
  if ($LASTEXITCODE -ne 0)
  {
    throw "git clone failed with exit code ${LASTEXITCODE}: $cloneUrl"
  }

  Set-Location $target
  Write-Host "Cloned to: $target"
  return $target
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
Export-ModuleMember -Function Clone-GitRepo
Export-ModuleMember -Function Get-GitCloneMapping
Export-ModuleMember -Function Set-GitCloneMapping
Export-ModuleMember -Function Remove-GitCloneMapping
