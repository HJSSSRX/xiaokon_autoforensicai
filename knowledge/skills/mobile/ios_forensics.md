# iOS 取证专题方法论

> 适用：iOS 设备（iPhone/iPad）取证。题目特征：见到 `Manifest.db`、`Manifest.plist`、`Info.plist`、`Status.plist`、`Keychain-backup.plist`、`*.mddata`/`*.mdinfo`、`HomeDomain`、`AppDomain-*`、`MediaDomain`、`mobilesync`、`Backup` 目录、`*.plist`/`*.bplist`、`SMS.db`、`AddressBook.sqlitedb`、`CallHistory.storedata`、`Photos.sqlite`、`History.db`、`KnowledgeC.db`、`screentime`、`InteractionC.db` 等。

---

## 1. iOS 取证总策略

### 1.1 三种获取方式
| 方式 | 前提 | 能拿到 | 局限 |
| --- | --- | --- | --- |
| **iTunes/Finder 备份**（最常见） | 设备解锁 + 信任电脑 | 大部分用户数据，**需选"加密备份"才有 Keychain/健康/通话历史** | App 沙盒中部分文件不进备份（NSURLIsExcludedFromBackupKey） |
| **AFC + iOS Backup**（取证软件如 iTools/3uTools/UFED） | 同上 | 同上+部分媒体直读 | 仍受备份范围限制 |
| **越狱后逻辑/物理提取**（checkra1n/palera1n/unc0ver） | 越狱成功 | 全文件系统 `/private/var/mobile/`、Keychain、SQLite WAL、删除痕迹 | 仅限可越狱机型/版本 |

### 1.2 BFU vs AFU（关键考点）
- **AFU**（After First Unlock，开机后至少解锁过一次）：Data Protection Class A/B/C 中已解密 keybag，Keychain 大部分 item 可读；**首选状态**。
- **BFU**（Before First Unlock，开机后从未解锁）：仅 Class D（NSFileProtectionNone）可读；联系人/短信/照片大多读不出来。
- **现场处置**：拿到设备后**保持开机、保持解锁状态、立刻屏蔽信号（法拉第袋）、连充电宝**。

---

## 2. iOS 备份目录结构

### 2.1 备份位置（PC 端）
| 系统 | 路径 |
| --- | --- |
| Windows | `%APPDATA%\Apple Computer\MobileSync\Backup\<UDID>\` |
| macOS | `~/Library/Application Support/MobileSync/Backup/<UDID>/` |
| iTunes Win Store | `%USERPROFILE%\Apple\MobileSync\Backup\<UDID>\` |

### 2.2 关键索引文件
| 文件 | 内容 | 备注 |
| --- | --- | --- |
| `Manifest.db` | SQLite，记录 fileID ↔ domain/relativePath/flags | **必查**，文件名映射核心 |
| `Manifest.plist` | bplist，备份元信息（IsEncrypted、Lockdown、Apps 列表） | 判断是否加密 |
| `Info.plist` | bplist，设备信息（IMEI、Serial、ICCID、设备名、iOS 版本、电话号码、Last Backup Date） | **设备身份取证主源** |
| `Status.plist` | bplist，备份状态（Date、IsFullBackup、SnapshotState） | |

### 2.3 文件名规则
- 备份后所有文件名变为 `SHA1(domain-relativePath)`，前两位作为子目录。
- 例：`HomeDomain-Library/SMS/sms.db` → SHA1 `3d0d7e5fb2ce288813306e4d4636395e047a3d28` → 存于 `3d/3d0d7e5fb2ce288813306e4d4636395e047a3d28`。

```sql
-- Manifest.db 查文件
SELECT fileID, domain, relativePath FROM Files WHERE relativePath LIKE '%sms.db%';
SELECT fileID, domain, relativePath FROM Files WHERE domain LIKE 'AppDomain-com.tencent.xin%';
```

---

## 3. 加密备份破解

### 3.1 判断是否加密
- `Manifest.plist` 中 `IsEncrypted=true`。
- 加密备份下 `Manifest.db` 本身也是加密的，需密码先解。

### 3.2 主流工具
| 工具 | 用途 | 命令/说明 |
| --- | --- | --- |
| **iOSbackup** (Python) | 解密 + 文件提取 | `pip install iOSbackup` |
| **ios_bfu_triage / iLEAPP** | 解析（解密后） | 见下 |
| **Elcomsoft Phone Breaker (EPB)** | 暴力破解备份密码（GPU 加速） | 商业 |
| **hashcat -m 14700/14800** | 离线爆破 iTunes 备份口令 | iTunes Backup ≤ iOS 10.1 用 14700，≥ 10.2 用 14800 |
| **iphone-backup-decrypt** (GitHub) | Python 解密 iOS 9+ 备份 | |

```bash
# hashcat 爆破示例
python /opt/itunes_backup2hashcat.py /path/to/Backup/<UDID> > hash.txt
hashcat -m 14800 hash.txt wordlist.txt -O
# iOSbackup 解密
python -c "from iOSbackup import iOSbackup; b=iOSbackup(udid='<UDID>',cleartextpassword='1234',backuproot='/path'); b.getFolderDecryptedCopy('HomeDomain','/tmp/out')"
```

### 3.3 备份密码丢失的备选
- 设备本身可访问 → **重置备份密码**：`设置 → 通用 → 传输或还原 iPhone → 还原 → 重置所有设置`（iOS 11+，需要锁屏密码，**不会清数据但会重置 Wi-Fi/键盘字典等**，重置后新备份无密码）。
- 或越狱直接绕过备份层取数据。

---

## 4. iOS Domain 速查（Manifest.db 里的 domain 字段）

| Domain | 关键路径 | 内容 |
| --- | --- | --- |
| `HomeDomain` | `Library/SMS/sms.db` | iMessage/SMS（含附件指针） |
| `HomeDomain` | `Library/CallHistoryDB/CallHistory.storedata` | 通话记录（Core Data SQLite） |
| `HomeDomain` | `Library/AddressBook/AddressBook.sqlitedb` | 通讯录 |
| `HomeDomain` | `Library/Calendar/Calendar.sqlitedb` | 日历 |
| `HomeDomain` | `Library/Notes/notes.sqlite` / `NoteStore.sqlite`（GroupContainer） | 备忘录（新版加密 BLOB，需 NoteStore.sqlite + ZICCLOUDSYNCINGOBJECT） |
| `HomeDomain` | `Library/Safari/History.db` `Bookmarks.db` | Safari |
| `HomeDomain` | `Library/CoreDuet/Knowledge/knowledgeC.db` | **应用使用、屏幕亮灭、电池、位置**（行为大全） |
| `HomeDomain` | `Library/CoreDuet/People/interactionC.db` | 联系人交互频次 |
| `HomeDomain` | `Library/Caches/locationd/cache_encryptedB.db` | 位置缓存（加密，越狱可解） |
| `MediaDomain` | `Media/DCIM/` | 相册原图 |
| `MediaDomain` | `Media/PhotoData/Photos.sqlite` | 照片元数据（GPS、人脸、时间线） |
| `CameraRollDomain` | 旧版相册 | |
| `WirelessDomain` | `Library/Databases/CellularUsage.db` `DataUsage.sqlite` | SIM/流量 |
| `KeychainDomain` | `keychain-backup.plist` | Keychain（加密备份才有） |
| `RootDomain` | `Library/Lockdown/data_ark.plist` | 设备激活信息 |
| `SystemPreferencesDomain` | `SystemConfiguration/com.apple.wifi.plist` | Wi-Fi 历史 SSID/BSSID（iOS 14+ 改 known_networks.plist） |
| `HealthDomain` | `Health/healthdb_secure.sqlite` | 健康数据（步数、心率、位置） |
| `AppDomain-<bundleid>` | `Documents/` `Library/` | 第三方 App 沙盒 |
| `AppDomainGroup-group.<id>` | 共享容器 | 微信/QQ 等部分数据 |
| `AppDomainPlugin-<id>` | 插件/Widget | |

### 常考 App bundle id
| App | bundle id |
| --- | --- |
| 微信 | `com.tencent.xin` |
| QQ | `com.tencent.mqq` / `com.tencent.qq` |
| WhatsApp | `net.whatsapp.WhatsApp` |
| Telegram | `ph.telegra.Telegraph` |
| 抖音（国内） | `com.ss.iphone.ugc.Aweme` |
| TikTok | `com.zhiliaoapp.musically` |
| Signal | `org.whispersystems.signal` |
| Line | `jp.naver.line` |

---

## 5. iOS 设备基本信息提取

### 5.1 Info.plist（备份根目录）
关键字段：
- `Device Name`、`Display Name`、`Product Type`（如 iPhone14,2）、`Product Version`、`Build Version`
- `Serial Number`、`IMEI`、`IMEI 2`（双卡）、`MEID`、`ICCID`、`ICCID 2`
- `Phone Number`、`Last Backup Date`、`GUID`、`Target Identifier`（UDID）
- `Installed Applications`（所有装过的 App 包名列表）

```bash
plutil -p Info.plist | grep -Ei "IMEI|ICCID|Serial|Product|Phone|Date"
```

### 5.2 设备型号速查（Product Type → 型号）
- `iPhone14,2` = iPhone 13 Pro
- `iPhone14,3` = iPhone 13 Pro Max
- `iPhone14,4` = iPhone 13 mini
- `iPhone14,5` = iPhone 13
- `iPhone15,2` = iPhone 14 Pro
- `iPhone15,3` = iPhone 14 Pro Max
- 完整对照查 [theiphonewiki.com](https://www.theiphonewiki.com/wiki/Models)。

### 5.3 越狱后获取
```bash
# 文件系统提取
ssh root@iphone "tar -czf - /private/var/mobile/Library /private/var/mobile/Containers" > dump.tgz
# 设备信息
gssc / lockdownd -h / ideviceinfo
ideviceinfo -k SerialNumber
ideviceinfo -k InternationalMobileEquipmentIdentity
ideviceinfo -k IntegratedCircuitCardIdentity
```

---

## 6. iLEAPP 深度使用

[iLEAPP](https://github.com/abrignoni/iLEAPP) 是 iOS 取证开源解析框架，覆盖 200+ artifact。

```bash
pip install ileapp
ileapp -t fs -i /path/to/extracted_fs -o /tmp/out         # 文件系统目录
ileapp -t itunes -i /path/to/Backup/<UDID> -o /tmp/out    # 未加密 iTunes 备份
ileapp -t gray -i /path/to/GrayKey_zip -o /tmp/out        # GrayKey 输出
# 仅跑某些模块：-p "Calls,Health,KnowledgeC"
ileapp -p ?            # 列出所有模块
```

输出 HTML 报告 + tsv/timeline，重点关注：
- `KnowledgeC` 屏幕使用/App 使用/位置/电池
- `InteractionC` 联系人交互频度
- `Cellular` 通话/数据
- `Health Workouts/Locations`
- `Wifi Networks`
- `Powerlog` 电量曲线（可推断在何处过夜）

---

## 7. Keychain 提取与解析

### 7.1 来源
- **加密备份**：`KeychainDomain/keychain-backup.plist`（bplist，内含 4 类 item：genp/inet/cert/keys，分别为通用密码/网络密码/证书/密钥）。
- **越狱设备**：`/private/var/Keychains/keychain-2.db` + Keybag（`/private/var/keybags/systembag.kb`）。

### 7.2 解析工具
| 工具 | 说明 |
| --- | --- |
| `iOSKeychain-decryptor` | Python 解密备份 keychain |
| `keychain_dumper` | 越狱设备直接 dump |
| `iOSbackup.py` 自带 | 备份解密后可读取 |
| `iLEAPP` Keychain 模块 | 自动提取 + 分类报告 |

### 7.3 实战注意
- Keychain item 有 `accessible` 属性（kSecAttrAccessible*），`AlwaysThisDeviceOnly` 不会进备份。
- Wi-Fi 密码、邮件密码、第三方 App 登录 token、Apple ID token 都在 Keychain。

---

## 8. 关键 SQLite 表（必背）

### 8.1 SMS / iMessage（`sms.db`）
```sql
SELECT m.ROWID, datetime(m.date/1000000000+978307200,'unixepoch','localtime') AS time,
       h.id AS contact, m.is_from_me, m.text, m.service, c.chat_identifier
FROM message m
LEFT JOIN handle h ON m.handle_id=h.ROWID
LEFT JOIN chat_message_join cmj ON m.ROWID=cmj.message_id
LEFT JOIN chat c ON cmj.chat_id=c.ROWID
ORDER BY m.date;
```
- **时间戳**：iOS 11+ 是 **Mac Absolute Time × 1e9**（纳秒）；早期是秒。需 `+978307200`（2001-01-01）。
- 附件：`message_attachment_join` ↔ `attachment.filename`（`~/Library/SMS/Attachments/`）。

### 8.2 通话历史（`CallHistory.storedata`，Core Data）
```sql
SELECT ZADDRESS, ZNAME, datetime(ZDATE+978307200,'unixepoch','localtime') AS time,
       ZDURATION, ZANSWERED, ZORIGINATED, ZSERVICE_PROVIDER
FROM ZCALLRECORD ORDER BY ZDATE DESC;
```
- `ZORIGINATED=1` 主叫，`ZANSWERED=1` 接通，`ZSERVICE_PROVIDER` 标识 FaceTime/微信通话/普通通话。

### 8.3 Safari 历史（`History.db`）
```sql
SELECT v.id, datetime(v.visit_time+978307200,'unixepoch','localtime') AS time,
       i.url, i.domain, v.title
FROM history_visits v JOIN history_items i ON v.history_item=i.id
ORDER BY v.visit_time DESC;
```

### 8.4 KnowledgeC（行为黄金表）
```sql
-- App 使用
SELECT ZSTREAMNAME, ZVALUESTRING AS bundle,
       datetime(ZSTARTDATE+978307200,'unixepoch','localtime') AS start,
       datetime(ZENDDATE+978307200,'unixepoch','localtime') AS end
FROM ZOBJECT WHERE ZSTREAMNAME='/app/usage' ORDER BY ZSTARTDATE DESC;
-- 屏幕亮灭
SELECT * FROM ZOBJECT WHERE ZSTREAMNAME='/display/isBacklit';
-- 设备充电
SELECT * FROM ZOBJECT WHERE ZSTREAMNAME='/device/isPluggedIn';
```

### 8.5 Photos.sqlite
- `ZGENERICASSET` / `ZASSET`（iOS 13+ 表名变化）：拍摄时间、GPS（`ZLATITUDE`/`ZLONGITUDE`）、设备型号、原文件名（`ZORIGINALFILENAME`）。
- `ZASSETDESCRIPTION`、`ZMOMENT`、`ZPERSON`（人脸库）。
- 删除照片：`ZTRASHEDSTATE=1`，30 天保留期。

### 8.6 Wi-Fi 历史
- iOS 13 及以前：`SystemPreferencesDomain` → `com.apple.wifi.plist`（bplist，含 SSID/BSSID/最后连接时间）。
- iOS 14+：`com.apple.wifi.known-networks.plist`（结构改变，按 SSID 分组）。

---

## 9. plist / bplist 解析

### 9.1 判断格式
- 文本 plist：`<?xml version="1.0"`
- 二进制 plist：开头 `bplist00`

### 9.2 工具
```bash
plutil -p file.plist                 # macOS 自带
plutil -convert xml1 in.plist -o out.xml
# Windows / Linux
python -c "import plistlib;import sys,pprint;pprint.pp(plistlib.load(open(sys.argv[1],'rb')))" file.plist
# 含 NSKeyedArchiver 的 plist（嵌套 $class/$objects）：
pip install ccl-bplist
python -c "import ccl_bplist as p,sys;f=open(sys.argv[1],'rb');d=p.load(f);t=p.deserialise_NsKeyedArchiver(d);import pprint;pprint.pp(t)" file.plist
```

### 9.3 NSKeyedArchiver 套娃
- 见到 `$archiver=NSKeyedArchiver`、`$objects=[..]`、`$top=...` 必须用 `ccl-bplist` 反序列化，否则全是 UID 引用。
- 微信 `MMSetting.archive`、抖音部分 plist 都是这种格式。

---

## 10. 越狱与文件系统提取

### 10.1 主流越狱
| 工具 | 支持版本 | 类型 |
| --- | --- | --- |
| **checkra1n** | iOS 12.0–14.8.1（A7–A11，**硬件漏洞 checkm8**） | 半束缚（重启需重越） |
| **palera1n** | iOS 15–16.x（A8–A11） | 同上，基于 checkm8 |
| **unc0ver** | iOS 11–14.3 | 软越（应用安装） |
| **Taurine** | iOS 14.0–14.3 | 软越 |
| **Dopamine** | iOS 15–16（A12+） | 半软越 |

### 10.2 提取流程
```bash
# 越狱后通过 SSH (默认 root/alpine 或自设)
ssh -p 22 root@<iphone_ip>
# 整盘 tar
tar --exclude=/proc --exclude=/sys -czf /var/mobile/Media/dump.tgz /private/var/mobile /private/var/keybags
# pull 出来
scp root@<iphone_ip>:/var/mobile/Media/dump.tgz .
```
- iOS 拉文件优先用 USB → `iproxy 2222 22` 转发，避免无线断流。

### 10.3 文件系统树（关键路径）
- `/private/var/mobile/Media/DCIM/` 相册
- `/private/var/mobile/Library/SMS/` 短信
- `/private/var/mobile/Library/AddressBook/` 通讯录
- `/private/var/mobile/Containers/Data/Application/<UUID>/Documents` App 沙盒（UUID 与 bundle id 通过 `installd`/`MobileInstallation.plist` 关联）
- `/private/var/mobile/Containers/Shared/AppGroup/<UUID>/` App Group 共享容器
- `/private/var/keybags/` Data Protection keybag
- `/private/var/wireless/Library/CallHistoryDB/` 通话

### 10.4 Bundle ID ↔ UUID 映射
```
/private/var/mobile/Library/MobileInstallation/LastBuildInfo.plist
/private/var/mobile/Library/FrontBoard/applicationState.db   # SQLite
/private/var/installd/Library/MobileInstallation/MobileInstallation.plist
```
SQL：
```sql
SELECT application_identifier, key_value FROM kvs k
JOIN application_identifier_tab a ON k.application_identifier=a.id
WHERE key='compatibilityInfo';
```

---

## 11. 决策树

```
拿到 iPhone 检材
├─ 设备在手且开机解锁（AFU）？
│   ├─ 是 → 立刻法拉第袋 + 充电 → 优先 iTunes 备份（设加密）→ 必要时越狱物理提取
│   └─ 否（BFU/已关机）→ 仅尝试 BFU 提取（GrayKey/checkra1n）；先别开机
├─ 仅有备份目录？
│   ├─ 加密 → 找密码（设备重置/字典/EPB）→ 解密 → iLEAPP
│   └─ 未加密 → 直接 Manifest.db 定位 + iLEAPP
└─ 越狱后镜像 → 全文件系统 → iLEAPP / 手工 SQLite
```

---

## 12. 命令速查

```bash
# Manifest.db 列出某 App 所有文件
sqlite3 Manifest.db "SELECT fileID, relativePath FROM Files WHERE domain='AppDomain-com.tencent.xin' ORDER BY relativePath;"
# 拼接备份内真实文件
fid=3d0d7e5fb2ce288813306e4d4636395e047a3d28
cp /Backup/<UDID>/${fid:0:2}/${fid} /tmp/sms.db
# Mac Absolute Time 换算
python -c "import datetime;print(datetime.datetime(2001,1,1)+datetime.timedelta(seconds=689012345))"
# 解析 bplist
plutil -p file.plist
# 解 NSKeyedArchiver
python -m ccl_bplist file.plist
# ideviceinfo 全量
ideviceinfo
# ifuse 挂载（macOS/Linux，需信任）
ifuse /mnt/iphone --documents com.tencent.xin
```

---

## 13. 常见坑

1. **加密备份中 Manifest.db 也是加密的**：必须先用密码解密，否则看到的是乱码 SQLite。
2. **时间戳混用**：iOS 大多 Mac Absolute Time（2001-01-01 起），但 sms.db 老版是秒、新版是纳秒，看数量级判断。
3. **SQLite WAL 不可丢**：`-wal`、`-shm` 必须随主库一起拉，否则最近的消息可能在 WAL 里没合并。
4. **bplist 套 NSKeyedArchiver 套 bplist**：层层反序列化，别只 `plutil -p` 一层就以为完了。
5. **照片 burst/livephoto/heic** 别漏：burst 同一时间多张共享 `ZBURSTUUID`；livephoto 配套 `.MOV`。
6. **CallHistory 在加密备份才完整**：未加密备份没有，老题常掉坑。
7. **iOS 16+ 改 SwiftUI/CoreData 命名空间**，`ZOBJECT` 表结构略变，别照搬旧 SQL。
8. **删除短信不进 message 表**：但附件 blob 可能仍在 `Attachments/` 目录或 `sms.db-wal`/未 vacuum 的页内（用 `undark`/`sqlparse` 雕复）。
9. **App 沙盒 UUID 每次重装会变**，不能依赖 UUID 关联同一 App 的不同时间快照。
10. **Find My/激活锁**：开了"查找"会触发远程擦除，**取证一定要先飞行模式 + 拔卡 + 法拉第袋**。

---

## 14. 交叉链接
- `device_basic_info.md`：设备基本信息提取通则
- `app_data_analysis.md`：App 行为分析方法论
- `wechat_deep_dive.md`：iOS 微信专题
- `geolocation_forensics.md`：位置取证（含 iOS Photos GPS / KnowledgeC location）
- `timestamps_reference.md`：Mac Absolute Time 换算
- `extraction_methods.md`：取证方法五级对照
