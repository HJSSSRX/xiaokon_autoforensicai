# Playbook · 流量分析

## 0. 概览

```bash
capinfos $PCAP                          # 开始/结束时间、包数、大小、文件 hash
tshark -r $PCAP -q -z io,phs            # 协议分布
tshark -r $PCAP -q -z conv,tcp | head   # TCP 会话排行
tshark -r $PCAP -q -z conv,udp | head
tshark -r $PCAP -q -z endpoints,ip
```

看 `phs` 协议分布第一眼就能判断是 HTTP 题 / DNS 题 / 蓝牙题 / 内网 SMB 题 / 蠕虫题。

---

## 1. HTTP / HTTPS

### 明文 HTTP

```bash
# 所有 URL
tshark -r $PCAP -Y http.request -T fields -e ip.src -e http.host -e http.request.uri

# POST 请求体
tshark -r $PCAP -Y 'http.request.method==POST' \
    -T fields -e http.host -e http.request.uri -e urlencoded-form

# 响应状态分布
tshark -r $PCAP -q -z http,stat,

# 导出所有 HTTP 对象
mkdir -p $OUT/http && tshark -r $PCAP --export-objects http,$OUT/http
```

### HTTPS

- 看 `tls.handshake.extensions_server_name`（SNI）
- 看证书：`tls.handshake.certificate`
- JA3 指纹：`tshark -o tls.desegment_ssl_records:TRUE -r $PCAP -Y ja3 -T fields -e tls.handshake.ja3`
- **解密**：需要 `SSLKEYLOGFILE` 或服务器私钥

```bash
tshark -o tls.keylog_file:/path/to/sslkeys.log -r $PCAP -Y http
```

---

## 2. DNS

```bash
# 所有查询
tshark -r $PCAP -Y 'dns.flags.response==0' -T fields -e dns.qry.name | sort -u

# DGA 识别
tshark -r $PCAP -Y 'dns.flags.response==0' -T fields -e dns.qry.name | \
    awk -F. '{print $1}' | awk '{print length}' | sort | uniq -c
```

DNS 隧道特征：
- 高熵子域、长度一致
- 大量 TXT 查询
- 异常高的查询频率

---

## 3. 文件还原

```bash
# HTTP 对象
tshark -r $PCAP --export-objects http,$OUT/http_objs

# SMB 文件
tshark -r $PCAP --export-objects smb,$OUT/smb_objs

# FTP 数据
tshark -r $PCAP --export-objects ftp-data,$OUT/ftp_objs

# TFTP（蠕虫常用）
tshark -r $PCAP --export-objects tftp,$OUT/tftp_objs

# 追流导出
tshark -r $PCAP -z follow,tcp,raw,$STREAM_ID -q > $OUT/stream.raw
```

导出后：
```bash
file $OUT/http_objs/*
md5sum $OUT/http_objs/*
```

---

## 4. Zeek 一键化（复杂流量必上）

```bash
mkdir -p $OUT/zeek && cd $OUT/zeek
zeek -C -r $PCAP
ls
# conn.log dns.log http.log ssl.log files.log weird.log notice.log
zeek-cut id.orig_h id.resp_h id.resp_p service < conn.log | sort -u
zeek-cut id.orig_h method host uri user_agent < http.log | sort -u
zeek-cut tx_hosts rx_hosts mime_type filename md5 sha1 < files.log
```

Zeek log 是 TSV + 带头注释，`awk` / `rg` / `pandas` 都顺。

---

## 5. 蓝牙流量（平航杯 2025 特色）

```bash
# 包类型分布
tshark -r $BTSNOOP -q -z io,phs | grep -i bt

# HCI 命令/事件
tshark -r $BTSNOOP -Y 'bthci_cmd or bthci_evt' \
    -T fields -e frame.time -e bthci_cmd.opcode -e bthci_cmd.param
```

蓝牙题常考：
- **设备名修改记录**：HCI_Write_Local_Name (0x0c13) 命令
- **MAC 地址变化**：HCI_LE_Set_Random_Address (0x2005)
- **广播数据（厂商 ID）**：`btcommon.eir_ad.entry.company_id`

```bash
# 设备改名时间
tshark -r $BTSNOOP -Y 'bthci_cmd.opcode == 0x0c13' \
    -T fields -e frame.time_utc -e bthci_cmd.device_name

# 广播厂商数据
tshark -r $BTSNOOP -Y 'btcommon.eir_ad.entry.company_id' \
    -T fields -e btcommon.eir_ad.entry.company_id -e btcommon.eir_ad.entry.data
```

---

## 6. SMB / Kerberos / 内网

```bash
# SMB 文件拷贝
tshark -r $PCAP -Y 'smb2.filename' -T fields -e ip.src -e smb2.filename

# Kerberos 票据
tshark -r $PCAP -Y kerberos.CNameString -T fields -e kerberos.CNameString

# NTLM hash（AS-REP Roasting / Responder 场景）
tshark -r $PCAP -Y 'ntlmssp.auth.domain' -T fields -e ntlmssp.auth.domain -e ntlmssp.auth.username
```

---

## 7. 常见恶意流量特征

| 特征 | 工具/命令 |
|---|---|
| C2 心跳 | 固定间隔 TCP/UDP 到同一 IP；`conn.log` 看 duration 周期性 |
| 数据外传 | 单向大流量；`conn.log` 排 `orig_bytes` 降序 |
| webshell 访问 | `http.log` 找 `.php/.aspx/.jsp` + POST + 长 body |
| Cobalt Strike | `http.log` 路径形如 `/submit.php?id=XXX`、特定 URI 模式、JA3 指纹库 |
| Meterpreter | 固定 header 长度、4 字节长度 + 加密 payload |

---

## 8. 大流量切片

```bash
# 按时间切
editcap -A '2025-01-01 00:00:00' -B '2025-01-02 00:00:00' in.pcap out.pcap

# 按 IP 过滤导出新 pcap
tshark -r in.pcap -Y 'ip.addr == 1.2.3.4' -w out.pcap

# 按包号
editcap -r in.pcap out.pcap 100-200
```

---

## 9. 常见坑

- **pcapng vs pcap**：新版 Wireshark 默认 pcapng，老工具（tcpdump 老版）不认。`editcap -F pcap in.pcapng out.pcap`
- **无 SSLKEY**：不要花时间尝试解密，看 SNI + 证书够了
- **时间戳**：frame.time 是捕获时间（本机时区），做时间对齐用 `frame.time_utc`
- **重传/乱序**：`tcp.analysis.retransmission` 过滤掉再分析 payload
- **蓝牙 btsnoop 格式**：`hcidump` 的 btsnoop 和 Wireshark 直接读的格式不完全一样
