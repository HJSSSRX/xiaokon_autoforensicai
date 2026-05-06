# 团队协作指南

> 这份文档告诉每个团队成员：你要做什么、怎么做、做完了怎么交。

---

## 一、环境准备（所有人都要做）

### 第 1 步：克隆项目

```powershell
git clone https://github.com/HJSSSRX/xiaokon_autoforensicai.git forhacker
cd forhacker
```

### 第 2 步：装工具（功能测试组必须做，知识搬运组可跳过）

```powershell
.\install.ps1 -Check   # 先看看缺什么
.\install.ps1           # 一键安装
```

如果报错，截图发群里，不要自己瞎折腾。

### 第 3 步：同步知识库

```powershell
git clone https://github.com/HJSSSRX/autoforensicai_data.git ..\autoforensicai_data
Copy-Item -Recurse ..\autoforensicai_data\knowledge\* .\knowledge\ -Force
```

### 第 4 步：打开 AI 工具

用 Windsurf / Cursor / Claude Code 打开 `forhacker` 文件夹。
输入 **"小空自己动"**，AI 就会进入工作模式。

---

## 二、知识搬运组工作流程

你的任务：**找别人的题解博客 → 让 AI 帮你整理成标准格式 → 提交到知识库**

### 每周目标：5 篇知识卡片

### 具体步骤

#### 1. 找博客

去这些地方搜取证/CTF题解：
- CSDN 搜 "电子取证 writeup"
- 博客园搜 "CTF forensics"
- 知乎搜 "取证比赛"
- GitHub 搜 "ctf-writeup forensics"
- 先知社区、FreeBuf
- 各种比赛官方公众号

#### 2. 让 AI 结构化

把找到的文章链接或内容丢给 AI，说：

```
请把以下内容按照 knowledge/solved/_TEMPLATE.md 的格式整理成一个知识卡片。
要求：
1. tags 用英文
2. Solution Steps 里必须写出具体命令
3. Key Takeaways 总结可迁移的经验
4. 如果原文缺少具体命令，尽量补充

原文内容：
[粘贴博客内容或链接]
```

#### 3. 检查 AI 输出

重点看：
- [ ] 答案对不对？（和原文一致）
- [ ] 工具名写对了吗？（vol3 不是 volatility3，tshark 不是 wireshark）
- [ ] 命令能看懂吗？（看不懂就问 AI 解释）
- [ ] tags 合理吗？

#### 4. 保存文件

文件名规则：`来源_关键词.md`

例如：
- `2024fic_pve_虚拟化配置.md`
- `ctfshow_内存取证_进程分析.md`
- `buuctf_流量分析_dns隧道.md`

保存到 `knowledge/solved/` 目录。

#### 5. 提交

```powershell
cd forhacker
git add knowledge/solved/你的文件名.md
git commit -m "knowledge: 添加 XXX 题解"
git push
```

不会用 git 的话，直接把 .md 文件发给队长，队长帮你提交。

---

## 三、功能测试组工作流程

你的任务：**领一个功能模块 → 用 AI 工具去跑 → 记录结果 → 汇报**

### 具体步骤

#### 1. 从任务清单认领任务

见下方"任务清单"章节，或者队长在群里分配。

#### 2. 打开 AI 开始跑

用 Windsurf/Cursor 打开项目，把任务描述告诉 AI。例如：

```
我的任务是测试 kb_search.py 的搜索质量。
请帮我执行以下测试：
1. 用中文搜"内存取证"，看搜到了什么
2. 用英文搜"registry forensics"，看搜到了什么
3. 用工具名搜 --tools vol3，看搜到了什么
4. 记录每次搜索的结果数量和相关性
```

#### 3. 遇到问题

- AI 报错了 → 截图发群
- AI 做了但结果不对 → 记录下来，继续下一个
- 完全卡住了 → 跳过，做下一个任务

#### 4. 写报告

每个任务完成后，写一个简短报告（不需要很长）：

```markdown
## 任务：[任务名]
## 状态：完成 / 部分完成 / 卡住
## 做了什么
- ...
## 结果
- ...
## 遇到的问题
- ...
```

发给队长或提交到 `reports/` 目录。

---

## 四、Prompt 优化组工作流程

你的任务：**用已知答案的题测试 AI 行为 → 记录对错 → 改进 prompt**

### 具体步骤

1. 从 `knowledge/solved/` 里挑一道已有答案的题
2. 用"训练模式"让 AI 从头做这道题
3. 记录：AI 做对了哪些步骤？做错了哪些？在哪一步卡住了？
4. 分析原因：是 prompt 没说清楚？还是 AI 模型能力不够？还是缺工具？
5. 如果是 prompt 问题 → 修改 `prompts/` 下的相关文件
6. 用同样的题再跑一次 → 对比改进效果

### 记录格式

```markdown
## 测试日期：2026-05-07
## 测试题目：knowledge/solved/xxx.md
## 使用模型：Claude 3.5 / GPT-4 / 本地 XX
## 使用 prompt：prompts/roles/computer_analyst.md

### 结果
- Step 1: ✅ 正确
- Step 2: ✅ 正确
- Step 3: ❌ AI 用了错误的 vol3 插件名
- Step 4: ⚠️ 卡住，不知道下一步

### 分析
prompt 里没有提到 vol3 的插件命名规则，AI 猜错了。

### 修改
在 skills/computer/quick_reference.md 里补充了 vol3 常用插件列表。

### 修改后重测
- Step 3: ✅ 修复
```

---

## 五、任务清单

> 队长会持续更新这个清单。认领任务前先在群里说一声。

### 知识搬运任务（每人每周 5 篇）

| 编号 | 方向 | 说明 | 认领人 | 状态 |
|------|------|------|--------|------|
| K01 | 内存取证 | 找 5 篇内存取证题解（Volatility 相关） | | |
| K02 | Windows 取证 | 找 5 篇 Windows 注册表/事件日志题解 | | |
| K03 | 流量分析 | 找 5 篇流量分析题解（Wireshark/tshark） | | |
| K04 | 手机取证 | 找 5 篇 Android/iOS 取证题解 | | |
| K05 | Web 渗透 | 找 5 篇 Web 题解（SQL注入/文件上传/命令执行） | | |
| K06 | 隐写密码 | 找 5 篇隐写/密码学题解 | | |
| K07 | 磁盘取证 | 找 5 篇磁盘镜像分析题解（Autopsy/TSK） | | |
| K08 | 综合案例 | 找 3 篇完整比赛的全套题解（如长安杯、美亚杯） | | |

### 功能测试任务

| 编号 | 任务 | 说明 | 难度 | 认领人 | 状态 |
|------|------|------|------|--------|------|
| T01 | 测试 kb_search.py | 用 20 个不同关键词搜索，记录结果质量 | 低 | | |
| T02 | 测试 install.ps1 | 在干净电脑上运行，记录成功/失败的工具 | 低 | | |
| T03 | 测试 tool_status.py | 运行 --missing，补充缺失工具的安装方式 | 低 | | |
| T04 | 测试训练模式 | 用一道简单的已知题跑全自动训练，看能不能走完全流程 | 中 | | |
| T05 | 测试协作模式 | 开两个 AI 窗口分别扮演不同角色，看 shared/ 交换是否正常 | 中 | | |
| T06 | 扩充工具清单 | 搜集取证常用工具，让 AI 帮忙补充到 manifest.yaml | 低 | | |
| T07 | 测试灌知识模式 | 找一篇博客 URL，用灌知识模式导入，看能否自动结构化 | 中 | | |
| T08 | 整理过时文档 | 对比 DESIGN.md 和实际项目结构，标记哪些已过时 | 低 | | |
| T09 | 测试 LAN 协作 | 两台电脑用 collab_sync.py lan-serve 测试局域网同步 | 高 | | |
| T10 | 测试 E01 读取器 | 用 e01_reader.py 读取测试镜像，记录支持/不支持的格式 | 中 | | |

### Prompt 优化任务

| 编号 | 任务 | 说明 | 认领人 | 状态 |
|------|------|------|--------|------|
| P01 | 测试 computer_analyst prompt | 用 3 道已解决的磁盘取证题测试 | | |
| P02 | 测试 network_analyst prompt | 用 3 道已解决的流量分析题测试 | | |
| P03 | 测试 mobile_analyst prompt | 用 3 道已解决的手机取证题测试 | | |
| P04 | 测试主设计师分工能力 | 给一套多板块题目，看小空的分工是否合理 | | |
| P05 | 对比不同 AI 模型 | 同一道题同一个 prompt，用 Claude / GPT / 本地模型分别跑 | | |

---

## 六、提交规范

### 文件命名
- 知识卡片：`knowledge/solved/来源_关键词.md`
- 测试报告：`reports/T编号_任务名_日期.md`（队长建 reports/ 目录）
- Prompt 测试记录：`reports/P编号_prompt名_日期.md`

### Git 提交信息
- 知识卡片：`knowledge: 添加 XXX 题解`
- 测试报告：`report: T01 kb_search 测试结果`
- Prompt 修改：`prompt: 改进 computer_analyst 的 vol3 指引`

### 不会用 Git？
没关系。直接把文件发给队长，队长帮你提交。先把内容做出来最重要。

---

## 七、沟通约定

- **每天在群里发一句**：今天做了什么 / 明天打算做什么 / 有没有卡住
- **卡住了立刻说**，不要自己闷头卡三天
- **每 3 周开一次线上会**（30-45 分钟）：展示成果 + 讨论问题
