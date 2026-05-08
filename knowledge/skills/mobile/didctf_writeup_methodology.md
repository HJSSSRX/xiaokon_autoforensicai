# DIDCTF / 长安杯 / FIC / 蓝帽杯 / 美亚杯 真题方法论

> 学习资料：DIDCTF 平台真题 writeup（cnblogs handsomesnowsword 整理 + xidian forensics wiki + DIDCTF 官方博客零星可见）
>
> 本文聚焦：**已有 KB 中的方法 ↔ 真题考点的映射**，以及**真题中暴露的、原 KB 漏写或不够细的点**。
>
> 取证比赛通用工作链：**镜像/检材到手 → 商业取证软件一遍（火眼/取证大师/盘古石/手机大师/AXIOM）→ 题目卡住 → 半手工脚本/Frida/IDA/jadx 兜底 → 答完 → hash 固定 + 报告**。

---

## 1. 真题考点矩阵

按"真题问的事 → 我的 KB 哪里写过 → 解题工具"三列整理（仅手机/APK 相关）：

| 考点 | 真题示例 | KB 章节 | 工具/命令 |
| --- | --- | --- | --- |
| APK SHA-256 | 长安杯 2021 检材 1 Q1 | `apk_internals.md` §10 | `certutil -hashfile a.apk sha256` / `sha256sum` / 取证大师 |
| APK 包名 | 长安杯 2021 Q2 / 2022 Q46 | `apk_internals.md` §2.4 | `aapt dump badging` / GDA BaseInfo / jadx |
| APK 服务商 APPID（DCloud / uni-app） | 长安杯 2021 Q3 | **§7.1（本文新增）** | manifest meta-data `DCLOUD_STREAMAPP_CHANNEL` |
| APK 危险权限 | 长安杯 2021 Q4 / 2022 Q47 | `apk_internals.md` §2.4 + §8.1 | `aapt dump permissions` |
| APK 回传内容/HTTP 方法/域名 | 长安杯 2021 Q5–Q9 | `android_app_cloud_forensics.md` §2 | Fiddler/Charles/mitmproxy + jadx 反编看 `apiserver` |
| APK 运行时数据库文件名 | 长安杯 2021 Q10 | `apk_crypto_analysis.md` + `database_forensics.md` | jadx 搜 `SQLiteOpenHelper` `DATABASE_NAME` `dbName` `openOrCreateDatabase` `.db` `.sqlite` |
| APK 数据库初始密码 | 长安杯 2021 Q11 | `hook_techniques.md` §5.1 | Frida hook `SQLiteOpenHelper` 构造或 `sqlite3_key` |
| APK 加固解锁多关 / 字符串密文 / VMP / native decrypt | 长安杯 2022 Q48–Q50 | `android_packer_unpacker.md` + `android_reverse_analysis.md` §4–§5 | jadx + frida hook + IDA 看 `libcipher.so` |
| 微信内部 ID / 受害者 ID | FIC 2024 Q4 / Q6；长安杯 2021 检材 4 Q9 | `wechat_deep_dive.md` | shared_prefs `login_weixin_username` |
| 微信 EnMicroMsg.db 解密 | FIC 2024 Q5 | `wechat_deep_dive.md` | IMEI + uin → MD5 7 位 → SQLCipher v1 |
| QQ 账号 / 接触渠道 | 长安杯 2021 Q7/Q10；FIC 多题 | `popular_apps_forensics.md` | 火眼 / 手机大师 |
| Wi-Fi 第一次连接时间 / 已知 Wi-Fi | FIC 2024 Q3/Q7；美亚 2021 Q6 | `ios_logs.md` §7 + `lock_password_forensics.md` | `misc/wifi/WifiConfigStore.xml` `CreationTime` |
| 平板/二级设备识别 | FIC 2024 Q2 | **§7.2（本文新增）** | 已配对设备 + 已连 Wi-Fi 名包含设备型号 |
| 手机型号识别（型号在哪个文件） | FIC 2024 Q1 | `device_basic_info.md` | `misc/location/xtra/useragent.txt` 内 UA |
| IMEI / 设备识别 | 长安杯 2021 检材 4 Q6 | `device_basic_info.md` | 火眼 / 手机大师 / `data/properties/persist.radio.imei` |
| 模拟器名称/安装日期 | 2022 暑假 Q3；长安杯 2022 Q33 | `emulator_forensics.md` §1.2 + §5.1 | 取证大师 + 注册表 `HKLM\SOFTWARE\<Vendor>` |
| 应用使用频度/活跃时段 | FIC 2024 Q8；美亚多题 | `android_app_attribution.md` §6.6 | `usagestats/` 解析 + 聊天表时间分桶 |
| 嫌疑 App 上传聊天/通讯录到服务器 | 长安杯 2021 检材 1 整套 | `android_app_cloud_forensics.md` §2 + §7.1 | Fiddler + jadx |
| 加密容器 VeraCrypt（小白鼠.txt 等） | 长安杯 2021 Q11；FIC 2024 Q2 | **§7.3（本文新增）** | VeraCrypt + 仿真大师 + 密码字典 |
| BitLocker 解密密钥 | 长安杯 2021 检材 4 Q2；FIC 2024 Q5；美亚 Q10 | **§7.3（本文新增）** | 取证大师自动取证 |
| 加密 zip / Office 工资表破解 | FIC 2024 Q19 | **§7.4（本文新增）** | `passware password recovery kit forensic` / hashcat |
| AI 换脸工具/生成参数 | FIC 2024 Q10–Q13 | **§7.5（本文新增）** | PowerShell 历史 + 工具痕迹 |
| 浏览器自动填充密码 | 2022 暑假 Q11；FIC 2024 Q17 | `database_forensics.md` + Windows 浏览器存储 | 火眼自动解密 / 仿真后看明文 |
| 隐写在图片中的密码 | FIC 2024 Q4 | **§7.6（本文新增）** | binwalk / steghide / zsteg / stegolsb / strings |
| 二维码扫描 / 解密 URL | FIC 2024 Q14 | **§7.6（本文新增）** | Chrome 历史记录 / zbar |
| 私有聊天服务器（Rocket.Chat） | FIC 2024 Windows + 服务器集群 | **§7.7（本文新增）** | docker inspect + mongodb |
| 容器密码与磁盘密码同源关联 | 长安杯 2021 Q11/Q12 | **§7.8（本文新增）** | 多检材密码相互关联 |

---

## 2. 真题三大手机/APK 解题套路

### 2.1 套路 A：APK 反编 + 抓包还原回传逻辑（**长安杯 2021 检材 1 完整流程**）
1. `certutil -hashfile a.apk sha256` 出 hash；
2. `aapt dump badging a.apk` 看包名 + 权限 + 启动 Activity；
3. `apktool d -s a.apk -o app/` 解 manifest + 资源；
4. AndroidManifest.xml 看 `<meta-data>` 内 SDK / 渠道 / APPID；
5. jadx 反编 dex 看 `apiserver`、`apisms`、`upload`、`POST` 等关键字；
6. **装到模拟器 + Fiddler / mitmproxy + 触发上传** 印证 URL + 请求体；
7. 看是否有 `SQLiteOpenHelper` / `DATABASE_NAME` 拿 db 名；
8. Frida hook `SQLiteOpenHelper` 构造拿初始密码。

### 2.2 套路 B：手机检材一次火眼/手机大师 → 不够再翻源文件（**FIC 2024 手机部分**）
1. 商业软件（火眼取证 / 美亚手机大师 / 盘古石）一遍报告；
2. 答案不全 / 自动解析未覆盖 → 翻**特征源文件**：
   - `data/com.tencent.mm/shared_prefs/com.tencent.mm_preferences.xml` 微信内部 ID/uin/手机号
   - `data/com.tencent.mm/MicroMsg/<md5>/EnMicroMsg.db` 主聊天库
   - `data/com.tencent.mm/shared_prefs/auth_info_key_prefs.xml` 解密辅料
   - `misc/wifi/WifiConfigStore.xml` Wi-Fi 历史 + 创建时间
   - `misc/location/xtra/useragent.txt` 含手机 UA / 型号
   - `data/system/packages.xml` 装过 App 列表 + 时间
   - `data/system/usagestats/0/` 使用频度
3. 时间戳交叉，回答活跃时段 / 第一次连接 / 创建账号等。

### 2.3 套路 C：APK 加固 → 多关 FLAG 解锁（**长安杯 2022 Q48–Q50**）
1. APKiD 识别加固厂商；
2. 装到 root 模拟器 + frida-server + frida-dexdump 脱壳；
3. jadx 反编 → 找 `OnClick` / 用例 → 定位每关 verify 函数；
4. **简单关**：直接字符串比对 → 看 `if (input.equals("xxx"))` 拿明文；
5. **加密关**：用例对比 → trim2 与解密结果比较 → frida hook `App.OooO0O0.OooO0oo` 字段拿明文 / 调用 `decrypt` native；
6. **复杂关**：4 字符一组移位拼大数 + try/catch trick → 写爆破脚本（每组 4 个可见字符暴破 95^4 ≈ 8e7 量级）。

> 这是少见的"取证赛要写逆向爆破脚本"题型；多数取证赛不会到这一步，但长安杯/蓝帽杯出过。

---

## 3. 商业取证软件在赛场的真实分工

| 软件 | 真题中干的活 |
| --- | --- |
| **火眼取证 / 美亚手机大师** | 一次性出手机报告（Wi-Fi/通话/短信/微信/QQ/相册/位置）；多题答案直接抄 |
| **盘古石 / DC-4501** | 同上；**iOS 备份解析强**；阅读器单独可用（蓝帽杯 2022 Q1 直接打开） |
| **取证大师** | Windows 镜像分析；BitLocker 自动取证；模拟器/浏览器自动识别；hash 计算 |
| **仿真大师 / VirtualMaster** | "把镜像直接跑起来"——**绕开机密码** / **看浏览器明文密码** / **看加密容器空密码登录后内容** |
| **Cellebrite / AXIOM / Oxygen** | 国际赛或要求商业凭证时；多支持 iOS 物理 |
| **passware password recovery kit forensic** | Office / zip / PDF / VeraCrypt 字典爆破 |
| **iLEAPP / ALEAPP** | 开源补足；商业漏的字段；可定制脚本 |
| **GDA / jadx-gui** | APK 反编（赛场首选） |
| **frida + Python** | 加固 / 加密字段兜底 |

> **场上时间分配建议**（4–6 小时赛事）：
> - 0–30 分钟：商业软件喂检材 + 跑全自动报告；
> - 30 分钟 – 题目结束 80%：根据题目答案直接抄报告；
> - 最后 20%：手工兜底卡住的题（reverse、爆破、隐写等）。

---

## 4. 真题暴露的"我 KB 缺漏"清单

下列条目原 KB 没专门写或写得太薄，本文 §7 单独补。

1. **DCloud / HBuilder uni-app "流应用"识别**——国内灰产打包神器，包名形如 `plus.H5xxxxxxx`，APPID 在 `DCLOUD_STREAMAPP_CHANNEL` 元数据里。
2. **二级设备识别套路**——目标手机的 Wi-Fi 历史 / 蓝牙配对里看到 `Xiaomi Pad 6S Pro 12.4` / `iPhone 15 Pro` 即推断嫌疑人有该平板/手机。
3. **VeraCrypt 加密容器手工识别**——文件大、entropy 高、扩展名常被改成 `.txt` `.bin` `.dat`；仿真后空密码 / key 文件挂载。
4. **加密 Office / zip 字典爆破**——`passware password recovery kit forensic` / hashcat。
5. **AI 换脸/AI 工具痕迹取证**——ROOP / Stable Diffusion / DiffusionDraw；PowerShell 历史 + 工具安装目录 + 输出图片元数据。
6. **图片隐写常用算法库**——steghide / zsteg / stegolsb / binwalk / `outguess` / EOF 数据。
7. **私有聊天服务器（Rocket.Chat / Mattermost / synapse / 自建 IM）**——容器化部署常见。
8. **跨检材密码关联**——一组检材里"PC 加密容器密码=BitLocker 恢复密钥保管位置"或"VeraCrypt 密码隐写在图片"等套娃。
9. **Fiddler 抓模拟器 HTTPS**——赛场最常见组合（mitmproxy 已写但 Fiddler 单独提一下）。

---

## 5. 真题中关键源文件路径速查（**Android 直接背**）

| 考点 | 源文件路径 |
| --- | --- |
| 手机 UA / 型号 | `misc/location/xtra/useragent.txt` |
| Wi-Fi 历史 + CreationTime | `misc/wifi/WifiConfigStore.xml`（旧版 `wpa_supplicant.conf`） |
| 微信内部 ID / 手机号 / uin | `data/com.tencent.mm/shared_prefs/com.tencent.mm_preferences.xml` |
| 微信 EnMicroMsg.db 解密辅料 | `data/com.tencent.mm/shared_prefs/auth_info_key_prefs.xml` |
| 微信主聊天库 | `data/com.tencent.mm/MicroMsg/<32位hex>/EnMicroMsg.db` |
| 微信图片缓存 | `data/com.tencent.mm/MicroMsg/<32位hex>/image2/` |
| QQ 主库 | `data/com.tencent.mobileqq/databases/<QQ号>.db` 或 `databases/Msg.db`（QQ NT） |
| 已装 App 清单 + 时间 | `data/system/packages.xml` + `packages.list` |
| App 使用频度 | `data/system/usagestats/0/` |
| 通讯录 | `data/com.android.providers.contacts/databases/contacts2.db` |
| 短信/彩信 | `data/com.android.providers.telephony/databases/mmssms.db` |
| 通话记录 | `data/com.android.providers.contacts/databases/calllog.db`（部分 ROM 已合入 contacts2.db） |
| 浏览器历史 | `data/com.android.chrome/app_chrome/Default/History` 或 `app_webview/` |
| 时区 | `getprop persist.sys.timezone` |
| Lockdown / 信任 PC（iOS） | `/private/var/root/Library/Lockdown/pair_records/`（参 ios_fundamentals.md） |
| iCloud 账号 | `Library/Preferences/com.apple.MobileMeAccounts.plist` |

---

## 6. 真题中的"出题方常埋的坑"

1. **包名 ≠ 应用名**：题目"应用名"是 launcher label，"包名"是 `com.x.y`，别填错。
2. **DCloud 流应用包名内含 APPID**：`plus.H5B8E45D3` 里的 `H5B8E45D3` 是 APPID 而非随便字符串。
3. **WiFi CreationTime 是 first-time 而非 last-time**：第一次连的时间题答这里；最后一次要看 LastUpdateTime / 通话/位置交叉。
4. **微信 UIN 和手机号**：`last_login_uin` 是数字 UIN，`login_user_name` 才是手机号；ID 是 `login_weixin_username`。
5. **EnMicroMsg.db 路径里 32 位 hex** = MD5("mm" + uin)；用 uin 反推可验证。
6. **certutil 不区分大小写但要小写**：题目要求小写 hash 时手工转。
7. **VeraCrypt 容器扩展名常被改**：见到大体积 entropy 极高的 `.txt`、`.dat`、`.bin` 即怀疑。
8. **"小白鼠.txt" 套娃**：长安杯出过；txt 实际是 VeraCrypt 容器，挂载需 key 文件。
9. **"我赚钱的工具.zip" + 同密码**：zip 密码与 BitLocker 密码相同 = `192.168.110.203-CAB2021` 一类长串；密码字典常含案件 IP 与会议名。
10. **AI 换脸题看 PowerShell 历史**：`%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`。
11. **取证大师有 BitLocker 自动取证** 但若忘了开就漏；务必勾选。
12. **手机大师 IMEI 与火眼 IMEI 偶尔不一致**：以火眼为准（题目通常按它出）。
13. **多检材密码套娃**：检材 1 题里给的密码可能是检材 2 的解压密码，必须按编号顺序解。
14. **盘古石阅读器 ≠ 盘古石全功能**：阅读器只读已生成的报告，不能再分析；蓝帽杯 2022 给的是阅读器 + 已分析数据。

---

## 7. 缺漏补强（KB 原文未细写的几条）

### 7.1 DCloud / HBuilder / uni-app 流应用识别
> 国内灰产 App 高频："拉一个 H5 网页 + 用 HBuilder 一键打包成 APK 上架" → 大量诈骗/赌博/裸聊 App 都是这种结构。

**特征**：
- 包名 `plus.H5xxxxxxxx`，主 dex 多为 DCloud 框架，**业务逻辑全在 `assets/apps/H5xxxxxxxx/www/` 内的 HTML/CSS/JS**。
- AndroidManifest meta-data 内 `DCLOUD_STREAMAPP_CHANNEL`、`DCLOUD_AD_ID`、`DCLOUD_APPKEY`。
- `assets/data/dcloud_control.xml` 含 appid、版本、强制更新 URL。
- SO 多有 `libweex.so`、`libuni-jsc-android.so`、`libpdr.so`。

**取证流程**：
```bash
unzip -l app.apk | grep -E 'assets/apps|dcloud|H5[A-Z0-9]+/www'
# 解 H5 业务
unzip app.apk -d app/
ls app/assets/apps/<H5xxxxxxxx>/www/
# index.html 内含 var apiserver = 'http://...'
grep -rEi 'apiserver|api_url|baseURL|http://' app/assets/apps/*/www/
```

> **比赛速题**：APPID 在 `DCLOUD_STREAMAPP_CHANNEL` 的 value 里（管道分隔三段）；回传地址在 `index.html` 或 `js/main.js` 里硬编码的 `apiserver`。

### 7.2 二级设备/平板识别套路
- **Wi-Fi 历史**含设备名 SSID（手机自身热点 SSID 默认是型号）→ 看 `WifiConfigStore.xml` 里 SSID 字段是否 `Xiaomi Pad 6S Pro 12.4`、`iPhone 15 Pro` 之类。
- **蓝牙配对历史** `data/misc/bluedroid/bt_config.conf` / `bt_config.xml` 里看 Name 字段。
- **隔空投送 / Mi share / Huawei Share 收发记录**：`data/system_de/0/sms-deferred-messages` 类，或厂商专属 db。
- **同账号登录其他设备**（Apple ID / 小米账号 / 华为账号）：账号系统 db 内 `device_id` 表。

### 7.3 VeraCrypt 加密容器识别 + 解锁
**识别**：
- 文件 entropy ≈ 7.99（接近随机）；
- 大小是 512 字节倍数；
- 头无任何特征魔数（VeraCrypt 故意如此，反取证）；
- 文件名常被改：`.txt`、`.bin`、`.dat`、`.zip`；
- 工具：`binwalk -E file.bin` 看高 entropy + 平直曲线即怀疑；`file` 报 `data`；统计 byte 分布是平的。

**解锁**：
1. 已知密码 → VeraCrypt GUI 直接挂；
2. **key file** 模式：嫌疑人用 `key.rar` / `keyfile.png` 当密钥文件 → 在嫌疑人检材里搜可疑文件作 keyfile；
3. **仿真大师**：直接跑起原 OS，VeraCrypt 已配置好的容器双击空密码 / 自动挂；
4. 字典爆破：`hashcat -m 13721/13722/13723 hash.txt dict.txt`（VeraCrypt SHA512/Whirlpool/RIPEMD160 各模式）；
5. 内存：嫌疑人当时挂载着 → RAM dump 抓密钥（Volatility `truecryptmaster`/`truecryptpassphrase`/`truecryptsummary` 插件兼容 VeraCrypt）。

### 7.4 加密 Office / zip / PDF 暴破
| 类型 | 工具 | hashcat mode |
| --- | --- | --- |
| Office 2007–2019 | `office2hashcat.py` + hashcat | 9400/9500/9600 |
| zip（PKZIP） | `zip2john` + hashcat | 13600 / 17200 |
| RAR3 / RAR5 | `rar2john` | 12500 / 13000 |
| 7z | `7z2john.pl` | 11600 |
| PDF v1–6 | `pdf2john.pl` | 10400/10500/10600/10700 |
| VeraCrypt | `veracrypt2john.py` | 13721/13722/13723 |
| Bitlocker | `bitlocker2john` | 22100 |
| WhatsApp crypt12 | `whatsapp2hashcat`/`hashcat -m 24800` | |
| Apple iTunes 备份 | `itunes_backup2hashcat.pl` | 14700/14800 |

商业一键：**Passware Kit Forensic**（题目内提到）/ **Elcomsoft Distributed Password Recovery**。

### 7.5 AI 换脸/AI 生成内容取证（**新兴**）
| 工具 | 痕迹位置 |
| --- | --- |
| **ROOP**（开源换脸） | 安装目录 + PowerShell `python run.py --target xxx --source yyy --output zzz --similar-face-distance 0.85` 类命令 |
| **DeepFaceLab** | 工作目录大量 `aligned/` `merged/` PNG；模型文件 `*.h5` `*.npy` |
| **Stable Diffusion / WebUI** | `outputs/txt2img-images/<日期>/` PNG 含 PNG-tEXt 元数据 `parameters` 字段 |
| **DiffusionDraw / Midjourney 客户端** | 历史日志 + 缓存图 |
| **AI 换声**（So-VITS-SVC / RVC） | 训练数据集 + 模型 `.pth` |

**取证关键来源**：
- `%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`：命令行历史，含完整调用参数。
- 浏览器历史：访问 huggingface / civitai / replicate 等。
- 工具自身日志：ROOP `roop.log`、SD WebUI `webui.log`。
- 输出图片 EXIF / PNG-tEXt：含模型 / prompt / 参数（**关键证据**）。
- 系统 Temp 目录 + Recycle Bin。

```bash
# 看 SD 输出图的元数据
exiftool out.png | grep -i parameters
strings -el out.png | head -30

# PowerShell 历史
type "%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" | findstr /i "roop sd python --source --target"
```

### 7.6 图片隐写 / 二维码题
**隐写常用工具组合**：
```bash
binwalk file.png                      # 看末尾是否藏 zip / file
foremost file.png                     # 提取嵌入文件
strings file.png | tail -200          # 末尾是否有可读文本
exiftool file.png                     # EXIF / Comment / UserComment
zsteg file.png                        # PNG/BMP LSB 全套
stegolsb stegdetect -t a file.png     # 多算法检测
steghide extract -sf file.jpg         # 输入密码尝试
outguess -r file.jpg out.txt          # outguess
stegseek file.jpg dict.txt            # 字典爆破 steghide
```

**二维码 / 条码**：
```bash
zbarimg qr.png                        # 解二维码
# 或在线 zxing.org
```

> **取证赛常见**：`steghide -p 已知密码` 解 jpg → 拿到 VeraCrypt 容器密码；二维码内是 base64 / URL，再拿密码继续套娃。

### 7.7 私有聊天服务器（Rocket.Chat / Mattermost / 自建 IM）
**Rocket.Chat 取证**（FIC 2024 服务器集群）：
- 部署形式：Docker / Snap / RPM；多数 Docker。
- 数据库：**MongoDB**，库名 `rocketchat`，集合 `users`/`rocketchat_message`/`rocketchat_room`。
- 配置：`/var/snap/rocketchat-server/common/` 或容器 `/app/data/`。
- 关键命令：
```bash
docker ps                                 # 找 rocketchat + mongo 容器
docker exec -it <mongo_id> mongosh
> use rocketchat
> db.users.find({}, {_id:1, username:1, emails:1, createdAt:1, roles:1}).pretty()
> db.rocketchat_message.find().sort({_id:-1}).limit(20).pretty()
> db.rocketchat_message.aggregate([{$group:{_id:"$u.username",cnt:{$sum:1}}},{$sort:{cnt:-1}}])
```
- 上传文件：`rocketchat_uploads.files` 元数据 + `rocketchat_uploads.chunks` 二进制；导出用 `mongofiles` 或 `db.collection.find().forEach(printjson)` 解。

**Mattermost / synapse(Matrix) / Element**：类似思路，PostgreSQL 后端为主。

### 7.8 跨检材密码关联（套娃题型）
**典型套路**：
1. 检材 N 内的某文档/便签 = 检材 N+1 的密码；
2. 检材 N 的图片隐写 = 检材 N+1 的容器密码；
3. 检材 N 的浏览器自动填充 = 检材 N+1 的某后台密码；
4. 检材 N 的密码字典文件（用户自留） = 后续暴破词典。

**应对**：
- 解出第一个密码后立即扫所有检材里的 .txt / 便签 / 桌面文件；
- 把案件人名 / 项目名 / 案发时间 / 路由器 IP / 公司名 加入密码字典；
- 看是否有 `dic.txt` `password.txt` `字典.txt` `常用密码.docx` 一类文件。

### 7.9 Fiddler 抓模拟器 HTTPS（**赛场最常见**）
```
1. PC 装 Fiddler Classic（免费）；Tools → Options → HTTPS：勾选 Capture HTTPS CONNECTs + Decrypt HTTPS traffic
2. Connections → Allow remote computers to connect + 端口 8888 + 重启 Fiddler
3. PC 防火墙允许 8888；记下 PC IP
4. 模拟器 / 真机 Wi-Fi 配代理：PC IP : 8888
5. 模拟器浏览器访问 http://ipv4.fiddler:8888 下载 FiddlerRoot 证书
6. 装到"信任凭据-用户"
7. Android 7+ App 不信任用户 CA → 装到系统 CA（root + Magisk MagiskTrustUserCerts）
8. 触发 App → Fiddler 看明文
```
> 与 §3 mitmproxy 二选一；Fiddler GUI 友好但脚本能力差，mitmproxy 反之。

### 7.10 certutil + PowerShell 一行 hash
```powershell
certutil -hashfile a.apk MD5
certutil -hashfile a.apk SHA1
certutil -hashfile a.apk SHA256

# PowerShell 5+
Get-FileHash a.apk -Algorithm SHA256
Get-ChildItem *.apk | Get-FileHash -Algorithm SHA256
```
- 题目要小写时：`(certutil -hashfile a.apk SHA256 | findstr /v ":").trim().toLower()`。

---

## 8. APK 反编时的"关键字搜索清单"（**长安杯题目暴露的）

按"找什么 → 搜什么"：
| 找 | 关键字 |
| --- | --- |
| 数据库文件名/初始化 | `SQLiteOpenHelper` `DATABASE_NAME` `dbName` `openOrCreateDatabase` `.db` `.sqlite` `getWritableDatabase` `getReadableDatabase` |
| SQLCipher key | `sqlite3_key` `SQLCipher` `WCDB` `setPassword` `cipher_compatibility` `password` |
| 上传 URL / API | `apiserver` `apiUrl` `BASE_URL` `BaseURL` `baseUrl` `host` `endpoint` |
| 短信回传 | `sms` `duanxin` `apisms` `SmsManager` `getMessageBody` |
| 通讯录回传 | `contact` `tongxunlu` `getContacts` `Phonebook` `READ_CONTACTS` |
| 加密函数 | `encrypt` `decrypt` `Cipher` `AES` `DES` `RSA` `MD5` `SHA1` `Base64` `XOR` `xor` |
| 网络发包 | `OkHttp` `HttpURLConnection` `Volley` `Retrofit` `WebView` `loadUrl` `postUrl` |
| Token / 登录 | `token` `accessToken` `refreshToken` `Authorization` `Bearer` `cookie` `session` |
| OSS / 云 | `OSS` `accessKey` `secret` `STS` `bucket` `endpoint` `cos` `s3` |
| 设备指纹 | `getDeviceId` `getImei` `getMeid` `Settings.Secure.ANDROID_ID` `Build.SERIAL` |
| WebView 桥 | `addJavascriptInterface` `JavascriptInterface` |
| 加固入口（壳） | `StubApp` `proxyApplication` `attachBaseContext` `loadDex` |

> jadx-gui Ctrl+Shift+F 全局搜，结合正则 `(?=.*sqlitehelper)(?=.*db)` 多关键词组合（来自长安杯 writeup）。

---

## 9. 真题型 → 决策流速查

```
题目分类：
├─ 给 APK 文件 → 单题 1 分钟
│   ├─ "包名/版本/权限/Activity" → aapt dump badging
│   ├─ "签名指纹" → apksigner verify --print-certs
│   ├─ "加固厂商" → apkid
│   └─ "渠道号/APPID" → AndroidManifest meta-data + walle
│
├─ 给 APK 文件 → 反编题
│   ├─ jadx-gui 反编（先看 launcher Activity / Application）
│   ├─ 关键字搜（§8 清单）
│   ├─ 加固 → frida-dexdump 脱壳
│   └─ 字符串密文 → frida hook decrypt 函数
│
├─ 给手机镜像/备份 → 用户层题
│   ├─ 商业软件喂一遍（火眼/手机大师/盘古石）
│   ├─ 答案不全 → 翻 §5 关键源文件路径
│   └─ 加密 db → wechat_deep_dive / database_forensics
│
├─ 给 PC 镜像 + APK 关联题
│   ├─ PC 内有模拟器 → emulator_forensics §3
│   ├─ PC 内有 APK 副本 → 直接反编
│   └─ PC 内有抓包工具痕迹（Fiddler/Charles 配置）→ 看会话历史
│
├─ 综合检材（手机 + PC + 服务器）
│   ├─ 套娃密码 → §7.8
│   ├─ AI 工具痕迹 → §7.5
│   ├─ 隐写 → §7.6
│   └─ 私有 IM → §7.7
│
└─ APK 加固解锁多关
    ├─ 脱壳 → jadx 看 OnClick
    ├─ 简单关：字符串明比对
    ├─ 中等关：frida hook 字段/decrypt
    └─ 复杂关：写 4-char × 6 组爆破脚本
```

---

## 10. 引用真题来源

- **DIDCTF 2021 第三届长安杯**：APK 反编 + 抓包 + 数据库密码（套路 A 完整模板）。
- **DIDCTF 2022 暑假取证学习**：模拟器识别 + Bitlocker + 浏览器密码 + 注册表 ControlSet。
- **DIDCTF 2022 第四届长安杯**：APK 加固 4 关 FLAG 解锁（套路 C）+ 模拟器内勒索程序分析。
- **DIDCTF 2024 FIC 线上赛**：手机型号溯源 / Wi-Fi 历史 / 微信 ID + AI 换脸 + 私有 Rocket.Chat（综合）。
- **2022 蓝帽杯初赛/半决赛**：iOS 取证（盘古石阅读器）+ 内存 TrueCrypt 密钥 + iBoot 版本。
- **2021 美亚杯个人赛**：iPhone 物证（GPS/相片元数据/Wi-Fi 密码/iBoot/iCloud 备份时间） + 跨平台综合。
- **2024 长城杯决赛溯源取证**：Tomcat / Web 入侵链路（非手机但与设备日志关联）。

---

## 11. 交叉链接（已有 KB 入口）
- `apk_internals.md` — APK 结构理论
- `android_packer_unpacker.md` — 加固/脱壳
- `android_reverse_analysis.md` — 同一/同源 + 反静动态分析
- `apk_crypto_analysis.md` — 算法/密钥
- `android_app_attribution.md` — 溯源
- `android_app_cloud_forensics.md` — 抓包/云数据
- `android_analysis_environment.md` — 工具环境
- `hook_techniques.md` — Frida/LSPosed/Substrate
- `wechat_deep_dive.md` / `popular_apps_forensics.md` — App 沙盒
- `emulator_forensics.md` — 模拟器
- `database_forensics.md` — SQLite/SQLCipher/WCDB
- `lock_password_forensics.md` — 锁屏 / 应用锁
- `ios_app_parsing.md` / `ios_logs.md` — iOS
- `quick_reference.md` — 顶层入口

---

## 12. 待补（未来题型趋势）

- **eBPF / Magisk Zygisk 取证**（设备已被嫌疑人改装 ROM 的证据链）
- **Web3 钱包 App 取证**（助记词/私钥/链上交易关联，参 `crypto_currency_forensics.md` 如已建）
- **多模态 AI 证据**（含 AI 视频 deepfake、AI 换声、AI 写文案的痕迹溯源）
- **国产化生态**：HarmonyOS NEXT 5 取证 / 鸿蒙 App `.hap` 反编（已在 `other_smart_devices.md` 起步，需深化）
- **5G SUCI/SUPI、AKMA**：与设备 IMSI 隐私化对取证的影响
- **Android 14+ Photo Picker / Privacy Dashboard**：限制了 App 沙盒外可见性，影响传统提取套路
