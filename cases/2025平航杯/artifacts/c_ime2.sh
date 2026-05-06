#!/bin/bash
IME='/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/InputMethod/Chs'

echo '=== 所有 IME 文件大小 ==='
sudo ls -la $IME

echo
echo '=== EUDPv1.lex 内容 (strings UTF-16 LE) ==='
for f in $IME/ChsPinyinEUDPv1.lex $IME/ChsPinyinUDL.dat $IME/ChsPinyinUDL.dat.bak; do
    echo "## $f"
    sudo strings -el "$f" 2>/dev/null | head -30
    echo '-- 8-bit --'
    sudo strings "$f" 2>/dev/null | head -30
done

echo
echo '=== UDP*.tmp files ==='
for f in $IME/UDP*.tmp; do
    echo "## $f size=$(stat -c%s $f)"
    sudo strings -el "$f" 2>/dev/null | head -20
    sudo strings "$f" 2>/dev/null | head -10
done

echo
echo '=== BIP39 英文词筛（24 个单词序列）==='
# Ethereum 助记词常是 12 或 24 个 BIP39 英文单词
# 最短 3 字母（如 add, air），列出前几个典型
for f in $IME/*.lex $IME/*.dat $IME/UDP*.tmp; do
    # 提取所有长度 3-8 的小写字母序列
    sudo strings -el "$f" 2>/dev/null | grep -oE '\b[a-z]{3,8}\b' | head -30
done