# iOS 日志体系与分析（取证视角）

> 适用：iOS 系统日志、崩溃日志、行为日志、电源/连接日志、统一日志（Unified Logging）解析。题目特征：见到 `.tracev3`、`Persist`、`Special`、`logarchive`、`unifiedlogs`、`syslog`、`ASL`、`PowerLog_*.PLSQL`、`KnowledgeC.db`、`interactionC.db`、`CurrentPowerlog.PLSQL`、`Analytics`、`AggregateDictionary`、`DiagnosticLogs`、`com.apple.MobileBackup`、`spindump`、`stacks-*`、`*.ips`、`crashreports` 等。

---

## 1. iOS 日志体系总图（先建立心智模型）

iOS 日志可分为 **6 大类**，按取证价值排序：

| 类别 | 代表文件 | 解析难度 | 取证价值 |
| --- | --- | --- | --- |
| **统一日志（Unified Logging）** | `*.tracev3`、`logarchive` | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **行为/知识图谱** | `KnowledgeC.db`、`interactionC.db` | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **电源 / 连接** | `CurrentPowerlog.PLSQL` | ⭐⭐ | ⭐⭐⭐⭐ |
| **诊断 / 分析** | `Analytics-*.json/plist`、`AggregateDictionary` | ⭐⭐⭐ | ⭐⭐⭐ |
| **崩溃 / 故障** | `*.ips`、`*.crash`、`spindump-*` | ⭐⭐ | ⭐⭐⭐ |
| **传统 syslog/ASL（旧）** | `*.asl`、`syslog` | ⭐ | iOS 10 前有用 |

---

## 2. Unified Logging（统一日志，iOS 10+）

### 2.1 什么是 Unified Logging
- Apple 自 iOS 10/macOS Sierra 起的统一日志框架（`os_log` API）。
- 取代 `printf/asl/syslog`，性能极高（环形缓冲 + 二进制 .tracev3）。
- 默认**只在内存**，仅"persist" / "special" 级别落盘。
- 系统/App 任何 `os_log()` 调用都进这套，**取证黄金来源**。

### 2.2 落盘文件结构
设备路径（越狱后）：
```
/private/var/db/diagnostics/
    ├─ Persist/    *.tracev3         # 持久化日志
    ├─ Special/    *.tracev3         # 关键事件（启动、关机、shutdown 原因）
    ├─ Signpost/   *.tracev3         # 性能 signpost
    ├─ HighVolume/ *.tracev3         # 高频低优先级
    ├─ logdata.LiveData.tracev3      # 当前实时缓冲落地
    ├─ timesync/  *.timesync         # 时间同步基准（**解析必需**）
    └─ version.plist
/private/var/db/uuidtext/<XX>/<...>  # 字符串/格式化模板（与 binary 关联，**必须随日志一起取走**）
/private/var/db/diagnostics/Extra/   # 系统快照
```

### 2.3 logarchive 打包
- 业内通用容器：`*.logarchive`（其实是目录），含 `Persist/`、`Special/`、`Signpost/`、`timesync/`、`uuidtext/`、`Info.plist`。
- iTunes 备份**不含** Unified Logging（只有越狱/物理提取/sysdiagnose 才能拿到）。
- **sysdiagnose**：iOS 自带诊断 bundle，可手动触发：
  - 同时按 **音量+ + 音量− + 电源**（约 1.5 秒），iPhone 会震动。
  - 几分钟后在 设置 → 隐私 → 分析与改进 → 分析数据 看到 `sysdiagnose_<日期>_<UUID>.tar.gz`，可同步到 iTunes 然后从 PC `Library/Logs/CrashReporter/MobileDevice/` 取出。
  - 内含 `system_logs.logarchive`、Powerlog、KnowledgeC、各类配置 plist 等——**取证神器**。

### 2.4 解析工具
| 工具 | 平台 | 命令 |
| --- | --- | --- |
| **macOS `log` 命令** | macOS | `log show --archive system_logs.logarchive --info --debug` |
| **`unifiedlogs` (Mandiant macos-UnifiedLogs)** | 跨平台 Rust | `unifiedlog_parser_json -i Persist -u uuidtext -o out.json` |
| **`Mac_apt`** / **`mac_apt unified_logs` 插件** | Python | 集成到 mac_apt 框架 |
| **`uafr` (Unified Apple Forensic Reader)** | 跨平台 | |

```bash
# macOS 上展开 sysdiagnose 后
log show --archive ./system_logs.logarchive --start "2025-12-01 00:00:00" \
    --predicate 'subsystem == "com.apple.locationd"' --info --debug

# 跨平台：mandiant unifiedlogs
unifiedlog_parser_json --input Persist --uuidtext uuidtext --output logs.json
```

### 2.5 重要 subsystem（取证常筛）
| subsystem | 内容 |
| --- | --- |
| `com.apple.MobileBackup` | iTunes 备份动作 |
| `com.apple.locationd` | 定位授权/请求 |
| `com.apple.bluetoothd` `com.apple.MobileBluetooth` | 蓝牙配对/连接 |
| `com.apple.wifi.manager` `com.apple.wifid` | Wi-Fi 关联/扫描 |
| `com.apple.cellular` `com.apple.commcenter` | 蜂窝/SIM/IMSI |
| `com.apple.aggregated` | 聚合统计 |
| `com.apple.springboard` | UI、解锁、亮屏 |
| `com.apple.SpringBoard.Notifications` | 通知 |
| `com.apple.duetexpertd` | KnowledgeC 写入源 |
| `com.apple.bluetoothd.audioRouting` | 音频路由（外接耳机/AirPods） |
| `com.apple.AppleAccount` | Apple ID 登录 |
| `com.apple.mobile.installation` `com.apple.installd` | App 安装/卸载 |
| `com.apple.SpringBoard` 的 `BSWatchdog` | 强制重启 |
| `com.apple.mobile.lockdown` | 信任配对 |

### 2.6 关键过滤示例
```bash
# Apple ID 登录/退出
log show --archive a.logarchive --predicate 'subsystem CONTAINS "AppleAccount"'

# App 安装/卸载
log show --archive a.logarchive --predicate 'subsystem CONTAINS "installd"' --info --debug

# 解锁/锁屏/亮屏
log show --archive a.logarchive --predicate 'subsystem CONTAINS "SpringBoard"' --info | grep -Ei "unlock|lock|wake"

# 蓝牙配对
log show --archive a.logarchive --predicate 'subsystem CONTAINS "bluetoothd"' --info

# 信任配对（哪台 PC 配过）
log show --archive a.logarchive --predicate 'subsystem CONTAINS "lockdown"' --info
```

### 2.7 timesync 与精确时间
- `.tracev3` 内时间戳是 mach absolute → 必须用同目录 `timesync/` 文件换算 wall clock。
- 工具会自动处理；自写解析时需把 `timesync` 一起喂给。

---

## 3. 行为/知识图谱（CoreDuet 系列）

### 3.1 KnowledgeC.db（**最有用**）
- 路径：HomeDomain → `Library/CoreDuet/Knowledge/knowledgeC.db`
- 表 `ZOBJECT` 是事件流；`ZSTREAMNAME` 决定事件类型。

| ZSTREAMNAME | 含义 |
| --- | --- |
| `/app/usage` | App 前台使用时段（**App 用没用过、用了多久**） |
| `/app/inFocus` | App 当前焦点 |
| `/app/activity` | NSUserActivity（深链/handoff） |
| `/app/intents` | Siri 意图触发 |
| `/display/isBacklit` | 屏幕亮灭（**一段段亮屏区间**） |
| `/device/isLocked` | 锁屏状态 |
| `/device/isPluggedIn` | 充电状态 |
| `/device/batteryPercentage` | 电量 |
| `/device/wifi` | Wi-Fi 关联 |
| `/audio/playback` | 音频播放 |
| `/portrait/poi/_DKLocationMetadataKey` | 位置兴趣点 |
| `/safari/history` | Safari 浏览（CoreDuet 同步） |
| `/inferred/calendar` | 推断的日历事件 |
| `/contacts/last_share` | 最近联系人共享 |

#### 关键 SQL
```sql
-- 全量事件
SELECT ZSTREAMNAME,
       ZVALUESTRING, ZVALUEINTEGER, ZVALUEDOUBLE,
       datetime(ZSTARTDATE+978307200,'unixepoch','localtime') AS start,
       datetime(ZENDDATE+978307200,'unixepoch','localtime') AS end
FROM ZOBJECT
ORDER BY ZSTARTDATE DESC
LIMIT 200;

-- 屏幕开/关时间线
SELECT datetime(ZSTARTDATE+978307200,'unixepoch','localtime') AS on_at,
       datetime(ZENDDATE+978307200,'unixepoch','localtime') AS off_at,
       (ZENDDATE-ZSTARTDATE) AS sec
FROM ZOBJECT WHERE ZSTREAMNAME='/display/isBacklit'
ORDER BY ZSTARTDATE DESC;

-- 某 App 累计使用
SELECT ZVALUESTRING AS bundle, SUM(ZENDDATE-ZSTARTDATE) AS total_sec
FROM ZOBJECT WHERE ZSTREAMNAME='/app/usage'
GROUP BY ZVALUESTRING ORDER BY total_sec DESC;

-- 24 小时活动热度
SELECT strftime('%H', datetime(ZSTARTDATE+978307200,'unixepoch','localtime')) AS hr,
       count(*) AS cnt
FROM ZOBJECT WHERE ZSTREAMNAME='/app/usage'
GROUP BY hr ORDER BY hr;
```

### 3.2 InteractionC.db（联系人交互频次）
- HomeDomain → `Library/CoreDuet/People/interactionC.db`
- 表 `ZINTERACTIONS` + `ZCONTACTS` + `ZATTACHMENTS`：每条记录"谁在何时通过什么 App 联系了谁"。
- `ZBUNDLEID` 例：`com.apple.MobileSMS`、`com.apple.mobilephone`、`com.tencent.xin`。
- 含 `ZSENDERPERSONIDLABEL` `ZRECIPIENTSPERSONIDLABEL`、`ZSTARTDATE` `ZENDDATE`。

```sql
SELECT i.ZBUNDLEID,
       datetime(i.ZSTARTDATE+978307200,'unixepoch','localtime') AS t,
       i.ZSENDERDISPLAYNAME, i.ZSENDERIDENTIFIER,
       i.ZTARGETIDENTIFIER, i.ZDIRECTION, i.ZRECIPIENTCOUNT
FROM ZINTERACTIONS i ORDER BY i.ZSTARTDATE DESC;
```
> ZDIRECTION：0 incoming，1 outgoing。

### 3.3 SignificantLocations
- HomeDomain → `Library/Caches/com.apple.routined/Cache.sqlite` / `Local.sqlite`
- iOS 频繁地点：家、公司、常去地点（系统聚类后的**高质量位置**）。
- 表 `ZRTLEARNEDLOCATIONOFINTERESTMO`、`ZRTLEARNEDVISITMO`。

```sql
SELECT ZLATITUDE, ZLONGITUDE, ZHORIZONTALUNCERTAINTY,
       datetime(ZENTRYDATE+978307200,'unixepoch','localtime') AS arrive,
       datetime(ZEXITDATE+978307200,'unixepoch','localtime') AS leave
FROM ZRTLEARNEDVISITMO ORDER BY ZENTRYDATE DESC;
```

### 3.4 cache_encryptedB.db（位置原始缓存）
- HomeDomain → `Library/Caches/locationd/`
- iOS 8+ AES 加密，key 在 SEP；越狱可用 `locationd` 私钥解。
- 一般用 iLEAPP / 商业工具自动处理，手工不易。

---

## 4. PowerLog（电源/活动黑匣子，**极高频考点**）

### 4.1 路径
- HomeDomain → `Library/BatteryLife/Archives/`：每天压一个 `powerlog_YYYY-MM-DD_*.PLSQL.gz`
- HomeDomain → `Library/BatteryLife/CurrentPowerlog.PLSQL`：当前未归档的实时库
- 是标准 SQLite，可直接打开。

### 4.2 关键表（部分，按 iOS 版本略有差异）
| 表 | 内容 |
| --- | --- |
| `PLApplicationAgent_EventNone_Bundle` | App 启动/进入后台/退出（**App 何时被打开**） |
| `PLApplicationAgent_EventForward_Application` | App 前台事件 |
| `PLAppTimeService_Aggregate_AppRunTime` | App 累计运行时间聚合 |
| `PLBatteryAgent_EventBackward_Battery` | 电量曲线 |
| `PLBatteryAgent_EventForward_Charge` | 充电状态变化（**何时插拔充电器**） |
| `PLLocationAgent_EventForward_*` | 位置代理事件 |
| `PLBluetoothAgent_EventForward_BluetoothDevice` | 蓝牙设备连接 |
| `PLCameraAgent_EventForward_*` | 相机使用 |
| `PLAudioAgent_EventBackward_AudioRoute` | 音频路由切换（耳机/外放/AirPods） |
| `PLDisplayAgent_EventBackward_DisplayState` | 屏幕亮灭（与 KnowledgeC 互补） |
| `PLLocationAgent_EventForward_TimeZone` | 时区变化（**跨城市移动证据**） |
| `PLLocationAgent_EventForward_GPS` | GPS 定位事件 |
| `PLBatteryAgent_EventBackward_BatteryHealth` | 电池健康 |

### 4.3 关键 SQL
```sql
-- App 何时被打开
SELECT BundleID,
       datetime(timestamp,'unixepoch','localtime') AS t,
       Status, ParentBundleID
FROM PLApplicationAgent_EventNone_Bundle
ORDER BY timestamp DESC LIMIT 200;

-- 何时插上充电器
SELECT datetime(timestamp,'unixepoch','localtime') AS t,
       IsCharging, IsExternalConnected, Level
FROM PLBatteryAgent_EventForward_Charge ORDER BY timestamp DESC;

-- 蓝牙连接（车载/耳机识别）
SELECT datetime(timestamp,'unixepoch','localtime') AS t,
       Address, Name, ProductID, VendorID, Connected
FROM PLBluetoothAgent_EventForward_BluetoothDevice ORDER BY timestamp DESC;

-- 时区变化（跨地点）
SELECT datetime(timestamp,'unixepoch','localtime') AS t, TimeZone
FROM PLLocationAgent_EventForward_TimeZone ORDER BY timestamp DESC;
```

> **PowerLog 取证三大用法**：
> 1. **App 使用时间反推**（即便 App 已删，仍可在 `PLApplicationAgent_EventNone_Bundle` 留痕）。
> 2. **充电插拔证明设备所在地**（家/车/办公室）。
> 3. **蓝牙连接车载** → 证明嫌疑人在某车上的具体时间窗口。

---

## 5. 诊断 / 分析数据

### 5.1 Analytics
- HomeDomain → `Library/Caches/com.apple.appstored/Analytics/`
- HomeDomain → `Library/Logs/CrashReporter/Analytics/Analytics-YYYY-MM-DD-*.zip / .ips`
- iOS 13+：`/private/var/mobile/Library/Analytics/Daily.tar`
- 内含 daily 行为聚合（App 启动次数、网络、广播、位置请求次数等）。

### 5.2 AggregateDictionary
- 按天聚合的计数器：`/private/var/Library/Aggregates/AggregateDictionary.SQL`（越狱可见）
- iOS 内部统计；含一些 App 启用次数、Siri 调用、键盘统计。

### 5.3 OSAnalytics / MetricKit
- App 自身上报的 metric/diagnostic（含异常崩溃、卡顿、能耗统计）。

---

## 6. 崩溃报告（Crash Reports）

### 6.1 路径
- HomeDomain → `Library/Logs/CrashReporter/`
- 越狱：`/private/var/mobile/Library/Logs/CrashReporter/`
- 同步到 PC：iTunes 同步后落于
  - macOS：`~/Library/Logs/CrashReporter/MobileDevice/<DeviceName>/`
  - Win：`%APPDATA%\Apple Computer\Logs\CrashReporter\MobileDevice\<DeviceName>\`

### 6.2 文件类型
| 类型 | 说明 |
| --- | --- |
| `*.ips`（JSON 格式，iOS 14+） | 单次崩溃，含 App、bundle id、版本、线程栈、寄存器、设备信息、时间 |
| `*.crash`（旧文本格式，iOS 13 前） | 同上但纯文本 |
| `JetsamEvent-*.ips` | 内存压力下被系统杀掉的进程列表（**重要：可证明某 App 当时在运行**） |
| `LowMemory-*.ips` | OOM |
| `spindump-*.ips` | 系统卡顿快照（含进程线程栈、磁盘 I/O） |
| `panic-full-*.ips` | 内核 panic（重启原因） |
| `stacks-*.ips` | 后台耗能调用栈 |

### 6.3 取证用法
- **JetsamEvent** 列出当时所有进程 + bundleid + 内存占用 → 反推"嫌疑人手机当时在跑哪些 App"。
- `spindump-*.ips` 第一行 `Begin time: 2025-12-01 14:20:33 +0800` 直接是绝对时间戳。
- `panic-full-*` 含 `OS Version`、`Boot Reason`（panic 类型）、`Panicked Task`，可证明设备何时重启。

```bash
# 把 .ips（iOS 14+ JSON 格式）格式化
python -c "import json,sys;d=open(sys.argv[1]).read();h,b=d.split('\n',1);print(json.dumps(json.loads(b),indent=2,ensure_ascii=False))" file.ips
```

---

## 7. 网络 / 配置类日志（plist 系列）

| 文件（HomeDomain 起） | 内容 |
| --- | --- |
| `Library/Preferences/SystemConfiguration/com.apple.wifi.plist` (iOS≤13) | Wi-Fi 历史 SSID/BSSID/最后连接时间/位置 |
| `Library/Preferences/SystemConfiguration/com.apple.wifi.known-networks.plist` (iOS 14+) | 已知 Wi-Fi（key 为 `wifi.network.ssid.<SSID>`） |
| `Library/Preferences/SystemConfiguration/preferences.plist` | 网络配置/服务集 |
| `Library/Preferences/com.apple.mobiletimer.plist` | 闹钟 |
| `Library/Preferences/com.apple.MobileSMS.plist` | iMessage 配置 |
| `Library/Preferences/com.apple.mobilephone.plist` | 电话设置 |
| `Library/Preferences/com.apple.mobile.lockdown.plist` | 配对（含 EscrowBag） |
| `Library/Preferences/com.apple.MobileBluetooth.devices.plist` | 蓝牙已配对设备（也可在 `/private/var/mobile/Library/Preferences/com.apple.MobileBluetooth.ledevices.plist`） |
| `RootDomain/Library/Lockdown/data_ark.plist` | 设备激活信息（**很多设备身份字段一站式**） |
| `Library/Preferences/com.apple.MobileMeAccounts.plist` | iCloud 账户 + DSID |
| `Library/Preferences/com.apple.celestial.plist` | 媒体/Now Playing 配置 |
| `Library/Preferences/com.apple.routined.plist` | Significant Locations 开关 |
| `Library/Preferences/com.apple.AppStore.plist` | App Store 登录 |

### 7.1 Wi-Fi 历史精读
```bash
plutil -p "Library/Preferences/SystemConfiguration/com.apple.wifi.known-networks.plist" \
  | grep -E '(ssid|BSSID|lastJoined|lastAutoJoined|JoinedBySSIDInfo|hidden)'
```
- `lastJoined`、`lastAutoJoined`：日期对象（plist Date = Mac Abs）。
- `BSSID` 是 **AP MAC 地址** → 配合 wigle.net 反查 AP 物理位置。

### 7.2 蓝牙已配对
```bash
plutil -p Library/Preferences/com.apple.MobileBluetooth.ledevices.plist
plutil -p Library/Preferences/com.apple.MobileBluetooth.devices.plist
```
含 `Name`、`DeviceAddress`、`LastSeenTime`、`Manufacturer`、`Type`、`PrimaryDeviceType`。

---

## 8. 旧版 syslog / ASL（iOS 9 及更早）

- 路径：`/private/var/log/asl/*.asl`
- 工具：`syslog -f file.asl`、`aslmanager`、`Mac_apt asl`。
- iOS 10+ 已转 unified logging，asl 极少。

---

## 9. 日志取证流程（实战题模板）

### 9.1 拿到检材后
```
1. 看是不是 sysdiagnose（.tar.gz 含 logarchive + powerlog + KnowledgeC + 各 plist）→ 解包
2. 否则：
   - iTunes 备份：拿不到 logarchive，但 KnowledgeC、PowerLog、CrashReports、各 plist 都有
   - 越狱物理：全部都有
3. 用 iLEAPP 一把梭，得 HTML 报告 + tsv 时间线
4. 针对题目精读：
   - "用过哪些 App / 多久" → KnowledgeC + PowerLog
   - "几点几分在哪儿" → SignificantLocations + Photos GPS + KnowledgeC location
   - "和谁联系" → InteractionC + sms.db + CallHistory
   - "App 安装/卸载时间" → installd Unified Logs + PowerLog + applicationState
   - "什么时候连过 X 设备/Wi-Fi" → 蓝牙 plist + Wi-Fi plist + Unified Logs
   - "充电习惯/在场证明" → PowerLog Charge
   - "重启过几次" → panic-full / shutdown 原因（Special tracev3）
```

### 9.2 时间线编排
- 把所有时间戳列统一换成 ISO8601（**同一时区**）。
- 多源比对：KnowledgeC `/app/usage` ↔ PowerLog ApplicationAgent ↔ InteractionC ↔ sms.db ↔ Photos.sqlite。
- 工具：iLEAPP 自动产生 timeline.csv；或自写 pandas 合并。

---

## 10. 比赛常见题与解法

| 题 | 来源 |
| --- | --- |
| 嫌疑人 X 月 X 日是否使用过某 App，使用了多久 | KnowledgeC `/app/usage` 或 PowerLog `PLAppTimeService` |
| 设备何时被解锁 / 屏幕何时亮起 | KnowledgeC `/display/isBacklit`、`/device/isLocked` |
| 设备何时充过电、连了什么 USB 配件 | PowerLog Charge + Accessory plist + Unified Logs |
| 嫌疑人哪天去过某地 | SignificantLocations + Photos GPS + KnowledgeC location |
| 嫌疑人何时和某人通过什么方式联系 | InteractionC（通用）+ sms.db / CallHistory（细节）|
| 设备何时被信任过哪台 PC | `com.apple.mobile.lockdown` Unified Logs + Lockdown 目录配对记录 |
| 何时安装/卸载了某 App | installd Unified Logs + applicationState.db + PowerLog ApplicationAgent |
| 设备出现过几次重启 / 强制关机 | panic-full / Special tracev3 / PowerLog Boot |
| 何时与某蓝牙设备配对 / 连接 | `com.apple.MobileBluetooth.*.plist` + bluetoothd Unified Logs + PowerLog Bluetooth |
| 何时切换过时区 / 出过境 | PowerLog `PLLocationAgent_EventForward_TimeZone` + Significant Locations |
| 嫌疑人是否使用过 VPN / 翻墙 | Unified Logs `com.apple.networkextension` + 配置 plist `Library/Preferences/com.apple.NetworkExtension.plist` |
| Apple ID 何时登录 / 切换 | Unified Logs `AppleAccount` + `accounts3.sqlite` 时间字段 |

---

## 11. 命令速查

```bash
# sysdiagnose 解包
tar xzf sysdiagnose_2025.12.01_*.tar.gz
ls sysdiagnose_*/ | head

# logarchive（macOS）
log show --archive sysdiagnose_*/system_logs.logarchive --info --debug \
    --predicate 'subsystem == "com.apple.locationd"' > location.log

# 跨平台解 tracev3
unifiedlog_parser_json -i Persist -u uuidtext -o all.json
unifiedlog_parser_json -i Special -u uuidtext -o special.json   # 启动/关机原因

# KnowledgeC App 使用 Top
sqlite3 knowledgeC.db <<EOF
SELECT ZVALUESTRING, SUM(ZENDDATE-ZSTARTDATE) sec FROM ZOBJECT
WHERE ZSTREAMNAME='/app/usage' GROUP BY ZVALUESTRING ORDER BY sec DESC;
EOF

# PowerLog 充电时间线
sqlite3 CurrentPowerlog.PLSQL "SELECT datetime(timestamp,'unixepoch','localtime'),IsCharging,Level FROM PLBatteryAgent_EventForward_Charge ORDER BY timestamp DESC LIMIT 200;"

# Significant Locations
sqlite3 Cache.sqlite "SELECT ZLATITUDE,ZLONGITUDE,datetime(ZENTRYDATE+978307200,'unixepoch','localtime'),datetime(ZEXITDATE+978307200,'unixepoch','localtime') FROM ZRTLEARNEDVISITMO ORDER BY ZENTRYDATE DESC LIMIT 50;"

# 蓝牙已配对
plutil -p Library/Preferences/com.apple.MobileBluetooth.devices.plist | grep -E "Name|Address|LastSeen"
plutil -p Library/Preferences/com.apple.MobileBluetooth.ledevices.plist

# Wi-Fi 历史
plutil -p Library/Preferences/SystemConfiguration/com.apple.wifi.known-networks.plist

# 崩溃日志（iOS 14+ ips JSON）
python -c "import json,sys;d=open(sys.argv[1]).read();h,b=d.split('\n',1);print(json.dumps(json.loads(b),indent=2,ensure_ascii=False))" Jetsam-*.ips | head -80

# iLEAPP 一把梭（iTunes 备份/物理目录都行）
ileapp -t fs -i /path/to/extracted_fs -o /tmp/out
ileapp -p ?           # 列模块
ileapp -t itunes -i /Backup/<UDID> -o /tmp/out
```

---

## 12. 常见坑

1. **iTunes 备份没有 `tracev3`**：Unified Logging 不在备份里，必须 sysdiagnose 或越狱物理。
2. **`tracev3` 解析必须带 `uuidtext` 和 `timesync`**：缺一即变成天书。
3. **KnowledgeC 时间是 Mac Abs（秒）**，PowerLog 时间是 **Unix 秒**，不要混用。
4. **InteractionC 不存消息内容**：只存"谁与谁交互的元数据"；要内容去 sms.db。
5. **PowerLog 滚动归档**：`Archives/` 里只保留近 30 天，更早的没了；要尽快取。
6. **蓝牙 LE 设备在 ledevices.plist，经典蓝牙在 devices.plist**：两个都要看。
7. **Wi-Fi 历史 iOS 14+ 在 known-networks.plist**，老脚本只读 `com.apple.wifi.plist` 会漏。
8. **JetsamEvent 不只是崩溃**：是被系统主动 kill，**反而证明 App 当时在运行/占内存**。
9. **CrashReporter 内 `*.ips` iOS 14+ 是两段**：第一行 JSON 头 + 第二段 JSON 体，别整文件 `json.loads`。
10. **Significant Locations 默认开**，但有些用户关了 → `Cache.sqlite` 可能为空，不能由空判定"没去过"。
11. **时区切换日志 vs 实际所在地**：飞行模式下时区可能不更新，要交叉 PowerLog GPS、Photos GPS。
12. **多用户/多设备 Apple ID**：日志中可能含两个 Apple ID 切换，需按时间分段。
13. **logarchive 直接被 macOS `log` 显示是按时区格式化**：导出时记得 `--timezone UTC` 保统一。
14. **sysdiagnose 包大且含敏感**：里面可能有蓝牙地址、Wi-Fi BSSID、用户位置等，作证据保管要 hash + 加密。

---

## 13. 交叉链接
- `ios_forensics.md`：iOS 取证总览
- `ios_fundamentals.md`：iOS 文件系统/安全机制/备份/越狱
- `ios_app_parsing.md`：iOS App 数据解析
- `geolocation_forensics.md`：位置取证（Significant Locations + Photos GPS + Wi-Fi）
- `network/bluetooth_forensics.md`：蓝牙取证（与 iOS 蓝牙日志互补）
- `timestamps_reference.md`：Mac Abs / Unix 换算
- `log_and_data_parsing.md`：通用日志/数据解析
