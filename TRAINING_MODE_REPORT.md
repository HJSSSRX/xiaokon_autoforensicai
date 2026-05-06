# 训练模式故障报告 — 2024FIC 决赛全自动训练

**日期**: 2026-05-05  
**触发**: 用户选择"全自动训练模式"，提供 2024FIC 决赛检材 + WP  
**实际结果**: 退化为"灌知识模式"——仅从 WP 提取答案写入 KB，未独立解题  

---

## ⚡ 修复状态 (2026-05-05 23:50)

**Layer 1 已修复！** E01 镜像访问问题已解决：
- Python 3.10 + dissect 库安装成功
- `tools/e01_reader.py` 已编写并通过端到端测试
- PersonalPC.E01 (60GB, NTFS) 文件系统完全可读
- 验证：能看到 `/Users/Luck/Desktop/老婆.png` 等题目中的关键文件

**仍然缺失**:
- hashcat（密码爆破）— 需手动下载
- binwalk（隐写分析）— 需 pip install
- VMDK 支持尚未测试（服务器镜像需要）
- PVE 嵌套虚拟化仍然无法 CLI 操作  

---

## 一、发生了什么

| 步骤 | 预期行为 | 实际行为 |
|---|---|---|
| 1. 接收检材 | 分析 E01 镜像内容 | ❌ 无法打开 E01（缺工具） |
| 2. 搜索 KB | 查找先验知识 | ✅ 正常（KB 无相关条目） |
| 3. 解题 | CLI 操作取证分析 | ❌ 直接读 WP 抄答案 |
| 4. 验证答案 | 独立验证 flag | ❌ 无法验证（没有数据） |
| 5. 写入 KB | 写结构化 writeup | ⚠️ 写了，但 verified 应为 false |

**根本原因**: AI 无法读取 E01 镜像内的文件系统，所有后续步骤都无法执行。

---

## 二、本机资源盘点

### 硬件
| 项目 | 值 |
|---|---|
| OS | Windows 11 家庭中文版 (26200) |
| RAM | 32 GB |
| 磁盘 | C: 141GB空闲, D: 221GB空闲, E: 253GB空闲 |

### 已安装取证软件（全部 GUI）
| 软件 | 路径 | AI可操作? |
|---|---|---|
| **火眼证据分析 V4** (GoldenEyes) | D:\ffffffff\fireeyes\证据分析\ | ❌ GUI |
| **火眼仿真 V4** (BootMagix) | D:\ffffffff\fireeyes\火眼仿真\ | ❌ GUI |
| **网矩数据分析 V4** (WebMatrix) | D:\ffffffff\fireeyes\网矩数据分析\ | ❌ GUI |
| **雷电手机快取** (Thunder) | D:\ffffffff\fireeyes\雷电手机快取\ | ❌ GUI |
| **雷电云快取** (ThunderCloud) | D:\ffffffff\fireeyes\雷电云快取\ | ❌ GUI |
| **苍穹AI引擎** (Firmament) | C:\Program Files\Honglian\FirmamentAIEngine\ | ❌ GUI (Electron) |
| **取证桌面** (ForensicDesktop) | D:\ffffffff\fireeyes\取证桌面\ | ❌ GUI (Electron) |
| **OSFMount** ⭐ 新装 | C:\Program Files\OSFMount\ | ⚠️ 需管理员权限 |

### CLI 工具
| 工具 | 状态 | 来源 |
|---|---|---|
| Python 3.8.6 | ✅ 默认 PATH | C:\Program Files\python\ |
| Python 3.10.5 | ✅ 可用 | C:\Program Files\Python310\ |
| 7-Zip | ✅ | C:\Program Files\7-Zip\ |
| strings | ✅ | mingw64 |
| nmap | ✅ | C:\Program Files (x86)\Nmap\ |
| git | ✅ | C:\Program Files\Git\ |
| certutil | ✅ | 系统自带 |
| exiftool ⭐ (火眼内置) | ✅ | D:\ffffffff\...\GoldenEyesV4\exiftool.exe |
| ExifTool ⭐ 新装 | ✅ | winget 安装 |

### Python 包（3.8）
| 包 | 用途 |
|---|---|
| Pillow | 图像处理 |
| pycryptodome | 加解密 |
| python-registry | Windows 注册表解析 |
| oletools | Office 文档分析 |
| exifread | EXIF 读取 |
| cryptography | 加密操作 |

### 缺失的关键工具
| 工具 | 用途 | 能否安装 |
|---|---|---|
| **E01 解析** (pyewf/libewf/dissect) | 读取 E01 镜像 | ⚠️ Python 3.10 可能装 dissect |
| **文件系统解析** (pytsk3/sleuthkit) | 遍历 NTFS/ext4 | ❌ 编译失败 |
| **hashcat** | 密码爆破 | 需手动下载 |
| **binwalk/foremost** | 二进制分析/文件提取 | 需手动下载 |
| **volatility3** | 内存取证 | pip install 可能可行 |

---

## 三、问题诊断：为什么训练模式不可用

### 核心障碍链

```
E01 镜像 (75GB)
    ↓ 需要 E01 解析器
无法读取文件系统
    ↓ 所有取证操作依赖文件访问
无法独立解题
    ↓ 退化为
只能从 WP 抄答案 = 灌知识模式
```

### 分层分析

**Layer 1 — 镜像访问**（最关键）
- E01 是 EnCase 专有格式，不能直接文件系统挂载
- OSFMount 可以挂载但需要**管理员权限**（当前终端无管理员）
- pyewf/pytsk3 编译失败（Python 3.8 + 无 C 编译器）

**Layer 2 — GUI 依赖**
- 火眼全套是 GUI 软件，AI 无法操作
- PVE Web UI 需要浏览器
- 嵌套虚拟化需要 VMware GUI

**Layer 3 — 工具链不完整**
- 无 hashcat（密码爆破）
- 无 binwalk/foremost（隐写分析）
- 无 volatility（内存取证）

---

## 四、解决方案

### 方案 A：最小修复 — 让 AI 能读 E01（推荐优先执行）

**目标**: AI 能浏览 E01 内的文件系统，提取文件，计算哈希

1. **用 Python 3.10 安装 dissect 库**
   ```powershell
   & "C:\Program Files\Python310\python.exe" -m pip install dissect.ewf dissect.volume dissect.ntfs dissect.fat dissect.extfs
   ```
   dissect 是 Fox-IT 出品的纯 Python 取证库，不需要 C 编译器

2. **如果 dissect 不可用，用 OSFMount CLI（需管理员终端）**
   ```powershell
   # 以管理员运行
   OSFMount.com -a -t file -f "E:\...\PersonalPC.E01" -m Z:
   # 之后 Z: 就是普通文件系统，AI 可以 dir/type/copy
   ```

3. **写一个 Python 脚本 `tools/mount_e01.py`** 作为统一入口：
   - 尝试 dissect → 成功则直接 Python 内遍历
   - 失败则调用 OSFMount CLI → 挂载为盘符
   - 提供 `list_files()`, `extract_file()`, `hash_file()` 接口

**效果**: AI 能做约 60% 的计算机取证题（文件搜索、哈希、配置文件读取、隐写分析）

### 方案 B：补全 CLI 工具链

| 工具 | 安装方式 | 解决的题型 |
|---|---|---|
| hashcat | GitHub release 下载 | 密码爆破 (Q8, Q9) |
| binwalk | pip install (Python 3.10) | 隐写分析 (Q8) |
| volatility3 | pip install | 内存取证 |
| jadx-cli | GitHub release 下载 | JAR 反编译（服务器取证） |

### 方案 C：解决 GUI 问题（长期）

**选项 1**: 苍穹AI引擎如果有 API/CLI 模式，可以直接调用火眼功能
**选项 2**: 写 AutoHotKey 脚本自动化火眼 GUI 操作（脆弱但可行）
**选项 3**: 对 PVE/OpenWrt 题——直接解析配置文件（/etc/pve/, /etc/config/）而不仿真

### 方案 D：重新定义"全自动训练"的适用范围

承认并非所有题目都适合全自动。按题目类型分类：

| 类型 | AI 全自动? | 条件 |
|---|---|---|
| 文件哈希计算 | ✅ | 镜像可挂载 |
| 配置文件分析 | ✅ | 镜像可挂载 |
| 注册表分析 | ✅ | python-registry |
| 隐写/文件提取 | ✅ | binwalk + Python |
| 密码爆破 | ⚠️ 半自动 | hashcat（耗时长） |
| EXIF/元数据 | ✅ | exiftool |
| SQL 数据库查询 | ✅ | 数据库文件可提取 |
| GUI 仿真操作 | ❌ | 需要人工 |
| 嵌套 VM 操作 | ❌ | 需要人工 |
| 浏览器交互 | ❌ | 需要人工 |

---

## 五、理想结果

### 全自动训练应该长这样：

```
用户: "小空自己动" → 全自动训练
用户: 提供 E01 路径 + 题目 + 答案

小空:
  1. mount_e01.py 挂载镜像 → 得到文件系统访问
  2. 搜索 KB → 无先验知识
  3. 分析文件系统：
     - 列出桌面文件 → 发现老婆.png、日报.docx
     - 读取回收站 → 发现备忘录.txt
     - 搜索 MobaXterm 配置 → 找到 SSH session
     - 搜索 QtScrcpy config → 读 userdata.ini
     - exiftool 老婆.png → 提取 Stable Diffusion 参数
     - binwalk 老婆.png → 提取隐藏的 xls
     - hashcat 爆破 xls 密码 → P1ssw0rd
  4. 逐题验证答案与已知答案一致
  5. 生成 verified: true 的 KB 文件
  6. 报告: "15 题中 AI 独立完成 11 题，4 题需人工（GUI 仿真相关）"
```

### 与当前差距

| 能力 | 理想 | 现状 |
|---|---|---|
| 读 E01 内文件 | ✅ 自动挂载 | ❌ 无工具 |
| 文件哈希 | ✅ sha256sum | ❌ 无文件访问 |
| 隐写分析 | ✅ binwalk+exiftool | ⚠️ 有 exiftool 无 binwalk |
| 密码爆破 | ✅ hashcat | ❌ 未安装 |
| 注册表 | ✅ python-registry | ⚠️ 有库无文件访问 |
| 配置文件 | ✅ grep/cat | ❌ 无文件访问 |
| GUI 操作 | ❌ 承认不能 | ❌ 同 |

### 下一步行动（按优先级）

1. **立即**: 用 Python 3.10 尝试安装 dissect 库
2. **立即**: 如果成功，写 `tools/mount_e01.py` 统一接口
3. **短期**: 下载 hashcat、binwalk 可执行文件
4. **短期**: 用挂载后的文件系统重新跑一遍计算机取证板块，验证可行性
5. **中期**: 调研苍穹AI引擎是否有 CLI/API
6. **长期**: 对 PVE/OpenWrt 类题目，开发配置文件直接解析方案（不依赖仿真）

---

## 六、对 knowledge/solved/ 文件的修正

刚才写入的 6 个文件 `verified: true` 不准确，应改为 `verified: false`，因为答案来自第三方 WP 而非独立验证。
