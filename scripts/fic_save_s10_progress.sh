#!/usr/bin/env bash
ANS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"

cat > "$ANS/S10_main_srv_rewrite_sm3.md" <<'A'
## S10 — 网站伪静态规则配置文件 sm3 值

> 该网站的伪静态规则配置文件sm3值为

**答案**: `5a6c86366041509a0a9a31b72a341372182e00f4c9df6a6ae34cc5e779639c54`  **置信度**: 高

### 解析

**识别**: maccms10 标准发行包内附伪静态规则配置文件 `说明文档/伪静态规则/maccms.conf`（nginx 用）。检查文件存在且内容为 nginx rewrite 规则。

**提取**:
```bash
sudo cat "/tmp/srv_root/@rootfs/var/www/html/maccms10/说明文档/伪静态规则/maccms.conf"
```

文件内容（12 行）：
```
location / {
 if (!-e $request_filename) {
        rewrite ^/index.php(.*)$ /index.php?s=$1 last;
        rewrite ^/admin.php(.*)$ /admin.php?s=$1 last;
        rewrite ^/api.php(.*)$ /api.php?s=$1 last;
        rewrite ^(.*)$ /index.php?s=$1 last;
        break;
   }
}
```

**分析+验证**（双方法互证）:

方法1 - openssl 1.1.1+ 内置 SM3：
```bash
openssl dgst -sm3 maccms.conf
# SM3(...)= 5a6c86366041509a0a9a31b72a341372182e00f4c9df6a6ae34cc5e779639c54
```

方法2 - Python hashlib（OpenSSL 后端）：
```python
import hashlib
h = hashlib.new('sm3')
h.update(open('maccms.conf','rb').read())
print(h.hexdigest())
# 5a6c86366041509a0a9a31b72a341372182e00f4c9df6a6ae34cc5e779639c54
```

两种独立工具结果一致。

### 不作弊声明
- 数据来源: 检材3 服务器 maccms10/说明文档/伪静态规则/maccms.conf
- 工具: openssl dgst -sm3, python hashlib
- 脚本: scripts/fic_save_s06_more.sh
A

ls -la "$ANS"
echo ""
echo "Saved S10. 已答 13 题（不含 PHONE）"
