# MyPsScripts

个人 PowerShell 模块集：把散落的日常开发操作（Git 工作树、SSH、Maven、JDK 切换等）收敛成一组稳定的命令。Git 相关命令集中在 Git.psm1。

## Language

**Clone-GitRepo**:
把任意 Git 托管平台（GitHub、阿里云 codeup 等）的仓库克隆到本地统一目录的命令。克隆位置由交互式 GitCloneMapping 决定，而非固定家目录。
_Avoid_: Copy-GitRepository、Clone-GitRepository

**GitCloneMapping（克隆映射）**:
把 URL 前缀段列表映射到本地绝对路径的记录，持久化于 Windows 本地应用数据目录（`$env:LOCALAPPDATA\MyPsScripts\clone-mappings.json`）。克隆时按最长前缀匹配查找映射，匹配到则在该路径下建目录并克隆，完全匹配不到才进入交互询问。
_Avoid_: mapping、别名、快捷方式、GITHUB_HOME

**Prefix（前缀段）**:
URL 按 `/` 拆分的连续段列表，从域名开始（如 `["codeup.aliyun.com", "6098..."]`）。是 GitCloneMapping 的键。
_Avoid_: namespace、路径段

**Mapping Root（映射根目录）**:
GitCloneMapping 指向的本地绝对路径。命中映射后，剩余前缀段在此路径下逐级建目录。
_Avoid_: 家目录、GITHUB_HOME

**Host（域名）**:
仓库托管平台域名，URL 中第一段（github.com、codeup.aliyun.com 等）。短写形式 `owner/repo` 隐含 github.com。
_Avoid_: server、主机

**Owner（组）**:
仓库的属主，组织或用户。对 GitHub 是域名后第一段；对 codeup 等多级托管为域名后多个层级。作为目录时统一小写。
_Avoid_: 组织、团队、namespace

**Repository（代码库）**:
仓库名，URL 最后一段。克隆目标始终是映射根下逐级建目录后的最末层目录，目录名统一小写（URL 大小写保留给克隆地址本身）。
_Avoid_: 仓库名以外的叫法（repo、代码库统一写作 Repository）
