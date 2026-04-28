# 解题套路 02：微信数据库解密

**适用场景**：需要解密微信 EnMicroMsg.db 数据库  
**解题时间**：2026-04-24  
**相关题目**：Q37, Q38

---

## 🎯 解题思路

1. **获取IMEI**：从微信配置文件中提取设备IMEI
2. **获取UIN**：从微信配置中获取用户UIN
3. **计算密钥**：使用 IMEI+UIN 生成32位MD5密钥
4. **解密数据库**：使用SQLCipher解密数据库

---

## 📋 操作步骤

### 1. 提取IMEI
```bash
# 从微信配置文件查找IMEI
find /tmp/zqw_phone -name "*.xml" -exec grep -l "imei" {} \;

# 查看 WLOGIN_DEVICE_INFO.xml
cat /tmp/zqw_phone/data/data/com.tencent.mm/shared_prefs/WLOGIN_DEVICE_INFO.xml
```

### 2. 提取UIN
```bash
# 从系统配置文件查找UIN
find /tmp/zqw_phone -name "*config*.xml" -exec grep -l "_auth_uin\|uin" {} \;

# 查看 system_config_prefs.xml
cat /tmp/zqw_phone/data/data/com.tencent.mm/shared_prefs/system_config_prefs.xml
```

### 3. 计算密钥
```python
import hashlib

def calculate_wechat_key(imei, uin):
    """计算微信数据库密钥"""
    # IMEI通常是十六进制字符串，需要解码
    imei_bytes = bytes.fromhex(imei)
    uin_str = str(uin)
    
    # 组合 IMEI + UIN
    combined = imei_bytes + uin_str.encode('utf-8')
    
    # 计算MD5
    md5_hash = hashlib.md5(combined).hexdigest()
    
    # 取前32位作为密钥
    return md5_hash[:32]

# 示例使用
imei = "Afe577bc2a810aa0"  # 从配置文件获取
uin = "852430965"          # 从配置文件获取
key = calculate_wechat_key(imei, uin)
print(f"解密密钥: {key}")
```

### 4. 解密数据库
```bash
# 方法1：使用sqlcipher命令行
sqlcipher EnMicroMsg.db <<EOF
PRAGMA key = 'your_key_here';
PRAGMA cipher_page_size = 4096;
ATTACH DATABASE 'decrypted.db' AS decrypted KEY '';
SELECT sqlcipher_export('decrypted');
DETACH DATABASE decrypted;
EOF

# 方法2：使用Python
python3 -c "
import sqlite3
conn = sqlite3.connect('EnMicroMsg.db')
conn.execute('PRAGMA key = \"your_key_here\"')
conn.execute('PRAGMA cipher_page_size = 4096')
cursor = conn.cursor()
try:
    cursor.execute('SELECT name FROM sqlite_master WHERE type=\"table\"')
    tables = cursor.fetchall()
    print('解密成功，表列表：', tables)
except Exception as e:
    print('解密失败：', e)
"
```

---

## 🔍 关键点

1. **IMEI格式**：可能是十六进制字符串或ASCII
2. **UIN格式**：可能是数字或字符串
3. **密钥长度**：必须32位（前32位MD5）
4. **页面大小**：通常4096，也可能是1024

---

## 🛠️ 工具需求

- SQLCipher 4.x
- Python sqlite3 + pysqlcipher3-binary
- hashlib（计算MD5）

---

## ⚠️ 注意事项

1. **多尝试组合**：IMEI可能有多种格式，需要尝试
2. **页面大小**：4096和1024都要尝试
3. **数据库版本**：不同版本微信可能用不同算法
4. **备份原文件**：解密前先备份

---

## 📊 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 解密失败 | 密钥错误 | 检查IMEI/UIN格式 |
| 文件损坏 | 数据库损坏 | 使用其他备份 |
| 权限错误 | 文件权限 | 检查文件权限 |

---

## 🔄 改进方向

1. 实现自动密钥生成（多种格式尝试）
2. 添加暴力破解功能
3. 支持多种页面大小自动尝试
4. 建立密钥缓存机制

---

## 📝 成功案例

**成功解密记录**：
- IMEI: `Afe577bc2a810aa0`
- UIN: `852430965`
- 密钥: `a5e577bc2a810aa0852430965`
- 页面大小: 4096

**失败案例**：
- 使用错误IMEI格式导致密钥错误
- 页面大小使用1024导致解密失败
