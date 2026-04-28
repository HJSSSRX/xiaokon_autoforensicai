# Playbook · 安卓取证

## 0. 检材形态识别

| 形态 | 判断 | 预处理 |
|---|---|---|
| 火眼导出 zip | 解压后有 `/data/data/` 和 `/sdcard/` 目录树 | `7z x` 到 `raw/` |
| `adb backup .ab` | 头部有 `ANDROID BACKUP` 字节串 | `java -jar abe.jar unpack x.ab x.tar` → `tar xf` |
| 物理镜像 `.img/.raw` | `file` 显示 ext4 / f2fs | WSL 下 `mount -o ro,loop` |
| 厂商备份（MIUI/华为） | `.bak` 或自研格式 | 对应厂商工具，或火眼解 |

预处理后统一目录 `$RAW`，之后所有操作基于 `$RAW`。

---

## 1. 基础信息类题

### 判题模式
- "手机型号 / IMEI / 系统版本 / 序列号"
- "Wi-Fi 曾连接的 SSID"
- "最近一次连接时间"
- "电池事件"

### 看哪里

| 问题 | 文件 |
|---|---|
| 型号、品牌 | `/system/build.prop` 或 `/vendor/build.prop` 里 `ro.product.model` / `ro.product.brand` |
| IMEI | `telephony.db` (`/data/data/com.android.providers.telephony/databases/`)，或 `/data/system/users/0/settings_ssaid.xml` |
| 系统版本 | `build.prop` 的 `ro.build.version.release` / `ro.build.display.id` |
| Wi-Fi | `/data/misc/wifi/WifiConfigStore.xml`（新版）或 `wpa_supplicant.conf`（旧版） |
| 电池 | `/data/system/batterystats.bin` + `dumpsys batterystats` 残留 |

### 命令

```bash
aleapp -t fs -i $RAW -o $OUT/aleapp    # 90% 的基础题看 HTML 报告
grep -E 'ro\.product\.(model|brand)|ro\.build\.version' $RAW/system/build.prop
```

---

## 2. 通讯类（微信 / QQ / 短信 / 通话 / 通讯录）

### 判题模式
- "XX 给 YY 发了什么消息 / 图片"
- "微信 wxid / QQ 号"
- "最后一次通话 / 短信时间"

### 看哪里

| 应用 | 数据库位置 |
|---|---|
| 短信 | `/data/data/com.android.providers.telephony/databases/mmssms.db` |
| 通话 | `/data/data/com.android.providers.contacts/databases/calllog.db` 或 `contacts2.db` |
| 通讯录 | `contacts2.db` |
| 微信 | `/data/data/com.tencent.mm/MicroMsg/<uinhash>/EnMicroMsg.db`（加密） + `.../FTS5IndexMicroMsg.db` |
| QQ | `/data/data/com.tencent.mobileqq/databases/<QQ号>.db` |
| 微信 wxid | `/data/data/com.tencent.mm/shared_prefs/auth_info_key_prefs.xml`（`_auth_uin` / `_auth_update_time` / `default_uin`） |

### 微信数据库解密

密钥 = `MD5(IMEI + uin).hexdigest()[:7]`（注意大小写、注意 `uin` 不是 QQ 号）

```python
import hashlib
key = hashlib.md5(f"{imei}{uin}".encode()).hexdigest()[:7]
# sqlcipher 或 pysqlcipher3:
# PRAGMA key = 'xxxxxxx';
# PRAGMA cipher_use_hmac = off;   # 旧版微信
# PRAGMA kdf_iter = 4000;         # 旧版
# PRAGMA cipher_page_size = 1024;
```

**iOS 微信**用完全不同机制，通常 backup 工具会解好。

### 命令

```bash
# 微信消息全导出
sqlcipher decrypted.db <<'SQL'
SELECT talker, content, createTime FROM message ORDER BY createTime;
SQL
```

---

## 3. APK 反编译（看 app 逻辑）

### 判题模式
- "这个 app 加密/通信使用什么算法"
- "硬编码的盐 / 密钥 / URL / IP"
- "app 包名 / 版本"
- "app 有多少个 SO 库 / 多少个 Activity"

### 流程

```bash
jadx --output-dir $OUT/jadx $APK         # 反编译 Java（首选）
apktool d $APK -o $OUT/apktool           # smali + 资源（看 AndroidManifest.xml）
unzip -l $APK                            # 快速列内容
unzip -p $APK classes.dex | xxd | head   # dex 头
```

### 看哪里（反编译后）

| 问题 | 文件 |
|---|---|
| 包名 / 主 Activity / 权限 | `apktool/AndroidManifest.xml` |
| 版本号 | `apktool/apktool.yml` |
| 字符串常量（URL/密钥/盐） | `jadx/resources/.../strings.xml` + `rg` 搜源码 |
| SO 库数量 | `ls apktool/lib/<arch>/*.so` |
| 加固识别 | 看 `lib/` 下有无 `libSecShell.so`（乐固）、`libjiagu.so`（360）、`libexec.so`（爱加密） |

### AI 读源码的高效方法

```bash
# 直接 grep 敏感字符串
rg -i 'aes|des|rsa|base64|password|token|secret|key|salt|http|https|api' $OUT/jadx/sources
```

---

## 4. SO 原生库分析

### 判题模式
- "加密算法在 SO 里，找出密钥"
- "SO 中有多少个导出函数"

### 工具
- `objdump -T libfoo.so` / `readelf -a` —— 导出符号
- Ghidra headless —— 反编译到伪 C
- frida + 真机 —— 动态 hook（最有效但门槛高）

### 命令

```bash
# 静态：列出导出函数
arm-linux-gnueabihf-readelf -a libfoo.so | grep 'FUNC.*GLOBAL'

# Ghidra headless 反编译
$GHIDRA/support/analyzeHeadless $OUT ProjName -import libfoo.so \
    -postScript PostDecompile.java -scriptPath $SCRIPTS -deleteProject
```

**AI 在 SO 题上胜率有限**，通常需要人类 + frida 动态看关键函数的返回值。

---

## 5. 图片 / 文件关联题

### 判题模式
- "去过哪里拍照（GPS）"
- "图片里藏了什么 flag"
- "什么时候拍的"

### 命令

```bash
# EXIF 批量
exiftool -r -csv $RAW/sdcard/DCIM > $OUT/exif.csv

# 隐写检测
binwalk -e image.jpg
zsteg image.png                  # PNG LSB
stegsolve                         # GUI 多通道查看
steghide info image.jpg

# 搜 flag 字符串
strings image.jpg | rg -i 'flag|ctf|\{'
```

---

## 6. 浏览器 / 地图 / 其他常见 app

| app | 数据 |
|---|---|
| Chrome/系统浏览器 | `/data/data/com.android.chrome/app_chrome/Default/History`（SQLite） |
| 高德/百度地图 | `/data/data/com.autonavi.minimap/databases/`、`com.baidu.BaiduMap/files/` |
| 支付宝 | `/data/data/com.eg.android.AlipayGphone/databases/`（多数加密，火眼可能解） |
| 抖音 | `/data/data/com.ss.android.ugc.aweme/` |

**套路**：ALEAPP 覆盖常见 100+ app。先看 ALEAPP 报告有没有对应模块，没有再手动挖 SQLite。

---

## 7. 常见坑

- 微信 uin 不是 QQ 号，是微信内部 ID，在 `auth_info_key_prefs.xml` 或 `CompatibleInfo.cfg`
- IMEI 可能有多个（双卡），答题时注意取哪个
- 某些加固过的 app 静态看不到字符串，必须脱壳后再 jadx
- ALEAPP 不支持国产 app（微信/QQ/支付宝），这些要手动
