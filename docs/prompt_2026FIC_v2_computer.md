# 续战提示词 v2 — computer_analyst (2026FIC)

> 把下面整段直接粘给 computer 机的 AI（替换 [HUB_IP]）

---

```
你是 2026FIC 比赛的 computer_analyst（计算机取证分析员），现在续接进度。
不要回复任何客套话，立即按下面执行。

━━━ 当前真实状态（来自 DIDCTF 平台） ━━━
[平台已确认 4 题]
- Q1 ✅ 23.1
- Q2 ✅ hf13338261292@outlook.com
- Q3 ✅ 13612817854
- Q5 ✅ 9527

[剩余 6 题, 全部错答需重做]
- Q4 ❌ apk下载链接 (我们答 https://dl.sp-live88.com/update/latest.apk, 平台不认)
- Q6 ❌ AI模型类型 (我们答 minimax/minimax-m2.5:free, 错; 参考格式 deepseek)
- Q7 ❌ AI模型 apiKey (我们答"不存在", 必须再找; 参考格式 sk-abcd...)
- Q8 ❌ 勒索软件解密服务联系方式 (我们答占位符; 参考格式 abcd123232)
- Q9 ❌ 保险柜编号 (依赖 vc 容器解密)
- Q10 ❌ 保险柜密码 (依赖 vc 容器解密)

━━━ 强制阅读顺序 ━━━
1. case\computer\HANDOFF*.md (全部读)                       ← 之前交接
2. case\shared\todo.yaml (computer_forensics 段)            ← 待解 6 题
3. case\shared\diff_report.md                               ← 答案对比
4. case\shared\findings.yaml (F-C001~F-C011)                ← 你的发现
5. E:\项目\自动化取证\knowledge\skills\computer\quick_reference.md
6. E:\项目\自动化取证\knowledge\skills\must_scan_dirs.md

━━━ 重大新线索 ━━━
[mobile 已确认] Q15 USDT钱包 = TXqH7sVn8bR4kL2mN9pW6xJ3cY5dF1gA
[mobile 已确认] Q13 编码 = Base64 (不是 URL!)
[server 已确认] Q3 docker 镜像创建时间 = 2026-04-16T07:15:50.535713491Z
                Q11 数据库 IP = 10.0.3.100
[互联网] Q1 Telegram 群组 = FIC_2026
        Q3 ngrok = blemish-junior-unengaged.ngrok-free.dev

━━━ 你今天的 4 步行动（按依赖顺序） ━━━

【Step 1: 复盘 Q4 (apk 下载链接)】
我们之前答 https://dl.sp-live88.com/update/latest.apk
但平台不认。重新检查推广设计图原文件:
```bash
# 在 case\computer_extract 找推广图 (jpg/png), 用 OCR 重读
ls case\computer_extract\**\*.{jpg,png,pdf}
# 用 paddleocr 或 tesseract 重新 OCR
python3 -c "
from PIL import Image
import subprocess
# tesseract <img> - -l chi_sim
"
```
推广图可能是另一个 URL (如 sp-live.com 不带 88, 或带 ?param)。

【Step 2: Q6 + Q7 (AI 软件模型 + apiKey)】
李安弘电脑上 AI 软件 = ?
- Cherry Studio / ChatBox / LobeChat / OpenWebUI / 自建 Open-Router 等
- 路径: ~/.config/<软件名>/  或 ~/AppData/Roaming/<软件名>/
- 在 Deepin 23.1 (Linux), 路径是 /home/lha/.config/

```bash
# WSL 下挂载检材1 后:
find /mnt/computer/home/lha/.config -type d 2>/dev/null
find /mnt/computer/home/lha -name "*.json" -exec grep -l "model\|apiKey\|api_key" {} \;

# 关键文件常见路径:
cat /mnt/computer/home/lha/.config/CherryStudio/data.json | jq '.providers'
cat /mnt/computer/home/lha/.config/Continue/config.json
cat /mnt/computer/home/lha/.config/Open-WebUI/*.db
sqlite3 /mnt/computer/home/lha/.config/Open-WebUI/webui.db "SELECT * FROM model;"
```
Q6 答案格式 "deepseek" → 简短模型名(可能是 deepseek/qwen/glm/gpt 等)
Q7 答案格式 "sk-abcd..." → OpenAI 风格 API Key (sk- 开头)

【Step 3: Q8 (勒索软件解密服务联系方式)】
格式 abcd123232 — 看起来是字母+数字的 Telegram 用户名 / 邮箱 / QQ
```bash
# 在桌面文件 / 文档 / 浏览器历史 / 邮件 中找勒索信
find /mnt/computer -type f \( -name "*.txt" -o -name "*.html" -o -name "README*" \) \
    | xargs grep -lE "(decrypt|解密|ransom|勒索|bitcoin|btc|t\.me|@.+bot|onion)" 2>/dev/null

# 桌面截图 / 壁纸可能含勒索信
ls /mnt/computer/home/lha/Desktop/
ls /mnt/computer/home/lha/Pictures/

# 浏览器历史
sqlite3 /mnt/computer/home/lha/.config/google-chrome/Default/History \
    "SELECT url FROM urls WHERE url LIKE '%t.me%' OR url LIKE '%onion%' OR url LIKE '%decrypt%';"

# 邮件 (如有 thunderbird)
find /mnt/computer/home/lha/.thunderbird -name "*.msf"
```

【Step 4: Q9 + Q10 (依赖 binary 解密 vc)】
等 binary_analyst 在 Hub 上 POST Q3 答案 → 立即:
```bash
# 用密码解密 vc
python3 case\binary\decrypt_vc.py
# 挂载 vhd
qemu-nbd -c /dev/nbd0 case\binary\decrypted.vhd
mount /dev/nbd0p1 /mnt/vhd
ls /mnt/vhd
# Q9 = 卷标 / 文件夹名 (如 "保险柜A1" → 编号 A1 → 1)
# Q10 = 密码 (vhd 内的 README/notes 或就是当前密码本身)
```

━━━ 协作铁律 ━━━
```python
import urllib.request, json
def post(path, data):
    body = json.dumps(data, ensure_ascii=False).encode("utf-8")
    return urllib.request.urlopen(
      urllib.request.Request(f"http://[HUB_IP]:8765{path}",
        data=body,
        headers={"Content-Type":"application/json; charset=utf-8"},
        method="POST")).read().decode("utf-8")

# 每解一题:
post("/answers", {"category":"computer_forensics","qid":"Q6",
     "answer":"deepseek","analysis":"...","evidence_path":"...",
     "source_role":"computer_analyst","confidence":"high"})

# 每发现新线索:
post("/findings", {"from":"computer_analyst","type":"evidence",
     "summary":"...","detail":"..."})
```

━━━ 答案格式硬要求 ━━━
跑完用 lint 复核:
```
python3 E:\项目\自动化取证\tools\answer_format_lint.py --case E:\ffffff-JIANCAI\2026FIC团体赛\case --cat computer_forensics
```

━━━ 完成定义 ━━━
- Q4/Q6/Q7/Q8 至少 3 题 high confidence (Q9/Q10 等 binary)
- 写 case\computer\SOLVED_v2.md

立即开始 Step 1。
```
