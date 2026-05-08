# 远程机 AI Agent 同步提示词模板

使用方法: 把下方【发送给 AI】里的内容完整复制，粘贴到远程机上的 AI 对话框，
把 [PAT] / [ROLE] / [HUB_IP] / [PROJECT_PATH] 替换成实际值后发送。

---

## 需要填入的变量

| 占位符 | 说明 | 例子 |
|---|---|---|
| `[PAT]` | GitHub Personal Access Token (找主机要) | `github_pat_11ABCDE...` |
| `[ROLE]` | 本机角色名 | `computer_analyst` 或 `mobile_analyst` |
| `[HUB_IP]` | 主机局域网 IP (主机 ipconfig 查 IPv4) | `192.168.1.100` |
| `[PROJECT_PATH]` | 本机项目目录 | `E:\项目\自动化取证` |

---

## 【发送给 AI】完整提示词 ↓ (复制下面全部内容)

```
你是一名计算机取证 AI，角色为 [ROLE]。

你的首要任务是在本机完成以下 4 步同步操作，然后继续取证分析。
立即开始，不要回复"好的"，直接执行。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
步骤 1 — 修复 Git 凭据 (PAT 认证)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

在 [PROJECT_PATH] 目录下执行:

git remote set-url all https://HJSSSRX:[PAT]@github.com/HJSSSRX/xiaokon-all.git
git remote set-url origin https://HJSSSRX:[PAT]@github.com/HJSSSRX/xiaokon-all.git

验证: git remote -v  → 确认 URL 含 PAT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
步骤 2 — 推送本机现有进度
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cd [PROJECT_PATH]
git add -A
git status   # 查看改动文件
git diff --stat HEAD   # 确认有无实质内容

# 如果有改动:
git commit -m "remote/[ROLE]: 同步本机进度 (2026FIC)"
git push all main

# 如果推送报冲突 (non-fast-forward):
git pull all main --rebase
git push all main

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
步骤 3 — 拉取主机最新框架
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

git pull all main
git log --oneline -5   # 确认看到 "854a27c docs: REMOTE_SYNC_GUIDE"

如果有冲突, 规则:
- tools/*.py / docs/*.md → 接受主机版本: git checkout --theirs <文件>
- knowledge/solved/*.md → 保留本机版本: git checkout --ours <文件>
然后: git add -A && git commit -m "merge: 接受主机框架" && git push all main

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
步骤 4 — 更新 Hub 连接配置
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

打开 [PROJECT_PATH]/tools/role_log.py，找到:
  HUB_URL = "http://127.0.0.1:8765"
改为:
  HUB_URL = "http://[HUB_IP]:8765"

保存，测试:
  python [PROJECT_PATH]/tools/role_log.py   # 如果输出 "Hub 连接正常" 则成功

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
步骤 5 — 同步完成后继续取证
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

同步完成后，立即打开并阅读以下文件，继续上次的分析工作:

1. 你的角色提示词:
   [PROJECT_PATH]/../2026FIC团体赛/case/role_prompt_[ROLE]_v4.md   (如果存在)
   否则读: [PROJECT_PATH]/../2026FIC团体赛/case/role_prompt_[ROLE].md

2. 当前答案进度:
   [PROJECT_PATH]/../2026FIC团体赛/case/shared/answers.yaml

3. 知识库速查手册:
   [PROJECT_PATH]/knowledge/skills/<你的专业>/quick_reference.md

读完后:
- 找出 answers.yaml 里 answer 字段为空的题目
- 从编号最小的未答题开始继续分析
- 每解出一题立即调用 log_answer() 上报到 Hub

新工具 (本次更新):
- tools/answer_format_lint.py — 校验答案格式
  python [PROJECT_PATH]/tools/answer_format_lint.py
- tools/parse_questions.py — 如需解析题目

不要回复，直接开始执行步骤 1。
```

---

## 发送给 computer_analyst 机 (示例, 填好变量的版本)

把上面 [ROLE]=computer_analyst, [HUB_IP]=主机IP, [PAT]=实际token 替换好后发送即可。

## 发送给 mobile_analyst 机

把 [ROLE]=mobile_analyst 替换即可，其他相同。
