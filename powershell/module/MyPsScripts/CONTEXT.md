# MyPsScripts

个人 PowerShell 模块集：把散落的日常开发操作（Git 工作树、SSH、Maven、JDK 切换等）收敛成一组稳定的命令。Git 相关命令集中在 Git.psm1。

## Language

**Clone-GitRepo**:
把 GitHub 仓库克隆到本地统一目录的命令。只接受 GitHub 仓库地址，非 GitHub 主机直接报错。
_Avoid_: Copy-GitRepository、Clone-GitRepository

**GITHUB_HOME**:
GitHub 仓库的本地家目录环境变量。未配置时默认为 `$HOME\github`。
_Avoid_: GITHUB_DIR、GIT_REPOS_ROOT

**Owner（组）**:
GitHub 仓库的属主，可以是组织或用户，即 URL 中 `github.com` 后第一段。克隆时作为 `GITHUB_HOME` 下的子目录，目录名统一小写。
_Avoid_: 组织、团队、namespace

**Repository（代码库）**:
GitHub 仓库名，即 URL 中 `github.com` 后第二段。克隆目标为 `GITHUB_HOME\<Owner>\<Repository>`，目录名统一小写（URL 大小写保留给克隆地址本身，仅目录名小写）。
_Avoid_: 仓库名以外的叫法（repo、代码库统一写作 Repository）
