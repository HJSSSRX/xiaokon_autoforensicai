# 手机模拟器取证深度专题

> 适用：检材是 PC 上的手机模拟器（雷电/夜神/MuMu/BlueStacks/逍遥/Genymotion/AVD/WSA/Anbox/Waydroid 等），或题目要求识别"该数据是否来自模拟器"、提取虚拟机内 App 数据、固定模拟器使用证据。
>
> 与 `emulator_clone_forensics.md` 互补：那篇是模拟器+分身合并速查，本篇专注模拟器**镜像格式 / 文件系统 / 提取方法 / 主机痕迹链**深度。

---

## 1. 模拟器全景

### 1.1 主流模拟器 + 内核技术
| 模拟器 | 厂商 | 虚拟化 | 镜像格式 | 默认 Android | 架构 |
| --- | --- | --- | --- | --- | --- |
| **LDPlayer / 雷电** | 上海雷电 | VirtualBox 改 + Hyper-V | `*.vmdk` | 7 / 9 / 11 | x86 + ARM 翻译 |
| **NoxPlayer / 夜神** | Bignox | VirtualBox 改 | `*.vmdk` | 5/7/9 | x86 |
| **MuMu**（旧 6） | 网易 | VBox 改 | `*.vmdk` | 6 | x86 |
| **MuMu Pro 12** | 网易 | QEMU/KVM + Hyper-V | `*.qcow2` | 9 / 12 | x86 |
| **BlueStacks 4 / 5 / 10** | BlueStacks | VirtualBox + Hyper-V | `*.vhd` + `*.bstk`（差分） | 7 / 9 / 11 | x86 |
| **MEmu / 逍遥** | 微猎 | VBox 改（MemuHyperv） | `*.vmdk` | 7 / 9 | x86 |
| **Genymotion** | Genymobile | VBox / 自家 hypervisor / Cloud | `*.vbox` + `*.vmdk` | 4–14 任选 | x86 + ARM 翻译 |
| **Android Studio AVD** | Google | QEMU | `userdata-qemu.img`（sparse ext4） + `system.img` | 4–15 | ARM/x86_64 |
| **WSA** | Microsoft | Hyper-V Container | `*.vhdx` | 11/13/14 | x86_64 + ARM |
| **Android-x86 / Bliss / Prime OS** | 社区 | 直接装 PC（裸机/VM） | 普通 ext4 | 9 / 11 / 13 | x86_64 |
| **Anbox / Waydroid** | Linux | LXC 容器 | squashfs / ext4 img | 7 / 11 / 13 | host arch |
| **Tencent GameLoop / 手游助手** | 腾讯 | VBox / Hyper-V | 内部多 vmdk | 7 | x86 |

### 1.2 主机安装路径速查（Windows）
| 模拟器 | 默认路径 |
| --- | --- |
| 雷电 | `C:\LDPlayer\LDPlayer<版本>\vms\leidian<n>\` |
| 夜神 | `C:\Program Files (x86)\Nox\bin\BignoxVMS\<vmname>\` 或 `%USERPROFILE%\Nox_share\` |
| MuMu（旧 6） | `C:\Program Files\MuMu\emulator\nemu\vms\` |
| MuMu Pro 12 | `C:\Program Files\Netease\MuMuPlayer-12.0\vms\MuMuPlayer-12.0-<n>\` |
| BlueStacks 5 | `C:\ProgramData\BlueStacks_nxt\Engine\<rvc64\|Nougat64\|Pie64>\` |
| MEmu | `C:\Program Files\Microvirt\MEmu\MemuHyperv VMs\<vm>\` |
| Genymotion | `%USERPROFILE%\.Genymobile\Genymotion\deployed\<UUID>\` |
| Android Studio AVD | `%USERPROFILE%\.android\avd\<name>.avd\` |
| WSA | `%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalCache\` |
| GameLoop | `C:\Program Files\TxGameAssistant\AppMarket\` + `%USERPROFILE%\AppData\Local\TxGameDownload\` |

> **取证铁律**：现场拿到 PC 后，**先全盘扫所有镜像类文件**，一次性发现所有模拟器实例：
> ```bash
> # Windows
> dir /s /b C:\*.vmdk *.vdi *.vhd *.vhdx *.qcow2 *.bstk *.vbox userdata*.img system*.img 2>nul
> # PowerShell
> Get-ChildItem -Path C:\ -Recurse -Include *.vmdk,*.vdi,*.vhd,*.vhdx,*.qcow2,*.bstk,*.vbox,userdata*.img,system*.img -ErrorAction SilentlyContinue
> ```

### 1.3 ADB 端口（在线连接侦察）
| 模拟器 | 默认端口 |
| --- | --- |
| 雷电 | 5555（多开 5555+0/5555+2/...） |
| 夜神 | 62001 / 62025 / 62026 |
| MuMu | 7555 |
| MuMu Pro 12 | 16384 / 16416 / 16448... |
| BlueStacks | 5555 / 5557 |
| MEmu | 21503 / 21505 |
| Genymotion | 6555（旧） / 5555 |
| AVD | 5554 / 5556... |
| WSA | 58526 |

```bash
# 端口侦察一把梭
for p in 5555 5557 62001 62025 7555 16384 21503 21505 58526 6555; do
  adb connect 127.0.0.1:$p && adb -s 127.0.0.1:$p shell getprop ro.product.brand 2>/dev/null
done
```

---

## 2. 镜像格式深度

### 2.1 VMDK（VMware/VBox）
- 头 4 字节 magic `KDMV`（`4B 44 4D 56`）。
- 两类布局：**monolithicSparse**（单文件稀疏，雷电/夜神/MEmu）；**2GB split + flat**（多 `*-flat.vmdk` + 描述子）。
- 描述子是文本，含 `extent`、`CID`、`parentCID`（差分链）。

```bash
file leidian0.vmdk                                    # 看类型
qemu-img info a.vmdk                                  # 详细信息（snapshot/backing）
qemu-img convert -O raw a.vmdk a.raw                  # 转 raw
VBoxManage clonemedium disk a.vmdk a.raw --format raw # 备选

# Linux 直接挂载
modprobe nbd
qemu-nbd -c /dev/nbd0 -r a.vmdk
fdisk -l /dev/nbd0
mount /dev/nbd0p1 /mnt -o ro
```
- Windows：**7-Zip 直接打开 vmdk** 多数能枚举 ext4 内文件；sparse 不稳就用 OSFMount / FTK Imager。

### 2.2 QCOW2（QEMU/KVM，MuMu Pro / 部分 Genymotion）
- 头 4 字节 magic `QFI\xfb`（`51 46 49 FB`）。
- 支持快照、差分、压缩、加密。

```bash
qemu-img info a.qcow2                # 看 backing file / snapshots
qemu-img convert -O raw a.qcow2 a.raw
qemu-nbd -c /dev/nbd0 -r a.qcow2
qemu-img snapshot -l a.qcow2         # 列快照
# 切换快照（会改文件，先复制）
qemu-img snapshot -a <id> a.qcow2
```

### 2.3 VHD / VHDX（Hyper-V / BlueStacks / WSA）
- VHD 头 512 字节在文件**末尾**（cookie `conectix`）。
- VHDX 头 8 字节 magic `vhdxfile`，256 字节后 region table。
- BlueStacks：`Root.vhd`（系统）+ `Data.vhd` + `Fastboot.vhd` + 差分 `*.bstk-NN.bstk`。

```powershell
# Windows 原生只读挂载
Mount-VHD -Path .\Data.vhd -ReadOnly
Get-Disk | where Location -like '*Data.vhd*'
Dismount-VHD -Path .\Data.vhd
```
```bash
# Linux
guestmount -a Data.vhd -m /dev/sda1 --ro /mnt
qemu-img convert -O raw Data.vhd Data.raw
```

> **BlueStacks 差分链**：`Data.vhd` + `Data.vhd.bstk-00.bstk` + `Data.vhd.bstk-01.bstk` ... 每层一次 commit；**整链一起拿走**才有最近写入。`qemu-img convert` 会跟 backing file 自动合并。

### 2.4 VDI（VirtualBox 原生，少见）
```bash
qemu-img convert -O raw a.vdi a.raw
VBoxManage clonemedium disk a.vdi a.raw --format raw
```

### 2.5 AVD `userdata-qemu.img`（Android sparse）
```bash
file userdata-qemu.img        # Android sparse image, magic 0xed26ff3a
simg2img userdata-qemu.img userdata.raw
mount -o ro,loop userdata.raw /mnt
simg2img system.img system.raw
```

### 2.6 WSA `userdata.vhdx`
- 标准 vhdx，内含 ext4。
- 路径 `%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_*\LocalCache\userdata.vhdx`
- 受 BitLocker 影响时先解卷。

### 2.7 BSTK（BlueStacks 差分）
- 私有差分格式，base = `*.vhd`，每次启动新 `.bstk` 层。
- 现代 BS 已能直接用 `qemu-img` 处理（识别为 vhdx-like）。
- 备选：BlueStacks 自带 `BstCommandProcessor.exe` 合并。

### 2.8 VBOX 描述符
- `*.vbox` 是 XML，描述硬件 + 快照树。
- 关键节点：`<HardDisk uuid=... location=...vmdk/>`（找镜像）、`<Snapshot uuid=... timeStamp=...>`（**何时做过快照** = 取证证据）。

---

## 3. 模拟器内 Android 文件系统

### 3.1 分区映射（按模拟器）
| 模拟器 | system | userdata | sdcard 共享（host） |
| --- | --- | --- | --- |
| 雷电 | leidian-0-vmdk-flat.vmdk 中分区 | 同 vmdk | 自定义共享目录 |
| 夜神 | nox-system.vmdk | nox-disk2.vmdk | `Nox_share/` |
| MuMu（旧 6） | Volume-system.vmdk | Volume-data.vmdk | `Documents\MuMu共享文件夹` |
| MuMu Pro 12 | system.qcow2 | userdata.qcow2 | `MuMuSharedFolder` |
| BlueStacks 5 | Root.vhd / Fastboot.vhd | Data.vhd | `Documents\BlueStacks` |
| MEmu | system-vbox.vmdk | data-vbox.vmdk | `Documents\MEmu Documents` |
| Genymotion | system.vmdk | userdata.vmdk | `~/Documents/Genymotion/` |
| AVD | system.img | userdata-qemu.img | sdcard.img（FAT32） |
| WSA | system.vhdx | userdata.vhdx | host 桥接 |

### 3.2 共享文件夹（**取证宝藏**）
- 几乎所有模拟器都有 host ↔ guest 双向共享目录，**嫌疑人导文件进出的高频通道**。
- 主机端在 `Documents\` 或安装目录下，**不进虚拟机直接拿**。

| 模拟器 | host 路径 | guest 路径 |
| --- | --- | --- |
| 雷电 | `C:\Users\<user>\LDPlayer\<vm>\` 或自定义 | `/mnt/shared/` |
| 夜神 | `C:\Users\<user>\Nox_share\` | `/mnt/shared/Other` |
| MuMu | `Documents\MuMu共享文件夹` | `/mnt/shared/MuMuShare` |
| BlueStacks | `Documents\BlueStacks` | `/sdcard/Download/BstSharedFolder` |
| MEmu | `Documents\MEmu Documents` | `/mnt/shell/emulated/0/MemuDocuments` |
| Genymotion | `~/Genymotion` | `/sdcard/Download/Genymotion` |

### 3.3 模拟器配置文件（**伪装信息全在这**）
| 模拟器 | 关键配置 |
| --- | --- |
| 雷电 | `vms\config\leidian<n>.config`（JSON：IMEI/IMSI/手机号/品牌/分辨率） |
| 夜神 | `BignoxVMS\nox\nox.vbox` 内 `<ExtraData>` + `bin\config.ini` |
| MuMu | `vms\<n>\config\<n>_data.config` |
| BlueStacks | 注册表 `HKLM\SOFTWARE\BlueStacks_nxt\` + `Engine\<x>\bluestacks.conf` |
| MEmu | `MemuHyperv VMs\<vm>\<vm>.memu` |
| Genymotion | `~/.Genymobile/Genymotion/deployed/<UUID>/genymotion.vbox` + `state.json` + `genymotion.log` |

> **雷电 config 内 IMEI 是嫌疑人改过的伪装值**，与真实手机 IMEI 完全无关；要在报告里写明。

### 3.4 模拟器多开
- 雷电/夜神/MuMu/MEmu 都支持多开，每个实例独立 vmdk。
- 路径里 `leidian0/leidian1/leidian2`、`MuMuPlayer-12.0-0/-1/-2` 即多开实例索引。
- **现场全盘扫所有 vmdk**——嫌疑人常一号一实例。

---

## 4. 数据提取标准流程

### 4.1 离线（PC 关机/抓盘后）
```
1. dd 全盘镜像 / 复制模拟器目录
2. find 所有镜像文件（§1.2 列表 + 全盘扫）
3. 按格式转 raw / 挂载 / 解压
4. 进 /data/data/ 或 /data/user/0/ 取 App 沙盒
5. 按 App 解析（参 wechat_deep_dive / popular_apps_forensics / database_forensics）
```

### 4.2 在线（模拟器运行中）
```bash
adb connect 127.0.0.1:<port>      # 端口见 §1.3
adb root                          # 多数模拟器默认 ok
adb shell tar -czf /sdcard/dump.tgz /data/data /data/user
adb pull /sdcard/dump.tgz
```
- 在线优势：**FBE 已是 AFU 状态**，CE 数据可读；可现场 dump 进程内存提 SQLCipher key。

### 4.3 内存快照（**模拟器场景的杀手锏**）
模拟器跑在 PC 上，内存随时可 dump，比真机简单得多：
```bash
# VBox 系（雷电/夜神/MEmu）
VBoxManage debugvm "leidian0" dumpvmcore --filename=leidian0.core
# QEMU 系
virsh save <vm> mem.snap
# 或快照 qcow2 内嵌 vmstate
qemu-img info userdata.qcow2

# 用 volatility / yara / strings 抓 SQLCipher key、token、明文消息
strings -el leidian0.core | grep -iE 'wxid_|token|sessionid'
```

### 4.4 快照与时间线
- VBox/雷电/夜神/Genymotion/QEMU 全支持快照 → `*.vbox` XML 内 `<Snapshot timeStamp=...>` 树即"嫌疑人在某时刻的全盘状态"。
- 列快照：
```bash
VBoxManage snapshot "leidian0" list --machinereadable
qemu-img snapshot -l userdata.qcow2
```

### 4.5 仅有 system + userdata 镜像（无 PC）的处理
- 用 QEMU 自己跑起来：
```bash
qemu-system-x86_64 -m 2048 -hda system.raw -hdb userdata.raw -netdev user,id=n0 -device e1000,netdev=n0 -enable-kvm
```
- 让 Android 启动后 adb 进，做活体提取（**注意：启动会改 userdata，先复制再跑**）。

---

## 5. 模拟器 vs 真机识别

### 5.1 PC 主机痕迹（**最直接**）
- 安装路径：§1.2。
- **注册表**：
  - 厂商主键：`HKLM\SOFTWARE\leidian`、`HKLM\SOFTWARE\BlueStacks_nxt`、`HKLM\SOFTWARE\Microvirt`、`HKLM\SOFTWARE\Bignox`。
  - 卸载键：`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\` 模拟器条目。
- **服务**：`LdVBoxSVC`、`NoxVMSVC`、`BstHdAndroidSvc`、`MEmuSVC`。
- **Prefetch / Amcache**：`C:\Windows\Prefetch\DNPLAYER.EXE-*.pf`、`NOXVMHANDLE.EXE-*.pf`、`HD-PLAYER.EXE-*.pf` 等。
- **Jumplist / RecentDocs**：模拟器图标。

### 5.2 镜像内 Android 的"模拟器味儿"
| 指纹 | 特征值 |
| --- | --- |
| `getprop ro.kernel.qemu` | `=1`（AVD/MuMu Pro/部分 Genymotion） |
| `ro.hardware` | `goldfish/ranchu`(AVD)、`ttvm`(雷电)、`vbox`(VBox)、`microvirt`(MEmu)、`bluestacks` |
| `ro.product.brand/manufacturer` | `generic`、`Genymotion`、`nox`、`Microvirt`、`BluestacksFHD` |
| `ro.product.cpu.abi` | x86 / x86_64（多数 ARM 真机不会） |
| MAC | `08:00:27:*`(VBox)、`52:54:00:*`(QEMU)、`00:15:5D:*`(Hyper-V/WSA) |
| `/proc/cpuinfo` flags | 含 `hypervisor` |
| `/proc/cmdline` | `androidboot.hardware=ranchu` 等 |
| `/system/lib*/` | `libdroid4x.so`、`libnox.so`、`ttVM_x86`、`microvirt-prop` |
| `/dev/` 节点 | `qemu_pipe`、`vboxguest`、`vboxsf` |
| `/init.*.rc` | 含硬件名、模拟器 init 脚本 |
| 传感器 | 缺陀螺仪/气压/光线（多数模拟器） |

### 5.3 反检测（嫌疑人伪装）与反制
- 嫌疑人手段：LSPosed 模块（HideMyApplist / MockProp / HideEmulator）、改 `build.prop`、改 MAC/IMEI/AndroidID。
- **反制**：上述指纹中以下几项**不被 Java/native API hook 覆盖**：
  - `/proc/cpuinfo` 的 `flags` 字段
  - `/proc/cmdline` 内核参数
  - `/dev/` 设备节点存在性
  - `init.rc` 文件名
  - 镜像本身的 VBOX OUI MAC（除非整盘擦写）
- 报告里**列举多条独立指标**才能下结论，单条易被反驳。

---

## 6. 模拟器特有数据结构

### 6.1 雷电 LDPlayer config（嫌疑人的伪装手机）
`vms\config\leidian<n>.config` JSON 示例：
```json
{
  "phoneIMEI": "863412040000123",
  "phoneIMSI": "460023456789012",
  "phoneNumber": "13812345678",
  "phoneSimSerial": "8986...",
  "phoneAndroidId": "9774d56d682e549c",
  "phoneModel": "Pixel 4 XL",
  "phoneManufacturer": "Google",
  "phoneBrand": "google",
  "macAddress": "00:15:5d:01:80:0a",
  "resolution": "1080,1920",
  ...
}
```
- **看这个文件即可获得嫌疑人为该实例伪造的全部硬件身份**。
- 多开实例 → 每个 leidian<n>.config 单独一份。

### 6.2 夜神 Nox 配置
- `bin\config.ini`：基本设置。
- `BignoxVMS\nox\nox.vbox` 的 `<ExtraData>` 节存伪装值。
- `Bignox\BgnGuestSrv\config.ini`：手机型号/IMEI 等。

### 6.3 BlueStacks 注册表（**整套硬件伪装**）
```
HKLM\SOFTWARE\BlueStacks_nxt\Guests\<rvc64|Pie64>\Config
  Imei / Imsi / SerialNum / AndroidId / WifiMacAddress / DeviceModel / Manufacturer
HKLM\SOFTWARE\BlueStacks_nxt\Logger\
HKLM\SOFTWARE\BlueStacks_nxt\Microsoft\               # 安装/版本
```
工具：`reg query` / RegRipper / RECmd 一把抓。

### 6.4 BlueStacks 共享文件夹索引
- `C:\ProgramData\BlueStacks_nxt\Engine\Userdata\SharedFolder\` 内文件直接是 host↔guest 共享，**无需进虚拟机即可取**。

### 6.5 Genymotion 日志
- `~/.Genymobile/Genymotion/genymotion.log`：完整启动 + 操作记录。
- `~/.Genymobile/Genymotion/deployed/<UUID>/state.json`：设备状态。

### 6.6 GameLoop（腾讯手游助手）
- 内置 VBox + 修改版 Android。
- `C:\Program Files\TxGameAssistant\AppMarket\TxGameDownload\` 含下载 apk。
- 用户数据 `%USERPROFILE%\AppData\Local\TxGameDownload\`。
- **高频出现于游戏案件**（和平精英、王者荣耀外挂/挂机/代练）。

---

## 7. 比赛/实战题型与解法

### 7.1 类型 A：嫌疑人 PC 上有模拟器，问微信聊天记录
1. 全盘扫 vmdk → 转 raw → 挂 ext4 → `/data/data/com.tencent.mm/`。
2. 默认 root → EnMicroMsg.db / MSG*.db 直接拿。
3. 解密用的 IMEI 来自 §6.1 config（**不是真实手机 IMEI**）。
4. 走 `wechat_deep_dive.md` 流程；多开则每个实例独立解。

### 7.2 类型 B：判断"该数据来自真机还是模拟器"
按 §5.2 跑指纹清单，**多个独立指标一致**才下结论；单条易被伪装反驳。

### 7.3 类型 C：嫌疑人多开 N 个微信号
- 找全部 `leidian<n>` / `nox<n>` / `MuMuPlayer-12.0-<n>` 实例。
- 每实例独立解密（IMEI/wxid/uin 全不同）。
- 配合注册表、安装目录、进程树（`tasklist /v` 看 dnplayer/nox/...）交叉。

### 7.4 类型 D：嫌疑人是否使用过模拟器（即使已删）
| 来源 | 说明 |
| --- | --- |
| 注册表残留 `HKLM\SOFTWARE\<Vendor>\` | 卸载常不删 |
| Prefetch | `DNPLAYER.EXE-*.pf` 等 |
| Amcache | `Amcache.hve` 内程序记录 |
| 卸载日志 | `%LOCALAPPDATA%\<Vendor>\Logs\` |
| 残留 vmdk | 卸载常不删 vms 目录 |
| MUICache / UserAssist | 启动次数 + 最后运行时间 |

### 7.5 类型 E：BlueStacks 差分链取证
- 必须把 `Data.vhd` 与所有 `*.bstk-NN.bstk` 一起带走。
- 单独拿 base 缺最近写入；单独拿 bstk 无意义（差分需 base）。
- `qemu-img convert` 自动跟链合并。

### 7.6 类型 F：从模拟器内存提 SQLCipher key
- 模拟器运行中 → `VBoxManage debugvm dumpvmcore` 或 qemu hmp `dump-guest-memory`。
- 用 strings + yara 找 32/64 byte 高熵串；或 frida 直接 hook。
- 比真机简单，**因为可静态 dump 不破坏运行**。

### 7.7 类型 G：判断嫌疑人是否在模拟器里跑过外挂/挂机脚本
- 看 `/data/local/tmp/`：脚本/工具堆放区。
- 看 `/data/data/com.tencent.tmgp.*/`（GameLoop/手游）数据。
- 看模拟器内安装的辅助 App（按键精灵、AutoJS、触动精灵）。
- AutoJS 工程：`/sdcard/脚本/`、`com.stardust.scriptdroid` 沙盒。

---

## 8. 命令速查

```bash
# 全盘扫镜像
Get-ChildItem -Path C:\ -Recurse -Include *.vmdk,*.vdi,*.vhd,*.vhdx,*.qcow2,*.bstk,*.vbox,userdata*.img,system*.img -ErrorAction SilentlyContinue | Select FullName,Length,LastWriteTime

# 头部识别
file *.vmdk *.qcow2 *.vhd *.vhdx
xxd a.vmdk | head -2          # KDMV
xxd a.qcow2 | head -1         # QFI\xfb
xxd a.vhdx | head -1          # vhdxfile
tail -c 512 a.vhd | strings   # conectix

# 转 raw
qemu-img convert -O raw a.vmdk a.raw
qemu-img convert -O raw a.qcow2 a.raw
qemu-img convert -O raw Data.vhd Data.raw      # 自动跟 bstk 链
simg2img userdata-qemu.img userdata.raw

# 挂载（Linux）
modprobe nbd
qemu-nbd -c /dev/nbd0 -r a.vmdk
fdisk -l /dev/nbd0
mount /dev/nbd0p1 /mnt -o ro

# Windows 挂载
Mount-VHD -Path .\Data.vhd -ReadOnly
# 7-Zip 直接打开 vmdk

# 看快照
qemu-img info a.qcow2
VBoxManage snapshot "<vm>" list --machinereadable

# 取证内存
VBoxManage debugvm "<vm>" dumpvmcore --filename=mem.core
strings -el mem.core | grep -iE 'wxid_|sessionid|token'

# ADB 端口侦察
for p in 5555 5557 62001 62025 7555 16384 21503 21505 58526 6555; do
  adb connect 127.0.0.1:$p
done
adb devices

# 雷电配置一把抓
type C:\LDPlayer\LDPlayer9\vms\config\leidian*.config

# BlueStacks 注册表
reg export HKLM\SOFTWARE\BlueStacks_nxt bs_nxt.reg

# 模拟器进程识别
tasklist /v | findstr /i "dnplayer nox memu vbox bluestacks hd-player MuMu wsaclient"
```

---

## 9. 常见坑

1. **只取 base 不取差分**：BlueStacks `*.bstk` 链丢一层就丢最近写入；现场必须打包 base + 全部差分。
2. **快照切换破坏证据**：`qemu-img snapshot -a` 会改文件，**永远先复制再切**。
3. **模拟器配置内 IMEI 误当真**：雷电/夜神 config 里的 IMEI 是嫌疑人编的，与真实嫌疑人手机无关；但**仍是嫌疑人主观选择的伪装身份**（取证报告里要写明用途）。
4. **运行中复制 vmdk 不一致**：模拟器跑着 dd 出来的 vmdk 文件系统多半坏；先关机或用 VBoxManage 暂停 + 快照，再复制 base。
5. **BlueStacks 5 走 Hyper-V**：`Mount-VHD` 在 Hyper-V 角色未启用的环境会失败；改用 `qemu-img convert`。
6. **ADB connect 不稳**：模拟器多开端口冲突，断电重启后端口可能漂移；以 `adb devices` 列表为准。
7. **多 PC 用户**：模拟器实例可能在 `C:\Users\<user>\` 也可能在 `D:\` 自定义；不要只看 ProgramData。
8. **WSA 受 BitLocker 保护**：vhdx 在加密卷内，需先解 BitLocker 才能拿到。
9. **AVD `userdata-qemu.img` 是 sparse**：不能直接 mount，要 `simg2img` 先转 raw。
10. **MuMu Pro qcow2 可能加密**：新版 MuMu 启动后写入加密 key 在 `vms/<n>/config/`；离线挂载需读取 key 否则报错。
11. **Genymotion 设备 UUID 在路径里**：deployed 目录每个 UUID = 一个虚拟设备，多个 UUID = 多设备，按需逐个看。
12. **模拟器内时间错乱**：guest 时区/RTC 与 host 偏离常见，用模拟器内 SQLite 时间戳前要看 `getprop persist.sys.timezone` 与 host 对比。
13. **反检测 hook 让 getprop 撒谎**：报告里只用 getprop 单源结论容易翻车；要叠加 `/proc`、`/dev`、init.rc、镜像 OUI 多源。
14. **GMS 缺失**：多数模拟器无 GMS，App 验签/Play Integrity 失败 → 嫌疑人会装第三方 GMS（OpenGApps），这个本身可见痕迹（`/system/priv-app/GoogleServicesFramework/`）。
15. **Anbox/Waydroid 走 LXC**：rootfs 是 squashfs（只读）+ 上层 overlay；用户数据在 host 的 `/var/lib/anbox/data/` 或 `~/.local/share/waydroid/data/`，**不是镜像**。

---

## 10. 交叉链接
- `emulator_clone_forensics.md`：模拟器 + 应用分身合并速查
- `extraction_methods.md`：通用 5 级提取方法
- `adb_filesystem_cheatsheet.md`：ADB / Android 文件系统
- `wechat_deep_dive.md` / `popular_apps_forensics.md`：模拟器内 App 数据解析
- `database_forensics.md`：模拟器内 SQLite/SQLCipher 解析
- `apk_crypto_analysis.md`：算法逆向（模拟器内 frida 比真机更易）
- `lock_password_forensics.md`：模拟器内屏锁/应用锁
- `device_basic_info.md`：设备指纹识别
- `anti_forensics_and_misleading.md`：模拟器作为反取证工具的常见手法
