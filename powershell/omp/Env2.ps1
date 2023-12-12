$MY_CONFIG_HOME = "$HOME\Github\jonas\my-configs"

$env:PATH = $env:PATH + ";$HOME\bin;$HOME\.local\bin"

$MAVEN_VER = "3.8.7"
$MAVEN_HOME = "D:\Maven\apache-maven-$MAVEN_VER\bin"
$env:PATH = $env:PATH + ";" + $MAVEN_HOME

$M2_CU = "$HOME/.m2/_codeup/settings.xml"
$M2_HS = "$HOME/.m2/_huashang/settings.xml"

$NVIM_HOME = "$env:NVIM_HOME"
$NVIM_CONF = "$env:LOCALAPPDATA\nvim"
$env:PATH = "$NVIM_HOME\bin;$env:PATH"

$PoshTheme = "blue-owl"
$PoshThemeConfig = "$($env:LOCALAPPDATA)\Programs\oh-my-posh\themes\$PoshTheme.omp.json"
$MyPoshThemeConfig = "$HOME\.my.$PoshTheme.omp.json"
$PoshConfig = $MyPoshThemeConfig
