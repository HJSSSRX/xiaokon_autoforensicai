# 工具速查表

每个工具一行定位 + 最常用命令。按检材类型分组。所有命令假设：
- `$EVIDENCE` 指向原始检材（镜像 / 压缩包 / pcap）
- `$OUT` 指向输出目录

---

## 0. 基础搜索（所有平台都要会）

| 工具 | 定位 | 最常用命令 |
|---|---|---|
| `rg` (ripgrep) | 跨文件极速全文搜索 | `rg -i '关键词' $DIR` |
| `grep` | 标准文本搜索 | `grep -rin 'pattern' $DIR` |
| `find` / `fd` | 按名字/大小/时间找文件 | `find $DIR -name '*.db' -size +1M` |
| `jq` | JSON 查询 | `jq '.[] | select(.pid==1234)' x.json` |
| `sqlite3` | SQLite 交互/导出 | `sqlite3 x.db '.schema'` / `.dump` |
| `exiftool` | 文件元数据（EXIF、PDF、Office） | `exiftool -r -csv $DIR > exif.csv` |
| `strings` | 从二进制提取可打印字符串 | `strings -n 8 file.bin | rg -i 'http'` |
| `xxd` / `hexdump` | 十六进制查看 | `xxd file | head -50` |
| `file` | 识别文件真实类型 | `file $(find . -type f) | rg -v ASCII` |

---

## 1. 磁盘镜像（E01 / dd / vmdk / vhd / raw）

### 识别与预览

| 工具 | 用法 |
|---|---|
| `mmls` (sleuthkit) | 列出分区表 → `mmls $EVIDENCE` |
| `fsstat` | 文件系统信息 → `fsstat -o <offset> $EVIDENCE` |
| `fls` | 递归列文件 → `fls -r -o <offset> $EVIDENCE` |
| `icat` | 按 inode 导出文件 → `icat -o <offset> $EVIDENCE <inode> > out` |
| `tsk_recover` | 批量恢复（含已删除） → `tsk_recover -o <off> $EVIDENCE $OUT` |
| `ewfinfo` / `ewfmount` | E01 元数据 / 挂成裸映像 |
| `qemu-img info` | vmdk/vhd/qcow2 元数据 |

### 挂载（只读！）

```bash
# E01 → 裸映像 → ntfs 挂载
ewfmount $EVIDENCE /mnt/ewf
sudo mount -o ro,loop,offset=$((2048*512)) /mnt/ewf/ewf1 /mnt/win
```

Windows 端：用 **Arsenal Image Mounter**（GUI，免费）挂成盘符。

### 批量 artifact 解析（Windows 镜像专用）

| 工具 | 用途 |
|---|---|
| `MFTECmd` | `$MFT` → CSV 时间线 |
| `EvtxECmd` | `.evtx` → CSV 事件日志 |
| `RECmd` | 注册表 hive 批量查询（有 Kroll_Batch.reb 规则库） |
| `PECmd` | Prefetch |
| `LECmd` | `.lnk` |
| `JLECmd` | Jump List |
| `SBECmd` | Shell Bag |
| `AmcacheParser` | Amcache |
| `SrumECmd` | SRUM（应用资源使用） |
| `AppCompatCacheParser` | ShimCache |

统一命令形式：
```powershell
& tool.exe -f <单个文件> --csv $OUT --csvf name.csv
& tool.exe -d <目录>    --csv $OUT --csvf name.csv   # 批量
```

### 一键超级时间线

```bash
log2timeline.py --storage-file $OUT/plaso.db $EVIDENCE
psort.py -o l2tcsv -w $OUT/timeline.csv $OUT/plaso.db
```

慢（几十分钟到几小时），但覆盖最全。

---

## 2. 内存镜像（raw / lime / vmem）

`volatility3` 是主力。没有对应 symbol table 会卡住。

```bash
vol -f $MEM windows.info                 # 识别系统版本
vol -f $MEM windows.pslist               # 进程列表
vol -f $MEM windows.pstree               # 进程树
vol -f $MEM windows.cmdline              # 进程命令行
vol -f $MEM windows.netscan              # 网络连接
vol -f $MEM windows.handles --pid N      # 句柄
vol -f $MEM windows.dlllist --pid N      # 加载的 DLL
vol -f $MEM windows.memmap --pid N --dump  # 导出进程内存
vol -f $MEM windows.filescan | rg -i 'wechat'   # 搜文件对象
vol -f $MEM windows.dumpfiles --virtaddr 0x...  # 导出特定文件
```

**微信密钥提取**（内存取证常见考题）：
- 社区工具：`PyWxDump`、`memprocfs` + `wxdb` 插件
- 原理：微信进程内存中搜 32 字节数据库密钥（pKey），特征 `pKey` 附近的指针结构
- Volatility3 插件：`wechatDecryptor`（第三方，需 clone）

---

## 3. 安卓检材

| 工具 | 用途 |
|---|---|
| `7z x` | 解压 .zip / .tar / .rar |
| `abe.jar` | `adb backup .ab` → tar |
| `aleapp` | 安卓 artifact 一键解析 → HTML + TSV |
| `sqlite3` | 读微信/QQ/短信/通讯录数据库 |
| `jadx` / `jadx-cli` | APK → Java 源码 |
| `apktool` | APK 反编译 smali + 资源 |
| `frida` | 动态 hook（需要真机/模拟器） |
| `ghidra` (headless) | so 库反汇编 → 伪 C |
| `exiftool` | 图片 EXIF（含 GPS） |

```bash
# 一键安卓解析
aleapp -t fs -i $EVIDENCE_DIR -o $OUT

# APK 反编译
jadx --output-dir $OUT/jadx $APK
apktool d $APK -o $OUT/apktool

# so 反汇编（headless）
$GHIDRA/support/analyzeHeadless $OUT ProjName \
    -import libfoo.so -postScript DecompileScript.java
```

微信数据库解密（当有 IMEI + uin 时）：
- 密钥 = `MD5(IMEI + uin)[:7]`
- 解密：`sqlcipher` + `PRAGMA key = 'xxxxxxx'`

---

## 4. Linux 服务器镜像

挂载后直接按 Linux 文件系统查：

| 目标 | 看哪里 |
|---|---|
| 系统版本 | `/etc/os-release`、`/etc/issue` |
| 内核版本 | `/boot/` 下 `vmlinuz-*`、`/lib/modules/` |
| 用户列表 | `/etc/passwd`、`/etc/shadow`（需 root） |
| 登录记录 | `last -f $ROOT/var/log/wtmp`、`/var/log/auth.log`、`/var/log/secure` |
| 命令历史 | `~/.bash_history`、`~/.zsh_history`、`/root/.*history` |
| 定时任务 | `/etc/crontab`、`/var/spool/cron/*`、`/etc/cron.*/` |
| 服务 | `/etc/systemd/system/`、`/lib/systemd/system/` |
| 网络配置 | `/etc/netplan/`、`/etc/network/`、`/etc/resolv.conf` |
| 最近安装包 | `/var/log/dpkg.log`、`/var/log/apt/history.log`、`/var/log/yum.log` |
| Redis 密码 | `/etc/redis/redis.conf` 的 `requirepass` |
| MySQL 密码 | `/etc/mysql/`、`~/.my.cnf`、`/var/lib/mysql/` |
| Nginx 配置 | `/etc/nginx/`、`/var/log/nginx/` |
| Docker | `/var/lib/docker/`、`/etc/docker/` |
| 应用代码 | `/opt/`、`/srv/`、`/home/*/`、`/var/www/` |

---

## 5. 流量包（pcap / pcapng）

| 工具 | 用途 |
|---|---|
| `capinfos` | pcap 元数据概览 |
| `tshark` | 全功能命令行 Wireshark |
| `zeek` | 协议日志化（conn/http/dns/ssl/files） |
| `NetworkMiner` | GUI 会话/文件还原 |
| `tcpflow` | 按流导出 |
| `editcap` | pcap 切片 / 转换 |

常用 tshark 片段：

```bash
capinfos $PCAP
tshark -r $PCAP -q -z io,phs              # 协议分布
tshark -r $PCAP -q -z conv,tcp            # TCP 会话统计
tshark -r $PCAP -q -z http,tree
tshark -r $PCAP -q -z dns,tree

# 导出 HTTP 对象
tshark -r $PCAP --export-objects http,$OUT/http_objs

# 按字段提取
tshark -r $PCAP -Y 'http.request.method==POST' \
    -T fields -e frame.time -e ip.src -e http.host -e http.request.uri
```

Zeek：
```bash
zeek -C -r $PCAP
# 产出 conn.log http.log dns.log files.log ssl.log weird.log notice.log
zeek-cut id.orig_h id.resp_h method host uri < http.log | sort -u
```

---

## 6. 可执行文件逆向

### .NET (PE + IL)

| 工具 | 用途 |
|---|---|
| `ilspycmd` | CLI 反编译 → C# 源码目录 |
| `dnSpy`（GUI） | 可视化反编译 + 调试 |
| `dotPeek`（GUI，JetBrains） | 反编译 + 查看类型 |
| `CFF Explorer` | PE 头 / 资源查看 |
| `de4dot` | 去混淆（ConfuserEx 等） |

```bash
ilspycmd $TARGET.exe -o $OUT/src -p
# 之后 AI 读 $OUT/src/**/*.cs
```

### Windows PE（原生）

| 工具 | 用途 |
|---|---|
| `strings` | 常量字符串、URL、IP |
| `radare2` / `rizin` | CLI 反汇编 + 简单反编译 |
| `IDA Free` / `Ghidra` | 完整逆向（GUI） |
| `pe-bear` / `pestudio` | PE 结构、导入表、签名 |
| `Detect It Easy (DiE)` | 识别编译器/打包器 |

### Java / Android

见 §3 安卓节。

### JavaScript 混淆

| 工具 | 用途 |
|---|---|
| `js-beautify` | 格式化 |
| `synchrony` | JS 去混淆器（obfuscator.io 等） |
| `node --inspect-brk` | 动态调试（谨慎，需隔离环境） |

---

## 7. 密码 / 哈希破解

| 工具 | 用途 |
|---|---|
| `hashcat` | GPU 破解各种哈希 |
| `john` (John the Ripper) | CPU 破解 + 多格式 |
| `impacket-secretsdump` | 从 SAM+SYSTEM+SECURITY 转储本地哈希 |
| `chntpw` | 查看/修改 NTUSER.DAT、SAM |
| `pypykatz` | 解析 lsass dump / mimikatz 功能纯 Python |
| `bcrypt` 爆破 | `hashcat -m 3200` |
| `bkhive` / `samdump2` | 旧式 SAM 解析 |

字典：`rockyou.txt`、`SecLists`、中文 top 字典。

```bash
# 解 NTLM
hashcat -m 1000 -a 0 hashes.txt rockyou.txt

# 解 bcrypt
hashcat -m 3200 bcrypt.txt rockyou.txt --rules best64.rule

# 解 VeraCrypt 容器（慢）
hashcat -m 13721 --veracrypt-pim N vc.bin wordlist.txt
```

---

## 8. 加密容器

| 工具 | 用途 |
|---|---|
| VeraCrypt GUI | 挂载 .hc/.tc/.vc 容器（需密码） |
| `veracrypt --text` | CLI 挂载 |
| BitLocker | `dislocker` / `libbde-utils` → `bdemount` |
| 7z 加密 | `7z x -pPASS archive.7z` |
| Office 加密 | `office2john.py x.docx > hash.txt` → hashcat -m 9600 |
| PDF 加密 | `pdf2john.py x.pdf > hash.txt` → hashcat -m 10500 |

---

## 9. 域/AD 分析

| 工具 | 用途 |
|---|---|
| `BloodHound` + `neo4j` | 图形化域关系分析 |
| `SharpHound` / `BloodHound.py` | 数据采集（出题方常已采好） |
| `ntdsutil` / `impacket-ntlmrelayx` 产物 | 域控 NTDS 哈希 |

当检材里有 `.zip` BloodHound 数据，直接导入 neo4j 后用预制 query：
- "Who controls Domain Admins"
- "Shortest path from X to Domain Admins"
- "Find sessions from users with local admin"

Cypher 示例：
```cypher
MATCH p=shortestPath((u:User {name:'ZHANGXIN@XIAORANG.LAB'})-[*1..]->(n {name:'XIAORANG.LAB'})) RETURN p
```

---

## 10. 火眼 / 盘古石系列（商业 GUI）

**定位**：人类操作员的键盘鼠标，不走 CLI。AI 用不了。

**AI 能消费的产物**：
- 导出的 SQLite 数据库（微信/QQ/短信/通话/位置 已脱密）
- 导出的文件（原始 docx/pdf/jpg/mp4）
- 导出的 HTML / CSV / JSON 报告

**AI 该对人说的话**：
> "请在火眼证据分析里加载镜像，定位到 `<模块>`，右键导出为 CSV/JSON，把导出目录告诉我。"

不要假设能读 `.ecase` / `.ecfx` / `.evidence` 专有格式。
