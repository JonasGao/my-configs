function Update-EnvFile
{
  if ((Test-Path Variable:\MY_CONFIG_HOME) -and (Test-Path Variable:\PWSH_PROFILE_HOME))
  {
    Copy-Item -Force -Confirm "$MY_CONFIG_HOME\powershell\omp\Env.ps1" "$PWSH_PROFILE_HOME\Env.ps1"
    Write-Host -ForegroundColor Green "Updated Env.ps1 file."
  } else
  {
    Write-Host -ForegroundColor Red "Failed update. Missing Variables."
  }
}

function Backup-EnvFile
{
  if ((Test-Path Variable:\MY_CONFIG_HOME) -and (Test-Path Variable:\PWSH_PROFILE_HOME))
  {
    Copy-Item -Force "$PWSH_PROFILE_HOME\Env.ps1" "$MY_CONFIG_HOME\powershell\omp\Env.ps1"
    Write-Host -ForegroundColor Green "Backup Env.ps1 file."
    Push-Location $MY_CONFIG_HOME
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

Export-ModuleMember -Function Update-EnvFile
Export-ModuleMember -Function Backup-EnvFile
