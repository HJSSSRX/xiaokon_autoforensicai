---
tags: [technique, rsa, fermat, factorization, crypto, weak_key]
tools: [python3, openssl]
category: stego_crypto
difficulty: easy
source: fic2026
date: 2026-05-09
verified: true
---
# Title: RSA Fermat 分解攻击 (p,q 接近时)

## When to Use
- 看到 RSA 公钥 (N, e) 且 N 是 1024-bit 或更小
- 怀疑 p 和 q 生成时距离过近 (|p-q| < N^(1/4))
- CTF 中 .enc + public.txt 同目录出现

## Detect Signal
```bash
# 1. 提取 N
cat public.txt  # 第一行 = N, 第二行 = e
# 2. 判断大小
python3 -c "print(len(bin(int(open('public.txt').readline()))-2))"
# < 2048 bit → Fermat 可试
```

## Complete Script
```python
import math

def fermat_factor(N, max_steps=2_000_000):
    """Fermat factorization: N = p*q where |p-q| is small.
    Returns (p, q) or None.
    Complexity: O(|p-q|) steps.
    """
    x = math.isqrt(N)
    if x * x < N:
        x += 1
    for i in range(max_steps):
        y2 = x * x - N
        y = math.isqrt(y2)
        if y * y == y2:
            return x - y, x + y
        x += 1
    return None

# Usage
N = int(open("public.txt").readline().strip())
e = 65537
p, q = fermat_factor(N)
phi = (p-1) * (q-1)
d = pow(e, -1, phi)
print(f"p={p}\nq={q}\nd={d}")
```

## Textbook RSA Decrypt (no padding)
```python
# Format: 128-byte ciphertext block → 120-byte plaintext
data = open("file.enc", "rb").read()
assert len(data) % 128 == 0
out = bytearray()
for i in range(len(data) // 128):
    c = int.from_bytes(data[i*128:(i+1)*128], "big")
    m = pow(c, d, N)
    out += m.to_bytes(120, "big")
open("decrypted", "wb").write(out)
```

## Key Takeaways
- Fermat 在 |p-q| 很小时 O(Δ) 步, Δ=240 时 0 步命中
- 1024-bit N 在 CTF 中几乎总是弱密钥
- 注意区分 PKCS#1 padding vs textbook RSA (本题是 textbook)
- 解密后检查文件 magic bytes 确认格式

## Not Applicable When
- N > 2048 bit
- p,q 由安全随机生成 (|p-q| ~ N^(1/2))
- 有 PKCS#1 OAEP padding (需额外处理)
