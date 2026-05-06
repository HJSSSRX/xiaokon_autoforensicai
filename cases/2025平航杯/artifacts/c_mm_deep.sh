#!/bin/bash
# 扫所有可能记录 transaction history 的字段
echo '=== NetworkController / Infura keys ==='
grep -oaE '"NetworkController"[^{}]{0,200}' /tmp/mm.txt | head -3
echo
echo '=== SmartTransactionsController ==='
grep -oaE '"SmartTransactionsController"[^{}]{0,300}' /tmp/mm.txt | head -3
echo
echo '=== AccountTracker balance ==='
grep -oaE '"AccountTrackerController"[^}]{0,500}' /tmp/mm.txt | head -3
echo
echo '=== NftController ==='
grep -oaE '"NftController"[^}]{0,500}' /tmp/mm.txt | head
echo
echo '=== 0x31afba0 说明 ==='
python3 -c "b=0x31afba0; print('balance raw=', b); print('balance / 10^5 =', b/1e5)"
echo
echo '=== TokenDetectionController / allDetected ==='
grep -oaE '"allDetectedTokens"[^}]{0,3000}' /tmp/mm.txt | head -3
echo
echo '=== 去所有大写 JSON key 全字段 (看可能的 contract deploy)==='
grep -oaE '"KeyringController"[^{}]{0,500}' /tmp/mm.txt | head -3