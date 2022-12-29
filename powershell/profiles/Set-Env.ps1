$MY_CONFIG_HOME = "$HOME\my-github\my-configs"

$CUM2 = "$HOME/.m2/_codeup/settings.xml"
$HSM2 = "$HOME/.m2/_huashang/settings.xml"

$MAVEN_HOME = "D:\Maven\apache-maven-3.8.6-bin\apache-maven-3.8.6\bin"
$env:PATH = $env:PATH + ";" + $MAVEN_HOME

$env:PATH = $env:PATH + ";$HOME\bin;$HOME\.local\bin"

$NVIM_HOME = "$HOME\Apps\nvim-win64\Neovim"
$env:PATH = "$NVIM_HOME\bin;$env:PATH"

$PoshTheme = "blue-owl"
$PoshThemeConfig = "$($env:LOCALAPPDATA)\Programs\oh-my-posh\themes\$PoshTheme.omp.json"
$MyPoshThemeConfig = "$HOME\.my.$PoshTheme.omp.json"
$PoshConfig = $MyPoshThemeConfig

function sortpom {
  param (
    $Settings
  )
  if ($Settings) {
    Write-Output "Using: $Settings"
    mvn -s $Settings com.github.ekryd.sortpom:sortpom-maven-plugin:sort "-Dsort.encoding=UTF-8" "-Dsort.keepBlankLines=false" "-Dsort.sortDependencies=optional,scope,groupId,artifactId" "-Dsort.sortPlugins=groupId,artifactId" "-Dsort.sortProperties=true" "-Dsort.sortExecutions=true" "-Dsort.sortDependencyExclusions=groupId,artifactId" "-Dsort.lineSeparator=`"\n`"" "-Dsort.ignoreLineSeparators=false" "-Dsort.expandEmptyElements=false" "-Dsort.nrOfIndentSpace=2" "-Dsort.indentSchemaLocation=true"
  } else {
    mvn com.github.ekryd.sortpom:sortpom-maven-plugin:sort "-Dsort.encoding=UTF-8" "-Dsort.keepBlankLines=false" "-Dsort.sortDependencies=optional,scope,groupId,artifactId" "-Dsort.sortPlugins=groupId,artifactId" "-Dsort.sortProperties=true" "-Dsort.sortExecutions=true" "-Dsort.sortDependencyExclusions=groupId,artifactId" "-Dsort.lineSeparator=`"\n`"" "-Dsort.ignoreLineSeparators=false" "-Dsort.expandEmptyElements=false" "-Dsort.nrOfIndentSpace=2" "-Dsort.indentSchemaLocation=true"
  }
}

function cumv {
  mvn -s $CUM2 $args
}
