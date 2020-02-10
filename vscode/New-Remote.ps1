param(
  [string]$VSCode
)

if (!$VSCode) {
  Write-Output "Please specify a VSCode(dir)"
  exit(1)
}

$newName = "remote"
$newDataName = "$newName-data"

Write-Output "Remove old [$newName]"
Remove-Item $newName -Force
Write-Output "Copy [$VSCode] to [$newName]"
Copy-Item "$VSCode" -Destination "$newName" -Recurse
Write-Output "Will link [$newDataName] to [$newName\data]"
New-Item -ItemType Junction -Path "$newName\data" -Value $newDataName
