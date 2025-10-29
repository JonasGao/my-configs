$env:MY_CONFIG_HOME = "$HOME\my-configs"

# Java
$env:JAVA_TOOL_OPTIONS = "-Dfile.encoding=utf-8"

# Maven
$env:MAVEN_VER = "3.8.7"
$env:MAVEN_HOME = "D:\Maven\apache-maven-$MAVEN_VER\bin"
$env:M2_CU = "$HOME/.m2/_codeup/settings.xml"
$env:M2_HS = "$HOME/.m2/_huashang/settings.xml"

# Oh My Posh
$PoshTheme = "amro"
$PoshThemeConfig = "$env:POSH_THEMES_PATH\$PoshTheme.omp.json"
$MyPoshThemeConfig = "$HOME\.my.$PoshTheme.omp.json"
$env:POSH_CONFIG = $PoshThemeConfig

# # kubectl and k Autocompletion
# kubectl completion powershell | Out-String | Invoke-Expression
# Register-ArgumentCompleter -CommandName k -ScriptBlock $__kubectlCompleterBlock
