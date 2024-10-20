$MY_CONFIG_HOME = $env:MY_CONFIG_HOME

if (-not (Test-Path env:MY_CONFIG_HOME)) {
    $profilePath = Join-Path -Path (Get-Location) -ChildPath "Microsoft.PowerShell_profile.ps1"
    if (Test-Path $profilePath) {
        $MY_CONFIG_HOME = (Get-Location).Path
        Write-Host "MY_CONFIG_HOME 设置为当前目录：$((Get-Location).Path)"
    } else {
        Write-Error "错误：当前目录下不存在 Microsoft.PowerShell_profile.ps1 文件，并且环境变量 MY_CONFIG_HOME 未设置。"
    }
} else {
    Write-Host "环境变量 MY_CONFIG_HOME 已存在，其值为：$env:MY_CONFIG_HOME"
}

Install-Module -Name posh-git -Scope CurrentUser
Install-Module -Name PSFzf -Scope CurrentUser -RequiredVersion 2.5.22
Write-Host "Success install Modules." -ForegroundColor Green

if (-not (Get-Command scoop))
{
  Write-Host "Not found command scoop. Will install scoop."
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  Invoke-RestMethod get.scoop.sh | Invoke-Expression
  Write-Host "Success install scoop." -ForegroundColor Green
}

scoop install delta
scoop install eza
scoop install oh-my-posh
scoop install aria2
scoop install ripgrep
scoop install fzf
scoop install fd
scoop install zoxide
Write-Host "Success install components from scroop." -ForegroundColor Green

$PROFILE_HOME = (Get-Item $PROFILE).Directory
Copy-Item "$MY_CONFIG_HOME\powershell\omp\Microsoft.PowerShell_profile.ps1" $PROFILE
if (Test-Path "$PROFILE_HOME\Env.ps1")
{
  Write-Host "Skip init Env.ps1, already exists."
} else
{
  Copy-Item "$MY_CONFIG_HOME\powershell\omp\Env.ps1" 
}
Write-Host "Success install Profiles." -ForegroundColor Green
