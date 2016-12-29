# 以下内容仅供参考
# http://stackoverflow.com/questions/714877/setting-windows-powershell-path-variable

### Modify system environment variable ###
[Environment]::SetEnvironmentVariable( "Path", $env:Path, [System.EnvironmentVariableTarget]::Machine )

### Modify user environment variable ###
[Environment]::SetEnvironmentVariable( "INCLUDE", $env:INCLUDE, [System.EnvironmentVariableTarget]::User )

### from comments ###
### Usage from comments - Add to the system environment variable ###
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\bin", [EnvironmentVariableTarget]::Machine)
