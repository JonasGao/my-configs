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
    "-Dsort.ignoreLineSeparators=false",
    "-Dsort.expandEmptyElements=false",
    "-Dsort.nrOfIndentSpace=2",
    "-Dsort.createBackupFile=false",
    "-Dsort.indentSchemaLocation=true"
  )

  if ($Settings)
  {
    Write-Output "Using: $Settings"
    mvn -s $Settings $arr $args
  } else
  {
    mvn $arr $args
  }
}

Export-ModuleMember -Function Format-Pom
