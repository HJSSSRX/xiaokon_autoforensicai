# ForensicAI — OpenClaw (小龙虾) 适配指南

> 请先阅读 `AGENTS.md` 作为通用入口。

## OpenClaw 专用启动方式

OpenClaw 不支持文件式 system prompt，需通过以下方式激活：

### 方式一：Dashboard 聊天中发送触发词

在 OpenClaw Web 界面或终端中发送：

```
小空你自己动
```

然后复制粘贴以下内容（作为第一条系统消息）：

```
你是 ForensicAI (小空自己动)，一个专注于电子数据取证的 AI 助手。

请立即执行以下启动序列：
1. 读取当前项目目录下的 AGENTS.md 文件
2. 读取 AI_BRAIN/persona.md
3. 读取 AI_BRAIN/output_contract.md
4. 读取 knowledge/taxonomy.yaml
5. 然后问我：要以什么模式开始？（competition / training / education / review）

项目目录：/mnt/e/项目/自动化取证
注意：所有对话用简体中文，代码注释用英文。
```

### 方式二：创建 OpenClaw Skill（自动化）

在 OpenClaw Dashboard 中创建 Skill：

1. 点击左侧 "Skills"
2. 新建 Skill，命名为 "forensicai_startup"
3. 填入以下 prompt：

```
当用户说"小空你自己动"或"小空开始吧"时：
1. 读取 /mnt/e/项目/自动化取证/AGENTS.md
2. 读取 /mnt/e/项目/自动化取证/AI_BRAIN/persona.md
3. 读取 /mnt/e/项目/自动化取证/AI_BRAIN/output_contract.md
4. 读取 /mnt/e/项目/自动化取证/knowledge/taxonomy.yaml
5. 询问用户 session mode（competition/training/education/review）
6. 加载对应 strategies/*.yaml
```

### 方式三：终端快速启动（TUI 模式）

在终端中运行：
```bash
openclaw chat
```

然后粘贴上述 "方式一" 的系统提示词即可激活。

## 模型切换

| 场景 | 命令 |
|------|------|
| 日常/快速 | `/model deepseek/deepseek-v4-flash` |
| 深度分析 | `/model deepseek/deepseek-v4-pro` |
| 思维链推理 | `/model deepseek/deepseek-reasoner` |

## 与 Windsurf/Cursor 的差异

| 特性 | Windsurf | OpenClaw |
|------|----------|----------|
| 触发词 | 自动识别 | 需手动粘贴系统提示 |
| 文件读取 | 自动 | 需明确告知路径 |
| 持久化 | 单会话 | 跨会话记忆（memory-core）|
| 心跳检查 | 无 | 每30秒自动检查任务 |

## 注意事项

1. **workspace 已配置**为 `/mnt/e/项目/自动化取证`，所有相对路径基于此
2. **模型默认**为 `deepseek/deepseek-v4-flash`
3. **成本**约 $0.28/百万 tokens（Flash 模型）
4. OpenClaw 的 system prompt 不可持久化，每次新会话需重新粘贴

## 性能对比记录

见 `worklog/benchmark_openclaw_deepseek.md`
