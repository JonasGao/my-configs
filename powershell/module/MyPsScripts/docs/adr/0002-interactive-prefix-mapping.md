# 0002: 交互式前缀映射替代固定 GITHUB_HOME

用交互式 GitCloneMapping 取代 ADR-0001 的固定 `$GITHUB_HOME\<owner>\<repo>` 布局：映射持久化于 `$env:LOCALAPPDATA\MyPsScripts\clone-mappings.json`，克隆时按最长前缀匹配查找映射（键为从域名开始的 URL 段列表，值为本地绝对路径），完全匹配不到才进入交互询问——Out-GridView 选择映射层级，再确认目录名。模块仅在 Windows 使用。

在 2026-08-18 的 grill-with-docs 会话中逐项确认（见 `CONTEXT.md` 词汇表），写进 ADR 记录取舍：

- **放弃固定目录**：新增 codeup 等非 GitHub 平台后，单一 `$HOME\github` 不再成立；且企业内部 ID 段（如 `6098a93e58f98c96956644dc`）无意义，不值得进目录名。曾考虑"每平台一个环境变量"（GITHUB_HOME、CODEUP_HOME…），最终选通用映射——域名与深层前缀都可映射，用户自选层级，消除对平台数量的枚举。
- **最长前缀匹配、匹配到就静默执行**：任意命中即信任映射（用户以前定好的规则），不再二次确认；只有完全匹配不到才询问，避免打断高频克隆。
- **交互强制**：不提供参数绕过询问，未映射前缀必须在交互会话中解决。曾考虑 `-Mapping` 参数，为保持单一真相源（配置文件）而放弃。
- **存绝对路径**：不存 HOME 相对路径，移动/重装后映射失效由用户自行维护（可通过 `Set-GitCloneMapping` 修复）。
- **Out-GridView + 数字菜单回退**：GUI 选择直观，但非交互会话（计划任务、SSH）中 Out-GridView 不可用，检测到 `$host.UI` 不支持时回退数字菜单。
- **超集原则**：GitHub 简写 `owner/repo` 仍隐含 github.com，不因通用化而丢失 ADR-0001 的宽容解析；owner 与 repository 目录名统一小写约定原样保留。

supersedes ADR-0001。
