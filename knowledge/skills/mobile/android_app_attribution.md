# 安卓 APK 溯源与同源性分析

> 适用：恶意/灰产/赌博/诈骗 APK 取证。题目特征：见到"找出该 App 的来源 / 同一作者 / 与已知样本是否同源 / 设备安装历史 / 嫌疑人最常访问哪些 App / 域名归属 / 签名指纹"等。
>
> 与 `android_packer_unpacker.md`（脱壳）+ `apk_crypto_analysis.md`（算法逆向）配合：本篇从"代码/资源/网络/签名"四个维度溯源 + 设备端"安装历史/使用频度"两个维度落实。

---

## 1. 溯源思路框架

```
APK 溯源问题 = 双向证据链
┌────────────────── 样本侧 ──────────────────┐
│ 签名指纹      域名/IP       代码同源        │
│ 资源同源      字符串聚类    打包工具/壳     │
│ 渠道 ID       构建指纹      VT/沙箱关联      │
└────────────────────────────────────────────┘
                     ↕
┌────────────────── 设备侧 ──────────────────┐
│ 安装时间      安装来源       使用频度        │
│ 网络访问      系统日志       Package Logs    │
│ 文件落地      多账号聚合     云备份历史      │
└────────────────────────────────────────────┘
```
- **样本侧**：从 APK 文件本身找出"它来自谁、与谁同源"。
- **设备侧**：从手机里找"它何时来的、被怎么用、与什么联系"。

---

## 2. APK 签名指纹（**最强的同源指标**）

### 2.1 签名机制
| 版本 | 算法 | 落点 | 引入 |
| --- | --- | --- | --- |
| **v1（JAR Signing）** | RSA/DSA/ECDSA + SHA1/SHA256 | `META-INF/CERT.RSA`+`MANIFEST.MF`+`CERT.SF` | Android 1.0+ |
| **v2（APK Sig Scheme v2）** | 同上 | APK 文件结尾 ZIP Central Dir 前的"Signing Block" | Android 7.0+ |
| **v3（APK Sig Scheme v3）** | 支持密钥轮换 | 同位置，新 block | Android 9+ |
| **v4** | 流式增量签名 | 单独 `.apk.idsig` 文件 | Android 11+ |

> 取证关注：**签名证书的公钥指纹**（SHA1/SHA256）。**公钥永远不可伪造改变**（除非作者主动换密钥）。

### 2.2 提取签名
```bash
# Java keytool（v1 JAR 签名）
keytool -printcert -jarfile app.apk

# apksigner（v1/v2/v3 都支持，**首选**）
apksigner verify --print-certs app.apk

# 输出关键行
# Signer #1 certificate DN: CN=Android Debug, O=Android, C=US
# Signer #1 certificate SHA-256 digest: 8a4f...e1
# Signer #1 certificate SHA-1 digest: c0a0...8b
```

### 2.3 解析 CERT.RSA / DER 证书
```bash
# 老 v1 直接看
unzip -p app.apk META-INF/CERT.RSA | openssl pkcs7 -inform DER -print_certs -text

# 关键字段
# Issuer  : CN, O, OU
# Subject : CN, O, OU
# Validity: 起止时间
# Public Key: 模数 + 公钥指纹
# Serial Number: 厂商签发序号
```

### 2.4 同源判定准则
| 一致项 | 同源强度 |
| --- | --- |
| 公钥 SHA-256 指纹 | **极强**（可视为铁证） |
| Subject DN 字段（CN/O/OU/邮箱） | 强（除非作者抄袭别人的 DN） |
| Issuer = Subject（自签名）+ 序列号 | 强 |
| 证书有效期起止时间 | 中（多个样本同一秒签发 → 强） |
| keystore 别名（v1 META-INF 文件名 `XXXXX.RSA`） | 弱（可改，但默认 `CERT.RSA`） |

> **黑产常见**：一个团伙数十/数百 APK 用同一 keystore 签 → 公钥指纹完全一致；这是连接样本族的最强抓手。

### 2.5 已公开的"白单"指纹（避免误归）
- Google Play 官方签名：`38918a453d07199354f8b19af05ec6562ced5788`
- AOSP 平台签名：`27196e386b875e76adf700e7ea84e4c6eee33dfa`
- 各厂商 ROM 签名（Samsung/Xiaomi/Huawei/...）：识别对照表见取证手册附录。

---

## 3. 包名 / 版本 / 构建指纹

### 3.1 包名（`AndroidManifest.xml`）
- 攻击者常用相似包名混淆：`com.tencent.mm` ↔ `com.tencent.mmm` ↔ `com.tcent.mm`。
- **不能仅凭包名同源**（容易被仿冒）；应配合签名公钥指纹。

```bash
aapt dump badging app.apk | head -5
# package: name='com.foo.bar' versionCode='123' versionName='1.2.3'
# sdkVersion:'21'  targetSdkVersion:'30'
```

### 3.2 versionCode / versionName
- 多样本同包名 → 按 `versionCode` 排升序得到**版本演进史**。
- VT 平台对同包名不同 versionCode 自动聚类。

### 3.3 构建工具指纹
| 字段 | 来源 | 用途 |
| --- | --- | --- |
| `Created-By` 在 `META-INF/MANIFEST.MF` | 例 `Android Gradle 7.4.2` | 识别构建工具版本 |
| `Built-By` | 编译机用户名（少见） | 强溯源 |
| `Built-Date` | 编译时间 | 多样本同分钟 = 同流水线 |
| `androidx.core.app.CoreComponentFactory` 等支持库版本 | 反编译看 BuildConfig | 与 SDK 渠道相关 |

```bash
unzip -p app.apk META-INF/MANIFEST.MF | head -5
```

### 3.4 渠道 ID（**国内 App 重要**）
- 国内 App 几乎必带"渠道号"，方便统计来自哪个应用市场/推广渠道。
- 落点（按主流方案）：
  - **walle**（美团开源）：APK Sig Block 内 `0x71777777` 块。
  - **packer-ng / VasDolly**（腾讯）：v2 块；新版用 `0x7e747777`。
  - **assets/channel.txt** / **META-INF/channel** / **META-INF/CHANNEL_<NAME>**（老方案）。
  - 部分 SDK：`AndroidManifest.xml` `<meta-data android:name="UMENG_CHANNEL" android:value="..."/>` / `BUGLY_APPCHANNEL` / `TD_APP_ID` 等。
- **取证用法**：从渠道 ID 反查嫌疑人从哪个市场/链接下载 → 配合应用市场后台调取下载记录。

```bash
# 渠道字符串扫描
unzip -p app.apk AndroidManifest.xml | strings | grep -iE 'channel|cid|UMENG_'
unzip -l app.apk | grep -iE 'META-INF/channel|channel\.txt'
# walle / VasDolly 提取
java -jar walle-cli.jar show app.apk
```

---

## 4. 代码级同源

### 4.1 Dex 哈希
- 整 dex 文件 SHA-256：基本无意义（少 1 字节即变）。
- **classes.dex 内 method 集合的归一化哈希**（NormalizedMethodHash）：忽略行号/调试信息，仅保留 opcode + 字面量类型。
- 工具：
  - **simhash** / **ssdeep** / **TLSH** 模糊哈希。
  - **AndroGuard** `androguard analyze` 计算 method hash。
  - **dexhash** 脚本：对每个 class+method 单独 hash → 集合 Jaccard 相似度。

```bash
pip install androguard
androguard analyze app.apk
# > a.classes -> 类列表
# > a.methods -> 全方法

# AndroSim（同源比对）
androsim app1.apk app2.apk
```

### 4.2 SO 哈希
- 同样：整 SO sha256 不稳，**符号表 + 节哈希更稳**。
- **TLSH** / **ssdeep**：模糊哈希同 family 相似度高。

```bash
ssdeep lib/arm64-v8a/libtarget.so
tlsh lib/arm64-v8a/libtarget.so
```

### 4.3 字符串聚类
- 提取 dex 内字符串（`strings classes.dex` + 过滤合法 UTF-8 + 长度 ≥ 6）→ 转集合 → Jaccard。
- 关键标识：
  - 自家函数名 / 异常文案（"网络异常请稍后重试"等）；
  - 版权 / Build 信息字符串；
  - 调试日志 TAG（如 `Log.d("MyApp", ...)`）；
  - C2 域名 / Bot 命令字面量。

```python
import re, zipfile
def strings_set(apk):
    z = zipfile.ZipFile(apk)
    s = set()
    for n in z.namelist():
        if not (n.endswith('.dex') or n.endswith('.so')): continue
        d = z.read(n)
        for m in re.finditer(rb'[\x20-\x7e]{6,}', d):
            s.add(m.group().decode())
    return s
a = strings_set('a.apk'); b = strings_set('b.apk')
print(len(a & b)/len(a | b))   # Jaccard
```

### 4.4 资源同源
- **AndroidManifest.xml**（解码后 XML）DOM 结构哈希。
- **resources.arsc**：strings pool + resource ids；同 family 多复用。
- **drawable / mipmap PNG/WebP 文件 SHA**：图标、品牌图最稳定。
- **layout XML** 哈希：UI 复用强证据。

```bash
# 计算所有资源文件 hash
unzip -p app.apk | sha256sum   # 整体（不稳）
# 逐文件
for f in $(unzip -l app.apk | awk 'NR>3{print $4}'); do
  unzip -p app.apk "$f" 2>/dev/null | sha256sum | awk -v f="$f" '{print $1, f}'
done
```

### 4.5 图标视觉 hash
- pHash / dHash 检测"换皮"App。
- 工具：`imagehash` Python 库。

```python
from PIL import Image
import imagehash, zipfile, io
z = zipfile.ZipFile('app.apk')
for n in z.namelist():
    if 'mipmap' in n and n.endswith(('png','webp')):
        try:
            img = Image.open(io.BytesIO(z.read(n)))
            print(n, str(imagehash.phash(img)))
        except: pass
```

---

## 5. 网络指标（域名 / IP / 证书）

### 5.1 提取硬编码 URL
```bash
# 一把抓所有 dex / so 内的 URL
strings classes*.dex lib/*/*.so | grep -oE 'https?://[A-Za-z0-9._:/-]+' | sort -u

# 加密的 URL：先脱壳后再扫；或动态运行时抓
# 字符串加密 hook：
frida -U -f com.target -l hook_string_decode.js
```

### 5.2 域名/IP 溯源
| 数据 | 工具 |
| --- | --- |
| WHOIS（注册人邮箱、组织） | `whois example.com` |
| 历史 DNS 解析 | SecurityTrails、PassiveTotal、VirusTotal Passive DNS |
| 证书透明度 CT log | crt.sh、censys |
| IP 反查域名 | reverse-IP（webxray / ViewDNS） |
| ASN 归属 | `whois -h whois.cymru.com " -v <ip>"` |
| 注册商 | 国内 .cn 域名可通过 CNNIC 查 |

```bash
whois example.com | grep -iE 'registrant|email|name|org'
# 历史
curl 'https://crt.sh/?q=%25.example.com&output=json' | jq '.[].name_value' | sort -u
```

### 5.3 同源域名特征
- **共注册邮箱**（Whois Privacy 之后较难）。
- **同一注册商 + 注册日期相邻**（24h 内注册的批量域名）。
- **同一 NS / 同一 IP / 同一 ASN**。
- **域名命名规律**：`[a-z]{6}.com` / `xxx-cdn.com` / 拼音首字母组合。
- **TLS 证书相同**（CN 字段 / SAN 列表 / 自签名公钥）。

### 5.4 证书锁（Pinning）= 强同源指标
- App 内若硬编码服务器证书指纹（pinning），不同 App 锁同一指纹 = 后端同一站点。
- 提取：搜 `pin-set` 配置文件（`res/xml/network_security_config.xml`）；或代码内 `OkHttpClient.Builder().certificatePinner(...)` 字面量。

```bash
unzip -p app.apk res/xml/network_security_config.xml | xmlstarlet sel -t -v '//pin' 2>/dev/null
```

### 5.5 第三方 SDK 指纹
| SDK | 标志类名 | 作用 |
| --- | --- | --- |
| 友盟统计 Umeng | `com.umeng.analytics.*` | App 用户行为统计；同样的 Umeng AppKey = 同后台 |
| Bugly（腾讯） | `com.tencent.bugly.*` | 崩溃统计 |
| 极光推送 JPush | `cn.jpush.*` + `JPUSH_APPKEY` 在 manifest | 推送 |
| 个推 GeTui | `com.igexin.*` | 推送 |
| TalkingData | `com.tendcloud.*` + `TD_APP_ID` | 行为分析 |
| 神策 Sensors | `com.sensorsdata.*` | 同上 |
| Bytedance Applog | `com.bytedance.applog.*` | 字节系 |
| MobTech ShareSDK | `com.mob.*` | 分享/短信 |
| Pingplusplus / 支付宝 / 微信支付 SDK | `com.pingplusplus.*` / `com.alipay.*` / `com.tencent.mm.opensdk.*` | 支付 |

> **AppKey/AppID 是后台账户唯一识别**，多个 App 配置相同的 Umeng/JPush/TalkingData AppID = 同一开发者后台 → **法律调取可拿到真人账户**。

```bash
# 提取所有 meta-data
aapt dump xmltree app.apk AndroidManifest.xml | grep -E 'meta-data|APPKEY|APP_ID|CHANNEL'
```

---

## 6. 设备侧：安装历史与使用频度

### 6.1 已装 App 列表 + 安装时间
```bash
adb shell pm list packages -f -i -u    # -i 显示 installer，-u 含已卸载
# package:/data/app/...==/base.apk=com.foo.bar  installer=com.android.vending

# 详细信息（首次/最后安装时间、来源、签名）
adb shell dumpsys package com.foo.bar
# firstInstallTime=1714540800000
# lastUpdateTime= 1715000000000
# installerPackageName=com.android.vending
# signatures: <pubkey hash>
```

### 6.2 PackageManager 数据库（离线）
- 设备：`/data/system/packages.xml`（Android < 11）/ `packages.xml` + `packages.list`（Android 11+）。
- 含每个 App 的：UID、安装时间、更新时间、签名证书、权限、installerPackageName。
- 取证脚本一把抓：

```bash
adb pull /data/system/packages.xml
xmlstarlet sel -t -m '//package' \
  -v '@name' -o $'\t' -v '@ft' -o $'\t' -v '@ut' -o $'\t' -v '@installer' -n packages.xml
# ft=firstInstallTime（hex ms）  ut=lastUpdateTime（hex ms）
```

### 6.3 安装来源（installerPackageName）
| 值 | 含义 |
| --- | --- |
| `com.android.vending` | Google Play |
| `com.huawei.appmarket` | 华为应用市场 |
| `com.xiaomi.market` | 小米应用商店 |
| `com.bbk.appstore` | vivo 应用商店 |
| `com.heytap.market` | OPPO 软件商店 |
| `com.tencent.android.qqdownloader` | 腾讯应用宝 |
| `com.qihoo.appstore` | 360 手机助手 |
| `com.android.packageinstaller` / `com.google.android.packageinstaller` | **侧载**（用户手动装、未知来源） |
| `null` / 空 | 系统预装 |
| `com.android.shell` | adb install |

> **来源 = `com.android.packageinstaller` 或 `com.android.shell` 是灰产 App 的常见信号**。

### 6.4 安装日志 / Logcat 历史（仅最近）
```bash
adb logcat -d -b all | grep -iE 'PackageManager.*(installPackage|installed|removed|deleted)'
```
- 仅当下会话；持久日志看 Unified Logging（无 Android 等价）→ 仅靠 `packages.xml` 的时间戳。

### 6.5 系统残留即便已卸载
| 残留 | 路径 | 含义 |
| --- | --- | --- |
| `/data/system/uiderrors.txt` | 错误记录 | 偶尔含包名 |
| `/data/system/dropbox/` | 系统崩溃/ANR | 含包名 + 时间 |
| `/data/system/packages_backup.xml` | 备份的 packages.xml | 上一版本的安装列表 |
| `/data/system/usagestats/` | usage stats | 每天 App 使用频度（**§6.6**） |
| `/data/data/<pkg>/` | 残留沙盒（卸载多数会清，但 `external` 不一定） | |
| `/sdcard/Android/data/<pkg>/` | 外部沙盒，**卸载常残留** | |
| `/sdcard/Download/<apkfile>.apk` | 下载的安装包本体 | |
| Downloads `provider`：`/data/data/com.android.providers.downloads/databases/downloads.db` | 含下载记录 + 来源 URL | |

> 看到沙盒外部目录有但 packages.xml 无 → **App 已卸载但用过**。

### 6.6 使用频度（**关键题源**）
- **UsageStatsManager** 数据：`/data/system/usagestats/<userid>/` 下分四级（daily/weekly/monthly/yearly）+ check-in。
- 每条记录含 `packageName`、`startTime`、`endTime`、`totalTimeInForeground`。

```bash
adb pull /data/system/usagestats/0 ./usagestats
# 文件名是 timestamp，二进制 + protobuf
# 工具：
git clone https://github.com/Ramedy/AppUsage   # 解析脚本
python parse_usagestats.py ./usagestats
```

或直接运行时取（设备需有 `PACKAGE_USAGE_STATS` 权限）：
```bash
adb shell dumpsys usagestats | head -200
adb shell dumpsys usagestats --user 0 | grep -A3 'package='
```

### 6.7 通知历史
- `/data/system/notification_log.db` / `notification.db`（部分 ROM）。
- 看 App 在何时弹过哪些通知 → 推断收消息时间。

### 6.8 网络访问记录
- 系统级：`/data/misc/net/`、`/data/system/netstats/`（NetworkStats）。
- VPN 日志（如启用）：`/data/misc/vpn/`。
- DNS 缓存：`getprop net.dns1`/`net.dns2`、 `/data/misc/net/rt_tables` 等。
- App 内部：每个 App 自有日志/缓存（OkHttp `journal`、Volley、Picasso 缓存）。

```bash
adb shell dumpsys netstats detail | head -200
```
含每个 UID 的接收/发送字节、按时间分桶。

### 6.9 Doze / JobScheduler / WorkManager 残留
- `/data/system/job/jobs.xml`：注册的后台任务，含包名 + 触发条件。
- 显示哪些 App"在后台主动联网" → 灰产/木马常驻特征。

---

## 7. 多账号 / 多设备聚合

### 7.1 同账号多设备
- Google 账号：`adb shell dumpsys account`、`/data/system_de/0/accounts_ce.db`、`accounts_de.db`。
- 厂商账号（小米/华为/Apple）：各自数据库。
- 第三方（微信/QQ/微博）：App 沙盒内 token。
- **同一账号 token 出现在多设备 → 聚合证据**。

### 7.2 同设备多账号
- `/data/system/users/userlist.xml` + `/data/user/<uid>/`（参 `lock_password_forensics.md`）。
- **应用分身**也属此类（参 `emulator_clone_forensics.md`）。

### 7.3 跨样本-跨设备-跨账号关联
| 关联点 | 强度 |
| --- | --- |
| Android ID（`Settings.Secure.ANDROID_ID`） | 强（设备唯一，刷机会重置） |
| 广告 ID（GAID/OAID） | 中（用户可重置） |
| IMEI/MEID | 强（硬件） |
| MAC / BSSID | 中（隐私化后已限） |
| Build.SERIAL | 强（部分老机型） |
| App 自家 deviceId（多数派生 IMEI/MAC/AndroidID） | 因 App 而异 |

---

## 8. 自动化工具链

### 8.1 静态批量分析
- **AndroGuard**（Python）：解析 APK / 计算 hash / 提 perms / 调用图。
- **Quark Engine**：基于威胁规则的 APK 分析 + 评分。
- **MobSF**（Mobile Security Framework）：一键报告（perm、URL、签名、字符串、风险点）。
- **APKLab**（VS Code 扩展）：apktool + jadx + frida 集成。
- **APKiD**（壳识别，已在 `android_packer_unpacker.md`）。

### 8.2 动态/沙箱
- **VirusTotal**：上传后看 family 命中、网络行为、关联样本。
- **CAPA**（Mandiant）/ **CAPE Sandbox** / **Cuckoo Android**：行为提取。
- **JoeSandbox / Triage / AnyRun**：商用/在线沙箱。
- **MobSF Dynamic** + frida + tcpdump 自建沙箱。

### 8.3 同源比对脚本（举例）
```bash
# 批量 SHA256 + 签名指纹
for f in *.apk; do
  sha=$(sha256sum "$f" | awk '{print $1}')
  cert=$(apksigner verify --print-certs "$f" 2>/dev/null | grep 'SHA-256 digest' | head -1 | awk '{print $NF}')
  pkg=$(aapt dump badging "$f" 2>/dev/null | grep -oE "package: name='[^']+'" | head -1)
  echo "$sha $cert $pkg $f"
done > family.tsv

# 按 cert 分组 = 同 keystore 族
sort -k2 family.tsv | awk '{print $2}' | uniq -c | sort -rn
```

### 8.4 高频访问统计（设备端取数据后）
```python
# 解析 usagestats 后聚合
import pandas as pd
df = pd.read_csv('usagestats_parsed.csv')   # cols: pkg, start, end, foreground_ms
top = df.groupby('pkg').foreground_ms.sum().sort_values(ascending=False).head(20)
print(top)
```

---

## 9. 比赛/实战题型与解法

### 9.1 题型 A："这两个 APK 是不是同一作者写的"
1. `apksigner verify --print-certs` → 比公钥 SHA-256 → 一致即铁证。
2. 公钥不同 → 比代码 simhash / 字符串 Jaccard / 资源 hash / SDK AppKey。
3. 比相同的 C2 / pinning 指纹。
4. 报告写"X 项一致 / Y 项不一致 / 同源置信度高/中/低"。

### 9.2 题型 B："这个 APK 来自哪个市场 / 渠道"
1. 提取渠道 ID（walle/VasDolly/META-INF/channel.txt/manifest meta-data）。
2. 安装来源在设备 `dumpsys package` 内 `installerPackageName`。
3. 下载来源在 `downloads.db` / 浏览器历史。

### 9.3 题型 C："找出嫌疑人手机里安装过的所有 App + 使用频度 Top 10"
1. `pm list packages -f -i -u` → 全清单（含已卸）。
2. `dumpsys package <pkg>` → 安装/更新时间。
3. usagestats parser → foreground_ms 累计 → 排序。
4. 报告：包名 + App 名（aapt dump badging label） + 安装时间 + 总使用时长。

### 9.4 题型 D："嫌疑人 X 月 X 日是否打开过 App Y"
1. usagestats（按天文件）查指定日期 → grep 包名。
2. 配合 KnowledgeC（iOS）/ PowerLog 思路（Android 无 PowerLog 等价）。
3. logcat 时间窗内有无相关包名活动。

### 9.5 题型 E："App 服务器 / C2 在哪里"
1. 静态扫硬编码 URL（脱壳后）。
2. 动态抓包（mitmproxy + 绕 ssl pinning）。
3. WHOIS/CT/Passive DNS 反查注册人。
4. 联系 ICP 备案查询（国内 .cn 域名 https://beian.miit.gov.cn/）。

### 9.6 题型 F："这个 App 与已知样本族 X 是否同源"
1. 公钥指纹比对（与已知 X 的指纹库）。
2. 类名 / 字符串 / 资源 / 图标 hash 比对。
3. 共用 C2 / SDK AppKey 比对。
4. 输出"同源置信度"。

### 9.7 题型 G："嫌疑人侧载了一个 App，这个 APK 来源是什么"
1. `dumpsys package` 看 installerPackageName。
2. `Downloads/` 下找 APK；`downloads.db` 看下载 URL + 来源 referer。
3. 浏览器历史（Chrome `History` db）匹配下载时间。
4. 微信/QQ 文件传输助手 / TIM 接收文件目录搜 apk。

### 9.8 题型 H："这个 App 的高频访问对象（联系人/服务器）"
1. App 沙盒数据库（IM 类）+ 聊天频次统计。
2. 网络日志 NetworkStats by UID（按时间桶）。
3. App 自家 SQLite 内"recent contacts"/"frequent contacts"表。
4. KnowledgeC（iOS） / Android `interactions` 表（部分 ROM）。

### 9.9 题型 I："App 已被卸载但需取证"
1. `packages_backup.xml` 看历史。
2. `/sdcard/Android/data/<pkg>/` 残留沙盒。
3. `/sdcard/Download/<file>.apk` 安装包本体。
4. usagestats 历史文件（不会随 App 卸载清空）。
5. 备份（厂商云备份/Google 备份）拉历史数据。

---

## 10. 命令速查

```bash
# 签名指纹
apksigner verify --print-certs app.apk
keytool -printcert -jarfile app.apk

# 包基础信息
aapt dump badging app.apk
aapt dump xmltree app.apk AndroidManifest.xml | head -80

# 渠道
java -jar walle-cli.jar show app.apk
unzip -p app.apk META-INF/channel.txt 2>/dev/null
unzip -p app.apk AndroidManifest.xml | strings | grep -iE 'UMENG_CHANNEL|JPUSH_APPKEY|BUGLY_APPID|TD_APP_ID'

# 字符串/URL
strings classes*.dex lib/*/*.so | grep -oE 'https?://[^"]+' | sort -u

# 设备已装 + 安装来源
adb shell pm list packages -f -i -u | sort

# 详细某 App
adb shell dumpsys package com.foo.bar | grep -iE 'firstInstallTime|lastUpdateTime|installerPackageName|signatures'

# packages.xml 离线
adb pull /data/system/packages.xml
adb pull /data/system/packages.list

# usagestats 离线
adb pull /data/system/usagestats/0 ./usagestats
python parse_usagestats.py ./usagestats > usage.csv

# usagestats 在线
adb shell dumpsys usagestats --user 0 > usagestats.txt

# NetworkStats（按 UID 流量）
adb shell dumpsys netstats detail > netstats.txt

# 通知历史
adb pull /data/system/notification_log.db ./   # 部分 ROM 才有

# 域名溯源
whois example.com
curl 'https://crt.sh/?q=%25.example.com&output=json' | jq '.[].name_value' | sort -u
nslookup example.com 8.8.8.8

# AndroGuard 同源
androsim sample1.apk sample2.apk
androsign *.apk             # 列签名指纹

# MobSF（在线分析）
docker run -p 8000:8000 opensecurity/mobile-security-framework-mobsf
```

---

## 11. 常见坑

1. **包名相同 ≠ 同源**：仿冒/侧载常用相同包名，**必须看签名公钥**。
2. **公钥不同也可能同作者**：作者换 keystore 是常事；要靠代码/资源/字符串/SDK AppKey 多维度补强。
3. **渠道号缺失/被剥离**：发布前可能去掉，**没找到不代表没有**。
4. **WHOIS Privacy**：现代域名注册商默认隐藏注册人；改看历史 WHOIS 快照（DomainTools / SecurityTrails）。
5. **CT log 不全**：自签证书/未提交 CT 的不出现在 crt.sh；仍需主动连接证书获取。
6. **usagestats 文件随时间合并**：每天独立文件 → 周 → 月；旧数据被聚合，**精度按时间逐渐降低**。
7. **logcat 不持久**：重启即丢；现场必须立即 `adb logcat -d > log.txt`。
8. **dumpsys 输出过长被截断**：大设备 dumpsys 输出几 MB，导出时 `> file.txt` 不要 `| head`。
9. **installer 为 null 不一定是预装**：有些根证书厂商或刷机 ROM 把字段清掉 → 仅靠这个判定预装易错。
10. **UID 复用**：App 卸载后 UID 可能复用给新 App，**netstats 历史按 UID 关联包名**时要看时间窗。
11. **AppKey 一致不等于一定同公司**：测试/开源代码可能复制粘贴 AppKey；要看 AppKey 是否绑定同后台账户（需法律调取证实）。
12. **CDN/反代隐藏真实 C2**：直连 IP 看到的是 Cloudflare/阿里云 → 看证书原始域名 + 历史 DNS。
13. **App 自我重命名**：嫌疑人改 App label / 图标，**包名/签名仍是原值**，不被 UI 误导。
14. **ICP 备案信息可能挂靠**：备案主体不是真用户；仍需结合资金链 / 域名 WHOIS / 服务器调取交叉。
15. **Android 11+ Package Visibility**：调用 `getInstalledPackages` 默认看不到全部 App（需声明 `<queries>` 或权限），现场取证要用 `adb shell pm list packages` 而非 App 内 API。
16. **多用户/分身的 packages.xml**：每个 user 一个；不要只看 user 0。
17. **VPN/代理改 IP**：网络日志的目标 IP 可能是 VPN 出口，非真实 C2；看 SNI / 应用层域名。
18. **同源置信度报告**：写"X 项一致 / Y 项不一致 / 综合判断"，**避免绝对化**。

---

## 12. 决策流

```
判定题
├─ "同一作者?"
│   1. 公钥 SHA-256 → 一致 = 强证据
│   2. 不同 → 比 dex/so simhash + 字符串 Jaccard + 资源 + SDK AppKey + C2
│   3. 输出置信度
├─ "App 来源?"
│   1. installerPackageName + 渠道 ID + downloads.db
│   2. 配合应用市场后台调取 / ICP 备案 / WHOIS
├─ "嫌疑人用 App 多频繁?"
│   1. usagestats（精确）
│   2. NetworkStats（流量证据）
│   3. App 内最近联系人/最近会话表
└─ "已卸载 App 取证?"
    1. packages_backup.xml + usagestats 历史
    2. 外部沙盒残留
    3. Download 目录 apk
    4. 云备份 / 应用市场账号下载历史
```

---

## 13. 交叉链接
- `android_packer_unpacker.md`：脱壳后才能比对代码同源
- `apk_crypto_analysis.md`：算法/密钥提取（pinning 证书也在内）
- `wechat_deep_dive.md` / `popular_apps_forensics.md`：具体 App 沙盒结构
- `lock_password_forensics.md`：多用户 / 分身 / packages.xml
- `emulator_clone_forensics.md`：分身/克隆数据
- `network/network_capture.md`（如有）：抓包配合域名溯源
- `device_basic_info.md`：设备唯一标识
- `extraction_methods.md`：取证前置（root/AFU）
- `anti_forensics_and_misleading.md`：仿冒/换皮/反归因
