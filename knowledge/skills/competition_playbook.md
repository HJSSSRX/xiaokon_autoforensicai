# Competition Playbook — 比赛实战手册

> Source: FIC2026 LESSONS_LEARNED + RETROSPECTIVE

## 赛前环境准备清单

### 必装 (WSL)
```
sqlite3, sqlcipher, jadx, radare2, python3, pycryptodome,
strings, grep, find, file, xxd, openssl, exiftool, 7z
```

### 必装 (Windows)
```
7zip, Arsenal Image Mounter (或 FTK Imager)
```

### 必装 (Python)
```
sqlcipher3, pycryptodome, openpyxl, pandas
```

### 建议装
```
WSL: binwalk, volatility3, tshark, btrfs-progs, lvm2, ewf-tools
Python: aleapp, ileapp
```

### 可不装
```
tesseract (OCR 效果差，用 PaddleOCR 替代)
zeek (网络分析，通常不用)
```

## 题型速查与时间估计

| 题型 | 典型工具 | 耗时 | 技巧 |
|------|---------|------|------|
| 操作系统版本 | `cat /etc/os-release` | 1 min | 速通 |
| 数据库查询 | sqlite3 | 5-10 min | 先 `.tables` 再 `.schema` |
| APP 反编译 | jadx + grep | 15-30 min | 搜 `Cipher/Key/Base64` |
| 加密DB解密 | sqlcipher3 | 10-20 min | APK 中找 `PRAGMA key` |
| PE 逆向 | r2 + strings | 30-60 min | 先 strings 再反汇编 |
| 邮件分析 | python email | 10-20 min | 建全量索引 |
| 文件系统分析 | mount + find | 10-15 min | 先 fstab 再 mount |
| Native SO 逆向 | r2 + python | 30-60 min | `readelf -x .rodata` 先看数据 |
| 密码学解密 | python + openssl | 15-30 min | 识别算法→找key→复现 |

## 核心方法论

### 1. SQLCipher 是必备工具
- 现代 APP (微信、WuKong IM、Signal) 全用 SQLCipher
- 密码藏在 APK 反编译代码中，搜 `PRAGMA key`、`getWritableDatabase`

### 2. jadx 反编译是手机题命脉
- 手机 APP 逆向占手机题 70%+ 工作量
- 关注: `@JavascriptInterface`、`SharedPreferences`、`Base64`、`Cipher`

### 3. 全盘搜索 > 猜路径
```bash
grep -r 'BEGIN RSA PRIVATE' /tmp/pc_data/         # 找私钥
strings -n 8 /tmp/pc_data/home/*/.* | grep -iE 'pass|pwd|key'  # 找密码
find /tmp -name '*.db' -o -name '*.sqlite' | head -50           # 找数据库
```

### 4. 30 分钟卡住就跳题
- 先做所有"速通"题 (15 min 内能解)，再回头啃硬骨头
- 跳题时记录进度: "已定位到 X 文件，缺 Y 信息"

### 5. 邮件题先建全量索引
- 用 Python `email` 模块遍历所有 `.eml`
- 导出 CSV/JSON 后用 grep 搜索
- 不要逐个文件手动看

### 6. 跨检材关联是高分题关键
- 答案常分散在 PC + 手机 + 服务器中
- TEAM 模式用 `facts/` 文件跨机共享发现

### 7. 密码学题通用解法
1. 识别加密算法 (AES/RSA/XOR/Base64/自定义)
2. 找密钥来源 (代码硬编码？配置文件？用户输入？)
3. Python 复现解密 (pycryptodome 覆盖 90% 场景)
4. 验证结果 (可读文本/合法文件格式)

### 8. openssl 瑞士军刀
```bash
openssl dgst -sm3 file                                      # SM3 哈希
openssl enc -aes-128-ecb -d -nopad -K hex_key -in ct.bin     # AES 解密
openssl x509 -in cert.pem -text                              # 证书解析
```

## PowerShell + WSL 注意事项
- 复杂 bash 命令**写成 .sh 文件再执行**
- 如必须内联: `wsl bash -lc "简单命令"` 且不超过一个管道
- 永远不要在 PowerShell 中内联复杂 bash

## FIC2026 板块成功率参考

| 板块 | 题数 | 成功率 | 关键工具 |
|------|------|--------|---------|
| 手机 | 17 | 88% (15/17) | jadx + sqlcipher + sqlite3 |
| 服务器 | 17 | 76% (13/17) | mount + grep + sqlite3 |
| 计算机 | 10 | 70% (7/10) | python email + r2 |
| 二进制 | 5 | 60% (3/5) | r2 + strings + openssl |
| 互联网 | 3 | 33% (1/3) | grep + nginx |
