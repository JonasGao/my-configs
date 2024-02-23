$MY_CONFIG_HOME = $env:MY_CONFIG_HOME

if (!$MY_CONFIG_HOME)
{
  throw "There is no MY_CONFIG_HOME"
}

New-Item "$HOME\.aria2" -ItemType Directory -Force > $null
Copy-Item "$MY_CONFIG_HOME\aria\aria2.conf" "$HOME\.aria2\"
Write-Host "Success install Aria2 conf." -ForegroundColor Green
