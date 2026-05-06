#!/bin/bash
echo '=== Edge 全历史扫所有 etherscan / web3 ==='
sqlite3 /tmp/edge_hist.sqlite "SELECT datetime((last_visit_time/1000000)-11644473600,'unixepoch','+8 hours') as t, visit_count, typed_count, url, title FROM urls WHERE url LIKE '%etherscan%' OR url LIKE '%sepolia%' OR url LIKE '%metamask%' OR url LIKE '%web3%' OR url LIKE '%remix%' OR url LIKE '%solidity%' OR url LIKE '%0x%' ORDER BY last_visit_time ASC;" | head -60

echo
echo '=== Google 搜索历史（看做什么）==='
sqlite3 /tmp/edge_hist.sqlite "SELECT datetime((last_visit_time/1000000)-11644473600,'unixepoch','+8 hours') as t, url FROM urls WHERE url LIKE '%google.com/search%' ORDER BY last_visit_time ASC LIMIT 40;" | head -60