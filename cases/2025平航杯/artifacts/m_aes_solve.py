#!/usr/bin/env python3
from Crypto.Cipher import AES

magic = bytes([113,99,92,106,89,98,54,113,104,89,117,100,113,127,124,89])
key = bytes(b ^ 6 for b in magic)
print("key:", key, key.hex())
# fallback cipher (since "Pcc0431..." contains 'P' not hex)
cipher_bytes = bytes([80,0xCC,0x04,0x31,0x35,0x06,0x80,0xC3,0x0A,0x5E,0xC5,0x19,0x52,0x73,0x6D,0x0C])
print("cipher:", cipher_bytes.hex())

# Java code does AES-128 with no IV (ECB) and PKCS#7-like unpadding
plain = AES.new(key, AES.MODE_ECB).decrypt(cipher_bytes)
print("raw plain:", plain)
last = plain[-1]
if 0 < last <= 16:
    print("unpad:", plain[:-last])