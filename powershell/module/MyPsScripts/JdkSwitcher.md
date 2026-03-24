# JdkSwitcher 功能说明

`JdkSwitcher.psm1` 用于在 PowerShell 中管理本地 JDK 映射并快速切换当前会话的 `JAVA_HOME` / `PATH`。

## 1. 功能概览

- 本地维护 JDK 映射（`Id/Key/Path`）
- 根据 `Key` 或直接 `Path` 切换当前会话 JDK
- 自动更新 `PATH`，避免旧 `JAVA_HOME\bin` 残留
- 递归扫描目录，查找可能的 JDK 安装位置
- 兼容并自动迁移历史记录格式（含备份）

## 2. 数据文件与存储格式

默认存储目录：

- `~/.jdks/`

默认数据文件：

- `~/.jdks/javahome.csv`

当前 CSV 格式（v2）：

```csv
Id,Key,Path
jdk-abcdef0123456789,jdk21,C:\Program Files\Java\jdk-21
```

字段说明：

- `Id`：唯一标识，基于 `java -version` 详情 + `Path` 生成哈希
- `Key`：用户自定义别名（例如 `jdk8`、`jdk17`、`jdk21`）
- `Path`：JDK 根目录（例如 `C:\Program Files\Java\jdk-21`）

## 3. 命令说明

## `Set-JavaHome`

注册或更新一条 JDK 映射。

示例：

```powershell
Set-JavaHome -Key jdk21 -Path "C:\Program Files\Java\jdk-21"
```

行为：

- 校验路径是否为有效 JDK（检查 `bin/java`、`bin/javac`）
- 自动生成 `Id`
- 相同 `Key` 会被覆盖更新

## `Get-JavaHome`

查询映射。

示例：

```powershell
Get-JavaHome
Get-JavaHome -Key jdk21
```

返回：

- 不带 `-Key`：返回全部记录（`Id/Key/Path`）
- 带 `-Key`：返回单条记录对象（`Id/Key/Path`）

## `Remove-JavaHome`

删除指定 `Key` 的映射记录（不卸载本地 JDK）。

示例：

```powershell
Remove-JavaHome -Key jdk8
```

## `Use-JavaHome`

切换当前 PowerShell 会话的 Java 环境。

示例：

```powershell
Use-JavaHome -Key jdk21
Use-JavaHome -Path "D:\SDK\jdk-17"
```

行为：

- 设置 `env:JAVA_HOME`
- 将 `JAVA_HOME\bin` 置于 `env:PATH` 前面
- 自动移除旧 `JAVA_HOME\bin` 与重复项

## `Search-JavaHome`

扫描指定目录下的 JDK 目录。

示例：

```powershell
Search-JavaHome -Path "D:\SDKs" -Depth 4
Search-JavaHome -Path "D:\SDKs" -Depth 4 -Save
```

说明：

- 会检查根目录本身和子目录
- 返回识别到的 JDK 根路径
- 增加 `-Save` 后，会将搜索到的 JDK 自动写入本地映射
- `-Save` 自动生成 `Key`（基于目录名），冲突时自动追加序号（如 `jdk-21-2`）

## `Clear-JavaHome`

清空本地映射文件（支持 `-WhatIf` / `-Confirm`）。

示例：

```powershell
Clear-JavaHome -Confirm
```

## 4. Id 生成规则

`Id` 的目标是“稳定且足够唯一”，生成步骤：

1. 执行目标 JDK 的 `java -version`
2. 获取完整版本输出文本（stderr/stdout 统一收集）
3. 与规范化 `Path` 拼接为指纹字符串
4. 做 SHA-256，取前 16 位，前缀 `jdk-`

示例：

- `jdk-1f3a9b1c7d4e8a12`

## 5. 历史数据迁移说明

模块初始化时会自动执行迁移：

1. **优先处理当前 `javahome.csv`**  
   若内容为旧格式，会自动转换到 `Id/Key/Path`。

2. **当前文件不可用时尝试历史文件**  
   依次尝试：
   - `~/.jdks/javahome.txt`
   - `~/.jdks/javahome.properties`
   - `~/.jdks/jdk.csv`

3. **迁移前自动备份**  
   备份命名示例：
   - `javahome.csv.legacy.20260324121030.bak`

兼容的历史格式示例：

```text
jdk21,C:\Java\jdk-21
jdk17=C:\Java\jdk-17
jdk8:C:\Java\jdk1.8.0_202
```

## 6. 会话范围与持久化范围

- `Use-JavaHome` 对环境变量的修改仅影响**当前 PowerShell 会话**
- 映射数据写入 `~/.jdks/javahome.csv`，可跨会话复用

如果希望新开终端自动使用某个 JDK，请在你的 PowerShell profile 中调用：

```powershell
Use-JavaHome -Key jdk21
```

## 7. 常见工作流

1) 首次扫描并注册

```powershell
Search-JavaHome -Path "C:\Program Files\Java" -Depth 2
Search-JavaHome -Path "C:\Program Files\Java" -Depth 2 -Save
Set-JavaHome -Key jdk21 -Path "C:\Program Files\Java\jdk-21"
Set-JavaHome -Key jdk17 -Path "D:\SDK\jdk-17"
```

2) 日常切换

```powershell
Get-JavaHome
Use-JavaHome -Key jdk17
java -version
```

3) 删除无效记录

```powershell
Remove-JavaHome -Key old-jdk
```

## 8. 注意事项

- `Key` 不允许包含 `:`
- `Path` 必须是 JDK 根目录，不是 `bin` 目录
- 如果某路径无法执行 `java -version`，会降级使用占位版本字符串生成 `Id`
- `Clear-JavaHome` 会清空映射，请先确认是否需要保留历史记录

