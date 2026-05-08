# 其他智能手机/智能终端取证速查

> 适用：检材不是主流 Android / iOS 时，常见为 **HarmonyOS / OpenHarmony**、**云手机**、**BlackBerry**、**Google Pixel（含 GrapheneOS）**、**Windows Phone**、**Tizen**、**KaiOS**、**Sailfish/Aurora/Ubuntu Touch**、**Amazon Fire OS** 等。题目特征：见到 `.hap`、`HMFS`、`EROFS`、`com.huawei.hmos`、`HAP`、`distributed soft bus`、`bbm`、`BIS/BES`、`IT Policy`、`bbb-secure`、`Lumia`、`WP8`、`WPSStore`、`AppX`、`livetile`、`tizen`、`Wgt`、`KaiOS`、`Gaia`、`Sailfish`、`Aurora` 等。

---

## 1. 全景对照表（先定位是哪种系统）

| 系统 | 厂商 / 状态 | 内核 | 应用包 | 特点 |
| --- | --- | --- | --- | --- |
| **HarmonyOS（鸿蒙）1–4** | 华为，2019–2024 | Linux（AOSP 兼容） | `.apk` + `.hap` | 手机版基本是 AOSP + EMUI 改名 |
| **HarmonyOS NEXT 5（纯血鸿蒙）** | 华为，2024+ | OpenHarmony Linux 内核 | `.hap` / `.hsp` / `.app` | **不再兼容 Android**，独立生态 |
| **OpenHarmony**（开源） | OpenAtom 基金会 | LiteOS/Linux 双内核 | `.hap` | 政企/IoT 多 |
| **云手机** | 华为云 / 百度 / 阿里 / 腾讯 / 红魔 / 网易 | 远程 ARM 服务器 Android | apk | 数据**在云端**，本地仅 streaming 客户端 |
| **BlackBerry OS / BB10** | RIM/BlackBerry，2016 停 | QNX（BB10） / 自研（BBOS） | `.cod`（BBOS） / `.bar`（BB10） | PIN 唯一 ID、BBM、IT Policy |
| **BlackBerry 安卓**（Priv/Key2/Aurora） | TCL 代工，2017+ | Android | `.apk` | DTEK 安全监控 |
| **Google Pixel 原生 Android** | Google | Linux | `.apk` | Titan M2、StrongBox、最新 AOSP |
| **GrapheneOS / CalyxOS / DivestOS** | 第三方 ROM（Pixel） | Linux | `.apk` | 强化隐私，关 GMS、Sandboxed Play、严格权限 |
| **Windows Phone 7/8/10** | Microsoft，2017 终结 | NT（WP8+ ）/ CE（WP7） | `.xap`(7) / `.appx`(8+) | Live ID、OneDrive、磁贴 |
| **Tizen** | 三星（手表/电视） | Linux | `.tpk` / `.wgt` | Galaxy Watch、Gear 系列 |
| **KaiOS** | KaiOS Tech | Linux + Gecko | `.zip` (Gaia App) | 功能机/Banana Phone |
| **Sailfish / Aurora** | Jolla（俄军政企） | Linux（Mer 项目） | `.rpm` | Android 兼容运行时 |
| **Ubuntu Touch** | UBports | Linux | `.click` / Snap | 极少见 |
| **Fire OS** | Amazon | Android 分支 | `.apk` | 无 GMS，亚马逊服务 |
| **Symbian S60/^3** | Nokia，2014 停 | EKA2 微内核 | `.sis` `.sisx` | 老案件 |
| **Bada / Brew / Java ME** | 三星 / Qualcomm / Sun | 自研 / RTOS | 各自专用 | 罕见 |

---

## 2. HarmonyOS / OpenHarmony 取证

### 2.1 三个版本必须分清
| 版本 | 时期 | 实质 | 取证差异 |
| --- | --- | --- | --- |
| **HarmonyOS 1.x（手机）** | 2021 EMUI 11 改名 | 完全 AOSP + EMUI 11 | **当 Android 处理** |
| **HarmonyOS 2.x – 4.x（手机）** | 2021–2024 | AOSP + 鸿蒙微内核框架 + 分布式软总线 | 当 Android 处理；新增 .hap |
| **HarmonyOS NEXT 5（纯血鸿蒙，2024 Q4+）** | Mate 70、Pura 70 部分新机 | **独立内核 + ArkUI + ArkTS**，**不能装 Android APK** | **完全不同生态**，需专用工具 |
| **OpenHarmony** | 开源（OpenAtom） | 与 HarmonyOS 共享代码池 | 政企设备多见 |

### 2.2 文件系统
- HarmonyOS 2-4：基本 ext4/F2FS（同 EMUI/AOSP）。
- **EROFS**（Enhanced Read-Only File System）：华为主推的只读系统分区，已被 Android 13/14 主线采纳。挂载只读，**适合用于物理镜像**（无写入污染）。
- HarmonyOS NEXT：**HMFS**（HarmonyOS File System，2024 公布），针对分布式 + 加密优化；细节未公开，目前商业取证软件正在跟进。

### 2.3 分区与路径（手机版）
- 与 Android 几乎一致：`/system`、`/vendor`、`/data`、`/cust`（华为定制）、`/preload`（预装应用）、`/persist`、`/cache`。
- 用户数据：`/data/user/0/<pkg>`、`/data/user/999/<pkg>`（华为应用分身）、`/data/user/<10|11>/<pkg>`（华为隐私空间）。
- 鸿蒙 NEXT：路径变为 `/data/app/el2/<pkg>` 等，`el1`/`el2`/`el3`/`el4`/`el5` 表示加密等级（**与 iOS Data Protection Class 类似**）：

| 加密类 | 含义 | BFU 可读 |
| --- | --- | --- |
| **EL1** | 设备级（永远可读） | ✅ |
| **EL2** | 用户级（解锁后可读） | ❌（默认） |
| **EL3** | 解锁后可读，锁屏后不可读 | ❌ |
| **EL4** | 同 EL3 但更严格 | ❌ |
| **EL5** | 应用敏感数据，需用户认证 | ❌ |

### 2.4 应用包格式
- **.hap（HarmonyOS Ability Package）**：本质 ZIP，含：
  - `module.json` / `config.json`：应用配置（包名、签名、ability 列表）
  - `pack.info`
  - `ets/` `js/` 编译后的 ArkTS/JS 字节码
  - `assets/` `resources/`
  - `libs/<arch>/`
  - `META-INF/`：签名块（华为 HarmonyAppSign，CMS 格式）
- **.hsp**：Harmony Shared Package（共享库）
- **.app**（NEXT）：上架应用市场的整包，内含一个或多个 .hap

```bash
# .hap 解包同 zip
unzip app.hap -d hap_root/
cat hap_root/module.json | jq

# 反编译 ArkTS 字节码
# 工具：ArkAnalyzer、abc-decompiler、abc2java（社区）
```

### 2.5 ADB / hdc
- HarmonyOS 1-4：**adb 仍可用**（与 Android 兼容）。
- HarmonyOS NEXT：用 **hdc**（HarmonyOS Device Connector）替代 adb：
```bash
hdc list targets
hdc shell
hdc file send local remote
hdc file recv remote local
hdc bm dump -a              # bm = bundle manager（≈ pm）
hdc bm dump -n com.example.app
```
- 工具下载：HUAWEI DevEco Studio 集成；或 OpenHarmony SDK。

### 2.6 微信/QQ 等 Android App 在鸿蒙
- 1.x – 4.x：直接装 apk，数据路径同 Android → 走 `wechat_deep_dive.md`。
- NEXT 5 + 华为应用市场版微信（鸿蒙原生）：包名仍 `com.tencent.mm`，但**沙盒路径在 `/data/app/el2/100/com.tencent.mm/`**（100 是默认 user id），数据库结构据社区反馈与 Android 微信高度相似（仍 EnMicroMsg/MSG*.db 风格），但具体加密参数与版本相关，**需逐版本验证**。

### 2.7 取证策略
1. **先看版本**：`getprop ro.build.os.version` / `setprop` / 设置 → 关于本机。
2. HarmonyOS 1-4 → **完全按 Android 处理**（参 `extraction_methods.md`）。
3. HarmonyOS NEXT 5 → 商业取证软件（**美亚柏科 / 盘古石 / 效率源 / 易加/Cellebrite Premium**已在 2024-2025 陆续支持），**自研需 hdc + 镜像挂载**。
4. 越狱：HarmonyOS NEXT **无公开越狱方案**；EL2+ 数据未解锁时不可读。
5. 应用分身：`/data/user/999/`（同 EMUI），见 `emulator_clone_forensics.md`。

### 2.8 关键考点
- HarmonyOS NEXT 不兼容 Android（**最大变化**）。
- 加密分级 EL1–EL5。
- 包格式 `.hap` 是 ZIP，可解包看 `module.json`。
- 分布式软总线（碰一碰、超级终端）→ 多设备数据可能联动，取证要把同账号其他华为设备列入排查范围（手表、平板、智慧屏）。

---

## 3. 云手机（Cloud Phone）

### 3.1 主要服务商
| 服务 | 厂商 | 用途 |
| --- | --- | --- |
| **华为云手机** | Huawei Cloud | 企业批量自动化 / 移动办公 |
| **百度云手机** | Baidu Cloud | 同上 + 游戏挂机 |
| **阿里无影云手机 / 红手指** | Alibaba | 个人挂机 |
| **腾讯云手机** | Tencent | 同上 |
| **网易云手机 / MuMu Cloud** | 网易 | 个人 |
| **小米云手机** | 小米 | 个人 |
| **多多云手机 / 雷电云 / 红魔云游戏** | 各家 | 游戏 / 多开 |
| **AWS Device Farm / Genymotion Cloud** | 海外 | 测试 |

### 3.2 工作机制
- 云端：一台 **ARM 服务器**虚拟出多台 Android 实例（KVM/QEMU/Anbox/Container/Docker）。
- 客户端：手机/PC App 用 **WebRTC / RTSP / 自研协议**接收画面、上传操作。
- 数据：**几乎全部在云端**，本地仅有：
  - 客户端登录 token、设备列表、流量统计。
  - 录屏缓存（少数 App 支持本地存）。
  - 文件上传/下载缓存。

### 3.3 取证策略
1. **先确认是否云手机题**：嫌疑人手机里只有"云手机 App"图标但无目标 App 真实数据 → 几乎可以肯定。
2. **从客户端 App 提账号信息**：
   - `/data/data/<云手机包>/shared_prefs/` → user_id、token、设备实例 id。
   - 例：华为云手机 `com.huawei.cloud.pad`、百度云手机 `com.baidu.cloudgame`、红手指 `com.fhkj.redfinger`。
3. **登录云端账号**（合法授权下）→ 查看用户的所有云手机实例。
4. **向云服务商发法律调取**（公安专用渠道）：通常可拿到：
   - 登录 IP、登录时间、实例 ID、绑定手机号 / 实名信息。
   - 实例镜像快照（可下载导出 .img 后按 Android 取证）。
   - 客户端文件传输日志。
5. **协议抓包辅助**：在客户端机上抓 https/wss，可获取实例 endpoint / 鉴权 token。

### 3.4 题型与解法
| 题型 | 解法 |
| --- | --- |
| 嫌疑人在哪个云手机平台用了哪些 App | 客户端 token + 服务商查 |
| 云手机里聊天记录 | 实例镜像导出 → 当 Android 取证 |
| 嫌疑人多账号登录 | 客户端登录历史 + 服务商日志 |
| 流量/操作时间 | 客户端流量统计 + 服务商调取 |
| 案件涉及虚拟币/赌博 App 在云手机 | 云端实例 + 链上分析（参 `crypto_currency_forensics.md`）|

### 3.5 常见坑
- **云手机本地无数据**：直接拷"嫌疑人手机"全盘 → 几乎一无所获，必须走云端调取。
- **多设备实例**：一个账号可同时跑 N 个安卓实例，要全列出来。
- **云端镜像格式各异**：华为/阿里多用 qcow2 + ext4；导出后按 `emulator_clone_forensics.md` 处理。
- **截图/录屏只在客户端机**：嫌疑人若手动截图保存，本地相册里有；用 `geolocation_forensics.md` 套路找 EXIF。

---

## 4. BlackBerry 取证

### 4.1 三个时代
| 时代 | OS | 典型机型 | 应用 |
| --- | --- | --- | --- |
| **BBOS（经典）** | BlackBerry OS（自研） | 7100 / 8800 / 9700 / 9900 | `.cod`（Java + 自家库） |
| **BB10**（QNX 内核） | BlackBerry 10 | Z10 / Q10 / Q5 / Z30 / Passport / Classic | `.bar`（QNX 包，含 Android 应用兼容层） |
| **BlackBerry Android**（TCL 代工） | Android | Priv / DTEK50/60 / KEYone / KEY2 / Aurora / Motion | apk |

### 4.2 BBOS 取证（老案件）
- **设备识别**：每台 BB 有唯一 **PIN**（8 位 hex），可通过 `*#06#`、电池仓贴纸或菜单看。
- **加密**：IT Policy 加密（企业级 BES）+ 内容保护（用户密码 PBKDF2）。
- **密码**：尝试上限默认 10 次，超限**抹除整机**（Content Protection）。
- **取证工具**：
  - **BlackBerry Desktop Manager**（BDM）：备份 `.ipd` / `.bbb` 文件。
  - **MagicBerry / ABC Amber BlackBerry Converter**：解析 .ipd 备份。
  - **Cellebrite UFED Touch / Classic**：物理提取（旧机型支持）。
- 备份格式：
  - `.ipd`：早期，结构开放，可手工解析（每条记录变长，含数据库分段）。
  - `.bbb`（BB10）：实际是 zip。

### 4.3 BBM（BlackBerry Messenger）
- 基于 PIN 的私信协议，不依赖手机号/邮箱。
- 数据库：`messages.dat` / `bbm_history.db`。
- 加密：BB 服务器中转，端到端加密（BBM Protected 版本）。
- 已停服，存量证据多在备份内。

### 4.4 BB10
- QNX 微内核，文件系统 ext4 + 加密层。
- 数据：`/accounts/1000/` 是用户 home（≈ /home/user）。
- 关键库：
  - `pim.db`（联系人/日历）
  - `messages.db`（短信/邮件）
  - `bbmcore.db`（BBM）
- BB10 应用包 `.bar` = ZIP，含 manifest.mf、QNX 二进制（`.so` ELF/PE-COFF 风格）+ 资源。

### 4.5 BlackBerry Android（Priv 起）
- **完全是 Android**：取证全套用 Android 流程。
- 特色 App：**DTEK**（安全监控、可记录隐私事件、`com.blackberry.dtek*`）、BlackBerry Hub（统一邮件/IM）、BBM Enterprise（独立企业版，至 2023 末停）。
- DTEK 数据库 `dtek.db`：含设备完整性事件、App 权限请求记录——**取证额外宝藏**。

### 4.6 比赛常考点
- BBOS PIN 的作用：唯一识别 + BBM 联系标识。
- IT Policy = 企业 MDM 配置，可强制设备加密、禁用相机等。
- BB10 是 QNX 内核（非 Linux）。
- BlackBerry Android 设备虽然品牌是 BB，但内部就是 AOSP。
- 已停服：BBM Consumer（2019 关闭）、BBM Enterprise（2023 关闭）。

---

## 5. Google Pixel（含 GrapheneOS / CalyxOS）

### 5.1 Pixel 特殊点
- **Titan M2 安全芯片**（Pixel 6+）：独立 RISC-V 处理器，做 Keystore、StrongBox、防回滚、Verified Boot 根。
- **eSIM**：多数 Pixel 仅 eSIM 或单物理 + eSIM 组合。
- **Verified Boot 2.0**：解锁 bootloader 必须 OEM 允许 + 输 PIN，且解锁后 dm-verity 失效（启动时显示橙色警告）。
- **OTA delta + AB 分区**：永久双 slot，rollback protection。
- **AOSP 最干净**：无 OEM 改动，路径与上游 AOSP 一致。

### 5.2 GrapheneOS / CalyxOS 等
| ROM | 特点 |
| --- | --- |
| **GrapheneOS** | 强化沙盒、关闭 USB 在锁屏后、PIN scrambler、Sandboxed Google Play（不给系统权限）、严格权限模型、Storage Scopes、Contact Scopes |
| **CalyxOS** | microG（开源 GMS 替代）、Datura 防火墙、稍宽松 |
| **DivestOS** | LineageOS 派生，去 Google |
| **/e/OS** | 主打去谷歌 + 自家 ecloud |
| **iodéOS** | 去谷歌 + 内置广告/追踪过滤 |

### 5.3 GrapheneOS 取证特殊难点
- **USB 锁屏后默认关闭**：拔线即数据线无效；现场必须保持 AFU + 屏幕亮。
- **Auto-reboot**（默认 18 小时不解锁）：定时回到 BFU。
- **2FA / Owner profile lockdown**：可设禁用所有登录直至下次解锁。
- **Sandboxed Play**：Play 服务在用户态运行，不给特权 → Google Find My Device、远程擦除等多数失效（**实战上对用户隐私好，但对取证调取不友好**）。
- **PIN scrambler**：每次解锁数字键盘随机布局，肩窥/录像复现密码无效。
- 物理提取：与 Pixel 原 AOSP 同；FBE 加密、需要 PIN 才能解 CE 数据。

### 5.4 Pixel 取证流程
1. 设备型号识别：`getprop ro.product.model` → `Pixel 7` 等。
2. ROM 识别：`getprop ro.modversion`、`/system/build.prop` 含 `org.lineageos`、`org.calyxos`、`GrapheneOS` 等关键字。
3. 解锁状态：bootloader 解锁 → fastboot oem 命令多。
4. 数据提取按 Android 标准（参 `extraction_methods.md`）。
5. eSIM 信息：`/data/misc/euicc/` 或 `dumpsys euicc`。

### 5.5 题型
| 题 | 解法 |
| --- | --- |
| 判断是不是定制 ROM | build.prop + `ro.modversion` + Settings → About |
| GrapheneOS 提取受阻 | 必须 AFU 状态；保持开机 + 防自动重启（18h） |
| Titan M2 限速器 | PIN 错误指数退避，无法越过；硬件爆破不可行 |
| eSIM ICCID/IMSI | `dumpsys euicc all` / `/data/misc/euicc/*` |

---

## 6. Windows Phone

### 6.1 三个版本
| 版本 | 内核 | 文件系统 | 应用 |
| --- | --- | --- | --- |
| **Windows Phone 7 / 7.5 / 7.8** | Windows CE 7（**非 NT**） | 自有 | `.xap`（Silverlight） |
| **Windows Phone 8 / 8.1** | NT（与 Win8 共内核） | NTFS | `.xap` + `.appx`（WinRT） |
| **Windows 10 Mobile** | NT（W10 Core） | NTFS / ReFS | `.appx` / `.appxbundle` |

### 6.2 取证特点
- 已 EOL（2017 年终结），但旧案件常见。
- **整盘 BitLocker 加密**（WP8.1+ 默认开），密钥与设备绑定 + Microsoft Account 上行托管。
- **用户名 = Microsoft Account（Live ID）**，邮箱形式，绑 OneDrive / Xbox / Skype。
- 应用沙盒：`Data\Users\DefApps\AppData\Local\Packages\<PackageName>\`
- 关键数据：
  - 短信：`store.vol`（ESE 数据库，与 Outlook/Win Mail 兼容）
  - 联系人：`peopledb`
  - 通话：`phone.db`
  - 邮件：`livcomm.dat`
  - OneDrive 缓存：`Data\Users\Public\Pictures\Camera Roll\`

### 6.3 取证工具
| 工具 | 备注 |
| --- | --- |
| **Cellebrite UFED**（Logical/Advanced） | 主流，支持解 BitLocker 部分场景 |
| **Oxygen Forensic** | 同上 |
| **Magnet AXIOM** | 解 .appx + ESE store.vol |
| **WPInternals** / **Thor**（社区） | Lumia 引导/物理提取（早期） |
| **WPDevicePort** | adb 风格调试（仅开发模式） |
| **EseDbViewer** / **libesedb** | 解 ESE（store.vol、peopledb 等） |

### 6.4 解析 ESE（核心）
WP 大量使用 ESE（Extensible Storage Engine，与 AD/Edge cache 同源）：
```bash
# libesedb
esedbexport -t /tmp/out store.vol
esedbinfo store.vol
# Python
pip install pyesedb
python -c "import pyesedb;f=pyesedb.file();f.open('store.vol');[print(t.name) for t in f.tables]"
```

### 6.5 OneDrive 同步
- WP 数据高度依赖 OneDrive：照片、短信备份（启用后）、联系人、设置。
- 取证：登录 Microsoft Account（合法授权）→ OneDrive 网页或商业 Cloud Analyzer 下载。
- "短信和 MMS 备份" Azure 端：可通过 https://account.microsoft.com 调取（已停部分）。

### 6.6 BitLocker on WP
- 设备加密 = 简化 BitLocker，密钥派生自设备 + MS Account。
- **解锁途径**：
  1. 已知账号密码 → 联机解；
  2. Microsoft Recovery Key（MS Account 后台可查）；
  3. Cellebrite 部分 Lumia 提取了 raw key。

### 6.7 比赛常考
- WP 文件系统是 NTFS（WP8+）。
- 应用包是 .xap（WP7）/.appx（WP8+）。
- 用户身份是 Live ID / MSA。
- 数据多在 ESE 数据库。
- BitLocker 默认开。
- 已 EOL，云端 OneDrive 仍可调取。

---

## 7. Tizen（三星可穿戴）

### 7.1 现状
- 三星 Galaxy Watch 1/2/3、Gear S2/S3 用 Tizen。
- Galaxy Watch 4+ 已切到 **WearOS**（Android-based）。
- Tizen 还在 Samsung Smart TV、冰箱等。

### 7.2 文件系统与路径
- 内核：Linux
- FS：ext4 + 加密
- 用户 home：`/home/owner/`、`/opt/usr/home/owner/`
- App 数据：`/opt/usr/apps/<appid>/data/`、`/opt/usr/home/owner/apps_rw/<appid>/`
- App 包：`.tpk`（原生）/`.wgt`（Web App）

### 7.3 取证
- 工具：**Cellebrite Smartwatch Forensics**、**Oxygen Wearable Module**、**Tizen Studio sdb**（Tizen Studio 自带 sdb，类似 adb）。
- sdb 命令：`sdb shell`、`sdb pull /opt/usr/home/owner /tmp/`
- 关键库：`contacts.db`、`messages.db`、`logs.db`（健康/步数）、`sticker.db`。

### 7.4 题型
- 同步源：手表数据多与配对手机同步（Samsung Health）→ 优先取手机数据。
- 健康数据：手表本地 + Samsung Health App + Samsung Cloud。
- 通知镜像：手表上看到的通知 = 手机推过来的复制，**真消息内容仍在手机端 App**。

---

## 8. KaiOS（功能机）

### 8.1 是什么
- KaiOS 基于 Firefox OS，运行于低端功能机（4G 翻盖机、TCL/Nokia 部分老人机）。
- 内核 Linux + Gecko Web 引擎；应用是 HTML/JS（Gaia）。

### 8.2 文件系统
- 修改版 ext4
- 用户数据：`/data/local/`、`/data/local/webapps/`
- App 数据库：IndexedDB（LevelDB）→ 用 plyvel + V8 反序列化（参 `database_forensics.md`）。
- WhatsApp / Facebook for KaiOS 仍存在，数据库形式与 Android 不同（IndexedDB）。

### 8.3 取证
- adb：部分机型开启 root 调试可用 adb。
- 工具：**Oxygen Forensic** 支持。
- 注意：很多新兴市场（印度、非洲）案件设备是 KaiOS。

---

## 9. Sailfish OS / Aurora OS（俄罗斯军政）

### 9.1 背景
- Sailfish 由 Jolla 开发，源自 MeeGo/Mer。
- **Aurora OS** 是俄罗斯 Rostelecom 派生版，俄军政强制使用（2024+）。
- 内核 Linux，无 Android 兼容（早期版本有兼容运行时）。

### 9.2 取证要点
- 文件系统 ext4 / btrfs，路径 `/home/defaultuser/`、`/home/nemo/`。
- 应用包 `.rpm`，数据 `~/.local/share/<appname>/`。
- 系统管理 `systemd`，数据库主流 SQLite。
- 工具：商业取证软件支持有限；多用 Linux 取证流程（dd 物理 + autopsy）。
- 实战：在涉俄案件中可能出现，国际比赛偶尔涉及。

---

## 10. Ubuntu Touch / Amazon Fire OS / Symbian / Bada / Java ME（速过）

### 10.1 Ubuntu Touch (UBports)
- 基于 Ubuntu，Click 包 + Snap。
- 路径：`/home/phablet/`，App 数据 `~/.local/share/<click-app>/`。
- 极少见。

### 10.2 Amazon Fire OS（Kindle Fire / Fire phone）
- AOSP 派生 + 亚马逊服务（Amazon AppStore、Silk Browser）。
- 取证按 Android 处理，但**无 GMS**；Amazon 账号 + S3 后台同步。
- 关键数据：Kindle 阅读、Alexa 历史（设备本地 + 云端）。

### 10.3 Symbian S60 / Symbian^3
- Nokia 老机（N73、N95、E71、N8、808）。
- 文件系统：FAT/EFFS；应用 `.sis`/`.sisx`。
- 数据库：dbms.dbms2（自有格式）、cntmodel.cdb（联系人）、msgs.dat（短信）。
- 工具：**Paraben DDS**、**Cellebrite UFED Classic**、**Oxygen**（旧版）。
- 已绝迹 10+ 年，老案件偶现。

### 10.4 Bada（三星早期）/ Brew / Java ME
- 已彻底淘汰，遇到一律 Cellebrite UFED Classic + 物理 dd。

---

## 11. 通用解题决策树

```
拿到一台"非主流"手机
├─ 还能开机？
│   ├─ 是 → 先看版本（设置 → 关于本机 / *#06# / build.prop）
│   │   ├─ HarmonyOS / EMUI → ADB 兼容时按 Android；NEXT 5 用 hdc
│   │   ├─ Pixel + 第三方 ROM → AFU 保持，按 Android 流程，注意 USB 锁
│   │   ├─ Windows Phone → Live ID + OneDrive 联机；本地 ESE 解析
│   │   ├─ BB10 → BB Link / UFED；BBOS → BDM .ipd
│   │   ├─ Tizen 表 → sdb；优先取配对手机
│   │   ├─ KaiOS → adb（部分机）+ IndexedDB/LevelDB
│   │   └─ 其他 Linux 系（Sailfish/Ubuntu Touch）→ Linux 取证流程
│   └─ 否 → 物理芯片级（JTAG/ISP/Chip-off，多数老机仍可）
└─ 是云手机？
    ├─ 客户端 App 找账号、token、实例 ID
    ├─ 联系服务商法律调取实例镜像
    └─ 镜像导出后按 Android 流程解析

辅助原则：
- 任何"陌生系统"先执行 file/strings 摸文件结构
- 应用包基本都是 zip：先 unzip 看 manifest
- 数据库基本是 SQLite：先 head 16 字节认头
- 时间戳：先看是 Unix 秒/毫秒/纳秒/Mac Abs/FILETIME（Windows）
```

---

## 12. 命令速查

```bash
# HarmonyOS / NEXT (hdc)
hdc list targets
hdc shell "bm dump -a"           # 列所有装的 bundle
hdc shell "param get const.product.os.version"   # 鸿蒙版本
hdc file recv /data/app/el2/100/<bundle> ./

# .hap / .bar / .tpk / .wgt / .appx 都是 zip
unzip -l app.hap
unzip app.bar -d bar_root/
file bar_root/META-INF/MANIFEST.MF

# Windows Phone ESE
esedbinfo store.vol
esedbexport -t /tmp/out store.vol
python -c "import pyesedb;f=pyesedb.file();f.open('store.vol');[print(t.name,t.number_of_records) for t in f.tables]"

# BlackBerry .ipd（老备份）
# 用 ABC Amber 或自写：
python -c "import struct;d=open('a.ipd','rb').read();print(d[:38])"   # 头是 'Inter@ctive Pager Backup/PDA Backup'

# Tizen sdb（与 adb 几乎一样）
sdb devices
sdb shell
sdb pull /opt/usr/home/owner/.

# KaiOS adb（部分机型需先 ADBHack）
adb shell ls /data/local/webapps/
adb pull /data/local/webapps/whatsapp/

# 鸿蒙 NEXT 应用沙盒（root 后）
ls /data/app/el2/100/com.tencent.mm/
ls /data/app/el2/100/com.huawei.hmos.<appid>/

# 云手机客户端取 token
ls /data/data/com.huawei.cloud.pad/shared_prefs/
ls /data/data/com.fhkj.redfinger/shared_prefs/
```

---

## 13. 常见坑

1. **HarmonyOS 1-4 误当全新系统**：实际就是 EMUI/AOSP，**直接走 Android 流程**别绕弯。
2. **HarmonyOS NEXT 5 与之前完全不同**：装不了 Android APK，需要 hdc + 鸿蒙原生工具。
3. **EL2+ 数据需解锁后才可读**：即便有 root，BFU 状态下读到的是密文。
4. **云手机本地几乎无数据**：仅客户端 App 沙盒里有 token，**主战场在云端**，必须法律渠道调取。
5. **BB Content Protection 输错 10 次抹机**：BBOS 设备绝不能盲试密码。
6. **WP 设备加密 + MS Account**：取证要尽早记录账号；离线场景下设备解锁难度大。
7. **GrapheneOS USB 锁屏即断**：拔线就废，必须屏幕亮 + AFU。
8. **Pixel 解锁 bootloader 会触发 dm-verity 警告 + 永久痕迹**：对取证完整性是污染，操作前评估。
9. **Tizen 表数据是手机镜像**：通知/微信预览可能在手表，但**消息原文仍在手机**，别把表当主战场。
10. **KaiOS 数据是 IndexedDB（LevelDB）**：不是 SQLite，按 LevelDB + V8 反序列化处理。
11. **Sailfish/Aurora 加密**：俄方政企版多有 LUKS 卷加密 + TPM 绑定，无解锁不行。
12. **ESE store.vol** 不是 SQLite：用 sqlite3 工具会失败，必须 libesedb / pyesedb。
13. **Symbian/Bada 数据库是私有格式**：手工解析极困难，依赖 UFED Classic 等老工具的内置解析。
14. **应用包统一是 zip**：.hap/.bar/.tpk/.wgt/.appx/.xap 都可 unzip，但反编译方式差异大（ArkTS、QNX ELF、Silverlight DLL、UWP CIL）。
15. **多设备生态**：HarmonyOS 超级终端、Apple Continuity、Windows Phone Continuum、Samsung DeX → 数据可能流到平板/电视/PC，**别只盯手机**。
16. **设备时间戳格式**：Windows Phone 大量是 **FILETIME**（100ns 自 1601-01-01），与 iOS Mac Abs / Unix 秒都不同；先看数量级。
17. **BB10 是 QNX 内核**：不要用 Linux 工具想当然挂 ext4；QNX 自有 fs（QNX6）。
18. **云手机存证**：调取的实例镜像必须做 hash 固定 + 服务商加盖电子凭证，否则证据链不完整。

---

## 14. 比赛题型对照

| 题型 | 关键提示 | 解法 |
| --- | --- | --- |
| HarmonyOS 是什么内核 | 1-4 = AOSP Linux；NEXT = OpenHarmony 微内核+Linux 双内核 | 选 Linux/微内核组合 |
| .hap 文件如何分析 | 解压 → 看 module.json | unzip + jq |
| 鸿蒙 NEXT 与 Android 关系 | 不再兼容 | "完全独立生态" |
| 云手机现场仅有客户端 App，怎么取证 | 客户端 token + 服务商调取 | 法律调取实例镜像 |
| BlackBerry PIN 是什么 | 8 位 hex，唯一设备/BBM 标识 | 不是手机号 |
| WP 主要应用包 | .xap (WP7) / .appx (WP8+) | 选 .appx |
| WP 数据库 | ESE（store.vol） | libesedb/pyesedb |
| WP 用户身份 | Live ID / MSA | 邮箱形式 |
| Tizen 用 sdb 还是 adb | sdb（Tizen Studio） | sdb |
| Pixel + GrapheneOS 取证防御 | USB 锁、自动重启、Auth lockdown | AFU + 不拔线 |
| KaiOS 数据存哪 | IndexedDB（LevelDB） + 文件系统 | plyvel |
| BBM 协议 | 走服务器中转 + PIN 标识 | 端到端加密 |

---

## 15. 交叉链接
- `extraction_methods.md`：5 级提取方法，对鸿蒙/Pixel 仍适用
- `adb_filesystem_cheatsheet.md`：ADB / Android 文件系统（鸿蒙 1-4 通用）
- `emulator_clone_forensics.md`：云手机镜像导出后按这里处理；分身用户路径
- `wechat_deep_dive.md` / `popular_apps_forensics.md`：鸿蒙上 Android App 的解析
- `database_forensics.md`：ESE/IndexedDB/LevelDB/SQLite 通用解析
- `device_basic_info.md`：跨平台设备信息提取
- `timestamps_reference.md`：FILETIME / Mac Abs / Unix 秒/毫秒 换算
- `anti_forensics_and_misleading.md`：云手机/分身常作为反取证手段
