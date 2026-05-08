---
tags: [timestamps, epoch, unix, cocoa, filetime, webkit, chrome, gps, dos, ole, timezone, methodology, cross_domain]
tools: [python, sqlite3, cyberchef, dcode, exiftool, plaso]
category: methodology
difficulty: foundational
source: kb_seed_2026-05-07
verified: false
---
# 时间戳取证 — 识别 + 换算 + 校准

> **核心心法**：拿到一个数字之前先回答三件事：
> 1. **它是什么纪元（epoch）？** Unix? Cocoa? Windows FILETIME? Chrome?
> 2. **它的单位是什么？** 秒/毫秒/微秒/100ns?
> 3. **它的时区是什么？** UTC? 本地? 还是没标？
>
> 三件事任一搞错，结果差几小时到几十年。**永远先用一个"已知正确"的锚点反推公式**，再批量处理。

## 0. 速判：看数字"长相"识格式

| 数字范围 | 可能格式 | 例值 (=2026-05-07 14:00 UTC) |
|---|---|---|
| 10 位整数 (~1.7e9) | Unix 秒 | `1778162400` |
| 13 位整数 (~1.7e12) | Unix 毫秒 / Java/Android | `1778162400000` |
| 16 位整数 (~1.7e15) | Unix 微秒 / iOS 13+ sms 纳秒类 | `1778162400000000` |
| 17–18 位整数 (~13e16) | Windows FILETIME / Chrome WebKit | `13391323200000000` |
| 9–10 位浮点 (~7.7e8 + 小数) | iOS / macOS Cocoa (Core Data) | `799855200.0` |
| 8 位 hex `0x???` | 可能是 Unix 秒的 hex | `0x6809E7E0` |
| 字符串 `2026-05-07T14:00:00Z` | ISO 8601 UTC | — |
| 字符串 `2026-05-07T22:00:00+08:00` | ISO 8601 本地 | — |
| 字符串 `Wed May 07 ...` | RFC 2822 / ctime | — |

**判定要点**：先看位数选纪元/单位，再看首位数字校年代（`1`+13 位 ≈ 2001-2080 Unix ms），同表多看几行就锁单位。

## 1. 主流时间戳格式速查表

| 格式 | 纪元起点 | 单位 | 何处遇到 |
|---|---|---|---|
| **Unix 秒** | 1970-01-01 UTC | s | 经典 sqlite, log |
| **Unix 毫秒** | 1970-01-01 UTC | ms | Java/Android/JS `Date.now()`, mmssms.db |
| **Unix 微秒** | 1970-01-01 UTC | µs | postgres `epoch_usec` |
| **Cocoa / Core Data** | 2001-01-01 UTC | s（带小数） | iOS sqlite, CallHistory, knowledgeC |
| **Mac HFS+** | 1904-01-01 UTC | s | 旧 macOS 文件系统 |
| **Windows FILETIME** | 1601-01-01 UTC | 100ns | NTFS, Registry, $MFT, evtx |
| **Chrome / WebKit** | 1601-01-01 UTC | µs | Chrome `urls.last_visit_time`, Cookies |
| **OLE / VARIANT** | 1899-12-30 (本地) | day（带小数） | Excel, Outlook |
| **GPS 时间** | 1980-01-06 UTC | s | NMEA 原始；**比 UTC 快 18s** |
| **DOS 时间** | 1980-01-01 (本地) | 2s 步进 | ZIP, FAT |

## 2. 换算公式（直接背）

### Unix 系
```python
import datetime as dt
dt.datetime.utcfromtimestamp(N)             # 秒
dt.datetime.utcfromtimestamp(N / 1000)      # 毫秒
dt.datetime.utcfromtimestamp(N / 1e6)       # 微秒
```

### iOS Cocoa / Core Data
```python
# 偏移：Cocoa 0 = Unix 978307200
unix_secs = cocoa + 978307200
dt.datetime.utcfromtimestamp(unix_secs)

# 反向
cocoa = unix_secs - 978307200
```

```sql
SELECT datetime(ZSTART_DATE + 978307200, 'unixepoch') FROM ZOBJECT;
```

### Windows FILETIME / Chrome WebKit
```python
# FILETIME 0 = 1601-01-01 UTC = Unix -11644473600 秒
unix_secs = filetime / 10_000_000 - 11644473600   # FILETIME (100ns)
unix_secs = chrome   / 1_000_000  - 11644473600   # Chrome (µs)
```

```sql
-- Chrome History
SELECT datetime(last_visit_time / 1000000 - 11644473600, 'unixepoch') FROM urls;
```

### Mac HFS+
```python
unix_secs = hfs - 2082844800   # HFS 0 = 1904-01-01 UTC
```

### OLE Date (Excel / Outlook)
```python
from datetime import datetime, timedelta
def ole_to_dt(ole):
    return datetime(1899, 12, 30) + timedelta(days=ole)
```
⚠️ Excel 1900 闰年 bug：OLE Date < 60 时差 1 天。

### GPS 时间
```python
unix_secs = gps + 315964800 - 18   # GPS 0 = 1980-01-06 UTC; 含 18s 跳秒补偿（2024 年值）
```

### DOS 时间（FAT / ZIP）
```python
def dos_to_dt(date, time):
    year   = ((date >> 9) & 0x7F) + 1980
    month  = (date >> 5) & 0x0F
    day    =  date       & 0x1F
    hour   = (time >> 11) & 0x1F
    minute = (time >> 5)  & 0x3F
    second = (time & 0x1F) * 2     # 步进 2 秒
    return datetime(year, month, day, hour, minute, second)
```

## 3. 时区那些坑

### UTC vs 本地
- **UTC 纪元**：Unix / Cocoa / FILETIME / Chrome / GPS — 解出的 datetime 是 UTC，展示再 +8h
- **本地纪元**：DOS / OLE / 部分 SQL `datetime()` — 受系统时区影响
- **ISO 8601**：看后缀
  - `...Z` = UTC
  - `...+08:00` = 本地
  - 无 Z 无偏移 = 未指定，**按上下文猜**

### SQLite `datetime()` 函数
```sql
datetime(ts, 'unixepoch')              -- UTC
datetime(ts, 'unixepoch', 'localtime') -- SQLite 进程的本地时区
```
⚠️ SQLite 没有内置时区数据库，`'localtime'` 在不同机器结果不同！取证请只用 `'unixepoch'`，转换时区在外部做。

### 取证场景常见时区错位
- **手机改过时区**：EXIF 用本地、GPS 时间用 UTC，对比能识破
- **设备 RTC 未同步**：开机 30 分钟未联网就拍照
- **Android 时区**：`getprop persist.sys.timezone`
- **iOS 全用 UTC 存**：所有 Cocoa 时间无歧义
- **Windows evtx**：日志 UTC 存储，事件查看器自动转本地，**导出后看原值**

## 4. 实战决策流程

```
拿到一个待换算的时间数字
   │
   ├─ 看位数 → 选纪元/单位
   │
   ├─ 找一个"已知正确"的锚点
   │   例：表里某行 hint="发短信" 你知道发生在 2026-05-01 12:00
   │   反算 → 1761912000000
   │   对比 db ts，确认公式
   │
   ├─ 批量换算 → 检查结果合理性
   │   全部 2024-2026？ ✅
   │   半数在 1970？     → 默认 0，过滤
   │   一些到 2099？     → 单位错（毫秒当秒）
   │   全部偏 8 小时？   → 时区没处理
   │
   └─ 输出：永远附带时区
      "2026-05-07 14:00:00 UTC" 或 "2026-05-07 22:00:00 +08:00"
      ❌ 不要写 "2026-05-07 22:00:00"（歧义）
```

## 5. 命令 / 工具速查

### Python 一行换算
```python
import datetime as dt

# Unix s/ms/µs
dt.datetime.utcfromtimestamp(N)
dt.datetime.utcfromtimestamp(N/1000)
dt.datetime.utcfromtimestamp(N/1e6)

# Cocoa
dt.datetime.utcfromtimestamp(N + 978307200)

# FILETIME / Chrome
dt.datetime.utcfromtimestamp(N/1e7 - 11644473600)
dt.datetime.utcfromtimestamp(N/1e6 - 11644473600)

# 反向：人类时间 → 数字
dt.datetime(2026,5,7,14,0,0).replace(tzinfo=dt.timezone.utc).timestamp()
```

### 命令行
```bash
# Linux date
date -u -d @1778162400                       # Unix 秒
date -u -d @$(echo "1778162400000/1000"|bc)  # Unix 毫秒

# Windows PowerShell
[datetimeoffset]::FromUnixTimeSeconds(1778162400).UtcDateTime
[datetimeoffset]::FromUnixTimeMilliseconds(1778162400000).UtcDateTime

# FILETIME → DateTime
[datetime]::FromFileTimeUtc(133913232000000000)
```

### 推荐 GUI / Web
- **CyberChef**：`From UNIX Timestamp` / `From WebKit Timestamp` / `From FILETIME` — 不用记公式
- **DCode by Digital Detective**：输入数字自动给出所有可能解读，取证圈标配
- **Plaso / log2timeline**：构建跨数据源时间线

## 6. Android / iOS 各 App 时间戳实情

| 数据库 | 字段 | 实际格式 |
|---|---|---|
| Android `mmssms.db` | `date` | Unix **ms** |
| Android `calllog.db` | `date` | Unix **ms** |
| Android `contacts2.db` | `last_time_contacted` | Unix **ms** |
| Android Chrome `History` | `last_visit_time` | Chrome WebKit µs |
| Android 微信 `EnMicroMsg.db` | `createTime` | Unix **ms** |
| Android 微信 `MicroMsg.db` 新版 | 同上 | Unix **ms** |
| Android QQ `*.db` | `time` | 大多 Unix **秒**（⚠️ 不一致） |
| iOS `sms.db` | `date` | Cocoa（iOS 13+ 改纳秒：`ZDATE/1e9 + 978307200`） |
| iOS `CallHistory.storedata` | `ZDATE` | Cocoa 秒 |
| iOS Safari `History.db` | `visit_time` | Cocoa 秒 |
| iOS 微信 `MM.sqlite` | `CreateTime` | Unix **秒** |
| iOS `knowledgeC.db` | `ZSTART_DATE` | Cocoa 秒 |
| iOS `Notes.sqlite` | `ZCREATIONDATE1` | Cocoa 秒 |
| iOS `Photos.sqlite` | `ZDATECREATED` | Cocoa 秒 |
| iOS `healthdb_secure.sqlite` | `startDate` | Cocoa 秒 |
| Windows NTFS `$MFT` | `$SI`/`$FN` 时间 | FILETIME |
| Windows Registry | `LastWriteTime` | FILETIME |
| Windows evtx | `TimeCreated` | FILETIME (UTC) |
| Windows Edge | `last_visit_time` | Chrome WebKit µs |
| Linux ext4 inode | atime/mtime/ctime/crtime | Unix 秒（含纳秒辅字段） |
| **Windows Phone** `store.vol`（ESE 短信/邮件/联系人） | 各时间字段 | **FILETIME**（与桌面 NTFS 一致） |
| **Windows Phone** `phone.db` 通话记录 | `StartTime` | FILETIME |
| **Windows Phone / W10M** OneDrive 同步元数据 | `lastModified` | FILETIME |
| **HarmonyOS 1–4**（手机 AOSP 兼容） | App SQLite 字段 | 与 Android 同（多 Unix ms） |
| **HarmonyOS NEXT 5** | 大部分系统库 | Unix **ms**（少数底层 Cocoa 风格 Mac Abs，遇到先看数量级） |
| **BlackBerry 10**（QNX）`messages.db` `pim.db` | 各字段 | Unix **ms**（QNX 默认） |
| **BlackBerry OS（BBOS .ipd 备份）** | record timestamp | Unix **ms**（少数老机型为 1900-01-01 起秒，**老题坑**） |
| **Tizen** Galaxy Watch SQLite | `time` / `created_at` | Unix **秒**（多数）/ ms（部分） |
| **KaiOS** IndexedDB（LevelDB+V8） | `Date` 对象 | Unix **ms**（JS `Date.now()`） |

⚠️ **iOS sms.db 17 位**：从 iOS 13 起改纳秒，`ZDATE/1e9 + 978307200` 才对。
⚠️ **Windows Phone 整机就是 FILETIME 世界**：所有 ESE 数据库、注册表、$MFT 都是 100ns since 1601；与 iOS Cocoa（秒 since 2001）/ Android Unix ms 完全不同，**别拿桌面 Windows 的工具去解 iOS 数据，反之亦然**。
⚠️ **HarmonyOS NEXT 5 时间字段尚在演进**：分布式服务/超级终端跨设备同步可能引入"设备时间"与"主控时间"两份；交叉验证比单数判断更重要。

## 7. 常见坑

- **位数辨识陷阱**：14 位可能是 Unix µs 也可能是别的，多列佐证
- **哨兵值**：0 / -1 / 9999999999，跳过
- **闰秒**：UTC 含闰秒，TAI/GPS 不含；只在 GPS NMEA 题里关注
- **2038 问题**：32 位 Unix 秒在 2038-01-19 溢出，老系统会回到 1970
- **NTFS 双时间** `$SI` vs `$FN`：`SetFileTime` 类工具只改前者，对比能识破伪造（详见 `anti_forensics_and_misleading.md`）
- **Excel 1900 闰年 bug**：1900-02-29 不存在但 Excel 当作存在
- **Outlook PST 时间**：多数 UTC FILETIME，但部分字段本地
- **Wireshark 时区**：跟系统时区走，导出 csv 前确认 `View → Time Display Format`
- **shell `date` 命令**：BSD/macOS 与 GNU/Linux 参数不一样
- **JS `Date()` 显示**：浏览器自动转本地，`.toISOString()` 才是 UTC
- **数据库时间默认值**：很多框架 default 1970-01-01 / 2001-01-01，看到统一异常值就警觉

## 8. 报告写法

每个关键时间戳写**三件套**：

```
原始值: 1778162400000
解读  : Unix 毫秒
结果  : 2026-05-07 14:00:00 UTC = 2026-05-07 22:00:00 GMT+8
来源  : /data/data/com.android.providers.telephony/databases/mmssms.db
        message 表 _id=1234 row.date 字段
```

## 9. 反向锚点速查（背几个常用偏移）

| 偏移 | 含义 |
|---|---|
| `978307200` | Cocoa → Unix（加） |
| `11644473600` | FILETIME/Chrome → Unix（减） |
| `2082844800` | HFS → Unix（减） |
| `315964800` | GPS → Unix（加） |
| `25569` | OLE 1970-01-01 的天数（用于 Excel ↔ Unix） |

记住这五个数，覆盖 95% 题目。
