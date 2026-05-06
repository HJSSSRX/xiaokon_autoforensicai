#!/bin/bash
U='/mnt/win_c/Users/起早王'
MM_ID='ejbalbakoplchlghecdalmeeeajnimhm'

LES="$U/AppData/Local/Microsoft/Edge/User Data/Default/Local Extension Settings/$MM_ID"
IDB="$U/AppData/Local/Microsoft/Edge/User Data/Default/IndexedDB/chrome-extension_${MM_ID}_0.indexeddb.leveldb"

echo '=== MetaMask 全部文件 ==='
sudo ls "$LES"
echo
sudo ls "$IDB"

echo
echo '=== MetaMask state — vault + tokens + transactions ==='
sudo cat "$LES"/*.ldb "$LES"/*.log 2>/dev/null | tr -d '\0' > /tmp/mm.txt
# 看 controller state 存在 KV
grep -oaE '"TokensController"[^}]{0,1000}' /tmp/mm.txt | head -3
echo '---'
grep -oaE '"allTokens"[^}]{0,2000}' /tmp/mm.txt | head -3
echo '---'
grep -oaE '"tokens"\s*:\s*\[[^]]{0,2000}\]' /tmp/mm.txt | head -3
echo '---'
grep -oaE '"TransactionController"[^}]{0,1000}' /tmp/mm.txt | head -3
echo '---'
grep -oaE '"transactions"[^}]{0,500}' /tmp/mm.txt | head -3

echo
echo '=== 搜可能的合约地址和 decimals ==='
grep -oaE '"address"\s*:\s*"0x[0-9a-fA-F]{40}"' /tmp/mm.txt | sort -u | head -20
grep -oaE '"decimals"\s*:\s*[0-9]+' /tmp/mm.txt | sort -u | head
grep -oaE '"symbol"\s*:\s*"[^"]{1,20}"' /tmp/mm.txt | sort -u | head
grep -oaE '"chainId"\s*:\s*"0x[0-9a-fA-F]+"' /tmp/mm.txt | sort -u | head