# 手机分析机 同步快照 — 2026-05-08

> 角色：`mobile_analyst` (本机)
> 工作区：`e:\自动化取证\framework\`
> 主机：`LAPTOP-GFVF0KBV` / Windows
> 目的：把本机积累的"手机取证"有效成果 + 当前比赛进度 同步到 `xiaokon-all` 共享仓库，方便其他机器/后续会话接续。

---

## 一、本次推送内容（手机相关有效成果）

### 新增 / 增强：`knowledge/skills/mobile/`（38 个新文件 + 1 个增强）

按主题分组（每个文件都是从实战 + 公开 writeup 沉淀出的可执行 skill 卡）：

#### Android 取证主链
- `adb_filesystem_cheatsheet.md` — adb 文件系统遍历速查
- `android_analysis_environment.md` — 分析环境标准化搭建
- `android_app_attribution.md` — APP 归属 / 来源溯源方法
- `android_app_cloud_forensics.md` — 云手机 / 云控 APP 取证
- `android_packer_unpacker.md` — 加固识别 + 脱壳手段（梆梆 / 360 / 爱加密 / DexProtect 等）
- `android_reverse_analysis.md` — Android 逆向流程
- `app_data_analysis.md` — APP 数据目录解析
- `apk_crypto_analysis.md` — APK 内置加密算法逆向
- `apk_internals.md` — APK 结构 / smali / dex 内部
- `apk_permission_analysis.md` — 权限分析与风险定位
- `database_forensics.md` — 移动端数据库（SQLite / Realm / LevelDB / IndexedDB）
- `device_basic_info.md` — 设备基线信息（IMEI/MEID/序列号/build prop）
- `extraction_methods.md` — 物理 / 文件系统 / 逻辑 / 云提取方法对比
- `hook_techniques.md` — Frida / Xposed / objection / Magisk 模块
- `lock_password_forensics.md` — 锁屏密码 / Pattern / Gatekeeper 取证

#### iOS 取证主链
- `ios_app_parsing.md` — iOS APP 数据解析
- `ios_forensics.md` — iOS 取证总览
- `ios_fundamentals.md` — iOS 文件系统 / 容器 / 备份基础
- `ios_logs.md` — iOS 日志（unified log / sysdiagnose）
- `ios_toolchain.md` — iOS 工具链（libimobiledevice / iLEAPP / 商业产品）

#### 常见 APP 取证
- `wechat_deep_dive.md` — 微信深度分析（DB 解密 / KeyValueDB / 多账号）
- `popular_apps_forensics.md` — 主流 APP（QQ / 抖音 / TG / 微博 / Snapchat 等）
- `crypto_currency_forensics.md` — 加密货币钱包取证
- `geolocation_forensics.md` — 位置信息（GPS / cell / WiFi / 照片 EXIF）

#### 进阶 / 边角
- `anti_forensics_and_misleading.md` — 反取证与误导识别
- `dji_forensics.md` — 大疆无人机取证
- `emulator_forensics.md` — 模拟器（雷电 / 夜神 / MuMu / BlueStacks）
- `emulator_clone_forensics.md` — APP 多开 / 双开 / 沙盒
- `iot_device_forensics.md` — IoT / 智能家居
- `other_smart_devices.md` — 智能设备杂项（手表 / 车机 / Pad）
- `uninstalled_app_recovery.md` — 已卸载 APP 恢复

#### 比赛相关 writeup 沉淀
- `fic2026_writeup.md` — FIC2026 手机题复盘
- `competition_2024_2025_writeups.md` — 历届比赛手机题归集
- `competition_2025_late_writeups.md` — 2025 下半年赛事手机题
- `dfir_suxiaomu_writeups.md` — DFIR 苏小慕系列 writeup
- `didctf_writeup_methodology.md` — 滴滴 CTF 取证方法论

#### 速查 / 基础
- `fundamentals_cheatsheet.md` — 手机取证基础速查
- `log_and_data_parsing.md` — 日志与数据解析通用法
- `quick_reference.md` ★ **增强版**（从 1.6KB → 11KB，覆盖 Android/iOS 双栈快速命令）

### 同步推送的相邻 skill
- `knowledge/skills/network/bluetooth_forensics.md` — 蓝牙取证（与手机取证强关联）
- `knowledge/skills/timestamps_reference.md` — 跨平台时间戳对照（手机题高频用到）

---

## 二、当前比赛进度（mobile_analyst 视角）

### 历史完成状态（来自本机 `framework/HANDOFF.md`）
- **2024FIC 决赛 · 计算机取证板块**：15/15 题独立解出 (100%) ✅
- 输出物：`E:\ffffff-JIANCAI\2024FIC决赛\2024FIC_解题报告.xlsx` + KB validation
- 2024FIC 剩余 5 板块共 53 题（板块 2-6）尚未全部完成，核心障碍：
  - 板块 2（PVE 虚拟化 / LVM）— `parse_pve_lvm.py` 已写未跑通
  - 板块 4（云手机）— 需启动 PVE VM + Docker，CLI 难以完成
  - 板块 5/6（服务器 / 数据分析）— 需重建 MySQL/网站环境

### 当前手机分析机部署状态（来自本机 `framework/progress.txt`）
角色：让本机扮演"手机取证"角色，测试工具齐全可用。

**已就绪**：
- Python `D:\python\python.exe` (3.12.4) + 取证全家桶（dissect/volatility3/oletools/pycryptodome 等）
- Java JDK 1.8（能跑 `abe.jar`）
- 7-Zip / binwalk / git 2.47 / hashcat / radare2 / sleuthkit / die / ffuf / gobuster / upx / strings
- manifest.yaml 已加 `mobile` 段（adb / aleapp / ileapp / pysqlcipher3 / androguard / pyaxmlparser / abe / jadx / apktool / sqlcipher）
- `tool_status.py --role mobile` 过滤 bug 已修

**待办（被用户上次取消打断）**：
- [ ] 下载 ALEAPP / iLEAPP / platform-tools / abe.jar 到 `framework/bin/`
- [ ] 装 ALEAPP/iLEAPP requirements
- [ ] manifest known_paths 写入 ALEAPP/iLEAPP 路径
- [ ] pysqlcipher3 在 Windows 装不上 → 改试 `sqlcipher3-binary`
- [ ] exiftool 本机暂无（exiftool.org 国内基本死） → 走 npmmirror `exiftool-vendored` 或翻墙手下
- [ ] 跑 `python tools/tool_status.py --role mobile` 期望全 OK
- [ ] 端到端冒烟：`.ab → abe.jar unpack → ALEAPP -t tar` 看 HTML 报告

### 网络 / 工具未就绪清单（参考 `HANDOVER.md`）
| 工具 | 失败原因 |
|---|---|
| wireshark/tshark | 官方仅 setup.exe 无便携 zip |
| nmap | nmap.org 限速 8KB/s |
| exiftool | exiftool.org 国内 TLS 后挂死 |
| ghidra | 400MB，gh-proxy 不稳 |
| john | openwall.com 国内不通 |

可用国内通道（实测）：
- pip 走 `pypi.tuna.tsinghua.edu.cn` ✅
- GitHub 走 `gh-proxy.com/<url>` 中等速度 ✅（必走，github.com 直连不通）
- npmmirror.com ✅
- gitee.com / Sysinternals ✅

---

## 三、关键文件位置（便于其他机器接续）

```
本机工作区（同步前）：
  e:\自动化取证\framework\knowledge\skills\mobile\   ← 手机 skill 38+1 文件
  e:\自动化取证\framework\knowledge\skills\network\bluetooth_forensics.md
  e:\自动化取证\framework\knowledge\skills\timestamps_reference.md
  e:\自动化取证\framework\progress.txt               ← 本机进度原始档
  e:\自动化取证\framework\HANDOFF.md                 ← 项目交接（含 2024FIC 状态）
  e:\自动化取证\HANDOVER.md                          ← 部署交接（工具/网络）
  e:\自动化取证\framework\tools\manifest.yaml        ← 工具清单
  e:\自动化取证\framework\bin\                       ← 二进制（大部分未填）
```

仓库（同步后）：
- `knowledge/skills/mobile/` — 完整手机 skill 库（39 个文件）
- `knowledge/skills/network/bluetooth_forensics.md`
- `knowledge/skills/timestamps_reference.md`
- `worklog/2026-05-08_mobile_machine_sync.md` — 本文件

---

## 四、下一台接手机器需要做的

1. `git pull origin main` 后，进入 `knowledge/skills/mobile/` 直接消费 39 个 skill
2. 如果继续手机机器部署：按本文 §二"待办"清单从 ALEAPP/iLEAPP 下载开始，参考 `progress.txt`
3. 如要在比赛中用：先看 `quick_reference.md`，再按题型查具体 skill 卡
4. 如果接 2024FIC 残题（板块 2-6）：参考 `framework/HANDOFF.md` §五，关键工具是 `tools/e01_reader.py` + Python 3.10 dissect 栈

---

## 五、本次同步未推送的内容（避免污染主仓库）

刻意不推：
- `framework/bin/` 大量二进制 / 子模块（`apktool/`, `die/`, `ffuf/`, `platform-tools/`, `ALEAPP/`, `iLEAPP/` 等）— 体积大且与机器 / 网络绑定
- `framework/.venv/` — Python 虚拟环境
- `framework/references/` — 上游参考仓 (.gitignore 已排除)
- 本机 root `install_*.ps1`、`fix_tools.ps1`、`install_tools.log`、`HANDOVER.md` — 部署级脚本和日志，是这台机器的部署痕迹，不是协作产物
- 与仓库已有内容重复或更旧的 skill（`competition_playbook.md` 等）— 仓库版本更新

如果后续需要把"手机取证工具就绪报告"也归档进仓库，建议另起 `knowledge/skills/mobile/_machine_setup_report.md` 这样的文件。
