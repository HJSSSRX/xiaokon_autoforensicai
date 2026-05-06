#!/bin/bash
ZIP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/20250415_181118.zip"
cd /tmp/phone

# Extract QQ and WeChat backup files (Chinese filename in zip)
echo '=== List zip with QQ/wechat ==='
unzip -l "$ZIP" 2>/dev/null | grep -E "QQ|tencent" | head -5

# QQ has English filename
unzip -o "$ZIP" "*com.tencent.mobileqq*" 2>&1 | tail -3

# extract weixin (binary safe via -j)
unzip -o "$ZIP" "*com.tencent.mm*" 2>&1 | tail -3

ls -la 20250415_181118/ | grep -E "tencent" | head -3