#!/bin/bash
U='/mnt/win_c/Users/起早王'
CACHE="$U/AppData/Local/Microsoft/Edge/User Data/Default/Cache/Cache_Data"

A1=1978a452c8066b57cc25816a9637f1146253be4a
A2=c4bfccb1668d6e464f33a76badd8c8d7d341e04a

echo '=== Cache 文件数 ==='
sudo ls "$CACHE" | wc -l

echo
echo '=== Cache 内是否有合约字符串 (zcat/brotli 解) ==='
# Chromium cache data_[0-3] 是索引，f_*** 是大文件
# 试着 brotli 解压 f_* 扫
which brotli 2>&1
for f in "$CACHE"/f_*; do
    # 先试不解压
    if sudo strings "$f" 2>/dev/null | grep -qaE "$A1|$A2|倩倩|QianQian"; then
        echo "HIT raw: $f"
        sudo strings "$f" | grep -aE "$A1|$A2|倩倩|QianQian" | head
    fi
    # 试 brotli
    if command -v brotli &>/dev/null; then
        if sudo brotli -d -c "$f" 2>/dev/null | strings | grep -qaE "$A1|$A2|倩倩|QianQian"; then
            echo "HIT brotli: $f"
        fi
    fi
    # 试 gzip
    if sudo gunzip -c "$f" 2>/dev/null | strings | grep -qaE "$A1|$A2"; then
        echo "HIT gzip: $f"
    fi
done

echo
echo '=== data_? 文件 ==='
for f in "$CACHE"/data_?; do
    echo "## $f  size=$(stat -c%s $f)"
    sudo strings "$f" | grep -aEiHn "$A1|$A2|倩倩|QianQian|token|Supply" | head -5
done

echo
echo '=== Edge Cookies 找 session (可推知时间) ==='
sudo cp "$U/AppData/Local/Microsoft/Edge/User Data/Default/Cookies" /tmp/cookies.sqlite 2>/dev/null
sqlite3 /tmp/cookies.sqlite "SELECT host_key, name FROM cookies WHERE host_key LIKE '%etherscan%' OR host_key LIKE '%infura%' OR host_key LIKE '%alchemy%';" 2>&1 | head