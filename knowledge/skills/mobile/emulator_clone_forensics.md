# 模拟器 / 双开 / 分身取证方法论

> 适用：检材是 Android 模拟器（雷电/夜神/MuMu/BlueStacks/逍遥等）、PC 上的虚拟手机镜像，或真机内有"应用双开/分身/工作资料"。题目特征：见到 `Nox`、`Ldplayer`、`MuMu`、`BlueStacks`、`Genymotion`、`AVD`、`vmdk`、`qcow2`、`/data/user/0`、`/data/user/10`、`/data/user/999`、`Work Profile`、`xspace`、`AppClone`、`MIUI 双开`、`分身应用` 等。

---

## 1. 模拟器识别（先判类型）

### 1.1 PC 端文件特征
| 模拟器 | 默认安装/数据路径 | 镜像格式 |
| --- | --- | --- |
| **雷电（LDPlayer）** | `C:\LDPlayer\LDPlayer<ver>\vms\leidian<n>\` | `*.vmdk`（VirtualBox 改） |
| **夜神（Nox）** | `C:\Program Files\Nox\bin\BignoxVMS\nox\` | `*.vmdk`（VirtualBox 改） |
| **MuMu（网易）** | `C:\Program Files\Netease\MuMu\vms\` | `*.vmdk` 或 `*.qcow2`（新版基于 QEMU/KVM） |
| **MuMu Pro（手游版）** | `C:\Program Files\Netease\MuMuPlayer-12.0\vms\` | `*.qcow2` |
| **BlueStacks** | `C:\ProgramData\BlueStacks_nxt\Engine\<rvc64/Nougat64>\` | `*.vhd` / `*.vdi` / `*.bstk` |
| **Genymotion** | `~/.Genymobile/Genymotion/deployed/` | `*.vbox` + `*.vmdk` |
| **Android Studio AVD** | `~/.android/avd/<name>.avd/` | `userdata-qemu.img` (yaffs2/ext4)、`system.img` |
| **WSA**（Windows Subsystem for Android） | `%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_*\LocalCache\` | `system.vhdx`、`userdata.vhdx` |
| **逍遥（MEmu）** | `C:\Program Files\Microvirt\MEmu\MemuHyperv VMs\` | `*.vmdk` |

### 1.2 Android 内部识别（运行时）
检测模拟器常见指纹：
```bash
# 设备信息中的特征
getprop ro.product.brand    # generic / Genymotion / nox / mumu
getprop ro.product.model    # SM-G900P (Genymotion) / Nox / Custom Phone (MuMu) / MEmu
getprop ro.product.manufacturer
getprop ro.kernel.qemu      # 1 → 模拟器
getprop ro.hardware         # ranchu/goldfish/ttvm（雷电）/intel（MuMu/夜神）
getprop ro.bootloader       # unknown
getprop init.svc.qemud
getprop init.svc.qemu-props
getprop ro.boot.serialno
# 文件特征
ls /system/lib/libdroid4x.so /system/bin/nox-prop /system/bin/microvirt-prop /system/bin/ttVM_x86 2>/dev/null
ls /sys/qemu_trace /system/bin/qemu-props /system/bin/qemud
```

| 指纹 | 模拟器 |
| --- | --- |
| `ro.product.brand=generic` + `ro.kernel.qemu=1` + `goldfish/ranchu` | AVD/官方模拟器 |
| `ttVM_x86` / `ttVM-prop` | 雷电（LDPlayer） |
| `nox-prop` / `ro.product.brand=nox` | 夜神 |
| `microvirt-prop` / `ro.product.manufacturer=Microvirt` | 逍遥 MEmu |
| `mumu` / `ro.product.brand=netease` | MuMu |
| `bluestacks` 字符串 / `Nougat`/`Pie` 异常组合 | BlueStacks |
| `WSA-*` / `WindowsSubsystemForAndroid` | WSA |

---

## 2. 模拟器镜像挂载提取

### 2.1 .vmdk（雷电/夜神/逍遥）
```bash
# Windows：用 7-Zip 直接提（雷电/夜神 vmdk 内通常是 ext4）
7z l vm.vmdk
7z x vm.vmdk -o./vmdk_root

# 或 VirtualBox 自带工具
VBoxManage clonemedium disk vm.vmdk vm.raw --format raw
# Linux/WSL 挂载
fdisk -l vm.raw
losetup -fP vm.raw
mount /dev/loop0p<n> /mnt/vmdk -o ro
```

### 2.2 .qcow2（MuMu Pro）
```bash
qemu-img convert -O raw vm.qcow2 vm.raw
# 或直接 NBD 挂载
modprobe nbd
qemu-nbd -c /dev/nbd0 -r vm.qcow2
fdisk -l /dev/nbd0
mount /dev/nbd0p<n> /mnt -o ro
```

### 2.3 .vhd / .vhdx（BlueStacks / WSA）
```bash
# Windows：右键 vhdx → 装载 → 自动分配盘符
# 或 PowerShell
Mount-VHD -Path .\userdata.vhdx -ReadOnly
# Linux
guestmount -a userdata.vhdx -m /dev/sda1 --ro /mnt
```

### 2.4 AVD userdata-qemu.img（QEMU yaffs/ext4）
```bash
file userdata-qemu.img
# 多为稀疏 ext4：
simg2img userdata-qemu.img userdata.raw
mount -o ro,loop userdata.raw /mnt
```

### 2.5 提取后核心目录
- `/data/data/`（旧版） 或 `/data/user/0/`（新版）：App 沙盒。
- `/data/media/0/`：内置 SD 卡。
- `/sdcard/Android/data/<pkg>/`：App 外部存储。
- `/data/system/users/0/accounts.db`：账户列表（含 Google 账号）。
- `/data/system/packages.xml`：装过的 App 全清单 + 权限授予历史。
- `/data/system/users/0/wallpaper`：壁纸。

---

## 3. 模拟器 vs 真机区别（取证细节）

| 项 | 真机 | 模拟器 |
| --- | --- | --- |
| IMEI | 真实 IMEI（双卡两个） | 默认全 0 或固定值（如 `000000000000000`、`358240051111110`），**雷电/夜神可自定义** |
| Android ID | 真实 64 位随机 | 模拟器默认相同（如 `9774d56d682e549c`），常被服务端识别为模拟器 |
| Mac | 真实 BSSID/网卡 | `08:00:27:xx:xx:xx`（VirtualBox OUI）、`52:54:00:xx:xx:xx`（QEMU OUI） |
| 传感器 | 完整（gyro/加速度/光线） | 多数缺失或返回固定值 |
| GPU | Mali/Adreno | SwiftShader/llvmpipe（软件渲染）、HostGL |
| CPU | ARM 真实 | x86/x86_64（多数模拟器是 x86，但有 Houdini 兼容 ARM .so） |
| 已 root | 默认未 root | **大多数模拟器默认 root**（雷电/夜神/MuMu 都开） |
| Magisk | 需自刷 | 通常无 |
| /proc/self/maps | 干净 | 含 `qemu-system-`、`nox-prop`、`vbox` 等字串 |

> **取证小结**：模拟器一般默认 root，提取数据反而比真机简单。但要警惕**模拟器伪装真机**（Xposed/LSPosed + 模拟器伪装模块如 MockProp、HideMyEmulator），此时 `getprop` 会被 hook，需要看 `/proc/cpuinfo`、`/proc/version`、内核命令行 `/proc/cmdline` 才靠谱。

---

## 4. 应用双开 / 分身机制

### 4.1 分身原理分类
| 类型 | 实现 | 数据位置 | 典型 |
| --- | --- | --- | --- |
| **系统多用户**（Multi-user） | Android 4.2+ 原生 | `/data/user/<userId>/<pkg>/` | Pixel 原生多用户、华为/EMUI 用户切换 |
| **系统应用分身**（Cloned App） | 厂商在系统层做的"分身/双开"，新建 userId（通常 999/95/98） | `/data/user/999/<pkg>/` 或 `/data/user/10/<pkg>/` | 小米双开、OPPO 应用分身、Vivo 应用分身、华为应用分身、Realme/一加/Honor 等 |
| **Work Profile**（工作资料） | Android for Work（DPC） | `/data/user/10/<pkg>/`（userId 通常 10） | Google Workspace、企业 MDM |
| **第三方虚拟容器**（VirtualXposed/Parallel Space/360 分身大师/LBE 平行空间） | 用户态进程级沙盒，包名相同但运行在宿主进程下 | 宿主 App 沙盒下子目录，如 `/data/data/com.lbe.parallel/parallel_intl/<pkg>/` | Parallel Space、Dual Space、双开助手、VirtualApp |
| **App 内多账号**（非分身） | App 自身实现 | App 沙盒内多账号子目录 | QQ 多账号、抖音切换账号 |

### 4.2 系统应用分身路径速查（关键考点）
| 厂商/UI | 主用户路径 | 分身用户路径 | userId |
| --- | --- | --- | --- |
| 原生 / Pixel | `/data/user/0/<pkg>/` | `/data/user/<n>/<pkg>/` | 用户切换 10、11... |
| MIUI（小米） | `/data/user/0/<pkg>/` | `/data/user/999/<pkg>/`（应用双开） + `/data/user/10/<pkg>/`（手机分身） | **999=应用双开，10=系统分身** |
| ColorOS（OPPO/一加） | `/data/user/0/<pkg>/` | `/data/user/999/<pkg>/`（应用分身） | 999 |
| OriginOS / FuntouchOS（Vivo） | 同上 | `/data/user/95/<pkg>/` 或 `/data/user/999/<pkg>/` | 视版本 |
| EMUI/HarmonyOS（华为） | 同上 | `/data/user/<10\|11>/<pkg>/`（隐私空间）+ `/data/user/999/<pkg>/`（应用分身） | 10/11/999 |
| Realme/iQOO | 通常同 ColorOS/Vivo | 999 | |
| Samsung One UI | `/data/user/0/<pkg>/` | `/data/user/95/<pkg>/`（Secure Folder，**额外加密**） | 95 |

> **核心记忆**：看到 `/data/user/<n>/`（n≠0）就要高度警觉——里面可能是**第二份相同 App 的完整数据**，多数考点中嫌疑人会用分身藏微信/QQ/支付。

### 4.3 用户元数据
- `/data/system/users/userlist.xml`：所有用户 ID + 创建时间 + 标志位（FLAG_PROFILE=0x10 工作资料、FLAG_RESTRICTED=0x08 受限）。
- `/data/system/users/<userId>.xml`：每个用户的名字、图标、创建时间、最后登录时间。
- `/data/system/users/<userId>/accounts.db`：该用户绑定的账号。
- `/data/system/users/<userId>/package-restrictions.xml`：该用户启用的 App 列表（**反查谁在分身里装了什么**）。

```bash
# 列出所有用户
cat /data/system/users/userlist.xml
ls /data/user/        # 看到 0/10/95/999 等说明启用了多用户/分身/工作空间
ls /data/user/999/
# 看分身用户装了哪些 app
xmllint --xpath "//pkg/@name" /data/system/users/999/package-restrictions.xml
```

### 4.4 三方虚拟容器识别
| App | 包名 | 数据沙盒 |
| --- | --- | --- |
| Parallel Space | `com.lbe.parallel.intl` / `com.parallel.space.lite` | `/data/data/<它>/parallel_intl/0/<pkg>/`（VA 风格 vuid 子目录） |
| Dual Space | `com.ludashi.dualspace` | `/data/data/<它>/<vuid>/<pkg>/` |
| 双开助手 | `com.excelliance.multiaccount` | 同上 |
| VirtualXposed / VirtualApp | `io.va.exposed` / `com.lody.virtual` | `/data/data/<它>/virtual/data/user/0/<pkg>/` |
| 360 分身大师 | `com.qihoo.magic` | `/data/data/<它>/magic/<vuid>/<pkg>/` |

- 三方容器中**每个被分身的 App 数据都是完整的 `<pkg>` 沙盒**（databases/ shared_prefs/ files/），可以原样套常规 App 解析方法。
- 容器自身另有"运行时映射表"，记录哪些 App 被双开过。

---

## 5. 工作资料（Work Profile）取证

### 5.1 特征
- userId 通常 10（首个工作资料）。
- `/data/user/10/` 与主用户隔离，**默认全盘加密分组（Class C）**，与主用户密钥不同。
- App 名称会有"工作 +" 前缀图标。
- DPC（Device Policy Controller）App 会装在工作资料下，常见：
  - Google Apps Device Policy `com.google.android.apps.work.clouddpc`
  - Microsoft Intune `com.microsoft.intune`
  - Citrix `com.citrix.work`
- 加密：工作资料密码独立，**主用户解锁后工作资料未必解锁**（双解锁）。

### 5.2 取证策略
- BFU 工作资料：未解锁前 `/data/user/10/` 内容 EBE，仅元数据可见。
- 解锁主用户但未解锁工作资料 → 工作资料数据仍密文。
- 完整取证需要工作资料的密码/PIN（独立于主锁屏）。

---

## 6. iOS 上的"分身"

iOS 不允许真正的双开（沙盒模型限制），但有几种近似场景：
1. **企业证书侧载**同一 bundle id 的修改版（如 WeChat 多开版） → 实际是不同 bundle id（如 `com.tencent.xin.dual`），各自独立沙盒。
2. **TestFlight / Beta 版**与正式版共存（不同 bundle id）。
3. **快捷指令 + 备份还原**伪多开（不实用）。
4. **越狱后的 AppCake / Multiple Accounts** 工具：会创建附加 bundle id。

→ **iOS 取证只要枚举 `Manifest.db` / `MobileInstallation` 中所有 bundle id**，即可发现"伪分身"。

---

## 7. 决策树

```
拿到检材
├─ 是 PC 上的虚拟机镜像？
│   ├─ 识别格式（vmdk/qcow2/vhd/vhdx/img）
│   ├─ 挂载/转 raw → 找 /data 分区
│   └─ 按真机 Android 流程取证（多数已 root，简单）
├─ 是真机
│   ├─ ls /data/user/ → 出现 0 之外的 userId？
│   │   ├─ 999 → 厂商应用双开（小米/OPPO/Vivo/华为/Realme）
│   │   ├─ 10/11 → 工作资料 或 系统分身（华为隐私空间）
│   │   ├─ 95 → 三星 Secure Folder（额外加密，需该用户密码）
│   │   └─ 进入对应 /data/user/<n>/<pkg>/ 按常规 App 解析
│   ├─ 装了 Parallel Space/Dual Space/VirtualXposed？
│   │   └─ 进 /data/data/<容器>/.../<pkg>/ 提分身数据
│   └─ App 内多账号？
│       └─ App 沙盒内按 wxid/uid 分子目录（参 wechat_deep_dive.md）
└─ 关键问题：嫌疑人主用户没痕迹？分身/工作资料里找。
```

---

## 8. 命令速查

```bash
# 列模拟器/虚拟机镜像
find . -type f \( -name "*.vmdk" -o -name "*.vhd*" -o -name "*.qcow2" -o -name "*.vbox" -o -name "userdata*.img" \)

# 挂载 vmdk
7z x vm.vmdk -o./out
# 或
qemu-img convert -O raw vm.vmdk vm.raw && losetup -fP vm.raw

# 模拟器指纹（在设备内或 chroot 后）
getprop | grep -Ei "qemu|nox|ldplayer|mumu|microvirt|bluestacks|generic|ranchu|goldfish"
cat /proc/cpuinfo | head
cat /proc/cmdline

# 查多用户
cat /data/system/users/userlist.xml
ls /data/user/
ls /data/user_de/    # FBE 设备解密区

# 分身用户装了哪些 App
for u in /data/system/users/*/package-restrictions.xml; do
  echo "=== $u ==="
  grep -oP 'pkg name="\K[^"]+' "$u"
done

# 进入分身用户 App
ls /data/user/999/com.tencent.mm/databases/

# 三方容器
find /data/data/com.lbe.parallel.intl -name "EnMicroMsg.db" 2>/dev/null
find /data/data/com.lody.virtual -name "*.db"
find /data/data/io.va.exposed -name "*.db"

# packages.xml 找所有装过的 App
grep -oP 'package name="\K[^"]+' /data/system/packages.xml | sort -u

# accounts.db
sqlite3 /data/system/users/0/accounts.db "SELECT name,type FROM accounts;"
sqlite3 /data/system/users/999/accounts.db "SELECT name,type FROM accounts;"
```

---

## 9. 常见坑

1. **只看 `/data/data/`**：新版 Android 真实数据已迁到 `/data/user/0/`，前者只是兼容软链；多用户/分身完全在 `/data/user/<n>/`。
2. **忽略 `/data/user_de/`**：FBE 加密下，`user_de`（Device Encrypted）是 BFU 即可读区，常含锁屏壁纸、通知、系统配置；BFU 取证主战场。
3. **模拟器默认 root 但不等于无加密**：装了 Magisk + LSPosed 仿真后行为会被 hook，原始数据反而难取，**先关掉 Xposed 模块再读**。
4. **`/data/user/999/` 解密**：分身用户和主用户共用解锁密码（多数厂商如此），但**有些厂商分身另设密码**（OPPO/Vivo 可设私密空间密码），此时分身数据 EBE 加密。
5. **三星 Secure Folder（userId=95）**：用 Knox Container，**独立加密 + Knox key**，未输入 Secure Folder 密码 → 数据完全不可读，常规 root 也不行。
6. **userlist.xml 中标记**：`flags="16"` (0x10) = MANAGED_PROFILE 工作资料；`flags="1024"` = CLONE_PROFILE（应用克隆，Android 11+）；用这个区分系统分身 vs 工作资料。
7. **PC 镜像的快照差异**：BlueStacks 经常用差分快照，主 vhd 可能不含最新数据，要把 `Engine\<rvc64>\Root.vhd` 和 `*.delta` 都拼上。
8. **WSA**：数据在用户 AppData 里，`userdata.vhdx` 内是标准 ext4；可能被 BitLocker 加密。
9. **三方虚拟容器自带反调试**：VirtualXposed/Parallel Space 的运行时映射表常加密，**不开起来直接读静态文件即可**，别试图运行。
10. **同一 App 主体 + 分身的 IMEI/AndroidID 可能不同**（厂商伪造），导致用主用户 IMEI 解不开分身的微信，要分别读分身环境 IMEI（在 `/data/user/999/<pkg>/shared_prefs/` 中可能有 App 缓存到的 IMEI 值）。

---

## 10. 交叉链接
- `extraction_methods.md`：提取方法/物理镜像处理
- `adb_filesystem_cheatsheet.md`：Android 文件系统全景
- `device_basic_info.md`：设备信息（含分身环境 IMEI/AndroidID）
- `wechat_deep_dive.md`：双开微信解密时 IMEI/uin 仍按分身用户拼
- `popular_apps_forensics.md`：分身里常见的 QQ/抖音/支付宝同样适用
- `anti_forensics_and_misleading.md`：分身/隐藏应用属于反取证常见手段
