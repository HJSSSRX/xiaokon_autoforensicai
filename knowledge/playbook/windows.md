# Playbook · Windows 磁盘镜像

## 0. 预处理

```bash
mmls $IMG                                          # 找分区偏移
OFFSET=<startsector>                               # 通常 2048 或 NTFS 主分区起始
fls -r -o $OFFSET $IMG > $OUT/allfiles.txt         # 全量文件清单
tsk_recover -o $OFFSET -a $IMG $OUT/files/         # 批量导出所有已分配文件
```

Windows 端挂盘符用 Arsenal Image Mounter（只读）。

---

## 1. 系统信息

### 判题模式
- "Build 版本 / 安装时间 / 时区 / 计算机名 / 默认浏览器"

### 看哪里

```
SOFTWARE\Microsoft\Windows NT\CurrentVersion
    ProductName, ReleaseId, CurrentBuild, UBR,
    InstallDate, RegisteredOwner
SYSTEM\ControlSet001\Control\ComputerName\ComputerName  → ComputerName
SYSTEM\ControlSet001\Control\TimeZoneInformation        → TimeZoneKeyName, Bias
SOFTWARE\Clients\StartMenuInternet                      → 默认浏览器

Build 完整版 = CurrentBuild.UBR   e.g. 19045.4780
```

### 命令

```powershell
& RECmd.exe --bn RECmd\BatchExamples\Kroll_Batch.reb -d $SYSTEM_CONFIG --csv $OUT
# 或单独查：
& RECmd.exe -f $CONFIG\SOFTWARE --kn 'Microsoft\Windows NT\CurrentVersion' --csv $OUT
```

---

## 2. 用户 / 登录 / 密码

### 判题模式
- "用户 X 的密码 hash"
- "最近登录成功几次"
- "RDP 登录记录"

### 看哪里

| 信息 | 文件/位置 |
|---|---|
| 本地账户 NTLM/LM hash | `SAM` + `SYSTEM` hive → `impacket-secretsdump LOCAL -system SYSTEM -sam SAM` |
| 域缓存哈希 (MSCACHEv2) | `SECURITY` + `SYSTEM` → 同命令 |
| 最近登录用户 | `SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*` |
| 登录事件 | `Security.evtx` 事件 ID 4624 (成功)、4625 (失败)、4634 (注销) |
| RDP 登录 | `Microsoft-Windows-TerminalServices-*.evtx` |
| 用户最后登录 | `SAM\Domains\Account\Users\*` (RECmd Kroll_Batch 自动解析) |

### 命令

```powershell
# 1. 提取 hash
impacket-secretsdump -system SYSTEM -sam SAM -security SECURITY LOCAL

# 2. 登录事件
& EvtxECmd.exe -f Security.evtx --csv $OUT --csvf sec.csv
# 然后 rg '4624' | 计数
```

---

## 3. 程序执行痕迹

### 判题模式
- "XX 程序什么时候运行过"
- "用户打开过哪些文件"
- "U 盘插入过几次 / 序列号"

### 看哪里（执行四件套）

| 工具 | 含义 |
|---|---|
| Prefetch (`C:\Windows\Prefetch\*.pf`) | 最近执行的程序，8 次运行时间 |
| Amcache (`C:\Windows\AppCompat\Programs\Amcache.hve`) | 所有执行过的 exe 记录，含 SHA1 |
| ShimCache (在 SYSTEM hive) | 应用兼容性缓存 |
| UserAssist (NTUSER.DAT) | 用户双击启动的程序计数 |
| SRUM (`C:\Windows\System32\sru\SRUDB.dat`) | 每个应用的网络/资源消耗，按用户按时间 |

### 判题模式 · 近期文件

| 工具 | 含义 |
|---|---|
| Jump List (`AppData\...\AutomaticDestinations\*.automaticDestinations-ms`) | 每个应用的最近打开 |
| LNK (`AppData\...\Recent\*.lnk`) | 最近访问的文件（含原始完整路径、MAC 时间、卷序列号） |
| Office MRU (`HKCU\Software\Microsoft\Office\<ver>\<app>\User MRU\`) | |
| Shell Bag | 浏览过的目录 |

### USB 痕迹

| 信息 | 位置 |
|---|---|
| USB 序列号 | `SYSTEM\ControlSet001\Enum\USBSTOR\*` |
| 首次/最后插入 | `SYSTEM\ControlSet001\Enum\USB\` 子键时间戳 + setupapi.dev.log |
| 盘符映射 | `SOFTWARE\Microsoft\Windows Portable Devices\Devices\` |

### 命令

```powershell
& PECmd.exe -d $PREFETCH --csv $OUT --csvf pf.csv
& AmcacheParser.exe -f Amcache.hve --csv $OUT
& JLECmd.exe -d $RECENT --csv $OUT
& LECmd.exe -d $RECENT --csv $OUT
& SBECmd.exe -d $USERDIR --csv $OUT
& SrumECmd.exe -f SRUDB.dat --csv $OUT
```

---

## 4. 用户活动痕迹

### 判题模式
- "用户搜过什么"
- "用户访问过什么网站"
- "便签里写了什么"

### 看哪里

| 数据 | 位置 |
|---|---|
| Chrome 历史 | `AppData\Local\Google\Chrome\User Data\Default\History` (SQLite) |
| Chrome 登录 | `.../Login Data` (SQLite) — 密码用 DPAPI 加密 |
| Edge 历史 | `AppData\Local\Microsoft\Edge\User Data\Default\History` |
| Firefox | `AppData\Roaming\Mozilla\Firefox\Profiles\*\places.sqlite` |
| Windows 便签 (Sticky Notes) | `AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_*\LocalState\plum.sqlite` |
| Windows 便笺（旧） | `AppData\Roaming\Microsoft\Sticky Notes\StickyNotes.snt` |
| Cortana / 搜索 | `AppData\Local\Packages\...\SearchApp\` |
| 剪贴板历史 | `AppData\Local\Microsoft\Windows\Clipboard\Pins` |

### 命令

```bash
# Chrome 历史示例
sqlite3 History "SELECT url, title, datetime(last_visit_time/1000000-11644473600,'unixepoch') FROM urls ORDER BY last_visit_time DESC LIMIT 50"

# Sticky Notes
sqlite3 plum.sqlite "SELECT Text FROM Note"
```

---

## 5. 邮件

| 客户端 | 存储 |
|---|---|
| Outlook | `AppData\Local\Microsoft\Outlook\*.ost` / `*.pst` |
| Foxmail | `Storage\<account>\` 下 mbox + 附件 |
| Thunderbird | `AppData\Roaming\Thunderbird\Profiles\*\ImapMail\` / `Mail\` |
| 网页邮件 | 仅浏览器缓存 / IndexedDB |

工具：
- `pffexport`（`libpff`）解 ost/pst
- `readpst` 解 pst → mbox

---

## 6. 常见应用

| 应用 | 位置 / 工具 |
|---|---|
| 微信 PC 版 | `Documents\WeChat Files\<wxid>\Msg\*.db`（SQLCipher 加密，密钥在内存） |
| QQ PC 版 | `Documents\Tencent Files\<QQ>\Msg3.0.db`（加密） |
| utools | `AppData\Roaming\uTools\` — 剪贴板历史、插件数据（**常藏密码**） |
| SillyTavern | `<安装目录>\data\default-user\` —— 聊天记录、人物卡、API key |
| neo4j | `<安装目录>\conf\neo4j.conf` + `data\dbms\auth`（首次启动密码 `neo4j/neo4j`） |
| VeraCrypt | 配置 `AppData\Roaming\VeraCrypt\` + 容器文件（需密码挂载） |

---

## 7. 已删除文件恢复

```bash
# TSK 恢复所有（含 unallocated）
tsk_recover -o $OFFSET -a $IMG $OUT/recovered/
# 按 MD5 找
find $OUT/recovered -type f -exec md5sum {} + | grep -i $TARGET_MD5
```

也可用 `photorec` 按文件头雕刻（会丢失原路径，但能恢复 unallocated）。

---

## 8. 仿真（启动成 VM）

人工操作，AI 无法自动化：
- 火眼仿真系统
- FTK Imager + VMware
- `qemu-system-x86_64 -drive file=$IMG,format=raw,readonly=on,snapshot`

当题目涉及"打开某个软件看什么"、"看桌面"、"看壁纸"时，必须走仿真。

---

## 9. 常见坑

- NTFS 删除文件时 `$MFT` 记录保留，但 `$Data` 可能被覆盖 → `icat` 可能出空文件
- Prefetch 在 SSD 上有时被禁用（`EnablePrefetcher=0`）
- Windows 10+ 默认只保留 1024 条 Prefetch
- Shadow Copy（`\\?\Volume{...}`）是额外的历史快照，大镜像里别忘了看
- 时间戳注意：NTFS 存 UTC，但很多字段显示本地时间；evtx 存 UTC
