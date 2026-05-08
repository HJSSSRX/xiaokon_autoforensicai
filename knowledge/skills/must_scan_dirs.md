# 取证必扫目录矩阵

> **作用**：拿到任何 OS 的镜像，挂载只读后**第一遍 ripgrep / find 就要覆盖**这里列出的所有路径。
> **维护**：每次比赛/案件遇到新的"系统自带应用"未列入时，回填到本表。
> **使用**：与 `TRIAGE_DSL_v1.md` 配合，walker 把这些路径自动标 P0/P1。

---

## 索引

- [§1 Linux 通用](#1-linux-通用)
- [§2 deepin / UOS 专属](#2-deepin--uos-专属)
- [§3 Ubuntu / GNOME](#3-ubuntu--gnome)
- [§4 KDE](#4-kde)
- [§5 Windows 11/10](#5-windows-1110)
- [§6 macOS](#6-macos)
- [§7 Android](#7-android)
- [§8 iOS](#8-ios)
- [§9 浏览器（跨 OS）](#9-浏览器跨-os)
- [§10 即时通讯（跨 OS）](#10-即时通讯跨-os)
- [§11 系统自带 AI 助手](#11-系统自带-ai-助手)

---

## §1 Linux 通用

```
/etc/os-release                                  系统版本
/etc/passwd  /etc/shadow  /etc/group             用户/组
/etc/hostname  /etc/timezone  /etc/locale.conf
/etc/hosts  /etc/resolv.conf  /etc/network/      网络
/etc/fstab  /etc/crontab  /etc/cron.*/           定时任务
/var/log/                                        系统日志
/var/spool/cron/crontabs/                        用户 cron
/var/lib/AccountsService/users/<user>            登录画像/真名
/var/lib/AccountsService/icons/                  用户头像
/home/<user>/.bash_history  .zsh_history         shell 历史 (反取证常被 rm)
/home/<user>/.viminfo  .lesshst                  编辑器历史
/home/<user>/.ssh/                               SSH key/known_hosts
/home/<user>/.gnupg/                             GPG key
/home/<user>/.local/share/recently-used.xbel     最近文件
/home/<user>/.local/share/Trash/                 回收站
/root/                                           root 用户家目录 (常被忽略)
/tmp/  /var/tmp/                                 临时文件残留
```

## §2 deepin / UOS 专属

```
~/.config/uos-ai*/                               UOS AI sqlite (apiKey/chat history) ★
~/.local/share/deepin/deepin-voice-note/         语音记事本 sqlite
~/.config/deepin/deepin-mail/Storage/<UID>/      deepin-mail (uuid 命名 .eml)
~/.config/Foxmail.deepin/Storage/                Foxmail
~/.config/io.github.clash-verge-rev.*/           clash-verge
~/.local/share/applications/  ~/.config/dock/    桌面/任务栏自定义
/var/lib/lastore/                                deepin 应用商店历史
/usr/share/applications/                         系统级 .desktop
/etc/deepin-version
```

★ = 2026FIC 致命遗漏点（Q6/Q7 因没扫这里全错）

## §3 Ubuntu / GNOME

```
~/.config/dconf/user                             GNOME 配置 (二进制)
~/.local/share/gnome-shell/                      GNOME shell
~/.config/evolution/                             evolution 邮件
~/.config/goa-1.0/                               GNOME Online Accounts
/var/log/auth.log  /var/log/syslog
/var/snap/<app>/current/                         snap 应用配置
```

## §4 KDE

```
~/.config/kdeconnect/                            KDE Connect (手机配对)
~/.local/share/akonadi/                          akonadi 邮件/PIM 数据库
~/.config/kwalletd5/                             KWallet (密码库)
~/.config/baloofilerc                            Baloo 索引
```

## §5 Windows 11/10

```
C:\Users\<user>\NTUSER.DAT                       用户注册表 hive
C:\Users\<user>\AppData\Local\Microsoft\Windows\WebCache\        IE/Edge 索引
C:\Users\<user>\AppData\Roaming\Microsoft\Windows\Recent\        最近文件
C:\Users\<user>\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt  ★
C:\Users\<user>\AppData\Local\Packages\                          UWP/Store 应用
C:\Users\<user>\AppData\Local\ConnectedDevicesPlatform\          Timeline activitiescache.db
C:\$Recycle.Bin\<SID>\                                           回收站
C:\Windows\System32\config\SOFTWARE  SYSTEM  SAM  SECURITY       系统注册表
C:\Windows\Prefetch\                                             prefetch (执行痕迹)
C:\Windows\System32\winevt\Logs\                                 事件日志
C:\Windows\Tasks\  C:\Windows\System32\Tasks\                    计划任务
C:\Users\<user>\AppData\Local\Microsoft\Edge\User Data\Default\  Edge
C:\Users\<user>\AppData\Local\Google\Chrome\User Data\Default\   Chrome
C:\ProgramData\                                                  全局应用数据
C:\Users\<user>\AppData\Local\Microsoft\Windows\INetCache\IE\    IE 缓存
C:\Users\<user>\Documents\WeChat Files\                          WeChat
C:\Users\<user>\Documents\Tencent Files\                         QQ
C:\Users\<user>\AppData\Roaming\Telegram Desktop\tdata\          Telegram
C:\Users\<user>\AppData\Local\Packages\Microsoft.Copilot_*\      Win11 Copilot ★
```

★ = 系统自带 AI / shell 历史，常被忽略

## §6 macOS

```
/Users/<user>/Library/Mail/                      Mail.app
/Users/<user>/Library/Messages/chat.db           iMessage
/Users/<user>/Library/Application Support/       绝大多数应用数据
/Users/<user>/Library/Containers/                沙盒应用
/Users/<user>/Library/Keychains/                 钥匙串
/Users/<user>/.bash_history  .zsh_history
/Users/<user>/Library/Logs/
/private/var/log/
/System/Library/CoreServices/SystemVersion.plist 系统版本
```

## §7 Android

```
/data/data/<pkg>/databases/                      应用 sqlite
/data/data/<pkg>/shared_prefs/                   xml 配置
/data/data/<pkg>/files/                          应用文件
/sdcard/Android/data/<pkg>/                      外置存储
/sdcard/DCIM/  /sdcard/Pictures/  /sdcard/Download/
/data/system/users/<id>/accounts.db              账户
/data/system/packages.xml                        已装应用
/data/misc/wifi/                                 WiFi 配置 (root)
/data/data/com.tencent.mm/                       WeChat
/data/data/com.tencent.mobileqq/                 QQ
/data/data/org.telegram.messenger/               Telegram
/data/data/com.android.providers.contacts/databases/contacts2.db
/data/data/com.android.providers.telephony/databases/mmssms.db
```

## §8 iOS

```
HomeDomain/Library/SMS/sms.db
HomeDomain/Library/AddressBook/AddressBook.sqlitedb
HomeDomain/Library/Calendar/Calendar.sqlitedb
HomeDomain/Library/CallHistoryDB/CallHistory.storedata
HomeDomain/Library/Mail/                         Mail
HomeDomain/Library/Notes/notes.sqlite
WirelessDomain/Library/Databases/CellularUsage.db
RootDomain/Library/Lockdown/                     配对记录
KeychainDomain                                   钥匙串
CameraRollDomain/Media/                          媒体
```

## §9 浏览器（跨 OS）

不同 OS 路径前缀不同，但子结构一致：

```
<browser-profile>/
├── History                         访问/下载/搜索 sqlite
├── Cookies / Network/Cookies       cookies sqlite
├── Login Data                      保存的登录 (DPAPI/NSS 加密)
├── Web Data                        autofill / credit cards
├── Bookmarks                       书签 json
├── Top Sites                       常访问
├── Favicons                        图标
├── Sessions/                       会话恢复
├── Local Storage/leveldb/          window.localStorage
├── Session Storage/                window.sessionStorage
├── IndexedDB/                      indexed db
├── Service Worker/                 PWA / 缓存
├── Cache_Data/                     HTTP cache
└── Extensions/                     已装扩展
```

Firefox 额外：
```
<profile>.default-release/
├── places.sqlite                   history/bookmarks
├── cookies.sqlite
├── formhistory.sqlite
├── logins.json + key4.db           saved password (NSS 加密)
├── cert9.db / pkcs11.txt
└── storage/default/                IndexedDB
```

## §10 即时通讯（跨 OS）

| 应用 | 主数据库 / 关键路径 | 备注 |
|---|---|---|
| WeChat (Win) | `Documents\WeChat Files\<wxid>\Msg\` MSG_*.db (DB Browser + 解密) | 7-zip 隐写 |
| WeChat (Android) | `/data/data/com.tencent.mm/MicroMsg/<MD5>/` EnMicroMsg.db | sqlcipher |
| QQ (Win) | `Documents\Tencent Files\<QQ>\` Msg3.0.db | 数据库加密 |
| Telegram | `tdata/D877F783D5D3EF8C/` (encrypted) | 解密需 local pass |
| WhatsApp (Android) | `/data/data/com.whatsapp/databases/msgstore.db` | crypt14/15 |
| Signal | `/data/data/org.thoughtcrime.securesms/databases/signal.db` | sqlcipher |
| 飞书/Lark | `~/.config/Lark/` `%AppData%\Lark` | leveldb |
| 钉钉 DingTalk | `%AppData%\DingTalk\<staffid>\db\` | sqlite |
| 旺旺/千牛 | `Documents\WangWang\` | profile sqlite |

## §11 系统自带 AI 助手

| OS | 应用 | 关键路径 | 取证关键字段 |
|---|---|---|---|
| **deepin / UOS** | UOS AI | `~/.config/uos-ai*/data.db` | `llm` 表 (provider / apiKey / model) ★ |
| Win11 | Copilot | `%LocalAppData%\Packages\Microsoft.Copilot_*\` | sqlite + chat history |
| macOS | Apple Intelligence (15+) | `~/Library/Containers/com.apple.intelligence/` | encrypted blobs |
| Android | Google AICore / Gemini | `/data/data/com.google.android.aicore/` | local model + chat |
| iOS | Apple Intelligence | `HomeDomain/Library/AppleIntelligence/` | siri suggestions |
| Linux 通用 | 第三方 (Trae / Cursor / VS Code Copilot) | `~/.config/<app>/` | configuration only |

★ = 2026FIC Q6/Q7 答案位置，**优先级最高**

---

## 反模式提醒

- ❌ 只看用户家目录，不看 `/root/`（root 也是真实用户）
- ❌ 看 `~/.bash_history` 看到 `rm -rf` 就放弃，应当看 mtime / 上下文重建时间线
- ❌ 看到中文文件夹名（`/root/文档`）跳过——中文路径常含关键证据
- ❌ 默认 Linux 桌面应用都装在 `/usr/share/applications/`——deepin/UOS 多放在 `/opt/apps/<bundle>`
- ❌ 浏览器只看 History 一个表，不看 Local Storage / IndexedDB / Service Worker（前端密钥常存这里）
