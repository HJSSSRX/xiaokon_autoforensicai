# 提案：本机端远程协作微调 v1

> **角色**：computer_analyst（小空协作子角色）
> **提交对象**：总设计师
> **提交时间**：2026-05-08
> **决策方式**：你在每条 §X 的"决策"段勾选 `Y / N / 改：...`，git pull 反馈即可

---

## 0. 背景

最近一次会话（2026FIC 计算机复盘）暴露出 **本机端协作的 4 类摩擦**：

| 摩擦 | 直接证据（本会话内发生） |
|---|---|
| **A. Hub 不可达** | `127.0.0.1:8765` 拒绝 + `172.21.161.2:8765` 超时；11 条 finding / 4 个 question 无处投递 |
| **B. Git 网络抖动** | `git pull framework master` → `RPC failed; curl 28 Recv failure: Connection was reset` |
| **C. 数据孤岛** | `D:\2026FIC` 是无远端的本地 git 仓，所有 artifacts/samples/answers 不在协作仓内，崩盘即丢 |
| **D. 仓库礼仪缺失** | `user.name=MXM` 而非角色名；每次 add 都报 LF→CRLF；commit message 格式不统一 |

本提案**只动本机端配置**，不改协议、不改 hub、不改远端仓结构。

---

## 1. 拓扑速览（当前实际形态）

```text
本地 F:\cloud\DD  (master 分支)
   ├── push framework master:main → github.com/HJSSSRX/xiaokon_autoforensicai   框架/工具/通用技能
   ├── push data      master:main → github.com/HJSSSRX/autoforensicai_data      案件数据/复盘/worklog
   └── hub server   http://...:8765                                              准实时 finding/question/progress
                                                                                 ❌ 当前不可达

D:\2026FIC  (孤岛 master 分支，无 remote)
   └── artifacts/, samples/, *.md   ← 所有做题产出在此，不进协作仓
```

仓库职责切分（已确立的约定，本提案不变更）：

| 路径 | 推送目的地 | 内容 |
|---|---|---|
| `cases/<case>/` | data | 案件复盘、答案、证据链 |
| `worklog/` | data | 会话日志（按日期+序号+主题） |
| `knowledge/` | framework | 通用技能、卡片、wp_index、已解题集 |
| `prompts/`, `tools/`, 顶层 *.md | framework | 项目规则、工具、prompt |

---

## 2. 五项微调

### 微调 ① 角色身份 + commit 模板

**痛点**：`user.name=MXM`，每次手动 `git -c user.name='computer_analyst' commit ...`；commit message 格式漂移。

**做法**：本机本仓 local 配置（不污染全局）+ 一份 `.gitmessage` 模板。

```powershell
git -C F:\cloud\DD config user.name  'computer_analyst'
git -C F:\cloud\DD config user.email 'computer-analyst@xiaokong.local'
git -C F:\cloud\DD config commit.template '.gitmessage'
```

`.gitmessage` 内容（受 conventional commits 启发，新增 `case`/`refs`/`blocked` 字段）：

```text
<type>(<scope>): <subject>

# type:    docs / feat / fix / refactor / chore / case
# scope:   2026FIC / 2025平航杯 / framework / role-name
# refs:    F-C001  Q005  hub:offline
# blocked: -
```

**收益**：commit author 即角色名，远端可直接区分谁做了什么；message 可被 grep。
**风险**：极低；本机 local 配置可随时回退。
**决策**：`Y / N / 改：___`

---

### 微调 ② `.gitattributes` 防 LF/CRLF + 大文件熔断

**痛点**：每次 add 报 `LF will be replaced by CRLF`；`vc.bin` (10 MB) `.E01` (GB级) 一旦误推就把仓库撑炸。

**做法**：新增 `.gitattributes`（团队共享、git 自动应用）：

```gitattributes
* text=auto eol=lf

# 二进制白名单（不做行尾转换）
*.png  binary
*.jpg  binary
*.jpeg binary
*.gif  binary
*.pdf  binary
*.zip  binary
*.7z   binary

# 大文件熔断（Git LFS）
*.bin  filter=lfs diff=lfs merge=lfs -text
*.E01  filter=lfs diff=lfs merge=lfs -text
*.vhd  filter=lfs diff=lfs merge=lfs -text
*.vhdx filter=lfs diff=lfs merge=lfs -text
*.iso  filter=lfs diff=lfs merge=lfs -text

# samples/ 整目录强制非文本（保险起见）
artifacts/samples/** -text
**/samples/** -text
```

**收益**：彻底消除 LF/CRLF 警告；二进制大文件即使误 add 也走 LFS。
**风险**：需要 `git lfs install`（一次性）；未装 LFS 的协作者 clone 时 LFS 文件占位。
**决策**：`Y / N / 改：___`（含是否启用 LFS）

---

### 微调 ③ 网络抖动加固

**痛点**：`curl 28 RPC failed Recv reset`，github 大 push 易断。

**做法**：

```powershell
git -C F:\cloud\DD config http.postBuffer    524288000   # 500MB push 缓冲
git -C F:\cloud\DD config http.lowSpeedLimit 1000        # <1 KB/s 视为掉线
git -C F:\cloud\DD config http.lowSpeedTime  60          # 持续 60s 才放弃
git -C F:\cloud\DD config remote.framework.proxy ''      # 显式清代理（如本地有 proxy 干扰）
git -C F:\cloud\DD config remote.data.proxy      ''
```

**收益**：大 commit / 文档批量 push 不再轻易断。
**风险**：无；纯本机 git 行为参数。
**决策**：`Y / N / 改：___`

---

### 微调 ④ Hub 离线降级 — 用 git 当 inbox

**痛点**：hub 不可达时，finding/question/progress 无处去；本会话 11 条 finding + 4 个 question 至今未投递。

**做法**：每个 case 加一个 inbox 树，schema 与 hub HTTP body 1:1：

```text
cases/2026FIC/
├── inbox/
│   ├── findings/
│   │   ├── F-C001.json
│   │   ├── F-C002.json
│   │   └── ...
│   ├── questions/
│   │   ├── Q-C001.json
│   │   └── QQ005-reply.json
│   ├── progress/
│   │   └── computer_analyst.json   # 最新覆盖
│   └── _SYNCED.txt                 # 已被 hub 接收的 ID 列表（每行一个）
```

**示例 `F-C001.json`**：

```json
{
  "id": "F-C001",
  "from": "computer_analyst",
  "type": "evidence",
  "summary": "vc 16-char 候选 PC 全盘 dump 完成 SHA1 全 miss",
  "details": "34526 个候选, 见 artifacts/candidates_16char_verified.txt",
  "confidence": "high",
  "related_to": ["binary_analyst", "stego_crypto"],
  "source": "computer_image",
  "ts": "2026-05-08T14:50+08:00"
}
```

配套一个 10 行的 `tools/hub_replay.py`（hub 上线时跑一次）：

```text
读 cases/*/inbox/**/*.json - _SYNCED → POST 到 hub → append _SYNCED
```

**收益**：协作不再硬依赖 hub 在线；总设计师 `git pull` 即看到所有 finding/question；hub 上线后单脚本回放。
**风险**：路径冲突（多角色同名 ID）— 用 `F-<role-prefix>NNN` 命名空间约定即可。
**决策**：`Y / N / 改：___`

---

### 微调 ⑤ 解决 `D:\2026FIC` 数据孤岛（最重要也最大动作）

**痛点（最严重）**：`D:\2026FIC` 是无远端的本地 git 仓，所有做题产物（artifacts/、samples/、answers_final.md、HANDOFF_v3.md 等约 80 个脚本/数据文件）不在协作仓内：

- D 盘崩盘 → 全没
- 总设计师 `git pull` 看不到原始证据链
- 跨工作区检索（kb_search/grep）无法跨盘扫

**三选一**：

| 方案 | 操作 | 优势 | 代价 |
|---|---|---|---|
| **A. 全迁入** | `D:\2026FIC\*` → `F:\cloud\DD\cases\2026FIC\workspace\`（除 E01 / vc.bin / 大 sample） | 单仓自包含；总设计师能看全；自动备份到远端 | 改路径，旧脚本要 grep 替换 `D:\\2026FIC` → 新路径 |
| **B. git worktree** | `git -C F:\cloud\DD worktree add D:\2026FIC case-2026FIC` | 路径不动；共享 .git 历史 | 学习曲线稍陡；分支管理复杂；两边都要 commit |
| **C. 软链** | `cases\2026FIC\workspace` → `D:\2026FIC` (`mklink /D`) + `.gitignore` 大文件 | 零改动 | Windows 跨盘符软链脆弱；commit 行为反直觉；CI/远端拉取仍看不到 |

**强烈推荐 A（全迁入）**：

- 一次性付清，长期收益最大
- 大文件（E01、vc.bin、`samples/*`）走 § ② 的 `.gitattributes` LFS 或 `.gitignore` 排除
- 旧脚本里的 `D:\\2026FIC` 路径 sed 替换一次
- 提案：保留 D 盘 7 天作为应急 fallback，期间双写；7 天后归档为 `.zip` 备份

**收益**：消除孤岛；总设计师能看到原始 artifacts/scripts；本机崩盘风险归零。
**风险**：路径迁移有 ~80 个脚本要改；Windows 长路径（260 字符限制）需开 `core.longpaths=true`。
**决策**：`A / B / C / 暂缓 / 改：___`

---

## 3. 取舍 — 不做的事

明确**拒绝**以下"看似优化但代价过高"的方案：

| 拒绝项 | 理由 |
|---|---|
| ❌ 引入 git hooks 自动 push | 与"等总设计师 review"语义冲突 |
| ❌ submodule | 双 remote 已满足，submodule 反增心智 |
| ❌ CI/CD pipeline | 本机协作场景过重 |
| ❌ 每个角色独立分支 | master 单分支足够；多角色改不同子目录基本无冲突 |
| ❌ 切换到 SSH 远端 | 当前 https 已可用，curl 28 是 GFW/抖动问题，换协议解决不了 |
| ❌ 自建 hub mirror | 离线 inbox（§ ④）已足够 fallback |

---

## 4. 决策表（请勾选）

| # | 微调项 | 决策 | 备注 |
|---|---|---|---|
| ① | 角色身份 + commit 模板 | `Y / N / 改` | |
| ② | `.gitattributes` LF + LFS 熔断 | `Y / N / 改` | 是否启用 LFS：`Y / N` |
| ③ | http.postBuffer + 网络抖动加固 | `Y / N / 改` | |
| ④ | hub 离线降级 inbox | `Y / N / 改` | 是否需要我同时写 `tools/hub_replay.py`：`Y / N` |
| ⑤ | D:\2026FIC 数据孤岛 | `A / B / C / 暂缓` | 双写期：默认 7 天 / 改：___ |

**额外一票**：是否把本提案的 §2.① §2.③ 内容追加到 `COLLABORATION_GUIDE.md`：`Y / N`

---

## 5. 一旦决策完成 — 执行命令清单（可直接 copy 跑）

我会在你勾选后写成一个 `tools/apply_local_tuning.ps1`，覆盖以下步骤（按你勾选的项裁剪）：

```powershell
# ① 身份
git -C F:\cloud\DD config user.name  'computer_analyst'
git -C F:\cloud\DD config user.email 'computer-analyst@xiaokong.local'
git -C F:\cloud\DD config commit.template '.gitmessage'

# ② attributes
# (写 .gitattributes 文件 + git lfs install)

# ③ http
git -C F:\cloud\DD config http.postBuffer    524288000
git -C F:\cloud\DD config http.lowSpeedLimit 1000
git -C F:\cloud\DD config http.lowSpeedTime  60

# ④ inbox 目录骨架
mkdir cases/2026FIC/inbox/findings, cases/2026FIC/inbox/questions, cases/2026FIC/inbox/progress

# ⑤A 迁入（仅当选 A）
robocopy D:\2026FIC F:\cloud\DD\cases\2026FIC\workspace /E /XD .git /XF *.E01 *.bin
git -C F:\cloud\DD config core.longpaths true
# 之后跑一次 grep -rl 'D:\\2026FIC' --include=*.py --include=*.sh | xargs sed -i 替换路径
```

---

## 6. 时间预算

| 项 | 工时 |
|---|---|
| ①+②+③+④ 全套 | ~25 分钟 |
| ⑤A 迁入 + 路径替换 + 验证 | ~45 分钟 |
| **合计** | **≤ 1.5 小时** |

---

## 7. 我等你回复后做的事

1. 按你勾选的项写 `tools/apply_local_tuning.ps1`
2. 自己跑一遍验证（用本仓 commit/push 一次小文件）
3. 写 worklog `2026-05-08_02_*.md` 记录变更
4. 把通过的微调提级到 `COLLABORATION_GUIDE.md`（如你勾选）

不擅自执行任何 §2 微调，等你回复。

---

## 8. v1.1 实施跟踪 — 提前落地的 3 项低风险增强

> 本节由 computer_analyst 在 2026-05-08 20:30 加入（用户口头批准"全做"后）。
> 不属于 §2 ①-⑤ 主菜单。这 3 项是 §2 ① 强化 + §2 ③ 网络部分子集 + 新增的 ⑥ DNS 劫持检测。
> 主菜单 §2 ②④⑤（`.gitattributes` LFS / hub inbox / D:\ 数据迁入）**未实施**，仍等总设计师 §4 决策。

### 8.1 已落地

| # | 产物 | 路径 | 关联 §2 项 |
|---|---|---|---|
| ⑥ | Watt Toolkit / DNS 劫持检测 | `tools/check_net.ps1` | 新增（§3 也提到，原未编号） |
| ① 强化 | Git author 防呆 hook | `.githooks/pre-commit` + `tools/install_hooks.ps1` | §2 ① 进阶版 |
| ⑦ | xiaokon-all 一键同步 | `tools/sync_xiaokon-all.ps1` | 整合 ⑥ + 标准化 fetch/merge/push |

### 8.2 触发本次实施的具体证据

merge commit `5ce84eb` 因 `user.name=MXM` 漏配，author 被打成 Windows 用户名而非 `computer_analyst`，已不可逆地落入公共历史。
用户决策 A（不动远程，只修配置）后，需要"机制层防呆"防止再次发生 → 直接催生 §8.1 的 hook 落地。

### 8.3 各产物行为

**`tools/check_net.ps1`**

- `Resolve-DnsName github.com -Type A`，若返回 `127.x` / `::1` / `0.0.0.0` 视为劫持
- 退出码：`0` 干净 / `1` 劫持（需 schannel）/ `2` DNS 不通
- 干净时静默；异常时 stderr-styled 输出

**`.githooks/pre-commit`（POSIX sh）**

- 黑名单 `user.name`：`""`、`MXM`、`Your Name`、`root`、`Administrator`、`User`、`git`
- 命中即 reject（exit 1），输出修复指引
- `email` 为常见默认值时 warn-only，不阻拦
- 一次性绕过：`GIT_BYPASS_AUTHOR=1 git commit ...`
- 通过 `tools/install_hooks.ps1` 设置 `core.hooksPath=.githooks` 一次性激活，新 clone 需各自跑一次

**`tools/sync_xiaokon-all.ps1`**

- 5 步：网络预检 → 工作树/分支检查 → fetch → merge --no-ff（冲突自动 abort）→ push
- 网络劫持时自动加 `-c http.sslBackend=schannel`
- 支持 `-NoPush`（只拉不推）和 `-DryRun`（只看不动）

### 8.4 验证记录（本次会话现场跑）

| 测试 | 命令 | 期望 | 实际 |
|---|---|---|---|
| install_hooks 幂等 | `install_hooks.ps1` | `core.hooksPath=.githooks` 设置成功，列出 hook | ✓ |
| check_net 正常网络 | `check_net.ps1` | exit 0，github.com 解析到公网 IP | ✓ `20.205.243.166` |
| pre-commit 拦 MXM | `git -c user.name=MXM commit --allow-empty` | reject，HEAD 不变 | ✓ HEAD 仍为 5ce84eb |
| sync 脚本端到端 | `sync_xiaokon-all.ps1` | 干净 working tree → fetch → push | （本 commit 完成后跑） |

### 8.5 与原 §2 主菜单的关系 / 反悔预案

如总设计师 §4 决策与 §8 冲突：

- §2 ① 选 `N`（不要角色身份配置）：删 `.githooks/pre-commit`，运行 `git -C . config --unset core.hooksPath`，删两个 ps1 脚本即可彻底 revert
- §2 ③ 选 `N`（不要网络抖动加固）：本节 §8 的 `check_net.ps1` 仍可独立保留，仅做"探测+提示"不改 git 行为
- 若你在 §4 给出与本节命名/路径不同的方案，本节的 3 个文件可改名/移动/删除

### 8.6 后续计划

- 等你 push 你的审批结果，merge 进来后看 §4 决策
- 按 §4 决策补做 §2 剩余项目（②③④⑤），合到 `tools/apply_local_tuning.ps1` 中
- 通过的微调按 §7-4 提级到 `COLLABORATION_GUIDE.md`
