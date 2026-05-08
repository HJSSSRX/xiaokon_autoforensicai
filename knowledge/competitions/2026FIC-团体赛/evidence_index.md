# 检材路径索引 — 2026 FIC 团体赛

> 注：检材文件不在版本控制内，仅记录**路径和元数据**。任何机器跑题前需要先把检材放到对应路径，或修改 prompt 中的路径常量。

---

## 物理检材文件

| 编号 | 类型 | 文件路径（主机） | 大小（约） | 用途 |
|---|---|---|---|---|
| 检材1 | 计算机 | `E:\ffffff-JIANCAI\2026FIC团体赛\检材1-计算机.E01` | ~ 大 | computer Q1-Q10 |
| 检材2 | 手机 | `E:\ffffff-JIANCAI\2026FIC团体赛\检材2-手机\` | tar 包 | mobile Q1-Q17 |
| 检材3-1 | 服务器盘1 | `E:\ffffff-JIANCAI\2026FIC团体赛\检材3-服务器\检材3-1.E01` | 大 | server Q1-Q15 + internet Q1-Q3 |
| 检材3-2 | 服务器盘2 | `E:\ffffff-JIANCAI\2026FIC团体赛\检材3-服务器\检材3-2.E01` | 大 | 同上（LVM 跨双盘） |
| 检材4 | U盘 | `E:\ffffff-JIANCAI\2026FIC团体赛\检材4-U盘.E01` | 中 | binary Q1-Q5 |

---

## 关键磁盘 offset / 偏移

> 来自 `F-S001` 和 server_analyst 的磁盘映射分析

### 检材3 服务器（双盘 LVM）

```
sda = 检材3-2.E01
sdb = 检材3-1.E01

VG volum (加密):
  └─ LV root (56GB)
       ├─ pv0 = sda2 (检材3-2 sector 8204288)
       └─ pv1 = sdb1 (检材3-1 sector 2048)

VG root:
  └─ LV data (60GB)
       ├─ pv1 = sdb2 (检材3-1 sector 58593280)
       └─ pv0 = sda3 (检材3-2 sector 66797568)

extent_size = 4MB
LVM2 = 2.03.31
创建于 2026-04-11
```

### 检材4 U盘

`SampleVC.exe` 的 inode 信息见 `F-B001`：从 NTFS 卷 offset=0 用 icat 提取。

---

## 关键文件偏移（finding 中提到的）

| 偏移 | 检材 | 内容 | 来源 finding |
|---|---|---|---|
| `0x6FF809353` | 检材3-1 | docker 字符串 | F-S004 |
| `0xC04A027` | 检材3-2 (swap) | docker 字符串 | F-S004 |
| `0x6FF845D38` | 检材3-1 | nginx 字符串 | F-S004 |
| `0x6FF8432C4` | 检材3-1 | ngrok 二进制 | F-S004 |
| `0xFDCD20` | 检材3-2 | ngrok 字符串 | F-S004 |
| `0x7779110DB` | 检材3-1 | nginx access.log Referer header → ngrok 域名 | F-S006 |
| `0x719ACE441` | 检材3-1 | MacCMS 模板 welcome.html | F-S007 |

---

## 关键 hash / 哈希

| Hash | 类型 | 含义 | 来源 |
|---|---|---|---|
| `764789dd9c095d74b6b258cf0f7568b2` | MD5 | SampleVC.exe 文件本身 | F-B001 |
| `afb977ac242ad60cf46124ad72ca5149` | MD5 | SampleVC.exe 中**期望的密码 MD5** | F-B003 |
| `2fe53132-155e-c444-b224-e29cb4201c0e` | UUID | btrfs 文件系统 UUID | F-S003 |
| `9628874a3c6b403593766496fa985893` | 32位hex | 手机用户 UID = 聊天 SQLCipher key | F-M005 |
| (待补) | SHA1 | F-M014 中提到的疑似 VC 密码散列 | F-M014 |

---

## 关键 IP / 域名 / URL

| 值 | 类型 | 含义 | 来源 |
|---|---|---|---|
| `blemish-junior-unengaged.ngrok-free.dev` | 域名 | ngrok 隧道 | F-S006 |
| `https://api.sp-live88.com/collect/userdata` | URL | 恶意 APP 数据上传地址 | F-M010 |
| `file:///android_asset/www/index.html` | URI | 恶意 APP 离线页面 | F-M009 |

---

## 关键钱包地址

| 钱包 | 链 | 用途 | 来源 |
|---|---|---|---|
| `TN8vQzB3n7W5wVca9W4kL2wP7xY9zM5nU1` | TRON (USDT-TRC20) | 云服务器商家备用 | F-M006 |
| `TXqH7sVn8bR4kL2mN9pW6xJ3cY5dF1gA` | TRON (USDT-TRC20) | 视频 APP 解密配置中 | F-M012 |
| (txhash 26226f...) | — | 第一次转账给搭建人员 | F-M018 |

---

## CMS / 框架信息

- **MacCMS v10** (PHP CMS, magicblack/maccms10) — 网站后台
  - admin 路径在 `application/admin/view_new/`
  - 配置变量 `${ADMIN_PATH}`
  - 前端 layui 框架

---

## 关键凭证 / 密码

| 类型 | 值 | 来源 |
|---|---|---|
| SQLCipher 密钥（uuuim） | `9628874a3c6b403593766496fa985893` | F-M005 |
| LVM 解密尝试密码（推测） | `FIC-{e404d6e66586e9460c23755afab5a872bcf7...}` | F-S003 detail |
| VC 密码期望 MD5 | `afb977ac242ad60cf46124ad72ca5149` | F-B003 |

---

## 工具路径（主机）

| 工具 | 路径 |
|---|---|
| ghidra | `C:\Users\44116\scoop\apps\ghidra\` |
| dissect.target / dissect.ewf | `pip install dissect.target dissect.ewf` |
| sleuthkit (mmls/fls/icat) | scoop / WSL |
| WSL Ubuntu | 推荐用于挂载 ewfmount + cryptsetup |
| Hub | port 8765 (本地) |
| cloudflared | `C:\Program Files (x86)\cloudflared\cloudflared.exe` |
| 公网隧道 URL | `https://burn-carter-president-dimensions.trycloudflare.com` (会变) |
