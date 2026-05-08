# APK 理论基础（取证比赛视角）

> 适用：电子数据取证比赛中需要从 APK 内部"快速定位某个事实"——包名/签名/入口/权限/资源/字符串/嵌入密文/Native 函数/应用类型。
>
> **取证视角**：不是开发者要会写 APK，而是要**会拆**——拿到检材里一个 APK，能在几分钟内找到答案。

---

## 1. APK 整体结构（**速记**）

APK = ZIP 容器，标准目录如下：
```
app.apk
├── AndroidManifest.xml          # 二进制 AXML（清单）
├── classes.dex                  # 主 dex（Dalvik/ART 字节码）
├── classes2.dex / classes3.dex  # 多 dex（method 数 > 65536 时）
├── resources.arsc               # 二进制资源索引
├── res/                         # 资源（layout/drawable/values/...）
│   ├── layout/*.xml             # 二进制 AXML
│   ├── drawable*/               # PNG/WebP/9-patch
│   ├── values/*.xml             # 二进制 AXML
│   └── raw/                     # 原始文件
├── assets/                      # **不被编译**，原样存放（**取证宝藏**）
├── lib/<abi>/*.so               # Native 库（armeabi-v7a/arm64-v8a/x86/x86_64）
├── META-INF/                    # 签名信息 + manifest 摘要
│   ├── MANIFEST.MF              # 各文件 SHA1/SHA256
│   ├── CERT.SF                  # MANIFEST.MF 的摘要
│   ├── CERT.RSA / CERT.DSA / CERT.EC  # 证书（v1 签名）
│   └── *.kotlin_module          # Kotlin 元数据
├── kotlin/                      # Kotlin 元信息（kotlin-reflect 用）
├── stamp-cert-sha256            # Play 官方时间戳证书摘要（部分）
└── DebugProbesKt.bin            # Kotlin 协程调试（部分）
```

> **取证扫描三连**：`unzip -l app.apk | sort -k4 -n -r | head` → 看大文件；`unzip -l app.apk | grep -E 'assets|lib|raw'` → 看可疑数据落地；`apkid app.apk` → 一行识别加固。

---

## 2. AndroidManifest.xml（**最高频解析对象**）

### 2.1 文件格式（AXML 二进制）
APK 内 `AndroidManifest.xml` 是 **AXML 二进制格式**（不是文本 XML），结构：
```
[AXML Header (Chunk Type 0x00080003, file size)]
[String Pool]              # 所有字符串去重存放
[Resource Map]             # attribute name → resource id 映射
[XML Tree Chunks]          # START_NS / START_ELEMENT / END_ELEMENT / END_NS / TEXT 节点流
```

### 2.2 解码工具
| 工具 | 命令 | 备注 |
| --- | --- | --- |
| **aapt**（首选） | `aapt dump xmltree app.apk AndroidManifest.xml` | 输出树形 |
| **aapt dump badging** | `aapt dump badging app.apk` | 一行获取最常用字段 |
| **apktool** | `apktool d -s app.apk` | `-s` 不解 dex；得到文本 XML |
| **AXMLPrinter2.jar** | `java -jar AXMLPrinter2.jar AndroidManifest.xml` | 老牌 |
| **androguard** | `androaxml -i app.apk -o m.xml` | Python |
| **jadx-gui** | 直接打开 APK 看 Manifest 节点 | 取证常用 |

```bash
# 一行抓核心信息
aapt dump badging app.apk | head -20
```
输出含：`package: name='...'`、`versionCode/Name`、`sdkVersion`、`uses-permission`、`launchable-activity`、`application-label`、`application-icon` 等。

### 2.3 取证关注节点
| 节点/属性 | 含义 | 取证用途 |
| --- | --- | --- |
| `<manifest package=>` | 包名 | App 唯一标识 |
| `<uses-permission>` | 权限 | 判断 App 能干什么（恶意？读短信/位置？） |
| `<uses-sdk minSdkVersion targetSdkVersion>` | 版本 | 推断编译时间窗 |
| `<application android:name=>` | 入口 Application 类 | **判加固关键**（StubApp 系列） |
| `<application android:debuggable="true">` | 是否可 `run-as` | 取证可调试 |
| `<application android:allowBackup="true">` | 是否允许 `adb backup` | 取证可备份 |
| `<application android:networkSecurityConfig=>` | 网络安全配置 | 看 SSL pinning / cleartext |
| `<activity android:name= intent-filter>` | 主入口 / Deep Link | App 启动方式 + URL Scheme |
| `<service>` `<receiver>` `<provider>` | 后台/广播/数据提供 | 恶意常驻入口、数据外泄点 |
| `<meta-data android:name=...>` | SDK AppKey / 渠道号 | **溯源宝藏**（Umeng/JPush/Bugly/Channel） |
| `<provider android:authorities=>` | ContentProvider URI | 共享数据接口 |
| `<intent-filter>` 内 `data` `scheme` `host` | URL Scheme / Deep Link | "微信扫码后跳哪" |
| `<queries>` （Android 11+） | 可见 App 列表 | 反取证：嫌疑 App 想看哪些其他 App |

### 2.4 比赛速题
| 题 | 命令 |
| --- | --- |
| App 包名是？ | `aapt dump badging app.apk \| grep package` |
| 用了什么权限？ | `aapt dump permissions app.apk` |
| 启动 Activity 是？ | `aapt dump badging app.apk \| grep launchable` |
| 友盟 / JPush AppKey？ | `aapt dump xmltree app.apk AndroidManifest.xml \| grep -A1 -E 'UMENG_APPKEY\|JPUSH_APPKEY\|BUGLY_APPID'` |
| App 渠道号？ | 同上 + `META-INF/channel*` 文件 |
| 是否声明 SSL pinning？ | 解 `res/xml/network_security_config.xml`（也是 AXML） |
| 是否可侧载调试？ | 看 `debuggable / allowBackup` 标志 |
| Deep Link / URL Scheme？ | 抓所有 `intent-filter > data` |

---

## 3. resources.arsc（资源索引表）

### 3.1 是什么
- 二进制表，记录所有资源 ID（`R.string.xxx`、`R.layout.yyy`）→ 文件路径或字面值的映射。
- 多语言/多分辨率配置（zh/en、ldpi/hdpi/xhdpi）也由此分发。

### 3.2 结构
```
[Header]
[String Pool]              # 所有资源字符串
[Package]                  # 包级元信息（packageId 通常 0x7f 用户 App）
  [Type Spec]              # 类型表（string/layout/drawable...）
  [Type Configuration]     # 各配置变体
  [Entry & Value]
```

### 3.3 取证用法
| 用途 | 怎么做 |
| --- | --- |
| 看 App 文案（隐藏的话术、敏感词） | `aapt dump strings app.apk` 或 `apktool d` 后看 `res/values/strings.xml` |
| 看多语言版本（中/英/俄）→ 推断目标用户 | 看 `res/values-*` 子目录 |
| 看 hardcoded URL/IP | `aapt dump xmltree app.apk res/values/strings.xml` |
| 资源同源（多 APK 是否同套 UI） | 比对 strings.xml + layout SHA |
| 找 ICP 备案号 / 公司名 | strings.xml 内文案 |

```bash
apktool d -s app.apk -o app/
grep -ri 'http://\|https://\|公司\|ICP' app/res/values* | head
```

---

## 4. DEX 文件结构（**逆向核心**）

### 4.1 头部（前 0x70 字节）
| 偏移 | 字段 | 长度 |
| --- | --- | --- |
| 0x00 | magic `dex\n035\0` / `dex\n037\0` / `dex\n038\0` / `dex\n039\0` | 8 |
| 0x08 | checksum (Adler32) | 4 |
| 0x0C | SHA1 of file from offset 0x20 | 20 |
| 0x20 | file_size | 4 |
| 0x24 | header_size = 0x70 | 4 |
| 0x28 | endian_tag = 0x12345678 | 4 |
| 0x2C | link_size / link_off | 8 |
| 0x34 | map_off（指向 map_list） | 4 |
| 0x38 | string_ids_size / off | 8 |
| 0x40 | type_ids_size / off | 8 |
| 0x48 | proto_ids_size / off | 8 |
| 0x50 | field_ids_size / off | 8 |
| 0x58 | method_ids_size / off | 8 |
| 0x60 | class_defs_size / off | 8 |
| 0x68 | data_size / off | 8 |

> **取证识别 dex**：扫内存找 magic `dex\n` + 验 file_size 合法 → 即一个 dex；脱壳时大量用此（参 `android_packer_unpacker.md` §4.6）。

### 4.2 七大索引区
| 区 | 含义 |
| --- | --- |
| **string_ids** | 字符串引用表（指向 string_data，UTF-8 with leb128 长度） |
| **type_ids** | 类型表（指向 string_id 的索引） |
| **proto_ids** | 方法签名（return_type_id + param_type_list） |
| **field_ids** | 字段引用（class + name + type） |
| **method_ids** | 方法引用（class + name + proto） |
| **class_defs** | 类定义（class_idx + access_flags + superclass_idx + interfaces + source_file_idx + annotations + class_data_off + static_values_off） |
| **call_site_ids / method_handles**（DEX 038+） | invoke-dynamic 支持 |

### 4.3 method 内 code_item 关键结构
```
registers_size       // 寄存器数
ins_size             // 入参寄存器数
outs_size            // 出参最大数
tries_size           // 异常表
debug_info_off       // 调试信息（行号/参数名）
insns_size           // 指令长度（16位单位）
insns[]              // Dalvik 字节码
```

> **取证用途**：method `code_off=0` 即为"被抽空"的方法（壳的标志，参 `android_packer_unpacker.md`）；脱壳工具 FART 就是在调用前回填 insns。

### 4.4 多 dex（multidex）
- Android 4.x 单 dex method 上限 65536；超出拆为多 dex。
- `classes.dex` + `classes2.dex` + `classes3.dex` ...
- AndroidX `MultiDex.install` 在 Application 启动时加载。
- 取证：**所有 dex 都要反编译合并查**，不能只看主 dex。

### 4.5 ART 优化产物
| 文件 | 路径 | 含义 |
| --- | --- | --- |
| `*.odex` | `/data/dalvik-cache/` 或 `/data/data/<pkg>/code_cache/oat/` | 优化后的 dex（旧 Dalvik） |
| `*.oat` | 同上 | ART 编译后的 ELF（含原 dex 嵌在 `.rodata` 中） |
| `*.vdex` | 同上 | Verified dex（明文嵌入，**取证可直接抽 dex**） |
| `*.art` | image cache | boot.art 系统镜像 |

```bash
# vdex 抽 dex
vdexExtractor -i base.vdex -o /tmp/    # 输出 .dex
# oat 转 dex
python oat2dex.py base.oat /tmp/
```
> **取证捷径**：嫌疑人 App 加固但已运行过 → `/data/dalvik-cache/` 内的 `vdex` 可能含明文 dex，**比 frida 脱壳更轻松**。

### 4.6 反编译工具
| 工具 | 输出 | 备注 |
| --- | --- | --- |
| **jadx / jadx-gui** | Java | 首选 |
| **GDA** | Java + smali | 国产，jadx 失败时备选 |
| **smali / baksmali** | Smali 汇编 | 改 dex 重打包 |
| **dex2jar** | jar | 老牌，不太稳 |
| **AndroGuard** | Python API | 程序化处理 |

---

## 5. SO 文件结构（ELF）

### 5.1 ELF 总览
APK 内 `lib/<abi>/lib*.so` 是标准 ELF：
```
[ELF Header]                # 0x00, 64 字节
[Program Headers]           # 段定义（LOAD/DYNAMIC/NOTE/...）→ 运行时加载
[Section Headers]           # 节定义（.text/.rodata/.data/...）→ 链接/调试
[.text]                     # 代码
[.rodata]                   # 只读数据（字符串、常量）
[.data] [.bss]              # 可写数据
[.dynsym] [.dynstr]         # 动态符号 / 字符串表
[.plt] [.got]               # 过程链接 / 全局偏移
[.init_array] [.fini_array] # 初始化 / 析构函数列表
[.note.android.ident]       # Android 标识
```

### 5.2 ELF Header（前 64 字节）
| 偏移 | 字段 |
| --- | --- |
| 0x00 | magic `0x7F 'E' 'L' 'F'` |
| 0x04 | EI_CLASS（1=32bit / 2=64bit） |
| 0x05 | EI_DATA（1=little-endian） |
| 0x10 | e_type（1=relocatable / 2=executable / 3=shared） |
| 0x12 | e_machine（0x28=ARM / 0xb7=AARCH64 / 0x03=x86 / 0x3E=x86_64） |
| 0x18 | e_entry（入口） |
| 0x20 | e_phoff（program headers 偏移） |
| 0x28 | e_shoff（section headers 偏移） |
| 0x36 | e_phnum / e_shnum |

```bash
file libtarget.so
readelf -h libtarget.so | head
readelf -d libtarget.so       # DYNAMIC 段，含 NEEDED（依赖库）
readelf -s libtarget.so       # 全部符号
```

### 5.3 JNI 函数 + 注册方式
- **静态注册**：函数名遵循 `Java_<package>_<class>_<method>` 格式，`readelf -s` 直接看到。
- **动态注册**：`JNI_OnLoad` 内调 `RegisterNatives`，函数名可任意（混淆/加固常用）。
- 取证：
  - 静态：`readelf -s lib.so | grep Java_`
  - 动态：必须运行时 hook `RegisterNatives` 抓注册映射。

```bash
# 一行 dump 静态 JNI
nm -D libtarget.so | grep ' T Java_'
```

```js
// frida hook RegisterNatives
var p = Module.findExportByName('libart.so', '_ZN3art3JNI15RegisterNativesEP7_JNIEnvP7_jclassPK15JNINativeMethodi');
Interceptor.attach(p, {
  onEnter(args){
    var n = args[3].toInt32();
    var arr = args[2];
    for (var i=0;i<n;i++){
      var name = Memory.readUtf8String(arr.add(i*Process.pointerSize*3).readPointer());
      var sig  = Memory.readUtf8String(arr.add(i*Process.pointerSize*3+Process.pointerSize).readPointer());
      var fn   = arr.add(i*Process.pointerSize*3+Process.pointerSize*2).readPointer();
      console.log(name, sig, fn);
    }
  }
});
```

### 5.4 关键节区（取证扫）
| 节 | 内容 | 用途 |
| --- | --- | --- |
| `.text` | 代码 | 反汇编/解密入口 |
| `.rodata` | 字符串、AES key、URL | **strings 一把抓** |
| `.data.rel.ro` / `.data` | 可写常量 | 动态注册的方法表 |
| `.init_array` | 初始化函数列表 | 加固入口（自解密、反调试） |
| `.fini_array` | 析构函数 | |
| `.note.gnu.build-id` | 编译指纹（同 build = 同源极强证据） | **同源比对** |

```bash
strings -el libtarget.so | head -50      # UTF-8 字符串
strings -e l libtarget.so                # 16 位 little
readelf -p .rodata libtarget.so | grep -iE 'http|key|aes|cipher|sql'
readelf -p .note.gnu.build-id libtarget.so   # build-id（hex），同源比对
```

### 5.5 反汇编/反编译工具
| 工具 | 用途 |
| --- | --- |
| **IDA Pro** | 老牌，F5 看伪 C |
| **Ghidra** | NSA 开源，免费 |
| **Binary Ninja** | 商业 |
| **Cutter / r2** | radare2 GUI |
| **Hopper**（macOS） | Mac 友好 |
| **GDA** | 国产 + 反编译 |

### 5.6 ABI / 架构
| ABI | 处理器 | e_machine |
| --- | --- | --- |
| `armeabi-v7a` | ARM 32 | 0x28 |
| `arm64-v8a` | ARM 64 | 0xb7 |
| `x86` | Intel 32 | 0x03 |
| `x86_64` | Intel 64 | 0x3e |
| `mips/mips64` | MIPS | 已废弃 |

> **取证挑选**：拿到 lib/ 目录下多 ABI 时，**优先反编 arm64-v8a**（现代真机主流），其次 armeabi-v7a。x86 仅模拟器用，部分加固在不同 ABI 下逻辑不一致。

---

## 6. APK 应用类型（**比赛常考分类**）

### 6.1 按发行形式
| 类型 | 文件名 | 说明 |
| --- | --- | --- |
| **APK** | `*.apk` | 标准 ZIP，最常见 |
| **AAB**（Android App Bundle） | `*.aab` | Google Play 上传格式；用户下载时由 Play 切片成 APK；**取证从设备上拿到的仍是 APK split** |
| **APKS / APKM / APKZ** | 多文件包 | 第三方市场打包多 split + base |
| **XAPK** | ZIP 容器 | APK + obb（资源） |
| **APEX** | `*.apex` | 系统模块（Android 10+）；可视为加密 zip 含 ext4 image |
| **HAP**（鸿蒙 NEXT） | `*.hap` | OpenHarmony 应用包；ZIP，含 ArkTS 字节码（参 `other_smart_devices.md`） |

### 6.2 按"split apk"组成
- 设备上 `/data/app/<pkg>-<hash>/` 内可见：
  - `base.apk`（主 APK）
  - `split_config.<abi>.apk`（按架构）
  - `split_config.<dpi>.apk`（按分辨率）
  - `split_config.<lang>.apk`（按语言）
  - `split_<dynamic_feature>.apk`（动态特性模块）
- 取证：**多 split 必须全拿**，否则装不回去 + 漏字符串/资源。

```bash
adb shell pm path com.foo.bar
# 输出：
# package:/data/app/com.foo.bar-XXX/base.apk
# package:/data/app/com.foo.bar-XXX/split_config.arm64_v8a.apk
# package:/data/app/com.foo.bar-XXX/split_config.zh.apk
# 全部 pull 出来
```

### 6.3 按"安装位置"
| 类型 | 位置 | 含义 |
| --- | --- | --- |
| **系统应用** | `/system/app/` `/system/priv-app/` | ROM 预装，签名一般是平台签名 |
| **厂商应用** | `/vendor/app/` `/product/app/` | 厂商定制 |
| **用户应用** | `/data/app/` | 安装的 |
| **运营商应用** | `/oem/app/` | 运营商定制（极少） |
| **下载更新** | `/data/app/<pkg>--m/` | 用户更新过的版本（覆盖系统 ROM 版） |

### 6.4 按"运行时类型"（**比赛常考"是不是原生 App"**）
| 类型 | 特征 | 取证差异 |
| --- | --- | --- |
| **原生 Java/Kotlin** | classes.dex 内全是 `Activity`/`Fragment` | 标准反编译 |
| **Flutter** | `lib/<abi>/libflutter.so` + `lib/<abi>/libapp.so` + `assets/flutter_assets/`（含 `kernel_blob.bin`） | Java 层壳薄；逻辑在 libapp.so（Dart AOT），用 **blutter**（首选，输出 ASM+objs.txt+frida hook 模板）/ reFlutter（旧）/ Doldrums 解；典型 `com.carriez.flutter_hbb`（RustDesk）。详见 `competition_2024_2025_writeups.md` §2 |
| **React Native** | `assets/index.android.bundle`（JS Bundle，可能 hbc 字节码） + `lib/<abi>/libreactnativejni.so` | JS bundle 解析；Hermes 字节码用 hbcdump |
| **Cordova / Ionic / WebView 壳** | `assets/www/` 内 HTML/CSS/JS | **所有逻辑在 assets/www**，按 web 取证 |
| **Unity 游戏** | `lib/<abi>/libunity.so` + `lib/<abi>/libil2cpp.so` + `assets/bin/Data/Managed/Metadata/global-metadata.dat` | il2cpp 反编译用 Il2CppDumper |
| **Cocos2d-x / Cocos Creator** | `assets/src/` 含 lua/js | lua 字节码解 |
| **Xamarin / .NET MAUI** | `lib/<abi>/libxamarin*.so` + `assemblies/*.dll` | dnSpy / ILSpy 反编 .NET |
| **Qt** | `lib/<abi>/libQt5*.so` | 罕见 |
| **小程序容器**（WeChat/Alipay 子包） | 主 APK 内含小程序运行时 + 安装时下载 wxapkg | 见 `popular_apps_forensics.md` 微信小程序部分 |
| **HAP 容器** | `*.hap` 在 APK 内（极少） | 鸿蒙生态 |

### 6.5 识别命令
```bash
# 一行识别 runtime
unzip -l app.apk | grep -E 'libflutter|libapp\.so|libreactnative|index\.android\.bundle|libunity|libil2cpp|libxamarin|assets/www|assets/flutter_assets|assets/bin/Data'
```

---

## 7. APK 签名块（v2/v3，**取证关键**）

### 7.1 ZIP 末尾结构
```
[ZIP Entries]
[APK Signing Block]      # ← v2/v3 在这（v1 在 META-INF/）
[Central Directory]
[End of Central Directory (EoCD)]
```

### 7.2 v2 Signing Block 二进制布局
```
size of block (8 bytes)
[ID-value pairs]
  ID 0x7109871a -> v2 signature
  ID 0xf05368c0 -> v3 signature
  ID 0x71777777 -> walle 渠道（**取证常用**）
  ID 0x42726a (其它) -> 各厂家自定义
size of block (8 bytes)
magic: "APK Sig Block 42"
```

### 7.3 提取
```bash
apksigner verify --print-certs --verbose app.apk
# 看到所有 v1/v2/v3 签名 + 公钥指纹

# 解 walle 渠道
java -jar walle-cli.jar show app.apk
```

---

## 8. 比赛常见题型与解法

### 8.1 类型 A：基础信息题
| 问 | 解 |
| --- | --- |
| App 包名 | `aapt dump badging app.apk \| grep package` |
| 版本号 | 同上 |
| 最低/目标 SDK | 同上 |
| 主 Activity | `aapt dump badging app.apk \| grep launchable` |
| 全部权限 | `aapt dump permissions app.apk` |
| 是否 debuggable / allowBackup | `aapt dump xmltree app.apk AndroidManifest.xml \| grep -E 'debuggable\|allowBackup'` |

### 8.2 类型 B：签名/作者/同源
- 见 `android_app_attribution.md`；
- 一行：`apksigner verify --print-certs app.apk`。

### 8.3 类型 C：加固识别
- 见 `android_packer_unpacker.md`；
- 一行：`apkid app.apk`。

### 8.4 类型 D：找 hardcoded URL/IP/Key
```bash
# 资源文件
apktool d -s -o app/ app.apk
grep -ri 'http://\|https://' app/res/ app/assets/ | head

# dex 内字符串
strings classes*.dex | grep -oE 'https?://[^"]+' | sort -u

# so 内
strings -el lib/arm64-v8a/*.so | grep -oE 'https?://[^"]+' | sort -u
```

### 8.5 类型 E：判断"App 是 Flutter / RN / Unity / 原生"
- 一行命令（§6.5）；
- 取证应据此选不同后续路线。

### 8.6 类型 F：找出 SDK AppKey / 渠道号
- aapt dump xmltree → AndroidManifest meta-data；
- walle / VasDolly 解渠道。

### 8.7 类型 G：DEX 是不是被抽空（method 数 0）
```bash
androguard analyze app.apk
> a.classes
# 若主 dex 仅 Stub Application 类 → 加固
```

### 8.8 类型 H：判断 SO 是否被加密 / OLLVM
```bash
file lib/arm64-v8a/*.so      # 看是否标准 ELF
readelf -S libtarget.so      # 节多/节名乱码 = 已加密
strings .rodata 部分 | head  # 内容是否大量乱码
# OLLVM 特征：函数内大量 dispatcher switch + 虚假分支，IDA 看 CFG 一片混乱
```

### 8.9 类型 I：从已运行的设备恢复 dex
```bash
# 取 vdex（明文 dex 嵌入）
adb pull /data/app/<pkg>--m/oat/arm64/base.vdex
vdexExtractor -i base.vdex -o /tmp/
ls /tmp/*.dex
```

### 8.10 类型 J：从 split apk 集合反编
```bash
adb shell pm path <pkg>
# 把 base + split 都 pull
# 合并装回模拟器再分析（或 jadx 直接喂 base.apk + split 数组）
jadx -d out base.apk        # base 通常含主代码
```

---

## 9. 命令速查

```bash
# 综合一行：包+版+签名+权限
aapt dump badging app.apk | head -25
apksigner verify --print-certs app.apk
apkid app.apk

# Manifest 解码
aapt dump xmltree app.apk AndroidManifest.xml > manifest.txt
apktool d -s -o app/ app.apk     # 不解 dex；得到文本 manifest 与 res
java -jar AXMLPrinter2.jar AndroidManifest.xml > manifest.xml

# resources.arsc / strings
aapt dump strings app.apk | head
apktool d -s -o app/ app.apk && grep -ri 'http' app/res/values* | head

# DEX 分析
androguard analyze app.apk          # 交互
jadx-gui app.apk
GDA app.apk

# DEX 多文件检查
unzip -l app.apk | grep -E 'classes[0-9]*\.dex'

# DEX 头识别（已 dump 的内存）
xxd raw_mem.bin | head -2
python -c "import sys;d=open(sys.argv[1],'rb').read(8);print(d)" file.dex

# vdex / oat
vdexExtractor -i base.vdex -o /tmp/
oatdump --oat-file=base.oat --output=base.oat.dump

# SO 分析
file lib/arm64-v8a/lib*.so
readelf -h lib/arm64-v8a/libtarget.so
readelf -d lib/arm64-v8a/libtarget.so
readelf -s lib/arm64-v8a/libtarget.so | grep ' T Java_'
strings -el lib/arm64-v8a/libtarget.so | head
nm -D lib/arm64-v8a/libtarget.so | grep -i jni
readelf -p .note.gnu.build-id libtarget.so

# Runtime 识别
unzip -l app.apk | grep -E 'flutter|libapp\.so|index\.android\.bundle|libunity|libil2cpp|libxamarin|assets/www'

# split apk 提取
adb shell pm path <pkg>
adb pull /data/app/<pkg>--m/

# 渠道
java -jar walle-cli.jar show app.apk
unzip -p app.apk META-INF/channel*

# 完整一键报告
docker run -it -p 8000:8000 opensecurity/mobile-security-framework-mobsf
```

---

## 10. 常见坑

1. **AndroidManifest 是 AXML 不是文本**：直接 `cat` 看到乱码；必须 aapt/apktool 解码。
2. **`apktool d` 反 manifest 失败**：framework 缺失；`apktool if framework-res.apk` 装一下。
3. **AAB 不能直接装/反编**：解开成 split APK；用 `bundletool` 或在设备 `pm path` 拿设备已安装的 split。
4. **multidex 漏看 classes2.dex**：很多反编项只默认看主 dex；必须全拿。
5. **vdex 扔进 jadx 不识别**：先 vdexExtractor 抽出 .dex 再喂。
6. **SO 多 ABI 都拿**：x86/x86_64 仅模拟器跑；arm64-v8a 才是真机；某些 App 不同 ABI 实现不同（仅 arm 加固，x86 不加）。
7. **静态 JNI 函数名混淆**：动态注册下 `readelf` 看不到 Java_ 前缀；用 frida hook RegisterNatives 抓。
8. **大字符串被加密**：`strings .rodata` 看不到明文；动态运行时 hook 字符串构造点。
9. **Flutter / RN / Unity 的 Java 层壳薄**：以为反编了 dex 就完事，**真逻辑在 .so / bundle / 自家字节码里**。
10. **XAPK 安装包**：base.apk 外还有 `Android/obb/<pkg>/` 资源；只拿 base 漏数据。
11. **APEX**：mount 后里面是 ext4 镜像；普通 unzip 看不出全貌。
12. **resources.arsc 同名资源覆盖**：split apk 的 resources.arsc 会与 base 合并；只看 base 漏多语言/多 dpi 资源。
13. **build-id 同源**：同一编译器 + 同一源码 → 完全相同 build-id；强同源证据；**同源不一定同作者**（开源库被多家用同样情况）。
14. **`unzip` 有时报 CRC 错**：APK 末尾 v2 签名块对部分老 unzip 不友好；用 `7z` / `aapt` 直接读。
15. **嵌入二级 payload**：`assets/` 内有 `*.jar` `*.apk` `*.so` `*.dex` `*.zip`，多为加固二级 dex 或恶意 dropper；务必 `unzip -l` 全列。

---

## 11. 决策流（拿到 APK 第一眼）

```
1. unzip -l app.apk | head            # 看大致结构
2. aapt dump badging app.apk | head   # 包名/版本/权限/入口
3. apksigner verify --print-certs     # 签名指纹
4. apkid app.apk                      # 加固/反检测识别
5. 看 AndroidManifest.xml             # application class / meta-data / Deep Link
6. unzip -l 看 lib/ 内 ABI            # 是否含 SO；多 ABI 选 arm64
7. unzip -l 看 assets/                # 是否含二级 payload / Flutter / RN / Unity
8. 反编 dex (jadx-gui)                # Java 逻辑
9. 反编 SO (IDA / Ghidra)             # 关键算法
10. 题目要"运行时数据" → 装到模拟器 + frida
```

---

## 12. 交叉链接
- `android_analysis_environment.md`：工具/环境怎么装
- `android_packer_unpacker.md`：壳 → dex 还原
- `apk_crypto_analysis.md`：拿到代码后找 key 算法
- `android_app_attribution.md`：签名/同源/溯源
- `popular_apps_forensics.md` / `wechat_deep_dive.md`：具体 App 沙盒
- `database_forensics.md`：dex 找到 db 后的解析
- `extraction_methods.md`：从设备先取出 split APK
- `quick_reference.md`：顶层速查
