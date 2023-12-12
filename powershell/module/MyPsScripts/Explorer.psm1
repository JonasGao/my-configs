function Copy-ItemUsingExplorer
{
  param(
    [string]$Source,
    [string]$Destination,
    [int]$CopyFlags = 0
  )

  if (!$Source)
  {
    Write-Output "There is no source"
    return 1
  }

  if (!$Destination)
  {
    Write-Output "There is no destination"
    return 2
  }

  $objShell = New-Object -ComObject 'Shell.Application'    
  $objFolder = $objShell.NameSpace((Get-Item $Destination).FullName)
  $objFolder.CopyHere((Get-Item $Source).FullName, $CopyFlags.ToString('{0:x}'))
}

function Move-ItemUsingExplorer
{
  param(
    [string]$Source,
    [string]$Destination,
    [int]$MoveFlags = 0
  )

  if (!$Source)
  {
    Write-Output "There is no source"
    return 1
  }

  if (!$Destination)
  {
    Write-Output "There is no destination"
    return 2
  }

  $objShell = New-Object -ComObject 'Shell.Application'    
  $objFolder = $objShell.NameSpace((Get-Item $Destination).FullName)
  $objFolder.MoveHere((Get-Item $Source).FullName, $MoveFlags.ToString('{0:x}'))
}

Export-ModuleMember -Function Copy-ItemUsingExplorer
Export-ModuleMember -Function Move-ItemUsingExplorer
