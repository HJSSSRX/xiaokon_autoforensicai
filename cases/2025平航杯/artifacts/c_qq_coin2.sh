#!/bin/bash
U='/mnt/win_c/Users/起早王'
MM_ID='ejbalbakoplchlghecdalmeeeajnimhm'

# 两合约地址
A1=1978a452c8066b57cc25816a9637f1146253be4a
A2=c4bfccb1668d6e464f33a76badd8c8d7d341e04a

echo '=== MetaMask IndexedDB 搜合约地址 ==='
IDB="$U/AppData/Local/Microsoft/Edge/User Data/Default/IndexedDB/chrome-extension_${MM_ID}_0.indexeddb.leveldb"
sudo grep -rla "$A1\|$A2" "$IDB" 2>/dev/null

echo
echo '=== Local Extension Settings ldb 搜 ==='
LES="$U/AppData/Local/Microsoft/Edge/User Data/Default/Local Extension Settings/$MM_ID"
sudo grep -rla "$A1\|$A2" "$LES" 2>/dev/null

echo
echo '=== 所有 MetaMask 文件 strings 找 token 信息 ==='
# 查找含 "supply" "decimals" "symbol" 和地址的上下文
sudo strings -n 4 "$LES"/*.{ldb,log} "$IDB"/*.{ldb,log} 2>/dev/null > /tmp/mm_all.txt
wc -l /tmp/mm_all.txt
grep -iaE "$A1|$A2" /tmp/mm_all.txt | head -30

echo
echo '=== MetaMask vault (加密助记词存在这里) ==='
grep -aoE '"vault":"[^"]{0,200}"' /tmp/mm_all.txt | head -5
echo
echo '=== tokens 配置 (起早王自己添加的) ==='
grep -iaE 'ERC20|erc20|symbol.{0,50}|contractAddress|tokens\b' /tmp/mm_all.txt | head -30

echo
echo '=== Edge Cache 扫 sepolia.etherscan 页面 ==='
CACHE="$U/AppData/Local/Microsoft/Edge/User Data/Default/Cache/Cache_Data"
sudo ls "$CACHE" 2>&1 | head
# 搜 cache 里含 token 信息的页面
sudo grep -rla "$A1\|$A2" "$CACHE" 2>/dev/null | head