# Dependency scoop
if (-not(Get-Command scoop -ErrorAction SilentlyContinue))
{
  throw "There is not found 'scoop'. Please install 'scoop'."
}

# Dependency 7zip
if (-not(Get-Command 7z -ErrorAction SilentlyContinue))
{
  scoop install 7zip
}

# Subconverter constants
SubVer = "0.8.1"
SubRelUrl = "https://github.com/tindy2013/subconverter/releases/download/v${SubVer}/subconverter_win64.7z"
SubRelFile = "subconverter_win64.7z"
SubInstallPath = "subconverter"
SubExeName = "subconverter.exe"

# Clash constants
ClaVer = ""


# Install subconverter
if (Test-Path $SubInstallPath)
{
  if (Test-Path $SubInstallPath -PathType Leaf)
  {
    throw "'subconverter' exists and it is not a directory."
  }
  if (Test-Path $SubInstallPath -PathType Container)
  {
    # Subconverter dir exists
    if (-not(Test-Path "$SubInstallPath/$SubExeName" -PathType Leaf))
    {
      # But subconverter exe not exists
      # Download Subconverter
      Invoke-RestMethod $SubRelUrl -OutFile $SubRelFile
      Write-Host "Successful downloaded $SubRelFile" -ForegroundColor Green

      # Un7zip subconverter
      Set-Alias Start-SevenZip "7z"
      Start-SevenZip x $SubRelFile "-o$InstallTarget"
      if (-not($?))
      {
        throw "Expand $SubRelFile failed."
      }
    } else
    {
      Write-Host "'subconverter' already installed."
    }
  }
}

# Clash installation
