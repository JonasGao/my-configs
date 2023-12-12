$PROFILE_HOME = (Get-Item $PROFILE).Directory
delta "$MY_CONFIG_HOME\powershell\omp\Microsoft.PowerShell_profile.ps1" $PROFILE
delta "$MY_CONFIG_HOME\powershell\omp\Env.ps1" "$PROFILE_HOME\Env.ps1"
