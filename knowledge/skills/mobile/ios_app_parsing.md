# iOS 应用数据解析与云数据固定（取证视角）

> 适用：iOS App 沙盒数据手工解析、SQLite/Core Data/plist/Realm/Protobuf 反结构化、iCloud 云数据固定。题目特征：见到 `ZOBJECT`、`ZRECORD`、`Z_PRIMARYKEY`、`*.sqlite`、`*.storedata`、`*.plist`、`bplist00`、`NSKeyedArchiver`、`$archiver`、`$objects`、`Manifest.db`、`Documents/`、`Library/`、`tmp/`、`Caches/`、`Containers/Shared/AppGroup/`、`Realm`、`MMKV`、`leveldb`、`fsCachedData`、`iCloud Drive`、`CloudDocs`、`CloudKit`、`com.apple.CloudKit` 等。

---

## 1. iOS App 沙盒结构总图

### 1.1 三种容器
| 容器 | 路径 | 内容 | 是否进 iTunes 备份 |
| --- | --- | --- | --- |
| **Bundle Container** | `/private/var/containers/Bundle/Application/<UUID>/<App>.app/` | 可执行 + 资源（ipa 解出来） | ❌（备份不含） |
| **Data Container** | `/private/var/mobile/Containers/Data/Application/<UUID>/` | App 用户数据 | ✅（受 `NSURLIsExcludedFromBackupKey` 影响） |
| **Shared Container（App Group）** | `/private/var/mobile/Containers/Shared/AppGroup/<UUID>/` | 多 App 共享（同 TeamID） | ✅ |

### 1.2 Data Container 内部
| 子目录 | 用途 | 备份归属 |
| --- | --- | --- |
| `Documents/` | 用户文档（File Sharing 暴露的目录） | ✅ |
| `Library/Preferences/<bundleid>.plist` | UserDefaults | ✅ |
| `Library/Application Support/` | App 内部数据库等 | ✅ |
| `Library/Caches/` | 缓存（系统可清） | ❌（不在备份） |
| `Library/Cookies/Cookies.binarycookies` | NSHTTPCookieStorage | ✅ |
| `Library/WebKit/` | WKWebView 持久化 | ✅ |
| `Library/SplashBoard/` | 启动图缓存 | |
| `tmp/` | 临时（系统可清） | ❌ |
| `StoreKit/` | 内购收据 | ✅ |

### 1.3 UUID ↔ bundle id 映射
- 设备内：`/private/var/mobile/Library/FrontBoard/applicationState.db`
- 备份内：通过 `Manifest.db.Files` 中的 `domain` 字段直接得到 bundle id（domain 形如 `AppDomain-<bundleid>`）。

```sql
-- applicationState.db（越狱设备）
SELECT a.application_identifier, k.value
FROM kvs k
JOIN application_identifier_tab a ON k.application_identifier=a.id
WHERE a.application_identifier LIKE '%tencent%';
```

---

## 2. 数据存储形态识别（先识别，再选解析法）

| 文件名/扩展 | 类型 | 工具 |
| --- | --- | --- |
| `*.sqlite` `*.db` | SQLite（多数 iOS App 首选） | `sqlite3`、DB Browser、Navicat |
| `*.sqlitedb` `.storedata` `.storedata-wal` | **Core Data 后端的 SQLite** | 同上，但表名前缀 `Z` |
| `*.plist`（开头 `<?xml`） | XML plist | `plutil`、`plistlib` |
| `*.plist`（开头 `bplist00`） | 二进制 plist | `plutil`、`ccl_bplist` |
| `*.archive` / 含 `$archiver` | NSKeyedArchiver bplist | `ccl_bplist.deserialise_NsKeyedArchiver` |
| `*.realm` `*.realm.lock` | Realm（Mongo 系） | Realm Studio、`realm` Python |
| `*.mmkv` 或 `mmkv*/` | MMKV（Tencent KV） | `mmkv-parser`、官方 mmkv |
| `LOG`、`MANIFEST-*`、`*.ldb`、`*.log` 同目录 | LevelDB | `plyvel` |
| `*.proto` / 无扩展 BLOB | Protobuf | `blackboxprotobuf`、`protoc` |
| `*.binarycookies` | Safari/WKWebView Cookies | `BinaryCookieReader.py` |
| `*.json` | JSON | 直接读 |
| `*.amr` `*.silk` `*.aac` `*.caf` | 音频（语音） | `silk-v3-decoder`、ffmpeg |
| `*.heic` `*.dng` `*.aae` | iOS 照片/编辑信息 | `heif-convert`、`exiftool` |
| `*.MOV` 关联 `*.HEIC` | Live Photo | exiftool 配对 |
| `Cookies.binarycookies` | 同上 | |
| 头部 `WALCache` `RDDB` | Realm 内部 | |

```bash
# 一键识别 App 沙盒
find /path/to/Container -type f -exec file {} \; | sort -u
# 找加密 SQLite（前 16 字节非 'SQLite format 3\0'）
find . -name "*.db" -o -name "*.sqlite" | while read f; do
  head -c 16 "$f" | grep -q "SQLite format 3" || echo "[CIPHER] $f"
done
```

---

## 3. SQLite 手工解析

### 3.1 标准查询模板
```sql
.tables
.schema <table>
SELECT count(*) FROM <table>;
PRAGMA table_info(<table>);
PRAGMA foreign_key_list(<table>);
```

### 3.2 时间戳列识别（**iOS 大杀器**）
- 数量级 `9~10` 位 → Unix 秒（1970）
- 数量级 `13` 位 → Unix 毫秒
- 数量级 `7~9` 位且 ≥ 5e8 → **Mac Absolute Time（2001-01-01 起）**
- 数量级 `18` 位 → Mac Absolute Time × 1e9（纳秒），常见 iOS 11+ `sms.db`
- 含 `T` 与 `Z` 的字符串 → ISO8601

```sql
-- 通用时间换算（Mac Abs → 本地）
SELECT datetime(<col>+978307200,'unixepoch','localtime') FROM t;
-- 纳秒
SELECT datetime(<col>/1000000000+978307200,'unixepoch','localtime') FROM t;
```

### 3.3 WAL 与 -shm
- 主库 `xxx.sqlite` + `xxx.sqlite-wal` + `xxx.sqlite-shm` 三件套必须**一起拷**。
- 解析时把 wal/shm 与主库放同目录，sqlite3 打开主库即自动合并。
- **取证抢救**：若设备掉电，最近写入只在 wal 里；用 `PRAGMA wal_checkpoint(FULL)` 合并到主库（**只读分析时不要做，会改时间戳**），改用副本操作。

### 3.4 删除记录恢复
- SQLite 删除是标记 free page，记录数据页可能仍在。
- 工具：
  - **undark**：扫 free page。
  - **sqlparse / sqlite-parser**：解 b-tree leaf。
  - **bring2lite**、**SQLite Deleted Records Parser**（@mdegrazia）。
- 常用：先 `sqlcipher_export` 解密为明文 → 再扫。

```bash
undark -i sms.db -d -o recovered_rows.txt
python sqlparse.py sms.db
```

### 3.5 Core Data 专项（`Z` 前缀）
- 表前缀 `Z`，主键列 `Z_PK`，类型列 `Z_ENT`，乐观锁 `Z_OPT`。
- 元数据表：`Z_PRIMARYKEY`（实体名 ↔ Z_ENT 数字）、`Z_METADATA`（plist BLOB，含 `NSStoreModelVersionHashes`、`NSPersistenceFrameworkVersion`）。
- 关系列：`Z_<REL>` 存目标 Z_PK；多对多通过 `Z_<N><A><B>` 中间表。

```sql
SELECT Z_NAME,Z_ENT FROM Z_PRIMARYKEY;        -- 实体清单
SELECT Z_PK,Z_ENT,* FROM ZRECORD WHERE Z_ENT=<n>;  -- 取某实体所有行
```

#### 典型 Core Data 库
| 库 | 实体 |
| --- | --- |
| `CallHistory.storedata` | `ZCALLRECORD`（通话） |
| `Calendar.sqlitedb` | `ZCALENDARITEM`、`ZALARM` |
| `notes.sqlite` / `NoteStore.sqlite` | `ZICCLOUDSYNCINGOBJECT`、`ZICNOTEDATA`（**新版备忘录数据 BLOB 在 `ZNOTEDATA.ZDATA` 里，gzip 后 protobuf**） |
| `Health/healthdb_secure.sqlite` | `ZQUANTITYSAMPLE`、`ZWORKOUT`、`ZLOCATIONSERIES` |
| `KnowledgeC.db` | `ZOBJECT`（事件流） |

#### 备忘录解 BLOB（高频考点）
```python
import gzip, blackboxprotobuf as p, sqlite3
con = sqlite3.connect('NoteStore.sqlite')
for pk, blob in con.execute("SELECT ZNOTEDATA.ZNOTE,ZNOTEDATA.ZDATA FROM ZICNOTEDATA ZNOTEDATA"):
    txt, _ = p.decode_message(gzip.decompress(blob))
    print(pk, txt)  # 字段 2 -> 字段 3 -> 字段 11 是富文本字符串
```

---

## 4. plist 手工解析（极高频）

### 4.1 三种格式
| 格式 | 头部 | 工具 |
| --- | --- | --- |
| XML plist | `<?xml version=` | `plutil -p`、`plistlib` |
| 二进制 plist | `bplist00` | `plutil -p`、`plistlib`（Py 3 自动识别） |
| OpenStep plist | `{ ... }` 老 NeXTSTEP 风格 | 罕见，`plutil` 也支持 |

```bash
plutil -p file.plist
plutil -convert xml1 in.plist -o out.xml
plutil -convert binary1 in.xml -o out.plist
file *.plist
```

```python
import plistlib
with open('file.plist','rb') as f:
    d = plistlib.load(f)        # 自动识别 xml/binary
```

### 4.2 NSKeyedArchiver（套娃 plist，**必考**）
特征：plist 顶层含 `$archiver=NSKeyedArchiver`、`$top`、`$objects=[...]`，每个对象内部是 `$class` 引用 + `NS.keys`/`NS.objects` UID 列表。

```python
import plistlib
import ccl_bplist
with open('MMSetting.archive','rb') as f:
    d = ccl_bplist.load(f)
    obj = ccl_bplist.deserialise_NsKeyedArchiver(d, parse_whole_structure=True)
print(obj)   # 还原成嵌套 dict/list
```

常见装这种格式的：
- 微信 `MMSetting.archive`、`mmsetting.archive.<wxid>`
- iOS 截图缓存 `*.ktx` 旁的 `*.plist`
- App Group 共享配置
- 部分 App 的 `*.archiver`

### 4.3 binarycookies
```bash
pip install pycookiecheat        # 或自写
python BinaryCookieReader.py Cookies.binarycookies
```
结构：每条 cookie 含 `creation_date`、`expiry_date`（Mac Absolute Time）、`domain`、`name`、`value`、`flags`（HTTPOnly/Secure）。

---

## 5. Realm 数据库

### 5.1 识别
- 文件 `*.realm`，伴随 `*.realm.lock`、`*.realm.management/`、`*.realm.note`。
- 头部魔数：`T-D-B`（前 4 字节 `0x54 0x2D 0x44 0x42`，对应 "T-DB"）。
- 加密 Realm：用户提供 64 字节 key + AES-256-CBC + HMAC，无 key 完全不可读。

### 5.2 工具
- **Realm Studio**（图形）：直接打开 `.realm`，读 schema + 数据。
- **realm-python** / **realm-cli**：脚本解析。
- 加密：必须有 64 字节 key（多数 App 把 key 存在 Keychain item，越狱后 dump）。

```python
import realm
config = realm.Configuration(path='app.realm', schema=[...])
r = realm.Realm(config)
for obj in r.all('Message'):
    print(obj.id, obj.text)
```

### 5.3 常见装 Realm 的 App
- 老版 WhatsApp、Wickr、部分海外 IM、健康/运动类 App、Pokemon GO 等。
- 国内 App 较少用 Realm，多数仍用 SQLite/Core Data。

---

## 6. MMKV / Protobuf / LevelDB（参 `log_and_data_parsing.md`，此处补 iOS 差异）

### 6.1 MMKV on iOS
- 路径：`Documents/MMappedKV/`、`Library/Caches/MMKV/`、Shared `AppGroup/<UUID>/MMKV/`。
- 文件名 = mmapID；`.crc` 校验文件成对。
- 微信、QQ、抖音、淘宝在 iOS 都重度使用。
- 加密 MMKV 需 16 字节 cryptKey（在 Keychain 或 SO 内）。

```python
import mmkv
mmkv.MMKV.initializeMMKV('/path/to/MMKV/parent')
kv = mmkv.MMKV('mmsetting.archive.wxid_xxx', mode=mmkv.MMKVMode.MultiProcess)
print(kv.allKeys())
```

### 6.2 Protobuf on iOS
- iOS App BLOB 字段大量是 protobuf（微信朋友圈 `SnsInfo.content`、备忘录 `ZNOTEDATA.ZDATA`、健康 `metadata`）。
- 无 .proto 时用 `blackboxprotobuf`：

```python
import blackboxprotobuf as p
data = open('blob.bin','rb').read()
val, types = p.decode_message(data)
import json; print(json.dumps(val, indent=2, ensure_ascii=False))
```

### 6.3 LevelDB on iOS
- 出现位置较少，主要在 WKWebView 的 IndexedDB、部分 Electron-like 框架。
- 路径：`Library/WebKit/<bundleid>/WebsiteData/IndexedDB/<origin>/<db>.indexeddb.leveldb/`。

---

## 7. 跨 App 共享与系统级数据库

### 7.1 系统数据库（**取证金矿**）
| 文件 | Domain | 内容 |
| --- | --- | --- |
| `sms.db` | HomeDomain → `Library/SMS/` | iMessage/SMS 全部消息 |
| `CallHistory.storedata` | HomeDomain → `Library/CallHistoryDB/` | 通话历史（Core Data） |
| `AddressBook.sqlitedb` | HomeDomain → `Library/AddressBook/` | 通讯录 |
| `AddressBookImages.sqlitedb` | 同上 | 头像 |
| `Calendar.sqlitedb` | HomeDomain → `Library/Calendar/` | 日历 |
| `Photos.sqlite` | MediaDomain → `Media/PhotoData/` | 照片元数据（GPS/人脸/burst） |
| `History.db` `Bookmarks.db` | HomeDomain → `Library/Safari/` | Safari |
| `KnowledgeC.db` | HomeDomain → `Library/CoreDuet/Knowledge/` | App 使用 + 屏幕亮灭 + 位置 |
| `interactionC.db` | 同 CoreDuet/People | 联系人交互频度 |
| `NoteStore.sqlite` | HomeDomain → `Library/Notes/`（旧） / GroupContainer 新版 | 备忘录 |
| `cache_encryptedB.db` | HomeDomain → `Library/Caches/locationd/` | 位置缓存（加密） |
| `tcc.db` | HomeDomain → `Library/TCC/` | 隐私授权日志（**谁在何时被授予相册/麦克风/位置/通讯录**） |
| `healthdb_secure.sqlite` | HealthDomain | 健康（步数、心率、地点） |
| `wallet/nanopasses.sqlite3` | HomeDomain | Wallet 卡片 |
| `Cellular/CellularUsage.db` `DataUsage.sqlite` | WirelessDomain | 蜂窝/流量 |
| `accounts3.sqlite` | HomeDomain → `Library/Accounts/` | Apple ID + 第三方账号 |
| `defaults.plist` `com.apple.preferences.* .plist` | HomeDomain → `Library/Preferences/` | 系统设置 |
| `com.apple.wifi.plist` / `com.apple.wifi.known-networks.plist` | SystemPreferencesDomain | Wi-Fi 历史 |
| `applicationState.db` | HomeDomain → `Library/FrontBoard/` | App 状态/UUID 映射 |

### 7.2 关键 SQL 模板

#### iMessage / SMS
```sql
SELECT m.ROWID,
       datetime(m.date/1000000000+978307200,'unixepoch','localtime') AS time,
       h.id AS contact, m.is_from_me, m.service, m.text, c.chat_identifier
FROM message m
LEFT JOIN handle h ON m.handle_id=h.ROWID
LEFT JOIN chat_message_join cmj ON m.ROWID=cmj.message_id
LEFT JOIN chat c ON cmj.chat_id=c.ROWID
ORDER BY m.date;
-- 附件
SELECT a.filename FROM attachment a
JOIN message_attachment_join j ON a.ROWID=j.attachment_id
WHERE j.message_id=<msg_rowid>;
```
> iOS 11+ `m.date` 是 Mac Absolute Time × 10^9（纳秒）；旧版是秒。

#### Photos.sqlite（GPS + 时间）
```sql
SELECT ZASSET.Z_PK, ZASSET.ZFILENAME, ZASSET.ZORIGINALFILENAME,
       datetime(ZASSET.ZDATECREATED+978307200,'unixepoch','localtime') AS shot,
       ZASSET.ZLATITUDE, ZASSET.ZLONGITUDE, ZASSET.ZDIRECTORY,
       ZADDITIONALASSETATTRIBUTES.ZORIGINALFILESIZE,
       ZASSET.ZTRASHEDSTATE
FROM ZASSET
LEFT JOIN ZADDITIONALASSETATTRIBUTES ON ZASSET.Z_PK=ZADDITIONALASSETATTRIBUTES.ZASSET
ORDER BY ZASSET.ZDATECREATED DESC;
```
> iOS 13+ 表名 `ZASSET`；以前 `ZGENERICASSET`。已删但未清空表 `ZTRASHEDSTATE=1`，30 天保留。

#### KnowledgeC（行为大全）
```sql
-- App 使用区间
SELECT ZOBJECT.ZVALUESTRING AS bundle_id,
       datetime(ZOBJECT.ZSTARTDATE+978307200,'unixepoch','localtime') AS start,
       datetime(ZOBJECT.ZENDDATE+978307200,'unixepoch','localtime') AS end,
       (ZOBJECT.ZENDDATE-ZOBJECT.ZSTARTDATE) AS dur_sec
FROM ZOBJECT WHERE ZSTREAMNAME='/app/usage'
ORDER BY ZSTARTDATE DESC;
-- 屏幕亮灭
SELECT ZSTARTDATE+978307200,ZENDDATE+978307200,ZVALUEINTEGER
FROM ZOBJECT WHERE ZSTREAMNAME='/display/isBacklit';
-- 位置（Significant Locations 在另一个 db，但 KnowledgeC 也有 /location 类）
SELECT * FROM ZOBJECT WHERE ZSTREAMNAME LIKE '/location%';
```

#### TCC（授权审计）
```sql
SELECT service, client, allowed,
       datetime(last_modified,'unixepoch','localtime') AS t
FROM access ORDER BY last_modified DESC;
-- service: kTCCServicePhotos / kTCCServiceMicrophone / kTCCServiceCamera ...
```

---

## 8. 加密 App 数据通解策略

### 8.1 SQLCipher 通解步骤
1. 看是不是 SQLCipher：头 16 字节不是 `SQLite format 3\0` 就基本是。
2. 找密钥来源（**优先级从易到难**）：
   - App `shared_prefs` / `UserDefaults plist` 明文字段
   - MMKV（解开 mmkv 即拿）
   - Keychain item（越狱后 keychain_dumper）
   - 从派生算法逆向 SO（IDA + frida hook `sqlite3_key`）
3. PRAGMA 参数（不同版本不同）：

```sql
-- SQLCipher 4 默认
PRAGMA key="x'<hex>'";
PRAGMA cipher_page_size=4096;
PRAGMA kdf_iter=256000;
PRAGMA cipher_hmac_algorithm=HMAC_SHA512;
PRAGMA cipher_kdf_algorithm=PBKDF2_HMAC_SHA512;
-- SQLCipher 3
PRAGMA cipher_page_size=1024; PRAGMA kdf_iter=64000;
PRAGMA cipher_hmac_algorithm=HMAC_SHA1; PRAGMA cipher_kdf_algorithm=PBKDF2_HMAC_SHA1;
```

```bash
# 一行 one-liner：解密成明文
sqlcipher cipher.db <<EOF
PRAGMA key="x'<128hex>'";
PRAGMA cipher_compatibility=4;
ATTACH 'plain.db' AS plain KEY '';
SELECT sqlcipher_export('plain');
DETACH plain;
EOF
```

### 8.2 frida hook 找 key（越狱必备）
```js
// hook sqlite3_key / sqlite3_key_v2 拿运行时 key
['sqlite3_key','sqlite3_key_v2'].forEach(n => {
  var f = Module.findExportByName(null, n);
  if (!f) return;
  Interceptor.attach(f, {
    onEnter: function(args){
      // sqlite3_key(db, key, nKey)
      var keyPtr = args[1], nKey = args[2].toInt32();
      console.log('[%s] key=%s', n, hexdump(keyPtr.readByteArray(nKey),{length:nKey,header:false,ansi:false}));
    }
  });
});
```

### 8.3 字段级加密（应用自定义）
- AES-CBC + 固定 IV、AES-GCM、ChaCha20、XOR mask……
- 套路：`shared_prefs` 找出可疑高熵字符串（base64/hex），与已知明文配对推 key。
- 详见 `apk_crypto_analysis.md`（同样适用 iOS，差别仅 SO → dylib，IDA/Hopper 都能开）。

---

## 9. iCloud / 云数据手工固定

### 9.1 哪些数据在云端
| 类别 | 同步通道 | 取证渠道 |
| --- | --- | --- |
| iCloud 备份 | 整机备份 | EPB 下载、UFED Cloud、iLeapp 接收 zip |
| iCloud Drive | CloudDocs（CloudKit） | 设备本地 `Mobile Documents/`、Web 下载 |
| 照片 | iCloud 照片图库 | 同上 + EPB |
| iCloud 钥匙串 | 端到端 | 仅 EPB（需 6 位安全码 + 2FA） |
| 信息（iMessage） | 启用"在 iCloud 中" | 集成在 iCloud 备份内 |
| 健康/家庭/屏幕使用 | E2E | 需登录 + 信任 |
| App 第三方云（CloudKit Public/Private DB） | 各 App 私有 | 看 App 是否本地缓存 |

### 9.2 云数据本地缓存位置
- `~/Library/Mobile Documents/<containerid>~<appid>/` 或 iOS 上 `/private/var/mobile/Library/Mobile Documents/`
- iOS 上对应路径同名 `Mobile Documents/`，每个 App 一个 `<TeamID>~<bundleid>/`。
- `iCloud~com~apple~CloudDocs/`：iCloud Drive 文件。
- `Library/Application Support/CloudDocs/session/db/client.db`：CloudDocs 客户端 DB（同步状态、文件 etag、版本树）。

### 9.3 iCloud 备份固定流程（合规）
1. **保留登录证据**：截屏 + 设备 UDID + 当前登录 Apple ID。
2. **保持飞行模式**直到准备好导出再连网，**避免远程擦除/抹除信号**。
3. 用 **EPB（Elcomsoft Phone Breaker）** 或 **UFED Cloud Analyzer** 登录：
   - 输 Apple ID + 密码。
   - 2FA：从受信设备读取 6 位代码（**取证应记录此过程**）。
   - 选择"下载 iCloud 备份"。
4. 导出后做 hash（SHA-256）固定。
5. 本地用 iLEAPP 的 `--type itunes` 解析（iCloud 备份解出来的目录结构与 iTunes 备份一致）。

### 9.4 token 取证（避免输密码/2FA）
- 设备已信任的 PC 上：
  - macOS：`~/Library/Keychains/login.keychain-db` 中含 Apple ID token。
  - Windows：`%APPDATA%\Apple Computer\iCloud\Account\` + Keychain 等。
- iOS 设备：`/private/var/mobile/Library/Accounts/Accounts3.sqlite` 含 `ZAUTHTOKEN`，越狱后导出，用 EPB 输入 token 模式登录，不用输密码/2FA。

### 9.5 已开启"高级数据保护"（ADP）
- iCloud 备份/Drive/照片/Wallet 等改 E2E。
- Apple **法律调取拿不到内容**。
- 取证只能依赖：
  - 已信任设备本地副本。
  - 受信任的备份联系人/恢复密钥。
  - 设备本身物理取证。
- 题目里看到 "Apple 已声明无法响应" → 八成考的就是 ADP。

### 9.6 第三方云 App
- 钉钉、企业微信、飞书、Microsoft 365、Google Drive 等：本地多有缓存数据库，云端需额外授权调取。
- WhatsApp：iCloud 自有备份（`Mobile Documents/iCloud~net~whatsapp~WhatsApp/`）含 `ChatStorage.sqlite`（**iOS 默认无密**，可直接读）。

---

## 10. 比赛/实战题型与解法

### 10.1 类型 A：给一个 App 沙盒目录，问"X 时间嫌疑人和谁聊了什么"
1. 列文件 → 识别 SQLite/plist/Realm/MMKV。
2. 找消息库（`*chat*.sqlite` `*msg*.db`）；判加密 → 解密。
3. 若是 Core Data，看 `Z_PRIMARYKEY` 找消息实体。
4. 时间列按数量级换算 Mac Abs / Unix。
5. 关联联系人表，输出 `时间-对象-内容`。

### 10.2 类型 B：照片来源/拍摄设备/GPS
- `Photos.sqlite` → `ZASSET`，含设备型号 `ZADJUSTMENTSSTATE`、`ZORIGINALFILENAME`。
- 文件本身 `exiftool IMG_xxxx.HEIC` 拿 EXIF/GPS。
- iOS Live Photo：`.HEIC` + `.MOV` 同名配对，组合分析。
- AAE 文件：包含编辑历史（裁剪/滤镜），bplist 内含 `adjustmentBaseVersion`、`adjustmentEditorBundleID`。

### 10.3 类型 C：屏幕使用/在场证明
- `KnowledgeC.db.ZOBJECT` `/app/usage` `/display/isBacklit` `/device/isPluggedIn`。
- 与照片/通话/位置时间线交叉。

### 10.4 类型 D：iCloud 取证流程描述题
- 答题模板：
  1. 现场断网 + 飞行模式（避免远程擦除）。
  2. 优先做物理/iTunes 加密备份。
  3. 取得 Apple ID + 密码 + 2FA → EPB 下载 iCloud 备份 + 各类别。
  4. 取受信 PC 的 token 作免密登录备选。
  5. 全程做 hash 固定 + 截屏过程记录。
  6. 注意 ADP（端到端）情况下云端不可得。

### 10.5 类型 E：定位"嫌疑人手机型号 + iOS 版本 + UDID"
- 任意 iTunes 备份 → `Info.plist` 一把全有。
- 物理镜像 → `/private/var/mobile/Library/Lockdown/data_ark.plist`。

### 10.6 类型 F："Apple ID 是什么 / 何时登录"
- `accounts3.sqlite` → `ZACCOUNT`、`ZACCOUNTTYPE`、`ZUSERNAME`（明文 Apple ID）。
- `com.apple.MobileMeAccounts.plist`（DSID）。
- `KnowledgeC.db` 中 Apple ID 切换事件较少出现，配合 `accountsd` 日志看（参 `ios_logs.md`）。

---

## 11. 命令速查

```bash
# 识别 App 沙盒所有文件类型
find /Container -type f -exec file {} \; | sort -u

# 找加密 SQLite
find . -name "*.db" -o -name "*.sqlite" | while read f; do
  head -c 16 "$f" | grep -q "SQLite format 3" || echo "[CIPHER] $f"
done

# 解 NSKeyedArchiver
python -c "import ccl_bplist as c, sys; f=open(sys.argv[1],'rb'); d=c.load(f); o=c.deserialise_NsKeyedArchiver(d); import json; print(json.dumps(o, default=str, indent=2, ensure_ascii=False))" file.archive

# Mac Abs Time → ISO
python -c "import datetime,sys;print(datetime.datetime(2001,1,1)+datetime.timedelta(seconds=float(sys.argv[1])))" 716832000

# Photos.sqlite GPS dump
sqlite3 Photos.sqlite "SELECT ZFILENAME,ZLATITUDE,ZLONGITUDE,datetime(ZDATECREATED+978307200,'unixepoch','localtime') FROM ZASSET WHERE ZLATITUDE IS NOT NULL;"

# 备忘录 BLOB → 文字
python - <<'EOF'
import sqlite3, gzip, blackboxprotobuf as p
con=sqlite3.connect('NoteStore.sqlite')
for note,blob in con.execute("SELECT ZNOTE,ZDATA FROM ZICNOTEDATA"):
    if not blob: continue
    try: data=gzip.decompress(blob)
    except: data=blob
    val,_=p.decode_message(data)
    print(note, str(val)[:300])
EOF

# Realm 简看
python -c "import realm; r=realm.Realm.open_with_path('a.realm'); print(r.schema)"

# binarycookies
python BinaryCookieReader.py Cookies.binarycookies

# SQLCipher 解密成明文（参数依版本调整）
sqlcipher cipher.db <<EOF
PRAGMA key="x'<128hex>'";
PRAGMA cipher_compatibility=4;
ATTACH 'plain.db' AS p KEY '';
SELECT sqlcipher_export('p');
DETACH p;
EOF

# iLEAPP 一键解析（iTunes/iCloud 备份/全文件系统）
ileapp -t itunes -i /Backup/<UDID> -o /tmp/ileapp_out
```

---

## 12. 常见坑

1. **时间戳混用**：iOS 里 Mac Abs（秒/纳秒）、Unix 秒、毫秒都有，**先看数量级再选公式**；微信/QQ 在 iOS 上仍多用 Unix 秒。
2. **WAL/-shm 丢失**：拷数据库一定带 wal/shm；只读分析切勿 `PRAGMA wal_checkpoint`，会触发写。
3. **Core Data 关系不在表里直接显示**：要看 `Z_<REL>` 列以及中间表 `Z_<N><A><B>`。
4. **NSKeyedArchiver 套娃**：`plutil -p` 看到的是 UID 引用图，必须用 `ccl_bplist` 反序列化。
5. **NoteStore 新版加密 BLOB**：`ZDATA` 是 gzip+protobuf，里面又分段，文本不在最外层。
6. **照片 burst/livephoto/heic** 不要漏：burst 同 `ZBURSTUUID`、livephoto `.HEIC + .MOV` 同名、HEIC 需转 JPG 才能给一般工具看 EXIF。
7. **iCloud Photos 优化**：本地若开了"优化存储"，相册里只有缩略图，原图在云端，**不能只看 Photos.sqlite 数量就当全有**。
8. **Cookies.binarycookies 时间是 Mac Abs**，别按 Unix 解。
9. **TCC.db 只有"被授权过"的记录**：被拒绝且未再询问的 App 没有行；不能由 TCC 反推"绝对没用过"。
10. **Realm 加密 key 64 字节**：32 字节是 AES key、32 字节是 HMAC key，少一段就不行。
11. **Mobile Documents 不全**："优化存储"会让本地只有占位 stub，实际数据在 iCloud；要联网下载或线下从 iCloud 备份取。
12. **ADP 开启**：iCloud 备份 + Drive + Photos + Wallet 等被 E2E，**法律调取无果**；现场必须最大化物理 + 已信任设备数据。
13. **多 App Group**：同一 TeamID 下多 App 共享，关键数据可能在 `Containers/Shared/AppGroup/<UUID>/` 而非 App Data 容器；查 App 的 `*.entitlements`（在 .app 内）确认 group id。

---

## 13. 交叉链接
- `ios_forensics.md`：iOS 取证总览
- `ios_fundamentals.md`：iOS 文件系统/安全机制/备份/越狱
- `ios_logs.md`：iOS 日志体系
- `wechat_deep_dive.md`：iOS 微信路径
- `popular_apps_forensics.md`：QQ/抖音/支付宝 iOS 路径
- `log_and_data_parsing.md`：通用 SQLite/Realm/MMKV/Protobuf 解法
- `apk_crypto_analysis.md`：加密算法逆向通法（iOS 同样适用）
- `geolocation_forensics.md`：照片 GPS / KnowledgeC location
- `timestamps_reference.md`：Mac Absolute Time 换算
