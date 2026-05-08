# 2026 FIC 第六届全国网络空间取证大赛初赛 — 手机/APK 取证笔记

> 资料来源：玫幽倩的小博客 [2026FIC初赛（全流程wp）](https://mei-you-qian.github.io/2026/05/07/2026FIC%E5%88%9D%E8%B5%9B/)（2026-05-07 发布；当前已知最新真题 writeup）。
>
> 案件设定：李安弘（沿用 2025 FIC 检材人物）开发/运营黄色直播 + USDT 收款 + 钓鱼推广 + 无人机航拍 + AI 工具混合案。
>
> 赛卷分类：**计算机取证 / 手机取证 / 服务器取证 / 互联网取证 / 二进制程序取证** —— **首次出现"二进制程序取证"独立大类**（之前 FIC 都把它并到计算机部分）。

---

## 1. 题型与解法对照表（手机/APK 部分）

| # | 题问 | 关键技术 / 路径 | 命中我已有 KB |
| --- | --- | --- | --- |
| 1 | 手机型号 | 火眼直接读出 RedmiNote7Pro | `quick_reference.md` 关键源文件 |
| 2 | 计划前往迪拜的日期 | 小米自带备忘录 `todo.db` | §2.1 新增（小米备忘录路径） |
| 3 | 与网站搭建人员沟通的 App 安装日期 | 双库 App（明文索引 + 加密聊天库），密码=文件名 | §2.2 新增 |
| 4 | 聊天数据库文件名 | `wk_<32 位 hex>.db` | §2.2 |
| 5 | 数据库解密密码 | **密码=文件名 hex** 同上 | §2.2 |
| 6 | 云服务器商家备用钱包地址 | 解密后 message 表 message_seq 定位 | 已写 popular_apps |
| 7 | 第一次转账的交易 hash 前 6 位 | 聊天截图图片名解析 + EXIF | 已写 |
| 8 | AI 软件中李安弘主动提问几次 | **PocketPal AI** 本地 db | §2.3 新增 |
| 9 | 本地调用的 AI 模型及版本 | PocketPal `models/` 目录 → Qwen3.5 | §2.3 |
| 10 | 无人机飞行县域 | DJI **FlightRecord 飞行日志** + 解析 | §2.4 新增（升级 dji_forensics） |
| 11 | 视频类色情 APK 敏感权限多选 | jadx 看 AndroidManifest | 已写 apk_internals |
| 12 | 网络不可用时加载的本地离线页面路径 | onCreate WebView 初始化 + `file:///android_asset/www/index.html` | §2.5 新增（混合 App / WebView 取证） |
| 13 | 上传地址编码方式 | **Base64** 字段 `aHR0cHM6...` → `https://api.sp-live88.com/collect/userdata` | 已写 quick_reference |
| 14 | 本地存储用户信息的 SQLite 表名 | jadx 搜 `CREATE TABLE` → `user_collection` | 已写（关键字搜索清单） |
| 15 | assets/config.dat 解密拿 USDT 钱包 | **AES-128/ECB/PKCS5**，key = `MD5("hotclub_2026_sec")[:16]`（赛中 key=`3ffc0b996b851d80`） | §2.6 新增（resources.arsc 找种子串） |
| 16 | 前端 JS 调用原生方法获取通讯录 | **`@JavascriptInterface`** 暴露 `AppNative.getContactsList()` | §2.5 |
| 17 | 主上传失败时备用服务器域名+端口 | **Native libsecurity.so**: 一层异或（`(i&0x0f)^0x55`）+ XTEA 64 轮（key 4×u32 在 .rodata，magic delta=0x61c8864f）→ `https://backup.sp-live88.xyz:8443/api/v2/collect/userdata` | §2.7 **新增**（首次出现 Native 层 XTEA 取证） |

---

## 2. 新题型与新方法（**这是 2026 FIC 真正新增的部分**）

### 2.1 小米/系统备忘录与 todo.db
- 小米备忘录数据库路径：
  - 备忘录正文：`/data/com.miui.notes/databases/notes.db`（表 `notes`）
  - **TODO（待办）**：`/data/com.miui.notes/databases/todo.db`（表 `todo` / `task`） ← **2026 FIC Q2 直接读这里**
- 与 `competition_2024_2025_writeups.md` §11 备忘录速查表互为补充。
- **取证速胜**：题目问"计划做某事的日期"先翻 `todo.db`。

### 2.2 双库 App "明文索引 + 加密聊天" 模式（**新模式**）
> 嫌疑人定制聊天 App 的常见结构：
- **索引库**（明文）：`<pkg>/databases/index.db` 含会话列表、用户列表；
- **加密聊天库**：`<pkg>/databases/wk_<32 位 hex>.db` 用 SQLCipher 加密；
- **关键发现**：很多自研 App **直接把聊天库文件名 hex 字符串当作 SQLCipher 密码**（懒人式实现）。

**取证流程**：
1. `file wk_*.db` 看是否 SQLCipher（魔数被改变，看不到 `SQLite format 3`）；
2. 用 `sqlcipher` + 密码 = 文件名 hex（去掉 `wk_` 前缀和 `.db` 后缀）尝试；
3. 若不行才反编 APK 看 `setPassword` 实际派生方式。

```bash
sqlcipher wk_9628874a3c6b403593766496fa985893.db
sqlite> PRAGMA key = '9628874a3c6b403593766496fa985893';
sqlite> .tables
sqlite> SELECT * FROM message ORDER BY message_seq;
```

**回插到 `database_forensics.md` 的"SQLCipher 密码常见构造"清单**：
| 密码派生 | 案例 |
| --- | --- |
| `MD5(IMEI+UIN)[:7]` | 微信 EnMicroMsg |
| `KEY` 直接硬编码字符串 | 多数小作坊 App |
| **文件名本身（hex）** | **2026 FIC 自研聊天 App** ← 新增 |
| `MD5(packageName + versionCode)[:16]` | 部分赌博 App |
| `keystore` AndroidKeyStore 派生 | 银行类 App |

### 2.3 移动端本地 AI 模型取证（**首次出现**）
| 项 | 说明 |
| --- | --- |
| **PocketPal AI** | 开源安卓本地 LLM App（GitHub a-ghorbani/pocketpal-ai） |
| 包名 | `com.pocketpalai` 或 `com.a_ghorbani.pocketpalai` |
| 模型存储 | `/data/<pkg>/files/models/`（GGUF 格式） |
| 对话记录 | `/data/<pkg>/databases/chat.db`（或 Realm/MMKV） |
| 模型识别 | 看 `models/` 下 `*.gguf` 文件名 + 文件头 magic `GGUF` + version |
| 题型 | "向 AI 提问几次" → 数 message 表里 role='user' 的行；"使用什么模型" → `model_config.json` / `models/` 目录 |

**类似产品**：
- MLC Chat（包名 `ai.mlc.mlcchat`）
- Llama.cpp Android 客户端
- Maid（`com.danemadsen.maid`）
- LM Studio（PC 端，但有移动端孪生）

**取证方法**：
```bash
# GGUF 文件元数据
python3 -c "import gguf; r=gguf.GGUFReader('m.gguf'); print(r.fields['general.name'])"
# 或字符串看头
xxd Qwen3.5.gguf | head -20  # 前面有 GGUF magic + 模型名 + 量化方式
```

### 2.4 DJI 无人机飞行轨迹取证（**作为独立题型升级**）
- 检材路径（手机端 DJI Fly / DJI Go 4）：
  - `data/dji.go.v5/files/FlightRecord/<DJIFLY_log_xxx>.txt`（小机型/早期）
  - `data/dji.go.v5/files/FlightRecord/<binary>.DAT`（飞控原始日志，最常见）
  - `Android/data/dji.go.v5/files/`（外存）
- 文件类型：
  - **`.txt` 飞行日志**：JSON-like 文本，可读；
  - **`.DAT` 飞控日志**：二进制，加密；DJI 官方限制访问。
- **解析工具**：
  - **DatCon / CsvView**（Win，`.DAT` 转 csv）
  - **PhantomHelp.com / airdata.com**（在线上传解析）
  - **dji-flight-log-decoder**（开源，部分支持）
  - **DJI FlightRecordParsingLib**（github.com/dji-sdk，需申请 SDK Key）
  - **DJIrecord**（民间脚本，部分机型可用）
- 题答取经纬度：
  ```
  经纬度 → 反向地理编码（高德/百度 API / Nominatim）
  37.7966, 110.3707 → 陕西省榆林市米脂县
  ```
- **更新工作区已有 `f:\电子取证\FIC2026-mobile_work\dji_q10.py`**：可加上自动反向地理编码。

### 2.5 混合 App / WebView 取证（**JavaScriptInterface 漏洞类**）
> 2026 FIC Q12-Q16 一连串"WebView App 反编"题，是经典 hybrid app 取证模式。

#### 关键代码点（jadx 搜索）
| 找 | 关键字 |
| --- | --- |
| WebView 初始化 | `WebView` `webView.getSettings()` `setJavaScriptEnabled(true)` |
| 加载 URL | `loadUrl(` `loadDataWithBaseURL(` |
| **网络判断 + 离线页面** | `NetworkInfo` `ConnectivityManager` `file:///android_asset/` |
| **JS Bridge 暴露** | `addJavascriptInterface(` `@JavascriptInterface` |
| 桥接对象暴露的方法名 | `getContactsList` `getSmsList` `getDeviceId` `getLocation` |

#### 离线页面路径
- 标准：`file:///android_asset/www/index.html` / `file:///android_asset/offline.html`
- 解 APK 看 `assets/www/`（直接 unzip 就拿）。

#### JS Bridge 漏洞
```java
// Java 侧
webView.addJavascriptInterface(new AppNative(this), "AppNative");

class AppNative {
    @JavascriptInterface
    public String getContactsList() { ... }  // ← 题问的"暴露给前端的通讯录方法"
    @JavascriptInterface
    public String getSmsList() { ... }
}
```
```html
<!-- HTML 侧 assets/www/index.html -->
<script>
window.AppNative.getContactsList();  // 直接调
</script>
```
**取证速答**：jadx 全局搜 `@JavascriptInterface` 列出全部暴露方法，按题意筛"通讯录/短信/位置"对应的方法名。

#### 上传地址 Base64 编码（Q13）
- 字符串 `aHR0cHM6Ly...` 标志性 Base64 头（=== `https://`）；
- 一行 `python3 -c "import base64; print(base64.b64decode('aHR0cHM6Ly9hcGku...'))"` 解。
- 属于"轻度反取证"，赛场常见。

### 2.6 assets/config.dat AES 解密 + resources.arsc 找种子串（**经典套路**）
> 2026 FIC Q15 完整链：
> `config_seed`（资源串） → `m312t()` 即 `MD5(seed).hex()[:16].encode()` → 16 字节 AES key → `AES/ECB/PKCS5Padding` 解 `config.dat` → JSON 含 USDT 地址。

**关键技术点**：
1. **`getResources().getIdentifier("config_seed", "string", packageName)`** 这种动态拿资源串，jadx 反编看不出常量值；
2. 需要去 **`resources.arsc`** 里找：
   ```bash
   apktool d app.apk -o out
   grep -rE 'config_seed|hotclub_2026_sec' out/res/values/
   # 或直接读编译后的
   aapt2 dump strings app.apk | grep config_seed
   ```
3. **`MD5(x).hex()[:16].encode()`** 是常见伪密钥派生（**实际只有 8 字节熵**，但 AES 接受任意 16 字节）；爆破成本极低。
4. **AES/ECB/PKCS5Padding + 16 字节 key** = AES-128。

**通用解密脚本骨架**：
```python
from hashlib import md5
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

def derive_key(seed: str) -> bytes:
    return md5(seed.encode()).hexdigest()[:16].encode()  # 注意是 hex 字符串再切片

def aes_ecb_decrypt(data: bytes, key: bytes) -> bytes:
    return unpad(AES.new(key, AES.MODE_ECB).decrypt(data), 16)

with open("config.dat", "rb") as f:
    print(aes_ecb_decrypt(f.read(), derive_key("hotclub_2026_sec")).decode())
```

**回插到 `apk_crypto_analysis.md`** 的"常见伪派生"清单。

### 2.7 Native 层 XTEA 解密备用服务器（**2026 FIC 最难题，首次 Native 题型**）

> Q17 设计：主上传服务器在 Java 层 Base64（Q13），备用服务器藏在 `libsecurity.so` 的 `.rodata` 段，用两层加密：

#### 流程拆解
1. **静态分析**：
   ```bash
   # 看 .so 暴露的符号
   readelf -Ws lib/arm64-v8a/libsecurity.so | grep -i 'getBackup\|Endpoint\|CommKey'
   # 看 .rodata 内容
   readelf -x .rodata lib/arm64-v8a/libsecurity.so
   # 反编伪代码（IDA / Ghidra / objdump）
   llvm-objdump -d --no-show-raw-insn --print-imm-hex lib/arm64-v8a/libsecurity.so
   ```
2. **算法识别要点**：
   - 看 `delta = 0x61C88649` / `sum += delta` / 32 或 64 轮 → **TEA / XTEA / XXTEA 家族**；
   - 0x9E3779B9 = TEA delta；0x61C88649 = XTEA 变体；
   - 4 个 u32 key 数组（`0xdeadbeef 0xcafebabe 0x12345678 0x9abcdef0`）。
3. **预处理 XOR**：常见前置去混淆：
   ```c
   for (i=0; i<n; i++) buf[i] ^= (i & 0x0f) ^ 0x55;
   ```
4. **解密**：用与加密对偶的 XTEA decrypt（s 从 sum=delta*rounds 起，倒数到 0）。

#### 通用 Native 字符串保护识别速查
| 看到这个常量 | 推断算法 |
| --- | --- |
| `0x9E3779B9` | TEA / XTEA / XXTEA |
| `0x61C88647`/`0x61C88649` | XTEA 变体 |
| `0x67452301 0xEFCDAB89 0x98BADCFE 0x10325476` | MD5 |
| `0x6A09E667 0xBB67AE85 ...` | SHA-256 |
| `0x428a2f98 0x71374491 ...` | SHA-256 round constants |
| 16-byte `0x63 0x7C 0x77 0x7B ...` | AES S-box |
| `0xa56363c6 0x847c7c f8...` | AES T-box |
| `0xC6A4A793 0x5BD1E995` | MurmurHash |
| `0xEDB88320` | CRC32 |

#### 取证比赛 Native 题型最佳实践
1. 先 `strings` + `readelf -p .rodata` 看常量；
2. 如果魔数明显 → 直接套该算法解密脚本；
3. 如果是定制混淆 → IDA 反编 + 翻译为 Python；
4. **能 frida 就 frida**：直接 hook 加解密函数 `onLeave` 拿明文，比静态翻译快 10 倍：
   ```javascript
   const lib = Module.findBaseAddress('libsecurity.so');
   Interceptor.attach(lib.add(0x1324), {
       onLeave: function(retval) {
           console.log(hexdump(retval, {length: 64}));
       }
   });
   ```

**回插到 `apk_crypto_analysis.md`** 与 `android_reverse_analysis.md`。

### 2.8 二进制程序取证 / Win32 GUI 加密程序（**首次独立大类**）
> 2026 FIC 第 5 大类"二进制程序取证"，让取证人员去拆 Win32 GUI 加密程序：
- 用 **DIE (Detect It Easy)** 一键看编译时间、链接器、壳；
- IDA 看 `WinMain` → `RegisterClass` → `WndProc` → `WM_COMMAND` 路由 → 按钮 ID 10001 处理；
- 加密算法：**AES-128/ECB**（轮密钥扩展为 11×16=176B = 0xB0）+ 一层异或（`buf[i] ^= 0x7F + 3*i`）；
- 解密拿密码 = `PleaseRunAsAdmin`；
- 解密文件后缀 `.vhd` → 挂载 vhd 拿钱包数据。

**取证流程**：
```
DIE 看时间戳 → IDA 反编 WinMain → 定位密码校验函数 →
识别 AES 轮密钥扩展 + 异或 → Python 写对应解密 → 拿到密码 →
原程序运行解密文件 → 挂载 vhd → 内部数据
```

**关键识别点**：
- AES 密钥扩展 0xB0 长度（AES-128）/ 0xF0（AES-192）/ 0x100（AES-256）；
- AES SubBytes 用 S-Box（256B 常量表）；
- ShiftRows + MixColumns 看到 GMul（×2、×3）数学；
- 看到这些就别试 DES/RSA 了，直接套 AES 解密。

**新增独立 KB 建议**：`pe_binary_forensics.md` 或并入 `android_reverse_analysis.md` 加 PE/Mach-O 章节。

---

## 3. 与已有 KB 的差异 / 增量

| 已有 KB | 2026 FIC 题中暴露的更新点 |
| --- | --- |
| `apk_internals.md` §6.4 应用类型表 | 加 **Hybrid WebView App**（assets/www + JavaScript Interface）独立行 |
| `apk_crypto_analysis.md` | 加"密钥派生套路"小节：MD5(seed).hex()[:16] / 文件名当 key / Native XTEA |
| `database_forensics.md` SQLCipher | 加"密码常见构造"清单（含**文件名 hex**） |
| `android_reverse_analysis.md` | 加"native 字符串保护识别"魔数对照 + frida 兜底 |
| `popular_apps_forensics.md` | 加 PocketPal / MLC Chat 类**移动 LLM** 取证 |
| `competition_2024_2025_writeups.md` §12 DJI | 升级为完整方法 §2.4 |
| `quick_reference.md` | 加"双库 App 加密聊天 = 文件名密码"速记 |
| 待建 `iot_forensics.md` / `pe_binary_forensics.md` | 二进制程序独立大类已成赛卷标配，需要专门 KB |

---

## 4. 取证比赛"题路"演化（2021 → 2026）

| 年份 | APK 题特征 |
| --- | --- |
| 2021 长安杯 | 反编 APK + 抓包还原回传逻辑 + jadx 直读 SQLCipher key |
| 2022 长安杯 | APK 加固 + 多关 FLAG（CTF 风） |
| 2024 FIC | DCloud 流应用 + AI 换脸（PC）+ Rocket.Chat |
| 2025 盘古石 | **Flutter/Dart APK + blutter** + RustDesk + IoT + macOS PyInstaller |
| 2025 獬豸杯 | 360 加固 + 流量包黑客模拟器 + APK 包名/签名/api 多基础 |
| 2025 FIC | VeraCrypt 套娃 + Web3 域名 + 备忘录密码 |
| **2026 FIC** | **Hybrid WebView APK（JS Bridge / Base64 url / AES config / Native XTEA / 移动端本地 LLM / 自研聊天 App 双库 / DJI 飞行日志 / Win32 PE 加密程序**） |

**趋势**：
1. **APK 反编正变成"全栈"**：Java + JS + Native + 资源串 + 静态加密 + 动态 hook 一题打通；
2. **AI 工具痕迹**从 PC 端蔓延到手机端（PocketPal、本地 LLM）；
3. **二进制程序逆向**已升格为独立赛卷大类，要求会 IDA + AES 解密；
4. **DJI/IoT/无人机/智能门锁**形成稳定题源；
5. **Base64 / AES-ECB / XTEA / 文件名当 key** 等"轻度对抗"成为基本盘——纯逆向技巧权重在上升。

---

## 5. 速查命令（取自本届真题）

```bash
# ---- APK ----
# 解 APK 看资源串
apktool d app.apk -o out
grep -rE 'config_seed|backup|api|wallet' out/res/values/

# Java 关键字搜（jadx-gui）
# CREATE TABLE / addJavascriptInterface / @JavascriptInterface
# loadUrl / file:///android_asset / Base64

# ---- so ----
strings lib/arm64-v8a/libsecurity.so | grep -E 'http|api|backup|key'
readelf -x .rodata lib/arm64-v8a/libsecurity.so
llvm-objdump -d --no-show-raw-insn --print-imm-hex lib/arm64-v8a/libsecurity.so
# 看常量魔数推断算法（XTEA delta=0x61C88649 等）

# ---- Base64 url ----
python3 -c "import base64; print(base64.b64decode('aHR0cHM6Ly9hcGkuc3AtbGl2ZTg4LmNvbS9jb2xsZWN0L3VzZXJkYXRh').decode())"

# ---- assets/config.dat AES-128/ECB ----
python3 -c "
from hashlib import md5
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
k = md5(b'hotclub_2026_sec').hexdigest()[:16].encode()
d = open('config.dat','rb').read()
print(unpad(AES.new(k,AES.MODE_ECB).decrypt(d),16).decode())
"

# ---- 自研聊天双库 ----
file *.db
sqlcipher wk_<hex>.db
# PRAGMA key='<同 hex>';

# ---- DJI 飞行日志 ----
# DAT 二进制：DatCon / CsvView / PhantomHelp / dji-flight-log-decoder
# txt 飞行日志：直接 jq / grep 经纬度
grep -E 'latitude|longitude|GPS' DJIFLY_*.txt

# ---- Win32 PE ----
DIE.exe SampleVC.exe                       # 编译时间 / 加壳 / 编译器
# IDA → WinMain → ButtonID(10001) → 加密函数
# 识别 AES 0xB0 轮密钥
```

---

## 6. 待办（基于本届真题反推应建/应升级 KB）

- [ ] 建 `pe_binary_forensics.md`（Win32 GUI 加密程序赛题逐步成型）
- [ ] 升级 `dji_forensics.md`（含 .DAT 与 .txt 飞行日志解析 + 反向地理编码 + 题型）
- [ ] 升级 `apk_crypto_analysis.md` 加"派生套路 + Native XTEA + Base64 URL"
- [ ] 在 `popular_apps_forensics.md` 加"移动端本地 LLM 取证"小节
- [ ] 在 `database_forensics.md` 加 SQLCipher "密码 = 文件名 hex" 套路

---

## 7. 引用真题

- 2026FIC 初赛全流程 wp（玫幽倩）：https://mei-you-qian.github.io/2026/05/07/2026FIC%E5%88%9D%E8%B5%9B/
- 案件人物李安弘延续自 2025 FIC，可见出题方刻意打造"叙事连续性"。
