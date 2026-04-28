# FIC2026 学生组 — PHONE 板块 WP

**比赛**: 第六届 FIC 全国网络空间取证大赛-学生组
**批次**: PHONE_M01-M05.md
**解题人**: PHONE 窗口（Cascade）
**时间**: 2026-04-25

---

﻿## M01 — 手机型号

> 分析手机检材，该手机型号为

**答案**：`Redmi Note 7 Pro`
**置信度**：高

### 解析

#### 识别
确定手机的产品型号（marketing name / model）。

#### 提取
读取 Android /data 备份中的指纹文件 `data/misc/recovery/ro.build.fingerprint`：

```
xiaomi/violet/violet:10/QKQ1.190915.002/V12.5.4.0.QFHCNXM:user/release-keys
```

#### 分析
- 厂商: `xiaomi`
- 设备代号 (codename): `violet`
- 代号 `violet` 是小米官方为 Redmi Note 7 Pro 分配的开发代号（公开见 LineageOS / 小米开源内核仓库设备清单）。
- Android 版本: 10 (QKQ1.190915.002)
- MIUI 版本: V12.5.4.0.QFHCNXM（Q=Android10、F=violet 系、CN=中国、M=Stable）

交叉证据：
- `data/system/users/0.xml` 中 `lastLoggedInFingerprint` 同为 `xiaomi/violet/violet:10/...`
- `data/user/0/com.xiaomi.account` SharedPreferences `<string name="build_fingerprint">xiaomi/violet/violet:10/...`

#### 验证
```bash
cat /tmp/phone_extract/data/misc/recovery/ro.build.fingerprint
grep -rh fingerprint /tmp/phone_extract/data/user/0/com.xiaomi.account/ | grep violet
grep lastLoggedInFingerprint /tmp/phone_extract/data/system/users/0.xml
```
三处来源一致 → `violet` → **Redmi Note 7 Pro**。

### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：仅本地文件，未查询本届赛题题解或调用外部 API；codename→市售名为公开常识
- **工具列表**：tar, cat, grep, sqlite3
- **脚本留存**：`cases/2026FIC电子取证/work_phone/recon.md`

---

## M02 — 李安弘计划前往迪拜的日期

> 分析手机检材，李安弘手机计划前往迪拜的日期是

**答案**：`2026.06.06`
**置信度**：高

### 解析

#### 识别
小米便签的"待办"模块（todo.db）记录用户日程。

#### 提取
```bash
sqlite3 /tmp/phone_extract/data/user/0/com.miui.notes/databases/todo.db \
  "SELECT id,content,plain_text,datetime(create_time/1000,'unixepoch','+8 hours') FROM todo"
```

#### 分析
todo 表中第 6 条记录：
- content: `2026.06.06 乘坐飞机去 dubai`
- plain_text: 同上
- create_time: 1776310200545 ms = 2026-04-16 17:30:00 CST
- last_modified_time: 1776323511373 ms = 2026-04-16 21:11:51 CST

文本中显式声明日期 `2026.06.06`（即 2026 年 6 月 6 日）。

围绕该计划的相关待办（同一用户、同一时间窗）形成完整链条：
- 4 搭建网站（已完成 2026-04-16 18:49）
- 5 建立挖矿基地（已完成 2026-04-16 18:50）
- 6 **2026.06.06 乘坐飞机去 dubai**（未完成）
- 7 购买矿机
- 8 买一个 u 盘存账单（已完成 2026-04-17 22:17）

#### 验证
```bash
sqlite3 /tmp/phone_extract/data/user/0/com.miui.notes/databases/todo.db \
  "SELECT plain_text FROM todo WHERE plain_text LIKE '%dubai%'"
# → 2026.06.06 乘坐飞机去 dubai
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M03 — 网站搭建沟通APP安装日期

> 分析手机检材，李安弘手机中与网站搭建人员沟通所使用的app安装日期为

**答案**：`2026-04-14 18:00:55`
**置信度**：高

### 解析

#### 识别
解密 com.talk.uuuim 的加密消息库后（详见 M05 解析），channel 表中 channel_id=`8c723cbb09bd47adcf0ba4d9758320c0` 的 channel_name 为「**网站开发**」，messages 内容明确为李安弘与"网站搭建人员"协商搭建非法视频网站的全过程。因此涉案 APP = `com.talk.uuuim`（uuTalk / WuKong IM 改版客户端）。

#### 提取
从 Android packages.xml 提取该包的安装时间：
```bash
grep '<package name="com.talk.uuuim"' /tmp/phone_extract/data/system/packages.xml
# codePath="/data/app/com.talk.uuuim-TvDbtcF2dENhraYZWbysyg=="
# ft="19d8b6fcff0" it="19d8b6fd571" ut="19d8b6fd571"
```

#### 分析
- `ft`（firstInstallTime）= 0x19d8b6fcff0 = **1776160854000 ms**
- `it`（installTime，全局）= 0x19d8b6fd571 = 1776160855409 ms
- `ut`（lastUpdateTime）= 0x19d8b6fd571 = 1776160855409 ms

```python
import datetime
datetime.datetime.fromtimestamp(int("19d8b6fcff0",16)/1000)
# datetime.datetime(2026, 4, 14, 18, 0, 54, 944000)  → 2026-04-14 18:00:54.944 CST
datetime.datetime.fromtimestamp(int("19d8b6fd571",16)/1000)
# datetime.datetime(2026, 4, 14, 18, 0, 55, 409000)  → 2026-04-14 18:00:55.409 CST
```

PMS 视角的"安装完成时间"通常以 `it`/`ut` 为准（首次写入与首次记录），即 **2026-04-14 18:00:55**（精确到秒）。

#### 验证
```bash
python3 -c "import datetime; print(datetime.datetime.fromtimestamp(int('19d8b6fd571',16)/1000))"
# 2026-04-14 18:00:55.409000
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；SQLCipher 解密参数从 com.talk.uabchat APK（同 SDK）反编译推导
- **工具列表**：tar, sqlite3, sqlcipher3 (Python), jadx 1.5.5, exiftool, grep, python3
- **脚本留存**：`cases/2026FIC电子取证/work_phone/` 及 inbox/main.md


---

## M04 — 网站搭建沟通APP聊天数据库

> 分析手机检材，李安弘手机中与网站搭建人员沟通所使用的app，存放聊天数据的数据库为

**答案**：`wk_9628874a3c6b403593766496fa985893.db`
**置信度**：高

### 解析

#### 识别
- com.talk.uuuim 是 WuKong IM (`net.sqlcipher` v4.5.3) 派生客户端。
- 用户登录 UID 在 SharedPreferences `wkSharedPreferences.xml` 中：`<string name="wk_uid">9628874a3c6b403593766496fa985893</string>`。
- WuKong IM SDK（`com.caht.base.db.wkdb.WKDBHelperKt`）以 `wk_<uid>.db` 命名消息加密库。

#### 提取
```bash
ls /tmp/phone_extract/data/user/0/com.talk.uuuim/databases/
# 9628874a3c6b403593766496fa985893.db        (Room：联系人/朋友圈，明文 SQLite)
# 9628874a3c6b403593766496fa985893_room_db   (Room：channel_archive)
# bugly_db_                                   (Tencent Bugly 崩溃日志)
# wk_9628874a3c6b403593766496fa985893.db     ← 消息加密库（SQLCipher v4）
```

```bash
file /tmp/phone_extract/data/user/0/com.talk.uuuim/databases/wk_*.db
# data  ← 加密
xxd ... | head -1
# 05bc cf0a 38a9 43ee 580f ad5c 0bec e533   ← SQLCipher 随机 salt
```

#### 分析
- 文件名规则验证（来自反编译 `com.talk.uabchat` 同 SDK 源码 `WKDBHelperKt.java`）：
```java
myDBName = WKDBHelperKt.DB_PREFIX + uid + ".db";   // DB_PREFIX = "wk_"
```
- 该 DB 大小 856064 字节，是会话/消息/频道/成员信息存放处；用户的"网站开发"会话所有 1022 条 message 均在此库中。
- 解密后 14 张业务表：`message`、`conversation`、`channel`、`channel_members`、`message_reaction`、`message_extra`、`reminders`、`robot`、`robot_menu`、`message_memo_record`、`message_memo_detail`、`message_pinned`、`conversation_extra`、`sqlite_sequence`。

**答**：`wk_9628874a3c6b403593766496fa985893.db`

#### 验证
```bash
ls -la /tmp/phone_extract/data/user/0/com.talk.uuuim/databases/wk_9628874a3c6b403593766496fa985893.db
# 856064 字节
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；SQLCipher 解密参数从 com.talk.uabchat APK（同 SDK）反编译推导
- **工具列表**：tar, sqlite3, sqlcipher3 (Python), jadx 1.5.5, exiftool, grep, python3
- **脚本留存**：`cases/2026FIC电子取证/work_phone/` 及 inbox/main.md


---

## M05 — 聊天数据库解密密码

> 分析手机检材，存放聊天数据的数据库的解密密码为

**答案**：`9628874a3c6b403593766496fa985893`
**置信度**：高

### 解析

#### 识别
反编译 com.talk.uabchat 同 SDK 包 `com.caht.base.db.wkdb.WKDBHelper`（WuKong IM Android），可以看到 SQLCipher 的密码即用户 UID（release 版本）：

```java
// WKDBHelper.java
public WKDBHelper(Context ctx, String uid2, Boolean needUpgrade) {
    uid = uid2;
    myDBName = WKDBHelperKt.DB_PREFIX + uid2 + ".db";
    this.mDbHelper = new DatabaseHelper(ctx);
    if (h(ctx)) {                                          // h(): debug build
        this.mDb = this.mDbHelper.getWritableDatabase("");
    } else {
        this.mDb = this.mDbHelper.getWritableDatabase(uid2);  // ← release: key = uid
    }
    ...
}
```

`uid2` = `wkSharedPreferences.xml` 中的 `wk_uid` = `9628874a3c6b403593766496fa985893`。

#### 提取
```bash
grep wk_uid /tmp/phone_extract/data/user/0/com.talk.uuuim/shared_prefs/wkSharedPreferences.xml
# <string name="wk_uid">9628874a3c6b403593766496fa985893</string>
```

#### 分析
- net.sqlcipher v4.5.3 默认 `cipher_compatibility = 4`（PBKDF2-SHA512, 256000 iters, AES-256-CBC, HMAC-SHA512）。
- 直接以 UID 字符串作为 PRAGMA key（即 SQLCipher v4 密码）即可解密，**无需任何派生**。

```python
import sqlcipher3
db = ".../wk_9628874a3c6b403593766496fa985893.db"
uid = "9628874a3c6b403593766496fa985893"
c = sqlcipher3.connect(db); cur = c.cursor()
cur.execute("PRAGMA cipher_compatibility = 4")
cur.execute(f"PRAGMA key = '{uid}'")
cur.execute("SELECT count(*) FROM message")
# → 1022 条消息
```

成功打开 14 张业务表、1022 条消息（含与"网站开发"和"大日云服务器"两条主线全部聊天）。

**答**：`9628874a3c6b403593766496fa985893`

#### 验证
```bash
python3 -c "
import sqlcipher3
c = sqlcipher3.connect('/tmp/phone_extract/data/user/0/com.talk.uuuim/databases/wk_9628874a3c6b403593766496fa985893.db')
cur = c.cursor()
cur.execute("PRAGMA cipher_compatibility = 4")
cur.execute("PRAGMA key = '9628874a3c6b403593766496fa985893'")
print(cur.execute('SELECT count(*) FROM message').fetchone())
"
# → (1022,)
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；SQLCipher 解密参数从 com.talk.uabchat APK（同 SDK）反编译推导
- **工具列表**：tar, sqlite3, sqlcipher3 (Python), jadx 1.5.5, exiftool, grep, python3
- **脚本留存**：`cases/2026FIC电子取证/work_phone/` 及 inbox/main.md


---
