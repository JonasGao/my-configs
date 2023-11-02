scoop install delta
Copy-Item "$MY_CONFIG_HOME\git\.gitconfig" "$HOME\.gitconfig" -Force
Write-Output "Installed .gitconfig."
