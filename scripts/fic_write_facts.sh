#!/usr/bin/env bash
# 把检材预探发现写入 shared/facts.md 和 phone inbox

FACTS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/facts.md"
TASKS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/TASKS.md"
PHONE_INBOX="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/inbox/phone.md"

cat > "$FACTS" <<'F'
# 共享发现 (Facts)

> 任何窗口发现 IOC 就追加。格式: ## YYYY-MM-DD HH:MM [窗口] 主题

---

## 2026-04-25 12:55 [MAIN] 检材形态预探（赛前合规探索，仅看结构不读业务数据）

### 检材清单
| 检材 | 类型 | 大小 | 板块 |
|-----|------|------|------|
| 检材1-计算机.E01 | **Linux 桌面**（非 Windows） | 22GB | MAIN |
| 检材2-手机.tar | **小米 Android（MIUI）** | 4GB | PHONE |
| 检材3-服务器（E01×2） | **Linux LVM 服务器** | 17.4GB | MAIN |
| 检材4-U盘.E01 | NTFS + **VeraCrypt** | 119MB | MAIN |

### 检材1-计算机（Linux 桌面）
- 内核：`vmlinuz-6.6.84-amd64-desktop-hwe`（HWE 命名 → Deepin/UOS 系）
- 分区：4 个 Linux 分区
  - offset 2048（boot 分区，含 vmlinuz/initrd/grub/efi）
  - offset 3147776（小，可能 swap）
  - offset 19666944（**root 分区**，看到 home/boot/persistent/opt/root/var/usr 等目录）
  - offset 134219784（可能数据分区）
- 挂载点（赛中用）：`/tmp/fic2026/pc/ewf/ewf1`

### 检材2-手机（小米 MIUI）
- tar 包内见到：
  - `data/misc/keystore/user_0/1000_USRPKEY_MIUI_AUTOFILL_SERVICE` ← **MIUI 特征**
  - `data/misc/recovery/ro.build.fingerprint` ← 含设备指纹（型号/版本）
  - `data/misc/bluedroid/bt_config.conf` ← 蓝牙配对历史
  - `data/misc/keystore/user_0/1000_USRPKEY_WifiConfigStore...` ← WiFi
- 38266 个条目（完整 /data 分区备份）
- 解压目标：`/tmp/phone_extract`（PHONE 窗口负责）

### 检材3-服务器（Linux LVM）
- 两个 E01 是同一台服务器的双磁盘
- 拼齐后 LVM：
  - **VG `volum`** → LV `root` 55.88GB（系统盘，rootfs）
  - **VG `root`** → LV `data` 60.20GB（数据盘）
- 已挂载：
  - `/tmp/fic2026/srv/ewf/ewf1` (检材3-1, loop3)
  - `/tmp/fic2026/srv2/ewf/ewf1` (检材3-2, loop4)
  - `/dev/volum/root`、`/dev/root/data` 已 active
- 挂载逻辑卷：`sudo mount -o ro /dev/volum/root /mnt/srv_root`

### 检材4-U盘（关键大题）
- NTFS 文件系统
- 文件：
  - `vc` 10,486,272 字节 = **10 MB VeraCrypt 容器**
  - `SampleVC.exe` 123,392 字节（可能是 VC portable 或自定义工具，需逆向）
  - `System Volume Information/`（NTFS 系统目录）
- 时间戳：2026-04-17 创建 / 2026-04-22 修改
- **解密思路**：从 PC/服务器找密码（可能是 bash_history、配置文件、聊天记录里）
  - 字典已备：`cases/2026FIC电子取证/artifacts/dicts/`

---

## 工具影响（赛前修正）
- ❌ EZ Tools（MFTECmd/EvtxECmd/RECmd）这次基本无用（PC 是 Linux）
- ❌ BitLocker 题型不会出现（PC 是 Linux）
- ✅ 主用：sleuthkit (fls/icat)、grep、jadx、binwalk、tshark、sqlite3、mongosh
- ✅ VeraCrypt 解密：`tcrypt` 模式 hashcat (-m 137xx) 或 `dislocker` 替代品
- ✅ Linux 取证关注：bash_history、auth.log、/etc/、systemd 服务、用户家目录
F

# 更新 TASKS.md
cat > "$TASKS" <<'T'
# FIC2026 题目分工表

## 检材→板块固定分工

| 检材 | 板块 | 状态 |
|-----|------|------|
| 检材1-计算机（Linux 桌面） | MAIN | 已挂 /tmp/fic2026/pc/ewf/ewf1 |
| 检材2-手机（小米 MIUI） | PHONE | tar 待解压 → /tmp/phone_extract |
| 检材3-服务器（LVM 双盘） | MAIN | LVM 已 active：/dev/volum/root、/dev/root/data |
| 检材4-U盘（VeraCrypt） | MAIN | 已挂 /tmp/fic2026/usb/ewf/ewf1 |

## 题目分配（开赛后填）

| 题号 | 简述 | 检材 | 板块 | 分给 | 状态 | 答案位置 |
|-----|------|------|------|------|------|---------|
| - | 待 13:00 公布 | - | - | - | - | - |

## 状态码
- pending / WIP / DONE / SKIP / WAIT
T

# 更新 phone inbox
cat > "$PHONE_INBOX" <<'P'
# PHONE 窗口 inbox

## 🚨 检材已确认（2026-04-25 12:55）

### 你的检材：检材2-手机.tar
- **路径**：`/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar`
- **大小**：4 GB
- **类型**：**小米 Android（MIUI）** /data 分区备份
- **条目数**：38266 个

### 已确认的 MIUI 特征
- `data/misc/keystore/user_0/1000_USRPKEY_MIUI_AUTOFILL_SERVICE` ← MIUI 自动填充
- `data/misc/recovery/ro.build.fingerprint` ← 设备指纹（开赛后第一题常考）
- `data/misc/bluedroid/bt_config.conf` ← 蓝牙配对
- `data/misc/keystore/user_0/1000_USRPKEY_WifiConfigStore...` ← WiFi 配置

## 启动指令（开赛即执行）

1. 解压 tar：`tar -xf /mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材2-手机.tar -C /tmp/phone_extract`
2. 等用户给你题目（MAIN 会 triage 后写到 inbox/phone.md 追加）
3. 开做手机题

## 手机题型常见考点（小米 MIUI）
- 设备型号 / Android 版本 / 内核（看 ro.build.fingerprint）
- 微信数据库解密（IMEI+UIN，套路 02）
- QQ 数据库
- 浏览器历史（小米浏览器/Chrome）
- 相册 EXIF/GPS（exiftool -r /tmp/phone_extract/data/media/）
- WiFi 配置（WifiConfigStore.xml，需 keystore 解密）
- 通话记录/短信
- MIUI 云服务/小米账号
- 第三方 APP 数据（支付宝/微信支付等）

## 共享发现
- 详见 `cases/2026FIC电子取证/shared/facts.md`
- 服务器/PC 板块的发现可能含密码，注意 facts 更新

## 答题
- 答案文件：`cases/2026FIC电子取证/shared/answers/qNN_phone_xxx.md`
- 严格 5 字段格式
- 每题: `python scripts/notify_when_done.py "Q号 PHONE done"`
P

echo "===== facts.md 已更新 ====="
wc -l "$FACTS" "$TASKS" "$PHONE_INBOX"
