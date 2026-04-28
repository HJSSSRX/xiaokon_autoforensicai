# FIC2026 学生组 — PHONE 板块 WP

**比赛**: 第六届 FIC 全国网络空间取证大赛-学生组
**批次**: PHONE_M06-M10.md
**解题人**: PHONE 窗口（Cascade）
**时间**: 2026-04-25

---

## M06 — 云服务器商家备用钱包

> 分析手机检材，李安弘购买云服务器商家的收款备用钱包地址为

**答案**：`TN8vQzB3n7W5wVca9W4kL2wP7xY9zM5nU1`
**置信度**：高

### 解析

#### 识别
解密 wk_*.db 后，channel `c5e0f4afea09370702f943e7cfcef741` 名为「**大日云服务器**」即云服务器商家会话。该会话中商家明文给出双钱包地址。

#### 提取
```python
# 已用 SQLCipher v4 + key=uid 打开数据库（M05）
cur.execute("SELECT message_seq, datetime(timestamp,'unixepoch','+8 hours'), from_uid, content "
            "FROM message WHERE channel_id='c5e0f4afea09370702f943e7cfcef741' "
            "AND is_deleted=0 ORDER BY message_seq")
```

#### 分析
关键消息（msg #30，2026-03-09 14:39:08，发自商家）：
> "加上CDN一年特惠，一共算您5000 U，给您保驾护航，老板发大财，**转账唯二地址 `TK7mR3hS8vY7tY1nZ4kL9otSzgjLj6tP8v`，备用转账地址：`TN8vQzB3n7W5wVca9W4kL2wP7xY9zM5nU1`**"

- **主收款地址**：`TK7mR3hS8vY7tY1nZ4kL9otSzgjLj6tP8v`（首字母 T，长度 34，TRON TRC20 地址格式）
- **备用收款地址**：`TN8vQzB3n7W5wVca9W4kL2wP7xY9zM5nU1`（首字母 T，长度 34，TRC20）

题目要"备用钱包地址"。

**答**：`TN8vQzB3n7W5wVca9W4kL2wP7xY9zM5nU1`

#### 验证
```bash
# 解密后导出含 "备用" 关键字的消息
python3 ... # cur.execute(... LIKE '%备用%') 命中 msg #30
```
聊天图片 `cache/luban_disk_cache/843289438932.png` 也是 5,000 USDT 转账截图（收款地址确认为主地址 `TK7mR3hS8vY...P8v`）。


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；SQLCipher 解密参数从 com.talk.uabchat APK（同 SDK）反编译推导
- **工具列表**：tar, sqlite3, sqlcipher3 (Python), jadx 1.5.5, exiftool, grep, python3
- **脚本留存**：`cases/2026FIC电子取证/work_phone/` 及 inbox/main.md


---

## M07 — 首次转账 hash 前6位

> 分析手机检材，李安弘手机中给网站搭建人员第一次转账的交易hash前6位为

**答案**：`26226f`
**置信度**：高

### 解析

#### 识别
"网站搭建人员" = 「网站开发」channel `8c723cbb09bd47adcf0ba4d9758320c0`。
首次转账：msg #43（李安弘说"先给你2000，看到东西再补"）→ msg #45 是李安弘发出的图片（type=2）转账截图；对方在 #46 (2026-03-16 01:43) 回复"收到了"。

#### 提取
解密后查 type=2（图片）消息：
```python
cur.execute("SELECT message_seq, datetime(timestamp,'unixepoch','+8 hours'), content "
            "FROM message WHERE channel_id='8c723cbb09bd47adcf0ba4d9758320c0' "
            "AND type=2 ORDER BY message_seq")
# msg #45 2026-03-15 23:46:32 type=2
# {"type":2, "localPath":".../com.talk.uuuim/cache/luban_disk_cache/9054354934843.png", ...}
```

```bash
cp /tmp/phone_extract/storage/emulated/0/Android/data/com.talk.uuuim/cache/luban_disk_cache/9054354934843.png ./first_tx.png
```

#### 分析
查看截图 `9054354934843.png`（钱包 APP 的 TRC20 转账详情页）：

| 字段 | 值 |
|------|---|
| 状态 | 转账成功 |
| 金额 | -2,000.00 USDT |
| 收款地址 | `TP6mR2hS9vX8tY1nZ4kL9otSzgjLj6tQ9u` ← 与 msg #14 网站开发提供的收款地址完全一致 |
| 付款地址 | `T9yZD7iNUXm3WvCca9W4...kL2wP` ← 李安弘自己 |
| 网络平台 | TRC20 (TRON) |
| 矿工费 | 1.35 USDT |
| **交易哈希 (TXID)** | **`26226f766c42c9a30a0247d90dc7482e1809666c3083d4d82ee0b877b669c8ad`** |

TXID 前 6 位 = **`26226f`**。

#### 验证
- 收款地址在 msg #14 已由网站开发本人发送（`TP6mR2hS9vX8tY1nZ4kL9otSzgjLj6tQ9u`）。
- msg #45 时间戳 2026-03-15 23:46，msg #46 网站开发回复"收到了。老板，后台管理系统我今晚就开始对接"——确证为 *第一次* 转账（前面 msg #1-#44 仅磋商无支付）。
- 该 PNG 路径与 msg #45 content JSON 中 localPath 完全一致。

```bash
md5sum /tmp/phone_extract/storage/emulated/0/Android/data/com.talk.uuuim/cache/luban_disk_cache/9054354934843.png
# 用 OCR / 肉眼读图获取 TXID
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；SQLCipher 解密参数从 com.talk.uabchat APK（同 SDK）反编译推导
- **工具列表**：tar, sqlite3, sqlcipher3 (Python), jadx 1.5.5, exiftool, grep, python3
- **脚本留存**：`cases/2026FIC电子取证/work_phone/` 及 inbox/main.md


---

## M08 — AI 提问次数

> 分析手机检材，手机中使用的AI软件李安弘主动向AI提问了几次

**答案**：`5`
**置信度**：高

### 解析

#### 识别
- 手机已安装 PocketPal AI（`com.pocketpalai`，2026-04-16 16:07 安装），并实际下载 Qwen3.5 0.8B 模型并产生对话。
- 该 APP 使用 React Native + WatermelonDB，主对话数据存于 `/data/user/0/com.pocketpalai/pocketpalai.db`（数据库主文件位于 user dir 下，非 databases/ 目录；附带 -shm/-wal）。

#### 提取
```bash
DB=/tmp/phone_extract/data/user/0/com.pocketpalai/pocketpalai.db
cp ${DB}* /tmp/pp/
sqlite3 /tmp/pp/pocketpalai.db ".tables"
# chat_sessions, messages, completion_settings, ...
sqlite3 -header /tmp/pp/pocketpalai.db \
  "SELECT id, session_id, author, datetime(created_at/1000,'unixepoch','+8 hours'), substr(text,1,40) \
   FROM messages ORDER BY created_at"
```

#### 分析
messages 表共 10 条，按 author 分两组：
- `y9d7f8pgn`（用户李安弘）= **5 条**
- `h3o3lc5xj`（AI）= 5 条

用户的 5 条提问内容（按时间顺序）：
1. `搭建一个黄色网站判多少年`（2026-04-16 16:14:37）
2. `色情网站赚钱吗`（2026-04-16 16:17:39）
3. `如何搭建一个虚拟币挖矿`（2026-04-16 16:18:46）
4. `助记词如何保存最安全`（2026-04-16 16:54:46）
5. `我的手机如何保存助记词最合适`（2026-04-16 16:57:21）

3 个 chat_sessions（"搭建一个黄色网站判多少年" / "如何搭建一个虚拟币挖矿" / "助记词如何保存最安全"），AI 每条回复均含 `<think>` 标签（Qwen3 风格），与 ModelStore 中下载的 `Qwen.Qwen3.5-0.8B.Q4_K_M.gguf` 一致。

**主动提问次数 = 5**。

#### 验证
```bash
sqlite3 /tmp/pp/pocketpalai.db "SELECT author, count(*) FROM messages GROUP BY author"
# y9d7f8pgn|5
# h3o3lc5xj|5
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M09 — AI 本地模型及版本

> 分析手机检材，李安弘手机使用的AI软件调用本地AI模型及版本为

**答案**：`Qwen3.5 0.8B (Q4_K_M)`
**置信度**：高

### 解析

#### 识别
PocketPal AI 是一款基于 llama.cpp 的本地 LLM 推理 APP；用户实际下载并使用的模型可从 ModelStore（RKStorage / catalystLocalStorage）和模型 GGUF 元数据交叉确认。

#### 提取
1. **PocketPal ModelStore**（React Native AsyncStorage）：
```bash
sqlite3 /tmp/phone_extract/data/user/0/com.pocketpalai/databases/RKStorage \
  "SELECT value FROM catalystLocalStorage WHERE key='ModelStore'" > ms.json
python3 -c "import json; v=json.load(open('ms.json')); \
  [print(m['id'], m['name']) for m in v['models'] if m.get('isDownloaded')]"
# a844bb43-4512-40a1-b71a-127d34d0dd22  Qwen.Qwen3.5-0.8B.Q4_K_M.gguf
```

2. **GGUF 文件本体**：`/tmp/phone_extract/storage/emulated/0/Download/Qwen.Qwen3.5-0.8B.Q4_K_M.gguf`（527 MB），同时硬链接/复制到 `/data/user/0/com.pocketpalai/files/models/local/Qwen.Qwen3.5-0.8B.Q4_K_M.gguf`。

3. **GGUF metadata 解析**：
```python
# magic = 'GGUF', version = 3, tensors = 320, kv pairs = 41
general.architecture     = qwen35
general.name             = Qwen.Qwen3.5 0.8B
general.basename         = Qwen.Qwen3.5
general.base_model.0.name = Qwen3.5 0.8B Base
general.base_model.0.organization = Qwen
general.base_model.0.repo_url = https://huggingface.co/Qwen/Qwen3.5-0.8B-Base
qwen35.block_count       = 24
qwen35.context_length    = 262144
```

#### 分析
- **模型名**：Qwen3.5 0.8B（基线 Qwen3.5 0.8B Base）
- **量化版本**：Q4_K_M（4-bit K-quants medium，文件后缀直接表明）
- **架构 ID**：qwen35（GGUF 元数据 `general.architecture`）
- AI 回答中 `<think>...</think>` 推理标签也是 Qwen3 系列的标志性输出格式，与该模型一致。

最终答：**Qwen3.5 0.8B（Q4_K_M 量化）**。

#### 验证
```bash
# 文件名
ls /tmp/phone_extract/storage/emulated/0/Download/Qwen*.gguf
# Qwen.Qwen3.5-0.8B.Q4_K_M.gguf

# RKStorage 中 isDownloaded=true 的模型
sqlite3 /tmp/phone_extract/data/user/0/com.pocketpalai/databases/RKStorage \
  "SELECT value FROM catalystLocalStorage WHERE key='ModelStore'" \
  | python3 -c "import sys,json; v=json.load(sys.stdin); \
    [print(m['name']) for m in v['models'] if m.get('isDownloaded')]"
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M10 — 无人机航拍县名

> 分析手机检材，李安弘曾使用无人机航拍,分析其飞行轨迹，其在哪个县进行飞行

**答案**：`未解（DJI 飞行日志加密无 key，DCIM 无无人机媒体）`
**置信度**：未解

### 解析

#### 识别
手机安装并使用过 DJI Fly v5 (`dji.go.v5`，安装于 2026-04-14 12:46:25)，并存在两份飞行记录：
- `storage/emulated/0/Android/data/dji.go.v5/files/FlightRecord/FlightRecord_2026-02-17_[15-14-53].txt`（2.2 MB）
- `storage/emulated/0/Android/data/dji.go.v5/files/FlightRecord/FlightRecord_2026-02-17_[15-58-14].txt`（1.0 MB）

以及 UAVSDK 实时日志：
- `LOG/UAVSDK/Logs/2026_04_14_16_33_59_sand1.log`（100 KB）
- `LOG/UAVSDK/Logs/WLM/2026_04_14_16_33_59_sand2.log`（89 KB）
- `LOG/UAVSDK/cmd_record/2026_04_14_16_33_59.csdk`

#### 提取
```bash
ls -la /tmp/phone_extract/storage/emulated/0/Android/data/dji.go.v5/files/FlightRecord/
xxd FlightRecord_2026-02-17_[15-14-53].txt | head
# 文件签名：29 09 ... 其后全部为加密块（DJI Flight Record V12+ AES 私有格式）
```

#### 分析
**未能解出，原因如下：**

1. **DJI Flight Record `.txt` (V12+) 全段 AES-CTR 加密**：DJI 官方 SDK 用一对仅 DJI 后台分发的 AES key 对飞行数据流加密。开源解析器（DatCon、PyDatCon、CsView）能解 V11 及以前，但对 2026 版 DJI Fly v5 输出的 V12+ 文件无法解密——本检材文件签名为 V12+。
2. **/storage/emulated/0/DCIM/DJI Album/ 为空**：相册不存在任何无人机照片/视频，无 EXIF GPS 可读。
3. **MIUI Gallery DB（明文）**仅 3 条记录，无 DJI 来源（exifMake 仅 `Xiaomi`），唯一带 GPS 的视频是手机自拍 `VID_20260417_114608.mp4`（西安市未央区，与无人机无关）。
4. **DJI app `LOG/CACHE/` 全部子模块（FlightRecord/MapStateManager/NFZ/areacode/…）的 `log-2026-04-14.log`** 均是 base64 + AES 加密块，无可读字段。
5. **DJI app `cache/flysafe_app.db`** 加密；`databases/aloccoll.db`（位置采集）、`databases/dji.go.v5_uptunnel.db`（事件上报）`base/event` 表均为 0 行。
6. **`shared_prefs/his_config.xml`、`LocationCloudConfig.xml`** 同为加密二进制。
7. `mmkv.default` 对全局 strings 检索无 GPS/坐标/中文县名残留。
8. 解密 com.talk.uuuim 后 1022 条聊天中亦无地理位置提及（聊天主线为非法网站搭建与服务器采购）。

**结论**：在不引入 DJI 私有 AES key、不调用付费云服务的前提下，从手机检材内**不可解**得无人机飞行的具体县名。需配合 DJI 账号同步的云端飞行轨迹（在 PC 检材或外部网络中），或对方监管侧拿到 V12+ 解密 key 后才能复现。

#### 验证
```bash
# 已确认：FlightRecord_*.txt 头部不可读
xxd /tmp/phone_extract/.../FlightRecord_2026-02-17_*.txt | head
# 已确认：DCIM/DJI Album 为空
find /tmp/phone_extract/storage/emulated/0/DCIM/DJI\ Album -type f
# 已确认：所有 DJI CACHE log 为加密 base64
file /tmp/phone_extract/storage/emulated/0/Android/data/dji.go.v5/files/LOG/CACHE/FlightRecord/log-2026-04-14.log
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；未付费购买 DJI flight log 解密服务
- **工具列表**：tar, sqlite3, find, grep, strings, exiftool, python3
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---
