CHCP 65001
New-Alias ll ls
Import-Module posh-gvm
Import-Module posh-git
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
try { $null = Get-Command pshazz -ea stop; pshazz init 'default' } catch { }
