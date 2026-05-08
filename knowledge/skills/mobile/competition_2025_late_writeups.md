# 玫幽倩博客电子取证 writeup 合集（手机/APK 增量）

> 资料来源：[玫幽倩的小博客](https://mei-you-qian.github.io/categories/%E7%94%B5%E5%AD%90%E5%8F%96%E8%AF%81/) 电子取证分类（2025-11 至 2026-05 共 16 篇）。
>
> 本文只挑**之前 KB 没写过**的手机/APK 新点；已重复的（如 EnMicroMsg.db / VeraCrypt 套娃 / Hybrid WebView）直接略过。
>
> 另一站 DFIRDD.com 当前 DNS 解析不通；DFIR蘇小沐主要内容在 [博客园 cnblogs.com/dfir](https://www.cnblogs.com/dfir) 与 CSDN，已暂略（用户指示）。

---

## 1. 真题来源 & 已学/未学一览

| 时间 | 赛事 | 已学 | 命中度 |
| --- | --- | --- | --- |
| 2026-05-07 | **2026 FIC 初赛**（手机/APK 全流程） | ✅ `fic2026_writeup.md` | 高 |
| 2026-01-22 | 2024 FIC 决赛 | ⚠️ 后续学 | 中 |
| 2025-12-22 | **2025 SPC 决赛**（服务器+计算机+EXE） | ✅ 本文 §6 | 中（手机弱） |
| 2025-12-17 | 文件结构和数据分析专项 | ⚠️ | 中 |
| 2025-12-16 | 2025 运维初赛 | ⚠️ | 低（多服务器） |
| 2025-12-01 | **2025 数证杯决赛-团体赛（手机部分）** | ✅ 本文 §2 | **高** |
| 2025-11-30 | 2025 SPC 初赛 | ⚠️ | 中 |
| 2025-11-25 | 2024 数证杯初赛 | ⚠️ | 中 |
| 2025-11-25 | **2025 第六届警铮杯**（手机题） | ✅ 本文 §4 | 中 |
| 2025-11-21 | **2025 美亚杯-资格赛**（iOS 多手机） | ✅ 本文 §3 | **高** |

---

## 2. 2025 数证杯决赛手机题（**新点最多**）

### 2.1 iOS 序列号 = `Adlockdown.json` 内 `MtpNo`（新路径）
> 2025 数证杯 Q21：火眼 / 取证大师外的备用方法。

- 路径：iOS 备份/检材根目录附近的 `Adlockdown.json`（**Apple Lockdown 文件，由 Apple Configurator 写入**），含设备序列号 / UDID / 配对状态。
- 关键字段：
  ```json
  { "MtpNo": "HT7BG1A05334", ... }   // ← 序列号
  ```
- 取证：直接 `grep -E '"MtpNo"|"UDID"|"DeviceClass"' Adlockdown.json`。
- 与 `~/Library/Lockdown/pair_records/<UDID>.plist` 配合可还原"哪台 PC 信任过本机"。

> **回插到** `ios_fundamentals.md`（如已建）/ `quick_reference.md`：iOS 设备 SN 多重来源对照。

### 2.2 用照片 EXIF "Camera Model" 反推手机型号（**新套路**）
> 数证杯 Q22：题目给的是 23 年的旧时间，机主当时手机不是现在这台。

**步骤**：
1. 火眼/取证大师"索引搜索"按时间范围 `2023-04-15`；
2. 看当天的照片 → **属性→照相机型号**（`exiftool` 的 `Model` 字段）；
3. 答案直接是该照片记录的 `Make/Model`（如 `vivo X Fold3 Pro`）。

```bash
exiftool -Make -Model -DateTimeOriginal photo.jpg
# 或全量
exiftool -r -if '$DateTimeOriginal =~ /2023:04:15/' -Make -Model dir/
```

**意义**：嫌疑人换过手机时，"嫌疑人当时用什么手机"答案常埋在该期间拍的照片 EXIF 里。

### 2.3 通话频次 SQL 模板（直接背）
```sql
-- 通话记录中拨打号码频次最多
SELECT number, COUNT(1) AS cnt
FROM calls
WHERE type = 2          -- 1=未接 / 2=拨出 / 3=接听 / 4=拒接（厂商各异）
  AND deleted = 0
  AND number > ''
GROUP BY number
ORDER BY cnt DESC;
```
> **`type` 含义不同 ROM 不一样**，做题前 `SELECT DISTINCT type FROM calls;` 印证。

### 2.4 火狐浏览器搜索结果缩略图（**新缓存路径**）
> 数证杯 Q24：浏览器历史 db 不存搜索结果页，但**缩略图缓存**保留搜索结果首屏。

- 路径：`/data/data/org.mozilla.firefox/cache/mozac_browser_thumbnails/thumbnails/`
- 文件名：URL 的 hash；
- 内容：搜索结果首屏 PNG/WebP；
- 题答：直接看图（应用版本号显示在第一条搜索结果里）。

**类似缩略图缓存全景**（**回插到 `popular_apps_forensics.md` 缓存清单**）：
| 浏览器 | 缩略图缓存 |
| --- | --- |
| Firefox Android | `org.mozilla.firefox/cache/mozac_browser_thumbnails/thumbnails/` |
| Chrome Android | `com.android.chrome/app_chrome/Default/Thumbnails` |
| Edge Android | `com.microsoft.emmx/app_chrome/Default/Thumbnails` |
| Samsung Internet | `com.sec.android.app.sbrowser/cache/Cache_Data/` |
| 夸克浏览器 | `com.quark.browser/cache/com.uc.browser.cache/snapshots/` |
| UC 浏览器 | `com.UCMobile/cache/com.uc.browser.cache/` |

### 2.5 Telegram 用户保存文件夹（直接读）
> 数证杯 Q25：所谓"telegram 应用历史保存文件记录"。

- 路径：`/data/media/0/Telegram/`（Android 公开存储）
- 子目录：`Telegram Documents/`、`Telegram Images/`、`Telegram Video/`、`Telegram Audio/`
- 嫌疑人保存的 txt / 凭证 / 日记常埋这里；**Telegram 卸载后该文件夹仍在**。

### 2.6 AI 生成图来源识别（豆包 / 即梦 / 文心一格 / 通义万相）
> 数证杯 Q28：相册中有多少张来自豆包应用？

| AI App | 包名 | 生成图特征 |
| --- | --- | --- |
| **豆包** | `com.larus.nova` | 图片右下角带"豆包 AI"水印 + EXIF Comment 含 `doubao` |
| **即梦 AI**（字节） | `com.luna.ailab` | 水印 + EXIF |
| **通义万相**（阿里） | `com.aliyun.tongyi` | EXIF Software 字段含 `tongyi` |
| **文心一格** | `com.baidu.aigarden` / `com.baidu.newapp` | 水印 + 元数据 |
| **可灵 AI**（快手） | `com.kuaishou.kling` | 水印 |
| **MidJourney**（Discord 内） | — | 文件名 `xxx_<uuid>.png` 多导出 |
| **Stable Diffusion WebUI** | PC 端 | PNG-tEXt `parameters` 字段 |

**取证查图来源**：
```bash
# 批量看 Comment / Software / UserComment
exiftool -ext jpg -ext png -r -Comment -Software -UserComment -ImageDescription -CreateDate dir/
# 找 "doubao" 来源
exiftool -ext jpg -r -if '$Comment =~ /doubao/i or $Software =~ /doubao/i' -filename dir/
```
若没有元数据，靠**水印 OCR**（PaddleOCR / Tesseract 中文）批量识别。

> **回插到** `popular_apps_forensics.md` §10.5 移动 LLM 取证（生成图侧补充一节）。

### 2.7 应用与文件隐藏器（Amarok / 隐藏大师 / 文件保险箱）
> 数证杯 Q29–Q31：嫌疑人用 Amarok 应用锁 + 文件隐藏 App。

**主流应用隐藏 App 速查**：
| App | 包名 | 隐藏方式 | 解锁套路 |
| --- | --- | --- | --- |
| **Amarok** | `com.amarok.security`（赛中实例） | 文件头改 + 应用锁 | xml 内 password 是 MD5；hashcat -m 0 爆破 |
| 文件保险箱 | `com.fileexplore.vault` | 文件移到沙盒 + 加密 | 解密同上 |
| Vault-Hide | `com.netqin.ps` | AES 加密 + 隐藏图库 | key 在 SP |
| Calculator Vault | `com.calculatorvault.gallerylocker` | 伪装计算器 | sp 内 PIN |
| Keepsafe | `com.kii.safe` | 服务端 + 本地双备份 | 云端取证 |
| App Hider | `com.hidepictures.photovault.lockgallery` | 复制 + 隐藏 | sp 内 |
| 应用分身（厂商自带） | `com.miui.securitycenter` 等 | 系统级用户 10/11 | 已在 `emulator_clone_forensics.md` |

**Amarok 解题流程（数证杯 Q30 实例）**：
```
1. 找出包名 + 安装包；
2. 雷电模拟器 + 把检材沙盒（/data/data/<pkg>）拷贝进去 → 进入嫌疑人原状态；
3. 应用打开见应用锁 → /data/data/<pkg>/shared_prefs/*.xml 内 password 字段
4. password 多为 MD5 → hashcat -m 0 dict.txt 或 cmd5 在线
5. 解锁后看隐藏方式（文件头改 / 路径转移 / 真加密）
6. 真加密：跟 jadx 反编看 Cipher 方法
   文件头改：直接抄文件回 /storage/emulated/0/Private/ 触发"解隐藏"
   路径转移：直接在沙盒里找到原文件
```

> **回插到** `lock_password_forensics.md` 应用锁章节 + `popular_apps_forensics.md` 隐藏 App 章节。

### 2.8 PNG 文件头/高度损坏 + 修复（数证杯 Q32）
**速查**：
```python
# 修 PNG 头
data = open('bad.png','rb').read()
fixed = b'\x89PNG\r\n\x1a\n' + data[8:]   # 强制头

# 改宽高（CRC 不算了，多数取证工具能容错）
import struct
ihdr_off = 16  # PNG IHDR 数据起点
# 宽 4B + 高 4B
new = bytearray(fixed)
new[ihdr_off+4:ihdr_off+8] = struct.pack('>I', 1080)  # 高度
open('out.png','wb').write(bytes(new))
```
工具：**随波逐流（pcat-aaaa）**、**aperisolve**、**Stegsolve**、**TweakPNG**、**pngcheck**。

### 2.9 视频损坏修复 + SHA1（**新工具**）
> 数证杯 Q33：嫌疑人收到视频 → 损坏 → 修复后再发。

- 嫌疑人手机里**自己已有修复后的版本**（在下载文件夹/微信缓存），直接 `certutil -hashfile xxx.mp4 SHA1`。
- 若需自己修：
  - **视频修复工具**：Stellar Repair / Video Repair Tool（grau gmbh）/ Untrunc / DivFix++ / FFmpeg `-c copy -err_detect ignore_err`
  - 多数题给"参考样本"，用 untrunc-anthwlock 可参考样本结构修。

### 2.10 银行卡 BIN 反查
> 数证杯 Q32：转账给好友的卡号识别。

- BIN 表（前 6 位）→ 银行 + 卡类型；
- **离线工具**：
  - 项目 [`zxsq-anti-cracking/binlist`](https://github.com/...)（IIN/BIN 数据库）
  - bankbin.com / openiin.com 在线
  - 国内卡 6-8 位定位力更强
- **Python**：
  ```python
  import csv
  bin_db = {}
  for r in csv.DictReader(open('binlist-cn.csv', encoding='utf-8')):
      bin_db[r['bin']] = (r['bank'], r['card_type'])
  print(bin_db.get('623110'))  # 苏州农商银行 / 借记卡
  ```

### 2.11 自创编码（视频内容当摩斯）
> 数证杯 Q34 设计：视频里"大老虎=1，小老虎=0，切换=空格" → 摩斯码 → 解出压缩包密码。

**通用做法**：题目"修视频"暗示视频内容编码 → 看视频帧出现的对比规律（颜色/大小/方向/模式）→ 套摩斯/二进制/Base 编码 → 解出。

> **新增到 `quick_reference.md`**：题目要求修视频/图片时，**修出来的内容大概率不是直接答案，而是另一道题的密钥**。

---

## 3. 2025 美亚杯 iOS 取证（**新点最多**，与国内题风格不同）

### 3.1 Manifest.plist 备份密码爆破
> 美亚杯起手就是 iOS 加密备份。

- 路径：iOS 备份目录根 / `Manifest.plist`（明文 plist）+ `Manifest.db`（加密 sqlite）
- 加密备份 → `Manifest.plist` 含 `IsEncrypted=true` + `BackupKeyBag` 二进制
- 提取 hash：`itunes_backup2hashcat.pl Manifest.plist > hash.txt`
- 爆破：
  - **passwarekit forensic**（GUI，比赛常用）
  - `hashcat -m 14700` (iOS ≤ 10.1) / `hashcat -m 14800` (iOS ≥ 10.2)
  - 字典 + mask + GPU
- 解密备份：`iphone-dataprotection` / `iLEAPP` 自动 / `Cellebrite/Magnet AXIOM`

### 3.2 AirDrop 收发记录取证
> 美亚杯 Q12–Q19 多题。

**iOS AirDrop 痕迹来源**：
| 来源 | 路径/方式 |
| --- | --- |
| **`com.apple.sharingd` 日志** | unified log: `log show --predicate 'subsystem=="com.apple.sharing"'` |
| **`Library/Sharing/Discoverable.plist`** | 当前/最近可见设备名 |
| **`Library/Preferences/com.apple.Sharingd.plist`** | 隔空投送配置 + 可见性 |
| **`Library/Preferences/com.apple.AirDrop.plist`** | 偏好 |
| **`/private/var/mobile/Library/IDS/`** | iMessage/AirDrop 共用身份 |
| **CoreDuet 行为日志** | `_CD_DataAccessAudit.db` / `interactionC.db` |
| **照片元数据 + Handoff** | 照片 EXIF + 共享相册 db |

**Android 端（com.apple.Sharing 不存在）**：
- 三星 Quick Share / 鸿蒙 NearLink；
- **Lenovo Anyshare**（包名 `com.lenovo.anyshare`）：`/data/com.lenovo.anyshare/databases/history.db`
- **Send Anywhere**（`com.estmob.paprika`）：sqlite + push token

### 3.3 iOS Photos.sqlite 与"图片来源识别"
**iOS 图片库主库**：
- `Photos.sqlite`（Core Data）路径 `/private/var/mobile/Media/PhotoData/Photos.sqlite`
- 表：`ZASSET`（条目）、`ZADDITIONALASSETATTRIBUTES`、`ZGENERICALBUM`、`ZSCENECLASSIFICATION` 等
- 关键字段：
  - `ZASSET.ZSAVEDASSETTYPE`（0=相机/截屏 1=保存自他处 2=隔空投送 3=iCloud 共享 4=同步 等）
  - `ZASSET.ZIMPORTSOURCE`（导入来源）
  - `ZADDITIONALASSETATTRIBUTES.ZORIGINALFILENAME`（原文件名 → 美亚杯 Q36）
  - `ZADDITIONALASSETATTRIBUTES.ZCREATORBUNDLEID`（**创建 App 的 Bundle ID** → "由哪个 App 拍摄"）
  - `ZASSET.ZADDITIONALATTRIBUTES.ZIMPORTEDBY` / `ZIMPORTEDBYBUNDLEIDENTIFIER`（导入 App）
  - `ZSCENE.ZACQUISITIONSESSION`（拍摄会话）

**SQL 模板（"由哪个 App 拍摄/保存"）**：
```sql
SELECT a.ZFILENAME, b.ZORIGINALFILENAME, b.ZCREATORBUNDLEID, b.ZIMPORTEDBYBUNDLEIDENTIFIER,
       datetime(a.ZDATECREATED + 978307200, 'unixepoch', '+8 hours') AS created
FROM ZASSET a LEFT JOIN ZADDITIONALASSETATTRIBUTES b ON b.ZASSET = a.Z_PK
WHERE a.ZFILENAME = 'IMG_0079.JPG';
```

### 3.4 iCloud / iCloud Drive 取证
- 多媒体 iCloud 上传：`ZASSET.ZCLOUDLOCALSTATE`（1 = 已上传 iCloud）
- iCloud Drive 文件：`/private/var/mobile/Library/Mobile Documents/`
- iCloud 账户：`Library/Preferences/com.apple.MobileMeAccounts.plist`

### 3.5 iOS Safari 历史 / 书签 / 下载
| 文件 | 内容 |
| --- | --- |
| `Library/Safari/History.db` | 历史 + 搜索（**WebKit 时间戳**：`+ 978307200 + visit_time`） |
| `Library/Safari/Bookmarks.db` | 书签 |
| `Library/Safari/Downloads.plist` | 下载文件元数据 |
| `Library/Safari/RecentlyClosedTabs.plist` | 最近关闭 |
| `Library/Safari/SearchDescriptions.plist` | 搜索引擎 |

### 3.6 iOS POE / iOS AI Chat 取证
> 美亚杯 Q43–Q46 一连串"POE 提问内容/时间/机器人"。

**POE iOS 路径**：
- Bundle: `com.quora.poe`
- 数据：`Documents/poe.sqlite` 或 Realm `default.realm`
- 表/对象：`Conversations`、`Messages`、`Bots`
- 关键字段：`bot_handle`（机器人名）、`user_id`、`text`、`creation_time`

**iOS 端 ChatGPT / Claude / 通义 / 文心**：
| App | Bundle | 对话存储 |
| --- | --- | --- |
| ChatGPT | `com.openai.chat` | `Documents/chats.db` 或 sqlite |
| Claude | `com.anthropic.claude` | sqlite |
| 通义 | `com.alibaba.tongyi.aliyun` | sqlite |
| Kimi | `com.moonshot.kimichat` | sqlite + LevelDB |
| DeepSeek | `com.deepseek.chat` | sqlite |
| 豆包 | `com.larus.nova` | sqlite |
| Poe | `com.quora.poe` | sqlite/realm |

> **回插到 `popular_apps_forensics.md` §10.5** 云端 AI 对照表。

### 3.7 WhatsApp 群组深度（**前所未覆盖**）
> 美亚杯 Q49–Q61 一整套 WhatsApp 群组题。

**iOS WhatsApp 主库**：`Library/Documents/ChatStorage.sqlite`
| 题问 | SQL 关键 |
| --- | --- |
| WhatsApp ID | `ZWAPRIVATESETTINGS.ZJID` 或 chat 表 own jid |
| 自己的电话号 | `ZWAOWNPRIVATESETTINGS.ZUSERJID` |
| 群组 ID | `ZWAGROUPINFO.ZJID`（如 `120363400622997111@g.us`） |
| 群组名 | `ZWAGROUPINFO.ZSUBJECT` |
| 群组成员数 | `ZWAGROUPMEMBER` 表 join 计数 |
| 群组管理员 | `ZWAGROUPMEMBER.ZADMINISTRATOR = 1` |
| 群组创建时间 | `ZWAGROUPINFO.ZCREATIONTIMESTAMP`（Cocoa） |
| 投票活动数 | `ZWAMESSAGE` 内 message_type = poll |
| 频道关注数 | `ZWANEWSLETTER` 表 |
| 社群（Communities） | `ZWACOMMUNITY` 表 |
| 群组图标 SHA-256 | 提取 `Library/Caches/Profile/` 群组头像后 hash |

**Android WhatsApp**：`/data/com.whatsapp/databases/msgstore.db`（默认 SQLCipher，密钥派生看 `apk_crypto_analysis.md`），表名同样 `groups` `group_participants` 等。

### 3.8 加密货币 / 钱包 / 助记词题（美亚杯 Q92–Q98）
- 题问"BEP-20 IQ Coin 钱包地址 / 存入次数 / TX 哈希 / 助记词文件"
- BEP-20 = BNB Chain；地址形如 `0x...`；用 BSCScan API / 区块链浏览器查
- 助记词文件特征：
  - 12 / 24 个 BIP-39 单词（英文）
  - 文件可能伪装为 .txt .doc .png 等
  - 用 `bip-39-list.txt` 全词比对扫整个检材
  ```python
  WORDS = set(open('bip39_en.txt').read().split())
  for f in files:
      content = open(f, errors='ignore').read().lower().split()
      hits = [w for w in content if w in WORDS]
      if 12 <= len(hits) <= 24 and len(set(hits)) == len(hits):
          print(f, hits)
  ```

> **回插到 `crypto_currency_forensics.md`**（如已建）。

---

## 4. 2025 第六届警铮杯（速查 1 行 1 题）

| 题 | 答案位置 | 新点 |
| --- | --- | --- |
| 机主 QQ 号（QQ 没装） | **火眼"关联账号"功能** | 关联账号 = 浏览器 cookie + WebView + 第三方登录 token 反查 |
| 机主微信号 | 火眼直接出 | — |
| 微信现有好友数 | 主库 contact 表 type='@chatroom' 排除后计数 | — |
| 银行卡卡号 | 微信群聊 / 备忘录 | — |
| 幕后老大手机号 | 通讯录 + 短信 | — |
| 网卡 MAC | 注册表 / `ipconfig /all` | — |
| 计划任务时间 | `schtasks /query` | 已写 |
| 表格"两个字姓名"统计 | Excel 公式 `=LEN(A1)=2` | — |
| 网站后台密码加密盐 | 看源码 PHP `md5(pwd.salt)` | — |

> 警铮杯整体偏简单；**唯一新点是"火眼关联账号"——能识别未直接安装但留痕的账号**。

---

## 5. 跨场赛事的"通用新套路"汇总

下列条目从多场 writeup 反复出现，是 **2025–2026 年取证赛新基本功**：

### 5.1 索引时间过滤 + 文件 EXIF 反推（数证杯 Q22 模式）
- 商业取证软件"索引搜索 → 时间范围"是关键功能；
- 可定位某天发生了什么 + 当时手机是什么型号（看那天照片 EXIF）。

### 5.2 缩略图缓存恢复"已删搜索/聊天/文档"（数证杯 Q24 模式）
- 三大类缩略图：浏览器、聊天 App、相册；
- 即使数据库被清，缩略图缓存常残留**首屏**或**预览图**。
- 对照表见 §2.4 + `competition_2024_2025_writeups.md` §5.2。

### 5.3 仿真还原嫌疑人原 App 状态（数证杯 Q30 模式）
**通用流程**：
```
1. 提取 /data/data/<pkg>/ 完整沙盒
2. 雷电/MuMu/夜神模拟器准备相同/相近 Android 版本
3. 安装相同版本 APK
4. 用 MT 管理器 / adb 把沙盒覆盖到模拟器
5. 启动 App → 进入嫌疑人原状态（含登录 / 应用锁 / 缓存）
6. 操作即可看见隐藏内容
```

### 5.4 应用锁 password 字段 MD5 爆破
- xml/sp/db 内字段名常为 `password` `pwd` `pin_md5` `lock_password`；
- 32 位 hex → MD5 → hashcat -m 0 / cmd5 / somd5；
- 命中率高的字典：6 位纯数字、6 位生日、case-insensitive 中文拼音 +常见数字、本机已知密码。

### 5.5 摩斯/视频内容自创编码 → 密码
- 视频被损坏 → 修复 → 看视频内容找编码规律 → 出密码。
- 数证杯老虎/2025 多场赛 / 蓝帽杯历年都出过此类。

### 5.6 应用关联账号识别（火眼 / 取证大师"关联账号"功能）
- App 没装，但留下关联痕迹（cookie、token、WebView 缓存、社交一键登录）；
- 商业软件能反推出 QQ、微信、微博、头条等账号。
- 自研：grep `qq=`、`uid=`、`oicq` cookie、WebView IndexedDB 内的登录态。

### 5.7 BIP-39 助记词全检材扫描
- §3.8 见模板。可直接做成工具 `f:\电子取证\FIC2026-mobile_work\bip39_scan.py`（待写）。

---

## 6. 2025 SPC 决赛 EXE 木马题（**与手机 APK 题型对照**）

> SPC 决赛三、EXE 二进制（Q1–Q5）：分析木马 → 找 hack.edata 解密代码 → 找接收指令函数。

**与 APK 题对照**：
| 关注点 | APK 题 | EXE 木马题 |
| --- | --- | --- |
| 反编 | jadx | IDA / Ghidra |
| 加密资源 | assets/config.dat AES | hack.edata 自定义加密 |
| 解密代码 | Java m312t() / Native libsecurity.so | DLL 内导出函数 |
| 网络回传 | DataUploader | C&C 指令分发函数 |

> 不展开（用户专注手机/APK），仅留对照表。EXE 题型详见用户后续要求时再建 KB。

---

## 7. 与已有 KB 的回插

| 本文新增 | 已有 KB |
| --- | --- |
| §2.1 iOS Adlockdown.json MtpNo | `ios_fundamentals.md` 设备 SN 来源 |
| §2.2 EXIF 反推手机型号 | `device_basic_info.md` |
| §2.3 通话频次 SQL | `quick_reference.md` Android db 快速查询 |
| §2.4 浏览器缩略图缓存对照 | `popular_apps_forensics.md` 缓存清单 |
| §2.5 Telegram 用户保存目录 | `popular_apps_forensics.md` |
| §2.6 AI 生成图来源识别 | `popular_apps_forensics.md` §10.5 |
| §2.7 应用隐藏器（Amarok） | `lock_password_forensics.md` 应用锁 |
| §2.8/2.9 PNG/MP4 修复 | `stego_crypto/quick_reference.md` |
| §2.10 BIN 表 | `crypto_currency_forensics.md` 或独立 |
| §3.1 iOS Manifest.plist 爆破 | `ios_forensics.md` |
| §3.2 AirDrop 取证 | `ios_logs.md` |
| §3.3 Photos.sqlite ZCREATORBUNDLEID | `ios_app_parsing.md` |
| §3.7 WhatsApp 群组 SQL | `popular_apps_forensics.md` |
| §3.8 BIP-39 助记词扫描 | `crypto_currency_forensics.md` |
| §5.6 关联账号识别 | `android_app_attribution.md` |

---

## 8. 待补 / 后续

- 2024 FIC 决赛（玫幽倩 2026-01-22）—— 待读
- 2024 数证杯初赛 —— 待读
- 2025 SPC 初赛 / 文件结构和数据分析专项 —— 待读（多服务器 / Misc，与手机/APK 关联弱）
- DFIRDD.com —— DNS 解析失败，跳过；DFIR蘇小沐 cnblogs 待用户决定是否学

---

## 9. 引用

- 玫幽倩博客电子取证分类：https://mei-you-qian.github.io/categories/%E7%94%B5%E5%AD%90%E5%8F%96%E8%AF%81/
- 2025 数证杯决赛-团体赛（手机部分）：https://mei-you-qian.github.io/2025/12/01/2025%E6%95%B0%E8%AF%81%E6%9D%AF%E5%86%B3%E8%B5%9B-%E5%9B%A2%E4%BD%93%E8%B5%9B/
- 2025 美亚杯-资格赛（全）：https://mei-you-qian.github.io/2025/11/21/2025%E7%BE%8E%E4%BA%9A%E6%9D%AF-%E8%B5%84%E6%A0%BC%E8%B5%9B/
- 2025 第六届警铮杯：https://mei-you-qian.github.io/2025/11/25/2025%E8%AD%A6%E9%93%AE%E6%9D%AF/
- 2025 SPC 决赛：https://mei-you-qian.github.io/2025/12/22/2025SPC%E7%94%B5%E5%AD%90%E5%8F%96%E8%AF%81%E7%AB%9E%E8%B5%9B%E5%86%B3%E8%B5%9B/
