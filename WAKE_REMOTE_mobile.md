# 给 mobile_analyst 的戳醒文本

> **使用方法**：完整复制下面 `===` 之间的内容，粘到远程机 2（mobile）的 IDE chat 窗口

===

你是 `mobile_analyst`。你已经停工 17 小时了。先拉一下最新状态再继续。

## Step 1: 立即同步项目（v3.1 新版本，已修中文 UTF-8 bug）

```powershell
cd "e:\项目\自动化取证"
git pull origin main
```

## Step 2: 检查 inbox 和角色状态

```powershell
$Hub = "http://127.0.0.1:8765"   # 如果你在远程机走 cloudflared 隧道，改成那个地址
Invoke-RestMethod "$Hub/ping"
Invoke-RestMethod "$Hub/questions?to=mobile_analyst" | Where-Object { -not $_.answer } |
    Select-Object id, from, question | Format-List
```

你应该看到 4 个未回复的 question：
- **QQ002**（computer 17h 前问）：确认 Q4 推广图 apk 下载链接
- **QQ004**（binary 17h 前问）：F-M014 SHA1 验证
- **QQ006**（binary 15.8h 前问）：dump com.miui.notes 全部
- **QQ008**（binary 15.6h 前问）：紧急 dump notes（含已删除）

## Step 3: 优先做 QQ006 + QQ008（同一件事）— vc 16 字符密码暴破依赖此

binary 已经确认：
- vc 是 RC4 加密的 VHD（不是 AES）
- 密码 = 16 字符可打印 ASCII
- SHA1(密码) = `3e627d9046481366eef9c89183f87004968363d9`
- MD5(密码) = `afb977ac242ad60cf46124ad72ca5149`

binary 已穷尽 ZxcvbnData 30K + 智能候选 5921，全失败。**需要从笔记 / 通讯录 / 相册 / todo 找出 16 字符串**。

请按顺序执行：

```powershell
# 1. 从手机镜像挂载点定位 com.miui.notes
$ImageRoot = "你的手机镜像挂载根目录"  # e.g. "E:\ffffff-JIANCAI\2026FIC团体赛\image_mobile\data\data\com.miui.notes"

# 2. 找所有可能的 notes 数据库
Get-ChildItem -Recurse -Force "$ImageRoot\com.miui.notes" |
    Where-Object { $_.Name -match "\.(db|db-shm|db-wal|sqlite|sqlite3|note|notes|todo)$" } |
    Select-Object FullName, Length, LastWriteTime
```

```powershell
# 3. 用 sqlite3 dump 所有表（包括 trash/deleted/草稿）
$db = "你定位到的 .db 文件"
sqlite3 $db ".tables"
sqlite3 $db ".schema"
# 关键: 找 content / body / text / note 列
sqlite3 $db "SELECT * FROM note ORDER BY modify_date DESC;" > notes_full_dump.txt
sqlite3 $db "SELECT * FROM trash;" > notes_trash.txt 2>$null
sqlite3 $db "SELECT * FROM todo;" > notes_todo.txt 2>$null
```

```powershell
# 4. grep 16 字符 ASCII 候选
Get-Content notes_full_dump.txt, notes_trash.txt, notes_todo.txt -ErrorAction SilentlyContinue |
    Select-String -Pattern '\b[\x21-\x7E]{16}\b' -AllMatches |
    ForEach-Object { $_.Matches } |
    Select-Object -ExpandProperty Value -Unique |
    Where-Object { $_ -notmatch '^[0-9a-f]{16}$' } |  # 过滤 hex
    Out-File candidates_16char.txt -Encoding utf8

"候选数: $((Get-Content candidates_16char.txt).Count)"
```

```powershell
# 5. 验证哪个候选 SHA1 命中
python -c @"
import hashlib
target = '3e627d9046481366eef9c89183f87004968363d9'
with open('candidates_16char.txt', encoding='utf-8') as f:
    for line in f:
        p = line.strip()
        if len(p) == 16 and hashlib.sha1(p.encode()).hexdigest() == target:
            print(f'*** HIT: {p!r}')
            break
    else:
        print('No SHA1 hit in candidates.')
"@
```

## Step 4: POST 结果到 Hub（**用 Python urllib，不要用 PowerShell ConvertTo-Json**！）

如果找到 hit：

```python
import urllib.request, json
body = {
    "id": "F-M023",
    "from": "mobile_analyst",
    "type": "evidence",
    "summary": "Q-mobile-fullnotes: 16字符密码 = '<找到的字符串>' (SHA1命中)",
    "details": "在 com.miui.notes/databases/notes.db 表 <X> 行 <Y> 列 <Z> 找到，SHA1 验证通过",
    "confidence": "high",
    "related_to": ["binary_analyst", "computer_analyst", "stego_crypto"],
    "source": "mobile_image/data/data/com.miui.notes/databases/notes.db",
}
data = json.dumps(body, ensure_ascii=False).encode("utf-8")
req = urllib.request.Request("http://127.0.0.1:8765/findings",
    data=data,
    headers={"Content-Type": "application/json; charset=utf-8"},
    method="POST")
urllib.request.urlopen(req)
```

如果**没找到**：把候选列表 + dump 的笔记内容 POST 给 binary 让他用 unicorn oracle 暴力验证：

```python
import urllib.request, json
candidates = open('candidates_16char.txt').read()
notes_excerpt = open('notes_full_dump.txt').read()[:3000]  # 截前 3KB
body = {
    "id": str(len([0]) + 11),  # 自动取 next id
    "from": "mobile_analyst",
    "to": "binary_analyst",
    "question": (
        "QQ006/QQ008 回复：com.miui.notes dump 完成。\n"
        f"16字符候选 ({len(candidates.splitlines())} 个):\n{candidates}\n"
        f"---\n笔记摘要前 3KB:\n{notes_excerpt}\n"
        "请用 unicorn oracle 验证这些候选，或建议下一步。"
    ),
}
data = json.dumps(body, ensure_ascii=False).encode("utf-8")
req = urllib.request.Request("http://127.0.0.1:8765/questions",
    data=data,
    headers={"Content-Type": "application/json; charset=utf-8"},
    method="POST")
urllib.request.urlopen(req)
```

## Step 5: 顺手回复 QQ002（计算机 Q4 推广图验证）

QQ002 问：相册截图里有没有"推广设计图"图片，写明 https://dl.sp-live88.com/update/latest.apk？

```powershell
# 在手机镜像 DCIM/Pictures/QQ/微信 截图里 grep 文件
Get-ChildItem -Recurse "$ImageRoot\storage\emulated\0\Pictures","$ImageRoot\storage\emulated\0\DCIM" |
    Where-Object { $_.Length -gt 50KB -and $_.Length -lt 5MB } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 30
```

如果找到带 dl.sp-live88.com 的图（OCR 或人工查看），POST 回复 QQ002。

## Step 6: 最后 POST progress 让队长知道你在干

```python
import urllib.request, json, datetime
body = {
    "status": "active",
    "current_task": "已 dump notes，正在暴破 16 字符密码 / 已回 QQ006/008",
    "updated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
}
data = json.dumps(body, ensure_ascii=False).encode("utf-8")
req = urllib.request.Request("http://127.0.0.1:8765/progress/mobile_analyst",
    data=data,
    headers={"Content-Type": "application/json; charset=utf-8"},
    method="POST")
urllib.request.urlopen(req)
```

完成后请汇报：(1) 候选数量、(2) 是否 SHA1 命中、(3) 已回复哪几个 QQ。

===
