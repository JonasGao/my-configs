param(
  [string]$VSCode
)

if (!$VSCode) {
  Write-Output "Please specify a VSCode(dir)"
  exit(1)
}

Write-Output "Remove old [mark]"
Remove-Item mark -Force

# Write-Output "Copy [$VSCode] to [mark]"
# Copy-Item "$VSCode" -Destination "mark" -Recurse
Expand-Archive $VSCode -DestinationPath mark

Write-Output "Will link mark-data to [mark]"
New-Item -ItemType Junction -Path "mark\data" -Value "mark-data"
