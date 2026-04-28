#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
BIN=/tmp/pc_root/usr/bin/uos-ai-assistant

echo "=== strings 找候选 16 字节 key (放在 deepseek 附近) ==="
SUDO strings -n 16 $BIN | grep -B2 -A2 -E 'deepseek|EVP_aes|DSQLITE' | head -40

echo ""
echo "=== 二进制中 16 字节常量字符串 (可能是 AES key) ==="
SUDO strings -n 16 $BIN | grep -E '^[A-Za-z0-9_!@#$%^&*+=/-]{16}$' | head -30

echo ""
echo "=== 搜 'key' / 'salt' / 'iv' 上下文 ==="
SUDO strings $BIN | grep -B1 -A1 -E 'key.*=|salt.*=|aeskey|secretkey|encrypt|decrypt' 2>/dev/null | head -40

echo ""
echo "=== uos-ai 用过的 DeepSeek 模型默认是哪个 ==="
SUDO strings $BIN | grep -i 'deepseek\|model.*=\|default_model\|trial' | head -20

echo ""
echo "=== 查 llm 表里 type=81 是什么 (从二进制找枚举) ==="
SUDO strings $BIN | grep -E 'TYPE_|LLM_TYPE|llm_type|81|Trial' | head -20

echo ""
echo "=== 试用 sqlcipher 解 db (PRAGMA key='DSQLITECIPHER') ==="
which sqlcipher
sqlcipher /tmp/fic_extract/uos_ai/basic <<EOF 2>&1 | head -20
PRAGMA key='DSQLITECIPHER';
.tables
EOF

echo ""
echo "=== 二进制 hexdump 找 AES 密钥常量 (s盒前后) ==="
# 看 .rodata 段里的 16/32 字节常量 (可能是密钥)
SUDO objdump -s -j .rodata $BIN 2>/dev/null | grep -B1 -A1 -i 'key\|deepseek' | head -30
