# 2024–2025 取证比赛真题增量笔记（手机 / APK 重点）

> 在 `didctf_writeup_methodology.md` 之上的**增量**——这次专门收录 2024、2025 年新出现、原 KB 未覆盖的新题型与新工具。
>
> 资料来源：
> - 2025 第二届獬豸杯（cnblogs WXjzc / CSDN tummyiii / CSDN BJYBJ / CSDN 2503_91212781）
> - 2025 第五届 FIC 全国网络空间取证大赛初赛（CSDN 2201_75769648）
> - 2025 盘古石杯晋级赛（cnblogs WXjzc）
> - 2024 第二届盘古石杯 / 2024 数证杯决赛 / 2024 第一届长城杯铁人三项
> - 2024 FIC 第四届（已在 didctf_writeup_methodology.md 记录）
>
> **2026 年比赛**：截至 2026 年 5 月，FIC 2026 / 第三届獬豸杯 2026 / 长安杯 2026 等公开 writeup 尚未上线（赛事多在每年 3–6 月间举办、3–6 个月后陆续放出 writeup）；以下增量条目主要以 2025 年题为主，2026 年待赛后补充。

---

## 1. 新题型一览（**这是 2024–2025 年与之前显著不同的部分**）

| 新题型 | 来源 | KB 命中度 | 处置 |
| --- | --- | --- | --- |
| **Flutter/Dart APK 取证（blutter + libapp.so）** | 2025 盘古石晋级赛 APK Q7–Q18 | ❌ 之前完全没写 | §2 新增 |
| **RustDesk 远程工具取证（com.carriez.flutter_hbb）** | 2025 盘古石晋级赛 APK Q1–Q6 | ❌ | §3 新增 |
| **物联网检材（智能冰箱、智能门锁、智能音箱）** | 2025 盘古石晋级赛"物联网取证"独立大类 | ⚠️ `other_smart_devices.md` 偏弱 | §4 新增 |
| **小米相册缓存（com.miui.gallery）保留已删截图** | 2025 獬豸杯（非预期解） | ⚠️ 没专门列 | §5 新增 |
| **Mac 程序逆向 / PyInstaller 解包** | 2025 盘古石晋级赛"苹果应用取证" | ⚠️ ios_* 没覆盖 macOS | §6 新增 |
| **国产会议软件取证（网易会议 / 银联会议 / 腾讯会议 / 钉钉视频会议）** | 2025 獬豸杯、2025 盘古石、2025 FIC | ❌ | §7 新增 |
| **Skype 群聊取证（盘古石阅读器）** | 2023 第七届蓝帽杯（仍参考） | ⚠️ | §7 |
| **K8s 集群 + Docker 容器检材** | 2025 獬豸杯、2025 FIC、2024 长城杯 | 服务器侧，简记 §8 | §8 简记 |
| **区块链域名 / Web3 DNS（HNS/ENS/Unstoppable）** | 2025 FIC 互联网部分 | ❌ | §9 简记 |
| **借贷 / 打金 / 盲盒 / 加密货币聚合平台** | 2025 獬豸杯 / 2025 盘古石 | 多见 | §10 简记 |
| **第三方备忘录 / 笔记 App 数据库（com.bijoysingh.yang/note-database）** | 2025 FIC 检材二 Q2 | ⚠️ | §11 |
| **DJI 无人机 / 大疆设备取证** | 2024–2025 多赛 | ⚠️ 已有 `dji_q10.py` 工具但缺方法论 | §12 |
| **dd 后缀实为 zip/tar/分卷压缩包**（命名陷阱） | 2025 獬豸杯 / 2025 FIC | ❌ | §13 |
| **图片 OCR + 推断题**（截图日期+N天） | 2025 FIC 检材二 Q5 | ❌ | §14 |
| **VeraCrypt 容器藏在 RAR + RAR 密码藏在二维码 + 二维码藏在 stegsolve 异色通道** | 2025 FIC 检材二 Q9–Q11 | ⚠️ 套娃方法已写但工具链具体到 stegsolve 异色通道这一步要补 | §14 |

---

## 2. Flutter/Dart APK 取证（**2025 年最重要的新点**）

### 2.1 Flutter APK 特征识别
```bash
# 看 lib 目录是否有 libapp.so + libflutter.so
unzip -l app.apk | grep -E 'lib/.*\.so'
# 典型：
# lib/arm64-v8a/libflutter.so       <-- Flutter 引擎
# lib/arm64-v8a/libapp.so           <-- 业务逻辑（Dart AOT Snapshot）
```
- **AndroidManifest 主 Activity 多为 `io.flutter.embedding.android.FlutterActivity` 或 `MainActivity extends FlutterActivity`**。
- jadx 反编 dex 几乎看不到业务逻辑——**全部业务在 `libapp.so` 的 Dart Snapshot 里**。
- 这是导致很多取证人员"反编 APK 看不到关键代码"的常见现象。

### 2.2 blutter 反编 Dart Snapshot
> **blutter** = Dart Snapshot 反编工具，输出 ASM + objs.txt（类/方法/字符串/常量），并自动生成 frida hook 模板。

```bash
git clone https://github.com/worawit/blutter
cd blutter && pip install -r requirements.txt
python3 blutter.py /path/to/apk/lib/arm64-v8a /path/to/output

# 输出：
# output/asm/        Dart 字节码反汇编
# output/objs.txt    所有类/方法/字符串/常量
# output/blutter_frida.js   自动生成 frida hook 模板
# output/ida_script/        IDA 脚本
```

**实战搜关键词**：
```bash
grep -E 'recordings|record|delay|key|iv|aes|salsa|rc4' output/objs.txt
grep -E 'dB|decibel|second|threshold' output/objs.txt
```

### 2.3 Frida 配 blutter 生成的 hook 模板
- blutter 生成的 `blutter_frida.js` 会列出每个 Dart 函数对应 `libapp.so` 的偏移；
- 改写成 `Interceptor.attach(libapp.add(0xXXXX), {...})` 在 `onLeave` 拿返回值；
- 关键点：**Dart 对象的指针需要通过 `getTaggedObjectValue()` 解出**（blutter 模板自带），且**对最新 Flutter 版本要把 `decompressPointer` 注释掉**（盘古石晋级赛 writeup 踩坑点）。

```javascript
function onLibappLoaded() {
    const fn_addr = 0x394a84;  // blutter 输出里找到的函数偏移
    Interceptor.attach(libapp.add(fn_addr), {
        onLeave: function (retval) {
            console.log('videoKeyByte =>', getTaggedObjectValue(retval));
        }
    });
}

function tryLoadLibapp() {
    const libapp = Module.findBaseAddress('libapp.so');
    if (libapp === null) setTimeout(tryLoadLibapp, 500);
    else onLibappLoaded();
}
tryLoadLibapp();
```

### 2.4 Flutter APK 题型套路
| 题问 | 怎么答 |
| --- | --- |
| 主入口 / Activity | manifest 里 `MainActivity` 仍存在（Flutter 也要个壳子 Activity） |
| 签名算法 | `apksigner verify --print-certs` —— **与 Flutter 无关**，仍是 SHA256withRSA 等 |
| 黑幕字符串 / UI 文本 | blutter 输出 `objs.txt` 内 String pool |
| 录音/录像门限 dB / 延迟秒数 | objs.txt 内 double 常量 / int 常量 |
| 加密算法（AES-256/Salsa20/RC4） | objs.txt 搜 `aes/salsa/rc4` + 找 32B/16B key 类 |
| 加密 key/iv 具体值 | frida hook 对应函数 `onLeave` 拿 |
| 密钥最后一位 | frida 拿到 key 数组后取末尾字节 |

### 2.5 Dart 反编 vs 传统 dex 反编对照
| 项 | 传统 Java APK | Flutter APK |
| --- | --- | --- |
| 反编工具 | jadx / GDA / JEB | **blutter**（Dart） + IDA / Ghidra（看 libapp.so） |
| 业务代码位置 | `classes*.dex` | `lib/<abi>/libapp.so` |
| Hook 框架对象 | `Java.use(...)` | `Module.findBaseAddress('libapp.so').add(0xXXXX)` |
| 字符串明文 | dex 内 string table | libapp.so 的 String pool（blutter objs.txt） |
| 加固/反 hook | 360 / 梆梆 / 爱加密 | obfuscated Flutter（`flutter build apk --obfuscate --split-debug-info`） |

### 2.6 React Native APK（**类比补充**）
> 没在 2024–2025 真题直接出现，但灰产用很多，备查：
- 特征：`assets/index.android.bundle`（JS bundle）+ `lib/*/libreactnativejni.so`。
- 反编：直接 `unzip` 拿 `index.android.bundle`，用 `react-native-decompiler` 还原。
- 加固版（hermes 编译为 hbc）：用 `hbctool` / `hermes-dec`。

---

## 3. RustDesk 远程工具取证（**2025 盘古石晋级赛**）

### 3.1 RustDesk 识别
- 包名：**`com.carriez.flutter_hbb`**（开源 RustDesk 安卓客户端的默认包名；自编译会改）。
- 是 **Flutter 应用**（参 §2），所以业务逻辑在 libapp.so + libhbb.so。
- 进程 / native 库：`librustdesk.so`、`libhbb.so`。

### 3.2 关键配置 / 取证字段
| 题问 | 文件路径 / 字段 |
| --- | --- |
| 中继服务器 IP / 域名（custom-rendezvous-server） | `data/com.carriez.flutter_hbb/files/RustDesk/config/RustDesk.toml` 或 SharedPreferences `<package>_preferences.xml` |
| ID 服务器端口（默认 21116） | 同上 toml `rendezvous-server` |
| 中继服务器 Key（pub key, base64） | 同上 toml `key` 字段 |
| 已收藏的远程 ID | `RustDesk.toml` 内 `fav` 列表，或 `peers.json` |
| 远控历史 + 设备型号 | `RustDesk_*.toml` 多个文件，文件名含 peer ID |
| 录像 / 文件传输历史 | `data/com.carriez.flutter_hbb/files/RustDesk/files/` |

```bash
# 找配置
find data/com.carriez.flutter_hbb -name "*.toml" -o -name "peers.json"
# 看 toml
cat data/com.carriez.flutter_hbb/files/RustDesk/config/RustDesk.toml
```

### 3.3 类似产品对照（赛场易混淆）
| 产品 | 包名 |
| --- | --- |
| RustDesk | `com.carriez.flutter_hbb` |
| ToDesk | `com.todesk.android` |
| AnyDesk | `com.anydesk.anydeskandroid` |
| TeamViewer QuickSupport | `com.teamviewer.quicksupport.market` |
| 向日葵 | `com.oray.sunlogin` |
| 网易UU远程 | `com.netease.uu.remote` |

> 国产/开源远控只有 RustDesk 是 Flutter 写的，其他多是原生 Java/Kotlin。

---

## 4. 物联网（IoT）检材：智能冰箱 / 智能门锁 / 智能音箱

> 2025 盘古石晋级赛把 IoT 单列大类，含 11 题。原 `other_smart_devices.md` 偏向手机 OS（鸿蒙、Tizen）；IoT 设备需单独考虑。

### 4.1 IoT 检材类型与镜像格式
| 设备 | 常见镜像形式 | 关键文件系统 |
| --- | --- | --- |
| 智能冰箱（华凌/小米/海尔/美的） | NAND raw / E01 / Buildroot | squashfs + ubifs + Linux rootfs |
| 智能门锁（小米/凯迪仕/鹿客） | SPI flash dump | LittleFS / FAT16 / 厂商私有 |
| 智能音箱（小爱 / 天猫精灵 / 小度） | Android 子集 | ext4 + 厂商分区 |
| 米家网关 / Hub | OpenWrt 派生 | squashfs + jffs2 |
| 智能摄像头（海康/萤石/小米） | DD raw + .E01 | YAFFS2 / squashfs |
| 行车记录仪 / 运动相机（DJI/小米/Insta360） | FAT32 SD 卡 | + 厂商日志 |

### 4.2 取证关键数据
| 题问 | 来源 |
| --- | --- |
| 品牌 / 型号 / UUID | `/etc/os-release`、`/etc/board.json`、`/system/product`、设备出厂二维码 |
| 配对账号（小米账号 / 米家） | `/var/db/miio.json` / `/data/mihome/` / SQLite 内 `mi_account` |
| 默认存储图片数 | 配置 JSON 里 `max_pic` / `max_capture` |
| 已存图片内容 | `/data/pic/` `/mnt/sd/DCIM/` |
| 隐藏分区内容 | `binwalk -e firmware.bin` 解嵌 |
| 嫌疑人图片 MD5 | 直接 `md5sum`；注意 EXIF 是否被改 |
| 开门 / 操作记录时间 | logd / journald / `/data/log/event.log` 厂商私有；门锁多用 `eventid + uts_time` 二进制日志 |
| 默认图片大小限制 | 配置或 nginx-upload-max-size 类 |

### 4.3 通用 IoT 取证流程
```bash
# 1. 识别文件系统
binwalk -B firmware.bin
# 2. 提取
binwalk -e firmware.bin
# 或精准抽 squashfs
unsquashfs -d out filesystem.squashfs
# 3. 看启动脚本
cat out/etc/init.d/* out/etc/rc.local
# 4. 看通讯
strings out/usr/bin/* | grep -E 'mqtt|http|aliyun|miio|tuya|aws'
# 5. SQLite/JSON 状态
find out -name "*.db" -o -name "*.json" -o -name "*.sqlite"
```

### 4.4 行车记录仪 / 监控（**2025 盘古石**"video.E01 被修改的录像 md5"）
- 镜像 E01 → FTK Imager 或 ewfmount 挂载；
- 视频帧级取证：`ffmpeg -i video.mp4 -vf "select='eq(pict_type,I)'" -vsync vfr i_frame_%04d.png`；
- 检测篡改：看视频元数据时间戳与文件 mtime/atime/ctime 是否一致；用 `mediainfo`/`ffprobe`/`exiftool` 看 `creation_time` 是否被改。
- 厂商私有日志：DJI 飞控 `.DAT`、小米米家 `event.bin`，需要解析工具或 frida hook。

### 4.5 与 `other_smart_devices.md` 的关系
- 那篇主要写"非主流手机 OS"（鸿蒙/Tizen/KaiOS）；
- 本节写"非手机的智能设备"；
- 后续可考虑独立 `iot_forensics.md`。

---

## 5. **Android 速胜技巧：缓存目录保留已删数据**

### 5.1 小米相册缓存（**2025 獬豸杯非预期解，直接打开 13 题里 3 题答案**）
```
/media/0/Android/data/com.miui.gallery/files/gallery_disk_cache/full_size/<sha256>.0
/media/0/Android/data/com.miui.gallery/files/gallery_disk_cache/thumbnail/...
```
- 文件名是图片内容的 SHA256；
- **删除原图后缓存仍保留**；
- 截图、聊天图、相机原图都会经过这里。

### 5.2 同类缓存路径（速查）
| 应用 | 缓存路径 | 备注 |
| --- | --- | --- |
| 小米相册 | `Android/data/com.miui.gallery/files/gallery_disk_cache/` | 删除照片后仍存 |
| 华为图库 | `Android/data/com.huawei.photos/cache/` 或 `data/com.android.gallery3d/cache/` | 同上 |
| Vivo 图库 | `Android/data/com.vivo.gallery/files/` | |
| OPPO 相册 | `Android/data/com.coloros.gallery3d/cache/` | |
| 微信图片 | `data/com.tencent.mm/MicroMsg/<hash>/image2/` 双层 hex 子目录 + `.dat` 异或加密；缓存 `Android/data/com.tencent.mm/cache/` | 已写在 wechat_deep_dive |
| QQ 图片 | `Android/data/com.tencent.mobileqq/Tencent/MobileQQ/diskcache/` | |
| WhatsApp 缩略图 | `Android/media/com.whatsapp/WhatsApp/Media/.thumbnails/` | |
| Telegram 缓存 | `Android/data/org.telegram.messenger/cache/` | |
| Chrome 缓存 | `Android/data/com.android.chrome/cache/Cache/Cache_Data/` | |
| 抖音缓存 | `Android/data/com.ss.android.ugc.aweme/cache/` `files/Awemes/` | |
| 快手缓存 | `Android/data/com.smile.gifmaker/cache/.video_cache/` | |
| 高德地图 | `Android/data/com.autonavi.minimap/files/autonavi/` | 含搜索历史 |

> **取证速胜**：先翻这些缓存目录再翻主沙盒；尤其是 `gallery_disk_cache`、`image2`，能直接拿"已删聊天图"。

### 5.3 dd 后缀的"命名陷阱"
- 2025 獬豸杯检材命名为 `xxx.dd`，实际是 **tar 包**（`file xxx.dd` 报 `POSIX tar archive`）；
- 2025 FIC 类似：`手机.dd` 实际是 zip；
- **第一步永远先 `file` + `binwalk` 看真实格式**，别被扩展名骗。
```bash
file xxx.dd
binwalk xxx.dd | head
xxd xxx.dd | head -2  # 看 magic：tar 是 0x75 0x73 0x74 0x61 0x72（"ustar"）于 257 字节偏移
```

---

## 6. macOS / Mac 程序取证（**2025 盘古石晋级赛"苹果应用取证"**）

> 题型：给 Mac 镜像 + Mac 电脑里某个加密程序，问 seed / 字段顺序 / 函数名错位 / 故意延迟值。这是把"PC 镜像取证"+"逆向 macOS Python 打包程序"结合。

### 6.1 macOS 程序类型识别
| 类型 | 识别 |
| --- | --- |
| 原生 Mach-O 二进制 | `file Foo` 显示 `Mach-O 64-bit executable arm64/x86_64` |
| `.app` Bundle | 文件夹结构 `Foo.app/Contents/MacOS/Foo` + Info.plist |
| Python 打包（PyInstaller / py2app / Nuitka） | Bundle 内有 `Resources/lib/python3.X/` 或 `_internal/`，多伴 `*.pyc` |
| Electron | Bundle 内 `Resources/app.asar` |
| Java | `Foo.app/Contents/MacOS/JavaApplicationStub` + `Resources/Java/` |
| Go 二进制 | strings 内 `Go build ID` |

### 6.2 PyInstaller 解包（**赛场最常见**）
```bash
# 1. 提取 PyInstaller archive
git clone https://github.com/extremecoders-re/pyinstxtractor
python3 pyinstxtractor.py Foo                 # 或 py2app 主二进制

# 2. 拿到 .pyc（通常对应 Python 3.X）
# 3. 反编译
pip install decompyle3 uncompyle6
decompyle3 main.pyc > main.py
# Python 3.10+ 用 pycdc / pylingual

# 4. 确认 Python 版本
xxd Foo.exe | head -1  # PyInstaller magic 后含版本

# 5. 看 _crypt 模块 / 自定义加密类
grep -rEi 'seed|random|hashlib|cryptography|cipher|key|iv|delay|sleep' src/
```

### 6.3 真题映射
| 题问 | 工具/技巧 |
| --- | --- |
| "种子是多少" | 反编 main.py，搜 `seed(`、`random.seed(`，常量值（真题答案 `42`） |
| "文件头部字段顺序" | 看 `def encrypt`/`pack` 函数里 struct 拼接顺序（如 `iv + encrypted + data`） |
| "函数名与功能不符" | 阅读所有命名为 `_descramble_key` `_obfuscate` `_decode` 的函数，**实际未调用 / 空实现** 的就是答案 |
| "故意减慢加密的延迟值" | 搜 `time.sleep(` |

### 6.4 macOS 镜像通用取证
- DMG / E01 → `hdiutil attach -readonly` 或 FTK Imager；
- APFS 解密：用户密码 / Recovery Key；商业工具 BlackBag MacQuisition / AXIOM。
- 关键路径：
  - `~/Library/Application Support/` 各 App 数据
  - `~/Library/Preferences/*.plist`
  - `~/Library/Containers/com.<app>/Data/`（沙盒）
  - `~/.zsh_history` `~/.bash_history`
  - `/private/var/log/` + `log show --info --debug`（unified log）
- iMessage / 通讯录 / 邮件：`~/Library/Messages/chat.db` `~/Library/Application Support/AddressBook/`

> macOS 取证笔记可独立成 `macos_forensics.md`，本文先简记。

---

## 7. 国产会议 / 通讯软件取证速查

### 7.1 网易会议（YunXin / 网易会议 / 网易瑶池）
- 包名：`com.netease.meetinglib` / `com.netease.meeting`；
- 个人会议号：`/data/<pkg>/shared_prefs/*.xml` 内 `personal_meeting_number`；
- 会议历史：`/data/<pkg>/databases/meeting_history.db` 表 `meeting_record`；
- 账号绑定：`account.db` / SP 文件 `nm_user_id`、`nm_phone`。

### 7.2 银联会议
- 包名：`com.unionpay.cloudmeeting` / 类似；
- 国产银联系产品，赛场近期出现（2025 盘古石）；
- 取证字段：会议邀请、参会人手机号、共享文件、屏幕共享截图。

### 7.3 腾讯会议（VooV）
- 包名：`com.tencent.wemeet.app`；
- 数据库：`databases/voov_meeting.db`；
- 录制视频：`Android/data/com.tencent.wemeet.app/files/recordings/`；
- 个人会议号 / 头像 / 绑定手机号：SP `wemeet_user_pref.xml`。

### 7.4 钉钉视频会议 / 企业微信会议
- 钉钉：`com.alibaba.android.rimet`，会议在 `databases/im.db` 表 `meeting_*`；
- 企业微信：`com.tencent.wework`，独立 db `meeting.db`。

### 7.5 飞书 / Lark
- 包名：`com.ss.android.lark`；
- 端到端加密相对最强，沙盒内多为加密 + LevelDB。

### 7.6 Skype / Teams（盘古石阅读器场景）
- Skype 群聊：直接用盘古石阅读器搜，群聊里**快递单号、电话、地址常被忽略**，是赛点。

### 7.7 取证比赛该问的
- 个人会议号 / 默认会议号
- 某时刻参与的会议号 + 主持人 + 参会名单
- 会议聊天 / 会议文件 / 会议录制
- 入会方式（密码 / 链接）
- 跨设备同账号其他登录设备 ID

---

## 8. K8s / Docker 检材简记（手机题挂钩部分）

> 2024 长城杯铁人三项、2025 獬豸杯 k8s 服务器、2025 盘古石服务器都出过；与手机题挂钩的常是"手机里 App 回传地址 → 服务器集群里同 IP/域名的容器"。

### 8.1 K8s 检材取证关键命令
```bash
# 集群信息
kubectl version
kubectl get nodes -o wide
kubectl get ns
kubectl get pods --all-namespaces -o wide
# CNI 插件
kubectl get pods -n kube-system | grep -iE 'flannel|calico|cilium|weave'
kubectl describe ds -n kube-system <calico-node|kube-flannel-ds>
# 创建时间
kubectl get cm cluster-info -n kube-public -o yaml
kubectl describe ns default | grep CreationTimestamp
```

### 8.2 Docker 检材
```bash
docker ps -a
docker inspect <id>
docker images
# 容器内 mongodb / mysql / postgres 直连
docker exec -it <mongo> mongosh
docker exec -it <mysql> mysql -uroot -p
# 把容器导出为 tar 离线分析
docker export <id> > c.tar; tar -xf c.tar -C c/
```

### 8.3 离线集群（无 kubectl 环境）
- 直接读 `/var/lib/etcd/` 数据库 → `etcdctl snapshot restore` → 恢复后再用 kubectl 模式分析；
- 或直接 `cat /etc/kubernetes/manifests/*.yaml`。

> 详细见 `server_forensics.md`（如已建）/ 待建。

---

## 9. Web3 / 区块链域名 / 助记词题型

### 9.1 区块链域名（**2025 FIC 互联网部分新增**）
| 服务 | 顶级域 | 注册区块链 | 解析方式 |
| --- | --- | --- | --- |
| Handshake (HNS) | 任意（用户竞拍） | HNS 链 | DNS-over-HNS / `dig @hs-resolver` |
| ENS (Ethereum Name Service) | `.eth` | 以太坊 | resolve via `0x3671...`合约；ens.domains |
| Unstoppable Domains | `.crypto` `.x` `.nft` `.bitcoin` `.wallet` `.dao` `.888` `.zil` | Polygon/ETH | unstoppabledomains.com 解析 |
| SpaceID | `.bnb` `.arb` | BNB/Arbitrum | space.id |
| .sol | Solana 域名 | Solana | bonfida |

**解题套路**：题问"该域名顶级域名在哪个区块链注册"→ 把顶级域和上表对照即得。

### 9.2 助记词 / 钱包题
- 12/24 词英文 BIP39 标准词汇；可放在 `.txt` `.docx` `.note` 任何文档里；
- 关键字搜：`mnemonic`、`seed phrase`、`recovery phrase`、`助记词`、`种子`、`钱包`；
- 常见钱包路径（移动端）：
  - imToken: `data/im.token.app/databases/`；助记词加密本地储存。
  - TokenPocket: `data/vip.mytokenpocket/`；
  - Trust Wallet: `data/com.wallet.crypto.trustapp/`；
  - MetaMask Mobile: `data/io.metamask/`；keychain 内 vault.json。
- PC 浏览器扩展：`%LOCALAPPDATA%\Google\Chrome\User Data\Default\Local Extension Settings\<extension_id>\` 下 LevelDB。
- 见 `crypto_currency_forensics.md`（如已建）。

---

## 10. 灰产平台共性（打金 / 借贷 / 盲盒 / 投资理财 / 直播）

> 2024–2025 年比赛清一色"灰产平台 + 嫌疑人手机 + 服务器集群"三件套。

| 平台类型 | 特征数据 | 必查表 |
| --- | --- | --- |
| **打金游戏（金币提现）** | 用户充值 / 累计产量 / 推广 | `user`、`order`、`referral`、`withdraw` |
| **借贷（高利贷 / 套路贷）** | 借款订单 / 实际到账 / 砍头息 / 逾期罚金 | `loan_order`、`bank_card`、`user`、`sms_log` |
| **盲盒** | 商品库 / 概率配置 / 中奖记录 / 提现 | `product`、`box_open_log`、`order` |
| **投资理财（虚拟币 / 期货）** | 充值 / 提现 / 会员等级 | `user`、`recharge`、`withdraw`、`level` |
| **直播（烟雨直播 / 蜜桃 / 桃花）** | 主播 / 用户 / 礼物 / 等级 | `live`、`gift_log`、`user`、`level` |
| **新葡京 / 棋牌博彩** | 房间 / 战绩 / 提现 | `room`、`game_record`、`pay_order` |

**通用解法**：
1. 先在嫌疑人手机里找 App → 包名 → 装到模拟器看登录账号；
2. 拿 App 反编看 `apiserver`；
3. 服务器检材里找同域名容器；
4. 进容器拿 mysql/mongo 数据；
5. 关键字段用 SQL `JOIN` 关联用户。

```sql
-- 例：找累计产量最高用户
SELECT u.phone, SUM(o.amount) AS total
FROM user u JOIN order o ON o.uid=u.id
WHERE u.phone='13067137585'
GROUP BY u.phone;
```

---

## 11. 第三方备忘录 / 笔记 App（**易被忽略**）

| App | 包名 | 密码/重要文档常埋的位置 |
| --- | --- | --- |
| 系统备忘录（小米） | `com.miui.notes` | `databases/note.db` 表 `notes` |
| 系统备忘录（华为） | `com.example.android.notepad` / `com.huawei.notepad` | 同上 |
| 系统备忘录（vivo） | `com.android.notes` | 同上 |
| Bijoy Note（日记） | `com.bijoysingh.yang` | `databases/note-database` —— **2025 FIC 检材二 Q2 嫌疑人 PC 开机密码就藏这里** |
| Color Note | `com.socialnmobile.dictapps.notepad.color.note` | `databases/colornote.db` |
| Evernote / 印象笔记 | `com.evernote` / `com.yinxiang.app` | `databases/user-*.db` |
| 有道云笔记 | `com.youdao.note` | `databases/yndb.db` |
| 飞书文档 / Notion | 见对应包 | LevelDB |
| 系统便签桌面小组件 | 桌面布局 db | 漏题点 |

> **题型套路**：嫌疑人 PC 密码 / 暗号 / 钱包密钥 / 联系人备注，常埋在备忘录里，且不是系统备忘录而是第三方装的小众 App；务必扫所有包名带 "note/notes/memo/diary/journal" 的应用。

---

## 12. DJI 无人机 / 大疆设备取证（占位）

> 工作区已有 `dji_q10.py`，方法论待补到独立文件 `dji_forensics.md`：
- DAT 飞控日志解析（DatCon、CsvView、PhantomHelp）
- 视频元数据中 GPS / 海拔 / 飞控时间
- 遥控器 / DJI Fly App 痕迹（`com.dji.fly`、`com.dji.go.v5`）
- 账号绑定与云端日志

---

## 13. "命名陷阱"清单

| 题目检材命名 | 实际格式 | 识别 |
| --- | --- | --- |
| `xxx.dd` | tar / zip | `file` 见 `POSIX tar` 或 `Zip archive` |
| `xxx.E01` | EWF（正常） | FTK Imager 直接挂 |
| `xxx.001` | raw / 分卷 | 看大小是否整 GB；分卷续 `.002` `.003` |
| `xxx.bin` | VeraCrypt / 镜像 / 固件 | binwalk + entropy |
| `xxx.txt` | VeraCrypt 容器 | entropy ≈ 7.99 |
| `xxx.jpg` | 实是 zip / rar 隐藏（魔数后置） | `binwalk -e` |
| `xxx.png` | 末尾追加 zip / 文本 | strings 末尾 |
| `xxx.docx`/`.xlsx` | zip 解开看 `word/document.xml`、`xl/sharedStrings.xml` | `unzip -l` |
| `xxx.apk` | zip 解开 + 反编 | jadx |

---

## 14. 套娃式 stego + VeraCrypt（**2025 FIC 检材二经典链**）

> 完整链：聊天图缩略图 → 同目录原图 png → stegsolve 异色通道看到二维码 → 扫码得 RAR 密码 → 解 RAR 拿欠条文件（实为 VeraCrypt 容器）→ 解 1.png 反色得容器密码 → 挂载得欠条全名 + 金额。

**工具链**：
```bash
# 1. 找原图（缩略图同目录）
ls Android/data/com.tencent.mm/MicroMsg/<hash>/image2/.../

# 2. stegsolve 异色通道
java -jar stegsolve.jar
# 切换 Red/Green/Blue/LSB 各 plane → 找出现二维码的 plane

# 3. 二维码解码
zbarimg qr.png
# 或在线 zxing.org

# 4. RAR 解压
unrar x -p<password> 欠条.rar

# 5. 容器密码反色
python3 -c "from PIL import Image,ImageOps; img=Image.open('1.png'); ImageOps.invert(img.convert('RGB')).save('1_inv.png')"

# 6. VeraCrypt 挂载
veracrypt --mount 欠条 --password='#!@KE2sax@!da0h5hghg34&@' /mnt/v
```

**通用题型路径**：聊天图 → 原图（缓存目录） → 异色通道二维码 → RAR 密码 → 容器（VeraCrypt/BitLocker） → 容器密码（反色/隐写/字典） → 内部文档（excel/docx 含答案）。

---

## 15. 工具更新（2024–2025 增）

| 工具 | 用途 | 项目 |
| --- | --- | --- |
| **blutter** | Flutter/Dart APK 反编 + frida hook 模板 | github.com/worawit/blutter |
| **hbctool** / **hermes-dec** | React Native Hermes 字节码反编 | github.com/bongtrop/hbctool |
| **pyinstxtractor-ng** | PyInstaller 解包（升级版） | github.com/pyinstxtractor/pyinstxtractor-ng |
| **pylingual** | Python 3.10+ 反编 | github.com/syssec-utd/pylingual |
| **stegsolve** | 图片异色通道 / LSB 浏览（赛场必备） | wbailey/StegSolve.jar |
| **stegseek** | steghide 字典爆破 | github.com/RickdeJager/stegseek |
| **盘古石阅读器** | 比赛官方常用 | 已在 `android_analysis_environment.md` |
| **火眼大师 6.x（2025）** | 国密 SM2/SM3/SM4 + Flutter App 自动识别 | 商业 |
| **取证大师 2025** | 加强 IoT + 区块链 | 商业 |
| **Cellebrite UFED 8.x** | iOS 17/18 物理；Android 14/15 全盘 | 商业 |
| **iLEAPP / ALEAPP 2025** | 持续更新支持新 App | 开源 |

---

## 16. 与已有 KB 的关系

| 本文新增章节 | 应回插 / 关联到 |
| --- | --- |
| §2 Flutter/Dart | `apk_internals.md`（新增"应用类型：Flutter/RN"小节） + `android_reverse_analysis.md`（新增"非 Java APK 反编"） + `hook_techniques.md`（新增 Dart hook 模板） |
| §3 RustDesk | `popular_apps_forensics.md`（远控 App 单列） |
| §4 IoT | 独立 `iot_forensics.md`（待建） |
| §5 缓存路径 | `popular_apps_forensics.md` + `wechat_deep_dive.md` |
| §6 macOS 程序 | 独立 `macos_forensics.md`（待建） |
| §7 国产会议 | `popular_apps_forensics.md` |
| §8 K8s/Docker | 独立 `server_forensics.md`（待建） |
| §9 Web3 | 独立 `crypto_currency_forensics.md` |
| §11 备忘录 | `popular_apps_forensics.md` |
| §12 DJI | 独立 `dji_forensics.md`（待建） |
| §13 命名陷阱 | `quick_reference.md` |
| §14 套娃 stego | `didctf_writeup_methodology.md` §7.6 已起头，本节是完整链 |

---

## 17. 待补 / 2026 等待

- **2026 FIC 初赛 writeup 已发布（2026-05-07）→ 详见 `fic2026_writeup.md`**
  - 新增题型：Hybrid WebView APK / 移动端本地 LLM（PocketPal）/ DJI 飞行日志县域定位 / Native XTEA / Win32 GUI 加密程序（独立大类）/ 自研聊天 App 双库密码=文件名
- 第三届獬豸杯 2026 / 长安杯 2026 / 盘古石 2026 / 蓝帽杯 2026（暂无公开 writeup，预计 2026 H2 发布）
- iOS 18+ Apple Intelligence 取证
- 鸿蒙 NEXT 5（HarmonyOS 5）独立态系下取证（无 Android 兼容层）
- AI 智能体 / Agent 留痕（赛事新趋势）
- 车机取证（华为 ADS / 鸿蒙座舱 / 特斯拉 / 蔚来 / 理想）—— 2024 已小范围出现

---

## 18. 引用真题

- **2025 第二届獬豸杯**：手机（小米相册缓存非预期）+ 计算机（澳门新葡京 APK + 360加固宝识别）+ k8s 集群（打金 + 借贷 + 盲盒平台）
- **2025 第五届 FIC 初赛**：网页快照（OBS 录像）+ 手机（备忘录密码 + 微信 EnMicroMsg + RAR/VeraCrypt 套娃）+ 介质（向日葵远控日志 + 钱包助记词）+ 互联网（Web3 域名 + Github + DOTA 英雄）
- **2025 盘古石晋级赛**：手机（IDFA + Telegram 卸载时间）+ APK（RustDesk + Flutter 录音监听 App）+ 计算机（伪造身份证 + 智能门锁品牌）+ 苹果应用（PyInstaller 加密程序）+ 服务器（Docker 网盘 + 投资理财）+ 物联网（智能冰箱）+ 数据分析（成员关系图）
- **2024 第二届盘古石杯**：iOS 物理 + 加密容器 + AI 换脸（已记录于 didctf_writeup_methodology.md）
- **2024 数证杯决赛**：流量分析 + 手机
- **2024 第一届长城杯铁人三项**：取证溯源 + Web 入侵
