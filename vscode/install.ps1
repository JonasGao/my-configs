param (
  [String] $Target,
  [String] $Proxy
)

if ($Proxy) {
  Invoke-RestMethod https://update.code.visualstudio.com/latest/win32-x64-archive/stable -OutFile vscode.zip -Proxy $Proxy
} else {
  Invoke-RestMethod https://update.code.visualstudio.com/latest/win32-x64-archive/stable -OutFile vscode.zip
}
Expand-Archive ./vscode.zip -DestinationPath $Target
Remove-Item vscode.zip
New-Item -Path $Target/data -ItemType "directory"