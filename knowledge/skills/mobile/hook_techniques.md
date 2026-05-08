# Hook 技术（取证比赛视角）

> 适用：取证比赛中需要"插入运行时" 抓 key / 抓明文 / 抓证书 / 抓字符串 / 改返回值。题目特征：见到"App 数据加密了，如何拿到密钥"、"App 反 root，如何绕过"、"App 走自家协议，如何抓明文" 等。
>
> 三大框架：**Frida**（跨平台主力）、**Xposed / LSPosed**（Android 持久化）、**Cydia Substrate**（iOS 越狱）。本篇定位**取证用脚本库**而非开发教程。

---

## 1. 三大 Hook 框架对照

| 维度 | Frida | Xposed / LSPosed | Cydia Substrate |
| --- | --- | --- | --- |
| **平台** | Android / iOS / Windows / macOS / Linux | Android | iOS（越狱） |
| **持久性** | 进程一关就失效（动态注入） | 重启后仍生效 | 重启后仍生效 |
| **是否需 root/越狱** | 真机要 root；模拟器多免；可用 frida-gadget 嵌入免 root | **必须 root**（旧 Xposed） / **Magisk + Zygisk**（LSPosed 现代） | **必须越狱** |
| **粒度** | 函数级 + 内存级 + 指令级 | 函数级（XposedBridge） | 函数级（MSHookFunction） |
| **语言** | JavaScript（NodeJS 风格） | Java 模块（apk） | Objective-C / C / Swift |
| **侵入度** | 低（运行时注入） | 高（替换 Zygote/启动时挂钩） | 高（注入到所有进程） |
| **重启不丢** | ❌ | ✅ | ✅ |
| **取证适用** | **首选**（即插即拔，最快） | 持续监控；过反 frida | iOS 越狱机的 Substrate 等价物 |

> **取证比赛 90% 的 hook 任务用 Frida + Objection 即可解决**；当 App 反 frida 强 / 需要长时监控 / 必须无外连接 → 上 LSPosed；iOS 全部用 Substrate / Frida iOS 模式。

---

## 2. Frida（**取证主力**）

### 2.1 工作模式
| 模式 | 说明 | 取证用法 |
| --- | --- | --- |
| **Spawn**（`-f <pkg>`） | 启动并 attach；可拦 onCreate 之前的初始化 | 抓初始化阶段的 key 派生 |
| **Attach**（`-n <pkg>` / `-p <pid>`） | 附加到运行中进程 | App 已启动时用 |
| **Gadget**（嵌入 .so） | App 自带 frida 库，外部不需要 server | 真机不能跑 frida-server / 反 frida 强时 |
| **Remote**（`frida -H <host>:<port>`） | 远程连接 | 多机并行 |

### 2.2 安装速记
```bash
# PC 端
pip install frida-tools

# 设备端（root 真机/模拟器）
# 下载对应架构二进制 https://github.com/frida/frida/releases
adb push frida-server-<ver>-android-arm64 /data/local/tmp/frida-server
adb shell chmod 755 /data/local/tmp/frida-server
adb shell /data/local/tmp/frida-server &

# 验证
frida-ps -U
```

### 2.3 Java 层 Hook（**取证最常用**）

#### 模板：基础类方法 hook
```js
Java.perform(() => {
  var Cipher = Java.use('javax.crypto.Cipher');
  Cipher.init.overload('int', 'java.security.Key').implementation = function(opmode, key) {
    var keyBytes = Java.use('javax.crypto.spec.SecretKeySpec').$cast(key).getEncoded();
    console.log('[Cipher.init] mode=' + opmode + ' key=' + bytes2hex(keyBytes));
    console.log(Java.use('android.util.Log').getStackTraceString(Java.use('java.lang.Throwable').$new()));
    return this.init(opmode, key);
  };
});

function bytes2hex(bytes){
  var s = '';
  for (var i=0;i<bytes.length;i++) s += ('00'+(bytes[i]&0xff).toString(16)).slice(-2);
  return s;
}
```

#### 模板：所有重载一次性 hook
```js
Java.perform(() => {
  var C = Java.use('com.foo.Crypto');
  C.decrypt.overloads.forEach(o => {
    o.implementation = function(){
      var args = Array.prototype.slice.call(arguments);
      var r = o.apply(this, args);
      console.log('[decrypt]', JSON.stringify(args), '->', r);
      return r;
    };
  });
});
```

#### 模板：枚举类 / 搜方法
```js
Java.perform(() => {
  Java.enumerateLoadedClasses({
    onMatch: function(name){
      if (/Cipher|AES|Encrypt|Decrypt|Sign/.test(name) && !name.startsWith('java.')) {
        console.log(name);
      }
    },
    onComplete: function(){}
  });
});
```

#### 模板：获取调用栈（**取证黄金**）
```js
Java.perform(() => {
  var Throwable = Java.use('java.lang.Throwable');
  var Log = Java.use('android.util.Log');
  function stack(){ return Log.getStackTraceString(Throwable.$new()); }

  Java.use('java.lang.String').getBytes.overload().implementation = function(){
    var r = this.getBytes();
    if (this.toString().startsWith('http')) {
      console.log('URL:', this.toString(), '\n', stack());
    }
    return r;
  };
});
```

### 2.4 Native 层 Hook
```js
// 1. 找到 SO 中的导出函数
var addr = Module.findExportByName('libtarget.so', 'doEncrypt');
Interceptor.attach(addr, {
  onEnter(args) {
    console.log('[doEncrypt] arg0=' + args[0]);
    console.log(hexdump(args[1], {length: 64, header:true}));
    this.outBuf = args[2];
  },
  onLeave(retval) {
    console.log('[doEncrypt] ret=' + retval);
    if (this.outBuf) console.log(hexdump(this.outBuf, {length:64}));
  }
});

// 2. 偏移地址 hook（无导出）
var base = Module.findBaseAddress('libtarget.so');
Interceptor.attach(base.add(0x12345), {
  onEnter(args){ ... }
});

// 3. JNI RegisterNatives 监控（动态注册的 native 函数）
var p = Module.findExportByName('libart.so', '_ZN3art3JNI15RegisterNativesEP7_JNIEnvP7_jclassPK15JNINativeMethodi');
Interceptor.attach(p, {
  onEnter(args){
    var n = args[3].toInt32();
    var arr = args[2];
    var ptrSize = Process.pointerSize;
    for (var i=0;i<n;i++){
      console.log(
        Memory.readUtf8String(arr.add(i*ptrSize*3).readPointer()),
        Memory.readUtf8String(arr.add(i*ptrSize*3+ptrSize).readPointer()),
        arr.add(i*ptrSize*3+ptrSize*2).readPointer()
      );
    }
  }
});

// 4. 替换函数实现
Interceptor.replace(addr, new NativeCallback(function(a,b){
  return 0;   // 直接返回 0 = 检测函数失效
}, 'int', ['pointer','int']));
```

### 2.5 内存搜索（**找 key/明文 黄金手法**）
```js
// 在所有 RX 区域搜 dex magic（脱壳）
Process.enumerateRanges('r--').forEach(r => {
  try {
    var found = Memory.scanSync(r.base, r.size, 'de 78 0a 03 35 00 00 00');  // dex
    found.forEach(m => console.log('dex@', m.address, m.size));
  } catch(e){}
});

// 搜已知字符串
Memory.scanSync(addr, size, 'aa bb cc dd');
Memory.scanSync(addr, size, '?? 41 53 ??');   // 通配
```

### 2.6 Stalker（指令级 trace）
- 性能差，仅短时间窗使用。
- 用途：trace VMP 解释器的真实执行路径。

```js
Stalker.follow(Process.getCurrentThreadId(), {
  events: { call: true, ret: true },
  onCallSummary(summary) {
    Object.keys(summary).slice(0,10).forEach(k => console.log(k, summary[k]));
  }
});
```

### 2.7 frida-trace（一行 trace）
```bash
# 自动 hook 所有 OkHttp 类
frida-trace -U -j '*okhttp3*!*' com.foo.bar

# 自动 hook 所有 JNI Java_ 函数
frida-trace -U -i 'Java_*' com.foo.bar

# Native 函数
frida-trace -U -I 'libcrypto.so' com.foo.bar
frida-trace -U -i 'EVP_*' com.foo.bar
```

### 2.8 frida-gadget（嵌入式，免 root/绕反 frida）
```bash
# objection 一键嵌入
objection patchapk -s app.apk
# 输出 app.objection.apk → adb install
adb install app.objection.apk
# App 启动后 frida 直连 Gadget
frida -U -n Gadget -l hook.js
```

### 2.9 Objection（基于 Frida 的便利层，**取证大杀器**）
```bash
pip install objection
objection -g com.foo.bar explore

# 关键命令（在 objection shell 内）
android root disable                     # 绕 root 检测
android sslpinning disable               # 绕 SSL pinning（一键覆盖主流框架）
android hooking list classes             # 列所有类
android hooking search classes Crypto    # 搜类
android hooking list class_methods com.foo.Crypto
android hooking watch class_method com.foo.Crypto.decrypt
android hooking generate simple com.foo.Crypto.decrypt > hook.js
android filesystem ls /data/data/com.foo.bar/databases
android filesystem download /data/data/com.foo.bar/databases/x.db ./x.db
android keystore list                    # 列 KeyStore（含别名）
android keystore export <alias>
android intent launch_activity com.foo.bar.SecretActivity
android shell_exec "id"
memory list modules                      # 列加载模块
memory dump all <module>                 # dump 模块
```

---

## 3. Xposed / LSPosed（**Android 持久化 Hook**）

### 3.1 演进关系
- **Xposed**（Rovo89）：rovo89 神级框架，仅支持 Android ≤ 8。
- **EdXposed**（Riru 模块）：基于 Riru，支持 Android 8–9。
- **LSPosed**（基于 Magisk Zygisk）：**现代主流**，支持 Android 8.1 – 14。
- **TaiChi 太极 / VirtualXposed**：免 root 容器（VirtualApp 沙盒里跑），仅特定 App 内 hook。

### 3.2 LSPosed 部署
```
1. Magisk root 设备
2. 装 Magisk Zygisk（Magisk 设置开启）
3. 刷 LSPosed Zygisk Module（zip）→ 重启
4. 进 LSPosed Manager → 启用 Zygisk 模式
5. 装 hook 模块（apk）
6. 模块设置 → 选作用域（要 hook 的 App）
7. 重启 App 生效
```

### 3.3 Xposed 模块取证常用清单
| 模块 | 用途 |
| --- | --- |
| **JustTrustMe** | 自动绕 SSL pinning（OkHttp/Retrofit/HttpClient） |
| **HideMyApplist** | 隐藏指定 App 包名（防嫌疑 App 检测 LSPosed/Magisk Manager） |
| **Shamiko** | Magisk DenyList 增强（绕 SafetyNet/反 root） |
| **Inspeckage** | 自动运行时审计（Java 调用 + I/O + 加密 + 网络） |
| **AppOps** | 权限细粒度控制 |
| **XPrivacyLua** | 数据伪造（伪 IMEI / 位置 / 联系人） |
| **TrackerControl** | 监控 App 网络访问域名 |
| **Storage Redirect** | 重定向 App 存储路径（取证镜像化用） |
| **DisableFlagSecure** | 强制可截屏（嫌疑 App 屏幕被锁防截屏时） |
| **HookTime** | 改 App 内系统时间（绕时间炸弹） |
| **PlayIntegrityFix** | 过 SafetyNet/Play Integrity |

### 3.4 自写 LSPosed 模块骨架（取证少用，但要懂）
```java
public class HookEntry implements IXposedHookLoadPackage {
  @Override
  public void handleLoadPackage(XC_LoadPackage.LoadPackageParam lpparam) throws Throwable {
    if (!lpparam.packageName.equals("com.foo.bar")) return;
    XposedHelpers.findAndHookMethod(
      "com.foo.bar.Crypto", lpparam.classLoader,
      "decrypt", String.class,
      new XC_MethodHook(){
        @Override
        protected void afterHookedMethod(MethodHookParam param) {
          XposedBridge.log("[decrypt] " + param.args[0] + " -> " + param.getResult());
        }
      });
  }
}
```
- AndroidManifest.xml 加 `<meta-data android:name="xposedmodule" android:value="true"/>`。
- `assets/xposed_init` 写入入口类。

### 3.5 Inspeckage（**取证黄金模块**）
- 启动后自动 hook：
  - `Cipher.init/doFinal/update`
  - `MessageDigest.update/digest`
  - `KeyGenerator/KeyPairGenerator`
  - `SQLite open/query/execSQL`
  - `WebView loadUrl/postUrl`
  - `SharedPreferences edit/getString`
  - `File open/read/write`
  - `Socket connect/send/recv`
  - `Runtime exec`
  - `Telephony getDeviceId`
- Web UI（端口 8008）查看实时事件。
- 比赛若无法上 frida：装 Inspeckage 即可白盒看 80% 行为。

### 3.6 Xposed/LSPosed vs Frida 取证场景选择
| 场景 | 选哪个 |
| --- | --- |
| 一次性抓 key / 一次性绕 SSL | **Frida + objection** |
| App 启动期 hook（onCreate 前） | Frida `-f` spawn 或 LSPosed |
| 需要持续监控（数小时/数天） | LSPosed + Inspeckage |
| App 反 frida 强（检测 frida-server / port / agent） | LSPosed（启动注入，更隐蔽）+ Shamiko + HideMyApplist |
| 多 App 同时监控 | LSPosed |
| 取证机房无外接 PC，只能设备本地 | LSPosed + Inspeckage Web UI |

---

## 4. Cydia Substrate（**iOS 越狱**）

### 4.1 是什么
- iOS 越狱后的"动态 Hook 框架"，相当于 Android 的 Xposed 等价物。
- 全名 **MobileSubstrate / Substrate**（Cydia 时代）。
- 现代 iOS：被 **libhooker / Substitute / ElleKit** 等替代实现，但接口兼容。
- 越狱机标配：`/Library/MobileSubstrate/DynamicLibraries/*.dylib` 自动注入到目标 App。

### 4.2 工作原理
- App 启动时，Substrate `dyld` insert 自家 dylib；
- dylib 的 `+ (void)load` 内调 `MSHookFunction(target, replacement, &orig)` / `MSHookMessageEx(class, sel, replacement, &orig)`；
- 执行流被劫持。

### 4.3 工具链 Theos（开发 tweak）
```bash
# 安装 Theos（macOS 主流）
git clone --recursive https://github.com/theos/theos.git ~/theos
export THEOS=~/theos

# 创建 tweak 工程
$THEOS/bin/nic.pl
> Choose a Template (required): 11. iphone/tweak
> Project Name: HookSomeApp
> Package Name: com.test.hooksomeapp
> Author: ...
> [iphone/tweak] MobileSubstrate Bundle filter: com.target.app   # 目标 App bundle id
```

### 4.4 Tweak 模板（Logos 语法）
```objc
// Tweak.x
%hook TargetClass

- (NSString *)decryptString:(NSString *)cipher {
    NSString *r = %orig;     // 调原方法
    NSLog(@"[HOOK] decrypt(%@) -> %@", cipher, r);
    return r;
}

- (id)init {
    NSLog(@"[HOOK] init called");
    return %orig;
}

%end

// C 函数 hook
%hookf(int, "SecRandomCopyBytes", void *r, size_t n, uint8_t *bytes) {
    int ret = %orig;
    NSLog(@"[HOOK] SecRandomCopyBytes: %@", [[NSData dataWithBytes:bytes length:n] description]);
    return ret;
}
```

```bash
# 编译 + 部署
make package install
# 自动通过 SSH 上传到设备 + 重启 SpringBoard
```

### 4.5 不用 Theos 直接写 .dylib
```objc
// hook.m
#import <objc/runtime.h>
#import <substrate.h>

static IMP orig_decrypt;
NSString *new_decrypt(id self, SEL _cmd, NSString *cipher) {
    NSString *r = ((NSString *(*)(id, SEL, NSString *))orig_decrypt)(self, _cmd, cipher);
    NSLog(@"[HOOK] %@ -> %@", cipher, r);
    return r;
}
__attribute__((constructor))
static void init() {
    Class cls = objc_getClass("TargetClass");
    MSHookMessageEx(cls, @selector(decryptString:), (IMP)new_decrypt, &orig_decrypt);
}
```

### 4.6 Substrate 取证常用 tweak
| Tweak | 用途 |
| --- | --- |
| **SSL Kill Switch 2** | 全局禁用 iOS SSL pinning |
| **Flex 3** | App 内 GUI 改任意属性 + 调任意方法（不写代码） |
| **Frida** for iOS | 同 Android，越狱后 frida-server 跑在设备上 |
| **iOSOpenDev** | 开发集成 |
| **Liberty Lite** | 绕越狱检测 |
| **A-Bypass / Choicy** | 防 App 检测越狱 |

### 4.7 Frida on iOS（**强烈推荐 over Substrate**）
- iOS 越狱后装 frida-server（Cydia/Sileo 仓库）；
- PC 端 `frida-ps -U` 看进程；
- ObjC API：
```js
ObjC.classes.NSString.stringWithString_('test');
var hook = ObjC.classes.TargetClass['- decryptString:'];
Interceptor.attach(hook.implementation, {
  onEnter(args){
    console.log('decrypt(', new ObjC.Object(args[2]).toString(), ')');
  },
  onLeave(ret){
    console.log('-> ', new ObjC.Object(ret).toString());
  }
});
```

> **取证比赛 iOS hook**：除非题目要"持久 + 不出网"，否则**全用 Frida iOS 模式**——开发快、不重启、跨平台命令一致。

### 4.8 不越狱场景：MonkeyDev / Theos Jailed
- 重签 IPA + 注入 dylib；
- 装到非越狱设备运行；
- 适用：手上无越狱机但有源 IPA。

---

## 5. 取证比赛常见 Hook 用例库

### 5.1 抓 SQLCipher key
```js
['sqlite3_key','sqlite3_key_v2','sqlite3_rekey','sqlite3_rekey_v2'].forEach(n => {
  var f = Module.findExportByName(null, n);
  if (!f) return;
  Interceptor.attach(f, {
    onEnter(args){
      var keyArg = n.endsWith('v2') ? args[2] : args[1];
      var nArg   = n.endsWith('v2') ? args[3] : args[2];
      var len = nArg.toInt32();
      console.log('[' + n + '] key=', hexdump(keyArg, {length:len, header:false}));
    }
  });
});
```

### 5.2 抓 AES key/IV（Java 层）
```js
Java.perform(() => {
  var K = Java.use('javax.crypto.spec.SecretKeySpec');
  K.$init.overload('[B','java.lang.String').implementation = function(k, alg){
    console.log('[KEY]', alg, '=', bytes2hex(k));
    return this.$init(k, alg);
  };
  var I = Java.use('javax.crypto.spec.IvParameterSpec');
  I.$init.overload('[B').implementation = function(iv){
    console.log('[IV]', bytes2hex(iv));
    return this.$init(iv);
  };
});
```

### 5.3 抓 OkHttp 请求/响应
```js
Java.perform(() => {
  var Builder = Java.use('okhttp3.Request$Builder');
  Builder.build.implementation = function(){
    var r = this.build();
    console.log('[REQ]', r.method(), r.url(), r.headers());
    return r;
  };
  var R = Java.use('okhttp3.Response');
  R.body.implementation = function(){
    var b = this.body();
    if (b) {
      var bs = Java.use('okhttp3.ResponseBody').$cast(b);
      console.log('[RESP]', this.code(), bs.string());
    }
    return b;
  };
});
```
> 注意：响应体读一次后需重设 source；上面代码会消耗 body。生产用 `peekBody`。

### 5.4 抓 String.<init> / String.getBytes（**字符串解密**）
```js
Java.perform(() => {
  var S = Java.use('java.lang.String');
  S.$init.overload('[B').implementation = function(b){
    var s = this.$init(b);
    if (b.length > 5 && b.length < 200) console.log('String([B]):', this.toString());
    return s;
  };
});
```

### 5.5 绕 root 检测
```js
Java.perform(() => {
  // 文件存在性
  var File = Java.use('java.io.File');
  File.exists.implementation = function(){
    var p = this.getPath();
    if (/su|magisk|busybox|xposed/i.test(p)) {
      console.log('[ROOT-HIDE]', p);
      return false;
    }
    return this.exists();
  };
  // 命令执行
  var Runtime = Java.use('java.lang.Runtime');
  Runtime.exec.overload('java.lang.String').implementation = function(cmd){
    if (/su|which|mount/.test(cmd)) {
      console.log('[ROOT-HIDE-EXEC]', cmd);
      throw Java.use('java.io.IOException').$new('blocked');
    }
    return this.exec(cmd);
  };
});
```

### 5.6 绕反 frida（自定义自检）
```js
// 改 maps 内 frida-agent 字符串
var maps = Module.findExportByName('libc.so', 'fopen');
Interceptor.attach(maps, {
  onEnter(args){
    var p = Memory.readCString(args[0]);
    if (p && p.indexOf('/proc/self/maps')!==-1) this.spoof = true;
  }
});
// fread 替换
var fread = Module.findExportByName('libc.so', 'fread');
Interceptor.attach(fread, {
  onLeave(ret){
    // 简化：实际要 patch 内容
  }
});
// 通常更直接：用 frida-gadget 替代 server，从根上绕"扫端口/扫进程名"检测
```

### 5.7 抓 SharedPreferences 写入
```js
Java.perform(() => {
  var Editor = Java.use('android.app.SharedPreferencesImpl$EditorImpl');
  ['putString','putInt','putLong','putBoolean','putFloat'].forEach(m => {
    Editor[m].implementation = function(k, v){
      console.log('[Pref]', m, k, '=', v);
      return this[m](k, v);
    };
  });
});
```

### 5.8 抓 SQLite 写入
```js
Java.perform(() => {
  var DB = Java.use('android.database.sqlite.SQLiteDatabase');
  DB.execSQL.overload('java.lang.String').implementation = function(s){
    console.log('[SQL]', s);
    return this.execSQL(s);
  };
  DB.insert.implementation = function(tbl, nullCol, values){
    console.log('[INSERT]', tbl, values);
    return this.insert(tbl, nullCol, values);
  };
});
```

### 5.9 抓 WebView URL/JS
```js
Java.perform(() => {
  var WV = Java.use('android.webkit.WebView');
  WV.loadUrl.overload('java.lang.String').implementation = function(u){
    console.log('[WebView]', u);
    return this.loadUrl(u);
  };
});
```

### 5.10 改 App 时间（绕时间炸弹）
```js
Java.perform(() => {
  var Sys = Java.use('java.lang.System');
  Sys.currentTimeMillis.implementation = function(){
    return 1700000000000;   // 自己改的时间
  };
});
```

### 5.11 抓 JNI RegisterNatives 映射（Native 隐藏函数）
（见 §2.4 模板 3）

### 5.12 dump 进程内存找 dex / so / 任意 magic
```js
function dumpRanges(magic){
  Process.enumerateRanges('r--').forEach(r => {
    if (r.size > 1024*1024*256) return;
    try {
      Memory.scanSync(r.base, r.size, magic).forEach(m => {
        console.log('found@', m.address);
      });
    } catch(e){}
  });
}
dumpRanges('64 65 78 0a 30 33 35 00');   // dex magic
dumpRanges('7f 45 4c 46');               // ELF magic
```

---

## 6. Hook 调度与脚本组织

### 6.1 项目结构推荐
```
hook_project/
├── lib/
│   ├── utils.js          # bytes2hex / stack / dumpMemory
│   └── stalker.js
├── targets/
│   ├── crypto.js         # 加密函数 hook
│   ├── network.js        # OkHttp / URL hook
│   ├── storage.js        # Pref / SQLite hook
│   └── antiroot.js       # 绕检测
└── main.js               # 入口，按需 require
```

```js
// main.js
function loadScript(name) {
  var url = 'frida:///path/to/' + name + '.js';
  // frida 不直接支持 require；推荐 frida-compile 打包
}
```

### 6.2 frida-compile（多文件打包）
```bash
npm install frida-compile
frida-compile main.js -o agent.js -w
frida -U -f com.foo.bar -l agent.js --no-pause
```
- `-w` watch 模式，自动重编。

### 6.3 Python 控制端（**取证脚本化首选**）
```python
import frida, sys
def on_msg(msg, data):
    if msg['type']=='send': print('[recv]', msg['payload'])
    elif msg['type']=='error': print('[err]', msg['stack'])

dev = frida.get_usb_device()
session = dev.attach('com.foo.bar')
script = session.create_script(open('agent.js').read())
script.on('message', on_msg)
script.load()
sys.stdin.read()
```
- 用 `script.exports.xxx()` 双向 RPC：
```js
// agent.js
rpc.exports = {
  decrypt: function(s){ return MyDecrypt(s); }
};
```
```python
print(script.exports.decrypt('aabbccdd'))
```

---

## 7. 比赛常见题型 → Hook 方案

| 题 | Hook 方案 |
| --- | --- |
| 找 SQLCipher key | §5.1 |
| 找 AES/IV / RC4 key | §5.2 / hook native crypto API |
| 抓 App 上传内容（HTTPS） | objection sslpinning + mitmproxy |
| 自家加密协议明文 | hook send/recv 或 `SSL_read/SSL_write` |
| 字符串都是密文 | §5.4 hook String 构造 / hook decrypt 函数 |
| 反 root 闪退 | §5.5 |
| 反 frida 闪退 | frida-gadget 嵌入 / LSPosed 替代 |
| 反模拟器 | hook getprop / 真机 |
| 反 SSL pinning（自家 native 校验） | objection 起手 → 不行就 frida hook native verify |
| 时间炸弹 | §5.10 改时间 |
| Dex 抽空脱壳 | frida-dexdump（基于 Memory.scanSync） |
| SO 加密节段 | Memory.dump + SoFixer |
| App 卡在反检测 splash | LSPosed + 全套隐藏 |
| 持续监控 N 小时 | LSPosed + Inspeckage |
| iOS 越狱 App 解密 | Frida iOS / Substrate tweak |
| iOS 不越狱 hook | MonkeyDev 重签 + dylib 注入 |

---

## 8. 命令速查

```bash
# Frida
pip install frida-tools
frida-ps -U
frida -U -f com.foo.bar -l hook.js --no-pause
frida -U -n com.foo.bar -l hook.js
frida-trace -U -j '*okhttp3*!*' com.foo.bar
frida-trace -U -i 'Java_*' com.foo.bar
frida-trace -U -I 'libcrypto.so' com.foo.bar
frida-compile main.js -o agent.js -w

# Objection
objection -g com.foo.bar explore
objection patchapk -s app.apk         # 嵌入 frida-gadget

# LSPosed 部署
# Magisk → Zygisk on → 刷 LSPosed.zip → 重启 → LSPosed Manager

# 推 frida-server
adb push frida-server /data/local/tmp/
adb shell chmod 755 /data/local/tmp/frida-server
adb shell /data/local/tmp/frida-server -l 0.0.0.0:9999 &
frida -H 192.168.1.x:9999 -f com.foo.bar -l hook.js

# iOS Frida（越狱）
# 在 Cydia/Sileo 装 Frida → 自动跑 frida-server
frida-ps -U
frida -U -n SpringBoard

# Substrate 编译
make package install      # Theos 下

# 看模块加载
frida -U -p $(adb shell pidof com.foo.bar) -e "Process.enumerateModules().forEach(m => console.log(m.name, m.base))"
```

---

## 9. 常见坑

1. **Frida server 与客户端版本必须严格一致**：差一个版本就连不上。
2. **架构匹配**：arm64-v8a 设备必须 frida-server arm64；模拟器多是 x86_64。
3. **spawn 与 attach 区别**：抓初始化阶段必须 `-f` spawn；attach 太晚错过。
4. **Java.perform 不能省**：所有 Java API 调用都要包在 `Java.perform(()=>{...})` 内。
5. **重载方法**：必须明确 `overload('arg_type')`；不指定可能 hook 错或全报错。
6. **数组类型**：byte[] 是 `'[B'`、int[] 是 `'[I'`、String[] 是 `'[Ljava.lang.String;'`。
7. **数组转 hex**：`Java.array('byte', byteArr)` 才是 JS 数组；`bytes2hex` 自写。
8. **OkHttp Response.body() 只能读一次**：hook 后要重置 source；用 peekBody 更安全。
9. **objection sslpinning 不万能**：自家校验 / native pinning 仍要 frida 单独 hook。
10. **frida-trace 默认只 attach 已加载模块**：动态加载的 SO 会漏；用 `Module.load` 监听。
11. **Stalker 性能差**：开了 App 卡死；只在很短窗口启用。
12. **LSPosed 模块作用域忘选**：装了不生效；要在 Manager 里勾选 App。
13. **LSPosed 日志看不到**：开 Manager → Logs → 选模块；或 `adb logcat -s LSPosed`。
14. **Inspeckage 端口 8008**：要 `adb forward tcp:8008 tcp:8008` 才能 PC 浏览器看。
15. **Substrate vs Frida iOS**：取证场景几乎都用 Frida；Substrate 仅在持久化要求高时。
16. **frida-gadget 嵌入会改 APK SHA**：不能用嵌入的 APK 当原始证据；做副本分析。
17. **改 App 时间不影响系统时间**：仅 `System.currentTimeMillis` 这个 API 被改；若 App 用 `SystemClock` / native 系统调用绕过，要逐个 hook。
18. **多进程 App**：`com.foo.bar:remote` `:push` 等子进程，frida 默认只 attach 主进程；用 `frida -U -f com.foo.bar --realm=child` 或 LSPosed 全进程注入。
19. **加固 App 启动慢**：spawn 后等 3–5 秒再注入 hook（避开自检阶段）。
20. **取证完整性**：装 frida-server / LSPosed 模块 = 改设备状态；必须**复制副本到模拟器或备用机**做 hook，原检材保持不动。

---

## 10. 决策流（取证场上选什么 hook）

```
要 hook 的目标
├─ 一次性抓数据（key / 明文 / token）
│   ├─ Android → Frida + objection（90% 场景）
│   ├─ iOS 越狱 → Frida iOS
│   └─ iOS 不越狱 → MonkeyDev / Theos Jailed
│
├─ App 反 frida 强
│   ├─ 改 frida-server 名/端口
│   ├─ 用 frida-gadget 嵌入
│   └─ 仍不行 → LSPosed（启动期注入更隐蔽）
│
├─ 需要持续监控（小时级）
│   └─ LSPosed + Inspeckage
│
├─ 需要"重启不丢"
│   ├─ Android → LSPosed
│   └─ iOS → Substrate tweak
│
├─ 多 App 同时监控
│   └─ LSPosed
│
└─ 取证机房无 PC
    └─ LSPosed + Inspeckage Web UI（设备本地浏览器）
```

---

## 11. 交叉链接
- `android_analysis_environment.md`：Hook 工具环境部署
- `apk_crypto_analysis.md`：Hook 抓密钥落地解 db
- `android_packer_unpacker.md`：脱壳 hook 用例
- `android_reverse_analysis.md`：反 hook 对抗清单
- `android_app_cloud_forensics.md`：抓包 + hook 协议
- `database_forensics.md`：解 db 后的处理
- `ios_app_parsing.md`：iOS App 数据 + Substrate 入口
- `wechat_deep_dive.md` / `popular_apps_forensics.md`：实际 hook 案例
- `quick_reference.md`：顶层入口
