param(
  $OutFile = "config.yaml"
)
$ProgressPreference = 'SilentlyContinue'
$SubConvHome = "$env:LOCALAPPDATA\subconverter\subconverter"
$SubConvPath = "$SubConvHome\subconverter.exe"
$ClashConfHome = "$HOME\.config\clash"
$RealOutFile = "$ClashConfHome\$OutFile"
$Processes = Get-Process -Name "subconverter" -ErrorAction SilentlyContinue
if ($? -and $Processes)
{
  Write-Output "Subconverter running"
  Write-Output $Processes
} else
{
  Start-Process $SubConvPath -Working $SubConvHome
  if (-not($?))
  {
    Exit 1
  }
}
Write-Output "Will save to $RealOutFile"
Invoke-RestMethod "http://127.0.0.1:25500/getprofile?name=profiles/j.ini&token=password&config=config/ACL4SSR_Online_Full.ini" -OutFile $RealOutFile
if ($?)
{
  Get-Process -Name "subconverter" | ForEach-Object {
    Stop-Process $_
  }
}
