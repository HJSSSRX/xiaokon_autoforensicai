# 工具清单

**生效版本**：v1.1  
**最后更新**：2026-04-26（FIC2026 赛后更新）  
**维护责任**：AI（每次使用后更新）

---

## 🔧 取证分析工具

### Volatility 3
- **用途**：内存镜像分析，进程、网络、句柄等
- **安装位置**：WSL `/opt/volatility3/` 或 Windows `E:\tools\volatility3\`
- **版本**：volatility3-2.7.0
- **常用命令**：
```bash
# 基本信息获取
python3 /opt/volatility3/vol.py -f <memdump.dmp> windows.info.Info

# 进程列表
python3 /opt/volatility3/vol.py -f <memdump.dmp> windows.pslist.PsList

# 命令行
python3 /opt/volatility3/vol.py -f <memdump.dmp> windows.cmdline.CmdLine

# 网络连接
python3 /opt/volatility3/vol.py -f <memdump.dmp> windows.netstat.Netstat

# 句柄分析
python3 /opt/volatility3/vol.py -f <memdump.dmp> windows.handles.Handles
```

### SQLite3
- **用途**：数据库查询，邮件、聊天记录等
- **安装位置**：系统自带 `/usr/bin/sqlite3`
- **版本**：3.37.2
- **常用命令**：
```bash
# 查询表结构
sqlite3 mail.db ".tables"

# 查询邮件
sqlite3 mail.db "SELECT subject, sender FROM MailMeta WHERE hasAttachment=1;"

# 查询附件
sqlite3 mail.db "SELECT filename, size, localPath FROM MailAttachment;"
```

### SQLCipher
- **用途**：加密数据库解密（微信等）
- **安装位置**：`/usr/bin/sqlcipher`
- **版本**：4.5.3
- **常用命令**：
```bash
# 解密微信数据库
sqlcipher EnMicroMsg.db "PRAGMA key = '<key>'; PRAGMA cipher_page_size = 4096; ATTACH DATABASE 'decrypted.db' AS decrypted KEY ''; SELECT sqlcipher_export('decrypted');"
```

---

## 🕵️ 文件分析工具

### Strings
- **用途**：提取二进制文件中的字符串
- **安装位置**：系统自带 `/usr/bin/strings`
- **版本**：2.34
- **常用命令**：
```bash
# 提取所有字符串
strings malware.exe

# 提取可打印字符，最小长度10
strings -n 10 malware.exe

# 查找特定字符串
strings malware.exe | grep -i "password"
```

### Binwalk
- **用途**：固件分析，文件提取
- **安装位置**：`/usr/bin/binwalk`
- **版本**：2.3.3
- **常用命令**：
```bash
# 扫描文件
binwalk firmware.bin

# 提取文件
binwalk -e firmware.bin

# 签名分析
binwalk -y firmware.bin
```

### Exiftool
- **用途**：元数据提取
- **安装位置**：`/usr/bin/exiftool`
- **版本**：12.60
- **常用命令**：
```bash
# 查看所有元数据
exiftool photo.jpg

# 查看GPS信息
exiftool -gpsphoto.jpg

# 批量处理
exiftool -r ./images/
```

---

## 🌐 网络分析工具

### Curl
- **用途**：HTTP请求，API调用
- **安装位置**：系统自带 `/usr/bin/curl`
- **版本**：7.81.0
- **常用命令**：
```bash
# GET请求
curl -s "http://example.com/api"

# POST请求
curl -X POST -d "data=value" http://example.com/api

# 保存文件
curl -O http://example.com/file.zip
```

### Wget
- **用途**：文件下载
- **安装位置**：`/usr/bin/wget`
- **版本**：1.21.2
- **常用命令**：
```bash
# 下载文件
wget http://example.com/file.zip

# 递归下载
wget -r -np http://example.com/files/
```

---

## 📦 压缩解压工具

### 7z
- **用途**：多格式压缩解压
- **安装位置**：`/usr/bin/7z`
- **版本**：16.02
- **常用命令**：
```bash
# 解压zip
7z x archive.zip

# 解压rar
7z x archive.rar

# 查看压缩包内容
7z l archive.zip
```

### Tar
- **用途**：tar包处理
- **安装位置**：系统自带 `/bin/tar`
- **版本**：1.34
- **常用命令**：
```bash
# 解压tar.gz
tar -xzf archive.tar.gz

# 解压tar
tar -xf archive.tar

# 查看内容
tar -tzf archive.tar.gz
```

---

## 🐍 Python 工具包

### pysqlcipher3-binary
- **用途**：Python SQLCipher绑定
- **安装位置**：Python site-packages
- **版本**：1.0.9
- **常用代码**：
```python
import sqlite3
conn = sqlite3.connect('EnMicroMsg.db')
conn.execute("PRAGMA key = 'yourkey'")
conn.execute("PRAGMA cipher_page_size = 4096")
```

### requests
- **用途**：HTTP请求库
- **安装位置**：Python site-packages
- **版本**：2.28.1
- **常用代码**：
```python
import requests
r = requests.post('http://spammimic.com/decode.cgi', data={'cyphertext': text})
print(r.text)
```

---

## 🔍 文本处理工具

### Grep
- **用途**：文本搜索
- **安装位置**：系统自带 `/bin/grep`
- **版本**：3.7
- **常用命令**：
```bash
# 搜索字符串
grep -r "password" ./data/

# 忽略大小写
grep -i "error" logfile.txt

# 显示行号
grep -n "pattern" file.txt
```

### Sed
- **用途**：文本替换
- **安装位置**：系统自带 `/bin/sed`
- **版本**：4.8
- **常用命令**：
```bash
# 替换字符串
sed 's/old/new/g' file.txt

# 删除行
sed '/pattern/d' file.txt
```

### Awk
- **用途**：文本处理
- **安装位置**：系统自带 `/usr/bin/awk`
- **版本**：5.1.1
- **常用命令**：
```bash
# 提取列
awk '{print $1, $3}' file.txt

# 条件处理
awk '$3 > 100 {print $0}' file.txt
```

---

## 📋 系统工具

### Find
- **用途**：文件查找
- **安装位置**：系统自带 `/usr/bin/find`
- **版本**：4.8.0
- **常用命令**：
```bash
# 按名称查找
find / -name "*.db"

# 按大小查找
find / -size +10M

# 按时间查找
find / -mtime -7
```

### Lsof
- **用途**：查看打开文件
- **安装位置**：`/usr/bin/lsof`
- **版本**：4.93.2
- **常用命令**：
```bash
# 查看进程打开的文件
lsof -p 1234

# 查看网络连接
lsof -i :80
```

### Netstat
- **用途**：网络状态
- **安装位置**：`/bin/netstat`
- **版本**：2.10
- **常用命令**：
```bash
# 查看所有连接
netstat -a

# 查看监听端口
netstat -ln
```

---

## 🛠️ 安装脚本

### WSL 环境初始化
```bash
#!/bin/bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y sqlite3 sqlcipher binwalk exiftool curl wget p7zip-full

# 安装Python包
pip3 install pysqlcipher3-binary requests

# 安装Volatility3
cd /opt
sudo git clone https://github.com/volatilityfoundation/volatility3.git
cd volatility3
sudo pip3 install -r requirements.txt
```

### Windows 环境初始化
```powershell
# 使用Chocolatey安装工具
choco install 7zip curl wget

# 下载Volatility3
Invoke-WebRequest -Uri "https://github.com/volatilityfoundation/volatility3/releases/download/v2.7.0/volatility3-2.7.0.zip" -OutFile "volatility3.zip"
Expand-Archive volatility3.zip -DestinationPath "C:\tools\volatility3"
```

---

## 📝 使用记录

### 最近使用（2026-04-24）
1. **Volatility3** - 分析微信内存 dump (`pid.10892.dmp`)
2. **SQLite3** - 查询邮件数据库 (`mail.db`)
3. **Strings** - 分析恶意软件 (`Haimuniu_VPN_Client.exe`)
4. **Curl** - spammimic 解码请求
5. **7z** - 解压邮件附件

### 问题记录
- **SQLCipher** - 解密微信数据库失败，密钥可能不正确
- **pysqlcipher3** - 编译失败，改用 pysqlcipher3-binary
- **PowerShell** - WSL 调用时 BOM 问题，需用 UTF8 无 BOM

---

## 🔄 更新日志

| 日期 | 工具 | 版本 | 变更 |
|------|------|------|------|
| 2026-04-24 | volatility3 | 2.7.0 | 新增 |
| 2026-04-24 | pysqlcipher3-binary | 1.0.9 | 替代 pysqlcipher3 |
| 2026-04-24 | sqlcipher | 4.5.3 | 新增 |

---

*AI 每次使用工具后应更新本文件，记录版本变化和使用问题。*

---

## 📊 FIC2026 实战评估

> 以下标注各工具在 FIC2026 中的**实际使用状态和效果**。

### 高频高效（★★★★★）必装
| 工具 | 使用场景 | 效果 |
|------|---------|------|
| sqlite3 | 几乎每题的数据库查询 | 核心工具 |
| jadx | M03-M17 全部 APK 反编译 | 手机题生命线 |
| radare2 | B01-B03 PE 逆向分析 | 唯一免费 PE 分析器 |
| grep/strings/find | 全局搜索 | 基础设施 |
| python3 + pycryptodome | AES/XTEA/XOR 解密 | 密码学万能钥匙 |
| sqlcipher3 | WuKong IM 加密 DB 解密 | 手机题关键 |
| openssl | SM3 哈希、AES-ECB 解密 | 无需额外安装 |

### 中频有用（★★★☆☆）建议装
| 工具 | 使用场景 | 备注 |
|------|---------|------|
| exiftool | 照片/视频元数据 | M10 尝试 DJI EXIF |
| btrfs-progs | 服务器 btrfs 挂载 | S04 快照路径 |
| 7z / unzip | .et 文件解压分析 | C09/C10 |

### 低频/未用（★☆☆☆☆）视题型决定
| 工具 | 状态 | 原因 |
|------|------|------|
| volatility3 | 未用 | FIC2026 无内存分析题 |
| tshark/zeek | 未用 | 无网络包分析题 |
| tesseract OCR | 用了但效果差 | 推广图识别失败 |
| sleuthkit (fls/icat) | 未用 | 检材已挂载，无需底层分析 |
| binwalk | 未用 | 无固件分析题 |

### 应该装但没装（导致失分）
| 工具 | 影响题目 | 说明 |
|------|---------|------|
| DJI Flight Log 解析器 | M10 | V12+ 加密无公开工具 |
| PaddleOCR | C04 | tesseract 效果差，PaddleOCR 可能更好 |
| TiDB 离线解析工具 | S08/S13-S15 | 无法直接读 TiDB 数据文件 |
