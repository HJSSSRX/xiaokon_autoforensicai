# PLAYBOOK —— Cascade 拿到新案子的检查单

> 这份文档是给**未来的 Cascade**（下一次会话里的我）看的。用户只需要说"在 `cases/<名字>/` 下有新案子"，Cascade 就照着这份跑。

---

## 0. 开场（必做，不要跳）

1. `ls cases/<名字>/` 看清楚有哪些检材。
2. 打开 `questions.xlsx`，**先把所有题目原文读一遍**，归类成：
   - Windows 镜像题
   - 安卓题
   - 流量题
   - 跨检材关联题（最难，放最后）
3. 在 `cases/<名字>/NOTES.md` 里记下检材清单、题目分类、每题初步打算用什么工具。**不要急着跑工具。**

> 权衡提醒：Karpathy 准则 §1。先想再跑。跑错一次浪费 10 分钟，想清楚只花 2 分钟。

---

## 1. Windows 磁盘镜像（.E01 / .dd / .vmdk / .vhd）

### 1.1 识别与提取

```bash
# WSL 内
cd /mnt/e/项目/自动化取证/cases/<名字>
IMG=evidence/disk.E01
mmls "$IMG"                          # 列分区
fls -r -m / -o <offset> "$IMG" > artifacts/bodyfile.txt   # 全盘 body file
```

### 1.2 关键 artifact 提取（用 tsk_recover 或 Arsenal 挂载后复制）

目标目录：`artifacts/windows/`

必提取：
- `C:\Windows\System32\config\{SAM,SOFTWARE,SYSTEM,SECURITY}` 及每个用户的 `NTUSER.DAT`、`UsrClass.dat`
- `C:\Windows\System32\winevt\Logs\*.evtx`
- `C:\Windows\Prefetch\*.pf`
- `C:\$MFT`（根目录下）
- 每个用户的 `AppData\Roaming\Microsoft\Windows\Recent\*.lnk`
- 每个用户的 `AppData\Local\Google\Chrome\User Data\Default\` 下的 `History`、`Cookies`、`Login Data`
- `C:\Users\<user>\AppData\Roaming\Tencent\` 下的微信/QQ 目录（如存在）

### 1.3 批量解析（回到 Windows，用 Zimmerman 套件）

PowerShell：

```powershell
$A = 'e:\项目\自动化取证\cases\<名字>\artifacts\windows'
$O = 'e:\项目\自动化取证\cases\<名字>\artifacts\parsed'
New-Item -ItemType Directory -Force -Path $O | Out-Null
& tools\MFTECmd.exe -f "$A\`$MFT"           --csv "$O" --csvf mft.csv
& tools\EvtxECmd.exe -d "$A\winevt\Logs"    --csv "$O" --csvf evtx.csv
& tools\PECmd.exe    -d "$A\Prefetch"       --csv "$O" --csvf prefetch.csv
& tools\RECmd\RECmd.exe --bn tools\RECmd\BatchExamples\Kroll_Batch.reb `
                        -d "$A" --csv "$O"
```

输出全部 CSV，直接 `rg` / `pandas` 即可查询。

### 1.4 时间线（可选，题目涉及顺序推理时跑）

```bash
log2timeline.py --storage-file artifacts/plaso.db evidence/disk.E01
psort.py -o l2tcsv -w artifacts/timeline.csv artifacts/plaso.db
```

### 1.5 需要登录状态 / 看桌面 / 解密 BitLocker

**停下**。告诉用户：
> "这题需要看到 `<具体什么>`，请在**火眼仿真系统**里启动该镜像，截图/导出后告诉我。"

---

## 2. 安卓检材（压缩包）

常见是火眼移动取证导出的 `.zip`，或 `adb backup` 的 `.ab`，或全盘的 `.tar`。

### 2.1 解压

```bash
cd cases/<名字>
mkdir -p artifacts/android
7z x evidence/android.zip -o artifacts/android/raw
```

### 2.2 ALEAPP 一键解析

```bash
aleapp -t fs -i artifacts/android/raw -o artifacts/android/aleapp_out
```

产物包含 HTML 报告 + 每模块的 TSV。常见模块覆盖：
- 通话记录、短信、通讯录
- 微信、QQ、支付宝（部分版本）
- 浏览器历史、下载
- Wi-Fi 连接记录、GPS、电池事件

### 2.3 微信/QQ 深挖（ALEAPP 不够用时）

- 定位 `/data/data/com.tencent.mm/MicroMsg/<uin_hash>/EnMicroMsg.db`
- 解密需要 `IMEI + uin`，MD5 前 7 位为密钥。**写专门的脚本**到 `scripts/wechat_decrypt.py`，不要每次手搓。
- 备选：**火眼移动取证**能直接解出来，解不出再上脚本。

### 2.4 图片 EXIF / 位置

```bash
exiftool -r -csv artifacts/android/raw/sdcard/DCIM > artifacts/android/exif.csv
```

---

## 3. 流量包（.pcap / .pcapng）

### 3.1 概览

```bash
cd cases/<名字>
capinfos evidence/traffic.pcapng
tshark -r evidence/traffic.pcapng -q -z conv,tcp | head -50
tshark -r evidence/traffic.pcapng -q -z http,tree
tshark -r evidence/traffic.pcapng -q -z dns,tree
```

### 3.2 文件还原

```bash
mkdir -p artifacts/traffic
tshark -r evidence/traffic.pcapng --export-objects http,artifacts/traffic/http_objs
tshark -r evidence/traffic.pcapng --export-objects smb,artifacts/traffic/smb_objs
tshark -r evidence/traffic.pcapng --export-objects ftp-data,artifacts/traffic/ftp_objs
```

### 3.3 协议级筛选（按题目需要写单次命令，不要预造脚本）

例子：

```bash
# 找所有 POST 请求的 URL 和 body 长度
tshark -r x.pcapng -Y 'http.request.method==POST' \
       -T fields -e http.host -e http.request.uri -e http.content_length

# 提取所有 DNS 查询
tshark -r x.pcapng -Y 'dns.flags.response==0' -T fields -e dns.qry.name | sort -u
```

### 3.4 Zeek（复杂流量必上）

```bash
zeek -C -r evidence/traffic.pcapng
# 产出 conn.log, http.log, dns.log, files.log, ssl.log ...
```

Zeek 的 log 格式规整，`zeek-cut` 切列后 `jq`/`awk` 轻松。

### 3.5 加密流量 / TLS

- 有 `sslkeys.log` / `SSLKEYLOGFILE` → `tshark -o tls.keylog_file:...`
- 无密钥 → 只能看 SNI、证书、JA3 指纹。老实告诉用户。

---

## 4. Excel 题目回写

所有题答完后，Cascade 在 `cases/<名字>/answers.md` 里写：

```markdown
## Q1 [题目原文]
**答案**：xxx
**证据**：`artifacts/parsed/evtx.csv` 第 N 行，事件 ID 4624，时间 ...
**置信度**：高 / 中 / 低（说明为什么）
```

**不**直接改 `questions.xlsx`，保持原始文件只读。最后由用户决定怎么填回去。

---

## 5. 反模式（别做）

- ❌ 不预先写"通用解题 agent"。每题情况差异大，过度抽象只会更慢。
- ❌ 不自动修改 Excel。
- ❌ 不在 `evidence/` 里写东西（保持只读）。
- ❌ 不在看不懂题目的时候瞎跑工具。先读题。
- ❌ 不假装火眼有 CLI。该手动就让用户手动。
