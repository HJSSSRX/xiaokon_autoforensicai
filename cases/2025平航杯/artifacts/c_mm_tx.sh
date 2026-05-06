#!/bin/bash
echo '=== 搜 transactions 相关 ==='
# MetaMask tx store in TransactionController
grep -oaE '"TransactionController"\s*:\s*\{[^{}]{0,5000}' /tmp/mm.txt | head -3
echo
echo '=== accountsByChainId / balance ==='
grep -oaE '"accountsByChainId"[^}]{0,3000}' /tmp/mm.txt | head -3
echo
echo '=== 所有 0x3818 出现的上下文 ==='
grep -oaE '.{100}0x3818ea4d51778f032943ca402535eDD2b3fB518d.{500}' /tmp/mm.txt -i | head -5
echo
echo '=== 所有 0x1978 和 0xc4bf 上下文 ==='
grep -oaEi '.{100}1978a452c8066b57cc25816a9637f1146253be4a.{300}' /tmp/mm.txt | head -3
echo '---'
grep -oaEi '.{100}c4bfccb1668d6e464f33a76badd8c8d7d341e04a.{300}' /tmp/mm.txt | head -3

echo
echo '=== 最大供应量/购买数量/时间线 key 搜 ==='
grep -oaE '"maxSupply"[^,]{0,100}' /tmp/mm.txt | head -3
grep -oaE '"totalSupply"[^,]{0,100}' /tmp/mm.txt | head -3
grep -oaE '"balance"\s*:\s*"0x[0-9a-f]+"' /tmp/mm.txt | head
grep -oaE '"tokenBalance"\s*:\s*"[^"]{0,200}"' /tmp/mm.txt | head
grep -oaE '"hash"\s*:\s*"0x[0-9a-f]{64}"' /tmp/mm.txt | sort -u | head
grep -oaE '"time"\s*:\s*[0-9]{13}' /tmp/mm.txt | head