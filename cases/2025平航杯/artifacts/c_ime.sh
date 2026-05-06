#!/bin/bash
U='/mnt/win_c/Users/起早王'

echo '=== 输入法搜索 ==='
sudo find "$U" /mnt/win_c/ProgramData -maxdepth 6 -type d \( -iname '*sogou*' -o -iname '*ime*' -o -iname '*baidu*' -o -iname '*pinyin*' -o -iname '*QQ拼音*' -o -iname '*rime*' -o -iname '*chipy*' -o -iname '*ShuangPin*' \) 2>/dev/null | head -20

echo
echo '=== 微软拼音 ==='
sudo find "$U/AppData/Roaming/Microsoft/InputMethod" 2>&1 | head -20
sudo find /mnt/win_c -maxdepth 7 -iname '*UserDict*' -o -iname 'UDP.dat' 2>/dev/null | head

echo
echo '=== 搜自定义短语文件 ==='
sudo find "$U" -maxdepth 8 \( -iname '*.scel' -o -iname '*.txt' -path '*InputMethod*' -o -iname 'PhraseEdit*' -o -iname 'UserDefinedPhrase*' -o -iname 'zwgd*' \) 2>/dev/null | head

echo
echo '=== 全盘含 0x 或助记词（bip39 单词）的 txt ==='
# BIP39 英文单词常见开头：abandon ability... 或纯中文 BIP39
sudo grep -rlE '(abandon|ability|able|about|above)' "$U" 2>/dev/null | head -10