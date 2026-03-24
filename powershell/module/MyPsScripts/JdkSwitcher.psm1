<#
.Synopsis
JDK local registry and environment switcher for PowerShell.

.Description
Provides commands to register local JDK homes, query them, search disk for candidates,
switch current session JAVA_HOME/PATH, and clear persisted mappings.

.Notes
Data file: $HOME\.jdks\javahome.csv
#>
Set-StrictMode -Version Latest

$script:JAVA_HOME_LIST_DIR = Join-Path $HOME ".jdks"
$script:JAVA_HOME_LIST_FILE = Join-Path $script:JAVA_HOME_LIST_DIR "javahome.csv"
$script:LEGACY_JDK_FILES = @(
  (Join-Path $script:JAVA_HOME_LIST_DIR "javahome.txt"),
  (Join-Path $script:JAVA_HOME_LIST_DIR "javahome.properties"),
  (Join-Path $script:JAVA_HOME_LIST_DIR "jdk.csv")
)

function Convert-JdkContentToTable {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RawContent
  )

  $table = @{}
  if ([string]::IsNullOrWhiteSpace($RawContent)) {
    return $table
  }

  $trimmed = $RawContent.TrimStart([char]0xFEFF).Trim()

  # Current format (v2): CSV with Id/Key/Path header.
  if ($trimmed -match '^(?i)"?Id"?\s*,\s*"?Key"?\s*,\s*"?Path"?\s*$') {
    $csvRows = $trimmed | ConvertFrom-Csv
    foreach ($row in $csvRows) {
      if ($row.Key -and $row.Path) {
        $table[$row.Key.Trim()] = @{
          Id   = if ($row.Id) { $row.Id.Trim() } else { $null }
          Path = $row.Path.Trim()
        }
      }
    }
    return $table
  }

  # Previous format (v1): CSV with Key/Value header.
  if ($trimmed -match '^(?i)"?Key"?\s*,\s*"?Value"?\s*$') {
    $csvRows = $trimmed | ConvertFrom-Csv
    foreach ($row in $csvRows) {
      if ($row.Key -and $row.Value) {
        $table[$row.Key.Trim()] = @{
          Id   = $null
          Path = $row.Value.Trim()
        }
      }
    }
    return $table
  }

  # Legacy format 1: CSV without header. e.g. jdk8,C:\Java\jdk1.8
  # Legacy format 2: key=value
  # Legacy format 3: key:path
  $lines = $trimmed -split "(`r`n|`n|`r)"
  foreach ($lineRaw in $lines) {
    $line = $lineRaw.Trim()
    if (-not $line -or $line.StartsWith("#")) { continue }

    $key = $null
    $value = $null
    if ($line -match "^\s*([^,=:\s]+)\s*,\s*(.+?)\s*$") {
      $key = $Matches[1]
      $value = $Matches[2]
    } elseif ($line -match "^\s*([^=:\s]+)\s*=\s*(.+?)\s*$") {
      $key = $Matches[1]
      $value = $Matches[2]
    } elseif ($line -match "^\s*([^=,\s]+)\s*:\s*(.+?)\s*$") {
      $key = $Matches[1]
      $value = $Matches[2]
    }

    if ($key -and $value) {
      $table[$key.Trim()] = @{
        Id   = $null
        Path = $value.Trim()
      }
    }
  }

  return $table
}

function Get-JdkVersionDetail {
  param(
    [Parameter(Mandatory = $true)]
    [string]$JavaHome
  )

  $javaExe = Join-Path $JavaHome "bin\java.exe"
  if (-not (Test-Path -Path $javaExe -PathType Leaf)) {
    $javaExe = Join-Path $JavaHome "bin\java"
  }
  if (-not (Test-Path -Path $javaExe -PathType Leaf)) {
    return "unknown-java-version"
  }

  try {
    # java -version usually writes to stderr.
    $outputLines = & $javaExe -version 2>&1
    $text = ($outputLines | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join "|"
    if (-not $text) { return "unknown-java-version" }
    return $text
  } catch {
    return "unknown-java-version"
  }
}

function New-HashText {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hashBytes = $sha.ComputeHash($bytes)
    return ([BitConverter]::ToString($hashBytes) -replace "-", "").ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function New-JdkId {
  param(
    [Parameter(Mandatory = $true)]
    [string]$JavaHome
  )

  $versionDetail = Get-JdkVersionDetail -JavaHome $JavaHome
  $fingerprint = "$versionDetail|$JavaHome"
  $hash = New-HashText -Text $fingerprint
  return "jdk-" + $hash.Substring(0, 16)
}

function Backup-FileForMigration {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (Test-Path -Path $Path -PathType Leaf) {
    $stamp = Get-Date -Format "yyyyMMddHHmmss"
    $backup = "$Path.legacy.$stamp.bak"
    Copy-Item -Path $Path -Destination $backup -Force
    return $backup
  }
  return $null
}

function Invoke-JdkStoreMigration {
  # 1) Try to normalize current javahome.csv (supports legacy content in same file).
  $currentRaw = Get-Content -Path $script:JAVA_HOME_LIST_FILE -Raw -ErrorAction SilentlyContinue
  if (-not [string]::IsNullOrWhiteSpace($currentRaw)) {
    $currentTable = Convert-JdkContentToTable -RawContent $currentRaw
    if ($currentTable.Count -gt 0) {
      if (-not ($currentRaw.TrimStart([char]0xFEFF) -match '^(?i)"?Id"?\s*,\s*"?Key"?\s*,\s*"?Path"?\s*$')) {
        $backupPath = Backup-FileForMigration -Path $script:JAVA_HOME_LIST_FILE
        Save-Jdks -Table $currentTable
        Write-Verbose "Migrated legacy JDK records in current file. Backup: $backupPath"
      }
      return
    }
  }

  # 2) Current file is empty/unusable, try to import from known legacy files.
  foreach ($legacyFile in $script:LEGACY_JDK_FILES) {
    if (-not (Test-Path -Path $legacyFile -PathType Leaf)) { continue }
    $legacyRaw = Get-Content -Path $legacyFile -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($legacyRaw)) { continue }

    $legacyTable = Convert-JdkContentToTable -RawContent $legacyRaw
    if ($legacyTable.Count -le 0) { continue }

    $legacyBackup = Backup-FileForMigration -Path $legacyFile
    Save-Jdks -Table $legacyTable
    Write-Verbose "Migrated JDK records from legacy file '$legacyFile'. Backup: $legacyBackup"
    return
  }
}

function Initialize-JdkStore {
  if (-not (Test-Path -Path $script:JAVA_HOME_LIST_DIR -PathType Container)) {
    New-Item -ItemType Directory -Path $script:JAVA_HOME_LIST_DIR -Force | Out-Null
  }
  if (-not (Test-Path -Path $script:JAVA_HOME_LIST_FILE -PathType Leaf)) {
    New-Item -ItemType File -Path $script:JAVA_HOME_LIST_FILE -Force | Out-Null
  }
  Invoke-JdkStoreMigration
}

function Test-IsJavaHome {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
  )

  if (-not (Test-Path -Path $Path -PathType Container)) { return $false }

  $javaExe = Join-Path $Path "bin\java.exe"
  $javacExe = Join-Path $Path "bin\javac.exe"
  $javaCmd = Join-Path $Path "bin\java"
  $javacCmd = Join-Path $Path "bin\javac"

  return (Test-Path $javaExe -PathType Leaf) -or
         (Test-Path $javacExe -PathType Leaf) -or
         ((Test-Path $javaCmd -PathType Leaf) -and (Test-Path $javacCmd -PathType Leaf))
}

function Resolve-JavaHomePath {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
  )

  $resolved = (Resolve-Path -Path $Path -ErrorAction Stop).Path
  if (-not (Test-IsJavaHome -Path $resolved)) {
    throw "Path '$resolved' is not a valid JDK home (missing bin/java or bin/javac)."
  }
  return $resolved
}

function Read-Jdks {
  [CmdletBinding()]
  param()

  Initialize-JdkStore
  $table = @{}

  $raw = Get-Content -Path $script:JAVA_HOME_LIST_FILE -Raw -ErrorAction SilentlyContinue
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return $table
  }

  $table = Convert-JdkContentToTable -RawContent $raw

  $needsSave = $false
  foreach ($key in @($table.Keys)) {
    $record = $table[$key]
    if ($record -isnot [hashtable]) {
      $table[$key] = @{
        Id   = $null
        Path = [string]$record
      }
      $record = $table[$key]
      $needsSave = $true
    }
    if (-not $record.ContainsKey("Id") -or [string]::IsNullOrWhiteSpace($record.Id)) {
      $record.Id = New-JdkId -JavaHome $record.Path
      $needsSave = $true
    }
  }

  if ($needsSave) {
    Save-Jdks -Table $table
  }

  return $table
}

function Save-Jdks {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Table
  )

  if (-not (Test-Path -Path $script:JAVA_HOME_LIST_DIR -PathType Container)) {
    New-Item -ItemType Directory -Path $script:JAVA_HOME_LIST_DIR -Force | Out-Null
  }
  if (-not (Test-Path -Path $script:JAVA_HOME_LIST_FILE -PathType Leaf)) {
    New-Item -ItemType File -Path $script:JAVA_HOME_LIST_FILE -Force | Out-Null
  }

  $rows = foreach ($item in ($Table.GetEnumerator() | Sort-Object Key)) {
    $record = $item.Value
    if ($record -isnot [hashtable]) {
      $record = @{
        Id   = New-JdkId -JavaHome ([string]$item.Value)
        Path = [string]$item.Value
      }
    } else {
      if (-not $record.ContainsKey("Id") -or [string]::IsNullOrWhiteSpace($record.Id)) {
        $record.Id = New-JdkId -JavaHome $record.Path
      }
    }
    [pscustomobject]@{
      Id   = $record.Id
      Key  = $item.Key
      Path = $record.Path
    }
  }

  $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $script:JAVA_HOME_LIST_FILE
}

<#
.Synopsis
Register or update a local JDK mapping.

.Description
Validates the given path as a JDK home, then stores id/key/path mapping into
the local csv registry. Existing key will be overwritten.

.Parameter Key
Unique key used to reference a JDK, for example: jdk8, jdk17, jdk21.
Colon is not allowed.

.Parameter Path
JDK home directory path. Must contain java/javac command in its bin folder.

.Example
Set-JavaHome -Key jdk21 -Path "C:\Program Files\Java\jdk-21"
#>
function Set-JavaHome {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[^:]+$")]
    [string]$Key,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
  )

  $jdks = Read-Jdks
  $fullName = Resolve-JavaHomePath -Path $Path
  $id = New-JdkId -JavaHome $fullName
  $jdks[$Key] = @{
    Id   = $id
    Path = $fullName
  }
  Save-Jdks -Table $jdks
  Write-Output "Saved JDK '$Key' (Id: $id) => '$fullName'"
}

<#
.Synopsis
Remove one JDK mapping by key.

.Description
Deletes the mapping entry from local csv registry. This does not uninstall JDK;
it only removes the local alias record.

.Parameter Key
The alias key to remove.

.Example
Remove-JavaHome -Key jdk8
#>
function Remove-JavaHome {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Key
  )

  $jdks = Read-Jdks
  if (-not $jdks.ContainsKey($Key)) {
    throw "JDK key '$Key' does not exist."
  }

  $removed = $jdks[$Key]
  [void]$jdks.Remove($Key)
  Save-Jdks -Table $jdks
  Write-Output "Removed JDK '$Key' (Id: $($removed.Id)) => '$($removed.Path)'"
}

<#
.Synopsis
Get local JDK mappings.

.Description
When -Key is provided, returns one mapping object: Id/Key/Path.
Without -Key, returns all mappings sorted by key.

.Parameter Key
Optional mapping key.

.Example
Get-JavaHome

.Example
Get-JavaHome -Key jdk21
#>
function Get-JavaHome {
  [CmdletBinding()]
  param(
    [string]$Key
  )

  $jdks = Read-Jdks
  if ($Key) {
    if (-not $jdks.ContainsKey($Key)) {
      throw "JDK key '$Key' does not exist."
    }
    return [pscustomobject]@{
      Id   = $jdks[$Key].Id
      Key  = $Key
      Path = $jdks[$Key].Path
    }
  }

  return $jdks.GetEnumerator() |
    Sort-Object Key |
    ForEach-Object {
      [pscustomobject]@{
        Id   = $_.Value.Id
        Key  = $_.Key
        Path = $_.Value.Path
      }
    }
}

<#
.Synopsis
Search JDK homes under a directory.

.Description
Recursively scans the given root path and returns directories that look like JDK homes.
Root directory itself will also be checked.

.Parameter Path
Root directory to search.

.Parameter Depth
Max recursion depth. Default is 3.

.Example
Search-JavaHome -Path "D:\SDKs" -Depth 4
#>
function Search-JavaHome {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$Path,
    [int]$Depth = 3
  )

  $roots = @((Resolve-Path -Path $Path -ErrorAction Stop).Path)
  $items = Get-ChildItem -Path $roots -Depth $Depth -Directory -ErrorAction SilentlyContinue
  $allDirs = @($roots) + ($items | Select-Object -ExpandProperty FullName)

  foreach ($dir in ($allDirs | Sort-Object -Unique)) {
    if (Test-IsJavaHome -Path $dir) {
      Write-Output $dir
    }
  }
}

<#
.Synopsis
Set JAVA_HOME and update PATH for current shell session.

.Description
Validates JavaHome path, then sets env:JAVA_HOME and prepends JavaHome\bin to env:PATH.
Old JAVA_HOME\bin and duplicated new bin entries are removed to avoid PATH pollution.

.Parameter JavaHome
Target JDK home path.
#>
function Set-CurrentJavaEnvironment {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$JavaHome
  )

  $javaHome = Resolve-JavaHomePath -Path $JavaHome
  $oldJavaHome = $env:JAVA_HOME
  $newBin = Join-Path $javaHome "bin"
  $oldBin = if ($oldJavaHome) { Join-Path $oldJavaHome "bin" } else { $null }

  $pathEntries = @()
  if ($env:PATH) {
    $pathEntries = $env:PATH -split ';' | Where-Object { $_ -and $_.Trim() }
  }

  # Remove old JAVA_HOME/bin and duplicated new bin entries.
  $filtered = $pathEntries | Where-Object {
    ($_ -ne $newBin) -and (-not $oldBin -or $_ -ne $oldBin)
  }

  $env:JAVA_HOME = $javaHome
  $env:PATH = ($newBin, $filtered) -join ';'

  Write-Output "Set JAVA_HOME = '$javaHome'"
}

<#
.Synopsis
Switch current PowerShell session to a target JDK.

.Description
Supports two ways:
- by registered key in local registry
- by direct JDK path
The command updates env:JAVA_HOME and env:PATH for current session only.

.Parameter Path
Direct JDK home path.

.Parameter Key
Alias key in local JDK registry.

.Example
Use-JavaHome -Path C:\xxx\java\jdk-21

.Example
Use-JavaHome -Key jdk21
#>
function Use-JavaHome {
  [CmdletBinding(DefaultParameterSetName = "ByKey")]
  param(
    [Parameter(ParameterSetName = "ByPath", Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [Parameter(ParameterSetName = "ByKey", Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Key
  )

  if ($PSCmdlet.ParameterSetName -eq "ByKey") {
    $record = Get-JavaHome -Key $Key
    Set-CurrentJavaEnvironment -JavaHome $record.Path
    return
  }

  Set-CurrentJavaEnvironment -JavaHome $Path
}

<#
.Synopsis
Clear all local JDK mappings.

.Description
Resets local csv registry file to empty state. Supports -WhatIf and -Confirm.

.Example
Clear-JavaHome -Confirm
#>
function Clear-JavaHome {
  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
  param()

  Initialize-JdkStore
  if ($PSCmdlet.ShouldProcess($script:JAVA_HOME_LIST_FILE, "Clear local JDK map")) {
    Remove-Item -Path $script:JAVA_HOME_LIST_FILE -Force -ErrorAction SilentlyContinue
    New-Item -ItemType File -Path $script:JAVA_HOME_LIST_FILE -Force | Out-Null
  }
}

Export-ModuleMember -Function Set-JavaHome
Export-ModuleMember -Function Remove-JavaHome
Export-ModuleMember -Function Get-JavaHome
Export-ModuleMember -Function Use-JavaHome
Export-ModuleMember -Function Search-JavaHome
Export-ModuleMember -Function Clear-JavaHome
