# Mobile Forensics — Quick Reference

## Android
```bash
# ALEAPP (automated extraction)
aleapp -t tar -i {backup.tar} -o {output_dir}
aleapp -t fs -i {extracted_dir} -o {output_dir}

# ADB (live device)
adb devices
adb shell pm list packages              # Installed packages
adb shell dumpsys battery               # Battery stats
adb pull /data/data/{package}/          # Pull app data
adb backup -all -f backup.ab           # Full backup
```

## iOS
```bash
# iLEAPP (automated extraction)
ileapp -t tar -i {backup.tar} -o {output_dir}
ileapp -t fs -i {backup_dir} -o {output_dir}

# Manifest.db — master index of backup files
sqlite3 Manifest.db "SELECT fileID, relativePath, flags FROM Files WHERE relativePath LIKE '%sms%';"
```

## SQLite Database Analysis
```bash
sqlite3 {db}
.tables                                 # List tables
.schema {table}                         # Table structure
SELECT * FROM {table} LIMIT 10;        # Sample data
SELECT * FROM messages ORDER BY date DESC LIMIT 50;  # Recent messages
```

## WeChat Forensics (Android)
- DB path: `/data/data/com.tencent.mm/MicroMsg/{hash}/EnMicroMsg.db`
- Encrypted with SQLCipher, key derived from IMEI + UIN
- Key extraction: `md5(IMEI + uin)[:7]`
- Open with: `sqlcipher EnMicroMsg.db` → `PRAGMA key = '{key}';`

## WeChat Forensics (iOS)
- DB path: `AppDomain-com.tencent.xin/Documents/{hash}/DB/MM.sqlite`
- Not encrypted on iOS (accessible from backup)

## Common Timestamps
- Android: Unix **ms** (`mmssms.db.date`, `calllog.db.date`, WeChat `createTime`)
- Android QQ: Unix **秒**（⚠️ 不一致，先验证）
- iOS Cocoa: 秒 since 2001-01-01 → `+ 978307200` = Unix 秒
- iOS sms.db (iOS 13+): **纳秒** Cocoa → `ZDATE / 1e9 + 978307200`
- Chrome/Edge `last_visit_time`: WebKit µs since 1601-01-01 → `/ 1e6 - 11644473600`
- Windows FILETIME: 100ns since 1601 → `/ 1e7 - 11644473600`
- 完整对照表+换算公式+Python/SQL 一行代码：
  → `@knowledge/skills/timestamps_reference.md`

## 2026 FIC 初赛新题型（2026-05 已发布 wp）
- 完整笔记：`@knowledge/skills/mobile/fic2026_writeup.md`
- **Hybrid WebView App 取证**：jadx 搜 `@JavascriptInterface` / `addJavascriptInterface` / `file:///android_asset/` / `loadUrl(`；离线页常在 `assets/www/index.html`。
- **Base64 上传 URL**：见 `aHR0cHM6Ly...`（== `https://...`）一律 `base64.b64decode`。
- **assets/config.dat AES-128/ECB**：key 派生常为 `MD5(seed).hexdigest()[:16].encode()`；seed 串去 `resources.arsc` 的 `<string name="config_seed">` 找。
- **自研聊天 App 双库**：明文索引 + `wk_<32hex>.db` 加密；**密码 = 文件名 hex 本身**（小作坊懒人式）。
- **Native XTEA 取证**：`libsecurity.so` `.rodata` 段含 4×u32 key + delta `0x61C88649` → 32/64 轮 XTEA；前置 XOR `(i&0x0f)^0x55` 常见。
- **移动端本地 LLM**：PocketPal AI（`com.pocketpalai`）/ MLC Chat；`models/*.gguf` + `databases/chat.db` 数提问数。
- **DJI 飞行日志**：`/data/dji.go.v5/files/FlightRecord/`；`.txt` 直读、`.DAT` 用 DatCon/CsvView/PhantomHelp；经纬度反向地理编码出"在哪个县飞行"。完整方法论见 `@knowledge/skills/mobile/dji_forensics.md`。
- **Win32 GUI 加密程序**（独立赛卷大类）：DIE 看时间 → IDA WinMain → 按钮 ID 10001 → AES-128 轮密钥 0xB0 + 异或 → Python 解密拿密码 → 解密 .vhd 挂载。

## iOS 工具就绪状态（本机已部署）
- 完整清单：`@knowledge/skills/mobile/ios_toolchain.md`
- **libimobiledevice** 25+ 工具齐：`e:\自动化取证\bin\libimobiledevice\`（idevicebackup2/info/installer/imagemounter/syslog/iproxy/usbmuxd/plistutil/irecovery/idevicerestore/...）。
- **iLEAPP** 已部署：`e:\自动化取证\bin\iLEAPP\`，`python ileapp.py -t {fs|tar|zip|gz|itunes|file} -i ... -o out`，加密备份用 `--itunes_password 1234`。
- **ALEAPP** 已部署：`e:\自动化取证\bin\ALEAPP\`（Android 对应版）。
- **APOLLO** 已部署：`e:\自动化取证\bin\APOLLO\` —— **行为时间线一表通**（KnowledgeC + Powerlog + Cellular + interactionC + Health 合并）。
- **mvt-ios / mvt-android** 全局 CLI：`mvt-ios decrypt-backup` / `check-backup` / `check-iocs`（含 Pegasus 等间谍软件 IOC 检测）。
- **ccl-bplist** 已用 `.pth` 注册到全局：`import ccl_bplist` 直接可用（NSKeyedArchiver 反序列化）。
- **exiftool 12.34** 已复用盘古石自带：`e:\自动化取证\bin\exiftool\exiftool.exe`（HEIC/JPEG/MOV EXIF/GPS）。
- **DB Browser for SQLCipher.exe**（GUI）已在 `e:\自动化取证\bin\sqlitebrowser\`，输 KEY 即可解密预览。
- **Python 库**：iOSbackup、pymobiledevice3、nska_deserialize、biplist、sqlcipher3、**sqlite_dissect**、**mvt**、pyliblzfse、pillow_heif、astc_decomp_faster、frida、pycryptodome 全装。
- **hashcat 6.2.6** + `itunes_backup2hashcat.pl`：`-m 14700` (iOS ≤10.1) / `-m 14800` (iOS 10.2+)。
- **sysdiagnose 包解析**：`e:\自动化取证\bin\iOS_sysdiagnose_legacy\`（cheeky4n6monkey，纯 Python 脚本可跑）；`e:\自动化取证\bin\sysdiagnose\`（EC 现代版仅作代码参考，Windows 缺 _curses）。
- **商业软件**：盘古石 GoldenEyesV4 / APPAnalysisV4 / X-Ways Forensics v20 / ForensicRecorder。
- **结论**：电子数据取证比赛中**所有 iOS 题目**（备份/加密备份/越狱镜像/SQLite 雕复/SQLCipher/plist/HEIC EXIF/统一日志/行为时间线/IOC）都已具备完整解题能力。

## DFIR蘇小沐博客重点（手机/APK/微信/汽车）
- 完整笔记：`@knowledge/skills/mobile/dfir_suxiaomu_writeups.md`
- **drizzleDumper 老牌脱壳**：内存扫 dex 魔数；对 360/爱加密/梆梆**老版**有效；新加固走 frida-dexdump / blackdex。
- **apk2url 工具**：`apk2url file.apk` → `endpoints/_uniqurls.txt` `_endpoints.txt`；URL 速提取，比 strings+grep 干净。
- **微信 Dat 异或解密**：单字节 XOR；前 2 字节 ⊕ 已知 magic（JPG `FF D8` / PNG `89 50` / GIF `47 49` / BMP `42 4D`）推 key → 全文异或还原。Android/PC 同算法。
- **PC 微信版本路径演进**：v3.7.0.26 起图片入 `MsgAttach/<MD5(微信ID)>/Image/`；v3.9.9.35 后视频/文件回滚旧位置；v4.x 全部重构 `xwechat_files/`。
- **微信收藏图片三处并存缓存**：原图 / 加密 / 转发再压缩 SHA 不同。
- **iOS 17.3+ 失窃设备保护**（18.2 起默认开启）：陌生地点修改关键设置需生物识别 + 1 小时延迟 + 二次确认；现场关闭 / Faraday 袋 / 物理提取绕过。
- **汽车 EDR 反常数据**：碰撞前 5s 车速骤减但制动状态"关闭" = 自适应巡航控制（ACC）减速；多源（EDR+TBOX+IVI+手机+视频）关联印证。
- **源盘 hash ≠ 镜像文件 hash**：取证报告必须两个都列；E01 还有 ewf 元数据，与 DD 也不等。

## 2025 数证杯/美亚杯/警铮杯/SPC 增量（玫幽倩 wp）
- 完整笔记：`@knowledge/skills/mobile/competition_2025_late_writeups.md`
- **iOS 序列号备用路径**：备份根目录 `Adlockdown.json` 的 `MtpNo` 字段。
- **EXIF 反推手机型号**：嫌疑人当时手机型号 = 那个时段照片 EXIF 的 `Make/Model`；火眼"索引搜索 + 时间过滤"先定位照片。
- **火狐搜索结果不在 history.db**：`/data/data/org.mozilla.firefox/cache/mozac_browser_thumbnails/thumbnails/` 缩略图缓存里。
- **Telegram 用户保存目录**：`/data/media/0/Telegram/`，卸载后仍在。
- **AI 生成图来源识别**：豆包 (`com.larus.nova`)、即梦、文心一格、通义万相 等多带水印 + EXIF Comment/Software 字段；exiftool 批量过滤。
- **应用隐藏器 Amarok**：xml 内 password 是 MD5；hashcat -m 0 爆破 → 模拟器仿真复原嫌疑人状态 → 复制到 `/storage/emulated/0/Private/` 解隐藏。
- **iOS 加密备份**：`Manifest.plist` → `itunes_backup2hashcat` + hashcat `-m 14700/14800` 或 passwarekit GUI。
- **iOS Photos.sqlite 反查"由哪个 App 拍摄"**：`ZADDITIONALASSETATTRIBUTES.ZCREATORBUNDLEID` / `ZIMPORTEDBYBUNDLEIDENTIFIER`。
- **AirDrop 痕迹**：unified log `subsystem==com.apple.sharing` + `com.apple.Sharingd.plist` + IDS 身份。
- **WhatsApp 群组 SQL**：iOS `ChatStorage.sqlite` 表 `ZWAGROUPINFO` / `ZWAGROUPMEMBER`；管理员 = `ZADMINISTRATOR=1`。
- **BIP-39 助记词全检材扫描**：12/24 词去重 + 全部命中 BIP-39 单词表。
- **火眼"关联账号"功能**：App 没装也能反推 QQ/微信账号（通过浏览器 cookie / WebView 登录态）。

## 2024–2025 比赛真题增量（新题型）
- 增量笔记：`@knowledge/skills/mobile/competition_2024_2025_writeups.md`
- **Flutter APK**（业务全在 `libapp.so`）：用 **blutter** 反编 + 自动生成 frida hook；典型 `com.carriez.flutter_hbb`（RustDesk）。
- **小米相册缓存**：`Android/data/com.miui.gallery/files/gallery_disk_cache/full_size/<sha256>.0` 即使删原图仍保留。
- **dd 后缀实为 tar/zip**：第一步永远 `file` + `binwalk` 看真实格式。
- **第三方备忘录**（如 `com.bijoysingh.yang/databases/note-database`）常藏 PC 密码 / 暗号 / 钱包密钥。
- **PyInstaller Mac 程序**：用 `pyinstxtractor-ng` + `decompyle3`/`pylingual` 反编。
- **Web3 域名**：`.eth=ENS/ETH`、`.crypto/.x/.nft=Unstoppable`、`.bnb=SpaceID/BNB`、`.sol=Solana`。
- **套娃 stego**：聊天图原图→stegsolve 异色通道→二维码→RAR 密码→VeraCrypt 容器→反色得密码→欠条/答案。

## DIDCTF / 长安杯 / FIC 真题速查
- 综合方法论（题型 ↔ 工具 ↔ KB 索引）：`@knowledge/skills/mobile/didctf_writeup_methodology.md`
- 高频出题方向：
  - APK 反编 + 抓包还原回传逻辑（长安杯 2021 套路 A）
  - 商业软件一遍 → 翻源文件兜底（FIC 2024 套路 B）
  - APK 加固多关 FLAG（长安杯 2022 套路 C）
- 易踩坑：包名 ≠ 应用名；DCloud 流应用 APPID 在 manifest meta-data；EnMicroMsg.db 路径下 32 位 hex = MD5("mm"+uin)；VeraCrypt 容器扩展名常被改成 `.txt`。

## Android 关键源文件（背）
- 微信 ID/uin/手机号: `data/com.tencent.mm/shared_prefs/com.tencent.mm_preferences.xml`（字段 `login_weixin_username` / `last_login_uin` / `login_user_name`）
- 微信解密辅料: `data/com.tencent.mm/shared_prefs/auth_info_key_prefs.xml`
- 微信主库: `data/com.tencent.mm/MicroMsg/<32位hex>/EnMicroMsg.db`（hex = MD5("mm"+uin)）
- Wi-Fi 历史 + 第一次连接: `misc/wifi/WifiConfigStore.xml` 字段 `CreationTime`
- 手机型号 UA: `misc/location/xtra/useragent.txt`
- 已装 App + 安装时间: `data/system/packages.xml`
- App 使用频度: `data/system/usagestats/0/`
- 蓝牙配对: `data/misc/bluedroid/bt_config.conf`

## APK 反编关键字搜索清单
- DB 文件名: `SQLiteOpenHelper` `DATABASE_NAME` `dbName` `openOrCreateDatabase` `.db` `.sqlite`
- SQLCipher key: `sqlite3_key` `WCDB` `setPassword` `cipher_compatibility`
- 上传 URL: `apiserver` `apiUrl` `BASE_URL` `host` `endpoint`
- 短信回传: `sms` `duanxin` `apisms` `SmsManager`
- 加密函数: `encrypt` `decrypt` `Cipher` `AES` `Base64`
- DCloud 流应用: `DCLOUD_STREAMAPP_CHANNEL` `plus.H5` `assets/apps/H5*/www/`
