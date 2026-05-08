# 远程机同步指南 (2026FIC)

适用: `computer_analyst` 机 / `mobile_analyst` 机 (及任何新加入的角色机)

---

## 一、为什么 git push 失败?

GitHub 从 **2021-08-13** 起停用密码认证。
`git push` 时输入的是密码 → GitHub 直接拒绝。

**必须使用 PAT (Personal Access Token)** 代替密码。

---

## 二、一次性修复 (在远程机上执行)

### 步骤 1 — 获取 PAT

找主机 (小空/主设计师) 要一个 PAT。PAT 在主机的 GitHub 账号里生成:
> GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
> → Generate new token → Repository: `xiaokon-all` → Permissions: Contents = Read and Write
> → 生成 → 复制这个 token (只显示一次!)

PAT 长这样: `github_pat_11ABCDEF_xxxxxxxxxxxxxxxxxxxxxxxx`

### 步骤 2 — 配置凭据 (Windows 远程机)

```powershell
# 方法 A: 用 Windows Credential Manager 存储 (推荐, 只做一次)
git credential-manager configure
# 然后执行任意一次 git push, 弹出登录框时:
#   用户名 = 你的 GitHub 用户名 (HJSSSRX)
#   密码   = PAT (不是 GitHub 密码!)

# 方法 B: 直接把 PAT 写进 remote URL (临时方案)
git remote set-url origin https://HJSSSRX:<PAT>@github.com/HJSSSRX/xiaokon-all.git
git remote set-url all    https://HJSSSRX:<PAT>@github.com/HJSSSRX/xiaokon-all.git
```

### 步骤 3 — 验证

```powershell
git push all main
# 如果成功: "Everything up-to-date" 或 "main -> main"
# 如果失败: 把报错截图发给主机
```

---

## 三、同步工作流 (每次比赛/测试前)

### 本次同步 (先拉后推)

```powershell
# 1. 进入项目目录
cd E:\项目\自动化取证   # 或你的路径

# 2. 拉最新 (主机已推 32067fc, 包含 CDE 方案)
git pull all main

# 3. 确认版本
git log --oneline -5
# 应看到: 32067fc CDE: C2 parse_questions + C3 answer_format_lint...

# 4. 推自己本机的改动 (如果有)
git add -A
git commit -m "remote/<角色名>: 同步本机进度"
git push all main
```

### 如果有冲突

```powershell
# 查看冲突文件
git status

# 对于 tools/*.py / docs/*.md: 接受 all/main 版本 (主机优先)
git checkout --theirs tools/
git add tools/

# 对于 knowledge/solved/*.md: 保留自己版本 (各机独立知识)
git checkout --ours knowledge/solved/
git add knowledge/solved/

git commit -m "merge: 接受主机框架, 保留本机知识"
git push all main
```

---

## 四、case 目录同步 (单独的 Git 仓库)

`case/` 目录 (`E:\ffffff-JIANCAI\2026FIC团体赛\case\`) 是独立仓库。
同步方式相同, 但 remote 可能不同:

```powershell
cd "E:\ffffff-JIANCAI\2026FIC团体赛\case"
git remote -v          # 查看当前 remote
# 如果没有 remote, 添加:
git remote add all https://HJSSSRX:<PAT>@github.com/HJSSSRX/xiaokon-all.git
# 注意: case 目录内容较敏感 (含答案), 确认主机允许后再 push
```

---

## 五、比赛现场 Hub 通信

Hub 运行在**主机** (`computer_analyst` 机) 的 `127.0.0.1:8765`。
远程机连接时要用**主机的局域网 IP**, 不是 127.0.0.1。

```powershell
# 在 role_log.py 里改 HUB_URL:
# 默认: HUB_URL = "http://127.0.0.1:8765"
# 改为: HUB_URL = "http://192.168.x.x:8765"   ← 主机的局域网 IP

# 查主机局域网 IP:
ipconfig | findstr "IPv4"
```

---

## 六、新工具 (本次更新 32067fc)

| 文件 | 用途 | 谁用 |
|---|---|---|
| `tools/parse_questions.py` | 粘贴题目 → 生成结构化数据 | 主机 (比赛前) |
| `tools/answer_format_lint.py` | 检查答案格式是否合规 | 任何角色机 |
| `tools/captain.py` | 主机态势板 (含格式 lint) | 主机 |
| `knowledge/skills/binary/quick_reference.md` | Binary 取证速查手册 | binary_analyst 机 |
| `knowledge/skills/server/quick_reference.md` | Server 取证速查手册 | server_analyst 机 |

```powershell
# 安装新依赖 (如果 lint 需要 pyyaml)
pip install pyyaml
```
