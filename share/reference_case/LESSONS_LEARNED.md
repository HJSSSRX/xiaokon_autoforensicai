# FIC2026 可迁移教训

> 本文件从 FIC2026 实战中提炼的**通用教训**，适用于任何电子取证比赛。

---

## 工具链教训

### 1. SQLCipher 是必备工具，不是可选项
- 现代 APP（微信、WuKong IM、Signal 等）几乎全部使用 SQLCipher 加密数据库
- **必须提前装好 `sqlcipher3` Python 包**，不能等比赛时再装
- 密码通常藏在 APK 反编译代码中，搜索 `PRAGMA key`、`getWritableDatabase` 关键方法

### 2. jadx 反编译能力决定手机题上限
- 手机 APP 逆向占手机题 70%+ 的工作量
- **jadx 1.5+ 必装**，配合 `grep -r` 在反编译输出中搜索关键字效率极高
- 关注 `@JavascriptInterface`、`SharedPreferences`、`Base64`、`Cipher` 等关键注解和类

### 3. radare2 是唯一免费的 PE 静态分析方案
- Windows PE 逆向在无 IDA 的情况下只能靠 r2
- 常用命令序列：`aaa; afl; pdf @fcn.xxx; px 256 @addr`
- **一定要分析对比函数**（`strncmp`、`memcmp`），从那里回溯找密码校验逻辑

### 4. tesseract OCR 在取证场景中效果差
- 推广图、截图中的文字 OCR 识别率很低
- **建议转为人工目视确认**，或使用更好的 OCR 引擎（如 PaddleOCR）
- 如果文字在截图中，先裁剪再 OCR 效果会好很多

### 5. openssl 是瑞士军刀
- SM3 哈希：`openssl dgst -sm3 file`
- AES 解密：`openssl enc -aes-128-ecb -d -nopad -K hex_key -in ct.bin`
- 证书解析：`openssl x509 -in cert.pem -text`
- **不需要额外安装任何密码学工具**

---

## 方法论教训

### 6. 邮件题先建全量索引
- **第一步**：用 Python `email` 模块遍历所有 `.eml` 文件，提取（发件人、主题、日期、附件列表、正文前 500 字）
- **第二步**：导出为 CSV 或 JSON，用 grep 搜索
- **不要**逐个文件手动看，效率太低
- deepin-mail 的数据在 `~/.local/share/deepin/deepin-mail/` 下，Foxmail 在 `Foxmail 7.2/` 下

### 7. "全盘搜索特征串" 比 "猜路径" 快
- 找私钥？`grep -r 'BEGIN RSA PRIVATE' /tmp/pc_data/`
- 找密码？`strings -n 8 /tmp/pc_data/home/*/.* | grep -iE 'pass|pwd|key'`
- 找数据库？`find /tmp -name '*.db' -o -name '*.sqlite' | head -50`
- **不要猜**文件在哪，直接搜

### 8. 30 分钟卡住就跳题
- 比赛时间有限，一道 11 分的题卡 1 小时 = 亏损
- 先做所有"速通"题（通常 15 分钟内能解），再回头啃硬骨头
- **跳题时记录当前进度**（"已定位到 X 文件，缺 Y 信息"），方便回来

### 9. 跨检材关联是高分题的关键
- 很多题的答案分散在 PC + 手机 + 服务器中
- 例如：服务器 maccms 配置中的数据库 IP 指向 LXC 容器
- 例如：手机聊天记录中提到的钱包地址需要在 PC 交易记录中验证
- **TEAM 模式下用 facts/ 文件跨机共享发现**

### 10. 密码学题的通用解法
- **步骤 1**: 识别加密算法（AES/RSA/XOR/Base64/自定义）
- **步骤 2**: 找密钥来源（代码中硬编码？配置文件？用户输入？）
- **步骤 3**: 用 Python 复现解密（pycryptodome 覆盖 90% 场景）
- **步骤 4**: 验证解密结果（是否为可读文本/合法文件格式）

---

## 协作教训

### 11. 三机协作的瓶颈是信息同步
- Git push/pull 的延迟 + 冲突处理 = 实际浪费 10-15 分钟
- **facts/ 目录**是跨机共享发现的生命线，必须勤写
- 每发现一个跨检材线索，立刻写入 `facts/<板块>.md`

### 12. Phone 板块产出最高
- 手机检材题目多（17题）、分值密集、且 APP 分析套路化
- **建议优先分配最强分析力到 Phone 窗口**
- 手机题 15/17 的成功率证明了：jadx + sqlcipher + sqlite3 三件套足以覆盖

### 13. PowerShell + WSL 是个坑
- 复杂 bash 命令**永远不要**内联到 PowerShell
- **写成 .sh 文件再执行**，零出错率
- 如果必须内联，用 `wsl bash -lc "简单命令"` 且不超过一个管道

---

## 环境准备清单（赛前）

```
必装:
  WSL: sqlite3, sqlcipher, jadx, radare2, python3, pycryptodome, 
       strings, grep, find, file, xxd, openssl, exiftool, 7z
  Windows: 7zip, Arsenal Image Mounter (或 FTK Imager)
  Python: sqlcipher3, pycryptodome, openpyxl, pandas

建议装:
  WSL: binwalk, volatility3, tshark, btrfs-progs, lvm2, ewf-tools
  Python: aleapp, ileapp

可不装:
  tesseract (OCR 效果差)
  zeek (网络分析，本次未用)
```

---

## 题型速查表

| 题型 | 典型工具 | 耗时估计 | 技巧 |
|------|---------|---------|------|
| 操作系统版本 | cat /etc/os-release | 1 min | 速通 |
| 数据库查询 | sqlite3 | 5-10 min | 先 .tables 再 .schema |
| APP 反编译 | jadx + grep | 15-30 min | 搜 Cipher/Key/Base64 |
| 加密DB解密 | sqlcipher3 | 10-20 min | APK 中找 PRAGMA key |
| PE 逆向 | r2 + strings | 30-60 min | 先 strings 再反汇编 |
| 邮件分析 | python email | 10-20 min | 建全量索引 |
| 文件系统分析 | mount + find | 10-15 min | 先 fstab 再 mount |
| Native SO 逆向 | r2 + python | 30-60 min | readelf -x .rodata 先看数据 |
| 密码学解密 | python + openssl | 15-30 min | 识别算法→找key→复现 |

---

*本文件应在每次比赛后更新，积累团队的集体经验。*
