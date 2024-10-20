if (Get-Command scoop -errorAction SilentlyContinue)
{
    scoop install delta
} else {
    Write-Output "Not found scoop, skip install delta."
}
Copy-Item "$MY_CONFIG_HOME\git\.gitconfig" "$HOME\.gitconfig" -Force
Write-Output "Installed .gitconfig."
