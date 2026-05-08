# 2026FIC 计算机取证 — 复盘 v1

> 对照官方 wp <https://mei-you-qian.github.io/2026/05/07/2026FIC%E5%88%9D%E8%B5%9B/> ，逐题核对 `D:\2026FIC\answers_final.md`。
> **结果：10 题中 4 对 (Q1/Q2/Q3/Q5)，1 个语义错 (Q6)，5 个完全错 (Q4/Q7/Q8/Q9/Q10)。**

---

## 一、逐题对照表

| # | 题面要点 | 我答 | 官方 | 命中 | 致命错因 |
|---|---|---|---|---|---|
| 1 | OS 版本 | 23.1 | 23.1 | ✅ | — |
| 2 | 钓鱼邮件发件人 | hf13338261292@outlook.com | hf13338261292@outlook.com | ✅ | — |
| 3 | 黄金换现金联系方式 | 13612817854 | 13612817854 | ✅ | — |
| 4 | 推广设计图 APK 链接 | `https://dl.sp-live88.com/update/latest.apk`（mobile 跨角色推断） | `https://drive.google.com/file/d/1z3aRS-lkaJYKm7Cp1XjtUmVPsOEVW2fV/view?usp=sharing` | ❌ | **没做 RSA Fermat 分解**，直接放弃私钥；又把 mobile 端的 APK 内嵌 update_url 当成图里二维码 |
| 5 | clash 代理端口 | 9527 | 9527 | ✅ | — |
| 6 | AI 软件当前模型类型 | minimax/minimax-m2.5:free | **OpenRouter** | ❌（语义错） | 题目"模型类型"指 UOS AI 设置页选的 **provider**，不是子模型；我未识别 deepin 自带 **UOS AI** |
| 7 | AI 软件 apiKey | "PC 不存在 → 转 server" | **UOS AI 本地 sqlite 的 llm 表**里有 | ❌ | 同上：没意识到 UOS AI 是 deepin 系统软件，配置在 `~/.config/uos-ai*` 的 sqlite 里 |
| 8 | 勒索解密联系方式 | "PC 无勒索本体 → server/mobile" | `beijixin996@tutanota.com` | ❌ | **vc 容器密码本就在手机便签**（`9ed2@99y8.com.cn`），里面有 `get_token_linux`（Go），main_main 中硬编码 tutanota 邮箱（小端序 UTF-8 拼接） |
| 9 | 保险柜编号 | "解密 vc 后看 VHD 内层" | `997546`（vc 内 mp4 stco 表 -1337 后帧像素显示） | ❌ | 同上：误判 vc 类型；不懂 mp4 `stco` chunk-offset 表可被偏移作隐写载体 |
| 10 | 保险柜密码 | "vc 16 字符暴破" | `583985`（`/root/文档/zhongyao/保险箱的秘密.et` WPS Shape 点阵字模 → `((x+100)^85)*1000+((y+100)^85)` 解码） | ❌ | **核心概念混淆**：把"vc 容器密码"等同于"保险柜密码"。两者完全独立——保险柜密码是 WPS .et 字模隐写的纯数字 |

---

## 二、错误根因（按破坏力排序）

### 1) 致命：vc 容器类型误判（连带 Q8/Q9/Q10 全错）

- **现象**：我反复深挖 SampleVC.exe 的"自定义 RC4/AES"，假设 vc 是 RC4-VHD；为此构造 unicorn oracle、SHA1+RC4 双验证、34526 候选暴破，全 miss。
- **真相**：vc 就是**标准 VeraCrypt 容器**（火眼直接弹"需 VeraCrypt 解密"提示）。SampleVC.exe 只是 `VirtDisk.dll` 调用器，无密码学逻辑核心。**密码 `9ed2@99y8.com.cn` 来自手机便签**——是跨检材联动点，不是逆向问题。
- **教训**：
  - **不要用反汇编替代取证软件的协议识别**；火眼的 magic 检测应作为第一信号源。
  - **`SampleVC.exe` 的命名本身就是提示**（"Sample VeraCrypt"）；我反而把它当成关键加密器深挖。
  - "16 字符 ASCII"是 SHA1 hash 的来源约束之一可能（实际官方密码 16 字符 `9ed2@99y8.com.cn` 倒确实满足），但 hash 校验对象与暴破是两回事——**hash 仅供校验，密码必须从用户记忆痕迹（便签/邮件/聊天）获得**。

### 2) 致命：保险柜 ≠ vc 容器

- **现象**：我把 Q9（保险柜编号）和 Q10（保险柜密码）都绑定到"vc 容器"上。
- **真相**：
  - Q9 答案 `997546` 在 vc 容器内的 **mp4** 里（stco offset -1337 后视频画面显示）。
  - Q10 答案 `583985` 在 `/root/文档/zhongyao/保险箱的秘密.et`，**完全独立于 vc 容器**，是 WPS Shape.AlternativeText 点阵字模隐写。
- **教训**：
  - **题面术语应当用全文搜索定位实体，再确认实体类型**：先搜 "保险" / "zhongyao" / ".et" / "保险箱"，不要先入为主把语义绑定到已经看到的资产上。
  - **每道题独立建立"实体→证据文件"映射**，不要让 Q1-Q9 的发现污染 Q10 的搜索域。

### 3) RSA Fermat 分解未尝试（Q4 错）

- **现象**：看到 `public.txt` 的 (n, e) 后，我搜了一圈"私钥文件"，没搜到就放弃。
- **真相**：n 的 decimal 长度 + p、q 接近的 hint，是 CTF 一眼可见的 Fermat 弱密钥；`isqrt(n)` 起步几次循环就能分解。
- **教训**：
  - **RSA 公钥到手必须强制走"弱密钥扫描套件"**（Fermat、Wiener、common modulus、low exponent）；这是固定模板，不超过 10 行代码 + 1 秒。
  - **永远不要因"私钥不在文件系统"而放弃**——CTF 设计本就要求选手算出私钥。

### 4) UOS AI 不识别（Q6/Q7 全错）

- **现象**：我搜了浏览器/邮件/`api_key` 通配符；从未搜过 `uos-ai` / `uos.ai` / `deepin-ai`。
- **真相**：UOS AI 是 deepin 23.1 自带的桌面 AI 助手，配置和聊天历史都在本地 sqlite，apiKey 字段直接存在表里。题目 6 问的是 UOS AI **provider**（即 OpenRouter），不是 OpenRouter 上选的子模型。
- **教训**：
  - **遇到"X 软件"题面，第一步不是"我家有什么 AI 软件"，而是 `dpkg -l | grep -i ai` / `find ~/.config -iname "*ai*"` / 看桌面 + 任务栏图标**。
  - **Linux 桌面发行版的"自带"应用是必查目录**（deepin: UOS AI / 语音记事本 / 文件保险柜 / Foxmail；Ubuntu: GNOME 系；KDE: KDE 系）。
  - **题面术语不要二次解读**："模型类型"对照设置页的 UI label，而不是猜成"模型名"。

### 5) 跨角色协作过度（错把"协作"当"借口"）

- **现象**：Q7/Q8/Q9/Q10 全部因为"在 PC 找不到"就转给 server / mobile / stego_crypto。Q4 因 mobile 已有 update_url 就照抄。
- **真相**：协作的前提是**自己已穷尽**。我连 `~/.config/uos-ai*`、`/root/文档/zhongyao`、`保险箱*.et`、`get_token_linux` 反汇编都没做就转手。
- **教训**：
  - **协作只在两种情况启用**：(a) 题面明确指向其他检材；(b) 自己穷尽所有合理路径后仍 0 命中。
  - **"在我的检材里没找到"≠"答案不在我的检材里"**——优先怀疑搜索范围不够。

### 6) 不会做 mp4 / WPS / Go ELF 反汇编

- **现象**：vc 容器解密后的 `.mp4`、`保险箱的秘密.et`、`get_token_linux`(Go ELF) 都需要二进制级别的解析。我把它们一律推给 binary 角色。
- **真相**：FIC 计算机题确实包含轻量级二进制工程（mp4 box 结构、OLE/CFB workbook 流、Go ELF main_main 反编译）。这是计算机角色的必备技能，不是 binary 角色的专利。
- **教训**：
  - **维护一个"取证文件格式 cookbook"**：mp4 atom、OLE/CFB、PE/ELF、sqlite WAL、leveldb、protobuf、SQLite encrypted、deepin-mail uuid 命名。
  - **看到 `.et`/`.wps` 不要绕开**：先 `file` 看是不是 OLE，是就 `olefile` 解压、找 Workbook 流、grep Shape AlternativeText。
  - **看到 ELF 不要先推走**：`strings | head` 30 秒就能看出语言；Go 程序看 `main.main` 的字符串拼接就能拿到硬编码常量。

---

## 三、系统性优化方案

### A. 做题流程（**新版**，单题 ≤ 30 分钟）

```
[题目接收]
   ↓
[T0] 关键词原文搜索（30 秒）
     - 题面里所有名词 → ripgrep 全检材
     - 命中文件 → 直接进 T2
   ↓
[T1] 火眼 / Autopsy / 取证软件 UI 浏览（5 分钟）
     - 系统信息、安装应用、桌面、最近文件、便签、浏览器历史
     - **任何"需要解密"的提示一律按提示走**（VC=VeraCrypt, BitLocker, Office DRM, ...）
   ↓
[T2] 实体路径定位（5 分钟）
     - 题面术语 → 文件路径（先 path-level，再 content-level）
     - 不要假设"题面 X = 资产 Y"，必须用证据链证明
   ↓
[T3] 证据级别判断（2 分钟）
     - 明文文件                     → 直接读
     - 标准加密容器（VC/BL/PGP）    → 找密码（其他检材 / 便签 / 邮件 / 聊天）
     - 自定义加密 / 隐写              → 反汇编 / 格式解析
     - 公钥但无私钥                   → RSA 弱密钥套件 (Fermat/Wiener/...)
   ↓
[T4] 解出 → 写答案 → 写证据链
   ↓
[T5] 30 分钟未解出 → 升级协作（带上"已尝试列表"，不要空手转）
```

### B. 必备速查清单（pre-computed）

#### B1 - Linux 桌面发行版必扫目录

```
deepin / UOS:
  ~/.config/uos-ai*/                  # UOS AI sqlite (apiKey, chat history)
  ~/.local/share/deepin/deepin-voice-note/   # 语音记事本
  ~/.config/deepin/deepin-mail/Storage/UID/  # 邮件 .eml + uuid 命名
  ~/.config/Foxmail.deepin/Storage/          # Foxmail
  ~/.config/io.github.clash-verge-rev.*/     # clash-verge
  ~/.config/google-chrome / chromium / deepin-browser-stable/Default/
  ~/.mozilla/firefox/*.default*/
  /root/文档/  /root/桌面/  /root/下载/        # root 用户目录中文化
  /var/lib/AccountsService/icons/             # 用户头像 → 真名
```

#### B2 - 文件签名优先级（先 magic 后扩展名）

```
D0CF11E0A1B11AE1     OLE/CFB     → olefile (xls/doc/wps/et/msg)
504B0304             ZIP         → docx/xlsx/jar/apk/odt 解压
7F454C46             ELF         → file + strings + ghidra/ida
4D5A                 PE          → pefile + strings
1F8B08               gzip
377ABCAF271C         7z
564843              "VHD" footer "conectix"
564552              VeraCrypt header (前 64KB 加密)
```

#### B3 - 弱密钥套件（公钥到手强制扫）

```python
# RSA: Fermat (p,q 接近) → Wiener (e>>n^0.25) → common modulus → ROCA
# DSA: nonce reuse
# ECC: curveball
# AES: 弱口令 (CrackStation/hashcat rockyou) + 字典生成（用户名/邮箱/生日/电话）
```

#### B4 - 跨检材"自然连接"提示

| 题面词 | 多半在哪 |
|---|---|
| 密码（容器/压缩包） | **手机便签 / 聊天 / 邮件**，不在 PC |
| apiKey / token | **目标软件本地 sqlite**，不在浏览器 |
| 推广图 / 二维码 / 短链 | **图片解密后扫码**，不一定有 URL 文本 |
| 保险柜 / 账单 / 隐藏文档 | **/root/文档**、Pictures、Documents 子目录里的 .et/.docx/.mp4 |
| 勒索 / 解密联系方式 | **勒索程序本体** 里的硬编码字符串（go: `qmemcpy(v6, "...@...", ...)`） |

### C. 工具链精简（避免重复造轮子）

| 任务 | 工具 |
|---|---|
| E01 挂载 | `ewfmount` + `losetup -P` + `mount -o ro` |
| 全盘搜索 | `ripgrep -a -uu --no-binary` |
| OLE 解析 | `olefile`（Python） |
| mp4 atom | 手写 stco/co64 解析（10 行） |
| ELF 反汇编 | `ghidra` 优先；`strings + capstone` 兜底 |
| Go 反编译 | `IDA 9.2` 或 `redress` / `golang-binary-grep` |
| RSA 弱密钥 | `RsaCtfTool` / 自写 Fermat |
| sqlite | `sqlite3 file.db ".tables" + "SELECT * FROM xxx LIMIT 5"` |

### D. "时间盒"硬约束

- **每题硬上限 30 分钟**；超时立即升级到协作或跳过。
- **第一遍 10 题快速过**（每题 ≤ 5 分钟），先抓"火眼一眼可见 + 关键词直接命中"的 4-6 道。
- **第二遍**对剩下的题做 T1-T4 深挖。
- **第三遍**才做反汇编/隐写/弱密钥这种重活。
- 这次失败的根本节奏问题：Q9/Q10 单题花了 8+ 小时反汇编 SampleVC.exe，**完全没去看 `/root/文档/zhongyao/`**。

---

## 四、对自己的核心反思（一句话）

**"我用 binary 角色的工作方式做了 computer 角色的题目"** —— 把每个加密文件都当成密码学谜题深挖，而忽略了"取证 = 找用户的痕迹"这个根本范式。

下次先做"找痕迹"，找不到再做"破密码"。
