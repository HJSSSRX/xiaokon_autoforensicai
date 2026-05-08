# 数据库取证深度专题（结构 / 存储 / 删除恢复 / 加解密）

> 适用：手机/PC App 中的数据库题。题目特征：见到 `SQLite format 3`、`-wal`、`-journal`、`-shm`、`free page`、`freeblock`、`undark`、`SQLCipher`、`WCDB`、`Realm`、`LevelDB`、`MANIFEST`、`*.ldb`、`Berkeley DB`、`MMKV`、`Couchbase Lite`、`ObjectBox`、`已删除消息恢复`、`数据库加密`、`字段加密` 等。
>
> 与 `log_and_data_parsing.md`、`ios_app_parsing.md`、`wechat_deep_dive.md` 互补：那些偏 App 数据流，本文偏**数据库底层结构 + 通用恢复/解密原理**。

---

## 1. 主流数据库类型速查

| 类型 | 引擎 | 文件特征 | 典型场景 |
| --- | --- | --- | --- |
| **关系型 SQLite** | sqlite3 | 头 16 字节 `SQLite format 3\0` | Android/iOS 80%+ App 首选 |
| **加密 SQLite** | SQLCipher / WCDB / 自定义 | 头不是 `SQLite format 3`（整库加密），或可正常打开但字段加密 | 微信、QQ NT、抖音、支付宝、Signal、WhatsApp（Android） |
| **Core Data**（Apple） | 上层封装 SQLite | 表名 `Z*` 前缀 | iOS 系统库、Notes、CallHistory、Photos |
| **Realm** | 自研 mmap+B+树 | 头 4 字节 `T-DB`（`0x54 0x2D 0x44 0x42`） | WhatsApp（旧）、Wickr、健康类 App |
| **LevelDB** | KV LSM-tree | 目录含 `LOG`、`MANIFEST-*`、`*.ldb`、`*.log`、`CURRENT` | Chromium IndexedDB、Electron、部分 Android App |
| **ObjectBox** | 自研 | `data.mdb` + `lock.mdb`（基于 LMDB） | Android 性能型 App |
| **Couchbase Lite** | SQLite 后端 + JSON | `*.cblite2/db.sqlite3` | 部分企业 App、iOS App |
| **Berkeley DB**（DBM） | hash/btree 文件 | 文件头 `0x00053162` 等魔数 | 老 Linux/Android 系统 |
| **MMKV** | mmap+protobuf | 文件 + `.crc` | 微信/抖音/QQ 等 KV 配置 |
| **plist / UserDefaults** | XML/bplist | `<?xml` / `bplist00` | iOS 配置 |
| **SharedPreferences XML** | 文本 XML | `<?xml ...><map>` | Android 配置 |
| **PostgreSQL/MySQL/Oracle** | 服务器 | `PG_VERSION` / `ibdata1` / `*.dbf` | 服务器取证（非常规手机题） |
| **Firebase/Realtime DB** | 云端 | 本地 `firestore.db`/`PersistedQueue.db` | 部分 Android App |

> **解题第一步：永远先 `file *` + `xxd | head -c 64` 看头部，识别是哪种引擎，再选解析路径。**

---

## 2. SQLite 内部结构（深度，必懂）

### 2.1 数据库文件分页
- 整个 `.db` 由若干 **page** 组成，page size 在文件头第 16-17 字节（默认 4096，旧 1024）。
- 每页类型：
  - **Page 1（头页）**：100 字节 DB Header + 第一张表 sqlite_schema 的 b-tree root。
  - **B-tree internal page**：导航。
  - **B-tree leaf page**：放真正记录。
  - **Overflow page**：单条记录 > 页大小时，溢出到链表式后续页。
  - **Free page / Freelist**：被删的页，链入 freelist trunk。
  - **Pointer map page**（启用 auto_vacuum 时）：记录每页的"父页"。
  - **Lock byte page**：第 1GB 处的特殊页。

### 2.2 文件头关键字段（offset → 含义）
| 偏移 | 字段 |
| --- | --- |
| 0–15 | `SQLite format 3\0` 魔数（**未加密就有，加密则无**） |
| 16–17 | page size（大端，2 字节，`0x10 0x00` = 4096） |
| 18 | file format write version（1 = legacy，2 = WAL） |
| 19 | file format read version |
| 24–27 | file change counter（每次写 +1） |
| 28–31 | 总 page 数 |
| 32–35 | first freelist trunk page（**删除恢复入口**） |
| 36–39 | freelist 总页数 |
| 56–59 | text encoding（1=UTF-8、2=UTF-16le、3=UTF-16be） |
| 60–63 | user_version |
| 92–95 | last sqlite version |
| 96–99 | sqlite version number |

### 2.3 记录格式（B-tree Cell）
每条记录（row）= **payload** = `[header_size][serial_types...][values...]`。
- header_size 是 varint。
- 每列一个 serial_type（varint）：
  - 0 NULL；1–6 整数（1/2/3/4/6/8 字节）；7 double；8/9 = 整数 0/1（无 payload）
  - N≥12 偶数 → BLOB，长度 (N-12)/2
  - N≥13 奇数 → TEXT，长度 (N-13)/2
- 行 ID（rowid）= varint，紧挨 payload 之前。
- **理解 serial_type 是手工恢复删除记录的关键**。

### 2.4 WAL / Rollback Journal（**取证宝藏**）
| 模式 | 文件 | 作用 |
| --- | --- | --- |
| Rollback journal（默认） | `<db>-journal` | 写前镜像，事务失败回滚；事务成功后清空（但内容仍可能残留） |
| WAL | `<db>-wal` + `<db>-shm` | 新写先入 wal，checkpoint 时合并到主库 |
| Memory journal | 仅内存 | 无文件 |
| Off | 无 | 不安全 |

#### WAL 文件结构
- 32 字节 wal header + 多个 frame，每 frame = 24 字节 frame header + 1 个 page（含完整该页内容）。
- 每个 frame 标有 commit flag（最后一帧的 commit_size 非零表示一次 commit）。
- 取证：
  - **wal 中的页可能比主库新**（未 checkpoint）→ 最近写入的"消息"只在 wal。
  - **wal 中的旧 frame 也可能保留某条记录被删除前的副本**（同页早期版本仍在）。

#### -journal 取证
- 文件首 8 字节 `0xd9d505f920a163d7` = "活动 journal"，全 0xff = 已 commit/截断。
- 页镜像直接是被覆盖前的整页 → **可恢复 commit 前的旧值**。

### 2.5 sqlite_schema（旧名 sqlite_master）
- 表 `sqlite_master` / `sqlite_schema`：所有对象（表/索引/视图/触发器）的定义。
- 列：`type, name, tbl_name, rootpage, sql`。
- 取证：DROP TABLE 后此表删除行 → 可能仍能恢复表 schema。

```sql
SELECT type,name,tbl_name,rootpage,sql FROM sqlite_master;
```

### 2.6 关键 PRAGMA（只读分析）
```sql
PRAGMA page_size;              -- 页大小
PRAGMA page_count;             -- 总页数
PRAGMA freelist_count;         -- 空闲页数（**>0 说明有删除痕迹**）
PRAGMA integrity_check;        -- 完整性
PRAGMA journal_mode;           -- WAL/DELETE/TRUNCATE/PERSIST/OFF
PRAGMA wal_checkpoint(PASSIVE);-- 不要在原盘做（会写）！
PRAGMA cell_size_check=ON;
PRAGMA schema_version;
```
> **铁律**：分析时只读副本（`cp` 出来 + `chmod -w`）；切勿在原盘上做 `wal_checkpoint`/`VACUUM`。

---

## 3. SQLite 删除恢复原理与方法

### 3.1 删除发生了什么
SQL `DELETE FROM t WHERE ...`：
1. 从 b-tree leaf page 找到对应 cell。
2. cell 标记为 freeblock（在该页 cell 区域内变为空闲块），cell 数据**仍在**，仅 cell pointer array 中的指针被移除。
3. 页内 freeblock 链表头指向被删 cell 起始位置（在页头 offset 1–2 的 first freeblock pointer）。
4. 若整页都没记录了 → 该页加入 freelist。
5. **数据本身原文未擦除**，下次新写记录复用空间时才覆盖。
6. `VACUUM` 会真正搬移并 truncate 文件 → **VACUUM 后基本无法恢复**。
7. `secure_delete=ON`（默认 OFF）→ 删除时清零；某些系统 db（如 iOS sms.db）显式开启 → 删除消息无残留。

### 3.2 三类残留区域
| 区域 | 内容 | 工具 |
| --- | --- | --- |
| **页内 freeblock**（leaf page 中的"空隙"） | 已删但页未释放，记录原文仍在 cell 数据区 | undark、bring2lite、sqlite-parser |
| **freelist 页** | 整页释放后入空闲链；该页 b-tree 内容多数仍在 | 同上 |
| **WAL/journal** | 较新或被覆盖前的旧页副本 | walitean、自写脚本 |
| **未分配尾部** | 文件 truncate 后被覆盖前的尾部 | binwalk、strings |

### 3.3 实战工具
| 工具 | 平台 | 用途 |
| --- | --- | --- |
| **undark** | C，跨平台 | 扫描全部 page 的 free space + freelist，dump 行 |
| **bring2lite** | Python | 高质量 cell 解析（含 schema 推断） |
| **sqlparse / sqlite_parser**（多版本） | Python | 单页 cell 分析 |
| **SQLite Deleted Records Parser**（@mdegrazia） | Python | 老牌脚本，输出 csv |
| **walitean / WALitean** | Python | 专扫 WAL frame |
| **DB Browser for SQLite** | GUI | 查看 cell（不能恢复） |
| **Magnet AXIOM / Cellebrite Inspector / 美亚** | 商业 | 自动化、含报告 |

```bash
# undark
undark -i suspect.db -d -o recovered.txt          # 默认含 freelist + freeblocks
undark -i suspect.db --freespace-only

# bring2lite
python3 bring2lite.py -i suspect.db -o /tmp/out --recover-deleted

# 手动看 freelist 头页号
sqlite3 suspect.db "PRAGMA freelist_count;"
xxd suspect.db | sed -n '1,8p'   # 偏移 32-35 是 first freelist trunk page

# 在 wal 里搜匹配模式
strings -n 8 suspect.db-wal | grep -E "wxid_|@chatroom|创建时间"
```

### 3.4 已知 schema 时的"靶向"恢复
1. 知道表的 schema（列数、列类型）→ 算出 serial_type 序列特征。
2. 在原始 page bytes 中扫匹配模式（如"4 列：INT, INT, TEXT, BLOB" → header 长度近似已知）。
3. 比对 rowid 范围（递增整数），定位记录边界。
4. 输出候选行。

> **bring2lite** 已实现"按已知 schema 扫"，比 undark 误报少得多。

### 3.5 几种"删了也救不回来"的情况
1. `VACUUM` 已执行（手动或 `auto_vacuum=FULL`）。
2. `secure_delete=ON` 且无 wal 历史。
3. 删除后产生大量新写覆盖（高频聊天/日志库尤甚）。
4. WAL 已 checkpoint + journal 已截断 + 主库被 vacuum。
5. SQLCipher 加密库的"垃圾"也是密文，但**解密后**仍按上述逻辑可恢复。

### 3.6 iOS sms.db 特例
- 默认 `secure_delete=ON` → 删除短信不留 cell 副本。
- 但 **附件 BLOB 不在 sms.db 里**，在 `Library/SMS/Attachments/`，**文件本身可独立存在**（即便 sms.db 删除了引用）。
- iMessage 在 iCloud 中可能仍存（"信息储存于 iCloud"开启时云端有副本）。

### 3.7 微信/QQ 已删消息恢复套路
- **微信 EnMicroMsg.db**：旧版默认 secure_delete OFF → 大量可恢复；新版 WCDB 改用多 db + 增量删除策略，恢复率下降。
- **PC 微信 MSG*.db**：SQLCipher 解密后的明文 db 可继续做删除恢复；wal 仍是金矿。
- **QQ Android `mr_msg_<QQ>_*`**：字段级 RC4 加密，恢复出来需要再解字段；rowid 区分发送/接收。
- **iOS 微信 MM.sqlite**：多无加密，删除消息条目有时仍在 wal/free page。

---

## 4. SQLCipher 深度

### 4.1 SQLCipher 是什么
- 在 SQLite 上做的整库加密扩展（开源 + 商业）。
- 每页前 16 字节是 IV，剩余密文 + 16 字节 HMAC（默认 SHA1，4 起 SHA512）。
- 密钥派生：用户 passphrase / raw key → PBKDF2 → AES-256-CBC 页加密 + HMAC 完整性校验。
- **判别**：`xxd file.db | head -1` 不是 `SQLite format 3` 即可疑。

### 4.2 版本与默认参数（**必背**）
| 主版本 | KDF | 迭代 | Page | HMAC | 备注 |
| --- | --- | --- | --- | --- | --- |
| **1** | PBKDF2-SHA1 | 4000 | 1024 | 无 | 旧版微信 EnMicroMsg.db |
| **2** | PBKDF2-SHA1 | 4000 | 1024 | HMAC-SHA1 | iOS WhatsApp 老版 |
| **3** | PBKDF2-SHA1 | 64000 | 1024 | HMAC-SHA1 | Signal 早期、PC 微信旧 |
| **4** | PBKDF2-SHA512 | 256000 | 4096 | HMAC-SHA512 | 现代默认 |

打开时 PRAGMA 决定行为，**版本不对就错**。

### 4.3 PRAGMA 速记
```sql
-- v4 默认（最常见）
PRAGMA key = "x'<128hex 64-byte raw>'";
-- 或 passphrase
PRAGMA key = 'mypassword';
PRAGMA cipher_page_size = 4096;
PRAGMA kdf_iter = 256000;
PRAGMA cipher_hmac_algorithm = HMAC_SHA512;
PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;

-- v3 兼容（常见 PC 微信、Signal 老）
PRAGMA cipher_compatibility = 3;
-- 或显式
PRAGMA cipher_page_size=1024; PRAGMA kdf_iter=64000;
PRAGMA cipher_hmac_algorithm=HMAC_SHA1;
PRAGMA cipher_kdf_algorithm=PBKDF2_HMAC_SHA1;

-- v1 兼容（旧微信 EnMicroMsg）
PRAGMA cipher_use_hmac = OFF;
PRAGMA cipher_page_size = 1024;
PRAGMA kdf_iter = 4000;
PRAGMA cipher_hmac_algorithm = HMAC_SHA1;
PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1;
```

### 4.4 "解密成明文"的标准操作
```sql
sqlcipher cipher.db
PRAGMA key = 'xxx';
-- ...其它 PRAGMA 视版本
ATTACH DATABASE 'plain.db' AS plain KEY '';
SELECT sqlcipher_export('plain');
DETACH DATABASE plain;
.exit
```
之后 `plain.db` 可用任意工具打开 + 做删除恢复。

### 4.5 raw key 与 salt
- 32 字节 raw key（64 hex）= 直接当 cipher key（无 KDF）。
- 但 SQLCipher v4 仍会用前 16 字节 salt（DB header 头 16 字节）派生 HMAC key → key 必须配该 db；换库不可通用。
- 输入格式：`PRAGMA key = "x'<64hex salt + 64hex key>'"`（96 字节，SQLCipher 4+ 支持）。

### 4.6 密钥来源（按优先级）
1. **明文存于 shared_prefs / UserDefaults / xml**（少见但存在）。
2. **MMKV / 配置 plist** 内（中等概率）。
3. **Keychain / Keystore**：iOS keychain item / Android Keystore，需提取后调用解密。
4. **SO / dylib 内派生**：常见于微信、抖音；frida hook `sqlite3_key`/`sqlite3_key_v2` 拿。
5. **从 IMEI/AndroidID/uin/wxid 派生**：旧微信 `MD5(IMEI+uin)[:7]`、各 App 自家算法（看 `apk_crypto_analysis.md`）。
6. **PC 端进程内存 dump**：微信/QQ NT 都靠这个。
7. **★ 密码 = 文件名 hex 本身**（小作坊新模式）：见下 §4.6.1。

### 4.6.1 SQLCipher 密码常见构造对照表

| 派生方式 | 实例 | 见于 |
| --- | --- | --- |
| **常量字符串硬编码**（jadx 一搜即得） | `setPassword("MyApp2024!@#$%^&*")` | 80% 小作坊 App |
| **`MD5(IMEI + UIN)[:7]`**（小写 hex 截 7 位） | `f3a9b1c` | 微信 EnMicroMsg.db（旧版 ★经典） |
| **`MD5(seed).hex()[:16]`** | `3ffc0b996b851d80` | 2026 FIC Q15 类、众多 App |
| **`SHA-256(seed)[:16]` / `[:32]`** raw bytes | 32 字节原始 | 中等水平自研 App |
| **PBKDF2(passphrase, salt, 64000+, 32)** | 用户密码派生 | Signal、新版 Android WhatsApp |
| **设备 + 账号绑定**：`MD5(AndroidID + userid + 常量)[:16]` | 跨设备失效 | 支付宝、QQ NT |
| **★ 密码 = 文件名 hex**（**懒人式新范式**） | `wk_9628874a3c6b403593766496fa985893.db` 密码 = `9628874a3c6b403593766496fa985893` | 2026 FIC 自研聊天 App |
| **密码 = 包名 / 包名+版本号** | `com.example.app1.0.0` | 极小作坊 |
| **密码 = 用户手机号 / 用户 UID** | `13800138000` | 部分财务/记账 App |
| **HMAC(IMEI, 固定 key)** | 16 字节原始 | 部分国产 IM |

**速试套路（看到 SQLCipher 库不知道密码时）**：
```python
# 候选密码生成器（去重后逐一试 sqlcipher_decrypt）
candidates = [
    fname_hex,                              # ★ 文件名 hex（去 wk_/.db 前后缀）
    pkg_name,                               # com.example.app
    pkg_name + version,                     # com.example.app1.2.3
    md5(seed.encode()).hexdigest()[:16],    # 资源串 MD5 hex 前 16
    md5(seed.encode()).digest()[:16],       # raw
    sha256(seed.encode()).digest()[:16],
    md5((imei + uin).encode()).hexdigest()[:7],
    imei,
    android_id,
    user_phone,
    user_uid,
    "1234567890123456",                     # 简单常量
]
```

### 4.6.2 双库模式（明文索引 + 加密聊天）— **2026 FIC 新出现**

**结构**：
```
/data/<pkg>/databases/
├── index.db              # 明文 SQLite，含 conversations / users / settings
└── wk_<32 位 hex>.db     # SQLCipher 加密，含 message 表
```

**取证流程**：
1. 先 `file *.db` 区分明文与加密；
2. 明文 `index.db` 直接 sqlite3 打开 → 找到当前用户对应的加密库文件名；
3. 加密库 `wk_<hex>.db` 用文件名 hex 当密码尝试；
4. 失败再上 §4.6 第 4 项 frida hook。

**对应 jadx 关键字搜索**：
```
SQLiteOpenHelper / SQLiteDatabase.openOrCreateDatabase
WCDB / SQLCipher / setPassword / cipher_compatibility
DATABASE_NAME / dbName / "wk_"
```

### 4.7 frida hook 拿 raw key
```js
['sqlite3_key', 'sqlite3_key_v2', 'sqlite3_rekey', 'sqlite3_rekey_v2'].forEach(n => {
  var addr = Module.findExportByName(null, n);
  if (!addr) return;
  Interceptor.attach(addr, {
    onEnter(args){
      // sqlite3_key(db, key, nKey)  /  v2(db, dbName, key, nKey)
      var keyArg = (n.endsWith('v2')) ? args[2] : args[1];
      var nArg   = (n.endsWith('v2')) ? args[3] : args[2];
      var n_     = nArg.toInt32();
      console.log('[%s] %s', n, hexdump(keyArg, {length: n_, header: false, ansi: false}));
    }
  });
});
```

### 4.8 爆破 SQLCipher
- 仅当**密码空间小**（4–6 位数字 PIN、字典）才有意义。
- 工具：
  - `sqlcipher_decryptor`（试 PRAGMA + key）
  - 自写 OpenSSL：每个候选 key 派生→解第 1 页→看头部是不是 `SQLite format 3`。
- v4 默认 256000 PBKDF2-SHA512，单线程秒级几十万次量级；GPU 加速有限。

```python
# Python 自写爆破核心
import hashlib, hmac
from Crypto.Cipher import AES
def try_key(db_bytes, page_size, kdf_iter, password):
    salt = db_bytes[:16]
    key  = hashlib.pbkdf2_hmac('sha512', password.encode(), salt, kdf_iter, 64)
    iv   = db_bytes[page_size-48:page_size-32]   # 末尾 16B IV (v4)
    ct   = db_bytes[16:page_size-48]
    pt   = AES.new(key[:32], AES.MODE_CBC, iv).decrypt(ct)
    return pt.startswith(b'SQLite format 3\0') or pt[:6] == b'\x0d\x00\x00'  # 第一页 b-tree
```

### 4.9 SQLCipher 删除恢复
- 解密成明文后再用 undark/bring2lite。
- 注意：**WAL 也是加密的**（每 frame 单独加密），需 SQLCipher 支持的方式整体解，不能只解主库。
- iLEAPP/AXIOM 内置流程：解密 → 导出明文 → 跑恢复。

---

## 5. WCDB（Tencent）特殊处理

### 5.1 是什么
- 微信团队基于 SQLCipher v3 修改的版本，加了 ORM/线程模型，**底层加密机制基本同 SQLCipher v3**。
- 文件外观和 SQLCipher 一样：头部不是 `SQLite format 3`。

### 5.2 关键差异
- WCDB 的 page_size = 4096（与 SQLCipher v3 默认 1024 不同），**这是常见踩坑点**。
- HMAC = SHA1，KDF = PBKDF2-SHA1，iter 通常 64000。
- key 可以是 passphrase 也可以是 raw 32B。

```sql
PRAGMA key = 'xxx';
PRAGMA cipher_page_size = 4096;
PRAGMA kdf_iter = 64000;
PRAGMA cipher_hmac_algorithm = HMAC_SHA1;
PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1;
```

### 5.3 微信新版（7.x+ Android）
- 部分库 key 改成"App 启动时随机生成 → 存 Android Keystore"。
- 必须 root + 提取 Keystore + 走 keystore daemon 解。
- 商业取证软件已固化；自研需 frida 在运行时 hook 拿 key。

---

## 6. Realm 内部与解密

### 6.1 文件结构
- 头 4 字节 `T-DB`（54 2D 44 42）+ 版本 + group ref + commit ID。
- Realm 是 mmap 直接读，page size 通常 4096。
- 含 history、versioning、写时复制（每次写不覆盖原数据，旧版本仍在）→ **天然支持回溯**。

### 6.2 加密 Realm
- 64 字节 key：前 32 = AES-256-CBC、后 32 = HMAC-SHA256。
- key 多存在 iOS Keychain item / Android Keystore；少数 App 直接写 plist。
- 无 key 完全打不开。

### 6.3 工具
- **Realm Studio**（GUI）：直接打开 `.realm`（含加密：输入 64 字节 hex）。
- **realm Python SDK**：但需要 schema 才能反射；没有 schema 时用 [realm-rs](https://github.com/realm/realm-core) 的 `realm-browser-cli` 之类工具。
- **realm-cli**（旧）。

```python
import realm
config = realm.RealmConfig(path='a.realm', encryption_key=b'\x...')  # 64 bytes
r = realm.Realm(config)
print(r.schema)
for o in r.objects('Message'):
    print(o.id, o.text)
```

### 6.4 Realm 删除恢复
- Realm 写时复制 → 旧版本可能在文件中一直存在直到 compact。
- 工具支持有限；**实战通常用 realm-core 的 historical version 切换**：

```bash
# 查看历史 commit
realm-browser-10 a.realm --history
```

---

## 7. LevelDB 与 IndexedDB

### 7.1 LevelDB 文件
- 目录而非单文件，含：
  - `CURRENT`：当前 manifest 文件名
  - `MANIFEST-NNNNNN`：版本元数据
  - `*.log`：MemTable 写前日志（最近未 compact 的写）
  - `*.ldb` / `*.sst`：SSTable 数据
  - `LOCK`：进程锁
- LSM-tree：写放大、删除是"墓碑标记"而非真删 → **删除项可在更老 SSTable 中找回**直到 major compact。

### 7.2 IndexedDB（Chromium/Electron/WKWebView）
- 路径：
  - Android Chrome: `app_chrome/Default/IndexedDB/<origin>/`
  - iOS WKWebView: `Library/WebKit/<bundleid>/WebsiteData/IndexedDB/<origin>/<db>.indexeddb.leveldb/`
  - Electron App: `Library/Application Support/<App>/IndexedDB/`
- 内含 LevelDB 子目录；KV 中的 value 是 V8 序列化对象（**SSV / structured clone**），需要 V8 反序列化才能读。

### 7.3 工具
```bash
pip install plyvel
```
```python
import plyvel
db = plyvel.DB('./leveldb_dir', create_if_missing=False)
for k, v in db:
    print(k[:60], v[:60])
```
- V8 序列化解 KV：用 `node ccs.js` / `pyV8serialize` / `node-v8-serialize` 等。
- 命令行：`leveldbutil dump *.ldb`（自带源码）。

### 7.4 删除恢复
- 老 SSTable 不主动删 → 直接读 `*.ldb` 的 KV 仍可见已被墓碑标记的"老值"。
- `*.log` 中的 KV 是最新写入；含未持久化数据。
- **取证流程**：先 list 所有 KV 含墓碑 → 再合并取最新 → 比对差异。

---

## 8. ObjectBox / Couchbase Lite / Berkeley DB

### 8.1 ObjectBox
- 基于 LMDB（B+ 树 mmap），文件 `data.mdb` + `lock.mdb`。
- 不加密（默认）；加密版用 AES。
- 工具：ObjectBox 官方 Java/Kotlin SDK；**取证手工解析较复杂**，无主流通用工具。
- 替代：把 `data.mdb` 当 LMDB 用 `python-lmdb` 读 raw KV：

```python
import lmdb
env = lmdb.open('./obj_dir', readonly=True, lock=False, subdir=True)
with env.begin() as txn:
    for k, v in txn.cursor():
        print(k[:60], v[:60])
```

### 8.2 Couchbase Lite
- 后端 SQLite（`db.sqlite3`）+ JSON 文档 + 全文索引。
- 加密用 SQLCipher 同款。
- 直接 sqlite3 打开 → 表 `kv_default`（key, body, type）；body 是 fleece 二进制（Couchbase 自家 JSON 二进制格式）→ 用 `python-fleece` 或 SDK 解。

### 8.3 Berkeley DB
- 已基本被淘汰，但旧 Android 系统 db 偶见。
- 工具：`db_dump`、`db_load`、`dbsql`。
- 文件头偏移 12 处的 magic 决定类型（hash/btree/queue）。

---

## 9. 字段级加密（数据库未加密但字段加密）

### 9.1 常见形态
- 数据库可正常打开 + 表可读，但某些字段是 BLOB / Base64 / hex / 长串数字看似随机。
- 算法常见：AES-CBC（固定 IV）、AES-GCM、ChaCha20、XOR mask、自家魔改。
- key 来源：固定字符串、硬编码、IMEI 派生、当前用户密码、随机 + 存别处。

### 9.2 识别
- 字段长度恒为块对齐倍数（16 的倍数 → 多半 AES-CBC/ECB）。
- 同明文重复 → 多半 ECB 或固定 IV CBC（取证可标）。
- Base64 字符集 + `=` 末尾。
- Hex 全 `0-9a-f`。

### 9.3 解法套路
1. 在 App SO/dylib 中搜 SQLite/字段相关 native 调用栈。
2. frida hook `EVP_DecryptInit_ex`、`AES_set_decrypt_key`、`CCCryptorCreate`、`javax.crypto.Cipher.init`、`Mac.init`，监听调用参数 → 拿 key + IV。
3. 静态：strings + IDA 找类似 `aes`、`cipher`、`encrypt`、`Base64` 字符串及其交叉引用。
4. 已知明文配对：找一对"明文-密文"（如登录 token 在 shared_prefs 与 db 中各有一份），反推 key。
5. 若是 XOR：`xor_with_known_plaintext` → 求 mask 周期。

### 9.4 常见 App 字段加密
| App | 字段 | 算法 |
| --- | --- | --- |
| QQ Android | `mr_msg_*.msgData` | RC4，key 与 uin 相关 |
| 抖音 `im.db` 字段 | 部分字段 AES-CBC | key 在 MMKV |
| 支付宝 `socialChat_*.chatmsg` | BLOB protobuf 部分加密 | AES，key 派生 userid |
| 微信 type=49 子消息 | XML 内部分字段 Base64 | 无加密但需解码 |

---

## 10. 跨平台：备份/克隆/同步导致的"db 复本"

### 10.1 同一数据库的多个版本
- **设备 db**：实时（含 wal/journal）。
- **手机 ADB 备份**：可能漏 wal/shm。
- **PC 同步**：多数仅时间点快照。
- **iCloud 备份**：时点快照，**WAL 已 checkpoint** → 可能丢最近写入。
- **微信/QQ PC 端**：独立 db，与手机 db 不同步骤但可交叉。

### 10.2 取证策略
- **三方对比**：手机 db、PC 端 db、云备份 db 互补。
- **多时间点快照**：iCloud/iTunes 多次备份累加可恢复"曾被删除"的记录。
- **wal 单独保留**：哪怕主库 vacuum 过，wal 中仍可能有旧页副本。

---

## 11. 题型与解法决策树

```
拿到一个 db 文件
├─ file *.db / xxd | head -c 16
│  ├─ "SQLite format 3" → 普通 SQLite
│  │   ├─ Z* 表前缀 → Core Data
│  │   ├─ 字段 BLOB 高熵 → 字段加密 → 第 9 节
│  │   └─ 删除恢复 → undark / bring2lite
│  ├─ 头 4 字节 "T-DB" → Realm → 找 64 字节 key
│  ├─ 目录有 LOG/MANIFEST/*.ldb → LevelDB → plyvel
│  ├─ 头 16 字节非 SQLite → SQLCipher / WCDB
│  │   ├─ 找 key 来源（shared_prefs/MMKV/Keychain/SO/内存）
│  │   ├─ 试 PRAGMA 组合（v1/v3/v4，大坑：page_size、HMAC、kdf_iter）
│  │   └─ 解密 → sqlcipher_export → 明文 → 后续分析
│  ├─ "data.mdb" + "lock.mdb" → ObjectBox/LMDB
│  └─ "*.cblite2/db.sqlite3" → Couchbase Lite
└─ 题目要"恢复删除"
   ├─ 主库 freelist_count > 0 → undark/bring2lite
   ├─ 有 -wal → walitean
   ├─ 有 -journal → 偏移 0 检查 magic，解析旧页镜像
   └─ 加密库 → 先解密再恢复
```

---

## 12. 命令速查

```bash
# 头部识别
file *.db *.sqlite *.realm
xxd suspect.db | head -2
xxd suspect.realm | head -1
ls leveldb_dir/  # 看 LOG / MANIFEST / *.ldb

# SQLite 基本检查
sqlite3 db.sqlite "PRAGMA integrity_check; PRAGMA freelist_count; PRAGMA page_count; PRAGMA page_size; PRAGMA journal_mode;"
sqlite3 db.sqlite ".tables"
sqlite3 db.sqlite ".schema <tab>"

# 删除恢复
undark -i db.sqlite -d -o recovered.txt
python3 bring2lite.py -i db.sqlite -o /tmp/out --recover-deleted
strings -n 8 db.sqlite-wal | grep -E '<已知关键字>'

# WAL 单独扫
python3 walitean.py db.sqlite-wal > wal.txt

# SQLCipher 解密为明文
sqlcipher cipher.db <<EOF
PRAGMA key = 'pwd';
PRAGMA cipher_compatibility = 4;
ATTACH 'plain.db' AS p KEY '';
SELECT sqlcipher_export('p');
DETACH p;
EOF

# 用 raw 64-byte hex
sqlcipher cipher.db "PRAGMA key=\"x'$(cat key.hex)'\"; PRAGMA cipher_compatibility=4; ATTACH 'plain.db' AS p KEY ''; SELECT sqlcipher_export('p'); DETACH p;"

# 试不同版本（懒办法）
for v in 1 2 3 4; do
  echo "=== v$v ==="
  sqlcipher cipher.db <<EOF
PRAGMA key='$pwd';
PRAGMA cipher_compatibility=$v;
.tables
EOF
done

# Realm
RealmStudio &        # GUI 输入 64-byte key
python -c "import realm;c=realm.RealmConfig('a.realm');r=realm.Realm(c);print(r.schema)"

# LevelDB
python -c "import plyvel;d=plyvel.DB('./db',create_if_missing=False);[print(k[:80],v[:80]) for k,v in d]"

# LMDB / ObjectBox raw
python -c "import lmdb;e=lmdb.open('./d',readonly=True,lock=False,subdir=True);t=e.begin();[print(k[:80],v[:80]) for k,v in t.cursor()]"

# 字段密文识别
sqlite3 db "SELECT length(data),hex(substr(data,1,32)) FROM messages LIMIT 5;"   # 看是否 16 倍数 + 高熵

# frida hook key
frida -U -f com.target.app -l hook_sqlcipher_key.js --no-pause
```

---

## 13. 常见坑

1. **WAL/-shm 丢失**：复制库永远三件套（主 + wal + shm），否则最近写入丢失。
2. **VACUUM 已执行**：删除恢复几乎不可能；先看 `freelist_count`、`page_count` × `page_size` 与文件大小是否匹配。
3. **secure_delete=ON**：iOS 系统库（sms.db、CallHistory）默认开 → 删除真实抹除。
4. **SQLCipher 版本混用**：v3 和 v4 PRAGMA 不兼容，别"拿 v4 默认参数解 v3 的 db"。
5. **WCDB 的 page_size=4096**：很多模板用 SQLCipher v3 默认 1024 → 解失败。
6. **加密 SQLite 的 wal 是密文**：单独处理 wal 必须经 SQLCipher，**不能直接 strings**。
7. **raw 64-byte key 不能跨库通用**：因 salt 在头 16 字节，每库独立。
8. **Core Data BLOB**：以为是普通字段，实际是 NSKeyedArchiver bplist 套娃，要二次反序列化。
9. **Realm 加密 key 必须 64 byte**：很多人只给 32 byte（AES）→ HMAC 校验失败。
10. **LevelDB 看似单 ldb 但写在 .log**：最近写未 flush，要先合并再读。
11. **IndexedDB 的 value 是 V8 序列化**：不是 JSON，不要 `json.loads`。
12. **删除恢复假阳性**：undark 会把碎片当行 → 必须按 schema 校验列数和类型；用 bring2lite + schema 严格匹配减少误报。
13. **大表的 freelist 占比小**：deleted 行的复活率 = `freelist + freeblocks` / `total cells`，常仅 0.1%–10%；客观告知不要承诺"全部恢复"。
14. **VACUUM 不等于 secure_delete**：vacuum 只压缩，不一定清零；vacuum 后旧页内容已不可寻址但磁盘上仍可能有（取决于 fs/SSD trim）。
15. **"明文"和"已解密"的区别**：sqlcipher_export 之后才是真正的标准 sqlite，能用所有标准工具；只 PRAGMA key 不导出，外部工具仍打不开。
16. **PRAGMA key 失败的判定**：执行 `.tables` 报 `file is not a database` 即 key 或参数错；不要被无报错的 `PRAGMA key` 行迷惑。
17. **iOS sms.db 时间纳秒 vs 秒**：删除恢复脚本默认按秒，对纳秒库会全部时间错乱。
18. **PC 微信/QQ 内存提 key**：进程关掉 + 内存被覆盖 → 拿不到；关电源前优先 dump。

---

## 14. 比赛常见题与解法

| 题型 | 解法骨架 |
| --- | --- |
| 给 sqlite，问"删了什么消息" | undark/bring2lite + 比对当前主库；时间从 wal/free page 中提取 |
| 给加密 db，问内容 | 识别 SQLCipher/WCDB → 找 key（按第 4.6 节优先级）→ 解 → 跑后续 |
| 给 Realm，问对象 | Realm Studio 输 64 字节 key 或越狱 dump key |
| 给 IndexedDB/LevelDB | plyvel 列 KV → V8 反序列化 → JSON 还原 |
| 给字段密文 | frida hook 或硬逆 SO；已知明文配对推 key |
| "微信删除消息恢复" | 解 EnMicroMsg → 明文落库 → undark → 时间过滤 |
| "WAL 中的最新一条消息" | walitean 扫 wal frame → 按 schema 解 → 时间排序取末尾 |
| "知道密码的 SQLCipher" | PRAGMA key + cipher_compatibility 试 1/3/4 → sqlcipher_export 落明文 |
| "不知道密码但 4 位数字" | 自写 PBKDF2 爆破第一页头 |
| "已 VACUUM" | 主库恢复无望 → 看是否有旧备份/旧 wal/旧 journal/iTunes 备份多版本 |
| "iOS sms.db 删除恢复" | 主库默认 secure_delete，几乎无戏 → 看附件目录 + iCloud 信息 + 早期 iTunes 备份 |

---

## 15. 交叉链接
- `log_and_data_parsing.md`：通用日志/数据解析（含 MMKV/Protobuf/SharedPrefs）
- `wechat_deep_dive.md`：微信 SQLCipher 完整方法
- `popular_apps_forensics.md`：抖音/QQ/支付宝 字段加密细节
- `apk_crypto_analysis.md`：APK 内密钥提取与算法逆向
- `ios_app_parsing.md`：iOS App 数据库（Core Data/Realm/SQLCipher）
- `extraction_methods.md`：取证方法对取数据库三件套的影响
- `timestamps_reference.md`：时间戳换算
