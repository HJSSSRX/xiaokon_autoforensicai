# Binary Forensics & Reverse Engineering — Quick Reference

tags: binary, reverse, pe, veracrypt, vc, hashcat, ghidra, radare2, upx, rc4, aes

---

## 一、快速判断加密类型 (第一步必做)

### DIE (Detect It Easy) 速查
```powershell
# 鉴定 PE 类型/编译器/壳
die SampleVC.exe
# 关注: TrueCrypt/VeraCrypt magic bytes, UPX packer, MSVC/MinGW 编译器
```

### 特征字符串快速判断
```powershell
strings -n 8 SampleVC.exe | grep -iE "TrueCrypt|VeraCrypt|VERA|TRUE|AES|RC4|XOR|SHA|password|密码|key"
```

**判断树**:
- 输出含 `TrueCrypt`/`VeraCrypt` → **标准 VeraCrypt 容器** → 用 hashcat 暴破, 不逆向
- 输出含 `RC4`/`AES`/`XOR` 但无 TC/VC magic → **自定义加密** → 逆向 main()
- 文件头 `VERA`/`TRUE` → VeraCrypt → hashcat
- 文件大小 = 1MB 整数倍 → VeraCrypt (容器通常对齐)

---

## 二、VeraCrypt 容器暴破 (hashcat)

```powershell
# hashcat 路径 (本机)
$hc = "D:\CTF\hashcat-7.1.2\hashcat-7.1.2\hashcat.exe"
$wl = "D:\CTF\hashcat-7.1.2\hashcat-7.1.2\rockyou.txt"

# 模式选择 (根据 VeraCrypt 加密设置):
# -m 13711 = VeraCrypt RIPEMD-160 + AES (常见)
# -m 13721 = VeraCrypt SHA-512 + AES
# -m 13722 = VeraCrypt Whirlpool + AES
# -m 13731 = VeraCrypt RIPEMD-160 + Serpent
# 比赛默认先试 13711 和 13721

& $hc -m 13711 vc $wl --force -O
& $hc -m 13721 vc $wl --force -O

# 已知密码格式 (如 16 字符): 先生成专用字典
# 16 字符 ASCII 全组合太大, 但比赛密码通常来自备忘录/KeePass/PE 字符串里
```

### VeraCrypt 容器挂载验证
```powershell
# Windows 命令行挂载 (需安装 VeraCrypt)
veracrypt --mount "E:\vc" /v: --password="PASSWORD" --keyfiles= --pim=0

# 或者 WSL:
veracrypt --text --mount /mnt/e/vc /mnt/vc --password=PASSWORD --keyfiles= --pim=0 --protect-hidden=no
```

---

## 三、PE 文件分析

### PE 头读取 (Python)
```python
import pefile, datetime, hashlib

pe = pefile.PE("SampleVC.exe")

# Q1: MD5
md5 = hashlib.md5(open("SampleVC.exe","rb").read()).hexdigest()
print("MD5:", md5)

# Q2: 编译时间戳
ts = pe.FILE_HEADER.TimeDateStamp
dt = datetime.datetime.utcfromtimestamp(ts)
print("Compile:", dt.strftime("%Y-%m-%d"))  # 答案格式: yyyy-mm-dd

# 其他元数据
print("Machine:", hex(pe.FILE_HEADER.Machine))  # 0x8664=x64, 0x14c=x86
print("Sections:", [s.Name.decode().rstrip('\x00') for s in pe.sections])
```

### 也可用 exiftool
```powershell
exiftool SampleVC.exe
# 看 TimeStamp, MachineType, LinkerVersion, CompanyName 等
```

---

## 四、逆向分析 (自定义加密时用)

### Ghidra 快速定位密码验证逻辑
1. File → Import File → SampleVC.exe → Analyze
2. Functions 窗口搜索 `main` / `WinMain` / `wmain`
3. 找到比较函数: `strcmp` / `memcmp` / 自定义 hash
4. 关注 `scanf` / `gets` 后面的第一个 `cmp` 指令

### radare2 命令行逆向
```bash
r2 -A SampleVC.exe
# aa            # 分析所有函数
# afl           # 列函数列表
# pdf @ main    # 反汇编 main
# iz            # 提取所有字符串 (可能有硬编码密码)
# /c strcmp     # 搜索 strcmp 调用
```

### UPX 脱壳
```powershell
upx -d SampleVC.exe -o SampleVC_unpacked.exe
# 如果 die 显示 UPX packer, 必须先脱壳再分析
```

---

## 五、从 E01 提取文件

```powershell
# 1. 看分区
mmls "E:\检材4-U盘.E01"
# 输出: 偏移量 (sectors) + 分区大小

# 2. 列文件 (假设偏移 2048 sectors, 扇区 512B)
fls -r -o 2048 "E:\检材4-U盘.E01"

# 3. 提取指定文件 (inode 号从 fls 输出里找)
icat -o 2048 "E:\检材4-U盘.E01" <inode> > SampleVC.exe
icat -o 2048 "E:\检材4-U盘.E01" <inode> > vc

# Python 一键读取 (不需要 inode):
# pip install dissect.target dissect.ewf
```

```python
from dissect.target import Target
t = Target.open(r"E:\检材4-U盘.E01")
for f in t.fs.path("/").rglob("*"):
    if f.is_file():
        print(f.path)
        # f.open().read() 读文件内容
```

---

## 六、经验铁律

> **错因 1** (2026FIC): 误判 VeraCrypt 容器为自定义 RC4-VHD → 浪费 6 小时逆向
> 铁律: **先用 DIE + strings 判断, 再决定逆向还是暴破**

> **错因 2**: 拿到密码候选后没有快速验证 → 不知道是否正确
> 铁律: **每次有新候选密码, 先 VeraCrypt mount 快速验证 (30 秒), 再继续暴破**

> **线索来源**: 比赛 vc 密码经常藏在:
> 1. mobile 角色的备忘录 (com.miui.notes 里有奇怪的 16 字符字符串)
> 2. 计算机桌面/文档里的 txt/Excel 文件
> 3. PE 字符串里 (strings SampleVC.exe 全量扫)
> 4. 服务器配置文件里的 password 字段

---

## 七、答案格式速查 (binary_forensics)

| 题目类型 | 标准格式 | 例子 |
|---|---|---|
| MD5 | 32 hex 小写 | `c4ca4238a0b923820dcc509a6f75849b` |
| 编译日期 | yyyy-mm-dd | `2025-06-06` |
| 密码 | 原文字符串 | `MyP@ssw0rd!2026` |
| 文件后缀 | 纯扩展名, 不含点 | `vhd` |
| 收款总金额 | 浮点 2 位小数 | `1.00` |
