# 安卓分析基础环境（取证比赛工作台）

> 适用：电子数据取证比赛中需要对 APK / 已装 App / 设备镜像做"分析、提数据、解密、定位证据"时的环境准备清单。
>
> **原则**：取证比赛≠完整逆向。能在 5–30 分钟内拿到题目答案的方案优先；商业取证软件 + 半手工脚本是常态。深度逆向（VMP/壳）放到最后，多数题目用不到。

---

## 1. 比赛中"安卓分析"任务三类

| 任务 | 时间 | 工具优先级 |
| --- | --- | --- |
| **A. 检材数据提取**（已有镜像/备份/dump） | 5–15 分钟 | 商业取证软件（盘古石/美亚/Volcano/Cellebrite/iLEAPP/ALEAPP） |
| **B. 应用数据/数据库分析** | 10–40 分钟 | DB Browser / sqlitebrowser / 手写 SQL / Python + AndroGuard |
| **C. APK/SO 反编译/Hook 拿密钥** | 30 分钟–几小时 | jadx + frida + IDA / GDA |

**取证比赛环境配置思路**：
1. **必备**（每场必用）：商业全功能软件 + ADB + jadx + sqlite + Python 取证库
2. **常备**（看题选用）：Frida + 一台 root 真机 + 一台模拟器
3. **进阶**（深度题）：IDA Pro / Ghidra / FART 内核 / OLLVM 解平坦化脚本

---

## 2. 主机基础环境

### 2.1 推荐操作系统组合
- **Windows 10/11**（主战场）：跑商业软件（盘古石/美亚/X-Ways/Volcano/UFED）。
- **Linux 子系统 / 双系统 Ubuntu**：跑 ALEAPP / iLEAPP / autopsy / 自写脚本 / qemu 系镜像挂载。
- **macOS（可选）**：iOS 配合，对 Android 没必要。

### 2.2 Python 取证库（**几乎每场都用**）
```bash
pip install androguard apkid frida frida-tools objection
pip install plistlib pyesedb pylnk3 libregf-python
pip install ssdeep tlsh pillow imagehash
pip install plyvel mmkv  blackboxprotobuf  pyfleece
pip install pycryptodomex pycryptodome
pip install pandas openpyxl jupyterlab
pip install ileapp aleapp                # 一键解析 iOS/Android 备份
```

### 2.3 Java（**必装**）
- JDK 11 或 17（Android Studio 推荐 17）。
- 配 `JAVA_HOME` + PATH。
- 用途：apksigner / keytool / apktool / jadx / smali/baksmali。

### 2.4 Android SDK 命令行工具（**只装命令行就够，不要装整个 Android Studio**）
- 下载：Google 官方 cmdline-tools。
- 配 `ANDROID_HOME` + `PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\build-tools\<ver>`。
- 装：
  ```bash
  sdkmanager --install "platform-tools" "build-tools;34.0.0" "platforms;android-34"
  ```
- 关键二进制：`adb`、`fastboot`、`aapt`、`aapt2`、`apksigner`、`zipalign`。

> **不装 Android Studio**：取证比赛不写代码，省 10GB 磁盘 + 启动慢。

### 2.5 反编译/反汇编三件套
| 工具 | 用途 | 备注 |
| --- | --- | --- |
| **jadx-gui** / **jadx** | dex → Java | **首选**；GUI 直接搜字符串 |
| **GDA**（国产） | dex → Java | 中文环境友好；jadx 反不出来时备选 |
| **apktool** | APK 资源/Manifest 解码 | 不解 dex |
| **smali / baksmali** | dex ↔ smali 汇编 | 改 smali 重打包用 |
| **IDA Pro** | so 反汇编 + 伪 C | 商业，正版贵；社区版亦可 |
| **Ghidra** | 同上 + 免费 | NSA 开源 |
| **GDA**（含 SO 模式）/ **CFF Explorer** / **010 Editor** | 辅助 | |

### 2.6 取证商业软件（按比赛常配）
| 软件 | 用途 |
| --- | --- |
| **盘古石**（PangGuShi） | 国内主流；安卓物理/逻辑/全文件提取 + 解析 |
| **美亚柏科 取证大师 / DC-4501** | 国内取证标配 |
| **效率源 SalvationDATA SmartPhone Forensics** | 国产 |
| **Cellebrite UFED / Inspector / Reader** | 国际首选 |
| **Magnet AXIOM** | 国际，报告强 |
| **Oxygen Forensic Detective** | 国际 |
| **MobilEdit Forensic** | 同上 |
| **iLEAPP / ALEAPP**（开源） | iOS / Android 备份解析；**比赛白送的稳定保底** |
| **DB Browser for SQLite** | SQLite 万金油 |
| **Forensic Toolkit (FTK) / X-Ways** | 整盘镜像 |
| **Autopsy** | 开源镜像分析 |

> **比赛建议**：商业软件 + ALEAPP/iLEAPP **平行跑**。商业软件没解析的 App、ALEAPP 经常补全；ALEAPP 出错的，商业软件兜底。

### 2.7 网络抓包/MITM
| 工具 | 平台 | 备注 |
| --- | --- | --- |
| **mitmproxy** | 跨平台 CLI | 写 Python 脚本最方便 |
| **Charles** | GUI | 商业，国内常用 |
| **Fiddler / Fiddler Everywhere** | GUI | 老牌 |
| **Burp Suite Community** | GUI | 偏 Web |
| **Wireshark** | 跨平台 | 看原始包 |
| **HttpCanary**（Android App） | 设备本地抓 | 无 root 也能（VPN 模式） |

---

## 3. ADB 环境（**取证基础中的基础**）

### 3.1 安装 + 配 PATH
- `platform-tools` 内的 `adb.exe`、`fastboot.exe`。
- Windows 还要装 OEM USB 驱动（华为/小米/三星各家不同）。

### 3.2 关键命令速查
```bash
adb devices                          # 列设备
adb root                             # 切 root（仅模拟器/userdebug 可）
adb remount                          # 让 /system 可写（仅 userdebug）
adb shell                            # 进 shell
adb push <local> <remote>            # 推文件
adb pull <remote> <local>            # 拉文件

# 进程/服务
adb shell ps -A
adb shell dumpsys package <pkg>
adb shell pm list packages -f -i -u

# 取数据
adb backup -apk -shared -all -f all.ab        # AOSP 备份（多数现代 App 已禁用）
adb shell tar -cz /data/data/<pkg> | tar -xz   # 通过管道拉数据（需 root）

# 截屏 / 录屏
adb shell screencap -p /sdcard/s.png && adb pull /sdcard/s.png
adb shell screenrecord /sdcard/v.mp4

# logcat
adb logcat -d > log.txt
adb logcat -c                        # 清缓冲

# 安装/卸载
adb install -r -t app.apk
adb uninstall com.foo.bar

# 多设备（模拟器+真机+多模拟器）
adb -s 127.0.0.1:5555 shell ...
adb -s emulator-5554 shell ...
```

### 3.3 ADB over Wi-Fi / 网络
```bash
adb tcpip 5555
adb connect 192.168.1.x:5555
# Android 11+ 配对码模式
adb pair 192.168.1.x:38219            # 设备开发者选项里的"无线调试"
```

### 3.4 取证现场 ADB 注意
1. **取证连接前先做 hash 备份**：连接动作可能写入设备（修改 `/data/data/com.android.shell` 等）。
2. **adb root 可能改设备状态**：仅在 userdebug 设备/模拟器有效；retail 设备 root 必须 Magisk。
3. **接 USB 弹出"是否信任"**：每次都会弹；**不要拒绝**，否则后续命令全失败。
4. **配对密钥** `/data/misc/adb/adb_keys`：每台 PC 一个公钥；可作为"嫌疑人配过哪些 PC"的证据。

---

## 4. 模拟器环境（**取证比赛主力**）

### 4.1 推荐选型
| 场景 | 推荐 |
| --- | --- |
| 装嫌疑人 APK 看运行行为 | **雷电 9** / **MuMu Pro 12**（国内 App 兼容好，默认 root） |
| 跑 frida hook | **Genymotion** / **AVD x86_64** + Magisk |
| 跑 ARM 原生 SO 题（不能 x86 模拟） | **Genymotion ARM 翻译** / **AVD ARM64**（慢） |
| 取证还原嫌疑人 PC 上的雷电/夜神 | 直接用相同模拟器加载嫌疑人 vmdk（参 `emulator_forensics.md`） |
| 不想踩坑 | **AVD（Android Studio 自带）** + Google API 镜像 |

### 4.2 为什么常用模拟器而非真机
1. **默认 root**（雷电/夜神/MuMu/MEmu/Genymotion）。
2. **可快照**：随时回滚到干净状态。
3. **多开**：同时跑多个嫌疑账号 / 不同 Android 版本。
4. **不怕变砖**：刷错系统重装即可。
5. **frida-server 易部署**：不需解 BL。

### 4.3 模拟器装 Magisk/Frida（如默认非 root）
- AVD：用 [rootAVD](https://github.com/newbit1/rootAVD) 一键 patch ramdisk。
- Genymotion：勾选"Open GApps + ARM Translation"或装 SuperSU。
- 雷电/夜神/MuMu：默认 root，开关在设置。

### 4.4 frida-server 部署
```bash
# 下载对应架构
# https://github.com/frida/frida/releases  -> frida-server-<ver>-android-x86_64.xz
adb push frida-server /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/frida-server"
adb shell "/data/local/tmp/frida-server &"

# 验证
frida-ps -U | head
```

### 4.5 模拟器与商业取证软件
- 多数商业软件可"采集模拟器"：在 PC 上识别为 ADB 设备。
- **跑题流程**：装嫌疑人 APK → 操作触发 → 商业软件采集 → 出报告。
- 用于验证答案（数据库内字段含义、解密后是否一致）。

---

## 5. 真机环境（**部分深度题需要**）

### 5.1 真机 vs 模拟器
| 对比 | 真机 | 模拟器 |
| --- | --- | --- |
| 兼容性 | ✅ 任何 ARM SO | ❌ x86 翻译不全 |
| 反检测 | ✅ 多数过 | ❌ 易被检测 |
| 部署速度 | ❌ 慢 | ✅ 秒级 |
| root | ❌ 多数要解 BL | ✅ 默认 |
| 备份恢复 | ❌ 复杂 | ✅ 快照 |

### 5.2 比赛常备真机推荐
- **Pixel 系列**（Pixel 4/5/6/7）：BL 解锁简单，AOSP 干净，frida 兼容好。
- **Mi A 系列**（Android One）：相同优势。
- **OnePlus**：解锁友好。
- **三星 Galaxy**（海外版）：可解锁。
- **华为/荣耀（2018 后）**：**官方禁解**，不推荐做研究机。
- **小米**（红米/Mi）：可解但要等 7–168h 激活。

### 5.3 解锁 + Magisk root 流程（Pixel 示例）
```bash
1. 设置 → 关于本机 → 连点版本号 7 次 → 开发者选项
2. 开发者选项 → OEM 解锁 + USB 调试
3. adb reboot bootloader
4. fastboot flashing unlock        # 抹机
5. 抓官方 factory image，patch boot.img with Magisk Manager
6. fastboot flash boot magisk_patched.img
7. 重启进系统，Magisk 检测 root，安装 modules：
   - LSPosed（替代 Xposed）
   - Shamiko / MagiskHide / DenyList（隐藏 root）
   - HideMyApplist（隐藏可疑 App 包名列表）
   - PlayIntegrityFix（过 SafetyNet）
```

### 5.4 取证机房双机准备
- **设备 A**：解锁 root + Magisk + frida + LSPosed → 装嫌疑 App 跑分析。
- **设备 B**：完全官方未 root → 复现嫌疑人真实环境，对照设备 A 的 hook 数据。
- 两机数据交叉 = 反检测攻防的高质量证据。

### 5.5 真机用 ADB 接收时
- 必须开启 USB 调试 + PC 信任。
- 部分厂商需开"USB 调试（安全设置）"才能 `pm install`。
- 若设备已锁定无法打开调试 → 走商业取证物理/EDL 提取（见 `extraction_methods.md`）。

---

## 6. Hook 环境

### 6.1 Frida（**必装**）
```bash
pip install frida-tools
frida --version

# server 跟客户端版本必须严格一致
adb push frida-server-<ver>-android-arm64 /data/local/tmp/
adb shell /data/local/tmp/frida-server &
frida-ps -U
```
**实用模式**：
```bash
# 启动并 hook
frida -U -f com.foo.bar -l hook.js --no-pause

# 已运行 attach
frida -U -n com.foo.bar -l hook.js

# 一行 oneliner
frida -U -n com.foo.bar -e "Java.perform(()=>{var c=Java.use('java.lang.String');console.log(c.\$init.overloads);})"

# spawn + 早期注入（绕反 frida）
frida -U --no-pause -f com.foo.bar -l hook.js
```

### 6.2 Frida-gadget（无需 frida-server）
- 把 `frida-gadget.so` 重新打进 APK，在 `Application.onCreate` 加载 → 自带 frida 客户端可连。
- 用途：真机不能跑 frida-server / 检测 frida-server 时；或目标设备不在手上。
```bash
objection patchapk -s app.apk      # 一键嵌入 frida-gadget
adb install app.objection.apk
frida -U -n Gadget -l hook.js
```

### 6.3 Objection（**取证最便利**）
```bash
pip install objection
objection -g com.foo.bar explore

# 进交互
android root disable          # 绕 root 检测
android sslpinning disable    # 绕 SSL pinning（一句话）
android hooking watch class_method com.foo.bar.MainActivity.onCreate
android hooking generate simple com.foo.bar.utils.Crypto.decrypt
android filesystem ls /data/data/com.foo.bar/databases
android filesystem download /data/data/com.foo.bar/databases/x.db
```
> **比赛大杀器**：取证现场 90% 的"绕 SSL pinning + 拿数据库 key + 抓字符串"用 objection 一行解决。

### 6.4 Xposed / LSPosed
- 全局 hook 框架，比 frida 持久（重启仍生效）。
- 仅在长期监控/不便重连时用。
- 模块：HideMyApplist（隐 App 列表）、JustTrustMe（绕 SSL pinning）、XPrivacyLua（细粒度权限欺骗）。
- 安装：Magisk → LSPosed Zygisk 模块。

### 6.5 Hook 用例对应取证场景
| 场景 | 套路 |
| --- | --- |
| 拿 SQLCipher key | hook `sqlite3_key` / `sqlite3_key_v2` |
| 拿 AES key/IV | hook `Cipher.init` / `EVP_DecryptInit_ex` / `CCCryptorCreate` |
| 看请求体（绕 SSL pinning + HTTPS） | objection ssl unpinning + mitmproxy |
| 看字符串解密结果 | hook `String.<init>(byte[],...)` 或自定义 `decrypt` 函数 |
| 看数据库写入内容 | hook `SQLiteDatabase.insert/execSQL` |
| 看登录用户 | hook `SharedPreferences.getString("user_id")` |
| 拿设备指纹生成算法 | hook `Settings.Secure.getString` / `TelephonyManager.getDeviceId` |
| 看 IM 消息明文（解密前/后） | hook `recv` / `send` / proto 解析点 |
| 跨进程 IPC 监控 | hook `Binder.transact` / `IBinder.transact` |

---

## 7. 抓包 / SSL Pinning 绕过

### 7.1 mitmproxy 起步
```bash
pip install mitmproxy
mitmweb --listen-port 8080         # 浏览器看
# 或 CLI
mitmproxy --listen-port 8080
```
- 设备 Wi-Fi 配代理 → PC IP : 8080。
- 装 mitmproxy CA：`http://mitm.it`。

### 7.2 Android 7+ 系统信任用户证书（默认拒绝）
两条路：
1. **改 APK** `network_security_config.xml`，重打包重签（**仅 frida 测试机用，取证不要改原 APK**）：
```xml
<network-security-config>
  <base-config cleartextTrafficPermitted="true">
    <trust-anchors>
      <certificates src="system"/>
      <certificates src="user"/>
    </trust-anchors>
  </base-config>
</network-security-config>
```
2. **把证书装到系统 CA**（root 设备）：
```bash
hash=$(openssl x509 -inform PEM -subject_hash_old -in mitm.pem | head -1)
adb push mitm.pem /sdcard/${hash}.0
adb shell su -c "mount -o rw,remount /system; cp /sdcard/${hash}.0 /system/etc/security/cacerts/; chmod 644 /system/etc/security/cacerts/${hash}.0; reboot"
```
- Magisk 模块 **MagiskTrustUserCerts** 一键替代上面手动操作。

### 7.3 SSL Pinning 绕过
| 方案 | 说明 |
| --- | --- |
| `objection android sslpinning disable` | **首选**，覆盖 OkHttp/Retrofit/HttpClient/TrustManager 主流框架 |
| **JustTrustMe** Xposed 模块 | 持久 |
| frida 自写脚本 | 针对自定义 pinning |
| 改 APK `network_security_config.xml` | 上面那段 |

### 7.4 抓包后的处理
- mitmweb 直接看明文 + body。
- 导出 har / flow 文件 → 用 mitmproxy/Wireshark 复读。
- 再过一遍 jadx 反编译看签名生成（rules、token、sign）→ 还原算法。

---

## 8. 取证比赛常见环境组合（按题型）

### 8.1 题型 A：拿到一个 APK，问"包名/签名/权限/版本"
```
环境 = aapt + apksigner
命令 = aapt dump badging app.apk + apksigner verify --print-certs app.apk
时间 = 1 分钟
```

### 8.2 题型 B：APK 反编译看代码
```
环境 = jadx-gui
命令 = jadx-gui app.apk
时间 = 5 分钟读代码 + 搜字符串
```

### 8.3 题型 C：从 App 沙盒数据库拿聊天记录
```
环境 = ADB（连模拟器或镜像挂载）+ DB Browser for SQLite
命令 = adb pull /data/data/<pkg>/databases/*.db
       打开 DB Browser
时间 = 10–30 分钟
```

### 8.4 题型 D：数据库被 SQLCipher 加密
```
环境 = root 设备 + frida + sqlcipher
1. frida -U -f <pkg> -l hook_sqlite3_key.js
2. 拿到 raw key
3. sqlcipher cipher.db
4. PRAGMA key="x'<hex>'"; sqlcipher_export
时间 = 30–60 分钟
```

### 8.5 题型 E：APK 加固，看不到代码
```
环境 = root 模拟器 + frida-dexdump
命令 = frida-dexdump -U -f <pkg>
       jadx ./output/<pkg>/*.dex
时间 = 30 分钟（普通壳）
```

### 8.6 题型 F：抓 App 与服务器通信
```
环境 = mitmproxy + 设备装 CA + objection 绕 pinning
1. mitmweb --listen-port 8080
2. 设备 Wi-Fi 配代理
3. 装 mitm.pem 到系统 CA（或用 MagiskTrustUserCerts）
4. objection -g <pkg> explore
   -> android sslpinning disable
5. 触发 App 行为 → 看 mitmweb 抓到的 HTTPS
时间 = 30–60 分钟
```

### 8.7 题型 G：嫌疑人手机镜像，问 App 使用频度/安装时间
```
环境 = ALEAPP + DB Browser
1. ALEAPP 直接喂 tar/zip 备份目录
2. 查 packages.xml + usagestats
3. 出报告
时间 = 20 分钟
```

### 8.8 题型 H：商业软件没解析的 App
```
环境 = ADB + Python + AndroGuard + 自写脚本
1. 找 App 沙盒 + 配置 + DB
2. 看 DB 表结构 → 写 SQL
3. BLOB 字段：strings + hex + protobuf 反编 + frida 验证
时间 = 1–3 小时
```

---

## 9. 标准取证比赛工作机镜像（开赛前装好）

```
[必装]
- JDK 17 + ANDROID_HOME 配好 platform-tools/build-tools
- Python 3.11 + 取证库（§2.2）
- ADB / fastboot / scrcpy
- jadx-gui / jadx
- DB Browser for SQLite / SQLiteStudio
- AndroGuard / APKiD / MobSF（docker 跑）
- Frida + frida-tools + Objection
- mitmproxy + Charles
- ALEAPP / iLEAPP
- 7-Zip / OSFMount / FTK Imager
- HxD / 010 Editor
- IDA Pro / Ghidra
- VS Code（编辑器+md预览）
- Notepad++

[预下载]
- frida-server 全架构（arm/arm64/x86/x86_64）多版本
- factory image：Pixel/Nexus 各 Android 主流版本
- Magisk + LSPosed + Shamiko + HideMyApplist + MagiskTrustUserCerts
- AOSP signing keys
- Apktool jar + 框架资源（aapt 框架包）

[模拟器]
- 雷电 9（含官方 root + frida-server 内置）
- AVD x86_64 + ARM64（rooted via rootAVD）
- 至少一份 Genymotion 备用

[真机]
- Pixel 5 或 Pixel 6（Magisk root + frida + LSPosed）
- 备用真机：未 root 的同型号或同厂商（用于复现）

[商业]
- 盘古石 / 美亚 / Cellebrite Reader（看主办方授权）

[网络环境]
- 路由器：开 PC 与手机同子网，方便代理
- 法拉第袋 / 蜂窝阻断器（用于隔离样本设备）
```

---

## 10. 常见环境踩坑

1. **ADB 设备名乱**：多设备时 `adb devices` 必看；命令前加 `-s <id>`。
2. **frida-server 与客户端版本不匹配**：连不上；下载页对照表必看。
3. **Android 7+ 用户 CA 不被信任**：抓包失败常见原因；走系统 CA 路线或改 APK。
4. **ARM App 在 x86 模拟器装不上**：开 ARM 翻译（雷电/夜神有，AVD 装 `arm-translation` 模块）；或换真机。
5. **Magisk 模块过多冲突**：装多个 hide 模块互踩；推荐组合 = LSPosed + Shamiko + HideMyApplist + PlayIntegrityFix，**别再加其他 hide**。
6. **userdebug 与 user ROM 区别**：`adb root` 仅前者可用；商业取证手机多 user ROM。
7. **adb 权限路径**：`/data/data/<pkg>` 在非 root 设备下 `adb shell` 进去 `Permission denied`；必须 root 或 `run-as <pkg>`（仅 debuggable）。
8. **`run-as`** 仅 App 编译时 `android:debuggable="true"` 才工作；多数商业 App 关；自己重打包加 debuggable 后能 run-as。
9. **PC 下载 SDK 慢**：用国内镜像 `aliyun.com` / `tuna.tsinghua.edu.cn` 镜像。
10. **Android 11+ scoped storage**：`/sdcard/Android/data/<pkg>` 没 root 不让看；必须 ADB shell + root 或 `dumpsys` 间接看。
11. **Java 版本**：apksigner v3 要 Java 11+；老 jdk8 报错。
12. **apktool 反编 manifest 失败**：framework 不全；`apktool if framework-res.apk` 装一下。
13. **jadx 反编译某些 dex 直接卡死**：换 GDA 或 dex2smali → 手读 smali。
14. **mitmproxy 内 HTTP/2 + brotli**：默认能解；但部分自定义协议（gRPC + 自家 frame）需写 addon。
15. **Frida 在 Android 14 部分新机**：受 SELinux + 反 frida 影响；用 frida-gadget 嵌入更稳。
16. **取证比赛限制联网**：考场禁止外网；frida-server / Magisk module / ALEAPP 等必须**赛前预下载到本地**。
17. **比赛时间紧**：先用商业软件跑一遍报告，再针对 N 道题分别上 jadx/frida/sqlite，**别上来就深度逆向**。
18. **改设备状态会失分**：取证完整性是评分项；hook/装证书等操作如果会改原检材，必须**复制副本到模拟器再做**。

---

## 11. 决策流（开题后该用什么）

```
拿到题目
├─ 给 APK 文件
│   ├─ 问基本信息 → aapt + apksigner
│   ├─ 问代码逻辑 → jadx-gui
│   ├─ 问加固/作者同源 → APKiD + apksigner（参 attribution.md）
│   ├─ 问算法/密钥 → 装到 root 模拟器 + frida hook
│   └─ 加固严重 → frida-dexdump 先脱壳，再上面流程
├─ 给设备镜像 / 备份 / 全文件
│   ├─ 商业软件 + ALEAPP **平行跑**（互补）
│   ├─ 答案在数据库 → DB Browser 找表 → SQL
│   ├─ 答案在 plist/proto/MMKV → Python 取证库
│   └─ 答案在加密字段 → 找 key（沙盒/MMKV/Keychain/SO）
├─ 题目要"流量/通信内容"
│   ├─ 设备装 mitmproxy CA + objection 绕 pinning
│   ├─ 重现 App 行为
│   └─ 抓包后用 jadx 验证签名/请求构造
└─ 题目要"已删除/恢复"
    ├─ DB 删除恢复（参 database_forensics.md）
    ├─ 文件删除恢复（fls / photorec / 商业）
    └─ App 已卸 → packages_backup.xml + usagestats + Download
```

---

## 12. 交叉链接
- `extraction_methods.md`：5 级提取，决定能拿什么
- `adb_filesystem_cheatsheet.md`：ADB 命令速查（已存在）
- `emulator_forensics.md`：模拟器镜像格式 + 共享文件夹
- `android_packer_unpacker.md`：脱壳深度
- `apk_crypto_analysis.md`：算法/密钥提取
- `android_app_attribution.md`：APK 溯源
- `database_forensics.md`：SQLite/SQLCipher/Realm/LevelDB
- `wechat_deep_dive.md` / `popular_apps_forensics.md`：常见 App 取证
- `lock_password_forensics.md`：屏锁/应用锁/隐私空间
- `quick_reference.md`：跨主题速查（顶层入口）
