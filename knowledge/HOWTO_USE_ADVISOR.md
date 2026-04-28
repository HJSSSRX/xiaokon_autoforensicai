# AI 顾问操作指南

本套件帮你在 FIC 2026 现场用**廉价 AI（DeepSeek/通义千问）**接管"取证教练"角色，省 token、保隐私。

---

## 0. 一句话原理

`scripts/ask_advisor.py` = 关键词召回 `knowledge/wp_index/*.md` 里的历年题 → 拼成 prompt → 发给 DeepSeek API → 返回**指导**（不是答案）

**它不告诉你最终答案，它告诉你"怎么做"**。在比赛规则上更稳。

---

## 1. 一次性配置（5 分钟）

### 1.1 装依赖

```powershell
pip install requests
# 可选（中文分词更准）：
pip install jieba
```

### 1.2 拿 API Key（任选其一）

| 提供商 | 注册 URL | 价格（输入/输出，¥/M token） | 备注 |
|---|---|---|---|
| **DeepSeek** ⭐推荐 | https://platform.deepseek.com/ | 0.5 / 1.5（缓存 0.1） | 中文最强、最便宜 |
| 通义千问 | https://dashscope.console.aliyun.com/ | 0.8 / 2.0 | 阿里出品 |
| OpenAI | https://platform.openai.com/ | $0.15 / $0.60 (gpt-4o-mini) | 贵 5-10 倍 |

充值 ¥10 够你跑整场比赛 100+ 次咨询。

### 1.3 设环境变量（PowerShell 永久写入）

```powershell
[Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', 'sk-xxx你的key', 'User')
# 重开终端生效，或：
$env:DEEPSEEK_API_KEY = 'sk-xxx你的key'
```

---

## 2. 现场用法

### 2.1 标准三步

```powershell
# 1. 把题目原文丢进去
python E:\项目\自动化取证\scripts\ask_advisor.py "分析检材2，请找出嫌疑人微信聊天记录数据库的加密密钥"

# 2. 看输出：先列召回的相似历年题，再是 LLM 给出的 7 段式指导
# 3. 按指导操作；如果指导卡住，把"我试了 X 但 Y"再喂回去
```

### 2.2 快捷参数

```powershell
# 题目太长就读文件
python ask_advisor.py -f question.txt

# 只看知识库召回，不烧 token（验证 grep 是否命中）
python ask_advisor.py "题目" --no-llm

# 召回多一点（默认 5）
python ask_advisor.py "题目" --topk 10

# 换 LLM
python ask_advisor.py "题目" --provider qwen
```

### 2.3 离线 / API 不通时的"网页粘贴备份方案"

把 `--no-llm` 加上，脚本会打印**完整 prompt**（system + user）。复制粘贴到：

- DeepSeek 网页 https://chat.deepseek.com/
- Kimi https://kimi.moonshot.cn/
- 通义千问 https://tongyi.aliyun.com/

效果一样。

---

## 3. 知识库结构

```
knowledge/
├── HOWTO_USE_ADVISOR.md     ← 你正在看
├── README.md                ← 总说明
├── tools_cheatsheet.md      ← L1 工具速查
├── playbook/                ← L1 分类型套路（android/windows/...）
├── competitions/            ← L2 题型分类（不到题）
└── wp_index/                ← L3 精到题索引（NEW）
    ├── INDEX.md             ← 总目录
    ├── FIC-2024决赛.md
    ├── FIC-2025初赛.md
    ├── FIC-2025决赛.md
    ├── 平航杯-2025初赛.md
    ├── 盘古石-2025晋级赛.md
    ├── 美亚杯-2025资格赛.md
    └── 美亚杯-2024团队赛.md
```

每个 wp_index 文件用紧凑格式：
- 头部：来源 URL、检材构成、特色
- 中部：每题一行 `- Q<n> [关键词,关键词] 题面`
- 尾部：`高频套路（自总结）`

CLI 用关键词在中部 grep。

---

## 4. 关键词技巧（提高召回质量）

题目原文里如果包含这些词，召回会更准：

| 你打的词 | 命中类别 |
|---|---|
| `微信`/`wechat` | 微信题 |
| `pve`/`虚拟化` | PVE 平台题（FIC 招牌） |
| `smali`/`apk` | 安卓逆向 |
| `pcap`/`流量` | 网络取证 |
| `helm`/`raid`/`nas` | 存储题 |
| `助记词`/`钱包`/`mnemonic` | 虚拟货币 |
| `蓝牙`/`bluetooth` | 蓝牙取证 |
| `neo4j`/`图数据库` | neo4j SQL |
| `winpe`/`u盘`/`仿真` | WinPE 题 |
| `airdrop`/`ios` | iOS 取证 |

如果一题召回 0 条，先试 `--no-llm` 看是不是关键词不够；可以手工加几个词到题目里，比如：`"这道题关于 windows 微信加密密钥 pywxdump"`。

---

## 5. 给 LLM 顾问的"角色契约"

`scripts/ask_advisor.py` 的 `SYSTEM_PROMPT` 把 DeepSeek 锁成**教练**而不是答题者。它会：

1. **先识别题目归类**（检材+方向）
2. **指出召回的历年题与新题的差异**（防止生搬）
3. **给 3-5 步路径**（每步：工具+文件+字段）
4. **给可复制的命令/SQL**（不给最终值）
5. **提示常见坑**（编码/时区/繁简）
6. **给置信度**
7. **给 plan B**

如果你想换风格（比如更激进直接给猜测答案），改 `ask_advisor.py` 顶部的 `SYSTEM_PROMPT` 即可。

---

## 6. 添加新比赛 / 新题

抓到新 WP 后：

1. 在 `wp_index/` 下加一个 md 文件，**严格遵守紧凑格式**：
   ```
   # <比赛名>
   - **来源**：<URL>
   - **检材构成**：...
   - **特色**：...

   ## <分类>
   - Q1 [tag1,tag2,tag3] 题面...
   - Q2 ...

   ## 高频套路（自总结）
   1. ...
   ```
2. 在 `INDEX.md` 表格里追加一行
3. CLI 自动扫描 `wp_index/*.md`，**无需改代码**

关键词标签建议沿用 `INDEX.md` 里的体系，便于跨比赛召回。

---

## 7. 故障排查

| 现象 | 原因 | 解法 |
|---|---|---|
| `环境变量 DEEPSEEK_API_KEY 未设置` | 没设 key 或没重开终端 | `$env:DEEPSEEK_API_KEY=...` |
| `LLM 调用失败: 401` | key 错或欠费 | 去控制台查 |
| `LLM 调用失败: timeout` | 网络问题 | 加 `--no-llm` 用粘贴方案 |
| 召回 0 条 | 关键词太抽象 | 加具体名词进题目，或 `jieba` 分词 |
| 召回的全是无关题 | 题目里有 stopword 干扰 | 简化题目，只留核心名词 |

---

## 8. 实战示例

```powershell
> python ask_advisor.py "分析手机检材，找出微信数据库的加密密钥，手机已 root"

============================================================
知识库目录: E:\项目\自动化取证\knowledge\wp_index
召回 5 条历年题：
  [3] FIC-2025初赛.md: - Q8 [android,wechat,db-key] 嫌疑人微信聊天记录数据库的加密密钥是什么
  [3] FIC-2025初赛.md: - Q6 [android,wechat,db-name] 嫌疑人微信生成的聊天记录数据库文件名称
  [2] 美亚杯-2024团队赛.md: - Q11 [whatsapp,db,sticker-type] WhatsApp 数据库中表情包的 message_type
  ...
============================================================

## 题目识别
安卓手机微信取证 / 数据库加密密钥提取 / 已 root

## 匹配的历年题
- FIC-2025初赛 Q6+Q8 几乎同款（数据库名 + 加密密钥）。差异：本题是 2026 新题，可能微信版本更高（≥8.0.50 加密方式变了）

## 解题路径
1. 用火眼或 adb 拉取 `/data/data/com.tencent.mm/MicroMsg/<uin>/EnMicroMsg.db`
2. 拿 IMEI（拨号 *#06#）+ uin（在 `auth_info_key_prefs.xml`）
3. md5(imei + uin) 取前 7 位 = 数据库密码（旧版）
4. 新版（≥8.0.50）：sqlcipher v4 + key 来自 KeyStore，需要 frida hook
5. 用 PyWxDump / wechat-decipher 自动化

## 关键命令
adb shell "su -c cat /data/data/com.tencent.mm/shared_prefs/auth_info_key_prefs.xml"
python -m pywxdump db --db EnMicroMsg.db --imei <imei> --uin <uin>

## 常见坑
- IMEI 是 1234567890ABCDEF（默认值）时，密钥是空 md5
- uin 是有符号 int32，注意负数转换
- 新版微信用 wcdb，文件名是 `wxid_<id>/db/MSG0.db`

## 置信度：高
本套路 2020+ 一直稳定，FIC-2025 也是这个路径

## Plan B
如果 PyWxDump 失败，直接在内存 dump 里 grep `BEGIN MicroMsg`
```

---

**用得顺就改进；卡住就开 issue。Good hunt.**
