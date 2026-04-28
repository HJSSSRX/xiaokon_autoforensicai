# Pattern 06: AES + XOR Mask 密码校验逆向

> 来源：FIC2026 B03 — SampleVC.exe 密码

---

## 题型特征

- Windows PE 程序要求输入密码
- 密码经过某种变换后与**固定字节序列**比较
- 变换涉及 AES S-box 查表 + XOR 操作

## 解题流程

### 1. 定位密码比较点
```
r2 -A exe
afl | grep -i dialog    # 找 UI 处理函数
pdf @fcn.xxx            # 找 strncmp / memcmp 调用
```
关键特征：`strncmp(s1, s2, 16)` 其中 s1 是固定 16 字节，s2 是用户输入变换后的结果。

### 2. 提取固定比较值
从反汇编中直接读 `mov dword [s1], 0xXXXXXXXX` 序列，拼出 16 字节 ciphertext。

### 3. 识别变换算法
搜索 AES S-box 特征值（`0x63, 0x7c, 0x77, 0x7b` 开头的 256 字节表）：
```
px 256 @addr    # 打印疑似 S-box
```
如果存在标准 AES S-box → 算法基于 AES。

### 4. 分析 XOR mask
用户输入可能先经过 XOR mask 再送入 AES，或 AES 输出再经 XOR。
```python
# 常见 mask 模式
mask = bytes([((0x7f + 3*i) & 0xff) for i in range(16)])
```

### 5. 反向解密
```python
import subprocess
ct = bytes.fromhex('afb977ac242ad60cf42461ad72ca5149')
open('/tmp/ct.bin','wb').write(ct)
# 尝试常见 key
for key_hex in ['0123456789abcdef0123456789abcdef', ...]:
    p = subprocess.run(['openssl','enc','-aes-128-ecb','-d','-nopad','-K',key_hex,'-in','/tmp/ct.bin'],
                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    pt = p.stdout
    # 再 XOR mask
    result = bytes([b ^ ((0x7f + 3*i) & 0xff) for i,b in enumerate(pt)])
    if all(32 <= c < 127 for c in result):
        print(f"PASSWORD: {result.decode()}")
```

## FIC2026 实战结果

- **固定比较值**: `afb977ac242ad60cf42461ad72ca5149`
- **AES key**: `0123456789abcdef0123456789abcdef`（标准递增序列）
- **XOR mask**: `bytes([((0x7f + 3*i) & 0xff) for i in range(16)])`
- **明文密码**: `PleaseRunAsAdmin`

## 可复现命令

```python
ct = bytes.fromhex('afb977ac242ad60cf42461ad72ca5149')
# AES-128-ECB decrypt with key 0123456789abcdef (repeated)
# Then XOR with mask → "PleaseRunAsAdmin"
```
