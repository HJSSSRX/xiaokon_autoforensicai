# iOS 取证工具链总览（本机就绪状态）

> 验证时间：2026-05-08。本机所有工具已就绪可用。
> 本文件**唯一作用**：列清楚"用什么、在哪、怎么调"。决策与方法论见 `ios_forensics.md` / `ios_fundamentals.md`。

---

## 1. 命令行工具（已部署）

### 1.1 libimobiledevice 全家桶
- 路径：`e:\自动化取证\bin\libimobiledevice\`
- 25+ exe 全齐：

| exe | 用途 | 速记 |
| --- | --- | --- |
| `idevice_id.exe` | 列连接设备 UDID | `idevice_id -l` |
| `ideviceinfo.exe` | 设备信息（IMEI/Serial/型号/系统版本/电话号码） | `ideviceinfo -k SerialNumber` |
| `idevicepair.exe` | 配对管理 | `idevicepair pair` / `idevicepair list` |
| `idevicebackup2.exe` | iTunes 风格备份创建/恢复/解密 | `idevicebackup2 backup --full <out>` |
| `ideviceinstaller.exe` | 列已装 App / 安装 ipa | `ideviceinstaller -l` |
| `ideviceimagemounter.exe` | 挂开发者镜像（启 SSH/调试用） | `ideviceimagemounter DeveloperDiskImage.dmg` |
| `idevicesyslog.exe` | 实时系统日志 | `idevicesyslog > log.txt` |
| `idevicescreenshot.exe` | 锁屏外截屏 | `idevicescreenshot out.png`（需开发者镜像） |
| `idevicecrashreport.exe` | 拉崩溃日志 | `idevicecrashreport -e -k <out>` |
| `iproxy.exe` | USB→TCP 端口转发（越狱 SSH 必备） | `iproxy 2222 22` |
| `irecovery.exe` | DFU/Recovery 模式控制 | `irecovery -m`（看模式） |
| `idevicerestore.exe` | 固件刷写 | 一般取证不用 |
| `idevicedebug.exe` | App 启动/调试 | 越狱设备 |
| `idevicedebugserverproxy.exe` | LLDB 调试代理 | 越狱设备 |
| `ideviceactivation.exe` | 激活 | 一般取证不用 |
| `usbmuxd.exe` | USB 多路复用守护 | Apple Mobile Device Service 备选 |
| `plistutil.exe` | plist 二进制 ↔ 文本互转 | `plistutil -i bin.plist -o text.xml` |
| `plist_cmp.exe` / `plist_test.exe` | plist 工具 | 调试用 |
| `ios_webkit_debug_proxy.exe` | Web 调试 | 较少用 |

> 把目录加到 PATH（已加），任意位置可直接运行。

### 1.2 通用辅助工具
| 工具 | 路径 | 用途 |
| --- | --- | --- |
| `hashcat.exe` 6.2.6 | `e:\自动化取证\bin\hashcat\hashcat-6.2.6\` | 备份口令爆破 |
| `itunes_backup2hashcat.pl` | 同上 | 备份 → hashcat 哈希格式 |
| `sqlite3.exe` | `e:\自动化取证\framework\bin\platform-tools\` | 命令行查 SQLite |
| **`DB Browser for SQLite.exe`** | `e:\自动化取证\bin\sqlitebrowser\` | GUI 查 SQLite |
| **`DB Browser for SQLCipher.exe`** | `e:\自动化取证\bin\sqlitebrowser\` | GUI 查 SQLCipher（输入 KEY 即可解密预览） |
| **`exiftool.exe`** 12.34 | `e:\自动化取证\bin\exiftool\` | HEIC/JPEG/MOV EXIF 元数据（GPS/相机/拍摄时间） |
| `undark` | `e:\自动化取证\bin\undark\` | SQLite 已删行/WAL 恢复 |
| `jadx`/`apktool` | `e:\自动化取证\bin\jadx\` `apktool\` | iOS 题如混合 APK 时 |
| `sleuthkit` | `e:\自动化取证\bin\sleuthkit\` | 文件系统取证 |

### 1.3 商业 / 综合取证软件
| 软件 | 路径 | iOS 能力 |
| --- | --- | --- |
| **盘古石 GoldenEyesV4**（Essential.exe） | `f:\电子取证\GoldenEyesV4\` | 完整 iOS 备份/沙盒解析、关键 App 自动化 |
| **APPAnalysisV4** | `f:\电子取证\APPAnalysisV4\` | 应用分析（Android+iOS） |
| **X-Ways Forensics v20** | `f:\电子取证\取证工具集\综合分析工具\` | 镜像 / APFS 解析 |
| **ForensicRecorder** | `f:\电子取证\ForensicRecorder\` | 取证记录 |

> 比赛主战场常是商业软件 + 半手工脚本结合；商业软件出不来的细节用下面的开源工具补齐。

---

## 2. Python 库（已 pip 安装）

| 包 | 版本 | 用途 |
| --- | --- | --- |
| `iOSbackup` | 0.9.925 | iTunes 加密备份解密 + 文件按 domain 提取 |
| `pymobiledevice3` | 9.12.0 | **libimobiledevice 现代替代**，支持 iOS 17/18，纯 Python |
| `nska_deserialize` | 1.5.1 | NSKeyedArchiver bplist 反序列化（**微信 MMSetting / 各 App preference**） |
| `biplist` | 1.0.3 | 老式 binary plist 解析（NSKeyedArchiver 备选） |
| `sqlcipher3` | 0.6.2 | SQLCipher 解密（部分 iOS App 用） |
| **`sqlite_dissect`** | latest | 已删行/freelist/journal/WAL 雕复（Microsoft 出品，比 undark 强） |
| **`mvt`** | 2026.4.28 | Mobile Verification Toolkit（Amnesty）。`mvt-ios` 解析备份/FS、间谍软件 IOC 检测 |
| `pyliblzfse` | 0.4.1 | Apple LZFSE 压缩（unified log / shutdown log 解压） |
| `astc_decomp_faster` | 1.1.2 | iOS ASTC 纹理解码 |
| `pillow_heif` | 1.3.0 | HEIC 照片处理 |
| `pycryptodome` | latest | AES/RSA/PBKDF2 |
| `frida` / `frida-tools` | 17.9.6 / 14.8.2 | 动态 hook（越狱设备） |
| `mdplistlib` | 0.1.3 | Apple iCloud bplist 增强 |
| `bencoding` `blackboxprotobuf` `mmh3` `PGPy` `simplekml` | iLEAPP 依赖 | 各类工件解析 |

### 2.1 ccl-bplist（Git 部署）
- 路径：`e:\自动化取证\bin\ccl-bplist\`
- 用法：
  ```python
  import sys; sys.path.insert(0, r'e:\自动化取证\bin\ccl-bplist')
  import ccl_bplist
  with open('MMSetting.archive','rb') as f:
      d = ccl_bplist.load(f)
      t = ccl_bplist.deserialise_NsKeyedArchiver(d)
  ```

### 2.2 iLEAPP（**iOS 200+ artifact 自动解析框架**）
- 路径：`e:\自动化取证\bin\iLEAPP\`
- 调用：
  ```bash
  cd e:\自动化取证\bin\iLEAPP
  python ileapp.py -t itunes  -i C:\Backup\<UDID>      -o out\         # iTunes 备份
  python ileapp.py -t fs      -i E:\extracted_fs       -o out\         # 越狱文件系统
  python ileapp.py -t zip     -i extraction.zip        -o out\         # 商业工具导出 zip
  python ileapp.py -t tar     -i extraction.tar        -o out\
  python ileapp.py -t gz      -i extraction.tar.gz     -o out\
  python ileapp.py --itunes_password 1234 -t itunes -i ... -o ...      # 加密备份直接给密码
  python ileapp.py -p                                                   # 列所有可解析模块
  ```
- **常用输出**：
  - HTML 总报告（开浏览器看）
  - tsv 详表（每个 artifact 一份）
  - timeline.csv（时间线总表）
  - kml（地理轨迹）

### 2.3 ALEAPP（**Android 对应版**，搭配做混合题）
- 路径：`e:\自动化取证\bin\ALEAPP\`
- 调用同上：`python aleapp.py -t fs -i extracted -o out`

### 2.4 mvt-ios（Mobile Verification Toolkit）
- 全局 CLI 命令：`mvt-ios` / `mvt-android`
- 调用：
  ```bash
  # 解析加密 iTunes 备份（输入密码）
  mvt-ios decrypt-backup -p PASSWORD -d decrypted_dir backup_dir
  mvt-ios check-backup -o out_dir decrypted_dir
  mvt-ios check-fs    -o out_dir extracted_fs_dir          # 越狱镜像
  mvt-ios check-iocs  -i indicators.stix2 out_dir          # 间谍软件 IOC 检测
  mvt-ios download-iocs                                     # 下载最新 IOC（Pegasus 等）
  ```
- 与 iLEAPP 互补：mvt 偏 IoC 检测和 sandbox/iCloud 痕迹；iLEAPP 偏全 artifact 报告。

### 2.5 APOLLO（**Apple Pattern of Life Lazy Outputter**）
- 路径：`e:\自动化取证\bin\APOLLO\`
- 调用：
  ```bash
  cd e:\自动化取证\bin\APOLLO
  python apollo.py -o sql -p ios extract MODULES_DIR DATA_PATH
  # ios = iOS 模块；DATA_PATH = 含 KnowledgeC/Cellular/Powerlog 等 sqlite 的目录
  ```
- 价值：**极简一句话产出"用户行为时间线"**——KnowledgeC（屏幕使用 / App 启动 / 通知）、CurrentPowerlog、interactionC、CellularUsage、HealthDB、CallHistory、etc 都汇成一张表。
- 题型：**还原嫌疑人何时打开了哪个 App、何时收到通知、何时发短信打电话**。

### 2.6 sysdiagnose 解析（仅参考，Windows 兼容性差）
- 现代框架：`e:\自动化取证\bin\sysdiagnose\`（EC-DIGIT-CSIRC，Linux 设计；Windows 缺 `_curses` 不可直接 CLI 跑，可作代码参考）
- 老牌脚本：`e:\自动化取证\bin\iOS_sysdiagnose_legacy\`（cheeky4n6monkey，纯 Python，Windows 可跑）
  ```bash
  python e:\自动化取证\bin\iOS_sysdiagnose_legacy\sysdiagnose-mobilebackup.py <sysdiagnose_dir>
  python e:\自动化取证\bin\iOS_sysdiagnose_legacy\sysdiagnose-wifi-net.py     <sysdiagnose_dir>
  ```
- > 取证比赛极少考 sysdiagnose 包；备份/越狱镜像/商业导出占 95%+。

---

## 3. 速查命令模板（按题型）

### 3.1 设备信息题（IMEI / Serial / 型号 / 电话号 / iOS 版本）
```powershell
# 有连接的真机
ideviceinfo -k SerialNumber
ideviceinfo -k InternationalMobileEquipmentIdentity
ideviceinfo -k ProductType
ideviceinfo -k ProductVersion
ideviceinfo -k PhoneNumber

# 仅有备份目录
plistutil -i "$Backup\Info.plist" -o info.xml
Select-String -Path info.xml -Pattern "Serial|IMEI|Phone|ProductType|ProductVersion"

# Adlockdown.json（数证杯路径）
Get-Content Adlockdown.json | ConvertFrom-Json | Select-Object MtpNo
```

### 3.2 加密备份题（密码 / 解密 / 提取）
```powershell
# 1) 已知密码：iLEAPP 一把梭
cd e:\自动化取证\bin\iLEAPP
python ileapp.py --itunes_password 1234 -t itunes -i "C:\Backup\<UDID>" -o out

# 2) 不知道密码：先转 hashcat → 字典/规则爆破
perl e:\自动化取证\bin\hashcat\hashcat-6.2.6\itunes_backup2hashcat.pl "C:\Backup\<UDID>" > h.txt
hashcat -m 14800 h.txt rockyou.txt -O          # iOS 10.2+
# hashcat -m 14700 h.txt rockyou.txt -O        # iOS ≤ 10.1

# 3) 设备解锁：重置备份密码（不丢用户数据，需先做镜像）
# 设置 → 通用 → 传输或还原 iPhone → 还原 → 重置所有设置
```

### 3.3 SQLite 题（短信 / 通话 / 浏览器 / 微信）
```powershell
# Manifest.db 找文件
sqlite3 "$Backup\Manifest.db" "SELECT fileID,domain,relativePath FROM Files WHERE relativePath LIKE '%sms.db%';"

# 拼接备份内真实路径
$fid = "3d0d7e5fb2ce288813306e4d4636395e047a3d28"
Copy-Item "$Backup\$($fid.Substring(0,2))\$fid" sms.db

# Mac AbsTime 时间戳查询模板
sqlite3 sms.db "SELECT datetime(date/1000000000+978307200,'unixepoch','localtime'),text FROM message;"
```

### 3.4 plist 题（NSKeyedArchiver / preferences）
```powershell
# 文本 plist
plistutil -i bin.plist -o text.xml

# NSKeyedArchiver
python -c "import sys; sys.path.insert(0, r'e:\自动化取证\bin\ccl-bplist'); import ccl_bplist; f=open(r'$plist','rb'); d=ccl_bplist.load(f); print(ccl_bplist.deserialise_NsKeyedArchiver(d))"

# 现代写法
python -c "import nska_deserialize as n; import sys,pprint; pprint.pp(n.deserialize_plist(open(r'$plist','rb')))"
```

### 3.5 行为还原题（KnowledgeC / TCC / Photos / Safari）
```powershell
# 一把梭让 iLEAPP 解
python e:\自动化取证\bin\iLEAPP\ileapp.py -t fs -i extracted_fs -o out
# out\report.html 里翻 KnowledgeC / TCC / Safari / Photos / Health

# 行为时间线：APOLLO 一表通
cd e:\自动化取证\bin\APOLLO
python apollo.py -o sql -p ios extract modules <含 KnowledgeC.db/Cellular/Powerlog 的目录>
# 输出：apollo.db 里的 timeline 表 = 全部 Apple POL 数据合并
```

### 3.6 EXIF / GPS / 拍摄设备题（iOS HEIC / 视频）
```powershell
exiftool -a -G1 -s -ee  IMG_xxxx.HEIC                    # 全部 EXIF
exiftool -GPSPosition -GPSDateTime -DateTimeOriginal IMG_*.HEIC
exiftool -r -ext heic -ext mov -csv -GPSPosition -DateTimeOriginal <Photos_dir> > exif.csv
exiftool -live  IMG_xxxx.HEIC                            # Live Photo 关联
```

### 3.7 SQLite 已删行雕复（sms.db / Photos.sqlite）
```powershell
# 1) undark：快速 dump 已删行
undark -i sms.db --no-ascii > recovered.sql

# 2) sqlite_dissect：完整解析 freelist + WAL + journal
python -m sqlite_dissect sms.db --output recovered_dir --no-warnings
```

### 3.8 间谍软件 / 异常 App 检测（mvt-ios）
```powershell
mvt-ios decrypt-backup -p PASSWORD -d dec   raw_backup_dir
mvt-ios check-backup -o mvt_out             dec
mvt-ios download-iocs                                          # 下载 Pegasus 等 IOC
mvt-ios check-iocs   -i ~/.local/share/mvt/indicators/*.stix2  mvt_out
```

### 3.9 混合现代设备（iOS 17/18，libimobiledevice 不支持时）
```powershell
# 改用 pymobiledevice3
pymobiledevice3 backup2 backup --full --no-encryption out_dir
pymobiledevice3 lockdown info
pymobiledevice3 syslog live
pymobiledevice3 mounter mount-developer
pymobiledevice3 apps list --user
```

---

## 4. 工具能力矩阵

| 题型 | 首选 | 备选 | 备注 |
| --- | --- | --- | --- |
| 设备基本信息 | `ideviceinfo` / `Info.plist` | 商业软件 | 离线读 plist 即可 |
| 加密备份解密 | `iOSbackup` Python | iLEAPP `--itunes_password` / `mvt-ios decrypt-backup` | 三选一 |
| 备份口令爆破 | `itunes_backup2hashcat` + `hashcat -m 14800` | EPB（无） | iOS 10.2+ PBKDF2-SHA256 极慢，靠字典 |
| 全备份解析 | **iLEAPP** | 商业软件 / mvt-ios | 报告完整 |
| 行为时间线（POL） | **APOLLO** | iLEAPP timeline.csv | KnowledgeC / Powerlog / Cellular 一表合并 |
| 间谍软件 / 异常 IOC | **mvt-ios check-iocs** | 商业软件 | Pegasus / Predator IOC |
| Manifest.db 查路径 | `sqlite3` | iLEAPP 自带 | |
| plist 文本/二进制 | `plistutil` | Python `plistlib` | |
| NSKeyedArchiver | `ccl_bplist` / `nska_deserialize` | 商业软件 | 微信 MMSetting 必用 |
| SQLite 删除恢复 | **`sqlite_dissect`** | `undark` / sqlitebrowser+雕复 | sms.db / Photos.sqlite |
| SQLCipher 解密 | `sqlcipher3` Python | DB Browser for SQLCipher GUI | 微信/部分 IM |
| HEIC / EXIF / GPS | **`exiftool`** | `pillow_heif` + iLEAPP | 拍摄设备/时间/经纬度/Live Photo |
| LZFSE 解压（unified log） | `pyliblzfse` | iLEAPP | shutdown log / wifi log |
| 越狱物理提取 | `iproxy + ssh + tar` | checkra1n+ramdisk | A11 及更老 |
| iOS 17/18 协议层 | **`pymobiledevice3`** | libimobiledevice 较旧 | RemoteXPC tunnel 需要 |
| sysdiagnose 包解析 | `iOS_sysdiagnose_legacy` 脚本 | EC sysdiagnose（仅看代码） | Windows 上 EC 版不能直接跑 |

---

## 5. 还差什么？（**取证比赛实际可用度评分**）

| 类别 | 状态 | 评估 |
| --- | --- | --- |
| iTunes 备份 / 加密备份 解析 | ✅ 完整（iLEAPP / iOSbackup / mvt-ios 三件套） | ⭐⭐⭐⭐⭐ |
| 越狱 / 文件系统镜像 解析 | ✅ 完整（iLEAPP + mvt-ios + APOLLO） | ⭐⭐⭐⭐⭐ |
| plist / bplist / NSKeyedArchiver | ✅ 完整 | ⭐⭐⭐⭐⭐ |
| SQLite + WAL + 删除恢复 | ✅ 完整（sqlite_dissect + undark） | ⭐⭐⭐⭐⭐ |
| SQLCipher 解密 | ✅ 完整（CLI + GUI 双备） | ⭐⭐⭐⭐⭐ |
| 备份密码爆破 | ✅ 完整（hashcat） | ⭐⭐⭐⭐ |
| iOS 17/18 现代协议（RSD/RemoteXPC） | ✅（pymobiledevice3） | ⭐⭐⭐⭐ |
| HEIC / EXIF / GPS / Live Photo | ✅（exiftool） | ⭐⭐⭐⭐⭐ |
| LZFSE / unified log 解压 | ✅ | ⭐⭐⭐⭐⭐ |
| 行为时间线（KnowledgeC/Powerlog） | ✅（APOLLO + iLEAPP） | ⭐⭐⭐⭐⭐ |
| 间谍软件 IOC 检测（Pegasus 等） | ✅（mvt-ios） | ⭐⭐⭐⭐ |
| sysdiagnose 包解析 | ⚠️ 仅参考（cheeky4n6monkey 老脚本） | 比赛极少考 |
| 商业级 iOS 提取（GrayKey/Cellebrite Premium） | ❌（执法专用） | 比赛一般不需要 |
| Apple ID / iCloud 抓取（EPB Cloud） | ❌ 商业 | 比赛一般不需要 |
| 越狱工具（checkra1n/palera1n） | ❌ 仅在 macOS/Linux + 旧机型 | 比赛检材都是已提取镜像，不需现场越狱 |

> **结论**：本机已具备**电子数据取证比赛中所有 iOS 题目**的完整解题能力。商业级现场提取工具（GrayKey/Cellebrite Premium）以及 Apple 后台数据抓取（EPB iCloud）属于执法专用范畴，赛场不会出现需要它们的题目。

---

## 6. 装机后的固化操作（建议）

### 6.1 PATH 检查
```powershell
$env:Path -split ';' | Select-String -Pattern "libimobiledevice|hashcat|sqlite3|jadx"
```
若 libimobiledevice 不在 PATH，**临时**：
```powershell
$env:Path = "e:\自动化取证\bin\libimobiledevice;" + $env:Path
```
**永久**：`系统设置 → 环境变量 → PATH 追加 e:\自动化取证\bin\libimobiledevice`

### 6.2 ccl-bplist 注册
建议在 `site-packages` 加 `.pth` 文件：
```powershell
"e:\自动化取证\bin\ccl-bplist" | Out-File -Encoding ascii "D:\python\Lib\site-packages\ccl_bplist_path.pth"
```
之后 `import ccl_bplist` 不再需要手动 `sys.path.insert`。

### 6.3 iLEAPP / ALEAPP 快捷
建议 powershell `$PROFILE` 加：
```powershell
function ileapp { python e:\自动化取证\bin\iLEAPP\ileapp.py @args }
function aleapp { python e:\自动化取证\bin\ALEAPP\aleapp.py @args }
```

---

## 7. 引用

- libimobiledevice：https://github.com/libimobiledevice/libimobiledevice
- iLEAPP：https://github.com/abrignoni/iLEAPP
- ALEAPP：https://github.com/abrignoni/ALEAPP
- ccl-bplist：https://github.com/cclgroupltd/ccl-bplist
- pymobiledevice3：https://github.com/doronz88/pymobiledevice3
- iOSbackup：https://pypi.org/project/iOSbackup/
- itunes_backup2hashcat：https://github.com/philsmd/itunes_backup2hashcat
- sqlcipher3：https://pypi.org/project/sqlcipher3/
- mvt（Mobile Verification Toolkit）：https://github.com/mvt-project/mvt
- APOLLO：https://github.com/mac4n6/APOLLO
- sqlite_dissect：https://github.com/dfirfpi/sqlite_dissect
- exiftool：https://exiftool.org/
- iOS_sysdiagnose_legacy：https://github.com/cheeky4n6monkey/iOS_sysdiagnose_forensic_scripts
- EC-DIGIT-CSIRC sysdiagnose：https://github.com/EC-DIGIT-CSIRC/sysdiagnose
