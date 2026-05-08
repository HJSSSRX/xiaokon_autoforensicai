# DJI 无人机 / 大疆设备取证（手机侧）

> 取证比赛中"无人机题"几乎都从**飞手手机**入手——手机里安装的 DJI App 同步了飞行日志、地图缓存、媒体文件、账号绑定。机身/遥控器物理取证罕见。
>
> 关联工作区脚本：`f:\电子取证\FIC2026-mobile_work\dji_q10.py`（飞行日志解析示例）。

---

## 1. DJI 生态产品线与对应 App

| 产品线 | 对应 App | 包名 | iOS Bundle ID |
| --- | --- | --- | --- |
| **DJI Fly**（消费级新一代：Mini/Air/Avata/Mavic 3 Classic+） | DJI Fly | `dji.go.v5` | `com.dji.djifly` |
| **DJI Go 4**（老消费级：Mavic 1/2、Phantom 4、Spark） | DJI Go 4 | `dji.go.v4` | `com.dji.go4` |
| **DJI Pilot 2**（行业级：Matrice 300/30、Mavic 3 Enterprise） | DJI Pilot 2 | `dji.pilot2` / `dji.go.v5` | `com.dji.industry.pilot2` |
| **DJI RC**（带屏遥控器，运行 Android） | 内置 DJI Fly / Pilot | 同上 | — |
| **Osmo Action / Osmo Pocket / Mic** | DJI Mimo | `dji.mimo` | `com.dji.djimimo` |
| **Ronin / Avata 2 头显** | DJI Goggles 等 | 各异 | — |
| **DJI Care / 商城** | DJI Store | `com.dji.store` | — |

> **赛场识别**：包名见到 `dji.go.v5` / `dji.go.v4` 即可断定飞手；`dji.pilot2` 多为行业用户（测绘/电力巡检/警用）。

---

## 2. DJI App 沙盒结构（Android）

以 `dji.go.v5`（DJI Fly）为例，关键路径：
```
/data/dji.go.v5/
├── databases/                  # SQLite
│   ├── flightrecord.db         # 飞行记录元数据
│   ├── media.db                # 媒体索引
│   └── cache.db
├── shared_prefs/
│   ├── dji.go.v5_preferences.xml          # 账号 / 飞机 SN / 上次连接
│   ├── DJI_USER_INFO.xml                  # 账号
│   └── DJI_FLIGHT_RECORD.xml
├── files/
│   ├── FlightRecord/                      # ★★★ 关键：飞行日志原始文件
│   │   ├── DJIFLY_20260308_153022_xxx.txt # 部分机型/版本输出文本
│   │   └── DJIFLY_20260308_153022_xxx.DAT # 二进制飞控（多数机型）
│   ├── DJI/dji.go.v5/CACHE_IMAGE/         # 地图缓存
│   ├── flycache/                          # 缓存
│   ├── mc/                                # 飞控固件升级缓存
│   └── log/                               # App 自身日志
└── cache/

# 外置存储（公开 + 媒体）
/sdcard/Android/data/dji.go.v5/files/
├── FlightRecord/                          # 同上，部分机型只在外存
├── REC/                                   # 录制视频
├── DJI Album/                             # 用户保存到相册的（也在系统 DCIM）
└── update_pkg/

/sdcard/DCIM/DJI/                          # 飞机直连下载的照片/视频
/sdcard/DJI/                               # 旧路径
```

iOS（DJI Fly）：
```
~/Documents/FlightRecord/
~/Documents/MEDIA/
~/Library/Preferences/com.dji.djifly.plist
~/Library/Application Support/...
```
- 通过 iTunes 备份只能拿到 Documents + Library/Preferences 文件夹的子集；**FlightRecord 文件夹默认 NoBackup 标记**，需要越狱或 idevice/Sysdiagnose 才稳。

---

## 3. 飞行日志格式

| 类型 | 扩展名 | 说明 | 解析难度 |
| --- | --- | --- | --- |
| **DAT 飞控原始** | `.DAT` | 飞控芯片 SD 卡的二进制黑匣子，**官方加密**，包含全部传感器/电池/GPS/电机数据 | ★★★★ |
| **TXT/CACHE 飞行记录** | `.txt`（含密文段）/ `.bin` | 手机 App 内导出的飞行记录，**含 GPS 轨迹、电池、警告**，部分字段加密 | ★★ |
| **DJIFLY_*.txt** | `.txt` | DJI Fly App 的飞行日志，**部分明文**，可直接 grep | ★ |
| **FlightRecord_xxx** | 内部二进制 | DJI Go 4 旧格式 | ★★ |

> 取证比赛多数用**DJIFLY_*.txt 与 .DAT 都给一份**，能解 .txt 拿到经纬度即可答题。

---

## 4. 解析工具链

### 4.1 工具速查
| 工具 | 输入 | 输出 | 备注 |
| --- | --- | --- | --- |
| **DJI FlightRecordParsingLib**（github.com/dji-sdk） | `.txt`/`.DAT` | CSV/JSON | **官方**库，需 SDK Key（注册申请，1–2 天） |
| **DatCon**（github.com/dgrant) | `.DAT` | CSV | 老牌民间，部分新机型不支持 |
| **CsvView**（github.com/Bashed-pilot/CsvView） | DatCon CSV | 图表 | 可视化 |
| **PhantomHelp**（phantomhelp.com/logviewer/）/ **airdata.com** | `.txt`/`.DAT` 上传 | 在线分析 + 地图 | **赛场最快**，但泄露检材，仅副本/脱敏 |
| **dji-flight-log-decoder**（github.com） | `.txt` | JSON | 轻量纯解析 |
| **DJIrecord**（民间脚本） | `.txt` | JSON | 部分机型 |
| **TXTLogToCSVTool** / **DJI_LOG_VIEWER** | 各种 | 各种 | 民间补丁工具 |

### 4.2 推荐流程（赛场 30 分钟内出经纬度）
```bash
# 1. 提取
adb pull /sdcard/Android/data/dji.go.v5/files/FlightRecord/ .
# 或从手机镜像里 find
find . -path '*FlightRecord*' \( -name '*.txt' -o -name '*.DAT' -o -name 'DJIFLY*' \)

# 2. 优先看 .txt（部分明文）
strings -el DJIFLY_20260308_153022_xxx.txt | head -200
grep -aE 'latitude|longitude|GPS|altitude|home_point' DJIFLY*.txt

# 3. .DAT 走官方解析
git clone https://github.com/dji-sdk/FlightRecordParsingLib
# 或直接 PhantomHelp 上传副本

# 4. 拿到 CSV 后 pandas 批量
python3 -c "
import pandas as pd
df = pd.read_csv('out.csv')
print(df[['OSD.flyTime', 'OSD.latitude', 'OSD.longitude', 'OSD.altitude']].dropna().head())
print('lat range:', df['OSD.latitude'].min(), df['OSD.latitude'].max())
print('lng range:', df['OSD.longitude'].min(), df['OSD.longitude'].max())
"
```

### 4.3 反向地理编码（题问"在哪个县/市/区"）
```python
# 高德 API（需 key）
import requests
def reverse_geo_amap(lat, lng, key):
    r = requests.get('https://restapi.amap.com/v3/geocode/regeo',
        params={'location': f'{lng},{lat}', 'key': key}).json()
    return r['regeocode']['addressComponent']  # {'province','city','district',...}

# 离线方案：reverse_geocoder 库
import reverse_geocoder as rg
print(rg.search((37.7966, 110.3707)))
# [{'lat':...,'lon':...,'name':'Mizhi','admin1':'Shaanxi',...}]
```
**注意**：DJI 经纬度通常是 **WGS-84**；中国境内地图（高德/百度/腾讯）多为 GCJ-02 / BD-09，差几十到几百米。题目要求精确到县时差异可忽略，要精确到道路时需要 `coord_convert` 转换。

```python
# WGS84 → GCJ02
from coord_convert.transform import wgs2gcj
gcj_lat, gcj_lng = wgs2gcj(wgs_lat, wgs_lng)
```

---

## 5. SharedPreferences / 数据库取证关键字段

### 5.1 账号绑定
```
shared_prefs/DJI_USER_INFO.xml
shared_prefs/dji.go.v5_preferences.xml
```
关键字段：
- `user_id` / `dji_user_account` / `email` / `phone` —— 飞手 DJI 账号
- `flycontroller_serial_number` —— 飞机序列号（FC SN）
- `aircraft_serial_number` / `drone_sn`
- `last_login_time` / `last_flight_time`
- `fcc_mode_enabled` —— 是否开了 FCC 模式（提示越境飞行）
- `gear_serial_number` —— 遥控器 SN

### 5.2 飞行历史 db
```sql
-- flightrecord.db（DJI Fly）
SELECT _id, file_name, start_time, duration, distance, max_height,
       max_horizontal_speed, fly_location, aircraft_serial,
       package_lat, package_lng
FROM flight_record
ORDER BY start_time DESC;
```
> `package_lat/lng` 多为起飞点（home point），即"飞手所在位置"，比飞行轨迹中的某一点更稳定。

### 5.3 媒体 db
```sql
-- media.db
SELECT path, file_size, file_time, gps_lat, gps_lng, model_name
FROM media
ORDER BY file_time DESC;
```

---

## 6. DJI 视频/照片元数据取证

DJI 拍摄的 JPG/MP4/DNG 含丰富 EXIF/XMP：
```bash
exiftool DJI_0001.JPG | grep -iE 'latitude|longitude|altitude|model|serial|drone|relative'
# 关键字段：
# GPS Latitude/Longitude/Altitude
# Drone Serial Number / Camera Model Name / Lens Serial
# Relative Altitude（起飞点上方高度）
# Speed X/Y/Z（速度向量）
# Yaw/Pitch/Roll（机身姿态）
```

视频元数据（HEVC/H.264）：
```bash
ffprobe -v quiet -print_format json -show_format -show_streams DJI_0001.MP4
# stream 内 com.dji.* 字段；TAG creation_time 即拍摄时间
mediainfo DJI_0001.MP4
```

> **比赛取证速胜**：相册里直接拿 DJI 照片用 exiftool，不用解 .DAT 也能拿位置 + 飞机 SN。

---

## 7. 比赛真题映射

### 7.1 2026 FIC 初赛 Q10（"在哪个县进行飞行"）
| 步骤 | 命令 / 路径 |
| --- | --- |
| 1. 找飞行日志 | `find sdcard -path '*FlightRecord*'` |
| 2. 看 .txt 直接 grep 经纬度 | `grep -aE 'lat\|lng' DJIFLY*.txt` |
| 3. .DAT 用 FlightRecordParsingLib 解 | 输出 CSV 内 `OSD.latitude/longitude` |
| 4. 反向地理编码 | `reverse_geocoder` 或高德 API |
| 5. 答案 | 例：(37.7966, 110.3707) → 陕西省榆林市米脂县 |

### 7.2 通用 DJI 题型清单
| 题问 | 数据来源 |
| --- | --- |
| 飞机型号 / 序列号 | `flightrecord.db.aircraft_serial` 或照片 EXIF `Drone Serial` |
| 飞手账号（手机号/邮箱） | `shared_prefs/DJI_USER_INFO.xml` |
| 起飞时间 / 落地时间 | `flight_record.start_time` + `duration` |
| 飞行总里程 / 总时长 | `flight_record.distance` `duration` 累加 |
| 飞行轨迹（在哪个县/园区） | .DAT/.txt 解析 + 反向地理编码 |
| 起飞点（home point） | `package_lat/package_lng` 或 .DAT 第一条 GPS |
| 是否越境 / 限飞区飞行 | 经纬度落在禁飞区表（民航局/DJI GEO） |
| 拍摄了哪些素材 | media.db + DCIM/DJI/ |
| 媒体 GPS / 时间 | exiftool |
| 与其他设备同步过 | `last_login_device` / iCloud / DJI Fly Cloud Drive |

---

## 8. 反取证 / 嫌疑人常见手段

1. **删除 FlightRecord 文件**：仍可通过 SQLite 删除恢复 + 扇区残留 + DCIM/DJI 视频反推；
2. **关闭 DJI App 上传**：本地仍留缓存；
3. **改飞机时间**：DJI 飞控时间从 GPS 同步**不可改**；用 GPS 时间反推；
4. **使用第三方 App**（Litchi、DroneLink）：路径 `com.aryuthere.invisible` / `com.dronelink.dji`，飞行日志在各自沙盒；
5. **匿名账号 / 共享账号**：看 SN + 上传时间 + 设备指纹相互印证；
6. **物理摧毁**：飞控 SD 卡 + 手机要分开取证。

---

## 9. 命令速查

```bash
# 提取整个 DJI 沙盒
adb pull /data/dji.go.v5/ . 2>/dev/null
adb pull /sdcard/Android/data/dji.go.v5/ .
adb pull /sdcard/DCIM/DJI/ .

# .DAT 头部识别（看是不是 DJI 飞控日志）
xxd DJIFLY_xxx.DAT | head -2
# 头部多为 "BUILD" / "55 AA" 等

# .txt 关键字
grep -aE 'osd|gps|home|sn|fc_serial' DJIFLY_*.txt | head

# 飞行 db 转 CSV
sqlite3 flightrecord.db -header -csv 'SELECT * FROM flight_record;' > fr.csv

# 媒体 EXIF 批量
exiftool -GPSLatitude -GPSLongitude -CreateDate -DroneSerialNumber \
    -csv -r /sdcard/DCIM/DJI/ > dji_media.csv
```

---

## 10. 关联工作区脚本

`f:\电子取证\FIC2026-mobile_work\dji_q10.py` —— 2026 FIC Q10 飞行轨迹县域定位实例（飞行日志解析 + 反向地理编码）。后续可抽出通用解析模块到 `framework/tools/`。

---

## 11. 与已有 KB 的关系

- `competition_2024_2025_writeups.md` §12 DJI 占位 → **本文是完整版**
- `fic2026_writeup.md` §2.4 DJI 飞行轨迹 → **本文给完整方法论**
- `geolocation_forensics.md`（如有）→ 反向地理编码 + 坐标系转换通用部分
- `popular_apps_forensics.md`（航拍类 App 章节）→ 引用本文
- `quick_reference.md` → 添加 DJI 一行速记

---

## 12. 待补

- DJI **行业级 Pilot 2** 加密日志格式（M30/M300）
- DJI **Cloud Drive / DJI Care 云端** 取证（账号取证 + 法律调取流程）
- DJI **Goggles / Avata 头显**（沙盒/录制取证）
- DJI Mimo（Osmo Pocket / Action）取证差异
- 第三方飞行 App：Litchi、DroneLink、Map Pilot、Pix4D Capture
