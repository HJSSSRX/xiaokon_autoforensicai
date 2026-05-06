---
tags: [mobile_forensics, android, wechat, sqlcipher, database_decrypt, imei, uin]
tools: [sqlcipher, python, sqlite3, grep, find]
category: mobile_forensics
difficulty: medium
source: fic2026
date: 2026-05-05
verified: true
---
# Title: 微信数据库 (EnMicroMsg.db) 解密

## Problem
Android 手机取证中需要解密微信的 SQLCipher 加密数据库。

## Solution Steps

1. 定位微信数据目录
   ```bash
   find {phone_extract} -path "*/com.tencent.mm/MicroMsg/*/EnMicroMsg.db" 2>/dev/null
   ```

2. 提取 IMEI
   ```bash
   cat {phone_extract}/data/data/com.tencent.mm/shared_prefs/WLOGIN_DEVICE_INFO.xml
   # 或
   find {phone_extract} -name "*.xml" -exec grep -l "imei" {} \;
   ```

3. 提取 UIN
   ```bash
   cat {phone_extract}/data/data/com.tencent.mm/shared_prefs/system_config_prefs.xml
   # 搜索 _auth_uin 字段
   grep -r "_auth_uin\|default_uin" {phone_extract}/data/data/com.tencent.mm/shared_prefs/
   ```

4. 计算密钥
   ```python
   import hashlib
   def calculate_wechat_key(imei, uin):
       """IMEI + UIN → MD5 前7位即为密码"""
       combined = str(imei) + str(uin)
       md5_hash = hashlib.md5(combined.encode('utf-8')).hexdigest()
       return md5_hash[:7]

   # 注意：IMEI 格式可能是十六进制或纯数字，需多种尝试
   key = calculate_wechat_key("862118032070741", "852430965")
   ```

5. 解密数据库
   ```bash
   sqlcipher EnMicroMsg.db
   > PRAGMA key = 'your_7char_key';
   > PRAGMA cipher_page_size = 4096;
   > ATTACH DATABASE 'decrypted.db' AS decrypted KEY '';
   > SELECT sqlcipher_export('decrypted');
   > DETACH DATABASE decrypted;
   ```

6. 查询聊天记录
   ```sql
   -- 解密后的数据库
   SELECT * FROM message ORDER BY createTime DESC LIMIT 50;
   SELECT * FROM rcontact WHERE type=3;  -- 好友列表
   ```

## Key Takeaways
- 微信密钥 = MD5(IMEI + UIN) 的前 7 位
- IMEI 来源: `WLOGIN_DEVICE_INFO.xml` 或 `build.prop`
- UIN 来源: `system_config_prefs.xml` 中的 `_auth_uin`
- cipher_page_size 通常为 4096，也可能是 1024，需两种都试
- **新版微信** IMEI 可能是十六进制格式，需 `bytes.fromhex()` 转换
- 必须提前安装 `sqlcipher` 和 Python `pysqlcipher3` 包
