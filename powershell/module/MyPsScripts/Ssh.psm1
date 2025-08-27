function New-SshProxy
{
  param($Name, $Port, $SshTarget)
  $FullName = "Start-${Name}Proxy"
  Set-Item -Path function:global:$FullName -Value {
    Write-Output "Startuping ssh @$Port"
    ssh -CND 127.0.0.1:$Port $SshTarget
    Write-Output "Finish"
  }.GetNewClosure()
}

<#
 .Synopsis
  Just like linux/unix "ssh-copyid xxxxx".
 
 .Description
  Copies SSH public key to remote host's authorized_keys file.
  Supports interactive selection when multiple keys are found.
 
 .Parameter Host
  Remote host in format "username@hostname" or "hostname".

 .Parameter IdentityFile
  Path to the public key file to copy. If not specified, will search for available keys.

 .Parameter WhatIf
  Shows what would happen if the command runs without actually executing it.

 .Parameter Confirm
  Prompts for confirmation before executing the command.

 .Parameter Force
  Overwrites existing key without confirmation.

 .Parameter Backup
  Creates backup of remote authorized_keys file before modification.

 .Example
  Copy-Sshid some_one@10.0.0.2

 .Example
  Copy-Sshid some_one@10.0.0.2 .ssh\id_rsa_other.pub

 .Example
  Copy-Sshid some_one@10.0.0.2 -WhatIf

 .Example
  Copy-Sshid some_one@10.0.0.2 -Force -Backup

 .Returns
  Returns $true if successful, throws exception on failure.
#>
function Copy-Sshid
{
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
  param(
    [parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[^@]+@[^@]+$|^[^@]+$')]
    [string] 
    $Host, 
    
    [parameter(Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    $IdentityFile = "",
    
    [switch]
    $Force,
    
    [switch]
    $Backup
  )
 
  # 内部函数：搜索可用的SSH公钥文件
  function Find-SshIdentity
  {
    [CmdletBinding()]
    param()
    
    $sshHome = "$env:USERPROFILE\.ssh" 
    
    # 验证SSH目录
    if (!(Test-Path $sshHome))
    {
      throw "SSH目录不存在: '$sshHome'。请先创建SSH目录。"
    }
    if (!(Test-Path $sshHome -PathType Container))
    {
      throw "'$sshHome' 不是一个目录。"
    }
    
    Write-Verbose "搜索SSH目录: $sshHome"
    
    # 查找所有公钥文件
    $publicKeys = @()
    Get-ChildItem $sshHome -Filter "id_*.pub" | ForEach-Object {
      if (Test-ValidSshPublicKey $_.FullName)
      {
        $publicKeys += $_
      }
    }
    
    if ($publicKeys.Count -eq 0)
    {
      throw "在 '$sshHome' 中未找到有效的SSH公钥文件。"
    }
    
    # 如果只有一个公钥，直接返回
    if ($publicKeys.Count -eq 1)
    {
      Write-Host "找到公钥文件: $($publicKeys[0].Name)" -ForegroundColor Green
      return $publicKeys[0].FullName
    }
    
    # 多个公钥时，让用户选择
    Write-Host "找到多个公钥文件:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $publicKeys.Count; $i++)
    {
      Write-Host "  [$i] $($publicKeys[$i].Name)" -ForegroundColor Cyan
    }
    
    do
    {
      $selection = Read-Host "请选择要使用的公钥文件 (0-$($publicKeys.Count-1))"
      if ($selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -lt $publicKeys.Count)
      {
        $selectedKey = $publicKeys[[int]$selection].FullName
        Write-Host "已选择: $($publicKeys[[int]$selection].Name)" -ForegroundColor Green
        return $selectedKey
      }
      Write-Host "无效选择，请重新输入。" -ForegroundColor Red
    } while ($true)
  }

  # 内部函数：验证SSH公钥文件格式
  function Test-ValidSshPublicKey
  {
    [CmdletBinding()]
    param([string]$KeyPath)
    
    try
    {
      $content = Get-Content $KeyPath -Raw -ErrorAction Stop
      if ([string]::IsNullOrWhiteSpace($content))
      {
        return $false
      }
      
      # 检查文件大小（SSH公钥通常小于1KB）
      $fileInfo = Get-Item $KeyPath
      if ($fileInfo.Length -gt 1024)
      {
        Write-Warning "公钥文件过大: $($fileInfo.Length) bytes"
        return $false
      }
      
      # 检查SSH公钥格式（ssh-rsa, ssh-ed25519, ecdsa-sha2-nistp256等）
      $lines = $content.Trim().Split("`n")
      foreach ($line in $lines)
      {
        if ($line.Trim() -match '^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-dss)\s+[A-Za-z0-9+/=]+(\s+.+)?$')
        {
          return $true
        }
      }
      
      Write-Warning "无效的SSH公钥格式: $KeyPath"
      return $false
    }
    catch
    {
      Write-Warning "无法读取公钥文件: $KeyPath - $($_.Exception.Message)"
      return $false
    }
  }

  # 内部函数：检查远程主机是否已存在该公钥
  function Test-RemoteKeyExists
  {
    [CmdletBinding()]
    param([string]$Host, [string]$PublicKeyContent)
    
    try
    {
      $keyFingerprint = ssh-keygen -lf $IdentityFile 2>$null | Select-String -Pattern 'SHA256:([A-Za-z0-9+/=]+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }
      
      if ($keyFingerprint)
      {
        $checkCmd = "grep -q '$keyFingerprint' ~/.ssh/authorized_keys 2>/dev/null || echo 'NOT_FOUND'"
        $result = ssh $Host $checkCmd 2>$null
        
        if ($result -and $result.Trim() -ne 'NOT_FOUND')
        {
          return $true
        }
      }
      
      return $false
    }
    catch
    {
      Write-Verbose "无法检查远程公钥存在性: $($_.Exception.Message)"
      return $false
    }
  }

  # 内部函数：备份远程authorized_keys文件
  function Backup-RemoteAuthorizedKeys
  {
    [CmdletBinding()]
    param([string]$Host)
    
    try
    {
      $backupCmd = @"
if [ -f ~/.ssh/authorized_keys ]; then
  cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup.$(date +%Y%m%d_%H%M%S)
  echo "BACKUP_CREATED"
else
  echo "NO_FILE"
fi
"@
      
      $result = ssh $Host $backupCmd 2>$null
      
      if ($result -and $result.Trim() -eq 'BACKUP_CREATED')
      {
        Write-Host "已创建远程authorized_keys备份" -ForegroundColor Green
        return $true
      }
      elseif ($result -and $result.Trim() -eq 'NO_FILE')
      {
        Write-Host "远程authorized_keys文件不存在，无需备份" -ForegroundColor Yellow
        return $true
      }
      else
      {
        Write-Warning "无法创建远程备份"
        return $false
      }
    }
    catch
    {
      Write-Warning "备份远程文件时出错: $($_.Exception.Message)"
      return $false
    }
  }

  # 主函数逻辑开始
  try
  {
    Write-Verbose "开始执行Copy-Sshid操作"
    
    # 处理IdentityFile参数
    if ([string]::IsNullOrWhiteSpace($IdentityFile))
    {
      Write-Verbose "未指定公钥文件，搜索可用公钥"
      $IdentityFile = Find-SshIdentity
    }
    elseif (!$IdentityFile.EndsWith(".pub"))
    {
      $IdentityFile = "$IdentityFile.pub"
    }
    
    # 验证公钥文件
    if (!(Test-Path -Path $IdentityFile -PathType Leaf))
    {
      throw "公钥文件不存在: '$IdentityFile'"
    }
    
    if (!(Test-ValidSshPublicKey $IdentityFile))
    {
      throw "无效的SSH公钥文件: '$IdentityFile'"
    }
    
    # 读取公钥内容
    $publicKeyContent = Get-Content $IdentityFile -Raw -ErrorAction Stop
    
    # 检查远程主机是否已存在该公钥
    $keyExists = Test-RemoteKeyExists $Host $publicKeyContent
    if ($keyExists -and !$Force)
    {
      $confirmation = Read-Host "该公钥已存在于远程主机，是否继续添加？(y/N)"
      if ($confirmation -notmatch '^[Yy]')
      {
        Write-Host "操作已取消" -ForegroundColor Yellow
        return $false
      }
    }
    
    # 显示操作信息
    $operationDescription = "复制公钥文件 '$IdentityFile' 到主机 '$Host'"
    if ($Backup)
    {
      $operationDescription += " (包含备份)"
    }
    
    if ($WhatIfPreference)
    {
      Write-Host "WhatIf: $operationDescription" -ForegroundColor Cyan
      return $true
    }
    
    if (!$Force -and !$PSCmdlet.ShouldProcess($Host, $operationDescription))
    {
      Write-Host "操作已取消" -ForegroundColor Yellow
      return $false
    }
    
    Write-Host "正在复制公钥到 '$Host'..." -ForegroundColor Green
    
    # 备份远程文件（如果指定）
    if ($Backup)
    {
      Backup-RemoteAuthorizedKeys $Host
    }
    
    # 执行复制操作
    $cmds = @(
      "[ -d .ssh ] || mkdir -p .ssh && chmod 700 .ssh",
      "[ -f .ssh/authorized_keys ] || touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys",
      "cat >> .ssh/authorized_keys"
    )
    
    $sshResult = $publicKeyContent | ssh $Host ($cmds -join "; ") 2>&1
    
    if ($LASTEXITCODE -eq 0)
    {
      Write-Host "公钥复制成功！" -ForegroundColor Green
      Write-Host "现在可以使用SSH密钥登录到 '$Host'" -ForegroundColor Cyan
      return $true
    }
    else
    {
      throw "SSH操作失败，退出代码: $LASTEXITCODE`n错误信息: $sshResult"
    }
  }
  catch
  {
    Write-Error "Copy-Sshid操作失败: $($_.Exception.Message)"
    throw
  }
}

Export-ModuleMember -Function New-SshProxy
Export-ModuleMember -Function Copy-Sshid
