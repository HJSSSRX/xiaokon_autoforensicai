# 历届 WP 题库索引

**用途**：当现场遇到一道新题，AI 顾问（本机或 DeepSeek）用关键词检索本目录下的 markdown，召回相似的历年题，去原 WP 链接看完整解法。

**数据源**：[didctf.com/practice/writeups](https://forensics.didctf.com/practice/writeups) 聚合 + 各博主原文。

---

## 已收录（按时间倒序）

| 文件 | 比赛 | 题数 | 原文 WP |
|---|---|---|---|
| `FIC-2025决赛.md` | 2025 FIC 决赛 | ~60 | [WXjzc cnblogs](https://www.cnblogs.com/WXjzc/p/18901128) |
| `FIC-2025初赛.md` | 2025 FIC 初赛 | ~50 | [玫幽倩 blog](https://mei-you-qian.github.io/2025/10/28/2025fic初赛复盘/) |
| `FIC-2024决赛.md` | 2024 FIC 决赛 | ~70 | [玫幽倩 blog](https://mei-you-qian.github.io/2026/01/22/2024FIC%E5%86%B3%E8%B5%9B/) |
| `平航杯-2025初赛.md` | 2025 平航杯初赛 | 73 | [玫幽倩](https://mei-you-qian.github.io/2025/10/29/2025平航杯初赛/) / [WXjzc](https://www.cnblogs.com/WXjzc/p/18840490) |
| `盘古石-2025晋级赛.md` | 2025 盘古石晋级赛 | ~60 | [玫幽倩](https://mei-you-qian.github.io/2025/10/28/2025盘古石晋级赛/) |
| `美亚杯-2025资格赛.md` | 2025 美亚杯资格赛 | 98 | [玫幽倩](https://mei-you-qian.github.io/2025/11/21/2025美亚杯-资格赛) |
| `美亚杯-2024团队赛.md` | 2024 美亚杯团队赛 | 130 | [WXjzc/K4m1to](https://www.cnblogs.com/WXjzc/p/18585542) |

**待补**（未公开 WP 或抓取受阻）：2024 平航杯（CSDN 反爬，已记录题型方向）；2026 任何赛事（未公开）。

---

## 关键词体系（grep 友好）

每题前用 `[标签]` 标注，便于检索。下面是常用标签的语义：

### 检材类型
`[android]` `[ios]` `[itunes-backup]` `[windows]` `[macos]` `[linux-server]` `[pcap]` `[pve]` `[docker]` `[nas]` `[vr]` `[usb]` `[iot]` `[apk]` `[exe]` `[so]` `[memory]`

### 取证方向
`[basic-info]` 基本设备信息（IMEI/MAC/版本）
`[browser]` 浏览器历史/书签/搜索
`[wechat]` `[whatsapp]` `[telegram]` `[qq]` 即时通讯
`[crypto]` 加密容器（VeraCrypt/BitLocker/加密 zip）
`[wallet]` 虚拟货币钱包/助记词/链上交易
`[malware]` 恶意样本分析
`[reverse]` 逆向（PE/APK smali/SO/PE/upx）
`[c2]` C2 通信/反弹 shell
`[steganography]` 隐写/水印
`[sql]` SQL 数据分析
`[neo4j]` 图数据库
`[bluetooth]` 蓝牙取证
`[remote-control]` 远程控制（teamviewer/向日葵/RustDesk）
`[shadow-account]` 影子账户/横向移动
`[deepfake]` AI 换脸/AI 生成
`[gps]` 地理位置/EXIF
`[tor]` `[vpn]` 暗网
`[website-rebuild]` 网站重构

### 工具栈提示
`[tool:火眼]` `[tool:EZ]` `[tool:volatility]` `[tool:tshark]` `[tool:apktool]` `[tool:jadx]` `[tool:dnSpy]` `[tool:passwarekit]` `[tool:hashtool]` `[tool:regripper]` `[tool:dislocker]`

---

## 用法（给 AI 顾问）

1. 拿到现场题面，提取**3-5 个关键词**（检材类型 + 取证方向 + 题面关键名词）
2. 在 `knowledge/wp_index/` 下 `grep -l` 这些关键词
3. 找到 top-K 相似历年题，**点开原文 WP 链接**看完整解法
4. 把解法迁移到现场题，给出**指导性建议**（不直接给答案，而是说"看 X 工具的 Y 字段"）

详见 `HOWTO_USE_ADVISOR.md` 与 `scripts/ask_advisor.py`。
