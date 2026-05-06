#!/bin/bash
U='/mnt/win_c/Users/起早王'
MM_ID='ejbalbakoplchlghecdalmeeeajnimhm'

LES="$U/AppData/Local/Microsoft/Edge/User Data/Default/Local Extension Settings/$MM_ID"
IDB="$U/AppData/Local/Microsoft/Edge/User Data/Default/IndexedDB/chrome-extension_${MM_ID}_0.indexeddb.leveldb"

echo '=== Local Extension Settings 目录 ==='
sudo ls -la "$LES" 2>&1 | head -20

echo
echo '=== IndexedDB 目录 ==='
sudo ls -la "$IDB" 2>&1 | head -20

echo
echo '=== 倩倩币 QianQian QQ 搜所有 ldb/log ==='
for dir in "$LES" "$IDB"; do
    sudo strings -n 4 "$dir"/*.{ldb,log} 2>/dev/null | grep -iaE '倩倩|qianqian|qqcoin|QQCoin|0x[0-9a-fA-F]{40}|totalSupply|maxSupply|symbol.*Q|mint|transfer' | head -30
done

echo
echo '=== IndexedDB + Vault 全 strings ==='
sudo strings -n 6 "$IDB"/*.{ldb,log} 2>/dev/null | grep -iaE 'symbol|decimals|chainId|token|contract' | head -30

echo
echo '=== Edge 历史 blockchain 相关 ==='
# 复制 History (might be locked)
sudo cp "$U/AppData/Local/Microsoft/Edge/User Data/Default/History" /tmp/edge_hist.sqlite 2>/dev/null
sqlite3 /tmp/edge_hist.sqlite "SELECT datetime((last_visit_time/1000000)-11644473600,'unixepoch','+8 hours') as t, url, title FROM urls WHERE url LIKE '%etherscan%' OR url LIKE '%bscscan%' OR url LIKE '%sepolia%' OR url LIKE '%polygon%' OR url LIKE '%opensea%' OR url LIKE '%token%' OR url LIKE '%uniswap%' OR url LIKE '%pancake%' OR title LIKE '%倩倩%' OR title LIKE '%QQ%' ORDER BY last_visit_time DESC LIMIT 30;" 2>&1

echo
echo '=== Edge downloads ==='
sqlite3 /tmp/edge_hist.sqlite "SELECT datetime((start_time/1000000)-11644473600,'unixepoch','+8 hours') as t, target_path, tab_url FROM downloads ORDER BY start_time DESC LIMIT 50;" 2>&1