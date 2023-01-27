param(
  [Switch]$CopyGitConfig,
  [Switch]$InstallDelta
) 

if ($CopyGitConfig)
{
  .scripts/Copy-GitConfig.ps1 
}

if ($InstallDelta)
{
  .scripts/Install-Delta.ps1
}
