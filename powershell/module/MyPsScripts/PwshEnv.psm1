function Update-EnvFile
{
  if ((Test-Path Env:\MY_CONFIG_HOME) -and (Test-Path Env:\PROFILE_HOME))
  {
    Copy-Item -Force -Confirm "$env:MY_CONFIG_HOME\powershell\omp\Env.ps1" "$env:PROFILE_HOME\Env.ps1"
    Write-Host -ForegroundColor Green "Updated Env.ps1 file."
  } else
  {
    Write-Host -ForegroundColor Red "Failed update. Missing Variables."
  }
}

function Backup-EnvFile
{
  if ((Test-Path Env:\MY_CONFIG_HOME) -and (Test-Path Env:\PROFILE_HOME))
  {
    Copy-Item -Force "$env:PROFILE_HOME\Env.ps1" "$env:MY_CONFIG_HOME\powershell\omp\Env.ps1"
    Write-Host -ForegroundColor Green "Backup Env.ps1 file."
    Push-Location $env:MY_CONFIG_HOME
    git diff
    git add .
    git commit
    git push
    Pop-Location
  } else
  {
    Write-Host -ForegroundColor Red "Failed update. Missing Variables."
  }
}

function Compare-Profile
{
  if ((Test-Path Env:\MY_CONFIG_HOME))
  {
    $TARGET_DIR = "$env:MY_CONFIG_HOME\powershell\omp"
    $NAME = (Get-Item $PROFILE).Name
    delta "$PROFILE" "$TARGET_DIR\${NAME}"
  } else
  {
    Write-Host -ForegroundColor Red "Missing Env:MY_CONFIG_HOME."
  }
}

function Save-Profile
{
  if ((Test-Path Env:\MY_CONFIG_HOME))
  {
    $TARGET_DIR = "$env:MY_CONFIG_HOME\powershell\omp"
    Copy-Item -Force "$PROFILE" "$TARGET_DIR\"
    Write-Host -ForegroundColor Green "Copied $PROFILE"
    Push-Location $TARGET_DIR
    git add .
    git commit -m "Save pwsh profile."
    git push
    Pop-Location
  } else
  {
    Write-Host -ForegroundColor Red "Failed Save. Missing Env:MY_CONFIG_HOME."
  }
}

Export-ModuleMember -Function Update-EnvFile
Export-ModuleMember -Function Backup-EnvFile
Export-ModuleMember -Function Save-Profile
Export-ModuleMember -Function Compare-Profile
