# SSH脚本改进设计文档

**日期：** 2026-06-05  
**目标：** 优化 Ssh.psm1 脚本，将每个主机需要2-3次密码输入减少到1次或0次

---

## 概述

### 问题分析

当前 `Copy-Sshid` 函数对每个主机执行多次独立的SSH连接：
- 检查公钥是否存在（Line 310）
- 备份文件（Line 235，如果使用-Backup）
- 复制公钥（Line 359）

**单个主机：** 至少2-3次密码输入  
**多个主机：** 每个主机重复上述操作，密码输入次数翻倍

### 目标

优化后达到：
- **单个主机：** 1次密码（或0次，使用ssh-agent）
- **多个主机：** 每个主机1次密码（使用ControlMaster时，整个批次可能只需1次）
- **ssh-agent用户：** 0次密码输入

### 三大核心改进

1. **SSH操作合并** - 所有操作合并到单次SSH命令
2. **ControlMaster连接复用** - 多个SSH命令共享TCP连接
3. **ssh-agent助手函数** - 便捷的ssh-agent管理

---

## 方案1：SSH操作合并

### 当前实现

```powershell
# 检查公钥是否存在 - 第1次SSH连接
ssh $target "grep -q '$keyFingerprint' ~/.ssh/authorized_keys ..."

# 备份文件 - 第2次SSH连接（如果-Backup）
ssh $target "cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup..."

# 复制公钥 - 第3次SSH连接
$publicKeyContent | ssh $target "cat >> .ssh/authorized_keys"
```

### 优化方案

将所有操作合并到一个shell脚本中，单次SSH执行：

```bash
#!/bin/bash
set -e

# 1. 检查公钥是否已存在
KEY_CONTENT="$1"
KEY_FP=$(echo "$KEY_CONTENT" | ssh-keygen -lf - 2>/dev/null | grep -o 'SHA256:[A-Za-z0-9+/=]+' || true)

if [ -n "$KEY_FP" ]; then
  if grep -q "$KEY_FP" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "ALREADY_EXISTS"
    exit 0
  fi
fi

# 2. 备份（如果指定）
if [ "$2" = "BACKUP" ]; then
  if [ -f ~/.ssh/authorized_keys ]; then
    BACKUP_FILE=~/.ssh/authorized_keys.backup.$(date +%Y%m%d_%H%M%S)
    cp ~/.ssh/authorized_keys "$BACKUP_FILE"
    echo "BACKUP_CREATED:$BACKUP_FILE"
  fi
fi

# 3. 确保目录和权限
[ -d ~/.ssh ] || mkdir -p ~/.ssh
chmod 700 ~/.ssh
[ -f ~/.ssh/authorized_keys ] || touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 4. 添加公钥
echo "$KEY_CONTENT" >> ~/.ssh/authorized_keys

# 5. 验证添加成功
if grep -qF "$KEY_CONTENT" ~/.ssh/authorized_keys; then
  echo "SUCCESS"
else
  echo "ERROR:Failed to add key"
  exit 1
fi
```

### PowerShell实现

```powershell
function Copy-Sshid {
  # ... 参数定义 ...
  
  # 构建远程脚本
  $remoteScript = @"
set -e
KEY_CONTENT='__KEY_CONTENT__'
__SCRIPT_BODY__
"@
  
  # 替换公钥内容（需转义）
  $escapedKey = $publicKeyContent -replace "'", "'\\''" -replace "`n", "\\n"
  $remoteScript = $remoteScript -replace '__KEY_CONTENT__', $escapedKey
  
  # 单次SSH执行
  $result = ssh $target "bash -c '$remoteScript'" $backupFlag
  
  # 解析返回状态
  if ($result -match 'SUCCESS') { ... }
  elseif ($result -match 'ALREADY_EXISTS') { ... }
  elseif ($result -match 'ERROR:') { ... }
}
```

### 优势

- 单次密码验证完成所有操作
- 原子性更好，中途失败不影响系统状态
- 减少网络往返，提升速度

---

## 方案2：SSH ControlMaster连接复用

### 原理

SSH ControlMaster允许多个SSH会话共享同一个TCP连接：
- 第一个连接建立并认证（需要密码）
- 后续连接复用已建立的连接（无需密码）
- ControlPersist控制连接保持时间

### 实现

#### 临时配置（Copy-Sshid内部）

```powershell
function Copy-Sshid {
  param(
    [switch]$UseControlMaster,
    [int]$ControlPersistSeconds = 60
  )
  
  if ($UseControlMaster) {
    # 平台适配的ControlPath
    $tempDir = if ($IsWindows) { $env:TEMP } else { "/tmp" }
    $controlPath = Join-Path $tempDir "ssh-control-%r@%h:%p"
    
    $sshOptions = @(
      "-o", "ControlMaster=auto",
      "-o", "ControlPath=$controlPath",
      "-o", "ControlPersist=$ControlPersistSeconds"
    )
    $sshCmd = "ssh $sshOptions $target ..."
  }
}
```

#### 全局配置助手函数

```powershell
function Enable-SshConnectionReuse {
  param([int]$PersistMinutes = 10)
  
  $configContent = @"
Host *
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist $PersistMinutes
"@
  
  # 确保~/.ssh/sockets目录存在
  # 追加或更新~/.ssh/config
  # 创建sockets目录
}

function Disable-SshConnectionReuse {
  # 移除ControlMaster相关配置
  # 清理sockets目录
}
```

### 使用场景

**场景1：Copy-Sshid临时复用**
```powershell
Copy-Sshid user@host1,user@host2,user@host3 -UseControlMaster
# 第一个host需要密码，后续复用连接，可能无需密码
```

**场景2：全局启用复用**
```powershell
Enable-SshConnectionReuse -PersistMinutes 30
# 所有SSH命令自动复用连接
Copy-Sshid user@host1,user@host2,user@host3
# 整个批次可能只需1次密码（取决于Persist时间）
```

---

## 方案3：ssh-agent管理助手

### 新增函数

#### 1. Start-SshAgent

```powershell
function Start-SshAgent {
  [CmdletBinding()]
  param(
    [switch]$AutoAddKeys,
    [switch]$PersistSession,
    [string[]]$KeyPaths,
    [int]$Lifetime = 0  # 0表示永久
  )
  
  # 平台适配的SSH目录
  $sshDir = if ($IsWindows) {
    Join-Path $env:USERPROFILE ".ssh"
  } else {
    Join-Path $env:HOME ".ssh"
  }
  
  # 启动ssh-agent
  $agentOutput = ssh-agent -s 2>&1
  # 解析输出，提取SSH_AUTH_SOCK和SSH_AGENT_PID
  
  # 设置环境变量（进程级）
  $env:SSH_AUTH_SOCK = ...
  $env:SSH_AGENT_PID = ...
  
  # 如果-PersistSession，保存到文件
  if ($PersistSession) {
    $sessionFile = Join-Path $sshDir "agent-session.json"
    # 确保目录存在
    if (-not (Test-Path $sshDir)) {
      New-Item -ItemType Directory -Path $sshDir -Force
    }
    # 保存session信息（设置文件权限600）
    $sessionInfo | ConvertTo-Json | Out-File $sessionFile -Encoding UTF8
    # Windows: 设置ACL权限，Linux: chmod 600
  }
  
  # 如果-AutoAddKeys，调用Add-SshKey -All
  
  return [pscustomobject]@{
    PID = $agentPid
    Socket = $socketPath
    Keys = $loadedKeys
  }
}
```

#### 2. Add-SshKey

```powershell
function Add-SshKey {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)]
    [string[]]$KeyPaths,
    
    [switch]$All,
    
    [int]$Lifetime = 0
  )
  
  if ($All) {
    # 扫描~/.ssh目录，查找所有私钥
    $keys = Get-ChildItem ~/.ssh -Filter "id_*" | Where-Object { 
      $_.Name -notmatch '\.pub$' 
    }
    $KeyPaths = $keys.FullName
  }
  
  foreach ($key in $KeyPaths) {
    ssh-add -t $Lifetime $key
    # 记录添加结果
  }
  
  return Get-SshAgentStatus
}
```

#### 3. Get-SshAgentStatus

```powershell
function Get-SshAgentStatus {
  [CmdletBinding()]
  param()
  
  $isRunning = $false
  $keys = @()
  
  if ($env:SSH_AUTH_SOCK -and $env:SSH_AGENT_PID) {
    # 测试连接
    $testResult = ssh-add -l 2>&1
    if ($testResult -notmatch 'Could not open a connection') {
      $isRunning = $true
      # 解析密钥列表
      $keys = $testResult | ForEach-Object {
        if ($_ -match '(\d+)\s+SHA256:([A-Za-z0-9+/=]+)\s+(.+)\s+\(([^)]+)\)') {
          [pscustomobject]@{
            Bits = $Matches[1]
            Fingerprint = $Matches[2]
            Comment = $Matches[3]
            Type = $Matches[4]
          }
        }
      }
    }
  }
  
  return [pscustomobject]@{
    IsRunning = $isRunning
    PID = $env:SSH_AGENT_PID
    Socket = $env:SSH_AUTH_SOCK
    Keys = $keys
  }
}
```

#### 4. Stop-SshAgent

```powershell
function Stop-SshAgent {
  [CmdletBinding()]
  param([switch]$KillAll)
  
  if ($env:SSH_AGENT_PID) {
    ssh-agent -k
    Remove-Item env:SSH_AUTH_SOCK
    Remove-Item env:SSH_AGENT_PID
  }
  
  if ($KillAll) {
    # Windows: Get-Process ssh-agent | Stop-Process
    # Linux: pkill ssh-agent
  }
  
  # 清理持久化文件
  Remove-Item ~/.ssh/agent-session.json -ErrorAction SilentlyContinue
}
```

#### 5. Resume-SshAgent

```powershell
function Resume-SshAgent {
  [CmdletBinding()]
  param()
  
  # 平台适配的SSH目录
  $sshDir = if ($IsWindows) {
    Join-Path $env:USERPROFILE ".ssh"
  } else {
    Join-Path $env:HOME ".ssh"
  }
  
  $sessionFile = Join-Path $sshDir "agent-session.json"
  
  if (Test-Path $sessionFile) {
    $session = Get-Content $sessionFile | ConvertFrom-Json
    
    # 检查agent是否还在运行
    if (Test-Path $session.Socket) {
      $env:SSH_AUTH_SOCK = $session.Socket
      $env:SSH_AGENT_PID = $session.PID
      return Get-SshAgentStatus
    }
    else {
      Write-Warning "Agent session已失效，请重新启动"
      Remove-Item $sessionFile
      return $null
    }
  }
  else {
    Write-Warning "未找到持久化的agent session"
    return $null
  }
}
```

### 使用流程

```powershell
# 首次配置（输入一次密钥密码）
Start-SshAgent -AutoAddKeys -PersistSession
# 此时所有SSH操作免密

# 新PowerShell会话中恢复
Resume-SshAgent
# 无需再次输入密码

# 查看状态
Get-SshAgentStatus

# 停止agent
Stop-SshAgent
```

---

## Copy-Sshid改进细节

### 参数调整

```powershell
function Copy-Sshid {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [parameter(Mandatory, Position=0)]
    [string[]]$RemoteHosts,
    
    [parameter(Position=1)]
    [string]$IdentityFile = "",
    
    [switch]$Force,
    [switch]$Backup,
    [switch]$ContinueOnError,
    
    # 新增参数
    [switch]$Parallel,
    [ValidateSet("Auto","Jobs","Runspaces","PS7Parallel")]
    [string]$ParallelMode = "Auto",
    
    [switch]$UseControlMaster,
    [int]$ControlPersistSeconds = 60,
    
    [int]$ConnectionTimeout = 30,
    [int]$RetryCount = 0,
    [int]$RetryDelaySeconds = 5
  )
}
```

### 执行流程

#### 单主机流程

```
1. 验证本地公钥文件
2. 构建合并的远程bash脚本
3. 配置SSH选项（ControlMaster、Timeout）
4. 执行单次SSH命令（带重试）
5. 解析返回状态：
   - SUCCESS → 成功
   - ALREADY_EXISTS → 已存在（-Force则继续添加）
   - ERROR:xxx → 失败，分析错误类型
6. 返回结构化结果对象
```

#### 多主机流程（-Parallel）

```
1. 分析ParallelMode：
   - Auto: PowerShell 7+用PS7Parallel，否则Jobs
   - Jobs: Start-Job并行
   - Runspaces: 使用runspace pool
   - PS7Parallel: ForEach-Object -Parallel

2. 并行执行：
   每个主机独立执行单次SSH命令
   
3. 收集结果：
   等待所有任务完成，整理结果
   
4. 输出汇总表格：
   Host              Status   Duration  Message
   user@host1        Success  2.3s      Key copied
   user@host2        Success  1.8s      Key copied
   user@host3        Failed   5.0s      Connection timeout
```

### 返回值

```powershell
# 不再返回$true/$false，返回结构化对象数组
return @(
  [pscustomobject]@{
    Host = "user@host1"
    Success = $true
    Message = "Key copied successfully"
    Duration = [timespan]::FromSeconds(2.3)
    BackupCreated = $true
    KeyAlreadyExists = $false
    ControlMasterUsed = $true
    Timestamp = Get-Date
  },
  ...
)

# 支持管道处理
Copy-Sshid ... | Where-Object {$_.Success} | Select-Object Host,Duration
Copy-Sshid ... | Export-Csv results.csv -NoTypeInformation
```

### 错误处理增强

```powershell
# 错误分类和诊断
if ($result -match 'ERROR:Connection refused') {
  $diagnostic = "SSH服务未启动或防火墙阻止"
}
elseif ($result -match 'ERROR:Permission denied') {
  $diagnostic = "用户名错误或无SSH访问权限"
}
elseif ($result -match 'ERROR:No space left') {
  $diagnostic = "远程主机磁盘空间不足"
}

# 重试机制
for ($retry = 0; $retry -le $RetryCount; $retry++) {
  $result = ssh ...
  if ($result -match 'SUCCESS') { break }
  if ($retry -lt $RetryCount) { 
    Start-Sleep -Seconds $RetryDelaySeconds
  }
}
```

---

## New-SshProxy改进

### 当前问题

```powershell
function New-SshProxy {
  param($Name, $Port, $SshTarget)
  # 创建函数但没有：
  # - 错误处理
  # - 连接状态检查
  # - 日志记录
  # - 停止代理的方法
}
```

### 改进方案

```powershell
function New-SshProxy {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,
    
    [Parameter(Mandatory)]
    [ValidateRange(1,65535)]
    [int]$Port,
    
    [Parameter(Mandatory)]
    [string]$SshTarget,
    
    [switch]$DynamicPort,  # 自动选择可用端口
    [int]$Timeout = 10     # 连接超时
  )
  
  # 1. 检查端口可用性
  if (-not $DynamicPort) {
    $portInUse = Test-PortInUse -Port $Port
    if ($portInUse) {
      throw "端口 $Port 已被占用"
    }
  }
  else {
    $Port = Find-AvailablePort -StartPort 1080
  }
  
  # 2. 测试SSH连接
  $connectionTest = Test-SshConnection -Target $SshTarget -Timeout $Timeout
  if (-not $connectionTest.Success) {
    throw "无法连接到 $SshTarget: $($connectionTest.Message)"
  }
  
  # 3. 创建启动函数
  $startFunctionName = "Start-${Name}Proxy"
  Set-Item -Path function:global:$startFunctionName -Value {
    param([switch]$Background)
    
    Write-Host "启动SSH代理: $SshTarget 端口:$Port" -ForegroundColor Green
    
    if ($Background) {
      # 后台运行
      Start-Process ssh -ArgumentList "-CND","127.0.0.1:$Port",$SshTarget -WindowStyle Hidden
      Write-Host "代理已在后台启动" -ForegroundColor Yellow
    }
    else {
      # 前台运行，显示日志
      ssh -CND 127.0.0.1:$Port $SshTarget -v
    }
  }.GetNewClosure()
  
  # 4. 创建停止函数
  $stopFunctionName = "Stop-${Name}Proxy"
  Set-Item -Path function:global:$stopFunctionName -Value {
    # 查找并终止SSH进程
    Get-Process ssh | Where-Object {
      $_.CommandLine -match "127.0.0.1:$Port"
    } | Stop-Process
    
    Write-Host "SSH代理已停止" -ForegroundColor Green
  }.GetNewClosure()
  
  # 5. 创建状态检查函数
  $statusFunctionName = "Get-${Name}ProxyStatus"
  Set-Item -Path function:global:$statusFunctionName -Value {
    $process = Get-Process ssh -ErrorAction SilentlyContinue | Where-Object {
      $_.CommandLine -match "127.0.0.1:$Port"
    }
    
    return [pscustomobject]@{
      IsRunning = $process -ne $null
      PID = $process?.Id
      Port = $Port
      Target = $SshTarget
    }
  }.GetNewClosure()
  
  Write-Host "已创建3个函数:" -ForegroundColor Cyan
  Write-Host "  $startFunctionName - 启动代理" 
  Write-Host "  $stopFunctionName - 停止代理"
  Write-Host "  $statusFunctionName - 查看状态"
}
```

---

## 实现优先级

### Phase 1：核心改进（立即实现）

1. **SSH操作合并** - Copy-Sshid改为单次SSH命令
2. **返回值结构化** - 返回对象数组，支持管道处理
3. **错误诊断增强** - 分类错误，提供诊断信息

预期效果：单个主机从3次密码 → 1次密码

### Phase 2：连接优化（次优先）

4. **ControlMaster支持** - Copy-Sshid内临时复用
5. **全局配置助手** - Enable/Disable-SshConnectionReuse
6. **超时和重试** - ConnectionTimeout, RetryCount参数

预期效果：多主机场景进一步优化密码输入次数

### Phase 3：ssh-agent管理（可选）

7. **Start/Stop-SshAgent** - 基本管理
8. **Add-SshKey** - 密钥添加
9. **Get-SshAgentStatus** - 状态查询
10. **Resume-SshAgent** - 跨会话复用

预期效果：ssh-agent用户实现0次密码输入

### Phase 4：New-SshProxy改进（可选）

11. **端口检查** - 验证端口可用性
12. **连接测试** - 测试SSH目标可达性
13. **生成停止函数** - 便捷停止代理
14. **状态查询** - 查看代理运行状态

---

## 测试计划

### 单元测试

```powershell
# 测试合并脚本逻辑
Test-CopySshidScriptGeneration

# 测试返回值解析
Test-ParseSshResult -Result "SUCCESS" -ExpectedSuccess $true
Test-ParseSshResult -Result "ALREADY_EXISTS" -ExpectedExists $true
Test-ParseSshResult -Result "ERROR:Connection refused" -ExpectedError $true

# 测试ssh-agent管理
Test-StartSshAgent
Test-ResumeSshAgent
```

### 集成测试

```powershell
# 测试单主机操作
Copy-Sshid user@testhost -WhatIf
Copy-Sshid user@testhost -Verbose

# 测试多主机操作
Copy-Sshid user@host1,user@host2,user@host3 -ContinueOnError

# 测试ControlMaster
Copy-Sshid user@host1,user@host2 -UseControlMaster

# 测试并行
Copy-Sshid user@host1,user@host2 -Parallel
```

### 验收标准

| 场景 | 当前 | 目标 | 验证方法 |
|------|------|------|----------|
| 单主机 | 3次密码 | 1次密码 | 实际执行，计数密码输入 |
| 3个主机 | 9次密码 | 3次（或1次） | 实际执行，对比优化前后 |
| ssh-agent启动 | 手动配置 | 自动配置 | Start-SshAgent后验证免密 |
| 错误诊断 | 无 | 有诊断信息 | 触发各种错误，检查输出 |
| 管道处理 | 不支持 | 支持 | 管道到Export-Csv验证 |

---

## 向后兼容性

### 保证兼容

- 所有现有参数保持不变
- 新参数都有默认值，不影响现有用法
- -WhatIf行为保持一致
- 基本错误处理流程保持一致

### 行为变化（用户需知）

1. **返回值变化**：从 `$true/$false` 改为对象数组
   - 影响：脚本中检查 `$?` 或返回值的代码
   - 解决：使用 `.Success` 属性判断

2. **密码输入减少**：从3次减到1次
   - 影响：无负面影响，纯优化

3. **新增函数**：不影响现有函数

---

## 风险和限制

### 技术风险

1. **远程脚本兼容性**
   - 风险：不同shell（bash/dash/zsh）语法差异
   - 解决：使用POSIX兼容语法，测试主流shell

2. **ControlMaster清理**
   - 风险：连接未正确关闭，占用资源
   - 解决：设置ControlPersist超时，提供清理函数

3. **ssh-agent持久化**
   - 风险：session文件泄露，socket权限问题
   - 解决：文件权限600，定期验证连接有效性

### 使用限制

1. **Windows ssh-agent**
   - 限制：Windows原生ssh-agent服务需手动启动
   - 解决：提供诊断和启动指导

2. **PowerShell版本**
   - 限制：PS7Parallel需要PowerShell 7+
   - 解决：提供Jobs模式作为兼容方案

---

## 文件结构

```
powershell/module/MyPsScripts/
├── Ssh.psm1               # 主模块（改进后）
│   ├── Copy-Sshid         # 核心函数（重写）
│   ├── New-SshProxy       # 代理函数（增强）
│   ├── Start-SshAgent     # 新增
│   ├── Add-SshKey         # 新增
│   ├── Get-SshAgentStatus # 新增
│   ├── Stop-SshAgent      # 新增
│   ├── Resume-SshAgent    # 新增
│   ├── Enable-SshConnectionReuse  # 新增
│   └── Disable-SshConnectionReuse # 新增
└── MyPsScripts.psd1       # 模块配置（保持不变）
```

---

## 参考资料

- SSH ControlMaster: https://www.openssh.com/manual.html
- ssh-agent手册: man ssh-agent
- PowerShell Jobs: https://docs.microsoft.com/powershell/module/microsoft.powershell.core/start-job
- PowerShell 7 Parallel: https://docs.microsoft.com/powershell/module/microsoft.powershell.core/foreach-object