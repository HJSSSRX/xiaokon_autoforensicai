# iOS 基础与安全机制（取证视角）

> 适用：iOS / iPadOS / watchOS / tvOS 取证基础知识题。题目特征：APFS、HFS+、Data Protection Class、Effaceable Storage、Secure Enclave、Keybag、SEP、AFU/BFU、iTunes 备份格式、越狱原理、checkm8/checkra1n/palera1n、ramdisk、SSV、Code Signing、SBI（Secure Boot）、AMFI、KPP/KTRR、PAC、SIP、Sandbox、Entitlement 等术语。

---

## 1. iOS 文件系统演进

### 1.1 时间线
| iOS 版本 | 文件系统 | 特点 |
| --- | --- | --- |
| iOS 1 – 10.2 | **HFS+**（区分大小写变种 `HFSX`） | 与 macOS 同源；日志式；不支持原生快照 |
| iOS 10.3+ | **APFS** | 写时复制（CoW）、原生加密、快照、稀疏文件、克隆 |
| iOS 15+ | APFS + **SSV**（Signed System Volume） | 系统卷是只读签名快照，开机挂载只读快照 |

### 1.2 APFS 容器布局（取证关键）
一个 NVMe 物理盘 → 一个 **Container** → 多个 **Volume**：
- `Macintosh HD` / `<x>` 系统卷（只读，SSV 签名）
- `Macintosh HD - Data` / `Data` 数据卷（读写，**用户数据全在这里**）
- `Preboot`：开机引导 + EFI/iBoot 配置 + APFS 加密 keybag
- `Recovery`：恢复模式
- `VM`：交换分区（iOS 一般禁用）

> **Firmlinks**（macOS）：把 `/Users` `/Applications` 等从系统卷"链"到数据卷的特殊机制；iOS 不暴露给用户但内部存在。

### 1.3 卷加密（FileVault on iOS = Data Protection）
- iOS 默认**整卷加密**（FDE）+ **逐文件 Class Key 加密**（FBE 等价物）。
- 卷主密钥存在 **Effaceable Storage**（NAND 上的特殊小区，可单独擦除 → 一键抹机）。
- "抹除所有内容和设置" = 抹掉 Effaceable Storage 中卷密钥 → 数据瞬间不可恢复。

### 1.4 关键挂载点（设备内部 / 越狱后能见）
| 路径 | 内容 |
| --- | --- |
| `/` | 系统卷只读快照（SSV，根分区） |
| `/private/var/` | 数据卷挂载点（**所有用户数据**） |
| `/private/var/mobile/` | 主用户 home（≈ Android `/data/user/0`） |
| `/private/var/mobile/Containers/Data/Application/<UUID>/` | 第三方 App 沙盒数据 |
| `/private/var/mobile/Containers/Bundle/Application/<UUID>/` | 第三方 App 可执行 + 资源（ipa 解出来的 .app） |
| `/private/var/mobile/Containers/Shared/AppGroup/<UUID>/` | App Group 共享容器 |
| `/private/var/containers/Bundle/Application/<UUID>/` | 系统 App 沙盒 |
| `/private/var/Keychains/` | Keychain（`keychain-2.db`） |
| `/private/var/keybags/` | 数据保护 Keybag |
| `/private/var/db/` | 系统数据库（`/MobileBluetooth.db` `imagent.db` `tcc.db`） |
| `/private/var/folders/<xx>/<yy>/0` `T` `C` | 系统进程缓存（类似 macOS DARWIN_USER_DIR） |
| `/private/var/log/` | 部分系统日志 |
| `/private/var/wireless/` | 蜂窝/通话历史 |
| `/private/var/preferences/SystemConfiguration/` | Wi-Fi、网络配置 |
| `/private/var/MobileDevice/` | 设备激活、ProvisionInfo |

### 1.5 与 Android 路径对照（速记）
| Android | iOS |
| --- | --- |
| `/data/data/<pkg>` | `/private/var/mobile/Containers/Data/Application/<UUID>` |
| `/data/app/<pkg>/base.apk` | `/private/var/containers/Bundle/Application/<UUID>/<App>.app` |
| `/data/system/packages.xml` | `installd` + `MobileInstallation.plist` + `applicationState.db` |
| `/sdcard/` | `Media/DCIM/`（在 `/private/var/mobile/Media/`） |
| Android Keystore | iOS Keychain（`/private/var/Keychains/keychain-2.db`） |

---

## 2. iOS 安全机制（必背概念题）

### 2.1 启动链（Secure Boot）
```
Boot ROM (硬编码 Apple Root CA, 不可改)
    └─ 验证 LLB / iBoot
         └─ 验证 Kernel + KEXT
              └─ 验证 System Volume (SSV 签名树根)
                   └─ 用户态启动
```
- **Boot ROM 漏洞**（如 **checkm8**，A5–A11，2019 公开）→ **不可修补**（写在 ROM 里）→ 永久越狱基础。
- 启动每一阶段都验签，签名失败 → DFU 恢复模式。

### 2.2 Secure Enclave（SEP）
- 独立协处理器（A7+），自带 ROM、内存、固件、密钥。
- 负责：Touch ID/Face ID 比对、设备 UID（每机唯一硬编码 256 位 AES key）、Keychain 解密、Apple Pay。
- 主 CPU 拿不到 UID 明文，所有用 UID 派生的密钥都得通过 SEP "封套（mailbox）" 接口请求。
- **取证意义**：越狱也碰不到 SEP；密码爆破必须**机上爆破**（rate-limit 由 SEP 控制：10 次错锁 1 分钟、再错变长）。

### 2.3 Data Protection（逐文件加密）
每个文件创建时分配一个 **Class Key**：
| Class | 名字 | 何时可读 |
| --- | --- | --- |
| **A** | NSFileProtectionComplete | 仅设备解锁后；锁屏立即不可读 |
| **B** | NSFileProtectionCompleteUnlessOpen | 解锁打开后即使锁屏仍可读直到关闭 |
| **C** | NSFileProtectionCompleteUntilFirstUserAuthentication | **AFU**：开机首次解锁后即可读 → **多数 App 默认就是 C 类** |
| **D** | NSFileProtectionNone | **BFU**：仅依设备 UID 加密，开机即可读 |

每个文件元数据中存了 `cprotect` xattr，包含被该 class 公钥包裹的文件密钥。

#### Keybag（密钥袋）
- `system keybag`（`/private/var/keybags/systembag.kb`）：解锁 Class A/B/C 用，**用 passcode 派生 key 包裹**。
- `backup keybag`：iTunes 加密备份用，**用备份密码派生 key 包裹**。
- `escrow keybag`：信任电脑后，可让 PC 不输入密码就解锁备份恢复。
- `iCloud keybag`：iCloud 备份用。
- `OTA keybag`：系统升级用。

### 2.4 BFU vs AFU（**核心考点**）
| 状态 | 定义 | 可读 Class | 可读项 |
| --- | --- | --- | --- |
| **BFU** | 开机后未输过任何一次 passcode | 仅 D | 来电、紧急联系人、闹钟、Wi-Fi 列表（部分）、SIM、绑定信息 |
| **AFU** | 开机后输过至少一次 passcode（之后即使锁屏） | A 已被擦/重新锁定，B/C 仍解 | 联系人、短信、照片元数据、大部分 App 数据库（C 类）|
| **Unlocked** | 当前已解锁 | 全部 | 所有 |

> 现场处置原则：拿到设备**保持开机 + 充电** → 维持 AFU；优先在 AFU 状态下取证。

### 2.5 SSV（Signed System Volume，iOS 15+）
- 系统卷的每个目录树节点哈希形成 Merkle 树，根哈希签名后存于 trustcache；启动时校验整树。
- **取证意义**：传统改 system 路径替换 launchd 已不可行；越狱必须用 **rootful + bind mount** 或 **rootless（不动系统卷，所有补丁用 launchd 注入到 /var）**。

### 2.6 其他关键防护
- **AMFI**（AppleMobileFileIntegrity）：内核级强制代码签名；非 Apple 签名 binary 不能执行（除非越狱后绕过）。
- **CodeSigning**：每个 .app 必须签名；TeamID + Entitlement 决定可调用 API。
- **Sandbox**（基于 macOS Seatbelt）：每个 App 进程被 sandbox profile 限制访问路径；越狱后部分工具可绕过。
- **PAC**（Pointer Authentication，A12+）+ **KPP/KTRR**：内核内存防护，越狱难度大幅上升。
- **TCC**（Transparency, Consent, Control）：iOS 14+ 类似 macOS 的隐私授权数据库（`/private/var/mobile/Library/TCC/TCC.db`），记录"哪个 App 何时获得相册/麦克风/位置/通讯录授权"——**取证宝藏**。
- **Activation Lock**（激活锁/Find My）：擦机需 Apple ID 密码；取证前**必须断网 + 飞行模式 + 法拉第袋**，避免远程擦除。

---

## 3. iTunes / Finder 备份

### 3.1 触发与类型
| 类型 | 触发 | 加密 | 含 Keychain | 含通话/健康 |
| --- | --- | --- | --- | --- |
| **未加密备份** | iTunes/Finder 默认 | 仅设备主密钥层加密落到本地后明文 | ❌ | ❌ |
| **加密备份**（推荐取证） | 勾选"加密本地备份"，设密码 | 备份密码派生 key 包裹 backup keybag | ✅ | ✅ |
| **iCloud 备份** | 设置 → iCloud → 备份 | Apple 自家加密；iCloud Advanced Data Protection 后端到端 | 部分 | 部分 |

> **取证选择**：**总是优先做加密备份**，密码自己设（如 `1234`）。否则会丢 Keychain、CallHistory、WiFi 密码、Health、HomeKit 等。

### 3.2 备份目录定位
- Windows iTunes：`%APPDATA%\Apple Computer\MobileSync\Backup\<UDID>\`
- Windows Microsoft Store iTunes：`%USERPROFILE%\Apple\MobileSync\Backup\<UDID>\`
- macOS：`~/Library/Application Support/MobileSync/Backup/<UDID>/`

### 3.3 文件命名（已在 `ios_forensics.md` 详述，此处补充内部结构）
- 备份目录下：
  - `00`–`ff` 子目录：每个文件名是 `SHA1(domain-relativePath)`，前两字符作子目录。
  - `Manifest.db`：SQLite，文件清单；加密备份下整库加密（`Manifest.plist` 中 `IsEncrypted=true`）。
  - `Manifest.plist`：元数据（`Lockdown`、`Applications`、`BackupKeyBag` Base64）。
  - `Info.plist`：设备信息明文。
  - `Status.plist`：备份状态。

### 3.4 加密备份解密原理（理论考点）
1. 备份密码 → PBKDF2-HMAC-SHA256，2 轮 + PBKDF2-HMAC-SHA1，约 10000 轮（iOS 10.2+），派生 **DeriveKey**。
2. DeriveKey + `Manifest.plist` 中的 `BackupKeyBag` → 解出 backup keybag，得到 Class Keys。
3. Class Keys 解 `Manifest.db`（含每个文件的 ProtectionClass + 文件 key wrap）。
4. 用对应 Class Key 解 `Manifest.db.Files.file`（plist BLOB）拿到 EncryptionKey → AES-CBC 解每个备份文件。

### 3.5 重置备份密码（实战大杀招）
> iOS 11+：设备本身可解锁时，**设置 → 通用 → 传输或还原 iPhone → 还原 → 重置所有设置**（需锁屏密码） → **不会清用户数据**，但会重置：
- 旧的 iTunes 备份密码（旧加密备份变成不可解 ←别覆盖原盘！）
- Wi-Fi 列表、键盘字典、家庭按钮设置
> 之后再做的备份就可以**自己设新密码**。**前提：原备份要先做完整 dd 影像保留**。

### 3.6 加密备份密码爆破
- `hashcat -m 14700`（iOS 6.x – 10.1，PBKDF2-SHA1 10000 轮）
- `hashcat -m 14800`（iOS 10.2+，PBKDF2-SHA256 10000 轮 + PBKDF2-SHA1 10000000 轮，**极慢**）
- `john --format=itunes-backup`
- 字典：手机号、生日、出厂密码、之前已知密码模式

```bash
python /opt/itunes_backup2hashcat.py /Backup/<UDID>/ > h.txt
hashcat -m 14800 h.txt rockyou.txt -O
```

### 3.7 商业取证工具
- **Elcomsoft Phone Breaker**：备份密码爆破 + iCloud 下载。
- **Cellebrite UFED / Inspector**：iTunes/Finder 备份 + Advanced Logical + Checkm8 全提取。
- **MSAB XRY**、**Magnet Axiom**、**Oxygen**、**MOBILedit Forensic**。
- 国内：**美亚柏科 DC-4501**、**盘古石**、**X-Ways**、**效率源** 等。

---

## 4. 越狱基础与取证应用

### 4.1 越狱分类
| 类型 | 重启后 | 典型 |
| --- | --- | --- |
| **完美越狱**（Untethered） | 无需任何外部辅助，开机自动越狱 | iOS 9 之前曾有 |
| **半束缚**（Semi-tethered） | 重启后回到"未越狱"状态，需要在电脑/App 上重新激活 | **checkra1n / palera1n / Dopamine（多数现代越狱）** |
| **束缚**（Tethered） | 每次重启必须连电脑用工具引导 | 早期 |
| **半完美**（Semi-untethered） | 不需电脑，但需要每次重启在设备上点 App 重新启用 | unc0ver / Taurine |

### 4.2 主流越狱工具（含 ROM 漏洞）
| 工具 | 漏洞 | 支持机型 | 支持 iOS |
| --- | --- | --- | --- |
| **checkra1n** | checkm8（Boot ROM，永久） | A5 – A11 | 12.0 – 14.x（部分 16.x 有第三方 fork） |
| **palera1n** | checkm8 | A8 – A11（仅旧机） | 15 – 17.x |
| **unc0ver** | 内核漏洞（运行时） | A7 – A14 | 11 – 14.3 |
| **Taurine** | cicuta_virosa 等 | A8 – A14 | 14.0 – 14.3 |
| **Dopamine** / **palera1n rootless** | 不同 1day | A12 – A16 | 15 – 16.x |

### 4.3 越狱后取证流程
```
1. checkm8 进入 DFU → checkra1n/palera1n 引导 ramdisk
2. 在 ramdisk 中：
   - 挂载用户卷（需要 passcode 解 keybag → AFU 状态可用 SEP rate-limit 内的爆破）
   - 启用 SSH（OpenSSH 或自带 dropbear）
3. SSH 进入：
   - tar/cp 全文件系统
   - dump keychain（keychain_dumper）
   - 取 SEP 限速器内可爆破的 4–6 位数字密码
4. 反 DFU/重启 → 设备回到非越狱状态（半束缚）
```

### 4.4 BFU 提取（无密码场景）
- checkm8 设备即使没有 passcode，也可在 ramdisk 中提取**所有 D 类（NSFileProtectionNone）文件**。
- BFU 能拿到的内容：来电记录摘要、Wi-Fi SSID/BSSID 历史、TCC.db 部分、部分系统 plist、应用安装列表。
- BFU **不能拿到**：联系人、短信、照片、绝大多数 App 数据库（这些是 C 类）。
- BFU 仍可暴力**机上爆破密码**（受 SEP 限速）。

### 4.5 商业全提取（替代越狱）
- **GrayKey**（Grayshift）：执法专用，宣称支持最新 iOS 全提取（含 BFU 部分爆破）。
- **Cellebrite Premium**：同级。
- **AccessData MPE+**、**MOBILedit**：等级稍低。

---

## 5. AFC / lockdownd / 信任电脑

### 5.1 lockdownd
- 设备守护进程，端口 62078（USB 转发）。
- 处理 `iTunes/Finder` 协议、信任配对、备份请求。
- 配对成功后 PC 端保存 `<UDID>.plist` 于：
  - Win：`%PROGRAMDATA%\Apple\Lockdown\<UDID>.plist`
  - mac：`/var/db/lockdown/<UDID>.plist`
- 该 plist 含 **HostID / RootCertificate / HostPrivateKey / EscrowBag**——**取走它就能在不输密码的情况下，对该设备做加密备份**（前提设备已 AFU）。

### 5.2 AFC（Apple File Conduit）
- 通过 lockdownd 提供的文件传输服务，**只暴露 `/private/var/mobile/Media/`**（DCIM、Recordings、iTunes_Control）。
- 越狱设备可启用 `AFC2`（解除沙盒，访问全文件系统）。

### 5.3 工具
```bash
# libimobiledevice 全家桶（Linux/macOS）
idevice_id -l                       # 列设备 UDID
ideviceinfo                         # 设备信息
idevicepair pair                    # 配对（设备需点信任）
idevicebackup2 backup --full /tmp/backup        # 备份
idevicebackup2 -i info /tmp/backup              # 元数据
idevicebackup2 -p enable <pwd> /tmp/backup      # 启用加密备份
ideviceactivation                   # 激活
ideviceinstaller -l                 # 已装 App 列表
afcclient ls /                      # AFC 浏览（仅 Media 区）
ifuse /mnt/iphone                   # FUSE 挂载 Media 区
ifuse /mnt/iphone --documents com.tencent.xin    # 文档共享 App 的 Documents
```

---

## 6. 设备识别与信息

### 6.1 标识符
| 名词 | 含义 | 取证位置 |
| --- | --- | --- |
| **UDID** | Unique Device Identifier，40 字符（旧）或 25 字符（A12+） | `ideviceinfo -k UniqueDeviceID`、备份目录名 |
| **ECID** | Exclusive Chip ID，硬件唯一 64 位 | DFU 模式下可读；checkm8 必备 |
| **Serial Number** | 制造序列号 | `Info.plist` / 设置 → 通用 → 关于本机 |
| **IMEI / IMEI2** | 蜂窝 | `Info.plist`、SIM 托盘 |
| **MEID** | CDMA | 同上 |
| **ICCID** | SIM 卡号 | 同上 |
| **MAC（Wi-Fi/BT）** | 注意 iOS 14+ 默认 **私有 Wi-Fi 地址**，每个 SSID 不同；硬件 MAC 仍可在备份内 plist 看到 |
| **Apple ID（DSID + AltDSID）** | iCloud 账号数字 ID | `accounts3.sqlite`、`com.apple.AppleAccount.plist` |

### 6.2 机型 ↔ Product Type 速查
- iPhone：`iPhone<x>,<y>` 见 `ios_forensics.md` 已列。
- iPad：`iPad<x>,<y>`，如 `iPad13,1` = iPad Air 4、`iPad14,3` = iPad Pro 11" M2。
- 完整：theiphonewiki.com/wiki/Models。

### 6.3 区域 / 运营商
- `Info.plist` → `Phone Number`、`ICCID`。
- `/private/var/wireless/Library/Preferences/com.apple.commcenter.plist`：当前/历史 SIM 配置。
- `CellularUsage.db`、`DataUsage.sqlite`（WirelessDomain）：运营商、流量、最后激活时间。

---

## 7. iCloud 与同步基础

### 7.1 iCloud 数据类别
| 类别 | 默认是否 E2E | 取证可获 |
| --- | --- | --- |
| iCloud 备份 | 否（普通模式） | EPB / 商业工具下载 |
| iCloud Drive | 否 | 同上 |
| 照片 | 否 | 同上 |
| **钥匙串（iCloud Keychain）** | **是** | 需配对设备 + 6 位 iCloud 安全码 + 2FA |
| 健康 / Home / 屏幕使用时间 | 是 | 需密码 + 2FA + 设备授权 |
| 信息（iMessage） | 启用"信息储存于 iCloud"后 | 取决于"高级数据保护"是否开启 |
| Find My / 共享相簿 | 否 | |

### 7.2 Apple Advanced Data Protection（iOS 16.2+）
- 用户启用后，iCloud 几乎所有类别变为**端到端加密**，Apple 也无法响应执法令。
- 取证标志：在 Apple 配合的法律响应中拿不到内容，仅有元数据（设备列表、登录时间）。

### 7.3 iCloud 取证途径
1. **Apple ID + 密码 + 2FA 验证设备** → 商业工具（EPB、UFED Cloud Analyzer）登录抓取。
2. **从已授信的 PC 提 token**（`com.apple.AccountAuthenticator` SQLCipher / Keychain），免输密码。
3. **从已授信的设备**直接同步（设备登录 iCloud → 在另一台设备登录同 Apple ID 拉同步数据）。
4. **法律调取**（向 Apple 官方提交 LE Request）。

---

## 8. 比赛/实战题型与解法

### 8.1 概念辨析（选择/判断）
| 题型 | 答题套路 |
| --- | --- |
| 文件系统类 | iOS 10.3 起 **APFS**；之前 HFS+；区分 SSV、容器、卷 |
| 加密类型 | 整盘 + 逐文件双层；卷主密钥在 Effaceable Storage |
| BFU vs AFU | 看 Class C 是否可解；联系人/短信能否读 |
| Keybag 种类 | system / backup / escrow / iCloud / OTA |
| 越狱原理 | checkm8 = Boot ROM（永久），其余 = 内核漏洞（可补） |
| 备份密码不可恢复但可重置 | iOS 11+ 设置内重置（需锁屏密码） |
| 数据保护类 | A 锁屏即不可读；B 打开后保持；C AFU 即可（默认）；D BFU 可读 |
| Find My | 远程擦除/定位/激活锁；现场必断网 |
| TCC.db | 隐私授权日志 |
| Apple ID 标识 | DSID 数字 ID；AltDSID 在设备本地 |

### 8.2 实战题分类与决策

#### 题型 A：给 iTunes 备份目录，问设备/账号信息
1. 解 `Info.plist`（IMEI/Serial/型号/电话/最后备份时间）。
2. 看 `Manifest.plist` → `IsEncrypted`、`Applications`（已装 App）。
3. 看 `Status.plist` → 备份完整性、Snapshot。

#### 题型 B：给加密备份 + 不知道密码
1. 试默认密码（`1234`、`123456`、`0000`、设备 ICCID/IMEI 末 6 位、生日）。
2. `itunes_backup2hashcat` → `hashcat -m 14800`。
3. 设备解锁可拿 → "重置所有设置"重做新备份。

#### 题型 C：给越狱物理镜像 / 文件系统目录
1. 直接进 `/private/var/mobile/`。
2. 列 `Containers/Data/Application/<UUID>` → 由 `applicationState.db` 反查 bundle id。
3. 关键库直接 SQLite 读（多数无密码）。
4. plist 用 `plutil -p` / `ccl_bplist`。

#### 题型 D：要找"启用 Find My / 远程擦除时间"等
- `RootDomain/Library/Lockdown/data_ark.plist`
- `/private/var/mobile/Library/FindMy/`
- `KnowledgeC.db` 含设备解锁/加锁历史
- `/private/var/mobile/Library/Preferences/com.apple.MobileMeAccounts.plist`

#### 题型 E：BFU 设备能拿到什么
- 列出 BFU 可读路径（D 类）：紧急联系人、闹钟、Wi-Fi（部分）、安装 App 清单、TCC 部分。
- 不能：联系人、短信、相册、App 数据。

#### 题型 F：怎么判断 iOS 版本与文件系统
- `Info.plist` → `Product Version`；< 10.3 一般 HFS+，≥ 10.3 APFS。
- `Status.plist` 也含版本。

---

## 9. 命令速查

```bash
# 设备配对 + 备份
idevicepair pair
idevicebackup2 backup --full /tmp/backup
idevicebackup2 -i info /tmp/backup
idevicebackup2 -p enable 1234 /tmp/backup     # 启用加密备份(密码 1234)

# 设备信息
ideviceinfo -k UniqueDeviceID
ideviceinfo -k SerialNumber
ideviceinfo -k InternationalMobileEquipmentIdentity
ideviceinfo -k ProductType
ideviceinfo -k ProductVersion

# AFC 浏览
afcclient ls /DCIM
ifuse /mnt/iphone

# 备份解密（已知密码）
pip install iOSbackup
python -c "from iOSbackup import iOSbackup;b=iOSbackup(udid='<UDID>',cleartextpassword='1234',backuproot='/Backup');b.getFolderDecryptedCopy('HomeDomain','/tmp/out')"

# 备份密码爆破
python /opt/itunes_backup2hashcat.py /Backup/<UDID>/ > h.txt
hashcat -m 14800 h.txt rockyou.txt -O

# Manifest.db 检索
sqlite3 Manifest.db "SELECT fileID,domain,relativePath FROM Files WHERE relativePath LIKE '%sms.db%';"

# bplist
plutil -p file.plist
plutil -convert xml1 in.plist -o out.xml
python -m ccl_bplist file.plist                # NSKeyedArchiver

# 越狱 SSH 后取数据
ssh root@<iphone>
tar --exclude=/proc --exclude=/sys -czf /var/mobile/Media/dump.tgz /private/var/mobile /private/var/keybags
exit
scp root@<iphone>:/var/mobile/Media/dump.tgz .

# Mac Absolute Time 转换（iOS 大量时间戳基准 2001-01-01）
python -c "import datetime;print(datetime.datetime(2001,1,1)+datetime.timedelta(seconds=716832000))"
```

---

## 10. 常见坑

1. **iOS ≠ macOS 文件系统时间起点**：Mac Absolute Time = `seconds since 2001-01-01 UTC`，比 Unix 时间戳小 978307200 秒；新版 sms.db 是**纳秒**。
2. **未加密备份缺数据**：通话记录、Keychain、Health、Wi-Fi 密码全部缺失，**取证一律加密备份**。
3. **加密备份密码丢失但有设备**：可"重置所有设置"换密码（不丢用户数据），但**操作前必须先做镜像**。
4. **`-wal` `-shm` 必须随主库一起拷**，否则最近消息丢失。
5. **bplist 套 NSKeyedArchiver**：双层 plist，要二次反序列化（`ccl_bplist` 或 `plistlib + NSKeyedUnarchiver`）。
6. **配对记录（Lockdown plist）即"设备钥匙"**：取得 PC 上的 `<UDID>.plist` 即可在不输密码情况下做加密备份（设备需 AFU）。
7. **iOS 16+ SSV**：尝试 root 写入 `/usr/bin/` 等系统路径会破坏 SSV → 设备进 recovery；越狱要选 rootless。
8. **checkm8 仅支持 A11 及以下**：A12+ 设备没有 ROM 永久越狱方案，依赖 1day。
9. **Find My 可远程擦除**：现场必须**飞行模式 + SIM 卡取出 + 法拉第袋**，否则证物秒丢。
10. **多账号/多设备 iCloud**：一个 Apple ID 可能绑了多台设备，各设备又可能登过多个 Apple ID；先看 `accounts3.sqlite` 把账号梳清楚。
11. **激活锁**（Activation Lock）：设备抹除后无 Apple ID 密码无法激活，硬件无价值；取证报告需注明状态。
12. **APFS 快照**：`/private/var/.snapshot/` 可能含历史快照；越狱可访问，常被忽略。

---

## 11. 交叉链接
- `ios_forensics.md`：iOS 取证总入口
- `ios_app_parsing.md`：iOS App 数据解析专题
- `ios_logs.md`：iOS 日志体系
- `extraction_methods.md`：取证方法五级对照
- `wechat_deep_dive.md`：iOS 微信路径与表
- `device_basic_info.md`：跨平台设备信息提取
- `timestamps_reference.md`：Mac Absolute Time 与各家时间戳
