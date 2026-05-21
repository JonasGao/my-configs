---
name: jdk-switcher
description: >
  PowerShell JDK environment manager for switching JAVA_HOME and PATH across multiple JDK installations.
  Use when the user needs to: (1) Switch between JDK versions in a PowerShell session,
  (2) Register or manage local JDK aliases (key -> path mappings),
  (3) Scan disk for JDK installations and auto-register them,
  (4) Query or remove existing JDK mappings,
  (5) Persist JAVA_HOME selection across new terminal sessions via profile,
  (6) Troubleshoot JAVA_HOME/PATH issues related to multiple JDKs.
  Triggers: "switch jdk", "change java version", "set JAVA_HOME", "manage jdk", "jdk alias",
  "register jdk", "scan jdk", "java home", "multiple jdk" in PowerShell context.
---

# JDK Switcher Skill

`JdkSwitcher.psm1` is a PowerShell module that maintains a local registry of JDK paths and switches `JAVA_HOME` / `PATH` for the current session.

## Prerequisites

Import the module before use:

```powershell
Import-Module JdkSwitcher
```

If the module is not in `$env:PSModulePath`, use the full path:

```powershell
Import-Module "C:\path\to\JdkSwitcher.psm1"
```

## Command Reference

### `Set-JavaHome -Key <alias> -Path <jdkRoot>`

Register or update a JDK mapping. The path is validated (must contain `bin/java` or `bin/javac`).

```powershell
Set-JavaHome -Key jdk21 -Path "C:\Program Files\Java\jdk-21"
```

### `Get-JavaHome [-Key <alias>]`

Query registered mappings. Returns `Id/Key/Path` objects.

```powershell
Get-JavaHome          # list all
Get-JavaHome -Key jdk21   # single record
```

### `Remove-JavaHome -Key <alias>`

Remove a mapping by key. Does **not** uninstall the JDK.

```powershell
Remove-JavaHome -Key jdk8
```

### `Use-JavaHome -Key <alias>` or `Use-JavaHome -Path <jdkRoot>`

Switch the current PowerShell session to the target JDK. Sets `env:JAVA_HOME` and updates `env:PATH`.

```powershell
Use-JavaHome -Key jdk21
Use-JavaHome -Path "D:\SDK\jdk-17"
```

Behavior:
- Prepends `<JavaHome>\bin` to `env:PATH`
- Removes the old `JAVA_HOME\bin` entry to prevent PATH pollution

### `Search-JavaHome -Path <root> [-Depth <n>] [-Save]`

Recursively scan a directory for JDK homes.

```powershell
Search-JavaHome -Path "C:\Program Files\Java" -Depth 2
Search-JavaHome -Path "D:\SDKs" -Depth 4 -Save   # auto-register found JDKs
```

With `-Save`, discovered JDKs are added to the local registry with auto-generated keys (based on directory name; conflicts append an index like `jdk-21-2`).

### `Clear-JavaHome [-WhatIf] [-Confirm]`

Clear all local mappings. Supports `ShouldProcess`.

```powershell
Clear-JavaHome -Confirm
```

### `Convert-JavaHomeStore`

Manually trigger migration from legacy formats (`javahome.txt`, `javahome.properties`, `jdk.csv`) to the current CSV format. Normally not needed—migration is automatic on read.

```powershell
Convert-JavaHomeStore
```

## Data Storage

- Registry directory: `~/.jdks/`
- Data file: `~/.jdks/javahome.csv`
- Format (v2): `Id,Key,Path`
- `Id` is a stable hash derived from `java -version` output + path
- Legacy format migration is automatic and creates `.legacy.<timestamp>.bak` backups

## Common Workflows

### First-time setup

```powershell
Search-JavaHome -Path "C:\Program Files\Java" -Depth 2 -Save
Get-JavaHome
```

### Daily switching

```powershell
Get-JavaHome
Use-JavaHome -Key jdk17
java -version
```

### Persist default JDK for new sessions

Add to your PowerShell profile (`$PROFILE`):

```powershell
Import-Module JdkSwitcher
Use-JavaHome -Key jdk21
```

## Important Notes

- `Use-JavaHome` affects **only the current PowerShell session**.
- `Key` must not contain `:` or path separators.
- `Path` must point to the JDK **root** (not the `bin` directory).
- If `java -version` fails for a registered path, `Id` generation falls back to a placeholder string.
