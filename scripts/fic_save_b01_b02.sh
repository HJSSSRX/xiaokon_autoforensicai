#!/usr/bin/env bash
ANS_DIR="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"
mkdir -p "$ANS_DIR"

cat > "$ANS_DIR/B01_main_SampleVC_md5.md" <<'A'
## B01 — SampleVC.exe MD5

> 分析u盘检材，找到其中保存的加密程序SampleVC.exe，请给出这个exe程序的md5值？

**答案**: `764789dd9c095d74b6b258cf0f7568b2`  **置信度**: 高

### 解析

**识别**: U盘检材为 NTFS，根目录下有 `SampleVC.exe`（123,392 字节，inode 40-128-3）。

**提取**:
```bash
sudo ewfmount /mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材4-U盘.E01 /tmp/fic2026/usb/ewf
sudo icat /tmp/fic2026/usb/ewf/ewf1 40-128-3 > /tmp/fic_extract/SampleVC.exe
```

**分析+验证**:
```bash
md5sum /tmp/fic_extract/SampleVC.exe
# 输出: 764789dd9c095d74b6b258cf0f7568b2  /tmp/fic_extract/SampleVC.exe
```

文件大小 123,392 字节，与 fls 报告一致。

### 不作弊声明
- 数据来源: 检材4-U盘.E01（赛方提供）
- 工具: sleuthkit (icat), GNU coreutils (md5sum)
- 未访问外部网络
- 脚本: scripts/fic_speed_q.sh
A

cat > "$ANS_DIR/B02_main_SampleVC_compile_date.md" <<'A'
## B02 — SampleVC.exe 编译日期

> 分析SampleVC.exe，该程序编译的日期可能是什么？

**答案**: `2026-04-17 13:53:20 (+08:00)` 或 `2026-04-17 05:53:20 UTC`  **置信度**: 高

### 解析

**识别**: PE32 可执行文件（Windows .exe）。PE 头中的 `IMAGE_FILE_HEADER.TimeDateStamp` 字段记录编译时间戳（Unix epoch）。

**提取**:
```python
import struct, datetime
with open("/tmp/fic_extract/SampleVC.exe", "rb") as f:
    data = f.read()
e_lfanew = struct.unpack_from("<I", data, 0x3C)[0]  # PE 头偏移
ts = struct.unpack_from("<I", data, e_lfanew + 8)[0]  # COFF.TimeDateStamp
print(datetime.datetime.fromtimestamp(ts, datetime.timezone.utc))
```

**分析+验证**:
- TimeDateStamp 原始值: `1776405200` (0x69e1cad0)
- UTC: `2026-04-17 05:53:20`
- 北京时间(+08:00): `2026-04-17 13:53:20`

与 NTFS 文件系统记录的 SampleVC.exe 创建时间 `2026-04-17 13:53:20 (CST)` 完全吻合，互证。

### 不作弊声明
- 数据来源: 检材4-U盘.E01
- 工具: Python struct（标准库），无外部依赖
- 未访问外部网络
- 脚本: scripts/fic_speed_q.sh
A

ls -la "$ANS_DIR/"
echo "Done"
