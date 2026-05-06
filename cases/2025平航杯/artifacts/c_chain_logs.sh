#!/bin/bash
RPC='https://ethereum-sepolia-rpc.publicnode.com'
C='0x3818ea4d51778f032943ca402535eDD2b3fB518d'
U='0xd8786a1345ca969c792d9328f8594981066482e9'
TOPIC0='0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
TOPIC2="0x000000000000000000000000${U#0x}"

R() { curl -s -m 15 -X POST $RPC -H 'Content-Type: application/json' -d "$1"; }

echo '=== 合约创建 block（用 eth_getCode 确认存在 + 搜 creation）==='
# 先拿当前 block
R '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
echo
echo
# 按时间估 2025-03-19 ~ 2025-03-26 Sepolia block 范围
# Sepolia 2024-11-10 block ~ 7,000,000
# 2025-03-19 ~ 7,835,000 (粗估)
# 保守扫 7700000 - 8000000 = 300k blocks，分 6 批 * 50k

START=7700000
END=8000000
STEP=50000

for ((b=START; b<END; b+=STEP)); do
    E=$((b+STEP-1))
    [ $E -gt $END ] && E=$END
    FB=$(printf '0x%x' $b)
    TB=$(printf '0x%x' $E)
    RES=$(R "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getLogs\",\"params\":[{\"fromBlock\":\"$FB\",\"toBlock\":\"$TB\",\"address\":\"$C\",\"topics\":[\"$TOPIC0\",null,\"$TOPIC2\"]}],\"id\":1}")
    # 如果 result 非空 []
    if echo "$RES" | grep -q '"result":\[{'; then
        echo "## HIT block $b - $E"
        echo "$RES"
    fi
done
echo