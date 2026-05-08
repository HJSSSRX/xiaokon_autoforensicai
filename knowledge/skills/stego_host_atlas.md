# 隐写宿主全景图谱

> **作用**：题面出现"加密""隐藏""不可见""异常"等词时，对照本表快速定位**载体类型 → 编码方式 → 解码工具**。
> **维护**：每发现一种新隐写手法回填一条。
> **使用**：与 `TRIAGE_DSL_v1.md` `STEGO <method>` 动作动词对应。

---

## 索引

- [§1 视频/音频](#1-视频音频)
- [§2 图像](#2-图像)
- [§3 Office / WPS](#3-office--wps)
- [§4 PDF](#4-pdf)
- [§5 压缩包](#5-压缩包)
- [§6 文本/源代码](#6-文本源代码)
- [§7 文件系统/磁盘层](#7-文件系统磁盘层)
- [§8 网络/协议层](#8-网络协议层)
- [§9 区块链/链上](#9-区块链链上)
- [§10 通用解码动作清单](#10-通用解码动作清单)

---

## §1 视频/音频

| 载体 | 隐写位 | 编码方式 | 解码 | 案例 |
|---|---|---|---|---|
| **MP4** | `stco` / `co64` chunk-offset 表 | 每个 offset ± 常数 (如 +1337) | 找 `stco` magic, 解出表后批量减常数 | **2026FIC Q9** |
| MP4 | `mvhd` `tkhd` 时间字段 | 时间戳 LSB | 读 `creation_time` `modification_time` | — |
| MP4 | `udta` / `meta` box | 自定义 atom 内嵌数据 | atom walker | — |
| MP4 | 帧间隔 / B-frame 数量 | 帧序列编码比特 | demux + 帧分析 | — |
| MOV/M4A | 同 MP4（共享 atom 结构） | 同 | 同 | — |
| AVI | `JUNK` chunk 内嵌 | RIFF chunk 自定义 | RIFF parser | — |
| MKV | tag / attachment | EBML 自定义 element | mkvextract | — |
| WAV | LSB | 每 sample 最低位 | wavsteg / steghide | CTF 常见 |
| MP3 | 帧 padding / ID3 tag | tag 自定义 frame | mutagen + 自定义 parser | — |
| FLAC | metadata block 7 (Picture) 边界 | 自定义 padding | metaflac | — |
| Opus | 帧 padding | LSB | opus-tools | — |

## §2 图像

| 载体 | 隐写位 | 编码方式 | 解码 |
|---|---|---|---|
| **PNG** | tEXt / zTXt / iTXt chunk | 自定义文本块 | `pngcheck -t` / `exiftool` |
| PNG | LSB (RGB / RGBA) | 每像素最低 1-3 位 | zsteg / stegsolve / lsb-extract.py |
| PNG | IDAT 后追加数据 | 文件末尾粘贴 | `binwalk -e` / `dd skip=...` |
| PNG | IHDR 异常宽高 | 改 IHDR 隐藏画面 | 修复 IHDR + 校验 CRC |
| **JPEG** | EXIF Comment / Maker Note | tag 自定义 | exiftool |
| JPEG | DCT 系数 LSB | 频域隐写 | F5 / OutGuess / steghide |
| JPEG | EOF 后追加数据 | append after FFD9 | binwalk / xxd 找 FFD9 |
| GIF | 帧间隔 / 注释扩展 | 帧延迟编码 | identify / 自定义 parser |
| BMP | LSB | 同 PNG LSB | stegsolve |
| WEBP | RIFF 自定义 chunk | 同 AVI | webpinfo |
| TIFF | 私有 IFD | tag 自定义 | exiftool |
| SVG | 注释 / `<metadata>` | 文本注入 | grep + xmllint |
| HEIC/HEIF | metadata box | 同 MP4 atom | exiftool |

## §3 Office / WPS

| 载体 | 隐写位 | 编码方式 | 解码 | 案例 |
|---|---|---|---|---|
| **WPS .et** | `Shape.AlternativeText` | UTF-16LE 数字串 → 字模点阵 → ASCII | OLE 解析 + 公式 `((x+B)^K)*M+((y+B)^K)` 反求 | **2026FIC Q10** |
| .docx / .xlsx / .pptx | 内含 `customXml/` | XML 自定义 | `unzip + xmllint` |
| Office | `vbaProject.bin` 宏 | 隐藏宏代码 | `oletools::olevba` |
| Office | 修订记录 / 注释 | 历史版本残留 | `oletools::olemeta` |
| Office | 嵌入对象 (OLE / Package) | 内嵌文件 | `oletools::oleobj` |
| Office | `docProps/custom.xml` | 自定义属性 | unzip |
| .doc/.xls/.ppt (老 OLE) | Workbook / WordDocument 流后段 padding | OLE FAT chain padding | `olefile` |
| .doc | "格式藏字" (黑底黑字) | 字色与背景同 | 转 txt 即现 |

## §4 PDF

| 隐写位 | 编码方式 | 解码 |
|---|---|---|
| Stream filter chain | 多重 filter | qpdf --qdf |
| 删除对象 (xref) | 引用未删 | qpdf / mupdf |
| Incremental updates | 历史版本未清 | mutool clean |
| 字体 ToUnicode CMap | unicode map 扰乱 | pdfminer |
| Form 字段 hidden | 不可见表单 | pdftk dump_data |
| 文档级 Names tree | 嵌入文件 | pdftk unpack_files |
| Annot 注释颜色匹配背景 | 注释藏字 | pdfminer 抓所有 annot |

## §5 压缩包

| 载体 | 隐写位 | 编码 | 解码 |
|---|---|---|---|
| ZIP | 注释 (EOCD) | 文件末尾自定义文本 | `zipnote` / `unzip -z` |
| ZIP | 多卷拼接尾部数据 | append after EOCD | `binwalk -e` / `dd` |
| ZIP | 假加密 (general purpose bit 0x01 置位但未真正加密) | 改 bit 即可看 | hex 编辑器 |
| ZIP | 已知明文攻击 (有同压缩格式同名文件) | bkcrack | bkcrack 工具 |
| 7z | header.bin attribute | 自定义 attr | 7z l -slt |
| RAR | comment / recovery record | rar 注释 | rar v |
| TAR | extended header (PAX) | 自定义键值 | bsdtar |

## §6 文本/源代码

| 载体 | 隐写位 | 编码 | 解码 |
|---|---|---|---|
| 任意文本 | 零宽字符 (U+200B/200C/200D/FEFF) | 不可见字符编码比特 | unicode-range filter |
| 任意文本 | 行尾 trailing 空格 | 空格/Tab 二进制 | `cat -A` 看 `$` 前空格 |
| 任意文本 | 标点全角/半角混用 | 字符切换编码 | unicode normalize 对比 |
| HTML/CSS | 注释 `<!--...-->` | 注释藏字 | grep `<!--` |
| HTML | display:none / 字色匹配背景 | DOM 隐藏 | 浏览器开发者工具 |
| JS | unicode escape `\u200b` | 同上 | 反序列化 |
| JS | 混淆变量名表 / packed | 自动反混淆 | de4js / synchrony |
| 源代码 | 注释中的 base64/hex | 长字符串 | grep 高熵字符串 |
| Markdown | 隐藏链接 `[text](url)` | url 编码 | grep `]\(` |

## §7 文件系统 / 磁盘层

| 载体 | 隐写位 | 编码 | 解码 |
|---|---|---|---|
| NTFS | ADS (Alternate Data Stream) | `file.txt:hidden` | `dir /R` (Win) / `getfattr` |
| NTFS | $LogFile / $UsnJrnl | journal 残留 | UsnJrnl2csv / fls -r |
| ext4 | journal | journal 残留 | extundelete / debugfs |
| ext4 | inode 末尾 reserved | xattr | `getfattr -d` |
| FAT | slack space (cluster 末尾) | 文件长度 < cluster size 的剩余 | dd + carving |
| 任意 | 文件 slack | 同上 | bulk_extractor |
| 任意 | 已删除 inode (未覆盖) | unlink 后扇区残留 | photorec / scalpel / foremost |
| LUKS | header keyslot 1-7 | 多密码槽 | cryptsetup luksDump |
| BitLocker | recovery key 文件 | 文本 / Key Package | dislocker |
| **VHD** | footer (末 512B "conectix") | container metadata | qemu-img info |
| **VeraCrypt** | 隐藏卷 (hidden volume) | 双密码空间 | tcplay / VeraCrypt |
| **VeraCrypt** | 全文件高熵 + 头 64KB 不可读 | header 加密 | **火眼会自动提示** |

## §8 网络/协议层

| 载体 | 隐写位 | 编码 | 解码 |
|---|---|---|---|
| TCP | sequence number / ISN | LSB | wireshark + 自定义 |
| ICMP | echo data payload | 自定义 payload | tcpdump |
| DNS | TXT / NULL 记录 | base32/hex 子域名 | dnscat / grep TXT |
| HTTP | Header (X-* 自定义) | 头藏数据 | mitmproxy |
| HTTPS | TLS SNI / ALPN | 域名编码 | sslsplit |
| TLS | session ticket | 票据数据 | wireshark |

## §9 区块链 / 链上

| 载体 | 隐写位 | 编码 | 解码 |
|---|---|---|---|
| BTC | OP_RETURN | 80 字节任意数据 | blockchain.com 查 OP_RETURN |
| ETH | input data (calldata) | 任意 hex | etherscan + abi 解码 |
| BTC | sigscript / scriptPubKey nonstandard | 假交易藏数据 | 自定义脚本解析 |
| NFT | metadata IPFS | json 自定义 | ipfs.io 网关 |

## §10 通用解码动作清单

任何不明二进制先依次跑：

```bash
file <X>                                  # magic
exiftool <X>                              # 元数据
strings -a -n 8 <X> | head -200           # 长字符串
binwalk -e <X>                            # 嵌入文件
foremost -i <X> -o out                    # carving
xxd <X> | head; xxd <X> | tail            # 头尾
hashdump <X>                              # md5/sha1/sha256
ent <X>                                   # entropy (>7.5 暗示加密)
zsteg <X>                                 # PNG/BMP LSB (Ruby)
steghide info <X>                         # JPEG/WAV/BMP
stegsolve <X>                             # GUI 多通道查看
```

## §11 触发关键词 → 推荐宿主

| 题面词 / 现象 | 优先猜测 |
|---|---|
| "保险柜密码" "隐藏密码" + 文档 | §3 WPS Shape AltText / Office 黑底黑字 |
| "视频被加密 / 打不开" | §1 mp4 stco 偏移 / 帧打乱 |
| "图片有蹊跷" | §2 PNG LSB / EXIF / 末尾追加 |
| "压缩包打不开 / 提示密码" | §5 假加密 / 已知明文 / 注释 |
| "聊天记录消失" | §10(WeChat/QQ/Telegram) sqlcipher 解密 |
| "邮件附件可疑" | §6 零宽 / §3 docx 宏 / §4 PDF embedded |
| "文件名诡异" / 无后缀 | §10 binwalk + magic 识别 |
| "数据高熵" entropy>7.5 | §7 加密容器 / §10 binwalk |
| 文档大小异常大 | §5 末尾追加 / §3 嵌入对象 |

---

## 反模式提醒

- ❌ 看到 `.mp4` 默认它是视频 — 大量比赛会把 mp4 当容器
- ❌ 用 `unzip` 解 docx 后只看 `word/document.xml` — 忽略 `customXml/` `embeddings/`
- ❌ 用图片预览器看 PNG — LSB 完全看不出，必须 stegsolve
- ❌ 看到 entropy 高就只想 AES — 可能是 zip / pdf / 已压缩流
- ❌ 看到 `.et` 扩展名认为是 WPS 表格"普通文件"— 它是 OLE 容器，必须 olefile 解析
