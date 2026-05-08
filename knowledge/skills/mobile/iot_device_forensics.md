---
tags: [mobile, iot, smart_home, mihome, aqara, tuya, ezviz, dji, homekit, mqtt, mdns, ssdp, ble, methodology]
tools: [sqlite3, tshark, wireshark, plyvel, datcon, realm_studio, exiftool, strings]
category: mobile_forensics
difficulty: medium
source: kb_seed_2026-05-07
verified: false
related: [bluetooth_forensics.md, geolocation_forensics.md, uninstalled_app_recovery.md, anti_forensics_and_misleading.md]
---
# 手机 ↔ 物联网设备取证

> **核心心法**：IoT 设备本身极少能直接取证（嵌入式系统封闭），但**控制它的手机 app 几乎记录了一切**：型号、固件、MAC、本地 IP、deviceId、绑定时间、操作日志、家庭成员。
> **思路**：从 IoT 设备倒过来追，先在手机找它的"控制端"，再决定是否物理拿设备。

## 0. 识别生态（先看手机装了什么）

| 生态 | App 包名 | 设备覆盖 |
|---|---|---|
| **米家** | `com.xiaomi.smarthome` | 小米/红米/Aqara 部分/绿米 |
| **Aqara** | `com.lumiunited.aqarahome` | 网关、传感器、摄像头、门锁 |
| **涂鸦 / Smart Life** | `com.tuya.smart` / `com.tuya.smartlife` | OEM 大头：插座、灯泡、遥控、几千种 |
| **海尔智家** | `com.haier.uhome.uplus` | 海尔家电 |
| **美的美居** | `com.midea.ai.appliances` | 美的家电 |
| **华为智慧生活** | `com.huawei.smarthome` | 华为/荣耀 |
| **Apple Home** | `com.apple.Home` | HomeKit |
| **Google Home** | `com.google.android.apps.chromecast.app` | Nest/Chromecast/Matter |
| **SmartThings** | `com.samsung.android.oneconnect` | 三星 |
| **Amazon Alexa** | `com.amazon.dee.app` | Echo |
| **DJI Fly / Go** | `dji.go.v5` / `dji.go.v4` | 大疆无人机 |
| **海康萤石** | `com.ezviz.ezviz` | 海康摄像头 |
| **TP-Link Tapo** | `com.tplink.iot` | 摄像头/插座 |
| **小天才** | `com.eebbk.weishu` | 儿童手表 |
| **Tesla** | `com.teslamotors.tesla` | 特斯拉 |

90% 国内 IoT 在这十几个 app 里，先看手机有哪个就锁定生态。

---

## 1. 八层数据挖掘清单

### 第 1 层：App 设备绑定数据库 ★★★

每个 IoT app 都有 SQLite/Realm/LevelDB 存设备列表。最关键字段：

| 字段 | 含义 |
|---|---|
| `did` / `device_id` / `mac` | 设备唯一标识 |
| `model` / `product_id` | 型号字符串（如 `lumi.gateway.v3`） |
| `name` / `nickname` | 用户起的别名（"卧室摄像头"） |
| `ip` / `local_ip` | 本地 IP（仅 LAN 模式） |
| `firmware_version` / `fw_ver` | 固件版本 |
| `bind_time` / `created_at` | 绑定时间 ★ 入时间线 |
| `owner_uid` / `home_id` | 所属账号/家庭 |
| `token` / `did_token` | LAN 通信令牌（米家有名） |
| `latitude` / `longitude` | 设备位置（部分支持） |
| `share_with` | 共享给哪些账号 |

**典型路径**：

| App | 数据库 |
|---|---|
| 米家 | `com.xiaomi.smarthome/databases/miio.db` 或 `mihome.db` |
| Aqara | `com.lumiunited.aqarahome/databases/aiot.db` |
| 涂鸦 | `com.tuya.smart/databases/tuyaSmart` (LevelDB) + `tuya_smart.db` |
| Apple Home (iOS) | `~/Library/HomeKit/HomeKitDatabase.realm` 或 `Database.sqlite` |
| Google Home | `com.google.android.apps.chromecast.app/databases/cast_devices.db` |
| 萤石 | `com.ezviz.ezviz/databases/ezDeviceInfo.db` |
| DJI Go | `dji.go.v5/files/quickshot/` + `databases/dji_*.db` |
| Tesla | `com.teslamotors.tesla/files/account/` |

```sql
-- 米家典型查询
SELECT did, name, model, mac, parent_id, owner, ip, token,
       datetime(bind_time, 'unixepoch') AS bound
FROM device;

-- Aqara
SELECT did, name, model, fw_ver, ip, position_id FROM aiot_device;
```

### 第 2 层：网络通信痕迹 ★★★

#### 2.1 流量包
| 协议 | 端口 | 内容 |
|---|---|---|
| **mDNS / Bonjour** | 5353 UDP | 局域网 IoT 自报家门：`_googlecast._tcp`, `_homekit._tcp`, `_miio._udp` |
| **UPnP / SSDP** | 1900 UDP | `M-SEARCH` 响应含设备型号 + 制造商 |
| **MQTT** | 1883/8883 | IoT 主流协议，topic 常含 deviceId |
| **CoAP** | 5683 UDP | 低功耗 IoT |
| **米家 miio** | 54321 UDP | 私有协议 |
| **TP-Link** | 9999 | 私有 |
| **海康** | 8000 | 私有 |

```bash
# Wireshark 显示过滤
mdns
ssdp
mqtt
udp.port == 54321        # 小米 miio
coap

# tshark 一键导设备列表
tshark -r cap.pcap -Y mdns -T fields -e ip.src -e dns.qry.name | sort -u
tshark -r cap.pcap -Y ssdp -T fields -e http.user_agent -e http.server | sort -u
tshark -r cap.pcap -Y mqtt -T fields -e mqtt.topic -e ip.src | sort -u
tshark -r cap.pcap -Y "udp.port == 54321" -x | head
```

#### 2.2 ARP / DHCP / OUI
```bash
# Android
cat /proc/net/arp
ip neigh

# DHCP 租约（路由器侧）
cat /var/lib/misc/dnsmasq.leases

# OUI 反查（前 6 hex）
curl https://api.macvendors.com/AA:BB:CC
# 或 IEEE 官方表 https://standards-oui.ieee.org/oui/oui.txt
```

### 第 3 层：账号 / 云端绑定 ★★★

很多答案在云端：

| App | Account 数据 |
|---|---|
| 米家 | `accounts.xml` + `mihome` Cookie，uid → 米家 web `home.mi.com/app/v2/home/device_list_page` |
| 涂鸦 | `tuya_user.db`（uid, phone, email） |
| 萤石 | `ezviz_account.db` |
| DJI | `dji_account.db` 含 SSO token |

策略：**uid + 短信验证码** → 司法协助调云端 device list / 操作日志。

### 第 4 层：型号 / 固件反查 ★★

公开数据库：
- **米家型号** https://home.miot-spec.com/
- **Tuya** https://developer.tuya.com/
- **OUI** https://standards-oui.ieee.org/oui/oui.txt
- **FCC ID** https://fccid.io（设备外壳上的 FCC ID 给到产品页 + 内部照片）
- 厂商官网 changelog → 版本号能确认时间线

例：
- `lumi.gateway.v3` → 米家网关 v3
- `chuangmi.camera.ipc019` → 米家摄像头
- `cgllc.airmonitor.s1` → 青萍空气检测仪
- `EZVIZ-CS-C6N` → 海康萤石
- `MAVIC_3` → DJI 无人机

### 第 5 层：操作 / 自动化日志 ★★★

| 表 | 含义 |
|---|---|
| `scene_log` / `automation_log` | 场景触发（"我回家时"开灯） |
| `device_event` / `event_log` | 设备状态变化（开/关/移动检测） |
| `cmd_history` | 用户主动控制 |
| `share_log` | 共享给/被共享 |

```sql
SELECT datetime(time/1000,'unixepoch') AS t, did, action, source
FROM device_event ORDER BY t DESC LIMIT 100;
```

案件价值：
- "门锁 14:23 开" + "监控 14:23 录像" + "GPS 14:25 在家" → 嫌疑人在场
- "智能门铃捕获访客" → 视频证据
- "扫地机器人地图" → 室内布局

### 第 6 层：本地媒体（摄像头/门铃/对讲）★★★

| App | 媒体路径 |
|---|---|
| 米家摄像头 | `/sdcard/Android/data/com.xiaomi.smarthome/files/MiHome/` |
| 萤石 | `/sdcard/EzvizDownload/` |
| Tapo | `/sdcard/Tapo/` |
| Aqara 门铃 | `/sdcard/Aqara/` |
| DJI | `/sdcard/DJI/` |

⚠️ 摄像头视频常**不在手机**，而在 microSD（设备插卡）或云端。本地多是缩略图 + 触发截图。

海康/萤石的 SD 卡用专有 FS，不是 FAT，需厂商工具或 ezOpen SDK。

### 第 7 层：BLE / WiFi 配网 ★★

- BLE 配对历史 → 详见 `network/bluetooth_forensics.md`
- 同 WiFi BSSID = 物理同位置 → 详见 `mobile/geolocation_forensics.md`
- **配网时间**（首次连接） = 案件时间锚

### 第 8 层：物理设备（最后手段）

| 设备 | 可取证 |
|---|---|
| 智能摄像头 | microSD 视频、内部 flash 配置（WiFi 密码、绑定账号） |
| 智能门锁 | MCU flash 含开锁记录、指纹/密码哈希 |
| 智能音箱 | flash 含语音历史缓存（Alexa 是大头） |
| 路由器 | DHCP 租约、ARP、syslog |
| 网关 (Hub) | 子设备完整列表 + 通信密钥 |
| 车载 | OBD/CAN 日志、infotainment 主机 |
| 无人机 | TF 卡飞行日志（DJI `.DAT`，DatCon 解析） |
| 可穿戴 | 同步缓存，自带 GPS 历史 |

物理取证手段：
- **UART**：主板 TX/RX/GND，串口出 root shell
- **JTAG / SWD**：MCU 调试接口 dump flash
- **chip-off**：拆 NAND 直读（破坏性）
- **固件提取**：从厂商升级包逆向

---

## 2. 决策树

```
"手机 + IoT 题"
   │
   ├─ Step 1: 看手机装了哪些 IoT app → 锁生态
   │
   ├─ Step 2: 解每个 IoT app 的 device 表
   │     → did/MAC/型号/IP/firmware/owner
   │
   ├─ Step 3: 型号反查 miot-spec/FCC ID/OUI
   │     → 锁厂家 + 设备实物
   │
   ├─ Step 4: 事件日志 → 时间线对齐
   │
   ├─ Step 5: owner uid → 司法协助查云端
   │     → 完整 device list + 远程操作记录
   │
   ├─ Step 6: 流量包 (如有) → mDNS/UPnP/MQTT 自报
   │
   ├─ Step 7: BLE/WiFi 配网历史 → 物理位置
   │
   └─ Step 8: 拿物理设备 → SD 卡 / flash
```

---

## 3. 命令速查

```bash
# 列手机所有 IoT app（先扫包名）
grep -hoE 'name="[^"]+"' /data/system/packages*.xml | grep -E \
  "xiaomi.smarthome|tuya|aqara|ezviz|huawei.smarthome|dji|tplink.iot|teslamotors|smartthings|alexa|chromecast"

# 米家设备列表
sqlite3 com.xiaomi.smarthome/databases/miio.db \
  "SELECT did, name, model, mac, ip, parent_id, owner, token,
          datetime(bind_time,'unixepoch') FROM device"

# Aqara
sqlite3 com.lumiunited.aqarahome/databases/aiot.db \
  "SELECT did, name, model, fw_ver, ip FROM aiot_device"

# 涂鸦 LevelDB
python -m plyvel /path/to/leveldb dump

# OUI 反查
curl https://api.macvendors.com/AA:BB:CC

# pcap 找 IoT
tshark -r cap.pcap -Y mdns -T fields -e dns.qry.name -e ip.src | sort -u
tshark -r cap.pcap -Y ssdp -T fields -e http.user_agent | sort -u
tshark -r cap.pcap -Y mqtt -T fields -e mqtt.topic -e ip.src | sort -u
tshark -r cap.pcap -Y "udp.port == 54321" -T fields -e ip.src -e ip.dst -e udp.payload

# DJI 飞行日志
DatCon flightrecord.dat -o decoded.csv

# Apple Home Realm
realm-studio HomeKitDatabase.realm   # GUI

# Tuya 产品图
curl "https://images.tuyaus.com/smart/product_pic/{product_id}.jpg"

# 萤石设备日志
sqlite3 com.ezviz.ezviz/databases/ezDeviceInfo.db ".tables"
```

---

## 4. 常见坑

- **米家 token 加密**：`miio.db` 里 token 是 AES，key 在 `shared_prefs/`，需联合解
- **Tuya 用 LevelDB 不是 SQLite**：`plyvel` 或 LevelDB CLI 读
- **Apple Home Realm 文件**：要 Realm Studio 或 `realm-cocoa`
- **设备 IP 动态**：DHCP 租约更新会变；本地 db 可能存旧 IP，**用 MAC 才稳**
- **云端日志保留期短**：米家约 3 个月，涂鸦约 30 天，**尽早调取**
- **HomeKit 端到端加密**：iCloud Keychain 锁配对密钥，云端拿不到设备控制权
- **儿童手表**：定位历史强证据，但常 5-15 分钟一个点，分辨率有限
- **车机 (CarPlay/Android Auto)**：连过的车 → `/data/data/com.google.android.projection.gearhead/`
- **企业 IoT (PLC/SCADA)**：协议 Modbus/Profinet，需 OT 取证专门工具
- **Matter / Thread**：跨生态统一协议，多 app 都可能记录同一设备
- **DJI 飞行日志加密**：`/sdcard/DJI/dji.go.v5/FlightRecord/*.txt`，DatCon 能解；服务器端日志最完整
- **海康/萤石 SD 卡专有 FS**：标准 FAT 工具读不到视频
- **Alexa 语音历史**：本地无，**全在 Amazon 云端**，必须司法协助
- **设备转赠/二手**：bind_time 突然变化 = 换主，前后两个账户都要查

---

## 5. 实战证据链示例

```
1. 手机装了米家 app                          （生态锚）
2. miio.db 含设备 did=12345 model=lumi.lock.v1 （设备身份）
3. event_log 显示该锁 2026-05-07 22:30 开启   （动作）
4. 同时段 GPS / WiFi BSSID 在家               （在场证明）
5. 米家云端日志远程操作 IP = 嫌疑人 4G IP     （操作主体）
6. 物理拿到锁，flash 提取记录与云端一致       （设备层印证）
```

任意 4 项匹配 = 强证据；6 项全匹配 = 铁证。

---

## 6. 与其它 KB 联动

| 场景 | 跳哪 |
|---|---|
| BLE 配对/伪装识别 | `network/bluetooth_forensics.md` |
| 手机本身的位置 | `mobile/geolocation_forensics.md` |
| 时间戳格式换算 | `skills/timestamps_reference.md` |
| IoT app 已被卸载 | `mobile/uninstalled_app_recovery.md` |
| 设备数据是否被伪造 | `mobile/anti_forensics_and_misleading.md` |
