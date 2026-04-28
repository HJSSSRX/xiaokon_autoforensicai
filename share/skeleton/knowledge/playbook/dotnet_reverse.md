# Playbook · .NET 木马逆向

这是 **LLM 最擅长**的题型之一。`.NET` 程序能反编译回非常接近原始的 C# 源码，AI 读源码即可回答绝大多数题目。

---

## 0. 判题模式（高频考点清单）

- 编译的 .NET 版本 / 目标框架
- 反沙箱 / 反调试检测点数量
- 计划任务 / 服务 / 注册表 Run 键 持久化
- 加密算法（AES / DES / XOR / Base64 / RC4）
- 硬编码密钥 / IV / 盐 / URL / IP / 端口
- 传播方式（移动介质 / SMB / 邮件）
- API 调用（`WNetAddConnection` / `SetThreadExecutionState` / `SetWindowsHookEx` 等）
- Mutex 名字
- 下载的 payload 路径 / 释放的 DLL 名

---

## 1. 反编译

### 首选：ilspycmd（CLI）

```bash
pip install ilspycmd  # 或 dotnet tool install -g ilspycmd
ilspycmd $TARGET.exe -o $OUT/src -p
# 产出完整项目结构 $OUT/src/<Namespace>/<Class>.cs
```

### 备选：dnSpy（GUI，Windows）

人类操作。双击 exe → Analyze → Decompile to Project → 保存。

### 去混淆

```bash
# ConfuserEx / .NET Reactor 混淆
de4dot.exe $TARGET.exe -o $TARGET.clean.exe
# 再反编译
```

### 识别混淆器

```bash
# Detect It Easy
die $TARGET.exe
# 或看 strings：ConfuserEx、Eazfuscator、.NET Reactor 都有特征字符串
strings $TARGET.exe | rg -i 'confuser|eazfuscator|reactor'
```

---

## 2. 快速定位关键代码

反编译产物目录下：

```bash
cd $OUT/src

# 入口
rg 'static void Main' --type cs

# 网络相关
rg -l 'HttpClient|WebClient|TcpClient|Socket|HttpRequest' --type cs

# 加密相关
rg -l 'AesManaged|DESCrypto|RijndaelManaged|RSACrypto|ComputeHash|TripleDES' --type cs

# 硬编码字符串
rg -o '"(https?://|[0-9]{1,3}(\.[0-9]{1,3}){3}:?[0-9]*|.*\.(?:exe|dll|bat))"' --type cs

# WinAPI P/Invoke
rg 'DllImport' --type cs

# 注册表持久化
rg '(OpenSubKey|SetValue).*Run' --type cs

# 计划任务
rg -l 'TaskScheduler|schtasks' --type cs

# 反沙箱 / 反调试
rg -i 'IsDebuggerPresent|CheckRemoteDebugger|vmware|virtualbox|sandbox|sbiedll|vboxguest' --type cs

# 移动介质传播
rg -l 'DriveType\.Removable|DriveInfo' --type cs
```

---

## 3. AI 读源码的输出格式

每题的答案应该附：

```
Q5X: <题目>
答案: <answer>
证据: $OUT/src/Trojan/Namespace/Class.cs:Line <N>, 代码片段:
       ```cs
       // 关键几行
       ```
置信度: 高
```

---

## 4. 分题型读法

### "使用的 .NET 版本"
- 看 `$TARGET.exe` 的 PE header 导入表（`ildasm` / `CorFlags.exe`）
- 或反编译后看 `AssemblyInfo.cs` 的 TargetFramework

```bash
CorFlags.exe $TARGET.exe   # 需要 Windows SDK
# 或
dotnet-ildasm $TARGET.exe | grep Target
```

### "反沙箱/反调试检测有几点"
读 `rg -i` 检测关键字的结果，**去重计数**：
- `IsDebuggerPresent()`
- `CheckRemoteDebuggerPresent()`
- `Debugger.IsAttached`
- WMI 查询 VM
- 检测 `SbieDll.dll`（Sandboxie）
- 检测 VirtualBox / VMware 注册表键
- 检测 Wine
- 鼠标移动检测
- 睡眠加速检测

### "加密算法"
读 `rg 'AesManaged|...'` 命中的代码。注意看：
- 是否组合多层（例如 AES 后再 Base64）
- 密钥/IV 是硬编码还是动态生成

### "硬编码 C2 / IP / 端口"
```bash
rg -o '"(http[s]?://[^"]+|\b([0-9]{1,3}\.){3}[0-9]{1,3}\b)"' --type cs
rg ':[0-9]{2,5}' --type cs
```

注意：**按代码中出现顺序**列出（题目常这么要求）。

### "Mutex 名"
```bash
rg 'new Mutex|Mutex\s*\(' --type cs
```

### "持久化计划任务名"
```bash
rg 'TaskService|schtasks|TaskDefinition' --type cs -A 10
```

通常任务名在 `TaskFolder.RegisterTaskDefinition("<name>", ...)`。

### "API hook / 用户输入捕获"
```bash
rg 'SetWindowsHookEx' --type cs      # 键盘记录
rg 'GetAsyncKeyState' --type cs      # 轮询键盘
rg 'SetThreadExecutionState' --type cs  # 阻止休眠
```

### "标记进程为关键进程"
- `NtSetInformationProcess` + `ProcessBreakOnTermination`
- `RtlSetProcessIsCritical`

这两个 API 是"标记进程为关键进程以防止被结束"的典型手法。

---

## 5. 复杂情况：配置数据加密

**套路**：木马常用一个硬编码字符串作 KDF 输入，派生实际 AES 密钥。题目可能分两题：
1. 硬编码字符串是什么？→ `rg` 命中的 `KDF("…")`
2. 实际 AES 密钥是什么？→ **跑 KDF 函数**

此时 AI 最好是：**复制木马的 KDF 代码到本地 C# 或 Python 复现**，跑一次得到真密钥。

```python
# 常见：PBKDF2-SHA1
import hashlib
key = hashlib.pbkdf2_hmac('sha1', password.encode(), salt, iterations, dklen=32)
```

---

## 6. 常见坑

- **.NET Native / AOT 编译**的二进制无法反编译成 C#，只能像原生 PE 一样分析
- **混合程序集**（C++ CLI）部分是原生 x86/x64，`ilspycmd` 会丢失
- **资源隐藏**：恶意 payload 可能藏在 `.resources`，`ilspycmd -p` 会导出但别漏
- **加壳**：UPX 和自写壳会让反编译失败，要先脱壳
- **JIT 加密**：运行时才解密的字符串，静态看全是密文，必须动态调试
