# 安卓 APP 云数据取证（取证比赛视角）

> 适用：题目涉及"App 数据在云端而非设备"，要求**抓包 / 云端固定 / 云数据分析**。题目特征：见到"嫌疑人手机微信聊天记录已删 → 云端是否还能取"、"嫌疑人用某 App 上传了文件到云盘"、"嫌疑人隐藏证据用云存储"、"App 与服务器交互内容是什么"等。
>
> 与 `wechat_deep_dive.md`（微信云）、`ios_app_parsing.md`（iCloud）互补：本篇聚焦**安卓 App 云数据**通用方法 + 法律调取 + 数据固定证据链。

---

## 1. App 云数据三类来源

| 类别 | 含义 | 取证手段 |
| --- | --- | --- |
| **A. 平台原生云**（微信云、QQ 云、百度网盘、阿里云盘等） | App 后台直接对接厂商云 | 法律调取 + 客户端 token + 抓包 |
| **B. 第三方对象存储**（OSS / S3 / COS / OBS） | App 自建后端，用阿里/腾讯/AWS 对象存储 | App 内 AccessKey 提取 + 直接列桶下载 |
| **C. App 自家服务器**（接口式云） | 嫌疑 App 私有 API 后端 | 抓包还原协议 + 服务端调取 |

> **取证原则**：合法授权下"双轨"——客户端取证 + 服务端调取。两条互补。

---

## 2. 数据抓包（**最高频题源**）

### 2.1 抓包目标
| 目标 | 含义 |
| --- | --- |
| 看 App 与服务器通信内容 | 还原协议 + 找证据字段 |
| 拿 token / cookie / refresh_token | 持续登录账户拿历史数据 |
| 拿对象存储 AccessKey | 直接列云端文件 |
| 看上传/下载的文件元数据 | 文件 hash 比对、URL 反查 |
| 还原签名算法 | 自构造请求拿数据 |

### 2.2 抓包工具组合
| 工具 | 角色 |
| --- | --- |
| **mitmproxy / mitmweb** | 主代理，跨平台 + Python 脚本 |
| **Charles** | GUI，国内常用 |
| **Burp Suite Community** | Web 渗透常用，插件多 |
| **Fiddler / Fiddler Everywhere** | 老牌 |
| **Wireshark** | 看裸 TCP/UDP/QUIC（非 HTTPS） |
| **HttpCanary**（设备本地 App） | 无 root，靠 VPN 模式 |
| **PCAPdroid**（设备本地 App） | 同上，开源 |
| **r0capture / Reqable** | Android Native + HTTPS 双解 |

### 2.3 抓包 HTTPS 标准流程（**Android 7+**）
```
1. 启动 mitmweb：mitmweb --listen-port 8080 --listen-host 0.0.0.0
2. 设备 Wi-Fi → 配 PC IP : 8080 代理
3. 装 mitmproxy CA：访问 http://mitm.it 下证书 → 安装到"用户证书"
4. Android 7+ 用户 CA 默认不被 App 信任 → 处理：
   ├─ 推荐：把证书装到系统 CA（root 设备）
   │   adb push mitm.pem /sdcard/
   │   hash=$(openssl x509 -inform PEM -subject_hash_old -in mitm.pem | head -1)
   │   adb shell su -c "mount -o rw,remount /system; cp /sdcard/mitm.pem /system/etc/security/cacerts/${hash}.0; chmod 644 /system/etc/security/cacerts/${hash}.0"
   │   reboot
   ├─ 替代：装 Magisk 模块 MagiskTrustUserCerts（重启即生效）
   └─ 临时：改 APK 加 networkSecurityConfig 信任用户 CA（要重签）
5. 触发 App 行为
6. 在 mitmweb 看明文请求/响应
```

### 2.4 SSL Pinning 绕过
| 形式 | 绕过 |
| --- | --- |
| **OkHttp CertificatePinner** | `objection android sslpinning disable`（一行） |
| **TrustManager / X509TrustManager** | 同上覆盖 |
| **WebView pinning** | objection 也覆盖；少数自家 WebClient 校验需 hook |
| **网络安全配置 `<pin-set>`** | 装系统 CA 即可（pin-set 仅校验链，不强制证书） |
| **自家 native 校验**（SO 内 verify） | frida hook native verify 函数 |
| **双向 mTLS** | 提取客户端证书 + 私钥（多在 assets/raw 或 keystore），喂给 mitmproxy |

```bash
# Objection 一行
objection -g com.foo.bar explore
> android sslpinning disable
> android root disable
```

### 2.5 反代理检测
| 检测点 | 绕过 |
| --- | --- |
| 检查系统代理（`Proxy.NO_PROXY`） | 不走系统代理 → 用透明代理（iptables redirect） |
| 检查证书链 | 装系统 CA |
| 检查 hostname 白名单 | 改 hosts 让目标域走代理 |
| 强制使用 QUIC/HTTP3 | mitmproxy 现在支持 H3 + HTTP/2 + Brotli |
| 自家协议（非 HTTP） | 用 frida hook send/recv 抓 |
| MARS 协议（QQ/微信使用） | 专用工具：mars-decoder；或 hook 加密层 |

### 2.6 透明代理（解决 App 不走系统代理）
```bash
# Linux 上跑透明代理
mitmproxy --mode transparent --listen-port 8080
# 设备 iptables 重定向（root 设备）
adb shell su -c "iptables -t nat -A OUTPUT -p tcp --dport 80 -j DNAT --to 192.168.1.x:8080"
adb shell su -c "iptables -t nat -A OUTPUT -p tcp --dport 443 -j DNAT --to 192.168.1.x:8080"
```
或用 **r0capture**：
```bash
python r0capture.py -U -f com.foo.bar -p result.pcap
# 自动 hook SSL_read/SSL_write，输出明文 pcap
```

### 2.7 取证抓包注意事项
1. **设备/网络隔离**：取证机房专网，避免触发远程擦除。
2. **保留原始流量**：mitmproxy `-w flow.flow` + tcpdump pcap 双份。
3. **录屏**：操作触发过程必须录屏（操作 ↔ 流量映射）。
4. **hash 固定**：导出 flow / pcap 后立即 SHA-256，写入笔录。
5. **不修改原 APK**：抓包用副本，原 APK 保留作证据。

---

## 3. App 云数据"客户端拿"（不联系服务商）

### 3.1 思路
不依赖法律调取，从设备本身取得云数据访问凭证 + 直接拉数据。

### 3.2 关键提取点（按存储位置）
| 位置 | 内容 | 提取 |
| --- | --- | --- |
| `shared_prefs/*.xml` | token/refresh_token/userId | 文本 grep |
| `databases/*.db` | session、配置、缓存 | sqlite3 |
| `MMKV/<id>` | 同上（KV 形式） | mmkv-parser |
| `assets/` | 配置/SDK 配 | unzip |
| `Account` 系统服务 | OAuth token（部分 App 走 AccountManager） | `dumpsys account` / `accounts.db` |
| `WebView/CookieManager` | 网页 cookie | `app_webview/Cookies` (sqlite) |
| `Keystore` | 加密 token / RSA key | 需 root + 提取 keystore + 解 |

### 3.3 提取后的应用
| 凭证 | 用途 |
| --- | --- |
| Bearer token / cookie | 直接 curl 调用 App API 拿数据 |
| OAuth refresh_token | 换 access_token 持续访问 |
| 对象存储 AccessKey/Secret | 用 ossutil/cosbrowser 列桶下载 |
| 加密 token | 找解密算法（参 `apk_crypto_analysis.md`） |

```bash
# 拿到 token 后 curl
curl -H "Authorization: Bearer <token>" https://api.target.com/v1/messages

# 阿里云 OSS AccessKey
ossutil config -e oss-cn-shanghai.aliyuncs.com -i <AK> -k <SK>
ossutil ls oss://bucket-name/
ossutil cp -r oss://bucket-name/ ./local/

# 腾讯云 COS
coscli config add -i <AK> -k <SK> -e cos.ap-shanghai.myqcloud.com
coscli ls cos://bucket
coscli cp -r cos://bucket/ ./local/

# AWS S3
aws s3 ls s3://bucket --profile <profile>
aws s3 sync s3://bucket ./local --profile <profile>
```

### 3.4 示例：从 App 提 OSS AccessKey
1. jadx 反编 → 搜 `OSSClient` / `STSGetter` / `Credential` 类。
2. 多数 App 走 STS（临时 AK），`shared_prefs` 内有 SecurityToken + Expiration。
3. 直接拿 STS 三件套 → ossutil 配置 → 列桶。

```bash
ossutil config -e <endpoint> -i <AK> -k <SK> -t <SecurityToken>
ossutil ls oss://bucket/
```

---

## 4. App 云数据"服务端调取"（**法律渠道**）

### 4.1 适用场景
- 设备已损坏 / 已抹除；
- 嫌疑 App 数据已删但**云端有备份**；
- 实时通信记录（IM）服务端可能仍在；
- 需要全量历史（设备只有最近时段）；
- 需要附件原文件（设备仅缩略图）。

### 4.2 调取流程（公安渠道，简述）
```
1. 立案 + 调取手续（《调取证据通知书》）
2. 联系厂商法务 / 安全应急对接窗口
3. 提交身份信息（嫌疑人 ID/手机号/账号）+ 时间范围
4. 厂商核实 + 出具数据 + 电子凭证（含 hash）
5. 取证人员收数据 + 加固完整性 + 入卷
6. 报告引用厂商出具凭证编号
```

### 4.3 主要平台调取窗口
| 平台 | 渠道 | 数据范围 |
| --- | --- | --- |
| 腾讯（微信/QQ） | 腾讯安全应急响应中心 / 协查公函 | 登录 IP 日志、注册资料、文件传输元数据；**聊天内容受限**（端到端的不可得） |
| 字节（抖音/今日头条） | 字节协查 | 视频上传记录、登录、私信元数据 |
| 阿里（淘宝/支付宝/钉钉/阿里云） | 阿里巴巴司法协助 | 同左 + 资金流水 |
| 百度（百度网盘） | 百度协查 | 登录 + 文件元数据 + 部分文件内容 |
| 美团 / 京东 / 拼多多 | 各家协查 | 订单/收货地址/支付 |
| Google（Gmail/Drive/Photos） | Google LERS | 通过 MLAT，国际刑事司法协助 |
| Apple（iCloud） | Apple Law Enforcement | 备份/Drive/Photos；ADP 开启则 E2E 不可得 |
| Microsoft（OneDrive/Outlook） | LEA portal | 同上 |
| Meta（FB/IG/WhatsApp） | LERS | WhatsApp 内容 E2E 不可得，元数据可 |

### 4.4 厂商通常能给的数据
| 数据 | 是否常见可得 | 备注 |
| --- | --- | --- |
| 注册手机号 / 邮箱 | ✅ | 实名核验 |
| 登录 IP / 设备型号 / 时间 | ✅ | 黄金证据，关联现场 |
| 好友列表 / 群成员 | ✅（社交） | |
| 聊天内容（IM） | ❌（多数 E2E）/ ⚠️（部分明文） | 不同平台政策不同 |
| 上传文件元数据（hash/大小/时间） | ✅ | 可追原文件 |
| 上传文件原文 | ⚠️（视政策）/ ✅（云盘类） | 法律调取门槛 |
| 资金流水（支付） | ✅（支付宝/微信支付） | 可证明交易 |
| 短信/通话记录 | ❌（运营商不是 App 厂商） | 走运营商 |
| 设备指纹 / 风控日志 | ⚠️ | 风控团队保留 |

### 4.5 端到端加密（E2E）的影响
- WhatsApp / iMessage（云开 E2E） / Signal / Telegram Secret Chat / 微信"端对端聊天"功能：**服务器没有明文**。
- 取证只能：
  - 客户端本地数据（设备物理/逻辑提取）；
  - 已信任设备 / 配对设备的本地副本；
  - 云备份（如果备份未加密，**WhatsApp Google Drive 备份未加密就是大漏斗**）。

---

## 5. App 云数据典型类别

### 5.1 IM 聊天云
| App | 云存储情况 |
| --- | --- |
| **微信** | iCloud 备份内含 ChatStorage（iOS）/ 自家"聊天迁移"云中转（限时）；服务器**不存历史聊天明文** |
| **QQ** | 服务端漫游消息 7/14/30 天可拉回；客户端/PC 可同步 |
| **WhatsApp** | Google Drive 备份**默认无 E2E 加密**（旧）/ 新版已支持 E2E 备份；iOS 同 |
| **Telegram 普通聊天** | 服务器中心化加密存储，可拉回；**Secret Chat** 例外 |
| **Signal** | 服务器零知识，**无任何聊天可调取** |
| **企业微信 / 钉钉 / 飞书** | 服务器明文存（合规审计）；管理员/法律可调 |

### 5.2 短信备份云
- iOS：iCloud 信息（Messages in iCloud）；
- Android：Google Messages（RCS） / Samsung Cloud / Mi Cloud；
- Huawei Cloud。

### 5.3 文件 / 相册云
| 云盘 | 厂商 |
| --- | --- |
| **微信收藏 / 文件** | 腾讯云后端 |
| **百度网盘** | 百度 |
| **阿里云盘** | 阿里 |
| **115 网盘** | 上海帮宝 |
| **天翼云盘** | 中国电信 |
| **OneDrive / Google Drive / iCloud Drive** | 微软/谷歌/苹果 |
| **Dropbox / Mega / pCloud** | 海外 |

### 5.4 浏览器云同步
- Chrome Sync（书签、历史、密码）→ Google 账号。
- Edge Sync → 微软账号。
- Safari iCloud → Apple。
- 取证：登录账号或法律调取。

### 5.5 应用使用云（健康/位置/购物）
- 华为运动健康 / 小米运动 / Samsung Health → 云步数/心率/睡眠/位置。
- 高德 / 百度地图 → 收藏地址 + 历史搜索。
- 美团 / 滴滴 → 订单地址 + 路线。
- 这些云数据**对人物画像/活动轨迹证据极强**。

### 5.6 IoT 智能设备云
- 米家 / 智能家居 / 摄像头 → 录像/告警在云。
- 小米手环 / 苹果手表 / 华为手环 → 健康数据。
- 行车记录仪 / 大疆无人机（参 `dji_q10.py` 类专项）。

---

## 6. App 云数据分析方法

### 6.1 抓回的流量分析
- mitmproxy flow 文件 → 用 mitmweb 重看 / mitmdump 脚本批量解。
- 提取所有 URL + body + response → CSV。
- 关键字段：`Authorization`、`Cookie`、`X-Request-ID`、`signature`、上行/下行 JSON 字段。

```python
# mitmdump 脚本：自动解 protobuf body
from mitmproxy import http
import blackboxprotobuf
def response(flow: http.HTTPFlow):
    ct = flow.response.headers.get("content-type","")
    if "protobuf" in ct or flow.response.content[:2] in (b'\x08\x01', b'\x08\x02'):
        try:
            v, t = blackboxprotobuf.decode_message(flow.response.content)
            print(flow.request.url, v)
        except: pass
```

### 6.2 调取数据的解析
| 形态 | 处理 |
| --- | --- |
| `*.csv` / `*.xlsx`（厂商出具表格） | pandas 直接读 |
| `*.json` / `*.jsonl` | jq + python |
| `*.zip` 含日志 + 文件 | 解压 + sha256 + 时间排序 |
| `*.eml` / `*.mbox`（邮件） | mailparser / pst-converter |
| `*.pst` / `*.ost`（Outlook） | libpff / pypff |
| 端 E2E 备份文件 | 需对应 App 解密（如 WhatsApp `crypt14`/`crypt15` 备份） |

### 6.3 时间线交叉
- 把云数据时间戳 + 客户端数据时间戳 + 网络登录 IP 时间戳画时间线；
- 互相印证：客户端"X 时刻发消息"应对应云端"X 时刻的写入"。
- 工具：plaso / log2timeline / Excel 透视表 / pandas。

### 6.4 IP / 地理画像
- 调取的登录 IP + 时间 → IP 反查地理 + ISP；
- 多次登录的 IP 聚类 = 嫌疑人活动地点；
- 多账号登录同 IP = 关联账号。

```bash
# IP 反查
whois <ip>
curl https://ip-api.com/json/<ip>
# 批量
cat ips.txt | while read ip; do curl -s https://ip-api.com/json/$ip | jq -c .; done
```

### 6.5 文件 hash 反查
- 服务器调取的"文件元数据"含 hash（多为 MD5/SHA1/SHA256）；
- 与本地相册/文件 hash 比对 → 证明嫌疑人确实持有/上传该文件。
- 与其他案件 hash 库（如已知淫秽物品库 PhotoDNA）比对 → 关联犯罪事实。

---

## 7. 比赛常见题型与解法

### 7.1 类型 A："抓 App 与服务器通信，看上传内容"
1. 装到模拟器/root 真机 + Magisk + MagiskTrustUserCerts；
2. mitmproxy + objection ssl unpinning；
3. 触发 App 行为（如发消息/上传文件）；
4. 看 mitmweb 请求 → 找 body 内的关键字段；
5. 报告：上传 URL / 字段 / 大小 / 时间。

### 7.2 类型 B："App 用 OSS 存文件，找出 AccessKey"
1. jadx 反编 → 搜 `OSS_KEY_ID` / `accessKey` / `OSSClient` / `STSGetter`；
2. 不行 → frida hook `OSSClient` 构造函数抓运行时 AK；
3. 拿到 AK 后用 ossutil 列桶；
4. 报告：AK 来源类 + 桶名 + 文件清单。

### 7.3 类型 C："嫌疑人手机已抹除，云端聊天/文件能否恢复"
1. 看 App 类型（IM？云盘？社交？）；
2. 联系厂商法务调取（合规流程）；
3. 同步获得登录 IP 日志；
4. 报告写"可调取范围 + 已调取数据 + E2E 限制"。

### 7.4 类型 D："嫌疑 App 走自家协议，看不到 HTTPS"
1. 用 r0capture / objection `pcapdroid` 模式抓裸 socket；
2. 仍加密 → frida hook send/recv 函数；
3. 解析自家协议（多为 protobuf / TLV / JSON 加密）；
4. 报告：协议结构 + 关键字段。

### 7.5 类型 E："嫌疑 App 上传文件到 OneDrive / Google Drive，找文件"
1. 提取 OAuth refresh_token（shared_prefs / Account / SQLite）；
2. 走对应 OAuth flow 换 access_token；
3. 调 Drive API 列文件 + 下载；
4. 或法律调取（MLAT，海外）。

### 7.6 类型 F："嫌疑人微信删除聊天记录后，云端是否还能恢复"
- 微信服务器**不存聊天明文**（端到端 + 仅中转）；
- 云端可调取的：注册资料、登录 IP、群成员、文件传输 URL（限时 7 天）；
- 完整恢复需依赖：iCloud 备份 / 微信"聊天迁移"中转 / PC 微信本地数据库 / 其他终端同账号。

### 7.7 类型 G："嫌疑 App 的请求签名算法是什么"
1. mitmproxy 抓包看请求是否有 `sign=xxx`；
2. jadx 搜 `sign` 字符串 / `signRequest` 类；
3. frida hook 签名函数抓运行时 输入/输出 → 推算法；
4. 报告写 sign = HMAC(key, sorted_params + timestamp + nonce) 等。

### 7.8 类型 H："嫌疑账号关联多设备登录"
1. 调取登录日志 → 设备型号 / IMEI / Android ID / IP / 时间；
2. 同账号多设备 = 关联其他嫌疑人或行动地点；
3. 与本地 Android ID / Build.SERIAL 比对，证实是嫌疑人手机。

### 7.9 类型 I："抓包遇到 QUIC / HTTP3 / WebSocket"
1. mitmproxy 已支持 H3，需开启 `--mode reverse:` 或 H3 代理；
2. WebSocket：mitmweb 默认看到 `ws://` `wss://` 双向消息；
3. QUIC 自家：用 `nQUIC` 工具（Cloudflare）；
4. 仍解不了 → SSL_read/write 层 hook（r0capture）。

### 7.10 类型 J："App 用 mTLS 双向证书"
1. 找客户端证书（assets/raw 或 keystore）；
2. 提取私钥（解密 keystore）；
3. mitmproxy 配 client_cert：
   ```bash
   mitmproxy --set client_certs=client.pem
   ```
4. 抓包成功；报告含证书来源。

---

## 8. 命令速查

```bash
# 抓包基础
mitmweb --listen-host 0.0.0.0 --listen-port 8080
adb shell settings put global http_proxy <PC_IP>:8080
# 关闭代理
adb shell settings put global http_proxy :0

# 装系统 CA（root）
hash=$(openssl x509 -inform PEM -subject_hash_old -in mitm.pem | head -1)
adb push mitm.pem /sdcard/${hash}.0
adb shell su -c "mount -o rw,remount /system; cp /sdcard/${hash}.0 /system/etc/security/cacerts/; chmod 644 /system/etc/security/cacerts/${hash}.0"
adb reboot

# Magisk 模块快捷
# 装 MagiskTrustUserCerts 模块；用户证书自动生效

# Objection 一行
objection -g com.foo.bar explore
> android sslpinning disable
> android root disable

# r0capture（HTTPS 明文 pcap）
python r0capture.py -U -f com.foo.bar -p out.pcap

# 透明代理 + iptables 重定向（root 设备）
adb shell su -c "iptables -t nat -A OUTPUT -p tcp --dport 443 -j DNAT --to <PC_IP>:8080"

# 提 token
adb shell run-as com.foo.bar cat /data/data/com.foo.bar/shared_prefs/auth.xml
adb shell cat /data/data/com.foo.bar/databases/auth.db
adb pull /data/data/com.foo.bar/

# WebView Cookie
adb pull /data/data/com.foo.bar/app_webview/Default/Cookies
sqlite3 Cookies "SELECT host_key,name,value FROM cookies;"

# OSS / COS / S3
ossutil ls oss://bucket -i <AK> -k <SK>
coscli ls cos://bucket
aws s3 ls s3://bucket

# 调取数据解析
jq '.events[] | select(.type=="login") | [.time, .ip, .ua]' login.json
pandas: pd.read_csv('login.csv').groupby('ip').time.count()

# IP 地理反查
curl https://ip-api.com/json/<ip>
whois <ip>

# 时间线
log2timeline.py --parsers=mitmproxy timeline.body flow.flow
psort.py -o l2tcsv timeline.body > timeline.csv

# WhatsApp Google Drive 备份解密（旧版未 E2E）
# 工具：whapa / wa-crypt-tools
whatsapp-crypt-tools --decrypt msgstore.db.crypt14 --key key
```

---

## 9. 常见坑

1. **抓包修改 APK = 改证据**：取证抓包必须用副本/同型号设备，原检材不动。
2. **用户证书 vs 系统证书**：Android 7+ 用户证书默认不被信任，必须装系统 CA / Magisk 模块 / 改 networkSecurityConfig。
3. **App 不走系统代理**：要么透明代理，要么 r0capture，要么 hook send/recv。
4. **objection sslpinning 不万能**：自家 native 校验 / mTLS / 自定义 TrustManager 仍需 frida 单独 hook。
5. **QUIC / HTTP3 难抓**：部分 App 强用 H3；要在系统级关 UDP:443 或用 mitmproxy h3 模式。
6. **OAuth refresh_token 有过期**：拿到后必须尽快换 access_token；某些 token 仅一次性。
7. **OSS AccessKey 是 STS 临时凭证**：有过期时间（通常 1–24h），失效后需重抓。
8. **服务端调取门槛**：必须正式公函 + 立案手续，越境数据需 MLAT；比赛通常不真调，但要写明流程。
9. **E2E 限制**：调取报告必须明确"E2E 端到端服务器无明文，仅可拿元数据"，避免承诺无法兑现。
10. **WhatsApp Google Drive 备份**：旧版无 E2E（**取证大漏斗**）；新版可选 E2E，需用户输 64 字符密钥才解。
11. **iCloud ADP（高级数据保护）**：开启后 iCloud 备份/Drive/Photos 全 E2E，**Apple 法律调取拿不到内容**。
12. **抓包流量含敏感信息**：用户密码/聊天内容；保管 + 加密存储 + 限制分发。
13. **时间戳混用**：抓包是本地时区，云日志可能 UTC；报告时统一时区。
14. **WebView Cookie 受 SameSite/Secure 影响**：直接 curl 带 Cookie 不一定行，需附加 UA / Origin / Referer。
15. **mTLS 证书格式**：mitmproxy 要 PEM；keystore 内是 BKS/JKS，需 `keytool` 转 + 解密。
16. **多账号同设备**：抓包时确认正在使用的账号；不要混淆 token。
17. **录屏和操作笔录**：每个抓包行为都要"操作 → 流量"对应；缺操作记录的流量证据力弱。
18. **OSS 列桶可能含他人数据**：嫌疑 App 桶可能与其他无关用户共用；提取仅嫌疑人 user_id 前缀的对象，避免越界。
19. **海外云数据**：必须经 MLAT；私自跨境调取违法。
20. **IM 漫游消息**：QQ 7-30 天 / 微信不漫游；超过窗口就拿不到。

---

## 10. 决策流

```
题目要"App 云数据"
├─ 题目要"通信内容/协议字段"（实时）
│   1. mitmproxy + 装系统 CA
│   2. objection sslpinning disable
│   3. 触发 App 行为
│   4. 看流量 + 分析 body
│   └─ 自家协议 → r0capture / frida hook send/recv
│
├─ 题目要"云端文件/聊天"（非实时）
│   ├─ 走客户端：从 App 提 token / refresh_token / OSS AK
│   │   1. shared_prefs / db / MMKV / Account / WebView Cookie
│   │   2. 反编代码确认存储位置
│   │   3. 凭证 + curl/ossutil 拿数据
│   └─ 走服务端：法律调取
│       1. 立案 + 调取手续
│       2. 联系厂商安全/法务窗口
│       3. 收数据 + 固定凭证
│
├─ 题目要"嫌疑人某段时间登录/IP"
│   1. 法律调取登录日志（厂商）
│   2. 客户端日志 / shared_prefs 内 last_login_ip
│   3. 时间线交叉 + IP 地理
│
└─ 题目要"E2E App 内容"
    1. 客户端本地数据（设备物理提取）
    2. 已信任设备/PC 副本
    3. 未加密的旧云备份（如 WhatsApp Google Drive 旧版）
    4. 受限：服务端无明文 → 报告明确说明
```

---

## 11. 交叉链接
- `wechat_deep_dive.md`：微信特定云路径与"聊天迁移"
- `popular_apps_forensics.md`：抖音/QQ/支付宝特定云
- `ios_app_parsing.md` §9：iCloud 详细
- `apk_crypto_analysis.md`：算法/密钥提取
- `android_packer_unpacker.md`：壳内提取 token 与算法
- `android_analysis_environment.md`：抓包/Hook 工具配置
- `android_reverse_analysis.md`：动态对抗与抓包绕过
- `database_forensics.md`：拿到密文 db 后的解密
- `network/network_capture.md`（如有）：通用网络取证
- `extraction_methods.md`：客户端取证前置
- `quick_reference.md`：顶层入口
