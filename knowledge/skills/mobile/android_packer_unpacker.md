# 安卓加固与脱壳深度专题

> 适用：APK 反编译时遇到 `classes.dex` 几乎为空 / 满是 `Stub` 类 / `Application` 在 native 加载真 dex 等加固特征。题目特征：见到 `libsecexe.so`、`libjiagu.so`、`libBugly.so`（误报）、`libDexHelper.so`、`libtup.so`、`libtosprotection.so`、`libtprt.so`、`libshell.so`、`stub.so`、`assets/i.jar`、`assets/libsecondary.so`、`assets/aijiami`、`tencent_stub`、`bangcle`、`ijiami`、`360_jiagu`、`tencent_legu`、`baidu_protection` 等。
>
> 与 `apk_crypto_analysis.md` 互补：那篇侧重"已知 App 算法逆向 + 密钥提取"；本篇侧重"加固判定 + dex/so 脱壳得到可分析代码"。

---

## 1. 为什么取证要懂加固/脱壳

| 取证场景 | 是否要脱壳 |
| --- | --- |
| 嫌疑人 App 是恶意软件 / 木马 / 灰产 | **必脱**，否则看不到核心逻辑 |
| 取数据库/聊天记录密钥（key 在 SO 内派生） | **必脱 SO**，否则不能定位算法 |
| 恶意 App 行为分析（隐私窃取/远控） | **必脱**，看 C2 / 上传字段 |
| 要确定 App 是哪家公司加固 | **指纹识别即可，不必脱** |
| 普通 App 数据库结构清楚（如微信/支付宝） | **通常不需脱**，已有公开方法 |
| 比赛"还原算法/解密 BLOB" | **大概率要脱**，因为出题方故意加固 |

> 取证人员**不必精通加固反混淆**，但必须**能识别加固类型 + 用通用脱壳工具**拿到原始 dex/so，再做静态分析。

---

## 2. APK 加固机制总览

### 2.1 加固层次
```
┌─ Java 层（Dex 加固）       ─ 抽空 Dex / 整 Dex 加密 / 类抽取 / VMP
├─ Native 层（SO 加固）       ─ OLLVM / VMP-SO / 自定义加密节
├─ 反调试 / 反 Hook / 反模拟器
├─ 完整性校验（签名/CRC/签名V2）
└─ Anti-Frida / Anti-Xposed / Anti-Magisk
```

### 2.2 Dex 加固几代演进
| 代际 | 手法 | 脱壳难度 | 代表 |
| --- | --- | --- | --- |
| **1 代** | 整 Dex 加密 + 启动时解密放内存 | 低 | 早期梆梆、爱加密 v1 |
| **2 代** | Dex 函数抽空（method.code = NULL）→ 调用前回填 | 中 | 360 v1、爱加密 v2 |
| **3 代** | Dalvik/ART 指令转换为虚拟机字节码（VMP-Dex） | 高 | 360 终极版、腾讯乐固、爱加密 v3 |
| **4 代** | Native 化（部分 Java 方法编译成 native）+ 流程混淆 | 高 | 爱加密 / 360 高级版 |
| **5 代** | OLLVM + 商业 VM + 整 ART 替换 | 极高 | 部分军工 / 银行 App |

### 2.3 SO 加固
| 手法 | 描述 |
| --- | --- |
| **加密节段**（`.text` 段密文） | 启动时调 `mprotect` + 自解密；常见 UPX 改造 |
| **OLLVM**（控制流平坦化、虚假分支、字符串加密） | 反编译看到一坨 switch-case + dispatcher |
| **VMP-SO**（自定义指令集 + 解释器） | 关键函数变成"vm_exec(bytecode)"，原汇编全消失 |
| **JNI 函数动态注册** | `JNI_OnLoad` 里 `RegisterNatives`，IDA 直接搜函数名失败 |
| **反调试**：ptrace 自调 / TracerPid 检测 / inotify 监听 | 进程被 attach 立即退出 |
| **完整性校验** | 启动检查 APK 签名 / dex CRC / so MD5 |

---

## 3. 主流商业加固识别（**取证第一步**）

### 3.1 文件指纹速查
| 加固厂商 | 关键文件 / 字符串 |
| --- | --- |
| **梆梆 Bangcle / Secneo** | `assets/libsecexe.so`、`assets/libsecmain.so`、`libDexHelper.so`、`libsecure*.so` |
| **爱加密 ijiami** | `assets/ijiami.dat`、`assets/ijiami.ajm`、`libexecmain.so`、`libexec.so`、`assets/aijiami/` |
| **360 加固 / 加固保 / 加固宝** | `libjiagu.so`、`libjiagu_x86.so`、`libjiagu_a64.so`、`assets/libjiagu.so` 文件名变体 |
| **腾讯乐固 / 御安全 (Legu/Yas)** | `libshell*.so`（如 `libshell-super.2019.so`、`libshella-2.10.6.0.so`、`libshellx-2.10.6.0.so`）、`tosprotection`、`assets/0OO00l111l1l` 类垃圾文件名 |
| **腾讯加固（旧 TUP）** | `libtup.so`、`libtprt.so`、`libtosprotection.armeabi.so` |
| **百度加固 / 百度乐固** | `libbaiduprotect.so`、`libbaiduprotect_x86.so`、`assets/baiduprotect*.jar` |
| **通付盾 Tongfudun / DexProtector** | `libdexprotector.so`、`libsmt.so`、`assets/dp.arm` |
| **网易易盾 Yidun** | `libnesec.so`、`libnesec_x86.so`、`assets/dummydata` |
| **阿里聚安全 / 御安全** | `libmobisec.so`、`libmobisecy.so`、`libsgmain.so`（非加固，但同公司）、`libpreverify1.so` |
| **江南天安 / Jiangnan** | `libcms.so`、`libfakejni.so` |
| **顶象 Dingxiang / 几维安全 Kiwisec** | `libkwslinker.so`、`libkwscmm.so`、`libtmap.so` |
| **APKProtect**（早期开源） | `libAPKProtect.so` |
| **DexGuard**（GuardSquare 商业） | 无独立 SO，dex 内部有 `o.LF` `Lo/o/o/oOO;` 一类奇怪类名；多与 ProGuard 同用 |
| **Promon Shield** | `libshield.so`、`libpromon.so` |

### 3.2 包内特征位置
```
APK
├── classes.dex              # 真 dex 几乎为空 / 仅 Stub Application
├── lib/<arch>/
│   ├── libsecexe.so         # 加固运行时
│   └── libjiagu.so          # ...
├── assets/
│   ├── ijiami.dat           # 加固后真 dex（密文）
│   ├── libsecondary.so      # 二级 SO（自解密）
│   └── 0OO00l111l1l         # 乱码文件名 = 真 dex/jar 密文
└── AndroidManifest.xml
    └── application.android:name = ".StubApplication" / "com.bangcle.protect.SApplication" / "com.qihoo.util.StubApp"
```

### 3.3 一键识别
```bash
# 工具：APKiD（最权威）
pip install apkid
apkid app.apk

# 输出示例
[+] anti_vm: emulator.detect.qemu_props
[+] anti_debug: ptrace, antiptrace
[+] packer: bangcle (secneo) v3
[+] obfuscator: ollvm

# 备选
file lib/arm64-v8a/*.so | grep -i upx
strings lib/arm64-v8a/*.so | grep -E 'ijiami|secneo|jiagu|legu|nesec|dexprotector'
```

### 3.4 Manifest 速判
```xml
<application
  android:name="com.qihoo.util.StubApp" ...>     <!-- 360 -->
  <meta-data android:name="ms" android:value="..."/>
  <meta-data android:name="cf" android:value="..."/>
```
常见 Stub Application：
| 加固 | application name |
| --- | --- |
| 360 | `com.qihoo.util.StubApp` / `com.stub.StubApp` |
| 梆梆 | `com.SecShell.SecShell.AppWrapper` / `com.bangcle.protect.SApplication` |
| 爱加密 | `com.shell.NativeApplication` |
| 腾讯乐固 | `com.tencent.StubShell.TxAppEntry` |
| 百度 | `com.baidu.protect.StubApplication` |
| 网易易盾 | `com.netease.nis.basesdk.protect.NeProxyApplication` |
| 通付盾 | `com.dx.mobile.shield.DxStubApp` |
| 几维 | `com.kiwisec.kdp.KiwiApplication` |

---

## 4. 通用脱壳方法

### 4.1 三大思路
1. **静态拆包**（针对 1 代整 Dex 加密）：定位密文 + key + 算法 → 离线解出 dex。
2. **运行时内存 dump**（针对 2-3 代）：让加固自己解，在解完那一刻 dump dex 内存。
3. **VM/解释器还原**（针对 4-5 代 VMP）：逆向加固自家解释器，把 vm 字节码翻回 Dalvik —— **极困难，多数取证不做**。

### 4.2 内存 dump 工具/方法
| 工具 | 原理 | 适用 |
| --- | --- | --- |
| **FRIDA-DEXDump** | frida hook + 扫所有内存找 dex magic | 通用，**最常用** |
| **FART**（Hanbin Hou） | 基于 ART，patch ROM 主动调用 method 触发回填 | 2-3 代抽空 / 整 dex |
| **dumpDex / DexExtractor** | hook libart 关键函数 | 老 ART 版本 |
| **BlackDex**（开源） | 不 root、不 frida，App 内 self-hook + dex 抓取 | 现代 5-9 代 |
| **youpk**（吾爱破解） | 改进版 FART | 同上 |
| **GDA / Jadx 动态版** | 部分内置脱壳 | 简单壳 |
| **Cellebrite Inspector** / **盘古石** / **美亚 APK 脱壳模块** | 商业一键 | 取证标配 |

### 4.3 FRIDA-DEXDump 推荐流程（**取证主力**）
```bash
# 安装
pip install frida-tools
git clone https://github.com/hluwa/FRIDA-DEXDump

# 设备：root + frida-server 跑起来
adb push frida-server /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/frida-server && /data/local/tmp/frida-server &"

# 启动 App 后 dump
cd FRIDA-DEXDump
python main.py             # 选目标进程，自动扫内存

# 输出：./output/<package>/*.dex
ls output/com.target.app/
# classes.dex classes2.dex ...

# 用 jadx / GDA 反编译
jadx output/com.target.app/classes.dex -d /tmp/decoded
```

### 4.4 BlackDex（**不 root 也能用**）
```
1. 装 BlackDex App 到设备
2. 选目标 App（必须已安装）
3. 点"开始" → 后台 fork 启动目标 + dump
4. 结果存 /sdcard/Android/data/com.blackdex/files/
```
适合无 root 真机；速度快；对 360/腾讯乐固/爱加密多数版本有效。

### 4.5 FART（深度回填 + dump）
- 修改 ROM 源码（AOSP），在 `art::Method::Invoke` 处插 dump。
- 必须刷自定义 ROM（Pixel/Nexus 各 Android 版本一份）。
- 优势：能强制触发未执行的方法回填 → 找到完整 dex（FRIDA-DEXDump 漏的 method）。
- 适用：高对抗加固。
- 缺点：不便携；现场取证少用，多用于深度逆向。

### 4.6 自写脱壳（理解原理）
关键点：**Dex 头**：
```
magic = "dex\n035\0" / "dex\n037\0" / "dex\n038\0" / "dex\n039\0"
checksum (Adler32)
sha1 (20 bytes)
file_size
header_size = 0x70
```
扫内存找 magic + 长度合理 → dump 出来即一个 dex。

```python
# 简化版（在能 ptrace 的环境）
import re, struct
mem = open('/proc/<pid>/mem','rb', 0)   # 需要 root
maps = open('/proc/<pid>/maps').read()
for line in maps.splitlines():
    if 'r' not in line.split()[1]: continue
    a,b = line.split()[0].split('-')
    start, end = int(a,16), int(b,16)
    try:
        mem.seek(start); buf = mem.read(end-start)
    except: continue
    for m in re.finditer(b'dex\n03[5-9]\x00', buf):
        off = m.start()
        size = struct.unpack_from('<I', buf, off+0x20)[0]
        if 0x100 < size < 100*1024*1024 and off+size <= len(buf):
            open(f'dump_{start+off:x}.dex','wb').write(buf[off:off+size])
```

### 4.7 ART 加固特殊处理
- 现代 5+ Android：ART 直接执行 dex2oat 后的 OAT，加固若篡改 OAT 缓存路径会出现：
  - `/data/data/<pkg>/code_cache/odex/`、`oat/<arch>/base.odex` 含已优化代码。
  - 取证可拿 OAT，用 `oat2dex.py`（GitHub）回 dex。
- 优点：跳过加固运行时，直接吃系统 OAT。
- 局限：加固若禁用 dex2oat 缓存（强制纯解释执行）则无 OAT。

---

## 5. SO 脱壳

### 5.1 加密节段（自解密 SO）
- ELF 启动后 `JNI_OnLoad` / `.init_array` 调 `mprotect` + `memcpy/XOR` 还原 `.text`。
- **dump 方法**：
  - **frida**：`Process.enumerateModules()` 找目标 SO，`Module.findExportByName` 后 dump 内存：
    ```js
    var m = Process.findModuleByName('libtarget.so');
    Memory.protect(m.base, m.size, 'rwx');
    var d = m.base.readByteArray(m.size);
    var f = new File('/data/local/tmp/libtarget_dump.so','wb');
    f.write(d); f.close();
    ```
  - **gcore** + 配合 ELF 头修复（`Section header` 重建）。
  - **SoFixer**（开源）：把 dump 的 raw 内存修复成可被 IDA 分析的 ELF。

### 5.2 OLLVM
- 三件套：控制流平坦化（CFF）/ 虚假分支（BCF）/ 字符串加密（SE）。
- 工具：
  - **deflat**（IDA 脚本，cabbage 等多版本）：自动还原 CFF。
  - **D-810** / **angr** / **miasm** / **Ghidra Decompiler 自带还原**。
  - 字符串：动态运行抓 → frida hook `__cxa_atexit` / 字符串构造点。

### 5.3 VMP-SO
- 关键函数变成 `vm_run(bytecode)` —— 原汇编不可见。
- 方法：
  1. 先脱壳 SO（密文 → 明文）；
  2. 找 vm 解释器主循环（`switch (opcode)`）；
  3. 逆向 opcode 表 → 把 bytecode 翻回伪汇编；
  4. 大量人力，多数取证**只 hook 入口/出口拿数据**而非完整翻译。

### 5.4 反调试 / 反 Frida 绕过
| 检测点 | 绕过 |
| --- | --- |
| `/proc/self/status` 的 `TracerPid` | hook `read` 返回 0 |
| `ptrace(PTRACE_TRACEME)` 自调 | hook `ptrace` 返回 0 |
| 检测 `frida-server` 进程名 / 端口 27042 | 改 frida-server 名 + 改端口 `frida-server -l 0.0.0.0:9999` |
| 检测 `/proc/self/maps` 含 `frida-agent` | 用 frida-gadget 注入 / 换名重编译 |
| Java.use 调用栈检测 | 使用 frida-gadget early-instrumentation |
| 完整性 / 签名 v2 校验 | 修改 APK 后用 `apksigner --v2` 重签 |

工具：**objection**（基于 frida 的便利层）、**HookHelper**、**rspack-frida**、**SwitchyHosts** 等社区脚本。

---

## 6. 比赛/实战题型

### 6.1 题型 A："给一个加固 APK，问 Application 类是哪个 / 加固厂商"
1. `apkid app.apk` 一行即可。
2. 备选：解 AndroidManifest 看 `application.name`。

### 6.2 题型 B："dex 内类几乎都是 Stub，怎么得到真 dex"
1. 装到设备/模拟器（推荐模拟器，方便 frida）。
2. `frida-dexdump -U -f com.target` 直接出 dex。
3. jadx 反编译看真代码。

### 6.3 题型 C："SO 关键函数被加密 / 反调试"
1. 先 frida `Memory.dump` 得明文 SO；
2. SoFixer 修复 → IDA。
3. 反调试用 objection 绕：
```bash
objection -g com.target explore
android root disable
android sslpinning disable
```

### 6.4 题型 D："找出 SQLCipher / AES 密钥"
1. 脱壳得 dex + so；
2. 看 Java 层是否调 `sqlite3_key`/`Cipher.init`；
3. frida hook 关键 API 抓运行时 key（参 `apk_crypto_analysis.md`）；
4. 把 key 落地，用 sqlcipher 解 db。

### 6.5 题型 E："APK 安装就崩溃 / 检测 root / 检测模拟器"
1. 看 logcat 报错关键字 → 反向定位检测点。
2. 用 LSPosed + HideMyApplist / Shamiko / RootBeerFresh 配合。
3. frida-gadget 注入而非外部 attach。
4. 模拟器：尽量用真机（参 `emulator_forensics.md` §5.3）。

### 6.6 题型 F："给一个加固 dex 文件，离线脱壳"
- 1 代整 Dex：`assets/ijiami.dat` / `0OO00l1...` 是密文，找 `libexec*.so` 内的 KEY + 算法（多 AES/XOR/魔改）。
- 2-3 代：必须运行；离线无解。
- 输出：dex 文件，`jadx`/`GDA` 反编译。

### 6.7 题型 G："取证恶意 APK，问 C2 服务器 / 上传字段"
1. 脱壳；
2. jadx 看 `OkHttpClient` / `HttpURLConnection` / 自家网络库构造 URL；
3. 字符串多被加密 → frida hook `String.<init>` 或 `decryptStr` 类函数；
4. 网络抓包印证（参 `network/network_capture.md` 或 mitmproxy）。

### 6.8 题型 H："APK 体积异常大 / 内含 jar / so 不正常"
- 看 `assets/` 是否有 jar/dex/so 隐藏文件 → 多为加固包 + 二级 payload。
- `unzip -l app.apk | sort -k1 -n -r | head` 看大文件；
- 可疑文件用 `file` / `xxd` 定结构。

---

## 7. 标准取证脱壳流水

```
1. apkid 识别加固厂商 → 决定路线
2. 静态先看：unzip + jadx --no-debug-info（看哪些类是 Stub）
3. 装目标 App 到 root + frida 模拟器（雷电/夜神 root 现成）
4. 启动 App + frida-dexdump 出 dex
5. 多 dex 合并：jadx 直接接受 dump 目录
6. 关键 SO：frida Memory.dump + SoFixer 修复 → IDA
7. 关键算法：frida hook 抓运行时 key/iv/明文
8. 用拿到的 key 解 db / 解密本地数据 / 解 BLOB 字段
9. 报告：标明加固厂商 + 版本 + 脱壳工具 + 提取数据来源
```

---

## 8. 命令速查

```bash
# 识别加固
apkid app.apk
strings lib/arm64-v8a/*.so | grep -iE 'ijiami|secneo|jiagu|legu|nesec|dexprotector|baidu|kwslinker'

# AndroidManifest 看 Stub Application
apktool d -s app.apk          # 不反编译 dex，只解资源
grep 'android:name' app/AndroidManifest.xml

# ART OAT 转 dex
python oat2dex.py base.odex
# 或
baksmali deodex base.odex -o smali/   # 再 smali 回 dex

# Frida-DEXDump
git clone https://github.com/hluwa/FRIDA-DEXDump
cd FRIDA-DEXDump
python main.py -d            # 详细模式

# objection 绕反调试 + ssl pinning
pip install objection
objection -g com.target explore

# BlackDex（设备 App）
# 装 BlackDex APK，UI 选目标，dump 到 /sdcard/Android/data/com.blackdex/files

# SO dump（frida）
cat > dump_so.js <<'EOF'
function dump(name){
  var m = Process.findModuleByName(name);
  if (!m) { console.log('module not found:', name); return; }
  Memory.protect(m.base, m.size, 'rwx');
  var data = m.base.readByteArray(m.size);
  var f = new File('/data/local/tmp/'+name+'.dump','wb');
  f.write(data); f.close();
  console.log('dumped',name,'->',m.size,'bytes');
}
setTimeout(function(){dump('libtarget.so');}, 3000);
EOF
frida -U -f com.target -l dump_so.js --no-pause

# SoFixer 修复
SoFixer-linux-64 -m 0x77b0000000 -s libtarget.so.dump -o libtarget_fixed.so

# 反编译
jadx -d out classes.dex
GDA classes.dex
# IDA: shift+F12 看字符串；F5 看伪 C
```

---

## 9. 常见坑

1. **apkid 不是万能**：很久未更新会漏认，结合 SO 文件名 + Manifest 综合判断。
2. **frida-server 版本必须匹配 frida 客户端**：版本不一致连不上。
3. **dexdump 出多 dex 但缺 method**：壳是抽空类，需 FART 主动调用回填；商业取证软件多有此模块。
4. **Jadx 反编译失败**：dex 被故意构造成"不合法但 ART 能跑"的形态，用 GDA / 开 jadx `--no-imports` / smali 直接读。
5. **OAT 路径权限**：`/data/dalvik-cache/` 与 `/data/data/<pkg>/code_cache/oat/` 都可能有，**root 才读得到**。
6. **完整性校验**：脱壳后改 dex 重打包会闪退；取证只读不改通常无碍，**纯逆向才需 patch**。
7. **反 Hook 进程检测**：检测到调试就 exit；改 frida-server 名 + 用 frida-gadget 静默注入。
8. **多 dex 合并要小心同名类**：脱壳 dex 之间偶尔有重复 stub 类，jadx 会抱怨；保留每个 dex 单独反编译再合并。
9. **SO dump size 不准**：内存中 SO 加载 + 解密后大小可能 ≠ 文件 size；用 `Process.findModuleByName().size` 而非文件 size。
10. **VMP-Dex 几乎无解**：碰到 360/爱加密/腾讯顶级方案的 VMP，**不要硬怼算法翻译**，转 hook 入口/出口拿明文输入输出更现实。
11. **加固保护对模拟器 hostile**：可能在模拟器内主动 crash；应换真机或反检测模块。
12. **取证完整性**：修改设备状态（装 frida-server、刷 patched ROM）会改原状；**做 hash 备份 + 录屏 + 操作日志**。
13. **加固版本变化快**：同一厂商一年内可能换 3 套实现；指纹文件名多为 `libshella-2.10.6.0.so` 类带版本，**一定记录版本**。
14. **APK signature v2/v3 校验**：脱壳重签必须用 `apksigner --v2-signing-enabled true --v3-signing-enabled true`；老 jarsigner 已不够。
15. **ART JIT 优化**：method 第一次调用前可能未解密；要遍历调用所有 method 才能完整 dump，所以 FART 比纯被动 dump 全。

---

## 10. 决策流

```
拿到加固 APK
├─ 取证目标是 "判断厂商" → apkid 即可，结束
├─ 取证目标是 "看 Java 逻辑"
│   ├─ 装到 root 设备 + frida-server
│   ├─ frida-dexdump → 拿全 dex
│   ├─ jadx 反编译
│   └─ 看不到 method? → 上 FART / BlackDex
├─ 取证目标是 "拿 SO 内的 key/算法"
│   ├─ frida Memory.dump → SoFixer → IDA
│   ├─ OLLVM? → deflat / D-810
│   └─ VMP-SO? → 别翻译，直接 hook 入口拿数据
├─ 取证目标是 "解密用户数据"
│   ├─ 找加密点（sqlite3_key / Cipher.init）
│   ├─ frida hook 抓运行时 key
│   └─ 落地 + 离线 SQLCipher 解
└─ 反调试/反 frida 拦截
    ├─ objection / Shamiko / HideMyApplist
    ├─ frida-gadget 早期注入
    └─ 改名 frida-server + 端口 + 移除字符串
```

---

## 11. 交叉链接
- `apk_crypto_analysis.md`：脱壳后 → 算法/密钥提取
- `database_forensics.md`：拿 key 后解 SQLCipher / WCDB
- `wechat_deep_dive.md`：微信 SO 内派生 key 思路
- `popular_apps_forensics.md`：抖音/QQ 等加固 App 取证
- `emulator_forensics.md`：模拟器内 frida 比真机方便
- `lock_password_forensics.md`：壳内置反 root/反模拟器与设备指纹
- `anti_forensics_and_misleading.md`：加固也是反取证手段之一
- `extraction_methods.md`：脱壳前先有 root + AFU + 可写设备状态
