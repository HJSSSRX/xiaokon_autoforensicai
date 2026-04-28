# Playbook · 内存取证

## 0. 识别

```bash
vol -f $MEM windows.info         # 系统版本、时间、架构
# 没有 volatility3 symbol 会报错，需要下载对应 PDB 构建 ISF
```

如果 `windows.info` 挂了，先装 symbol：
```bash
cd ~/.local/lib/python*/site-packages/volatility3/symbols/
git clone https://github.com/volatilityfoundation/volatility3
# 或从 MS 下 PDB 自行生成
```

---

## 1. 基础进程分析

```bash
vol -f $MEM windows.pslist         # 活进程
vol -f $MEM windows.psscan         # 含已退出（扫 EPROCESS 结构）
vol -f $MEM windows.pstree         # 父子关系
vol -f $MEM windows.cmdline        # 每个进程的命令行
vol -f $MEM windows.getsids        # 进程所属用户 SID
```

### 判题模式
- "某程序的 PID / 创建时间"
- "可疑进程"（父进程异常、命令行带 base64、从 `%TEMP%` 启动）
- "木马/后门进程 PID"

### 找木马套路

```bash
# 1. 看 pstree，找父进程异常的（explorer.exe 生出 cmd.exe 合理，cmd.exe 生出 powershell.exe 可疑）
vol -f $MEM windows.pstree > $OUT/pstree.txt

# 2. 命令行里有可疑关键字
vol -f $MEM windows.cmdline | rg -i 'base64|iex|downloadstring|tmp|appdata|powershell.*-enc'

# 3. 没签名 / 不在标准路径的进程
vol -f $MEM windows.pslist | rg -v 'Windows\\System32|Program Files'
```

---

## 2. 网络连接

```bash
vol -f $MEM windows.netscan        # 所有网络连接（含已关闭）
vol -f $MEM windows.netstat        # 活动连接（较新 Windows 需要 symbol）
```

**C2 识别**：
- 外联到非国内正常 IP 的高端口
- PID 对应进程路径可疑
- 持久化在 `%APPDATA%` / `%TEMP%`

---

## 3. 句柄 / DLL / 文件

```bash
vol -f $MEM windows.handles --pid $PID | rg -i 'key|file|mutex'
vol -f $MEM windows.dlllist --pid $PID
vol -f $MEM windows.filescan | rg -i 'wechat|msg|key'
vol -f $MEM windows.dumpfiles --virtaddr $ADDR -o $OUT    # 导出文件对象
```

---

## 4. 进程内存导出（关键能力）

```bash
# 导出进程完整内存（可能几百 MB）
vol -f $MEM windows.memmap --pid $PID --dump -o $OUT

# 导出特定地址区域
vol -f $MEM windows.vadinfo --pid $PID       # 先看 VAD 区域表
# 然后 dd 切片或用脚本提取
```

导出后可用：
- `strings -n 8 | rg 模式` 搜关键字
- `hex` 搜特定字节序列
- 专用工具（PyWxDump 等）

---

## 5. 微信 PC 密钥提取（平航杯高频）

### 原理
微信 PC 进程 `WeChat.exe` 内存里保存数据库解密用的 32 字节密钥（pKey），在堆上。

### 工具

**PyWxDump**（推荐）：
```bash
git clone https://github.com/xaoyaoo/PyWxDump
cd PyWxDump
pip install -e .
wxdump bias --mobile $MOBILE --name $NAME --account $ACCOUNT \
            --key $KEY --wxdb $WXDB  # 离线模式取 bias
# 或：
wxdump mem --mem $MEM
```

**手动原理**（当 PyWxDump 跑不起来时）：
1. 在 `WeChat.exe` 进程内存里搜 32 字节密钥。特征：
   - 密钥地址附近常有指向微信账号结构的指针
   - 用微信数据库头 16 字节反推：SQLCipher 数据库以盐值+HMAC 结构开始
2. 把候选 32 字节拿去试解 `MSG0.db`：
```python
# pysqlcipher3 尝试
import pysqlcipher3.dbapi2 as sq
conn = sq.connect('MSG0.db')
conn.execute(f"PRAGMA key = \"x'{key.hex()}'\"")
conn.execute("PRAGMA cipher_page_size = 4096")
conn.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA1")
conn.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1")
conn.execute("PRAGMA kdf_iter = 64000")
cur = conn.execute("SELECT name FROM sqlite_master")
cur.fetchone()  # 成功 = 对
```

### 判题模式
- "持有微信密钥的进程 PID" → `vol windows.pslist | rg -i wechat`
- "微信数据库密钥" → PyWxDump 或手动提取
- "某聊天记录内容" → 解密 MSG*.db → SQL 查询

---

## 6. 恶意软件分析

```bash
# 注入检测（恶意代码典型特征）
vol -f $MEM windows.malfind

# 服务
vol -f $MEM windows.svcscan

# 注册表 hive（从内存重建）
vol -f $MEM windows.hivelist
vol -f $MEM windows.printkey --offset $HIVE_OFFSET --key 'Software\Microsoft\Windows\CurrentVersion\Run'

# 检测 hook
vol -f $MEM windows.ssdt
```

### 找内存里的 C2 IP

```bash
# 1. 找可疑进程
vol -f $MEM windows.netscan | rg -v '127\.|0\.0\.0\.0|::1'

# 2. 如果连接已断开，从进程内存 dump 中搜 IP
vol -f $MEM windows.memmap --pid $PID --dump -o $OUT
rg -o -a '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' $OUT/pid.${PID}.dmp | sort -u
```

---

## 7. 时间线

```bash
vol -f $MEM timeliner.Timeliner > $OUT/mem_timeline.txt
```

---

## 8. 常见坑

- **symbol table 缺失**：对中国用户常见的是 Windows 10 中文版某些 build，需自行生成 PDB→ISF
- **vol2 vs vol3**：老的 profile 系统（vol2）和新的 symbol 系统（vol3）不兼容。现在只用 vol3
- **WSL 跑 vol3 OK**，Windows 原生也 OK，但依赖 pycryptodome 等
- **内存镜像格式**：`.raw` / `.mem` / `.vmem` / `.dmp`（Windows crash dump） / hiberfil.sys。前面这些 vol3 直接吃，hiberfil 要先 `volatility windows.hibernation_convert`
- 微信密钥**不在 WeChatWin.dll 里**，在堆内存，每次登录重新生成
