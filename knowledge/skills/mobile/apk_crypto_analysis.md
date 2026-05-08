---
tags: [mobile, android, apk, reverse_engineering, crypto, aes, rsa, frida, jadx, smali, native_so, packing, methodology]
tools: [jadx, apktool, apkid, androguard, frida, ghidra, ida, radare2, d2j_dex2jar, blackdex, pycryptodome]
category: mobile_forensics
difficulty: hard
source: kb_seed_2026-05-07
verified: false
related: [pattern_aes_xor_password_reverse.md, 2022_changancup_mobile_exe_apk.md, 美亚杯-2024团队赛.md, pattern_wechat_db_decrypt.md]
---
# APK 分析 — 加解密 / 密钥提取 / 算法还原

> **核心心法**：
> 1. **静态先行** — DEX 反编译看 Java 调了什么 API
> 2. **追到密钥** — 80% 在常量字符串、SharedPrefs、assets/raw、native .so
> 3. **算法还原** — 80% 是 AES/DES/RSA 标准用法 + 一两步混淆，10% 自定义（XOR + 移位居多）
>
> 卡住时上 **Frida**（运行时 hook 标准 API 直接拿明文），是 APK 加解密的作弊神器，能省 90% 时间。

## 0. 拿到 APK 的标准流程

```bash
# 1. 文件识别 / 加固检测
file game.apk                    # ZIP archive
unzip -l game.apk | head
apkid game.apk                   # 标 packer：360 / 爱加密 / 梆梆 / 乐固 / Bangcle / Ijiami / DexProtector

# 2. AndroidManifest
aapt dump badging game.apk
aapt dump permissions game.apk
python -c "from androguard.misc import APK; a=APK('game.apk'); print(a.get_package(), a.get_permissions())"

# 3. 反编译 DEX → Java
jadx -d out game.apk             # 主力
jadx-gui game.apk                # 全局搜更顺
apktool d game.apk -o smali_out  # 拿 smali

# 4. native .so
ls out/resources/lib/            # arm64-v8a / armeabi-v7a / x86_64
ghidra / ida / r2 -A libfoo.so

# 5. assets / res / raw（密钥常藏这里）
ls out/resources/assets/
ls out/resources/res/raw/
strings -n 8 out/resources/assets/* | head
```

---

## 1. 密钥九大藏身处（按出现频率）

| ★ | 位置 | 怎么找 |
|---|---|---|
| ★★★ | **Java 字符串常量** | jadx-gui 全局搜 `"AES"` `"DES"` `"RSA"` `"key"` `"password"` |
| ★★★ | **`assets/` 静态文件** | `strings`、`xxd`、文件类型识别 |
| ★★★ | **`SharedPreferences`** | `/data/data/{pkg}/shared_prefs/*.xml`（运行后才有） |
| ★★ | **`res/raw/`、`res/values/strings.xml`** | `<string name="api_key">...` |
| ★★ | **native .so 常量段** | IDA `.data` / `.rodata` |
| ★★ | **服务器下发** | 静态找不到 → 抓包看 API 响应 |
| ★★ | **AndroidManifest meta-data** | `<meta-data android:name="API_KEY" .../>` |
| ★ | **资源混淆 / 字符串加密** | 解出来还是密文，要找解密函数（常 `String a(int)`） |
| ★ | **设备绑定（IMEI/UUID 派生）** | 算法依赖运行时设备信息，必须动态分析 |

---

## 2. 标准 Java Crypto API 速查

| 调用 | 算法 |
|---|---|
| `Cipher.getInstance("AES/CBC/PKCS5Padding")` | AES-128/192/256 CBC |
| `Cipher.getInstance("AES/ECB/PKCS5Padding")` | AES ECB（最常见） |
| `Cipher.getInstance("AES/GCM/NoPadding")` | AES-GCM（认证加密） |
| `Cipher.getInstance("DES/...")` / `"DESede/..."` | DES / 3DES |
| `Cipher.getInstance("RSA/ECB/PKCS1Padding")` | RSA |
| `Mac.getInstance("HmacSHA256")` | HMAC |
| `MessageDigest.getInstance("SHA-256")` | 哈希 |
| `SecretKeySpec(key, "AES")` | 对称密钥 |
| `IvParameterSpec(iv)` | CBC 的 IV |
| `KeyFactory.generatePublic(...)` | RSA/EC 公钥 |
| `PBEKeySpec(pwd, salt, iter, len)` | PBKDF2 派生 |
| `KeyGenerator.getInstance("AES")` | 临时随机密钥 |

⚠️ **PKCS5Padding ≡ PKCS7**（Java 命名混乱，块大小 16）。

---

## 3. 非标准算法的指纹

| 看到 | 可能是 |
|---|---|
| 256 字节查表，开头 `0x63 0x7c 0x77 0x7b` | **AES S-box** |
| 256 字节查表，初始化阶段 swap | **RC4** |
| 大量 `^=` `>>>` `<<` 移位 | **XTEA / TEA / RC4 / 自定义流密码** |
| 64-round 循环 + 常量 `0x9E3779B9` | **TEA / XTEA**（黄金分割数） |
| 8 个 32 位 k0..k7 + 16 round | **SM4**（中国国密） |
| `0x67452301 0xefcdab89` | **MD5 / SHA1 初始化** |
| `0x6a09e667` | **SHA-256 初始化** |
| 大整数 + 模幂 | **RSA / ElGamal** |
| 椭圆曲线点 | **ECC / ECDSA** |
| Base64 后接奇怪解码 | 实际 **XOR / 替换** 套 Base64 外壳 |

---

## 4. 四种打法（按效率）

### 打法 1：静态分析 → 提取硬编码密钥（最快，5-30 分钟）

```
jadx-gui → 搜关键词 → 找到加密类 → 抄密钥 → Python/openssl 解
```

```python
# Python 复刻 Java AES/CBC/PKCS5
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

key = bytes.fromhex("...") or b"literal_key_string"
iv  = bytes.fromhex("...") or b"\x00" * 16
ct  = bytes.fromhex("...")

c = AES.new(key, AES.MODE_CBC, iv)
print(unpad(c.decrypt(ct), 16))

# AES/GCM
c = AES.new(key, AES.MODE_GCM, nonce=iv)
print(c.decrypt_and_verify(ct[:-16], ct[-16:]))

# DES
from Crypto.Cipher import DES
DES.new(key[:8], DES.MODE_ECB).decrypt(ct)
```

### 打法 2：Frida 运行时 hook（最强，5-10 分钟）

无需理解算法，直接在 `Cipher.doFinal` 处打印 in/out。

```javascript
// frida -U -f com.target.app -l hook.js --no-pause
Java.perform(function() {
  var Cipher = Java.use("javax.crypto.Cipher");
  Cipher.doFinal.overload("[B").implementation = function(data) {
    var algo = this.getAlgorithm();
    console.log("[Cipher] " + algo + " op=" + this.opmode.value);
    console.log("  in : " + bytesToHex(data));
    var out = this.doFinal(data);
    console.log("  out: " + bytesToHex(out));
    return out;
  };

  // 也 hook 密钥构造
  var KS = Java.use("javax.crypto.spec.SecretKeySpec");
  KS.$init.overload("[B", "java.lang.String").implementation = function(k, a) {
    console.log("[Key] " + a + " = " + bytesToHex(k));
    return this.$init(k, a);
  };

  // IV
  var IV = Java.use("javax.crypto.spec.IvParameterSpec");
  IV.$init.overload("[B").implementation = function(iv) {
    console.log("[IV] " + bytesToHex(iv));
    return this.$init(iv);
  };

  // MessageDigest 也常用
  var MD = Java.use("java.security.MessageDigest");
  MD.digest.overload().implementation = function() {
    var r = this.digest();
    console.log("[MD] " + this.getAlgorithm() + " = " + bytesToHex(r));
    return r;
  };

  function bytesToHex(b) {
    return Array.from(new Int8Array(b))
      .map(x => (x & 0xff).toString(16).padStart(2,"0")).join("");
  }
});
```

**前提**：手机 root + frida-server 跑起来 + app 可启动。

### 打法 3：动态调试（Frida 不够时）

```javascript
// hook 任意自定义类方法
var Foo = Java.use("com.bad.app.Crypto");
Foo.decrypt.implementation = function(input) {
    var r = this.decrypt(input);
    console.log("decrypt(" + input + ") = " + r);
    return r;
};
```

工具：smalidea (IntelliJ smali 调试) / JEB 调试器。

### 打法 4：Native .so 逆向（最难）

```bash
# IDA / Ghidra 找 Java_<package>_<class>_<method> export
# Frida 也能 hook native：
```

```javascript
Interceptor.attach(Module.findExportByName("libfoo.so", "Java_com_bad_app_decrypt"), {
    onEnter: function(args) { console.log("decrypt called"); },
    onLeave: function(ret) { console.log("ret = " + ret); }
});
```

**重写 / 在 Android 工程里调用 so**：自己 app `System.loadLibrary("foo")`，声明同签名 native，logcat 拿结果。`@knowledge/solved/2022_changancup_mobile_exe_apk.md:64-73` 用的就是这招。

---

## 5. 加固 APK 脱壳

### 识别加固
APKiD：`Bangcle / 360 / 爱加密 / 梆梆 / 乐固 / Ijiami / Naga / DexProtector`

### 脱壳难度

| 加固类型 | 难度 | 工具 |
|---|---|---|
| 整体 dex 加密（梆梆免费、爱加密） | 易 | FRIDA-DEXDump / blackdex |
| dex 抽取（VMP，乐固、360） | 中 | FRIDA-DEXDump (fart) |
| dex2c（恶意常见） | 难 | unidbg + so 模拟 |
| 自实现 VM | 极难 | 人工逆向 |

```bash
# 通用脱壳
frida -U -f com.target.app -l frida-dexdump.js --no-pause
# 或 blackdex（Android 上跑的 GUI app）

# 拿到 dex 后
for f in *.dex; do d2j-dex2jar.sh $f; done
# 或直接 jadx -d out *.dex
```

---

## 6. 字符串混淆破解

### 字符串解密
```java
String pwd = a.b("xK9z...");   // a.b() 是字符串解密函数
```

```javascript
// Frida 批量解
var A = Java.use("a.a.a");
A.b.implementation = function(x) {
    var r = this.b(x);
    console.log("b('" + x + "') = '" + r + "'");
    return r;
};
```

### 类名/字段混淆
- ProGuard → `jadx --deobf` 自动重命名
- 自定义混淆（全 `OooO0o0`）→ 看代码逻辑而非名字

---

## 7. 决策树

```
拿到 APK + 要解密某段密文
   │
   ├─ Step 1: APKiD 看是否加固
   │     ├ 是 → 先脱壳（FRIDA-DEXDump）
   │     └ 否 → Step 2
   │
   ├─ Step 2: jadx-gui 全局搜 "Cipher.getInstance"/"AES"/"key"/"decrypt"
   │
   ├─ Step 3: 看密钥在哪
   │     ├ 字符串常量    → 直接抄
   │     ├ assets/res/raw → 提取
   │     ├ SharedPrefs   → 跑一次 app 后读
   │     ├ native .so    → IDA 看 .data
   │     └ 服务器下发    → 抓包
   │
   ├─ Step 4: 算法还原
   │     ├ 标准 API   → Python pycryptodome 复刻
   │     ├ 自定义     → 重写 Java 逻辑成 Python
   │     └ 复杂/魔改  → Frida hook 拿明文
   │
   ├─ Step 5: 验证
   │     用一个已知明密对验证
   │
   └─ Step 6: 批量解所有目标密文
```

---

## 8. 命令速查

```bash
# 解 APK
unzip game.apk -d out
apktool d game.apk -o smali_out
jadx -d java_out game.apk
jadx-gui game.apk

# 加固检测
apkid game.apk

# 字符串扫
strings -n 8 game.apk | grep -E "AES|Cipher|key|password|http" | head

# DEX → JAR
d2j-dex2jar.sh classes.dex

# Native
ghidra libfoo.so
r2 -A libfoo.so

# Frida 跑通
adb push frida-server-arm64 /data/local/tmp/fs
adb shell "su -c 'chmod 755 /data/local/tmp/fs && /data/local/tmp/fs &'"
frida -U -f com.target.app -l hook.js --no-pause

# Java AES/CBC → Python
python -c "
from Crypto.Cipher import AES; from Crypto.Util.Padding import unpad
k=b'1234567890abcdef'; iv=b'\x00'*16
c=AES.new(k,AES.MODE_CBC,iv); print(unpad(c.decrypt(bytes.fromhex('...')),16))"

# Java SHA-256 → Python
python -c "import hashlib; print(hashlib.sha256(b'data').hexdigest())"

# RSA 公钥加密验证
python -c "
from Crypto.PublicKey import RSA; from Crypto.Cipher import PKCS1_v1_5
k=RSA.import_key(open('public.pem').read()); c=PKCS1_v1_5.new(k)
print(c.encrypt(b'plaintext').hex())"
```

---

## 9. 常见坑

- **PKCS5 ≡ PKCS7**：Java PKCS5Padding 实际是 PKCS7（块 16）
- **`.getBytes()` 默认 UTF-8 但部分 ROM 是 GBK**：转字节要确认
- **`SecretKeySpec` 第二参数 "AES" 只是标签**：实际 key 长度才决定 AES-128/192/256
- **CBC IV 不设 = 全 0**：常省略，写 Python `iv=b"\x00"*16`
- **`SecureRandom("SHA1PRNG", "Crypto")`** Android 老 bug：种子相同 → 派生相同密钥（可预测）
- **`new String(bytes)` 默认平台编码**：可能丢字节，显式 `new String(b, "UTF-8")`
- **Base64 NO_WRAP / URL_SAFE**：Java `Base64.encodeToString(b, NO_WRAP|URL_SAFE)` ↔ Python `base64.urlsafe_b64encode().rstrip(b"=")`
- **Hex 大小写不一**：Apache Hex vs Bouncy Castle，对比时 `.lower()`
- **JNI native key 与 Java key 不同**：Java 看到一个 key，但 native 真正用变形后的
- **设备绑定密钥**：`ANDROID_ID + UUID + IMEI` 派生 → 必须在原设备/原数据下解
- **加固壳的反调试**：`ptrace` / 检测 frida / 检测 root → `frida-anti-anti-frida` 或 magisk module
- **服务器下发 key**：抓包遇 SSL Pinning → `Universal Android SSL Pinning Bypass` Frida 脚本
- **签名校验自删**：APK 改后启动崩 → 先 patch 签名校验
- **Multidex**：classes2/3.dex 也要看，jadx 默认全反编译
- **App Bundle (.aab)**：`bundletool` 转回 APK 再分析
- **国密 SM4 容易认错**：8 个轮密钥 + 32 round + FK/CK 常量

---

## 10. KB 联动

| 场景 | 跳哪 |
|---|---|
| AES S-box / 自定义对称算法 | `solved/pattern_aes_xor_password_reverse.md` |
| APK 脱壳 + native so 调用实战 | `solved/2022_changancup_mobile_exe_apk.md` |
| AhMyth RAT 风格 APK 拆解 | `wp_index/美亚杯-2024团队赛.md` Q27-Q30 |
| 微信 SQLCipher 解密同思路 | `solved/pattern_wechat_db_decrypt.md` |
| PE 代码混淆识别 | `solved/pattern_malware_static_analysis.md` |
| 时间戳换算 | `skills/timestamps_reference.md` |

---

## 11.5 真题升华（2025–2026）：常见密钥派生套路、Native 加密、Base64 URL

### 11.5.1 密钥派生 6 大套路（取证赛**反复**出现）

| 派生方式 | Java 写法 | Python 还原 | 见于 |
| --- | --- | --- | --- |
| **常量字符串当 key** | `new SecretKeySpec("MyApp2024Key!@#$".getBytes(), "AES")` | 直接拿 16/24/32 字节 | 80% 小作坊 App |
| **MD5(seed).hex() 截前 16/32 字符 → bytes** | `MessageDigest.getInstance("MD5").digest(seed).map { "%02x".format(it) }.joinToString("").substring(0,16).getBytes()` | `md5(seed.encode()).hexdigest()[:16].encode()` | **2026 FIC Q15**（seed = `hotclub_2026_sec`） |
| **SHA-256(seed) 取前 16/32 字节** | `MessageDigest.getInstance("SHA-256").digest(seed).copyOf(16)` | `sha256(seed).digest()[:16]` | 中等水平 |
| **PBKDF2(password, salt, iter, len)** | `SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1").generateSecret(spec)` | `hashlib.pbkdf2_hmac('sha1', pw, salt, iter, 16)` | 高级；多见于支付/钱包 |
| **设备绑定**：`MD5(IMEI + UID + 常量)[:16]` | 同上 + `tm.getDeviceId()` | 必须拿到原设备 IMEI/UID | 微信 EnMicroMsg 经典；多数账号绑定 db |
| **资源串混淆**：`getResources().getIdentifier("xxx", "string", pkg)` 拿到的不是常量 | jadx 反编看不到值 | **去 `resources.arsc` 找 `<string name="xxx">`** | 2026 FIC Q15 |

**资源串挖掘（重要）**：
```bash
# 方式 A：apktool 解包看 xml
apktool d app.apk -o out
grep -rE 'config_seed|sec|key|salt|password' out/res/values/strings.xml

# 方式 B：aapt2 直接 dump
aapt2 dump strings app.apk | grep -iE 'seed|salt|aes|cipher'

# 方式 C：jadx 反编时勾选"反编 res"也能看到
```

**通用 AES-128/ECB/PKCS5 解密模板**：
```python
from hashlib import md5, sha256
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

def derive(seed: bytes, mode: str) -> bytes:
    if mode == "md5_hex":   return md5(seed).hexdigest()[:16].encode()  # 32 字符 hex 截 16 字符
    if mode == "md5_raw":   return md5(seed).digest()[:16]              # 16 字节原始
    if mode == "sha256_16": return sha256(seed).digest()[:16]
    if mode == "sha256_32": return sha256(seed).digest()
    raise ValueError(mode)

def aes_ecb_decrypt(blob: bytes, key: bytes) -> bytes:
    return unpad(AES.new(key, AES.MODE_ECB).decrypt(blob), AES.block_size)
```

### 11.5.2 Native 层加密题（2026 FIC Q17 模板）

**识别流程**：
```
1. strings + readelf -p .rodata libxxx.so   ← 看密文 / 魔数 / key 候选
2. readelf -Ws libxxx.so                    ← 找加解密函数符号（getXxxKey/decrypt/...）
3. llvm-objdump -d / IDA / Ghidra 反编      ← 看是否有 sum += delta / 32 轮 / 64 轮
4. 套魔数对照表识别算法
5. 翻译成 Python 解密 OR frida hook 函数 onLeave 抓明文
```

**Native 加密魔数对照表**：
| 常量 | 算法 |
| --- | --- |
| `0x9E3779B9` | TEA / XTEA / XXTEA |
| `0x61C88647` / `0x61C88649` | XTEA 变体 |
| `0x67452301 0xEFCDAB89 0x98BADCFE 0x10325476` | MD5 init |
| `0x6A09E667 0xBB67AE85 ...` | SHA-256 init |
| `0x428a2f98 0x71374491` | SHA-256 round constants |
| AES S-box（256B 0x63 0x7C 0x77 0x7B 起头） | AES |
| `0xC6A4A793 0x5BD1E995` | MurmurHash |
| `0xEDB88320` | CRC32 |
| `0x52525252 / 0xA5A5A5A5` | RC4 状态？多为自定义异或常量 |
| 32 字节 hex 串 | 大概率是密钥/IV/常数 hash |

**XTEA 解密通用模板**（可直接套到 Native 题）：
```python
import struct

def xtea_decrypt(buf: bytes, key, rounds=64, delta=0x9E3779B9) -> bytes:
    # 假设已经分好 8 字节块；key 为 4 个 u32
    out = bytearray(buf)
    for off in range(0, len(out), 8):
        v0, v1 = struct.unpack_from("<II", out, off)
        s = (delta * rounds) & 0xFFFFFFFF
        for _ in range(rounds):
            v1 = (v1 - ((((v0<<4) ^ (v0>>5)) + v0) ^ (s + key[(s>>11) & 3]))) & 0xFFFFFFFF
            s = (s - delta) & 0xFFFFFFFF
            v0 = (v0 - ((((v1<<4) ^ (v1>>5)) + v1) ^ (s + key[s & 3]))) & 0xFFFFFFFF
        struct.pack_into("<II", out, off, v0, v1)
    return bytes(out)
```

**Frida 兜底（看不懂算法时）**：
```javascript
const lib = Module.findBaseAddress('libsecurity.so');
// 偏移从 readelf -Ws / IDA 看符号或函数地址
['getBackupEndpoint', 'getCommKey', 'decryptBlob'].forEach((name, i) => {
    // 实际用符号名 resolveAddress；这里示例直接偏移
});
Interceptor.attach(lib.add(0x1324), {
    onEnter(args) { this.out = args[0]; },
    onLeave(retval) {
        console.log('decrypt result:\n' + hexdump(this.out, {length: 128}));
    }
});
```

### 11.5.3 URL / 字符串轻度编码（"轻度反取证"基本盘）

| 看到 | 算法 | 一行解 |
| --- | --- | --- |
| `aHR0cHM6Ly...` | Base64（== `https://`） | `base64.b64decode(s)` |
| `=?UTF-8?B?...?=` | MIME Base64 邮件头 | `email.header.decode_header` |
| `%E4%B8%AD...` | URL 编码 | `urllib.parse.unquote` |
| 反序的 `moc.udiab.www//:sptth` | 反转 | `s[::-1]` |
| 偶数移位的 ASCII | Caesar/ROT-N | 暴力 26 个 N |
| 全 hex 字符串（偶数长度） | hex | `bytes.fromhex(s)` |
| 16 字节 + 16 字节交错 | iv ‖ ciphertext（AES-CBC） | 拆头 16 字节当 iv |
| 等长 16 倍数密文 | AES-ECB/CBC | 看是否 PKCS5 padding 末尾 |
| `eyJhbGciOi...` | JWT（Base64URL JSON） | `jwt.decode(s, options={"verify_signature":False})` |
| `{"v":"1","cipher":"..."}` JSON 包 | 自定义协议 | 看 schema |
| 末尾大量 `=` | Base64 大数据 | 同 base64 |

**常见混合**：Base64 后再 AES，或 hex 后 XOR；"先 Base64 后 unzip"也常见。

### 11.5.4 自研聊天 App 双库模式（2026 FIC Q3–Q5）

| 现象 | 答案 |
| --- | --- |
| `databases/index.db`（明文）+ `databases/wk_<32位hex>.db`（SQLCipher 加密） | 索引在明文库，聊天在加密库 |
| 加密库密码 | **就是文件名 hex 部分**（去掉 `wk_` 与 `.db`） |
| 推断逻辑 | 反编 jadx 搜 `setPassword` / `cipher_compatibility` / `OpenHelper` 构造 |

**取证速记**（回插到 §1 密钥藏身处的最高频清单）：
> "**密钥就是文件名本身**"是 2026 比赛新增的小作坊模式。看到 `db_文件名` 是 hex/uuid/包名时，**先把它当密码试**，60% 命中。

---

## 11. 实战证据链 / 报告

最有说服力的"恶意 APK 加密通信"分析报告组合：

```
1. APK 包名 + 签名 + 安装时间                      （身份）
2. AndroidManifest 危险权限清单                    （能力）
3. jadx 反编译关键加密类 + 定位密钥                （静态）
4. Frida hook 抓到的明文 in/out                   （动态）
5. 流量包 SSL 解密后 + 与 Frida 输出一致           （网络层印证）
6. native .so 中的同算法二次确认                   （多层印证）
```
