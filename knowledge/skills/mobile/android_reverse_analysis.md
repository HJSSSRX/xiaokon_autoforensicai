# 安卓逆向分析（取证比赛视角）

> 适用：取证比赛中要做"两个 APK 是不是同一个"、"是不是同一作者写的"、"App 有反调试/反 hook 怎么办"、"哪些工具反编译它"等任务。
>
> 与 `android_app_attribution.md`（溯源指标）、`android_packer_unpacker.md`（脱壳）、`apk_internals.md`（结构）、`android_analysis_environment.md`（工具环境）互补：本篇专注 "**同一/同源对比**" + "**反分析对抗**" + "**静动态调试工具用法**" 三件事。

---

## 1. 同一性 vs 同源性（**先分清**）

### 1.1 定义
| 概念 | 问题 | 取证意义 |
| --- | --- | --- |
| **程序同一性**（Identity） | "样本 A 与样本 B 是不是**同一个**程序" | 证明检材内 APK 与已知样本完全一致（投放证据、还原现场） |
| **程序同源性**（Homology） | "样本 A 与样本 B 是不是**同一作者/家族/工程**" | 关联多个 APK 到同一团伙、追加犯罪事实 |

### 1.2 强度对照
| 比对维度 | 同一性强度 | 同源性强度 |
| --- | --- | --- |
| 整文件 SHA-256 | **绝对一致** = 同一 | 不同 → 不能否同源 |
| ZIP 内每文件 SHA-256 | 一致 = 同一 | 部分相同 = 强同源 |
| classes.dex SHA-256 | 一致 = 代码同一 | 局部相同 = 强同源 |
| 签名公钥 SHA-256 | 一致 ≠ 同一（可同钥不同 App） | **同公钥几乎铁证同源** |
| 包名 + versionCode | 一致 ≠ 同一（可仿冒） | 弱同源 |
| simhash / ssdeep / TLSH | — | **跨版本同源** |
| 字符串集 Jaccard | — | 同源 |
| build-id（ELF）/ Built-Date | — | 强同源 |
| C2 域名 / SDK AppKey | — | 强同源 |

> **取证报告差异**：
> - 同一性结论：必须 hash 完全一致才能下"同一"，否则只能写"内容一致 / 高度相似"。
> - 同源性结论：**写置信度**（强/中/弱），列举多条独立指标。

---

## 2. 程序同一性对比（**精确**）

### 2.1 文件级对比
```bash
# 整体 SHA-256
sha256sum a.apk b.apk

# ZIP 内每文件 SHA
for f in $(unzip -l a.apk | awk 'NR>3 && NF>=4{print $4}'); do
  ha=$(unzip -p a.apk "$f" 2>/dev/null | sha256sum | awk '{print $1}')
  hb=$(unzip -p b.apk "$f" 2>/dev/null | sha256sum | awk '{print $1}')
  [ "$ha" != "$hb" ] && echo "DIFF $f $ha $hb"
done
```

### 2.2 重打包识别
- 嫌疑人常重打包同一 App（改包名/改图标/插入广告）。
- 重打包后**整 SHA 必变**（签名/META-INF/对齐填充），但**class 内容/资源 SHA 大量相同**。
- 流程：
  1. 分别解 zip 出文件树；
  2. 对每对同名文件计算 SHA；
  3. 统计相同/不同比例。

### 2.3 二进制差分
| 工具 | 用途 |
| --- | --- |
| **bsdiff / bspatch** | 计算二进制 patch 大小（小 = 高度同一） |
| **rabin2 -H** / **xxd** | 看头部对比 |
| **diffoscope** | 自动深度差分（解 zip + 反编 + 比对） |
| **vbindiff** | 交互式十六进制对比 |
| **kdiff3 / Beyond Compare** | 文本/二进制 GUI 对比 |

```bash
# diffoscope 一键深度比对（解压、解 dex、解 SO 全做）
diffoscope a.apk b.apk --html report.html
```

### 2.4 反编译后的代码 diff
```bash
jadx -d a_src a.apk
jadx -d b_src b.apk
diff -r a_src b_src | head
# 或语义级
pip install simian
```

---

## 3. 程序同源性对比（**模糊**）

> 详细溯源指标见 `android_app_attribution.md`，本节侧重"算法/工具/比赛操作"。

### 3.1 模糊哈希
| 工具 | 算法 | 适合 |
| --- | --- | --- |
| **ssdeep** | CTPH | 经典；APK 整文件 / dex / so |
| **TLSH** | 局部敏感 | 比 ssdeep 更稳，开源 |
| **sdhash** | 块哈希 | 学术 |
| **mrsh-cf** | block bloom | 加固后差分较好 |

```bash
ssdeep a.apk b.apk
ssdeep -c a.apk b.apk             # 输出相似度 0–100

tlsh -c a.apk b.apk
```

### 3.2 SimHash（字符串/方法）
```python
# 字符串集合 → simhash → Hamming 距离
import re, zipfile
from simhash import Simhash

def apk_strings(p):
    z = zipfile.ZipFile(p)
    s = []
    for n in z.namelist():
        if not (n.endswith('.dex') or n.endswith('.so')): continue
        d = z.read(n)
        for m in re.finditer(rb'[\x20-\x7e]{6,}', d):
            s.append(m.group().decode('latin1'))
    return s

a, b = apk_strings('a.apk'), apk_strings('b.apk')
ha, hb = Simhash(a), Simhash(b)
print('hamming:', ha.distance(hb))   # < 16 视为强同源
```

### 3.3 类/方法级同源
| 工具 | 输入 | 输出 |
| --- | --- | --- |
| **AndroSim**（AndroGuard 子模块） | 两个 APK | 类似度矩阵 + 共同类列表 |
| **APKDiff**（开源） | 两 APK | 增删改类清单 |
| **Quark** 规则匹配 | APK | 与威胁规则的 hits |
| **VirusTotal** | hash | 自动聚类相同/相似样本 |
| **MalGenie / DroidKungFu detect 各 family** | APK | family 标签 |

```bash
androsim a.apk b.apk
# 输出：
# IDENTICAL: x classes / SIMILAR: y / NEW: z / DELETED: w / Score: 87.3%
```

### 3.4 资源级同源
- AndroidManifest 树状结构 hash；
- resources.arsc 字符串池 hash；
- mipmap/drawable PNG/WebP 文件 SHA；
- 图标 pHash（防换皮）；
- layout XML（解 AXML 后规范化再 hash）。

```python
# 图标 pHash 一行
from PIL import Image
import imagehash, zipfile, io
z = zipfile.ZipFile('a.apk')
for n in z.namelist():
    if 'mipmap' in n and n.endswith(('png','webp')):
        try:
            h = imagehash.phash(Image.open(io.BytesIO(z.read(n))))
            print(n, h)
        except: pass
```

### 3.5 SO 层同源
- ELF `.note.gnu.build-id`：完全相同 = 同源代码 + 同编译环境（强证据）。
- 函数 CFG hash（IDA `kam1n0`/`Diaphora`）：跨混淆/版本仍能匹配。
- 字符串/常量 Jaccard。

### 3.6 取证比赛同源比对模板
1. apksigner 比公钥指纹（强）
2. ssdeep / tlsh 比模糊哈希
3. jadx 反编 → 字符串 Jaccard
4. AndroSim → 类匹配率
5. 列共有 SDK AppKey / C2 / pinning 指纹
6. 综合判断置信度

> **报告语**：A 与 B 在公钥、Manifest meta-data、网络 C2 共 5 项一致，类相似度 89%，**判定同源置信度高**。

---

## 4. 静态分析对抗（**与之斗智的部分**）

### 4.1 嫌疑 App 常用静态对抗手段

#### A. 代码混淆
| 手法 | 描述 | 反制 |
| --- | --- | --- |
| **ProGuard / R8** | 类名/方法名/字段名重命名为 a/b/c | 用上下文/字符串/调用图反推；jadx 自动 deobf |
| **DexGuard** | ProGuard 加强版 + 字符串加密 + 反射隐藏 | 动态运行抓字符串 |
| **AllatoriObfuscator / DashO** | 商业 Java 混淆 | 同上 |
| **类名加 unicode / 不可见字符** | `o.l1l1l1` `O0OO0O` `аbcde`(西里尔) | 用 jadx 仍可读，但搜不到 |
| **方法名重载到极致**（多个 a()) | jadx 反编 OK，IDE 会糊涂 | 看签名区分 |
| **垃圾代码注入**（dead code） | 假分支 / 永真条件 | jadx deobf 大多识别 |
| **switch 控制流平坦化（Java 端）** | 整个方法变 dispatcher | 同 SO 端 OLLVM，需自写脚本反平坦化 |

#### B. 字符串加密
- AES/XOR/Base64/自家算法包裹关键字符串。
- **在静态时看不到任何 URL/key/SQL**，运行时才解密。
- 反制：
  - 找解密函数（多为 `decrypt(int)`/`a(int)` 接收 int 索引返回 String）；
  - hook 函数 → 遍历调用点拿明文表；
  - 或写脚本静态调用解密函数（SmaliRipper / D-810 / DexStringEncrypt 反制）。

```js
// frida hook 解密函数
Java.perform(() => {
  var Util = Java.use('com.foo.Util');
  Util.decrypt.overload('int').implementation = function(i){
    var r = this.decrypt(i);
    console.log('decrypt('+i+') ->', r);
    return r;
  };
});
```

#### C. 类抽空（Dex 加固第 2 代）
- 见 `android_packer_unpacker.md`：method.code = NULL，运行前回填。
- 反制：FRIDA-DEXDump / FART / BlackDex。

#### D. 整 Dex 加密（Dex 加固第 1 代）
- `assets/ijiami.dat` 等文件是密文 dex。
- 反制：找 SO 内解密 key + 算法（多 AES/RC4/XOR），离线解。

#### E. Native 化（Dex 加固第 4 代）
- 部分 Java 方法编译成 native，Java 端只剩声明。
- 反制：去 SO 找对应 native 函数 + IDA + frida。

#### F. SO 加密节段
- ELF 启动时自解密 `.text`。
- 反制：frida `Memory.dump` + SoFixer 修复（参 `android_packer_unpacker.md` §5.1）。

#### G. OLLVM 控制流平坦化 + 虚假分支
- IDA 看到一坨 dispatcher switch。
- 反制：
  - **deflat**（IDA 脚本）自动还原。
  - **D-810**（IDA 插件）。
  - Ghidra Decompiler 在新版有部分还原能力。
  - 实在不行：动态运行 trace 真实路径。

#### H. VMP-SO（自定义虚拟机）
- 关键函数变 `vm_run(bytecode)`。
- 反制：**取证不要硬翻译 vm，hook 入口/出口拿数据更快**。

#### I. 完整性校验
| 校验对象 | 反制 |
| --- | --- |
| APK 签名校验（`PackageManager.getPackageInfo` 比对） | hook 返回伪造证书 / objection 一行 |
| classes.dex 内 CRC 校验 | hook 校验函数返回 true |
| `BuildConfig` 编译时常量 | 修 BuildConfig 或 hook |
| SO MD5 校验 | 同上 |
| Magisk DenyList 检测 | 装 Shamiko 隐藏 |

```bash
# objection 一行绕签名校验（多数 App 适用）
objection -g com.foo.bar explore
> android root disable
> android sslpinning disable
```

#### J. 反静态符号
- 删除符号表（strip）；
- 加自家 section 名字混淆（`.text.encrypted`）；
- 把 Java 关键类名压成 `oO` 一类不可读字符串。

### 4.2 反制脚本/工具集合
| 工具 | 应对 |
| --- | --- |
| **jadx --deobf** | 自动识别 ProGuard 混淆类名重映射 |
| **simplify**（CalebFenton） | 模拟执行 dex 还原字符串/反混淆 |
| **dex-tools** + smali patch | 手动改 smali |
| **Quark** + 规则 | 标记反分析特征 |
| **D-810** / **deflat** / **angr / miasm** | OLLVM CFF 还原 |
| **LIEF** | ELF/DEX 修改库（重建 section/symbol） |
| **dexcalibur** | 全自动结合 frida 监控 + 反混淆 |

---

## 5. 动态分析对抗

### 5.1 嫌疑 App 常用动态对抗

#### A. 反调试
| 检测 | 反制 |
| --- | --- |
| `/proc/self/status` `TracerPid` ≠ 0 | hook `read` / `open(/proc/self/status)` 改返回 |
| `ptrace(PTRACE_TRACEME)` 自调 | hook `ptrace` 返回 0 |
| `wait4` 子进程检测 | 同上 |
| `Debug.isDebuggerConnected()` | hook 返回 false |
| `android.os.Debug.waitingForDebugger()` | 同上 |
| 信号 SIGSTOP/SIGTRAP 自陷 | hook signal 处理 |

#### B. 反 Frida / 反 Xposed
| 检测 | 反制 |
| --- | --- |
| 进程名扫描（`frida-server`、`frida-helper`） | 改 frida-server 名（任意名） |
| 端口扫描（27042 默认） | `frida-server -l 0.0.0.0:9999` 改端口 |
| `/proc/self/maps` 含 `frida-agent` | 用 frida-gadget early-instrumentation |
| 自检线程（线程数/CPU 时间异常） | 复杂，多要 patch |
| Java.use 调用栈检测 | frida-gadget |
| LD_PRELOAD 检测 | 删除环境变量痕迹 |

#### C. 反模拟器
| 检测点 | 反制 |
| --- | --- |
| `getprop ro.kernel.qemu` | hook getprop |
| `ro.hardware = goldfish/ranchu/vbox` | 改 build.prop / hook |
| `/proc/cpuinfo` `flags` 含 `hypervisor` | 改 ROM patch |
| MAC 前缀 08:00:27 / 52:54:00 | 改 MAC（雷电/夜神配置项） |
| 传感器列表缺失 | 模拟器装"传感器伪造模块" |
| **直接换真机** | 最稳 |

#### D. 反 Root
| 检测 | 反制 |
| --- | --- |
| `which su` / `/system/bin/su` 存在 | Magisk Hide / Shamiko / DenyList |
| Magisk Manager 包名 | Magisk 改包名 + Hide |
| `getprop ro.build.tags = test-keys` | hook getprop / patch build.prop |
| SafetyNet / Play Integrity | PlayIntegrityFix 模块 |
| 商业反作弊（如腾讯 ACE） | 几乎只能换真机 + 不动态 |

#### E. 反 SSL Pinning（加强版）
| 形式 | 反制 |
| --- | --- |
| OkHttp `CertificatePinner` | objection 一行 |
| 标准 `TrustManager` | 同上 |
| 自家 native 校验（在 SO 里 verify） | frida hook native verify 函数 |
| `network_security_config.xml` `<pin-set>` | 装 mitmproxy CA + objection |
| 双向证书 mTLS | 提取客户端证书 + key 注入 mitmproxy |

#### F. 反时间 / 反沙箱
| 检测 | 反制 |
| --- | --- |
| 检查 App 安装时长 / 系统启动时长 < 阈值 | hook `getStartElapsedRealtime` |
| 检查存在感拉长（5 分钟内不触发恶意逻辑） | 长时间运行触发 |
| 检测自动化框架（Appium/UI Automator） | 关闭检测进程 |
| 检测网络异常（沙箱常无网） | 配真实代理 |

#### G. 时间炸弹 / 地理围栏
| 形式 | 含义 |
| --- | --- |
| 仅在某日期后激活恶意行为 | 改设备时间 |
| 仅在某时区/语言/SIM 国家激活 | 改设备地区 / 模拟 SIM |
| 仅在受害人特征（IMEI/手机号黑/白名单）激活 | 改 IMEI 模拟受害人 |

> **取证关注**：动态对抗本身就是定罪证据 — App 用大量反检测说明作者有"反取证意图"，写在报告里加分。

### 5.2 反制工具集合
| 工具 | 用途 |
| --- | --- |
| **objection** | 通用反 root / SSL pinning / debug |
| **Magisk + Shamiko + DenyList** | 隐藏 root |
| **HideMyApplist** | 隐藏可疑 App 包名 |
| **PlayIntegrityFix** | 过 SafetyNet/Play Integrity |
| **frida-gadget** | 早期注入，过反 frida-server |
| **r2frida**（radare2 + frida） | 动态反汇编 |
| **dexcalibur** | 自动 hook + 反混淆 |
| **runtime-mobile-security (RMS)** | Web UI 看动态调用 |

---

## 6. 反编译/反汇编工具（按"用什么场景"分组）

### 6.1 Java/Kotlin 反编译
| 工具 | 优势 | 不足 | 取证常用度 |
| --- | --- | --- | --- |
| **jadx / jadx-gui** | 准、快、支持 deobf；GUI 搜索 | 偶尔解不出怪 dex | ⭐⭐⭐⭐⭐ |
| **GDA**（国产） | jadx 解不开时备选；中文界面 | 偶有 bug | ⭐⭐⭐⭐ |
| **dex2jar + JD-GUI / JD-Eclipse** | 老牌；Java 5/6 还行 | 现代 dex 普遍崩溃 | ⭐⭐ |
| **Procyon / CFR / Fernflower / Krakatau** | 各种 .class 反编引擎 | jadx 内部已用 | 间接用 |
| **Bytecode Viewer** | 集成多引擎对比 | 不快 | ⭐⭐⭐ |
| **Recaf** | 支持改 .class 重打 | 学习曲线 | ⭐⭐ |
| **enjarify** | dex→jar 转换 | 转完仍要其他工具反编 | 间接用 |

### 6.2 Smali 工具
- **baksmali** dex → smali；**smali** smali → dex。
- **apktool** 包装了上述 + 资源解码。
- 用途：jadx 反编不出时手读 smali；改 smali 重打包。

### 6.3 Native（SO/ELF）反汇编/反编译
| 工具 | 强项 | 备注 |
| --- | --- | --- |
| **IDA Pro** | F5 伪 C 行业标准；支持 ARM/ARM64/x86/MIPS | 商业 |
| **Hex-Rays Decompiler**（IDA 插件） | 同上 | 需另购 |
| **Ghidra** | NSA 开源；伪 C 不输 IDA；脚本生态强 | 免费首选 |
| **Binary Ninja** | 现代 UI；分析速度快 | 商业 |
| **Cutter / radare2** | 开源；脚本化 | 上手陡 |
| **Hopper**（macOS） | macOS 原生 | 商业 |
| **GDA**（含 SO 模式） | 国产 | 中文友好 |
| **Capstone / Keystone**（Python lib） | 程序化反汇编 | 嵌入脚本 |

### 6.4 反编译辅助
| 工具 | 用途 |
| --- | --- |
| **APKLab**（VS Code 插件） | apktool/jadx/smali 集成 |
| **AndroidLabs / MobSF** | 自动报告 |
| **APKiD** | 加固/反检测特征 |
| **Quark** | 威胁规则评分 |
| **Diaphora** | IDA 二进制 diff（同源/版本变化） |
| **kam1n0** | 跨架构 SO 函数搜索 |

### 6.5 特殊运行时反编
| 运行时 | 工具 |
| --- | --- |
| **Flutter** | reFlutter（patch libapp.so → 转 stalker dump 出 Dart 类） |
| **React Native + Hermes** | hbcdump、hermes-bytecode 工具 |
| **Unity il2cpp** | Il2CppDumper（生成 .NET dummy DLL） |
| **Unity Mono** | dnSpy / ILSpy 反编 .dll |
| **Cordova/Ionic/WebView** | 直接看 `assets/www/*.js` 或 sourcemap |
| **Xamarin** | dnSpy 反编 .NET assemblies |
| **HAP / ArkTS**（鸿蒙 NEXT） | abc-decompiler（社区） |
| **Lua（Cocos）** | luadec / unluac |

---

## 7. 动态调试

### 7.1 Java 层调试
| 工具 | 命令 | 备注 |
| --- | --- | --- |
| **Android Studio** | Run → Debug Attach Process | 仅 `debuggable=true` 的 App |
| **jdb**（JDK 自带） | `jdb -attach localhost:8700` | 命令行 |
| **smalidea**（IDEA 插件） | 直接调 smali 行 | 不需源码 |
| **Frida 替代调试** | hook + console.log | **取证主力** |

让 release App 可调试：用 `apktool` 反编 → 改 manifest `android:debuggable="true"` → 重签 → 装回。

```bash
apktool d app.apk -o app/
sed -i 's/debuggable="false"/debuggable="true"/; /<application/{/debuggable=/!s/<application/<application android:debuggable="true"/}' app/AndroidManifest.xml
apktool b app -o app_dbg.apk
apksigner sign --ks debug.keystore --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android app_dbg.apk
adb install -r app_dbg.apk
```

### 7.2 Native 层调试
| 工具 | 命令 |
| --- | --- |
| **gdbserver + gdb 多路连接** | `adb push gdbserver /data/local/tmp/`，`gdbserver :1234 --attach <pid>` |
| **lldb-server**（Android NDK 自带） | 同上 |
| **IDA Remote Debugger**（android_server） | 推 `android_server64` 到 `/data/local/tmp/`，IDA 远程 attach |
| **Ghidra Debugger** | 同上 |
| **r2** | `r2 -d attach://<pid>` |
| **Frida** | `Process.enumerateModules()` + `Interceptor.attach` |

### 7.3 Frida 在调试中的角色（**取证最常用**）
- 不是传统断点调试器，但可以**hook 任意 API + console.log**。
- 优势：
  - 跨 Java/Native；
  - 不需 debuggable；
  - 不需源码；
  - 不需重启 App（attach mode）。
- 劣势：
  - 不能精确单步；
  - 反 frida 对抗成熟。

### 7.4 Trace 工具
| 工具 | 用途 |
| --- | --- |
| **Frida-trace** | `frida-trace -U -i 'Java_*' com.foo` 自动 hook 所有 JNI |
| **frida-stalker** | 指令级 trace（性能差） |
| **strace / ltrace** | 系统调用 trace（root） |
| **dexcalibur** | 自动 hook + Web UI |
| **objection android hooking watch class_method** | 单方法 watch |

```bash
# 一行 trace 所有 OkHttp 调用
frida-trace -U -j '*okhttp3*!*' com.foo.bar
```

### 7.5 行为/网络抓包（参 `android_analysis_environment.md` §7）
- mitmproxy + objection sslpinning disable = 80% 题目通用。

---

## 8. 取证比赛题型与解法

### 8.1 类型 A："这两个 APK 是不是同一个 App"
1. 整 SHA-256 一致 → 直接同一。
2. 不一致 → ZIP 内逐文件 SHA + classes.dex SHA。
3. 写"内容完全一致 / 仅签名块差异 / 部分修改"。
4. **重打包识别**：META-INF 不同 + 资源/dex 大量相同 = 重打包。

### 8.2 类型 B："这两个 APK 是不是同一作者写的"
- 见 `android_app_attribution.md` §2-§5；本篇 §3 为算法补充。
- 模板答：公钥 / SDK AppKey / 字符串 Jaccard / 类匹配率 / build-id / pinning 指纹。

### 8.3 类型 C："APK 反调试无法分析"
1. APKiD 识别检测点；
2. objection 一句 disable；
3. 仍失败 → frida-gadget 嵌入 + 早期注入 + 改 frida-server 名/端口；
4. 仍失败 → 真机 + Magisk + Shamiko + HideMyApplist + PlayIntegrityFix；
5. 仍失败 → 静态硬怼 + 替换检测函数。

### 8.4 类型 D："APK 字符串都是密文，找不到 URL"
1. jadx 反编看是否所有 String 都来自 `decrypt(int)`；
2. frida hook 该函数遍历明文表；
3. 或直接动态抓包（mitmproxy + objection）；
4. SO 内字符串：动态运行 + memory dump 后搜。

### 8.5 类型 E："SO 用 OLLVM 平坦化"
1. IDA / Ghidra 反编看到 dispatcher switch；
2. deflat / D-810 自动还原；
3. 部分仍混乱 → 动态 trace 真实路径；
4. 取证目标：**只 hook 入口拿数据**比硬翻译节省 90% 时间。

### 8.6 类型 F："VMP-SO 加密关键算法"
1. 不要硬翻译 vm；
2. 找算法的 Java 调用入口 + 出口；
3. frida hook 这两个点拿明文输入输出；
4. 取证比赛要的是结果（解密后的数据），不是算法本身。

### 8.7 类型 G："APK 完整性校验，patch 后闪退"
1. objection / frida hook 校验函数返回 true；
2. 或直接 hook `Signature.equals` / `MessageDigest.digest` 返回伪造值；
3. 仍失败 → 动态 trace 检测点逐个干掉。

### 8.8 类型 H："Flutter / Unity / RN 的 App 反编译"
1. 识别运行时（参 `apk_internals.md` §6.4）；
2. 用对应工具：reFlutter / Il2CppDumper / hbcdump；
3. 关键算法仍可 frida hook native 函数。

### 8.9 类型 I："动态调试 / 跟踪某个方法"
1. Frida-trace 一行：`frida-trace -U -j '*decrypt*' com.foo`；
2. objection watch 单方法；
3. dexcalibur Web UI 监控；
4. 真断点调试：debuggable=true + Android Studio。

### 8.10 类型 J："样本与已知恶意家族 X 的关系"
1. VirusTotal 上传看 family；
2. AndroSim / Diaphora 与已知样本对比；
3. C2 域名 / pinning 指纹 / SDK AppKey 共用判断；
4. 报告"高置信度归属于 X 家族"。

---

## 9. 决策流（拿到对抗 App）

```
APKiD app.apk → 看到反调试/反 frida/反模拟器/壳
│
├─ 题目要数据（聊天/数据库内容）
│   ├─ 1. 装到真机 + Magisk + 全套隐藏
│   ├─ 2. objection -g <pkg> explore → ssl pinning disable + root disable
│   ├─ 3. frida hook 关键 API（Cipher.init / sqlite3_key / decrypt 函数）
│   ├─ 4. 拿到 key → 离线 sqlcipher 解 db
│   └─ 5. 提交答案
│
├─ 题目要算法
│   ├─ jadx 反编（壳 → 先 frida-dexdump 脱壳）
│   ├─ IDA / Ghidra 反 SO（OLLVM → deflat / 动态 trace）
│   ├─ VMP → 不翻译，hook 入口/出口拿数据
│   └─ 写算法描述 + 关键函数地址
│
├─ 题目要"是否同一/同源"
│   ├─ 同一性 → SHA + ZIP 内文件 SHA + diffoscope
│   ├─ 同源性 → 公钥 + ssdeep/tlsh + 字符串 Jaccard + AndroSim + SDK AppKey
│   └─ 报告置信度
│
└─ 题目要"对抗手段"
    ├─ 列出反调试/反 frida/反 root/反模拟器/反 SSL pinning 各项
    ├─ 截图 logcat 反推
    └─ 写"对抗强度评级"
```

---

## 10. 命令速查

```bash
# 同一性
sha256sum a.apk b.apk
diffoscope a.apk b.apk --html report.html

# 同源性 - 模糊哈希
ssdeep -bc a.apk b.apk
tlsh -c a.apk b.apk

# 同源性 - 类比对
androsim a.apk b.apk

# 同源性 - 签名
apksigner verify --print-certs a.apk
apksigner verify --print-certs b.apk

# 反编译 Java
jadx-gui app.apk
GDA app.apk

# 反编译 Native
ida64 lib/arm64-v8a/libtarget.so
ghidraRun

# 反混淆 OLLVM
# IDA + deflat.py / D-810 / d_810

# Frida 调试
frida -U -f com.foo.bar -l hook.js --no-pause
frida-trace -U -j '*decrypt*' com.foo.bar
objection -g com.foo.bar explore

# 反静态对抗 - 字符串解密
# hook 解密函数遍历调用点

# 反动态对抗 - 一键全开
adb install Magisk.apk
# 装 LSPosed + Shamiko + HideMyApplist + PlayIntegrityFix

# 真机 GDB
adb push android-ndk/.../gdbserver /data/local/tmp/
adb shell /data/local/tmp/gdbserver :1234 --attach $(pidof com.foo.bar)
gdb-multiarch
> target remote 127.0.0.1:1234

# IDA remote debugger
adb push ida_pro/dbgsrv/android_server64 /data/local/tmp/
adb shell /data/local/tmp/android_server64
# IDA: Debugger → Remote Linux/Android → 127.0.0.1:23946

# Smali patch + 重签
apktool d app.apk -o app/
# 改 smali
apktool b app -o new.apk
apksigner sign --ks debug.keystore new.apk
```

---

## 11. 常见坑

1. **同一性误判**：APK 重打包后整 SHA 必变；不能单看整 SHA 否定同一，必须看 dex/资源 SHA。
2. **同源置信度不能写"必同源"**：除非公钥完全一致；公钥不同时永远写置信度。
3. **ssdeep / tlsh 对加固后样本不稳**：壳改变了大量字节；同源样本相似度可能低于阈值，需多算法叠加。
4. **AndroSim 跑加固 APK 无意义**：必须先脱壳。
5. **objection ssl pinning disable 不万能**：自家 native 校验绕不过；要 frida 手 hook native verify。
6. **frida 改名后 App 仍检测出**：可能扫端口 / 扫 maps / 扫线程；改一个不够，全要改。
7. **真机刷 ROM patch 太重**：取证比赛通常用 Magisk 模块组合即可，不必改源码。
8. **debuggable 重签会改 hash**：原检材 SHA 永久变 → 别动原文件，做副本。
9. **GDA 中文路径**：部分版本不支持中文路径，移到英文路径再开。
10. **IDA 没装 ARM64 反编**：F5 出错；确认 Hex-Rays 模块包含 arm64。
11. **Ghidra 大型 SO 卡爆**：分析时间几十分钟；先关掉 Decompiler Parameter ID。
12. **Frida-server / 客户端版本必须严格一致**：不一致连不上。
13. **反混淆工具误删合法代码**：deflat 偶尔删除关键 dispatcher；最好与原版本 diff。
14. **hook 函数后 App 崩溃**：原函数有副作用（更新 state）；hook 后必须调原函数再做记录。
15. **Hex 编辑改 SO 后签名失效**：签名 v2/v3 校验整文件；改 SO 必须重签 APK。
16. **取证报告写 anti-X 项**：列举对抗手段在报告里**不要遗漏**，是定罪/恶意性的证据。
17. **reFlutter / Il2CppDumper 版本敏感**：Flutter / Unity 版本对应工具版本；不匹配会失败。

---

## 12. 交叉链接
- `apk_internals.md`：APK/DEX/SO 内部结构
- `android_packer_unpacker.md`：脱壳详细
- `apk_crypto_analysis.md`：算法/密钥提取
- `android_app_attribution.md`：同源指标完整列表
- `android_analysis_environment.md`：工具环境
- `database_forensics.md`：拿到 key 后解 db
- `wechat_deep_dive.md` / `popular_apps_forensics.md`：具体 App
- `lock_password_forensics.md`：与反 root 检测同框架
- `quick_reference.md`：顶层入口
