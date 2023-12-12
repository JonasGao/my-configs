$MY_CONFIG_HOME = "$HOME\my-github\my-configs"
$MAVEN_VERSION = "3.9.4"
$MAVEN_HOME = "D:\Maven\apache-maven-$MAVEN_VERSION-bin\apache-maven-$MAVEN_VERSION\bin"
$M2_CU = "$HOME/.m2/_codeup/settings.xml"
$M2_HS = "$HOME/.m2/_huashang/settings.xml"
$NVIM_HOME = "$env:NVIM_HOME"
$NVIM_CONF = "$env:LOCALAPPDATA\nvim"
$PWSH_PROFILE_HOME = $env:PWSH_PROFILE_HOME

$env:PATH = "$HOME\bin;$HOME\.local\bin;" + $env:PATH
$env:PATH = "$MAVEN_HOME;" + $env:PATH
$env:PATH = "$NVIM_HOME\bin;$env:PATH"

$POSH_HOME = "C:\Users\udemo\scoop\apps\oh-my-posh\current\"
$PoshTheme = "amro"
$PoshThemeConfig = "$POSH_HOME\themes\$PoshTheme.omp.json"
$MyPoshThemeConfig = "$HOME\.my.$PoshTheme.omp.json"
$PoshConfig = $PoshThemeConfig

Import-Module "$MY_CONFIG_HOME\powershell\module\MyPsScripts"

function Update-Env
{
  if (-not (Test-Path -Path Env:\PWSH_PROFILE_HOME))
  {
    throw "Not found env:PWSH_PROFILE_HOME!"
  }
  . "$env:PWSH_PROFILE_HOME\Env.ps1"
}

function Format-Pom
{
  param (
    $Settings
  )
  $arr = @(
    "com.github.ekryd.sortpom:sortpom-maven-plugin:sort",
    "-Dsort.encoding=UTF-8",
    "-Dsort.keepBlankLines=false",
    "-Dsort.sortDependencies=optional,scope,groupId,artifactId",
    "-Dsort.sortPlugins=groupId,artifactId",
    "-Dsort.sortProperties=true",
    "-Dsort.sortExecutions=true",
    "-Dsort.sortDependencyExclusions=groupId,artifactId",
    "-Dsort.lineSeparator=`"\n`"",
    "-Dsort.ignoreLineSeparators=false",
    "-Dsort.expandEmptyElements=false",
    "-Dsort.nrOfIndentSpace=2",
    "-Dsort.indentSchemaLocation=true"
  )

  if ($Settings)
  {
    Write-Output "Using: $Settings"
    mvn -s $Settings $arr
  } else
  {
    mvn $arr
  }
}

function mvn_cu
{
  mvn -s $M2_CU $args
}

function Set-GoPathLocation
{
  Set-Location $env:GOPATH
}
