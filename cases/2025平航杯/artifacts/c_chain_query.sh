#!/bin/bash
RPC='https://rpc.sepolia.org'
C='0x3818ea4d51778f032943ca402535eDD2b3fB518d'
U='0xd8786a1345ca969c792d9328f8594981066482e9'

echo '=== 1. totalSupply() ==='
curl -s -X POST $RPC -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"0x18160ddd\"},\"latest\"],\"id\":1}"
echo

echo '=== 2. name() ==='
curl -s -X POST $RPC -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"0x06fdde03\"},\"latest\"],\"id\":1}"
echo

echo '=== 3. decimals() ==='
curl -s -X POST $RPC -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"0x313ce567\"},\"latest\"],\"id\":1}"
echo

echo '=== 4. balanceOf(起早王) ==='
DATA="0x70a08231000000000000000000000000${U#0x}"
curl -s -X POST $RPC -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}"
echo

echo '=== 5. Transfer 事件 to 起早王 (topic0=Transfer, topic2=user pad) ==='
TOPIC0='0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
TOPIC2="0x000000000000000000000000${U#0x}"
curl -s -X POST $RPC -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getLogs\",\"params\":[{\"fromBlock\":\"0x0\",\"toBlock\":\"latest\",\"address\":\"$C\",\"topics\":[\"$TOPIC0\",null,\"$TOPIC2\"]}],\"id\":1}"
echo