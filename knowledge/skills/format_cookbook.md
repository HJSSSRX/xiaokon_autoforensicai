# 取证文件格式速查 cookbook

> **作用**：遇到不明二进制时，**先按 magic 识别 → 选对解析器**。不要先信扩展名。
> **使用**：与 `TRIAGE_DSL_v1.md` SIG 字段一一对应。

---

## §1 Magic Number 速查

```
D0 CF 11 E0 A1 B1 1A E1   OLE/CFB     → doc xls ppt msi msg wps et
50 4B 03 04                ZIP         → docx xlsx pptx jar apk odt epub ipa
50 4B 05 06 / 50 4B 07 08  ZIP empty/spanned
7F 45 4C 46                ELF         → linux 可执行
4D 5A                      PE          → Windows .exe .dll .sys (后续 PE\0\0)
FE ED FA CE / FE ED FA CF  Mach-O      → macOS 32/64 bit
CA FE BA BE                Java class / Mach-O FAT
25 50 44 46 2D             PDF         → "%PDF-"
89 50 4E 47 0D 0A 1A 0A    PNG
FF D8 FF E0/E1/DB          JPEG (JFIF/EXIF)
47 49 46 38 37/39 61       GIF87a/89a
42 4D                      BMP
49 49 2A 00 / 4D 4D 00 2A  TIFF (LE/BE)
52 49 46 46 ?? ?? ?? ?? 57 41 56 45  WAV (RIFF...WAVE)
52 49 46 46 ?? ?? ?? ?? 41 56 49 20  AVI
52 49 46 46 ?? ?? ?? ?? 57 45 42 50  WEBP
1A 45 DF A3                MKV / WebM (EBML)
00 00 00 ?? 66 74 79 70    MP4 / MOV (ftyp box)
ID3 / FF FB                MP3
66 4C 61 43                FLAC
4F 67 67 53                Ogg
1F 8B 08                   gzip
42 5A 68                   bzip2
FD 37 7A 58 5A 00          xz
37 7A BC AF 27 1C          7z
28 B5 2F FD                zstd
75 73 74 61 72             tar (POSIX)
53 51 4C 69 74 65 20 66 6F 72 6D 61 74 20 33 00  SQLite 3
4C 4F 47                   leveldb LOG
"bplist00"                 binary plist
"<?xml"                    XML / plist (text)
"redis"                    redis dump
00 06 15 61 00 00 00 02    PCAP/PCAPng (Magic 不固定)
"PCAP"                     pcap variant
"conectix"                 VHD footer (last 512 bytes)
"vhdxfile"                 VHDX
4C 55 4B 53 BA BE          LUKS1
"-FVE-FS-"                 BitLocker
"VeraCrypt" 不存在 magic     VeraCrypt (头 64KB 高熵+不可读)
ED AB EE DB                RPM
"!<arch>"                  ar / .deb (内含 control.tar + data.tar)
```

---

## §2 OLE/CFB（Office .doc/.xls/.ppt/.msg + WPS .wps/.et）

```python
import olefile
ole = olefile.OleFileIO('保险箱.et')
print(ole.listdir())
# [['Workbook'], ['SummaryInformation'], ['DocumentSummaryInformation'], ...]
data = ole.openstream('Workbook').read()
```

关键 Stream：
- `Workbook` / `Book` — Excel/.et 主数据流（含 BOF 记录）
- `WordDocument` — Word 主流
- `PowerPoint Document` — PPT 主流
- `\x05SummaryInformation` — 标题/作者/创建时间元数据
- `\x05DocumentSummaryInformation` — 公司/类别等
- `Macros/VBA/_VBA_PROJECT` — VBA 宏
- `ObjectPool/_NN/Package` — 嵌入文件 (OLE Object)
- `Pictures` — 嵌入图片

工具：`olevba`, `oletools.olemeta`, `oleobj`, `oleid`, `rtfobj`

**WPS 特有**：`Workbook` 流末段含 Shape 记录，`Shape.AlternativeText` 字段被 utf-16le 数字串占用 → 可能是字模点阵隐写（**2026FIC Q10**）。

---

## §3 OOXML（.docx / .xlsx / .pptx）

是 ZIP 包。`unzip -l` 看结构：

```
[Content_Types].xml                MIME 映射
_rels/.rels                        根关系
docProps/app.xml                   应用元数据
docProps/core.xml                  核心元数据 (作者/时间)
docProps/custom.xml                自定义属性 ★（藏数据点）
word/document.xml                  Word 主内容
word/_rels/document.xml.rels       文档关系
xl/workbook.xml + xl/worksheets/sheetN.xml   Excel
ppt/slides/slideN.xml              PPT 幻灯
**/embeddings/oleObject*.bin       嵌入 OLE
**/media/image*.png                嵌入图片
word/vbaProject.bin                VBA 宏（OLE 子格式）
customXml/                         自定义 XML 部件 ★
```

工具：`unzip` / `oletools` / `python-docx` / `openpyxl` / `python-pptx`

---

## §4 ELF (Linux 可执行)

```bash
file <bin>                                       # 看 arch / endian / static-dynamic
readelf -h <bin>                                 # ELF header
readelf -S <bin>                                 # sections
readelf -d <bin>                                 # dynamic
ldd <bin>                                        # 依赖
strings -a -n 8 <bin> | head -200                # 字符串
objdump -d <bin> | less                          # 反汇编
nm -D <bin>                                      # 动态符号
```

### Go 语言识别（重要）

```bash
strings <bin> | grep -E '^Go build ID:|^go1\.|runtime\.[a-z]'
go version <bin>                                 # 直接输出 go1.X.Y
```

Go 程序特征：
- 有 `runtime.*` 大量符号
- 字符串拼接常以 **小端 64-bit 整数 qmemcpy** 形式硬编码：`*(_QWORD *)v4 = 0xAFE886AFE5A3A7E8LL;` → 转 UTF-8 看 ASCII
- 函数命名 `main_main` `main_xxx` `pkg_func`
- 反编译用 **IDA 9.x + golang_loader_assist 插件** 或 `redress` `go-decompile`

适用：**2026FIC Q8** `get_token_linux` 即 Go 程序，main_main 含硬编码邮箱。

### Rust 识别

```bash
strings <bin> | grep -E 'rust_panic|core::panic|alloc::|std::'
```

### 静态 vs 动态

```bash
file <bin> | grep -E 'statically|dynamically'
# 静态链接的 Go/Rust 只能反编译，不能 LD_PRELOAD hook
```

---

## §5 PE (Windows 可执行)

```bash
file <bin>                                       # PE32+ / PE32
pefile <bin>                                     # python pefile
strings -e l <bin>                               # UTF-16LE 字符串 (Win 内部)
strings -a <bin>                                 # ASCII
exiftool <bin>                                   # 编译时间 / 公司名
sigcheck <bin>                                   # 签名 (Sysinternals)
PEview <bin> / CFF Explorer                      # GUI
```

关键查看点：
- TimeDateStamp（编译时间，可能造假）
- Imports 表（调用了哪些 API → 行为推断）
- Exports 表（DLL 导出）
- Resources（图标、版本信息、字符串表、对话框）
- Overlay（PE 末尾追加数据 — 安装包/隐写常用）
- Sections 名（异常名如 `.upx0` 暗示加壳）

加壳/混淆识别：
- UPX → `upx -d` 直接脱
- VMProtect / Themida → 重活
- .NET → ILSpy / dnSpy / dotPeek

---

## §6 SQLite (取证最重要的格式之一)

```bash
sqlite3 <db>
.tables                                # 列表
.schema <table>                        # 建表语句
.dump > out.sql                        # 全 dump
.mode csv
.output data.csv
SELECT * FROM <table>;
```

### WAL / SHM 文件

`<db>` `<db>-wal` `<db>-shm` **三个一起拷**，否则 WAL 中未提交事务会丢。

### 已删除记录恢复

SQLite 不立即覆盖删除的行；用以下工具恢复：
- `undark` / `sqlite_deleted_records_parser`
- `bring2lite`
- `sqlite-deleted-records-parser`

### 加密 SQLite (sqlcipher)

```bash
sqlcipher <db>
PRAGMA key = '<password>';
.schema
```

WeChat / Signal / 多个聊天软件都用 sqlcipher。

---

## §7 LevelDB (Chrome / Electron 应用)

目录里有 `LOG`, `MANIFEST-*`, `*.ldb`, `CURRENT`, `LOCK`：

```python
import plyvel
db = plyvel.DB('./Local Storage/leveldb', create_if_missing=False)
for k, v in db:
    print(k, v[:200])
```

适用：浏览器 Local Storage、IndexedDB（部分实现）、Electron 应用配置（Discord, VSCode, Atom, Lark 等）

---

## §8 Plist (macOS / iOS)

```bash
file Info.plist                                  # 看是 binary 还是 XML
plutil -convert xml1 -o - Info.plist             # 转 XML
plistutil -i input.bplist -o output.xml         # Linux 替代
```

Python: `plistlib`

---

## §9 MP4 / MOV (ISO BMFF)

box 结构（递归嵌套）：

```
ftyp     File Type
moov     Movie metadata
  mvhd   Movie header (duration / time)
  trak   Track
    tkhd Track header
    mdia
      mdhd
      hdlr
      minf
        stbl  Sample Table
          stsd  Sample Description
          stts  Time-to-Sample
          stsc  Sample-to-Chunk
          stsz  Sample Size
          stco  Chunk Offset 32-bit  ★ (隐写常见点)
          co64  Chunk Offset 64-bit  ★
udta     User Data (元数据 / 自定义 atom 藏数据)
mdat     Media Data (帧 raw 数据)
```

工具：
- `ffprobe -show_streams -show_format <mp4>`
- `mp4info` / `MP4Box -info`
- `bento4` 套件 (`mp4dump`, `mp4extract`)
- 自写 atom walker（30 行 Python）

适用：**2026FIC Q9** mp4 stco 偏移 +1337 隐写。

---

## §10 Email (.eml / .msg / mbox)

```python
# .eml (RFC 822)
import email
msg = email.message_from_bytes(open('a.eml','rb').read())
print(msg['From'], msg['Subject'])
for part in msg.walk():
    print(part.get_content_type(), part.get_filename())

# .msg (Outlook OLE)
import extract_msg
m = extract_msg.Message('a.msg')
print(m.sender, m.subject, m.body)
```

特殊：
- **deepin-mail** 邮件以 UUID 命名（`<uuid>.eml`），元信息在 sqlite
- **Foxmail** 邮件在 `Storage/<account>/Boxes/*.box` 内（自定义索引格式）
- **Thunderbird** mbox 格式（无 .eml，全在 `Inbox` 单文件）

---

## §11 Browser History / Cookies / LoginData

```bash
# Chromium 系 (Chrome / Edge / Brave / deepin-browser)
sqlite3 'History' "SELECT datetime(last_visit_time/1000000-11644473600,'unixepoch','localtime'), url, title FROM urls ORDER BY last_visit_time DESC LIMIT 50"

# Firefox
sqlite3 places.sqlite "SELECT datetime(visit_date/1000000,'unixepoch','localtime'), url, title FROM moz_places mp JOIN moz_historyvisits mh ON mh.place_id=mp.id ORDER BY visit_date DESC LIMIT 50"
```

时间戳坑：
- Chromium: webkit 时间戳（自 1601-01-01 微秒）→ `t/1000000 - 11644473600`
- Firefox: unix 微秒 → `t/1000000`
- WebKit (Safari): NSDate（自 2001-01-01 秒）→ `t + 978307200`

Login Data 解密：
- Linux: 主密码在 `~/.local/share/keyrings` (libsecret) 或 plain
- macOS: Keychain (`security find-generic-password`)
- Windows: DPAPI (用户登录密码作为 master key)

---

## §12 取证镜像格式

| 格式 | 工具 | 备注 |
|---|---|---|
| **E01** (EnCase) | `ewfmount` + `losetup -P` | 默认只读 |
| **AFF / AFF4** | `aff4-tools` | 较少见 |
| **dd / raw** | `losetup -P` 直接挂 | 需配合 `mmls` 看分区 |
| **VHD/VHDX** | `qemu-nbd` 或 `vboxmanage` | Windows 原生 mount |
| **VMDK** | `vmware-vdiskmanager` / `qemu-nbd` | |
| **DD over SMB** | `mount -o loop,offset=...` | |

### E01 挂载一键命令

```bash
sudo ewfmount image.E01 /mnt/ewf
# /mnt/ewf/ewf1 是 raw image，再用 mmls / losetup 处理分区
sudo mmls /mnt/ewf/ewf1
sudo losetup -P --read-only /dev/loop10 /mnt/ewf/ewf1
sudo mount -o ro /dev/loop10p4 /mnt/case_p4
```

---

## §13 反模式提醒

- ❌ 看扩展名判断格式 — 必看 magic
- ❌ 用记事本看二进制 — 必用 hex 编辑器（HxD / xxd / 010 Editor）
- ❌ 拆 .docx/.xlsx 只看 `document.xml` — 必看 `customXml/` `embeddings/` `_rels/`
- ❌ 默认 Office 文件没宏 — 必跑 `olevba`
- ❌ 看 ELF 直接 ghidra — 先 `file` + `strings | head` 判断语言（Go/Rust/C/C++）后选工具
- ❌ 拷 sqlite 不带 `-wal` `-shm` — WAL 中可能有未提交关键证据
- ❌ Browser History 看到空表就放弃 — 还有 `Top Sites` `Visited Links` `Favicons` `Login Data` `Web Data`
