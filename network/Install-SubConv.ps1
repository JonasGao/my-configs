param(
  [Switch]$Update,
  $Proxy
)
$ProgressPreference = 'SilentlyContinue'
$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
$InstallTarget = "$env:LOCALAPPDATA\subconverter"
$DownloadUri = "https://github.com/tindy2013/subconverter/releases/download/v0.7.2/subconverter_win64.7z"
$DownloadFile = "$InstallTarget\app.7z"
if (-not(Test-Path -Path $7zipPath -PathType Leaf))
{
  throw "Please provide 7z"
}
if (-not(Test-Path -Path $InstallTarget -PathType Container))
{
  New-Item $InstallTarget -ItemType "directory" > $null
}
if (-not(Test-Path -Path $DownloadFile -PathType Leaf) -or $Update)
{
  try
  {
    Write-Host "Downloading app.7z"
    Invoke-RestMethod -Uri $DownloadUri -Proxy $Proxy -OutFile $DownloadFile
    Write-Host "Success download app.7z" -ForegroundColor Green
  } catch
  {
    Write-Host "Download app failed: $_" -ForegroundColor Red
    Exit 1
  }
}
Write-Output "Expanding app.7z"
Set-Alias Start-SevenZip $7zipPath
Start-SevenZip x "$InstallTarget\app.7z" "-o$InstallTarget"
if (-not($?))
{
  Write-Host "Expand failed" -ForegroundColor Red
}
