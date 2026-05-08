# 屏幕锁 / 应用锁 / 隐私锁 / 各类密码取证

> 适用：手机/平板设备的"锁"类题目。题目特征：见到 `gatekeeper`、`synthetic password`、`spblob`、`gesture.key`、`password.key`、`locksettings.db`、`SEP`、`Class Key`、`AppLock`、`隐私空间`、`保险箱`、`私密相册`、`屏幕使用时间密码`、`Screen Time`、`SIM PIN/PUK`、`Activation Lock`、`Find My`、`Bootloader OEM lock`、`FRP`、`Knox` 等。
>
> 与 `emulator_clone_forensics.md`（分身、Work Profile、双开）配套阅读。

---

## 1. 锁的总分类（题目定位用）

| 类别 | 谁守门 | 影响 | 取证难点 |
| --- | --- | --- | --- |
| **屏幕锁**（Lock Screen） | OS + TEE/SEP | 数据加密密钥派生；锁屏=数据EBE | 必爆破/绕；硬件限速 |
| **SIM 锁**（PIN/PUK） | 卡 + 运营商 | 通话/网络功能；不影响设备数据 | 错 3 次锁，错 10 次报废 |
| **激活锁 / FRP** | Apple iCloud / Google FRP | 抹机后能否激活 | 无原账号难绕过 |
| **Bootloader 锁**（OEM） | 厂商 | 能否刷机/物理提取 | 解锁=数据擦除 |
| **应用锁**（App Lock） | OS 厂商 / 三方 App | App 启动门 | 通常不加密数据 |
| **隐私空间 / 第二空间 / Secure Folder** | OS 厂商 | 独立加密用户分区 | 三星 Knox 难度高 |
| **隐私文件夹 / 保险箱 / 私密相册** | App 自己实现 | 隐藏 + 加密文件 | App 自有算法 |
| **屏幕使用时间密码** | iOS Screen Time | 限制 App 使用 | 4 位 PIN，常被用作"二次锁" |
| **企业 MDM / DPC** | 公司 | 强制策略 + 远程擦除 | 离线时仍生效 |
| **特定 App 内锁**（微信钱包/支付宝） | App 自身 | 特定动作前再次输 | 多为 6 位数字，独立加密 |
| **iCloud 钥匙串恢复码 / 6 位安全码** | Apple | 同步 iCloud Keychain | 需信任设备 + 短信验证 |

---

## 2. Android 屏幕锁机制（**核心考点**）

### 2.1 锁类型
| 类型 | 强度 | 何处影响 |
| --- | --- | --- |
| **None / Swipe** | 无 | 数据不加密（FBE 仍走 default key） |
| **PIN** | 4–17 位数字 | 派生 user key |
| **Pattern**（手势） | 9 点连线，3–9 个点 | 同上，按 SHA1(节点序列) 处理 |
| **Password** | 字母数字 | 同上 |
| **Biometric**（指纹/面容） | 仅作为辅助解锁 | 不直接解 KEK，只在已解锁会话内"代签"；**首次开机/重启必须输 PIN/密码** |

### 2.2 存储演进
| Android 版本 | 锁屏存储 | 备注 |
| --- | --- | --- |
| 4.x – 5.x | `/data/system/gesture.key`（手势 SHA1）`password.key`（密码 hash） | 文本明文 hash，可离线爆破 |
| 6.0 – 8.x | **Gatekeeper**（HAL 调 TEE）+ `locksettings.db` | TEE 限速；离线仅能拿到 hash |
| 9.0+ | **Synthetic Password**（spblob）+ Weaver（Pixel 系，硬件限速器） | 硬件计数器，错 N 次设备级延迟/抹除 |

### 2.3 关键文件（按版本）
```
Android 4–5：
  /data/system/gesture.key       # 20 字节 SHA1(序列)
  /data/system/password.key      # 40+72 字节 SHA1+MD5(salt+pwd)
  /data/system/locksettings.db   # 含 lockscreen.password_salt
Android 6+:
  /data/system/locksettings.db   # 锁屏元数据（hash 存放在 gatekeeper 黑盒，DB 仅有 spblob 引用）
  /data/system/users/<uid>/      # 多用户锁屏元数据
  /data/system_de/<uid>/spblob/  # synthetic password blob
  /data/system/users/<uid>/lockSettings.db
  /data/misc/keystore/           # 软 keystore（旧）
  /data/misc/keystore_v2/        # AOSP 11+ keystore2
```

### 2.4 离线爆破（Android 4–5）
```python
# pattern.key（手势）
import hashlib
sha1 = open('gesture.key','rb').read().hex()
for n in range(2**18):
    seq = []
    x = n
    used = set()
    bad = False
    for _ in range(min(9,(x.bit_length()+3)//4)):
        d = x & 0xf; x >>= 4
        if d>=9 or d in used: bad=True; break
        seq.append(d); used.add(d)
    if bad or not seq: continue
    if hashlib.sha1(bytes(seq)).hexdigest()==sha1:
        print('PATTERN:', seq); break

# password.key（PIN/密码）
import hashlib, sqlite3
salt = sqlite3.connect('locksettings.db').execute(
  "SELECT value FROM locksettings WHERE name='lockscreen.password_salt'").fetchone()[0]
salt_hex = '%016x' % (int(salt) & 0xffffffffffffffff)
target = open('password.key','rb').read()[:40].decode()
for cand in (str(i).zfill(4) for i in range(10000)):
    sha1 = hashlib.sha1((cand+salt_hex).encode()).hexdigest()
    if sha1 == target.lower(): print('PIN:', cand); break
```

> **Android 4–5 PIN 4 位**：100% 几秒爆破。
> **复杂密码**：用 hashcat `-m 5800` (Android PIN/Password)。

### 2.5 Android 6+ Gatekeeper / Synthetic Password
- 锁屏 PIN → Gatekeeper HAL → TEE 内计算 `gk_response = HMAC(HW_key, password || nonce)` → 与登记态比对。
- 限速由 TEE/SEP 硬件实现：离线没有 hash 可拿，**离线爆破不可行**。
- spblob：`/data/system_de/<uid>/spblob/<handle>.<index>.<n>`，含被 user key 包裹的 KEK；`<handle>` 由 Weaver/Gatekeeper 生成。
- **解 spblob = 必须现场设备爆破**：商业全提取（Cellebrite Premium / GrayKey 等）走的就是这条。
- Weaver（Pixel 6+）：Titan M 内独立限速器，错 5 次后指数级延迟，无法绕。

### 2.6 已解锁/已知密码场景
- 设备处于 **AFU**（After First Unlock）→ 数据已解密挂载，root 后直接读 `/data/data/`、`/data/user/0/`。
- **保持 AFU**：不重启、屏幕亮、维持电量。
- 现场实操：**屏幕画面不要熄**，必要时禁用自动锁屏（系统设置或物理光感持续）。

### 2.7 屏锁绕过常见手法（**多数已无效**）
| 手法 | 适用版本 | 现状 |
| --- | --- | --- |
| `pm disable lockscreen` | Android 4 旧 | 已无效 |
| 删除 `gesture.key`/`password.key` | 4–5 | 6+ 无文件可删 |
| Recovery 中删 `locksettings.db` | 5–7 | 8+ 不再依赖此 DB |
| ADB 配对绕（`pair.lock`） | <8 | 修复 |
| Smart Lock（受信任设备/位置/语音） | 5+ | 仍可被利用：现场如有受信地点/蓝牙设备**自动解锁**！ |
| Face Unlock 弱版本（前置摄像头） | <11 | 部分老机被照片绕 |

> **Smart Lock 是取证窗口期**：嫌疑人若启用了"已配对蓝牙手表/车机/家中地址"自动解锁 → 只要把设备带回该环境就自动解。

### 2.8 工具
- 商业：**Cellebrite Premium / GrayKey / 美亚 / 盘古石**（针对各 SoC + Android 版本，支持 BFU/AFU 不同等级）。
- 开源：**hashcat -m 5800/13600**（旧版）；新版无开源方案。
- Magisk / TWRP（已解锁 BL）：可挂载 `/data` 但**不解 FBE**；FBE 锁屏密码不破照样读不到 CE 数据。

---

## 3. iOS 屏幕锁

### 3.1 机制（与 `ios_fundamentals.md` 互参）
- 锁屏密码 → SEP（Secure Enclave）派生 → 解 keybag → 解 Class A/B/C 文件密钥。
- **SEP 限速**（**最难绕**）：
  - 默认 4 位 PIN：错 6 次延迟 1 分钟，逐级增加；
  - 错 10 次后视设置可触发抹机（"擦除数据"开关）。
- 设备 UID 烧死在 SEP；离线不能复制密码到云端机器爆破（必须**机上爆破**）。

### 3.2 BFU / AFU
- 详见 `ios_fundamentals.md` §2.4；锁屏 = 当前不可解 Class A，但 AFU 下 C 类仍解。
- **现场处置铁律**：保持 AFU + 离网。

### 3.3 越狱辅助
- checkm8（A11 及以下）：可在 ramdisk 中**机上爆破**（仍受 SEP 限速）；
- A12+：无 ROM 永久越狱，依赖 1day。

### 3.4 屏幕使用时间密码（Screen Time PIN，**重要彩蛋**）
- 4 位 PIN，独立于锁屏密码。
- 用于"使用限制"、"内容隐私限制"、"账户更改禁止"等。
- **iOS 12 起本地存于** `Library/Preferences/com.apple.ScreenTimeAgent.plist` 或 keychain。
- **取证用法**：
  1. 嫌疑人若用此密码"二次保护"账户更改 → 拿到此密码可改 Apple ID。
  2. iOS 13 之前曾以**明文 SHA1**存 keychain（`RestrictionsPasswordKey`+`RestrictionsPasswordSalt`），可离线 4 位爆破：
     ```python
     import hashlib, base64
     k = base64.b64decode('<RestrictionsPasswordKey>')
     s = base64.b64decode('<RestrictionsPasswordSalt>')
     for n in range(10000):
         pin = f'{n:04d}'
         if hashlib.pbkdf2_hmac('sha1', pin.encode(), s, 1000, 20)==k:
             print(pin); break
     ```
  3. iOS 13.4+ 改 SEP 保护，离线不可破。

### 3.5 信任电脑配对（**绕屏锁的另一面**）
- 若设备**已 AFU + 信任过某 PC**，从该 PC 取出 lockdown plist（含 EscrowBag）→ 不需要锁屏密码即可对设备做加密备份。
- 详见 `ios_fundamentals.md` §5.1。

---

## 4. SIM 卡 PIN / PUK

### 4.1 机制
- SIM 卡内置计数器：
  - **PIN**：默认 `1234` / `0000`（运营商出厂值）；错 3 次锁。
  - **PUK**：8 位，运营商提供；错 10 次卡报废（无法解锁）。
- 与设备数据**完全无关**：不影响相册、消息、文件，只影响通话/短信/上网。

### 4.2 取证策略
- 从运营商法律调取 PUK + IMSI/ICCID 关联记录。
- 取卡用读卡器（Cellebrite SIM Reader、Quantaq ChipDNA），**不碰 PIN 也能读 SIM 内 ADN/SDN/SMS/LOCI**。
- 若已锁卡且 PUK 不可得：把 SIM 取出对手机仍可作离线取证；卡内数据需告知"需运营商配合"。

### 4.3 题型
- "SIM 锁了怎么办" → 联系运营商出 PUK；同时手机本体取证不受影响。
- "SIM 内有什么数据" → ICCID/IMSI/MSISDN/LOCI（最后位置区）/最近拨号/SMS（部分）。
- 详见 `network/cellular_forensics.md`（如有）。

---

## 5. Bootloader 锁 / OEM Unlock / FRP

### 5.1 概念
- **Bootloader 锁**：未解锁时只允许 fastboot 刷签名固件；解锁后才能刷 TWRP/Magisk/物理提取。
- **OEM Unlock 开关**（开发者选项内）：必须先在系统内打开（要求登录账号 + 等待 7 天，部分厂商）；之后 fastboot 才能 `flashing unlock`。
- **解锁 = 抹机**：所有厂商均会触发用户分区擦除，**对取证完整性是灾难**。
- **FRP（Factory Reset Protection）**：抹机后再次激活需登录原 Google 账号；社工或刷机绕过的难度高。

### 5.2 取证含义
- BL 已锁 → 只能走 ADB / iTunes 风格的逻辑/文件系统提取，**物理 dd 不行**。
- BL 已解锁（嫌疑人为越狱/装 ROM 自己解过）→ **大喜事**，可直接 fastboot boot ramdisk + dd `/dev/block/by-name/userdata`。
- 现场看 BL 状态：开机时 splash 警告 / `fastboot oem device-info` / 部分厂商需进 fastboot。

### 5.3 厂商 BL 解锁政策（速记）
| 厂商 | 政策 |
| --- | --- |
| Pixel | 默认允许，开关在开发者选项 |
| 三星 | 海外版可解（CSC 决定）；中/韩/美运营商版不可解 |
| 华为 | 2018 年后**官方关闭**解锁通道 |
| 小米 | 需绑定账号 + 申请等待（72h–168h） |
| OPPO/一加 | 需深度激活 + 等待 |
| Vivo | 几乎不允许 |
| Realme | 部分机型支持 |
| 索尼 | 官方门户解 |
| Motorola | 官方门户解 |

### 5.4 商业取证如何应对锁定 BL
- **Cellebrite Premium**：对部分高通/联发科 SoC 有 EDL（Emergency Download）9008 模式利用，可在不解锁 BL 情况下提取。
- **GrayKey**（Android 模块）/ **MSAB XRY** / **盘古石**：类似手法。
- 取证器材厂常按"芯片/版本/补丁号"维护支持矩阵。

---

## 6. 应用锁 / 隐私空间 / Secure Folder

### 6.1 系统应用锁（**核心**）
| 厂商 | 名称 | 机制 | 数据库 |
| --- | --- | --- | --- |
| MIUI | 应用锁 | 锁屏密码 / 单独密码 / 指纹；启动 App 前 SystemUI 弹框 | `/data/system/users/0/applocker.xml`、`com.miui.securitycenter` |
| EMUI / HarmonyOS | 应用锁 | 同上 | `com.huawei.systemmanager` |
| ColorOS / OPPO | 应用加密 | 同上 | `com.coloros.safecenter` / `com.oppo.privacysafe` |
| OriginOS / Vivo | 应用锁定 | 同上 | `com.iqoo.secure` / `com.vivo.permissionmanager` |
| One UI（三星） | App Lock（设置 > Biometrics）/ Secure Folder | 简单：锁前弹生物认证；Secure Folder 见 §6.3 | `com.samsung.android.applock` |
| Honor / Magic UI | 应用锁 | 同 EMUI | |

> 关键认知：**系统应用锁 ≠ 数据加密**。多数情况下只挡 UI 启动，App 沙盒内数据仍按用户主分区加密（FBE class CE）。**root 后直接进 `/data/user/0/<pkg>` 取数据无视应用锁**。

### 6.2 三方应用锁
| App | 包名 | 机制 |
| --- | --- | --- |
| AppLock（DoMobile） | `com.domobile.applock` / `com.domobile.applockwatcher` | 监听 `frontmost` Activity，弹自家锁屏 |
| Norton App Lock | `com.symantec.applock` | 同上 |
| Lockdown / Smart AppLock | 多家 | 同上 |

> 同样**不加密数据**；root 后直接读取 `/data/data/com.target.app/`。

### 6.3 隐私空间 / 第二空间 / Secure Folder（**真加密**）
| 厂商 | 名称 | userId | 加密 |
| --- | --- | --- | --- |
| 小米 | 第二空间 | 10/11 | 系统多用户 + 独立锁屏密码（**独立 CE 密钥**） |
| 华为 | 隐私空间 PrivateSpace | 10/11 | 同上 |
| 三星 | **Secure Folder**（Knox） | 95 | **Knox Container 独立加密**，密钥由 Knox 强化（**最难**） |
| OPPO/一加 | 私密保险箱 / 私密空间 | 999 | 用户级 + 独立 PIN，部分模型独立加密 |
| Vivo | 私密空间 / 隐藏应用 | 95/999 | 同上 |

#### 取证策略
- 必须**单独获得空间密码**才能解 CE。
- 主用户解锁后 → 子空间数据仍为 EBE，root 也读不到（FBE 由独立 class key 保护）。
- 三星 Secure Folder：Knox 由 TIMA / Trustzone 独立保护 → **常规越狱/root 无效**，商业全提取也支持有限。

#### 数据路径
```bash
ls /data/user/                   # 看到 0/10/95/999 等
ls /data/user/95/                # 三星 Secure Folder（如有）
ls /data/user/999/               # 小米/OPPO/Vivo/华为 应用分身/隐私空间
ls /data/user_de/<uid>/          # 设备级（FBE Device Encrypted），BFU 即可读
cat /data/system/users/userlist.xml   # 列出所有用户 + flags
```

flags 速读：
- `0x10`(16) = MANAGED_PROFILE（工作资料）
- `0x40`(64) = DISABLED
- `0x400`(1024) = CLONE_PROFILE（应用克隆，Android 11+）
- `0x100`(256) = QUIET_MODE_ENABLED

---

## 7. App 内置锁 / 保险箱 / 私密相册

### 7.1 类型
| 类型 | 例 | 数据 |
| --- | --- | --- |
| **App 启动密码** | 微信"声音锁"/ 钱包密码 / 支付宝手势 | 数据库存 hash |
| **图库私密相册** | 相册 → 隐藏；魅族/小米/三星都有 | 数据库 + 文件移动 |
| **第三方保险箱** | "保险箱 PRO"、"私密相册"、"加密相册" | 文件移动到 App 沙盒 + 自家加密 |
| **加密笔记 App** | Standard Notes / Notion 私密块 | 端侧加密 |

### 7.2 系统私密相册存储位置
| 厂商 | 路径 |
| --- | --- |
| 小米 | `/data/user/<uid>/com.miui.gallery/cache/secret/`、私密相册 DB `gallery_secret.db` |
| 华为 | `/data/user/<uid>/com.huawei.photos/files/SafeBox/` |
| 三星 | Secure Folder 内（`/data/user/95/`） |
| OPPO | `/data/user/<uid>/com.coloros.gallery3d/cache/safe/` |

> 文件多数 **重命名为 hash + 修改首字节**，不直接是 jpg/png。

### 7.3 第三方保险箱解法
1. 找 App 沙盒：`/data/data/<pkg>/files/encrypted/`、`Secret/`、`Vault/`。
2. 文件名常 base64/hash；前几字节多被 XOR 或 AES 处理。
3. **看 SO**：算法多固定（AES-CBC 固定 IV、XOR 0x66 整文件、首 1KB 加密其余明文）。
4. frida hook `read`/`write` 或 `EVP_DecryptInit_ex` 拿运行时数据。
5. 已知明文配对（如保险箱里能看到部分缩略图，与原图配对推 mask）。

### 7.4 微信钱包/支付宝支付密码
- 6 位数字 PIN，独立于登录密码。
- 服务端校验为主，本地仅缓存 hash + 风控数据。
- 不能"破解"，但可通过短信验证码 + 实名重置（合法授权）。
- 取证**目标不是获取 PIN，而是看交易流水/收款方/对账**。

### 7.5 屏幕使用时间 / 应用使用时间限制（双平台）
- iOS Screen Time PIN：见 §3.4。
- Android Digital Wellbeing：可对 App 设时长限制密码（部分厂商）。
- 解决路径：刷机/重置 OS 不动用户数据时通常不重置此类 PIN。

---

## 8. 激活锁 / Find My / Knox Guard / FRP

### 8.1 iCloud 激活锁（Activation Lock）
- 抹除/重置后再次激活必须输原 Apple ID 密码。
- 设备硬件唯一 ECID 与 Apple ID 在云端绑定，无法离线绕。
- 取证含义：
  - **抹机后无密码 = 硬件无价值**（激活不了 → 不能进系统）。
  - 现场必须**飞行模式 + SIM 取出 + 法拉第袋**避免被远程触发"丢失模式/抹除"。
  - 已登录设备：尽快取证完毕，避免 24 小时窗口期。

### 8.2 Google FRP（Factory Reset Protection）
- Android 5.1+，恢复出厂后激活需原 Google 账号密码。
- 已登录的 FRP 标记存于 `/persist`、`/frp` 分区。
- 绕过手段：社工 / 公开 1day / 替换 frp 分区（厂商相关）。
- 取证：能登录原账号最佳；否则部分商业工具支持 EDL 改 frp。

### 8.3 三星 Knox Guard / Verizon 锁
- 企业 / 运营商可远程锁定设备（防逃单）。
- 锁状态写入 Knox 计数器，**反向触发会熔断 e-fuse**：刷非官方固件后 KNOX=0x1 永久标记，影响 Samsung Pay / Secure Folder。
- 取证含义：碰到 Knox 锁定设备 → 联系运营商/企业管理员获 IMEI 解锁码。

---

## 9. 现场处置流程（针对锁/密码）

```
1. 拿到设备 → 判状态
   ├─ 屏幕亮 + 已解锁 → 立即关自动锁屏 + 提高亮屏时间（设置）
   ├─ 屏幕亮 + 锁屏 (AFU) → 不重启、不让没电；尝试 Smart Lock 环境（蓝牙、信任地点）
   └─ 已关机 (BFU) → 充电；若有原账号信息直接尝试输 1 次取得 AFU
2. 网络隔离
   ├─ iOS：飞行模式 + SIM 卡取出 + 法拉第袋
   └─ Android：同上 + 关闭 Find My Device + Knox Guard 警觉
3. 信息侦察
   ├─ 询问/搜查现场是否有：
   │   - 锁屏密码（便条/记事本/通讯录里）
   │   - 已配对蓝牙设备（手表/车机/AirTag）→ Smart Lock
   │   - 受信任电脑（lockdown plist）
   │   - 嫌疑人 Apple ID / Google 账号 + 2FA 设备
   └─ 记录设备型号、iOS/Android 版本、补丁日期、SoC、BL 状态
4. 取证
   ├─ AFU/已解锁 → 尽快备份 + 物理（如 BL 可解）
   ├─ BFU + 商业全提取支持 → 上 GrayKey / Premium
   └─ BFU + 不支持 → 仅能做 BFU 物理（D 类数据）+ 待技术更新
5. 文档化
   - 每个尝试输入密码次数（避免触发抹机阈值）
   - 每个开关变更（飞行模式开/关、亮屏时间）
   - 全程视频记录（合规）
```

---

## 10. 锁/密码与数据加密的关系（**必懂**）

| 锁 | 真正加密数据吗 | 影响 |
| --- | --- | --- |
| 屏幕锁（PIN/密码/手势） | **是**（FBE class CE / iOS Class A-C） | 锁定时 CE 数据 EBE 不可读 |
| 屏幕锁 = None/Swipe | **否**（仍走 default key） | 数据"加密"但 default key 无意义 |
| 系统应用锁 | **否**（仅 UI 拦截） | root 后视若无睹 |
| 三方 AppLock | **否** | 同上 |
| 隐私空间/第二空间/Secure Folder | **是**（独立 user CE） | 子空间密码不破即不可读 |
| App 私密相册 / 保险箱 | **取决于 App**：多为文件搬移 + 简单异或或 AES | 算法分析 + key 取证 |
| 微信/支付宝交易 PIN | **否**（服务端校验为主） | 不影响本地 db 解密 |
| Screen Time PIN | **否**（仅 iOS 限制层） | 但 iOS 13.3- 可离线爆破，作为辅助情报 |
| SIM PIN | **否**（仅卡功能） | 与设备数据无关 |
| Bootloader 锁 | **否**（影响刷机） | 影响物理提取手段 |
| 激活锁/FRP | **否**（数据已被擦除） | 影响二次激活 |

> **铁律**：见到"锁"先问"它是 UI 锁还是密钥锁"。**UI 锁 root 即破，密钥锁必须输密码或硬件爆破**。

---

## 11. 比赛/实战常见题与解法

| 题 | 类型 | 解法 |
| --- | --- | --- |
| 给 Android 4.4 镜像，问锁屏密码 | 屏锁 | 离线读 `gesture.key`/`password.key` + salt → SHA1/PBKDF2 4 位爆破 |
| Android 10 设备已 AFU root，问能否读 App 数据 | 屏锁 | 能；CE 已解 |
| Android 11 BFU，能读什么 | 屏锁 | 仅 DE 数据：`/data/user_de/<uid>/`、紧急联系人、Wi-Fi 部分 |
| 三星 Secure Folder 数据怎么取 | 隐私空间 | Knox 强化；需 Secure Folder 密码或商业全提取专项 |
| 小米第二空间路径 | 隐私空间 | `/data/user/10/<pkg>` 或 `/data/user/11/<pkg>` |
| 系统应用锁开了能拦取证吗 | 应用锁 | 不能；root 后直接读沙盒 |
| 三方 AppLock 怎么破 | 应用锁 | 同上；不影响数据 |
| iOS Screen Time PIN 4 位 | 屏使用 | iOS≤13.3 离线爆破；之后需机上输 |
| iOS BFU 能拿什么 | 屏锁 | D 类（紧急联系人、Wi-Fi、闹钟、安装清单等） |
| iCloud 激活锁绕不过怎么办 | 激活锁 | 联系 Apple Law Enforcement 或要求嫌疑人/家属配合输入 |
| Bootloader 已锁的高通设备物理提取 | BL 锁 | 试 EDL 9008 + 商业工具；否则只能逻辑提取 |
| 嫌疑人手机 PIN 不知道但有他蓝牙手表 | Smart Lock | 把手表带到设备旁，自动解锁 |
| SIM 卡 PIN 锁 3 次锁了 | SIM | 联系运营商出 PUK；手机数据不受影响 |
| 微信支付密码忘了能解吗 | App 内锁 | 不能本地"解"，重置流程；取证关注交易记录 |
| 私密相册图片打不开 | App 内锁 | 看路径与算法（多 XOR / AES + 改首字节）；frida hook 拿 key |
| 嫌疑人启用 Knox Guard，设备远程锁了 | 企业锁 | 联系运营商/企业管理员获解锁码 |
| 找回 iPhone 已开"丢失模式" | Find My | 飞行模式 + 法拉第袋；防止远程擦除 |

---

## 12. 命令速查

```bash
# Android 屏锁元数据
sqlite3 /data/system/locksettings.db ".tables"
sqlite3 /data/system/locksettings.db "SELECT name,value FROM locksettings;"
ls /data/system_de/0/spblob/
cat /data/system/users/userlist.xml          # 多用户清单
ls /data/user/                                # 看是否有分身/隐私空间

# 旧版 Android PIN 离线爆破
hashcat -m 5800 password.key dict.txt -O    # Android 4-5
# Pattern：自写脚本（见 §2.4）

# Android 9+ Synthetic Password 不离线
# 必须商业工具 / Cellebrite Premium

# iOS Screen Time PIN（≤13.3）
# 从 keychain 拿 RestrictionsPasswordKey/Salt
python pbkdf2_brute.py <key_b64> <salt_b64>   # 4 位 1000 轮即破

# 应用锁元数据（小米）
adb shell cat /data/system/users/0/applocker.xml
adb shell pm dump com.miui.securitycenter | grep -i lock

# 多用户列表
adb shell pm list users
adb shell ls /data/user/

# 三星 Secure Folder 状态
adb shell pm list packages | grep knox
# 不能直接读 /data/user/95/，需要 Secure Folder 解锁

# Bootloader 状态
adb reboot bootloader
fastboot oem device-info             # 看 unlocked: yes/no（部分厂商）
fastboot getvar unlocked

# iOS 配对/信任
ideviceinfo -k UniqueDeviceID
# Lockdown plist 路径
ls "%PROGRAMDATA%\Apple\Lockdown\"   # Win
ls /var/db/lockdown/                 # macOS

# SIM 卡
# 用 Cellebrite SIM Reader / 通用 PC/SC + scriptor
scriptor -r 'Generic Reader'
```

---

## 13. 常见坑

1. **"破解屏锁"** ≠ "解出加密数据"：FBE class CE 与屏锁 PIN 绑定，没 PIN 即便 root 也读不到 CE。
2. **AFU 状态价值巨大**：很多人现场重启设备求"干净环境" → 一脚踩坏取证，回到 BFU 损失 80% 可读数据。
3. **Smart Lock 是合法解锁路径**：现场带回受信地点/设备即可自动解锁，**别忽视**。
4. **三星 Secure Folder ≠ 应用分身**：前者 Knox 加密，破不了；后者 userId=999 系统级，主密码即可。
5. **OEM Unlock 触发抹机**：除非你有完整镜像备份并接受抹机，否则别轻易 fastboot unlock。
6. **激活锁 + 抹机 = 设备废铁**：取证策略必须保留账号信息；不要先抹再考虑。
7. **应用锁 / AppLock 没卵用**：root + 直接读沙盒，应用锁不构成加密屏障。
8. **iOS Screen Time PIN 离线爆破窗口窄**：仅 iOS ≤ 13.3，之后改 SEP。
9. **SIM PIN 与手机锁概念不同**：嫌疑人说"我手机锁了"先确认是哪种。
10. **BFU 误判**：iOS / Android FBE 都是首次输密码后才进 AFU；按下指纹 ≠ 解锁，会维持 BFU。
11. **限速器是硬件级**：SEP / Weaver / Titan 限速无法软件绕；商业工具的"全提取"也只是工程化每次试一次再等待。
12. **多用户混淆**：题目问"用户密码"可能指主用户、Work Profile、Secure Folder 任一；先 `cat userlist.xml` 看清。
13. **微信钱包/支付宝 PIN 不能"破解"**：取证目标是流水，不是 PIN。
14. **Find My 误删风险**：现场不离网，远程擦除可能在 1–10 分钟内执行；法拉第袋是必须。
15. **KNOX e-fuse 一次性**：刷过非官方固件 → KNOX=0x1 永久写入 → Knox Container/Pay 永久不可用，**对未来取证无影响但对设备价值评估有影响**。
16. **现场试错次数会被记录**：iOS / Android 都有"错误次数"计数，到阈值触发抹机；**任何尝试都要记录在案**。

---

## 14. 交叉链接
- `emulator_clone_forensics.md`：应用分身 / 双开 / Work Profile / 隐私空间路径速查
- `extraction_methods.md`：BL 锁/AFU/BFU 状态决定可用提取方法
- `ios_fundamentals.md`：BFU/AFU、SEP 限速、信任 PC 配对
- `ios_logs.md`：解锁/锁屏事件日志（`/display/isBacklit`、`/device/isLocked`）
- `device_basic_info.md`：设备型号/补丁/Knox 状态识别
- `network/cellular_forensics.md`（如有）：SIM 卡详细
- `anti_forensics_and_misleading.md`：应用锁/隐私空间常作反取证手段
- `apk_crypto_analysis.md`：保险箱 App 自家加密算法逆向
- `database_forensics.md`：私密相册数据库结构
