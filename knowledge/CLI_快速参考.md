# AI 顾问 CLI 快速参考

> 一页纸速查表。详细教程见 `HOWTO_USE_ADVISOR.md`。

---

## 最常用：3 条命令

```powershell
# 1. 直接问（题目短）—— 自动保存到 output/*.md 并用默认程序打开
python E:\项目\自动化取证\scripts\ask_advisor.py "题目原文"

# 2. 题目长，存文件再读
python E:\项目\自动化取证\scripts\ask_advisor.py -f C:\path\to\q.txt

# 3. 只看知识库召回，不烧 token（验证关键词命中）
python E:\项目\自动化取证\scripts\ask_advisor.py "题目" --no-llm
```

**🎨 可视化：每次回答会自动保存到 `output/<时间戳>_<题目摘要>.md` 并用默认程序打开。**

- 如果你装了 VSCode 且默认用它打开 `.md` → 看到分屏渲染，左 raw 右预览
- 如果是 Typora → 直接全渲染
- 浏览器（Chrome 装了 markdown 插件） → 也行
- **关闭自动打开**：加 `--no-open`
- **不保存**：加 `--no-save`
- **指定输出**：`--out C:\Users\xx\Desktop\q1_answer.md`

---

## 装快捷别名（一次性，强烈推荐）

```powershell
notepad $PROFILE
```

文件里加一行：

```powershell
function ask { python E:\项目\自动化取证\scripts\ask_advisor.py @args }
```

保存关闭，重开 PowerShell。以后：

```powershell
ask "题目原文"
ask -f q.txt
ask "题目" --no-llm
```

---

## 全部参数

| 参数 | 作用 | 示例 |
|---|---|---|
| `"..."` | 题目原文（位置参数） | `ask "找出微信加密密钥"` |
| `-f FILE` | 从文件读题目（替代位置参数） | `ask -f q.txt` |
| `--topk N` | 召回历年题数量，默认 5 | `ask "题目" --topk 10` |
| `--no-llm` | 只召回不调 LLM，省 token | `ask "题目" --no-llm` |
| `--provider X` | 切 LLM：`deepseek`/`qwen`/`openai` | `ask "题目" --provider qwen` |
| `--no-save` | 不保存为 markdown | `ask "题目" --no-save` |
| `--no-open` | 保存但不自动打开 | `ask "题目" --no-open` |
| `--out FILE` | 指定输出文件 | `ask "题目" --out q1.md` |
| `--kb DIR` | 自定义知识库目录 | 一般不用 |

---

## 输出怎么看

```
============================================================
召回 N 条历年题：
  [score] 文件名: - Q号 [关键词] 题面摘要      ← 命中越多越像
  ...
============================================================

## 题目识别                  ← LLM 给的归类
## 匹配的历年题              ← 哪些历年题相似 + 差异
## 解题路径                  ← 3-5 步工具+文件+字段
## 关键命令/SQL/正则         ← 可直接复制
## 常见坑                    ← 编码/时区/格式/繁简
## 置信度                    ← 高/中/低
## Plan B                    ← 卡住的备选方向
```

**记住**：LLM 给路径，不给最终答案。答案靠你自己跑工具拿。

---

## 召回不准时的应对

| 现象 | 解法 |
|---|---|
| 召回 0 条 | 题目里加具体名词：`微信`、`BitLocker`、`PVE`、`smali` |
| 召回的全无关 | 删掉题目里"请分析检材"这种废话，只留核心 |
| 想看更多 | `--topk 10` 或 `--topk 15` |

测命中：先 `--no-llm` 看召回，满意了再去掉 `--no-llm` 调 LLM。

---

## 网络断了 / API 不通

```powershell
ask "题目" --no-llm
```

脚本会打印完整 system + user prompt，**复制到网页版**：

- DeepSeek <https://chat.deepseek.com/>
- Kimi <https://kimi.moonshot.cn/>
- 通义千问 <https://tongyi.aliyun.com/>

效果一样。

---

## 报错速查

| 报错 | 解法 |
|---|---|
| `python 不是内部或外部命令` | 装 Python 并加 PATH |
| `No module named 'requests'` | `pip install requests` |
| `环境变量 DEEPSEEK_API_KEY 未设置` | 重设变量 + 重开 PowerShell |
| `LLM 调用失败: 401` | key 错或失效，去控制台重生成 |
| `LLM 调用失败: 402` | 余额不足，充值 |
| `LLM 调用失败: timeout` | 网络问题，用 `--no-llm` + 网页粘贴 |
| 中文显示乱码 | `chcp 65001` 切 UTF-8（不影响逻辑，仅显示）|

---

## 重设 API Key

```powershell
[Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', 'sk-新key', 'User')
```

设完**关掉所有 PowerShell 窗口重开**才生效。验证：

```powershell
echo $env:DEEPSEEK_API_KEY
```

---

## 三种典型场景

### 场景 1：拿到一道新题
```powershell
ask "请分析检材2，找出嫌疑人计算机BitLocker加密分区的恢复密钥"
```

### 场景 2：题目很长（剧情题）
1. 桌面新建 `q.txt`，粘贴题目
2. ```powershell
   ask -f $env:USERPROFILE\Desktop\q.txt
   ```

### 场景 3：LLM 给的路径卡住了
把"我试了 X，结果是 Y，下一步怎么办"作为新题再问一次：

```powershell
ask "我按指示用 dislocker 挂载，但报错 Volume header is corrupted，下一步怎么办"
```

LLM 会基于上下文继续指导（这是无状态调用，要把上下文写进题里）。

---

## 价格参考

DeepSeek 实测：每次 ~3000 token 输入 + 1000 token 输出 ≈ **¥0.003**（半分钱）。
**¥10 充值 = 跑 3000 次咨询**。比赛全程根本花不完。

---

## 一键升级知识库

抓到新 WP 时：

1. 在 `knowledge/wp_index/` 加一个 md，按已有格式写
2. CLI 自动扫描，**无需改代码**
3. 在 `wp_index/INDEX.md` 表格追加一行（可选，便于人类查阅）
