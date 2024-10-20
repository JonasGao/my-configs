if (Get-Command scoop -errorAction SilentlyContinue)
{
    scoop install delta
} else {
    Write-Output "Not found scoop, skip install delta."
}
if (Copy-Item "$env:MY_CONFIG_HOME\git\config" "$HOME\.gitconfig" -Force)
{
    Write-Output "Installed .gitconfig."
}
