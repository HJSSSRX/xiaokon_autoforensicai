# 人类操作手册

> 给拿到这个包的人类看的。假设你有 Windows + WSL2 + Windsurf IDE。

---

## 0. 先决条件

- Windows 10/11，已启用 WSL2
- WSL 中已安装 Ubuntu 22.04 或 24.04
- Windsurf IDE（有 Claude 模型访问权限）
- Git

## 1. 环境诊断（2 分钟）

在 PowerShell 中运行：

```powershell
.\share\install\00_diagnose.ps1
```

脚本会检查：
- WSL 是否可用、版本号
- Python 版本
- 磁盘剩余空间
- 代理连通性（可选）
- 已安装的关键工具

输出一份报告，告诉你还缺什么。

## 2. 安装工具链（10 分钟）

### WSL 端

```bash
# 在 WSL Ubuntu 中执行
bash /mnt/<drive>/项目/自动化取证/share/install/01_install_wsl_tools.sh
```

安装内容：
- sleuthkit, ewf-tools（磁盘分析）
- sqlite3, sqlcipher（数据库）
- jadx（APK 反编译）
- radare2（PE 逆向）
- python3 + venv + pycryptodome + sqlcipher3
- exiftool, 7z, ripgrep, jq
- btrfs-progs, lvm2（文件系统）

### Windows 端（可选）

```powershell
.\share\install\02_install_win_tools.ps1
```

安装内容：
- 7zip
- Arsenal Image Mounter 提示（手动下载）

## 3. 开始新比赛

### 方法 A：从骨架复制

```powershell
# 复制骨架到新比赛目录
Copy-Item -Recurse .\share\skeleton\ .\my_new_contest\
cd .\my_new_contest\
git init
```

### 方法 B：在已有项目中使用

把 `share/skeleton/` 下的文件合并到你的项目即可。关键目录：
- `AI_BRAIN/` — AI 大脑（必须）
- `.windsurf/rules/` — 项目规则（必须）
- `knowledge/` — 知识库（推荐）

## 4. 在 Windsurf 中启动 AI

1. 用 Windsurf 打开项目目录
2. 打开 Cascade 面板
3. 第一句话给 AI：

```
请读 AI_BRAIN/README.md，然后按开场流程初始化。
比赛名称：<你的比赛>
模式：SOLO（或 COOP / TEAM）
```

AI 会自动：
- 读取大脑索引
- 加载工作风格
- 检查上次进度
- 向你确认就绪

## 5. 比赛中的工作流

```
你（读题 + 分配优先级）
  ↓
AI（执行分析 + 输出 WP）
  ↓
你（确认答案 + 填写提交系统）
  ↓
AI（更新进度 + 写 session_handoff）
```

### 常用斜杠命令

| 命令 | 功能 |
|------|------|
| `/case-start` | 新比赛开始标准流程 |
| `/case-solo` | SOLO 快速模式 |
| `/case-coop` | COOP 协作模式 |
| `/env-check` | 环境健康检查 |
| `/team-sync` | TEAM 模式 Git 同步 |
| `/wp-report` | 生成 WP 批次报告 |

## 6. 赛后复盘

比赛结束后，告诉 AI：

```
比赛已结束，得分 XXX/YYY，进入复盘模式。
```

AI 会生成：
- 复盘报告（RETROSPECTIVE.md）
- 教训总结（LESSONS_LEARNED.md）
- 答案索引（INDEX.md）
- 新的解题套路（solved_patterns/）

## 7. FIC2026 参考案例

`share/reference_case/` 目录包含完整的 FIC2026 复盘，可作为学习参考：

| 文件 | 内容 |
|------|------|
| `RETROSPECTIVE.md` | 总复盘（成绩/成功路径/失误分析） |
| `LESSONS_LEARNED.md` | 13 条可迁移教训 |
| `questions.md` | 52 道题目原文 |
| `wp_batches/*.md` | 7 个 WP 批次（含完整解法） |

---

## FAQ

**Q: 我不是用 Claude，能用吗？**
A: 理论上可以。AI_BRAIN 的设计是模型无关的，但 `.windsurf/rules/` 和 workflows 是 Windsurf 专属。换其他 IDE 需要手动适配规则加载方式。

**Q: 检材在哪？**
A: 检材不包含在本包中。你需要自行获取比赛检材并挂载到 WSL 中（通常用 `mount -o loop` 或 Arsenal Image Mounter）。

**Q: 能用在 CTF 中吗？**
A: 可以。取证 CTF 和正式比赛的题型高度重叠。把 `questions.md` 换成你的题目即可。
