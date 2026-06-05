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

# 内部函数：生成远程执行脚本
function New-RemoteCopyScript {
  [CmdletBinding()]
  param(
    [string]$PublicKeyContent,
    [switch]$Backup,
    [string]$BackupTimestamp
  )
  
  # 转义公钥内容中的特殊字符
  $escapedKey = $PublicKeyContent -replace "'", "'\\''" -replace "`n", "\\n"
  
  # 构建bash脚本
  $script = @"
set -e

# 接收公钥内容作为环境变量
KEY_CONTENT='$escapedKey'

# 1. 计算指纹并检查是否已存在
KEY_FP=\$(echo "\$KEY_CONTENT" | ssh-keygen -lf - 2>/dev/null | grep -o 'SHA256:[A-Za-z0-9+/=]+' || true)

if [ -n "\$KEY_FP" ]; then
  # Iterate through each existing key and compare fingerprints
  while IFS= read -r line; do
    [ -z "\$line" ] && continue
    existing_fp=\$(echo "\$line" | ssh-keygen -lf - 2>/dev/null | grep -o 'SHA256:[A-Za-z0-9+/=]+' || true)
    if [ "\$existing_fp" = "\$KEY_FP" ]; then
      echo "ALREADY_EXISTS"
      exit 0
    fi
  done < ~/.ssh/authorized_keys
fi

# 2. 备份（如果指定）
if [ '$Backup' = 'True' ]; then
  if [ -f ~/.ssh/authorized_keys ]; then
    BACKUP_FILE=~/.ssh/authorized_keys.backup.$BackupTimestamp
    cp ~/.ssh/authorized_keys "\$BACKUP_FILE" 2>/dev/null || true
    echo "BACKUP_CREATED:\$BACKUP_FILE"
  fi
fi

# 3. 确保目录和权限正确
[ -d ~/.ssh ] || mkdir -p ~/.ssh
chmod 700 ~/.ssh 2>/dev/null || true
[ -f ~/.ssh/authorized_keys ] || touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys 2>/dev/null || true

# 4. 添加公钥
echo "\$KEY_CONTENT" >> ~/.ssh/authorized_keys

# 5. 验证添加成功
if grep -qF "\$KEY_CONTENT" ~/.ssh/authorized_keys; then
  echo "SUCCESS"
else
  echo "ERROR:Failed to verify key addition"
  exit 1
fi
"@
  
  return $script
}

# 内部函数：测试SSH连接
function Test-SshConnection
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Target,
    
    [ValidateRange(1, 300)]
    [int]$Timeout = 10
  )
  
  try
  {
    $result = ssh -o ConnectTimeout=$Timeout -o BatchMode=yes $Target "echo CONNECTION_OK" 2>&1
    if ($result -match 'CONNECTION_OK')
    {
      return [pscustomobject]@{
        Success = $true
        Message = "Connection established"
      }
    }
    else
    {
      $errorMsg = $result | Out-String
      return [pscustomobject]@{
        Success = $false
        Message = $errorMsg.Trim()
      }
    }
  }
  catch
  {
    return [pscustomobject]@{
      Success = $false
      Message = $_.Exception.Message
    }
  }
}

# 内部函数：查找可用端口
function Find-AvailablePort
{
  [CmdletBinding()]
  param(
    [ValidateRange(1, 65534)]
    [int]$StartPort = 1080
  )
  
  for ($port = $StartPort; $port -lt 65535; $port++)
  {
    $listener = $null
    try
    {
      $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
      $listener.Start()
      return $port
    }
    finally
    {
      if ($listener -ne $null) {
        $listener.Stop()
      }
    }
  }
  
  throw "未找到可用端口"
}

# 内部函数：处理单个主机的SSH密钥复制
function Process-SingleHost {
  param($Target, $PublicKeyContent, $Backup, $Force, $UseControlMaster, $ControlPersistSeconds, $ConnectionTimeout, $RetryCount, $RetryDelaySeconds)
  
  $startTime = Get-Date
  $result = [pscustomobject]@{
    Host = $Target
    Success = $false
    Message = ""
    Duration = [timespan]::Zero
    BackupCreated = $false
    KeyAlreadyExists = $false
    ControlMasterUsed = $false
    Timestamp = Get-Date
  }
  
  try {
    # 生成远程脚本
    $backupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $remoteScript = New-RemoteCopyScript -PublicKeyContent $PublicKeyContent -Backup:$Backup -BackupTimestamp $backupTimestamp
    
    # 配置SSH选项
    $sshArgs = @()
    if ($UseControlMaster) {
      $tempDir = if ($IsWindows) { $env:TEMP } else { "/tmp" }
      $controlPath = Join-Path $tempDir "ssh-control-%r@%h:%p"
      $sshArgs += @("-o", "ControlMaster=auto", "-o", "ControlPath=$controlPath", "-o", "ControlPersist=$ControlPersistSeconds")
      $result.ControlMasterUsed = $true
    }
    if ($ConnectionTimeout -gt 0) {
      $sshArgs += @("-o", "ConnectTimeout=$ConnectionTimeout")
    }
    
    # 执行远程脚本（带重试）
    # 修复: 使用 $retry -lt $RetryCount + 1 确保正确次数（初始尝试 + N次重试 = N+1次总尝试）
    $sshOutput = $null
    for ($retry = 0; $retry -lt $RetryCount + 1; $retry++) {
      try {
        $sshOutput = ssh $sshArgs $Target "bash -c '$remoteScript'" 2>&1
        if ($LASTEXITCODE -eq 0) { break }
        if ($retry -lt $RetryCount) {  # 只在还有重试次数时显示消息并等待
          Write-Verbose "[$Target] 尝试 $($retry + 1)/$($RetryCount + 1) 失败，等待 $RetryDelaySeconds 秒后重试"
          Start-Sleep -Seconds $RetryDelaySeconds
        }
      }
      catch {
        if ($retry -lt $RetryCount) {
          Write-Verbose "[$Target] 连接异常，重试中..."
          Start-Sleep -Seconds $RetryDelaySeconds
        }
      }
    }
    
    # 解析返回状态
    if ($sshOutput -match 'SUCCESS') {
      $result.Success = $true
      $result.Message = "Key copied successfully"
      Write-Host "[$Target] 公钥复制成功！" -ForegroundColor Green
    }
    elseif ($sshOutput -match 'ALREADY_EXISTS') {
      $result.KeyAlreadyExists = $true
      if (-not $Force) {
        $result.Success = $true
        $result.Message = "Key already exists (skipped)"
        Write-Host "[$Target] 公钥已存在，已跳过" -ForegroundColor Yellow
      }
      else {
        # Force模式下，强制添加（脚本已继续执行）
        $result.Success = $true
        $result.Message = "Key added (forced overwrite)"
        Write-Host "[$Target] 公钥已强制添加" -ForegroundColor Yellow
      }
    }
    elseif ($sshOutput -match 'BACKUP_CREATED:([^\s]+)') {
      $result.BackupCreated = $true
      $backupFile = $Matches[1]
      Write-Verbose "[$Target] 已创建备份: $backupFile"
      # 继续检查后续状态
      if ($sshOutput -match 'SUCCESS') {
        $result.Success = $true
        $result.Message = "Key copied with backup"
      }
    }
    elseif ($sshOutput -match 'ERROR:(.+)' -or $LASTEXITCODE -ne 0) {
      $errorMsg = if ($sshOutput -match 'ERROR:(.+)') { $Matches[1] } else { "SSH failed with exit code $LASTEXITCODE" }
      
      # 错误诊断
      if ($sshOutput -match 'Connection refused') {
        $errorMsg += " (SSH service not running or firewall blocking)"
      }
      elseif ($sshOutput -match 'Permission denied') {
        $errorMsg += " (Invalid username or no SSH access)"
      }
      elseif ($sshOutput -match 'No space left') {
        $errorMsg += " (Remote disk full)"
      }
      elseif ($sshOutput -match 'Network is unreachable') {
        $errorMsg += " (Network connectivity issue)"
      }
      
      $result.Message = $errorMsg
      Write-Error "[$Target] 失败: $errorMsg"
    }
    
    # 计算执行时长
    $endTime = Get-Date
    $result.Duration = $endTime - $startTime
  }
  catch {
    $result.Message = $_.Exception.Message
    Write-Error "[$Target] 异常: $($_.Exception.Message)"
  }
  
  return $result
}

<#
 .Synopsis
  Just like linux/unix "ssh-copyid xxxx".
 
 .Description
  Copies SSH public key to remote host's authorized_keys file.
  Supports interactive selection when multiple keys are found.
 
 .Parameter RemoteHosts
  One or more remote hosts in format "username@hostname" or "hostname".

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

 .Example
  Copy-Sshid user@host1,user@host2 -ContinueOnError

 .Returns
  Returns $true if successful, throws exception on failure.
#>
function Copy-Sshid
{
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
  param(
    [parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[^@]+@[^@]+$|^[^@]+$')]
    [string[]] 
    $RemoteHosts, 
    
    [parameter(Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    $IdentityFile = "",
    
    [switch]
    $Force,
    
    [switch]
    $Backup,

    [switch]
    $ContinueOnError,

    [switch]
    $Parallel,
    
    [ValidateSet("Auto","Jobs","Runspaces","PS7Parallel")]
    [string]
    $ParallelMode = "Auto",
    
    [switch]
    $UseControlMaster,
    
    [int]
    $ControlPersistSeconds = 60,
    
    [int]
    $ConnectionTimeout = 30,
    
    [int]
    $RetryCount = 0,
    
    [int]
    $RetryDelaySeconds = 5
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
    
    # 预处理目标主机列表
    $targets = @()
    foreach ($h in $RemoteHosts) { if ($h -and $h.Trim()) { $targets += $h.Trim() } }
    $targets = $targets | Select-Object -Unique
    if ($targets.Count -eq 0) { throw "未提供有效的目标主机" }

    $results = @()
    
    # WhatIf 模式：显示将要执行的操作但不实际执行
    if ($WhatIfPreference) {
      foreach ($target in $targets) {
        Write-Host "What if: Would copy SSH key to '$target'" -ForegroundColor Cyan
      }
      return @($targets | ForEach-Object { 
        [pscustomobject]@{ 
          Host=$_; 
          Success=$true; 
          Message='WhatIf - operation not executed'; 
          Duration=[timespan]::Zero;
          BackupCreated=$false;
          KeyAlreadyExists=$false;
          ControlMasterUsed=$false;
          Timestamp=Get-Date
        }
      })
    }
    
    # 根据Parallel参数选择执行模式
    if ($Parallel) {
      Write-Verbose "使用并行模式: $ParallelMode"
      
      # 确定实际并行模式
      $actualMode = $ParallelMode
      if ($ParallelMode -eq "Auto") {
        $actualMode = if ($PSVersionTable.PSVersion.Major -ge 7) { "PS7Parallel" } else { "Jobs" }
      }
      
      switch ($actualMode) {
        "PS7Parallel" {
          # PowerShell 7+ ForEach-Object -Parallel
          # 注意：Process-SingleHost 现在是模块级函数，可以在 parallel scope 中访问
          $results = $targets | ForEach-Object -Parallel {
            # 导入模块级函数定义
            $module = Get-Module MyPsScripts
            if ($module) {
              & $module { Process-SingleHost -Target $args[0] -PublicKeyContent $args[1] -Backup:$args[2] -Force:$args[3] -UseControlMaster:$args[4] -ControlPersistSeconds $args[5] -ConnectionTimeout $args[6] -RetryCount $args[7] -RetryDelaySeconds $args[8] } $_ $using:publicKeyContent $using:Backup $using:Force $using:UseControlMaster $using:ControlPersistSeconds $using:ConnectionTimeout $using:RetryCount $using:RetryDelaySeconds
            }
          } -ThrottleLimit 10
        }
        
        "Jobs" {
          # PowerShell Jobs
          # 必须传递函数定义到 Job 中，因为 Job 运行在独立进程中
          $processSingleHostDef = ${function:Process-SingleHost}.ToString()
          $newRemoteCopyScriptDef = ${function:New-RemoteCopyScript}.ToString()
          
          $jobs = @()
          foreach ($target in $targets) {
            $job = Start-Job -ScriptBlock {
              param($t, $pk, $b, $f, $cm, $cps, $ct, $rc, $rd, $processDef, $remoteCopyDef)
              # 在 Job 中定义函数
              Set-Item -Path function:New-RemoteCopyScript -Value $remoteCopyDef
              Set-Item -Path function:Process-SingleHost -Value $processDef
              Process-SingleHost -Target $t -PublicKeyContent $pk -Backup:$b -Force:$f -UseControlMaster:$cm -ControlPersistSeconds $cps -ConnectionTimeout $ct -RetryCount $rc -RetryDelaySeconds $rd
            } -ArgumentList $target, $publicKeyContent, $Backup, $Force, $UseControlMaster, $ControlPersistSeconds, $ConnectionTimeout, $RetryCount, $RetryDelaySeconds, $processSingleHostDef, $newRemoteCopyScriptDef
            $jobs += $job
          }
          
          # 等待所有Job完成
          Wait-Job -Job $jobs | Out-Null
          $results = $jobs | Receive-Job
          $jobs | Remove-Job
        }
        
        "Runspaces" {
          # Runspaces (更轻量)
          # 必须将函数定义注入到 Runspace 中
          $processSingleHostDef = ${function:Process-SingleHost}.ToString()
          $newRemoteCopyScriptDef = ${function:New-RemoteCopyScript}.ToString()
          
          $runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
          $runspacePool.Open()
          
          $runspaces = @()
          foreach ($target in $targets) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool
            $powershell.AddScript({
              param($t, $pk, $b, $f, $cm, $cps, $ct, $rc, $rd, $processDef, $remoteCopyDef)
              # 在 Runspace 中定义函数
              Set-Item -Path function:New-RemoteCopyScript -Value $remoteCopyDef
              Set-Item -Path function:Process-SingleHost -Value $processDef
              Process-SingleHost -Target $t -PublicKeyContent $pk -Backup:$b -Force:$f -UseControlMaster:$cm -ControlPersistSeconds $cps -ConnectionTimeout $ct -RetryCount $rc -RetryDelaySeconds $rd
            }).AddArgument($target).AddArgument($publicKeyContent).AddArgument($Backup).AddArgument($Force).AddArgument($UseControlMaster).AddArgument($ControlPersistSeconds).AddArgument($ConnectionTimeout).AddArgument($RetryCount).AddArgument($RetryDelaySeconds).AddArgument($processSingleHostDef).AddArgument($newRemoteCopyScriptDef)
            
            $runspace = [powershell]::BeginInvoke($powershell)
            $runspaces += [pscustomobject]@{ PowerShell = $powershell; Runspace = $runspace }
          }
          
          # 收集结果
          foreach ($rs in $runspaces) {
            $result = $rs.PowerShell.EndInvoke($rs.Runspace)
            $results += $result
            $rs.PowerShell.Dispose()
          }
          
          $runspacePool.Close()
          $runspacePool.Dispose()
        }
      }
    }
    else {
      # 串行执行
      foreach ($target in $targets) {
        # ShouldProcess 检查：支持 -WhatIf 和 -Confirm
        if (-not $PSCmdlet.ShouldProcess($target, "Copy SSH public key")) {
          Write-Host "[$target] Skipped due to -WhatIf or user declined confirmation" -ForegroundColor Yellow
          $results += [pscustomobject]@{
            Host = $target
            Success = $false
            Message = 'Skipped (WhatIf/Confirm)'
            Duration = [timespan]::Zero
            BackupCreated = $false
            KeyAlreadyExists = $false
            ControlMasterUsed = $false
            Timestamp = Get-Date
          }
          continue
        }
        
        $result = Process-SingleHost -Target $target -PublicKeyContent $publicKeyContent -Backup:$Backup -Force:$Force -UseControlMaster:$UseControlMaster -ControlPersistSeconds $ControlPersistSeconds -ConnectionTimeout $ConnectionTimeout -RetryCount $RetryCount -RetryDelaySeconds $RetryDelaySeconds
        $results += $result
        
        if (-not $result.Success -and -not $ContinueOnError) {
          Write-Error "[$target] 失败，停止后续操作"
          break
        }
      }
    }
    
    # 输出总结
    Write-Host "`n---------- 结果汇总 ----------" -ForegroundColor Cyan
    $successCount = ($results | Where-Object { $_.Success }).Count
    $failedCount = ($results | Where-Object { -not $_.Success }).Count
    Write-Host ("总计: {0} 成功, {1} 失败" -f $successCount, $failedCount) -ForegroundColor $(if ($failedCount -eq 0) { 'Green' } else { 'Yellow' })
    
    foreach ($r in $results) {
      $status = if ($r.Success) { 'Success' } else { 'Failed' }
      $durationStr = "{0:N1}s" -f $r.Duration.TotalSeconds
      Write-Host ("{0,-24}  {1,-7}  {2,6}  {3}" -f $r.Host, $status, $durationStr, $r.Message)
    }
    
    # 返回结果数组
    return $results
  }
  catch
  {
    Write-Error "Copy-Sshid操作失败: $($_.Exception.Message)"
    throw
  }
}

<#
.SYNOPSIS
    Enables SSH connection reuse via ControlMaster configuration.

.DESCRIPTION
    Adds ControlMaster configuration to ~/.ssh/config to enable SSH connection multiplexing,
    which allows multiple SSH sessions to share a single connection, improving performance
    for frequent SSH operations.

.PARAMETER PersistMinutes
    Number of minutes to keep the master connection open after the last session ends.
    Default is 10 minutes.

.PARAMETER Force
    Force overwrite existing ControlMaster configuration if it already exists.

.EXAMPLE
    Enable-SshConnectionReuse
    
    Enables connection reuse with default 10-minute persistence.

.EXAMPLE
    Enable-SshConnectionReuse -PersistMinutes 30
    
    Enables connection reuse with 30-minute persistence.

.EXAMPLE
    Enable-SshConnectionReuse -Force
    
    Enables connection reuse and overwrites any existing configuration.

.NOTES
    Creates ~/.ssh/sockets directory for storing control socket files.
    Works on both Windows ($env:USERPROFILE\.ssh) and Linux/Mac ($env:HOME/.ssh).
#>
function Enable-SshConnectionReuse
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 1440)]
        [int]$PersistMinutes = 10,
        
        [switch]$Force
    )
    
    # Determine SSH directory based on platform
    if ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT") {
        $sshDir = Join-Path $env:USERPROFILE ".ssh"
    } else {
        $sshDir = Join-Path $env:HOME ".ssh"
    }
    
    $socketsDir = Join-Path $sshDir "sockets"
    $configFile = Join-Path $sshDir "config"
    
    # Create .ssh directory if it doesn't exist
    if (-not (Test-Path $sshDir)) {
        if ($PSCmdlet.ShouldProcess($sshDir, "Create SSH directory")) {
            New-Item -Path $sshDir -ItemType Directory -Force | Out-Null
            Write-Verbose "Created SSH directory: $sshDir"
        }
    }
    
    # Create sockets directory for control files
    if (-not (Test-Path $socketsDir)) {
        if ($PSCmdlet.ShouldProcess($socketsDir, "Create sockets directory")) {
            New-Item -Path $socketsDir -ItemType Directory -Force | Out-Null
            Write-Verbose "Created sockets directory: $socketsDir"
        }
    }
    
    # Determine ControlPath format based on platform
    if ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT") {
        $controlPath = "~\.ssh\sockets\%r@%h-%p"
    } else {
        $controlPath = "~/.ssh/sockets/%r@%h-%p"
    }
    
    # Build ControlMaster configuration
    $controlMasterConfig = @"
Host *
    ControlMaster auto
    ControlPath $controlPath
    ControlPersist ${PersistMinutes}m
"@
    
    # Check if config file exists
    $configExists = Test-Path $configFile
    $existingConfig = if ($configExists) { Get-Content $configFile -Raw } else { "" }
    
    # Check if ControlMaster config already exists
    $hasControlMaster = $existingConfig -match '(?s)Host\s+\*\s+ControlMaster\s+auto'
    
    if ($hasControlMaster) {
        if ($Force) {
            # Remove existing ControlMaster block
            # Pattern matches from "Host *" to the next Host block or end of file
            $updatedConfig = $existingConfig -replace '(?s)(Host\s+\*\s+(?:ControlMaster\s+auto\s+|ControlPath\s+[^\s]+\s+|ControlPersist\s+[^\s]+\s+)+)', ''
            
            # Clean up extra blank lines
            $updatedConfig = $updatedConfig -replace '(\r?\n){3,}', "`n`n"
            $updatedConfig = $updatedConfig.TrimEnd() + "`n`n"
            
            # Add new config
            $updatedConfig += $controlMasterConfig + "`n"
            
            if ($PSCmdlet.ShouldProcess($configFile, "Update SSH config with ControlMaster settings")) {
                Set-Content -Path $configFile -Value $updatedConfig -Encoding UTF8 -NoNewline
                Write-Host "Updated existing ControlMaster configuration in: $configFile" -ForegroundColor Green
            }
        } else {
            Write-Host "ControlMaster configuration already exists. Use -Force to overwrite." -ForegroundColor Yellow
            Write-Host "Config file: $configFile" -ForegroundColor Gray
        }
    } else {
        # Add new ControlMaster config
        if ($configExists -and $existingConfig.Trim().Length -gt 0) {
            # Append to existing config
            $newConfig = $existingConfig.TrimEnd() + "`n`n" + $controlMasterConfig + "`n"
        } else {
            # Create new config
            $newConfig = $controlMasterConfig + "`n"
        }
        
        if ($PSCmdlet.ShouldProcess($configFile, "Add ControlMaster configuration to SSH config")) {
            Set-Content -Path $configFile -Value $newConfig -Encoding UTF8 -NoNewline
            Write-Host "Added ControlMaster configuration to: $configFile" -ForegroundColor Green
        }
    }
    
    Write-Host "SSH connection reuse enabled with ${PersistMinutes} minute persistence." -ForegroundColor Cyan
    Write-Host "Socket directory: $socketsDir" -ForegroundColor Gray
}

<#
.SYNOPSIS
    Disables SSH connection reuse by removing ControlMaster configuration.

.DESCRIPTION
    Removes ControlMaster configuration from ~/.ssh/config and optionally cleans up
    control socket files.

.PARAMETER RemoveSockets
    Remove socket files from ~/.ssh/sockets directory after disabling configuration.

.EXAMPLE
    Disable-SshConnectionReuse
    
    Removes ControlMaster configuration but leaves socket files intact.

.EXAMPLE
    Disable-SshConnectionReuse -RemoveSockets
    
    Removes ControlMaster configuration and cleans up socket files.

.NOTES
    Preserves other SSH configuration settings.
    Works on both Windows ($env:USERPROFILE\.ssh) and Linux/Mac ($env:HOME/.ssh).
#>
function Disable-SshConnectionReuse
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Low')]
    param(
        [switch]$RemoveSockets
    )
    
    # Determine SSH directory based on platform
    if ($IsWindows -or $PSVersionTable.Platform -eq "Win32NT") {
        $sshDir = Join-Path $env:USERPROFILE ".ssh"
    } else {
        $sshDir = Join-Path $env:HOME ".ssh"
    }
    
    $socketsDir = Join-Path $sshDir "sockets"
    $configFile = Join-Path $sshDir "config"
    
    # Remove ControlMaster config from SSH config file
    if (Test-Path $configFile) {
        $existingConfig = Get-Content $configFile -Raw
        
        # Check if ControlMaster config exists
        if ($existingConfig -match '(?s)Host\s+\*\s+ControlMaster\s+auto') {
            # Remove the ControlMaster block (Host * with ControlMaster, ControlPath, ControlPersist)
            $updatedConfig = $existingConfig -replace '(?s)(Host\s+\*\s+(?:ControlMaster\s+auto\s+|ControlPath\s+[^\s]+\s+|ControlPersist\s+[^\s]+\s+)+)', ''
            
            # Clean up extra blank lines
            $updatedConfig = $updatedConfig -replace '(\r?\n){3,}', "`n`n"
            $updatedConfig = $updatedConfig.TrimEnd()
            
            if ($PSCmdlet.ShouldProcess($configFile, "Remove ControlMaster configuration")) {
                if ($updatedConfig.Trim().Length -gt 0) {
                    Set-Content -Path $configFile -Value ($updatedConfig + "`n") -Encoding UTF8 -NoNewline
                    Write-Host "Removed ControlMaster configuration from: $configFile" -ForegroundColor Green
                } else {
                    # File is now empty, remove it
                    Remove-Item -Path $configFile -Force
                    Write-Host "Removed empty SSH config file: $configFile" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "No ControlMaster configuration found in: $configFile" -ForegroundColor Yellow
        }
    } else {
        Write-Host "SSH config file does not exist: $configFile" -ForegroundColor Yellow
    }
    
    # Optionally remove socket files
    if ($RemoveSockets -and (Test-Path $socketsDir)) {
        if ($PSCmdlet.ShouldProcess($socketsDir, "Remove socket files")) {
            # Remove all socket files
            $socketFiles = Get-ChildItem -Path $socketsDir -File -ErrorAction SilentlyContinue
            if ($socketFiles) {
                $socketFiles | Remove-Item -Force
                Write-Host "Removed $($socketFiles.Count) socket file(s) from: $socketsDir" -ForegroundColor Green
            }
            
            # Remove the sockets directory if it's empty
            $remainingFiles = Get-ChildItem -Path $socketsDir -ErrorAction SilentlyContinue
            if (-not $remainingFiles) {
                Remove-Item -Path $socketsDir -Force
                Write-Host "Removed empty sockets directory: $socketsDir" -ForegroundColor Green
            }
        }
    }
    
    Write-Host "SSH connection reuse disabled." -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Starts SSH agent and optionally loads SSH keys.

.DESCRIPTION
    Starts ssh-agent process, sets environment variables, optionally persists session
    to file, and can auto-add keys from ~/.ssh directory.

.PARAMETER AutoAddKeys
    Automatically add all identity keys from ~/.ssh directory to the agent.

.PARAMETER PersistSession
    Persist agent session information to ~/.ssh/agent-session.json for later resumption.

.PARAMETER Lifetime
    Maximum lifetime in seconds for added keys (0 = unlimited).

.EXAMPLE
    Start-SshAgent
    
    Starts ssh-agent without loading keys.

.EXAMPLE
    Start-SshAgent -AutoAddKeys
    
    Starts ssh-agent and loads all keys from ~/.ssh.

.EXAMPLE
    Start-SshAgent -AutoAddKeys -PersistSession -Lifetime 3600
    
    Starts ssh-agent, loads keys with 1-hour lifetime, and persists session.

.NOTES
    Works on both Windows and Linux/Mac.
#>
function Start-SshAgent
{
    [CmdletBinding()]
    param(
        [switch]$AutoAddKeys,
        [switch]$PersistSession,
        [int]$Lifetime = 0
    )
    
    # Platform-adapted SSH directory
    $sshDir = if ($IsWindows) { Join-Path $env:USERPROFILE ".ssh" } else { Join-Path $env:HOME ".ssh" }
    
    # Start ssh-agent and parse output
    $agentOutput = ssh-agent -s 2>&1 | Out-String
    if ($agentOutput -match 'SSH_AUTH_SOCK=([^;]+);') { $socket = $Matches[1] }
    if ($agentOutput -match 'SSH_AGENT_PID=(\d+);') { $pid = $Matches[1] }
    
    # Set environment variables
    $env:SSH_AUTH_SOCK = $socket
    $env:SSH_AGENT_PID = $pid
    
    # Persist session if requested
    if ($PersistSession)
    {
        $sessionFile = Join-Path $sshDir "agent-session.json"
        [pscustomobject]@{ PID=$pid; Socket=$socket; Timestamp=Get-Date } | ConvertTo-Json | Out-File $sessionFile -Encoding UTF8
    }
    
    # Auto-add keys if requested
    $loadedKeys = if ($AutoAddKeys) { Add-SshKey -All -Lifetime $Lifetime } else { @() }
    
    return [pscustomobject]@{ PID=$pid; Socket=$socket; Keys=$loadedKeys; Persisted=$PersistSession }
}

<#
.SYNOPSIS
    Adds SSH keys to the running ssh-agent.

.DESCRIPTION
    Adds specified SSH identity keys or all keys from ~/.ssh to the ssh-agent.

.PARAMETER KeyPaths
    Array of key file paths to add.

.PARAMETER All
    Add all identity keys from ~/.ssh directory (id_rsa, id_ed25519, etc).

.PARAMETER Lifetime
    Maximum lifetime in seconds for added keys (0 = unlimited).

.EXAMPLE
    Add-SshKey -KeyPaths ~/.ssh/id_rsa
    
    Adds a specific key to the agent.

.EXAMPLE
    Add-SshKey -All
    
    Adds all keys from ~/.ssh directory.

.EXAMPLE
    Add-SshKey -All -Lifetime 3600
    
    Adds all keys with 1-hour lifetime.

.NOTES
    Requires ssh-agent to be running.
#>
function Add-SshKey
{
    [CmdletBinding()]
    param(
        [string[]]$KeyPaths,
        [switch]$All,
        [int]$Lifetime = 0
    )
    
    # Check agent running
    $status = Get-SshAgentStatus
    if (-not $status.IsRunning) { throw "ssh-agent未运行，请先执行 Start-SshAgent" }
    
    # Find keys if -All
    if ($All)
    {
        $sshDir = if ($IsWindows) { Join-Path $env:USERPROFILE ".ssh" } else { Join-Path $env:HOME ".ssh" }
        $KeyPaths = Get-ChildItem $sshDir -Filter "id_*" | Where-Object { $_.Name -notmatch '\.pub$|\.pem$' } | Select-Object -ExpandProperty FullName
    }
    
    # Add each key
    $addedKeys = @()
    foreach ($keyPath in $KeyPaths)
    {
        if (Test-Path $keyPath)
        {
            $lifetimeArg = if ($Lifetime -gt 0) { "-t $Lifetime" } else { "" }
            $result = ssh-add $lifetimeArg $keyPath 2>&1 | Out-String
            if ($result -match 'Identity added') { $addedKeys += $keyPath }
        }
    }
    
    return $addedKeys
}

<#
.SYNOPSIS
    Checks ssh-agent status and lists loaded keys.

.DESCRIPTION
    Returns information about whether ssh-agent is running, its PID, socket path,
    and details of all loaded keys including fingerprints and types.

.EXAMPLE
    Get-SshAgentStatus
    
    Returns agent status and loaded keys.

.OUTPUTS
    PSCustomObject with IsRunning, PID, Socket, Keys, and KeyCount properties.
#>
function Get-SshAgentStatus
{
    [CmdletBinding()]
    param()
    
    $isRunning = $false
    $keys = @()
    
    if ($env:SSH_AUTH_SOCK -and $env:SSH_AGENT_PID)
    {
        $testResult = ssh-add -l 2>&1 | Out-String
        if ($testResult -match 'Could not open') { $isRunning = $false }
        elseif ($testResult -match 'no identities') { $isRunning = $true }
        else
        {
            $isRunning = $true
            # Parse keys from output
            $keys = $testResult -split "`n" | Where-Object { $_ -match '^\d+' } | ForEach-Object {
                if ($_ -match '(\d+)\s+SHA256:([A-Za-z0-9+/=]+)\s+(.+)\s+\(([^)]+)\)')
                {
                    [pscustomobject]@{ Bits=[int]$Matches[1]; Fingerprint="SHA256:$($Matches[2])"; Comment=$Matches[3].Trim(); Type=$Matches[4] }
                }
            }
        }
    }
    
    return [pscustomobject]@{ IsRunning=$isRunning; PID=$env:SSH_AGENT_PID; Socket=$env:SSH_AUTH_SOCK; Keys=$keys; KeyCount=$keys.Count }
}

<#
.SYNOPSIS
    Stops ssh-agent and cleans up environment.

.DESCRIPTION
    Stops the running ssh-agent, removes environment variables, cleans up session
    file, and optionally kills all ssh-agent processes.

.PARAMETER KillAll
    Kill all ssh-agent processes on the system (not just the current one).

.EXAMPLE
    Stop-SshAgent
    
    Stops the current ssh-agent.

.EXAMPLE
    Stop-SshAgent -KillAll
    
    Stops all ssh-agent processes on the system.

.NOTES
    Removes persisted session file if it exists.
#>
function Stop-SshAgent
{
    [CmdletBinding()]
    param([switch]$KillAll)
    
    if ($env:SSH_AGENT_PID)
    {
        ssh-agent -k 2>&1 | Out-Null
        Remove-Item env:SSH_AUTH_SOCK -ErrorAction SilentlyContinue
        Remove-Item env:SSH_AGENT_PID -ErrorAction SilentlyContinue
    }
    
    # Clean session file
    $sshDir = if ($IsWindows) { Join-Path $env:USERPROFILE ".ssh" } else { Join-Path $env:HOME ".ssh" }
    Remove-Item (Join-Path $sshDir "agent-session.json") -ErrorAction SilentlyContinue
    
    # Kill all agents if requested
    if ($KillAll)
    {
        if ($IsWindows) { Get-Process ssh-agent -ErrorAction SilentlyContinue | Stop-Process -Force }
        else { pkill ssh-agent 2>$null }
    }
    
    return $true
}

<#
.SYNOPSIS
    Resumes a previously persisted ssh-agent session.

.DESCRIPTION
    Loads ssh-agent session information from ~/.ssh/agent-session.json, validates
    that the socket and process are still available, and restores environment variables.

.EXAMPLE
    Resume-SshAgent
    
    Attempts to resume a persisted session.

.OUTPUTS
    PSCustomObject with agent status, or null if session cannot be resumed.
#>
function Resume-SshAgent
{
    [CmdletBinding()]
    param()
    
    $sshDir = if ($IsWindows) { Join-Path $env:USERPROFILE ".ssh" } else { Join-Path $env:HOME ".ssh" }
    $sessionFile = Join-Path $sshDir "agent-session.json"
    
    if (-not (Test-Path $sessionFile))
    {
        Write-Warning "未找到持久化的agent session文件"
        return $null
    }
    
    $session = Get-Content $sessionFile | ConvertFrom-Json
    
    # Verify socket and process exist
    if (-not (Test-Path $session.Socket))
    {
        Write-Warning "Agent socket已失效"
        Remove-Item $sessionFile -Force
        return $null
    }
    
    $processExists = if ($IsWindows) { Get-Process -Id $session.PID -ErrorAction SilentlyContinue }
    else { ps -p $session.PID 2>$null }
    
    if (-not $processExists)
    {
        Write-Warning "Agent进程已终止"
        Remove-Item $sessionFile -Force
        return $null
    }
    
    # Restore environment
    $env:SSH_AUTH_SOCK = $session.Socket
    $env:SSH_AGENT_PID = $session.PID
    
    return Get-SshAgentStatus
}

Export-ModuleMember -Function New-SshProxy
Export-ModuleMember -Function Copy-Sshid
Export-ModuleMember -Function Start-SshAgent
Export-ModuleMember -Function Add-SshKey
Export-ModuleMember -Function Get-SshAgentStatus
Export-ModuleMember -Function Stop-SshAgent
Export-ModuleMember -Function Resume-SshAgent
Export-ModuleMember -Function Enable-SshConnectionReuse
Export-ModuleMember -Function Disable-SshConnectionReuse
