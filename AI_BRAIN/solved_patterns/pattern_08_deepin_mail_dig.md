# Pattern 08: Deepin-mail / Foxmail 邮件内容挖掘

> 来源：FIC2026 C02-C04/C08 — 钓鱼邮件/推广设计图/勒索联系方式

---

## 题型特征

- 检材为 UOS/Deepin Linux 系统
- 用户使用 deepin-mail 或 Foxmail 收发邮件
- 题目要求从邮件中提取：发件人、附件、联系方式、链接等

## 解题流程

### 1. 定位邮件数据

**deepin-mail**:
```
~/.local/share/deepin/deepin-mail/
├── mail/db/deepin_mail.V.2.0.db    ← SQLite 元数据
└── imap.<server>/<account>/imap/
    └── <folder_id>/mail.eml         ← 原始邮件
```

**Foxmail**:
```
~/Foxmail 7.2/Storage/<account>/
├── Inbox/
│   └── *.emlx 或 *.box
└── Cache/
```

### 2. 查询邮件数据库
```bash
sqlite3 deepin_mail.V.2.0.db ".tables"
sqlite3 deepin_mail.V.2.0.db "SELECT subject, sender, hasAttachment FROM MailMeta WHERE hasAttachment=1;"
```

### 3. 建全量索引（推荐第一步）
```python
from email import policy
from email.parser import BytesParser
from pathlib import Path
import re, html

base = Path('/path/to/imap/')
for p in sorted(base.glob('*/mail.eml')):
    raw = p.read_bytes()
    msg = BytesParser(policy=policy.default).parsebytes(raw)
    subj = msg.get('subject', '')
    frm = msg.get('from', '')
    date = msg.get('date', '')
    atts = [part.get_filename() for part in msg.walk() if part.get_filename()]
    texts = []
    for part in msg.walk():
        if part.get_content_type() in ('text/plain', 'text/html'):
            try: t = part.get_content()
            except: t = ''
            t = html.unescape(re.sub('<[^>]+>', ' ', str(t)))
            texts.append(t[:500])
    print(f"FROM: {frm}")
    print(f"DATE: {date}")
    print(f"SUBJ: {subj}")
    print(f"ATTS: {atts}")
    print(f"BODY: {' '.join(texts)[:200]}")
    print("---")
```

### 4. 关键词搜索
```python
keywords = ['黄金', '收购', '换现金', '推广设计图', '解密', '私钥',
            '公钥', '勒索', '联系方式', '保险柜', '编号', '密码',
            'token', '钓鱼', 'http', '@']
```

### 5. 处理加密附件
如果邮件附件是 `.enc` 文件：
- 检查同一邮件中是否有 HTML 查看器（如 `加密图片查看.html`）
- 检查是否有 `public.txt`（RSA 公钥 n 和 e）
- **全盘搜索私钥**：`grep -r 'BEGIN RSA PRIVATE' /tmp/pc_data/`

## FIC2026 教训

1. **先建索引再搜**，不要逐个 eml 手动看
2. **注意编码**：deepin-mail 邮件可能是 quoted-printable + GB18030
3. **附件可能在独立路径**：deepin-mail 附件缓存在 `att/` 子目录
4. **RSA 解密题关键是找私钥**：public.txt 只有 n 和 e，必须全盘搜 d 或 private key

## 可复现命令

```bash
# 搜索所有 eml 文件
find /tmp/pc_data -name 'mail.eml' -o -name '*.eml' -o -name '*.emlx' 2>/dev/null

# 搜索邮件元数据 DB
find /tmp/pc_data -name 'deepin_mail*' -o -name '*.db' | xargs -I{} sqlite3 {} ".tables" 2>/dev/null

# 全盘搜私钥
grep -rl 'BEGIN RSA PRIVATE\|BEGIN PRIVATE' /tmp/pc_data/ 2>/dev/null
```
