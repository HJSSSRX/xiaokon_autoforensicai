#!/bin/bash
C='0x3818ea4d51778f032943ca402535eDD2b3fB518d'
U='0xd8786a1345ca969c792d9328f8594981066482e9'

for RPC in https://ethereum-sepolia-rpc.publicnode.com https://sepolia.drpc.org https://1rpc.io/sepolia https://endpoints.omniatech.io/v1/eth/sepolia/public; do
    echo "=== $RPC ==="
    RES=$(curl -s -m 10 -X POST $RPC -H 'Content-Type: application/json' \
      -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"0x18160ddd\"},\"latest\"],\"id\":1}")
    echo "$RES" | head -c 500
    echo
    if echo "$RES" | grep -q '"result"'; then
        WORKING=$RPC
        echo "✓ working"
        break
    fi
done

if [ -z "$WORKING" ]; then
    echo 'FAIL: no RPC working'; exit 1
fi

echo
echo "=== using $WORKING ==="
R() { curl -s -m 10 -X POST $WORKING -H 'Content-Type: application/json' -d "$1"; }

echo
echo '--- totalSupply() 0x18160ddd ---'
R "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"0x18160ddd\"},\"latest\"],\"id\":1}"
echo
echo '--- decimals() 0x313ce567 ---'
R "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"0x313ce567\"},\"latest\"],\"id\":1}"
echo
echo '--- name() 0x06fdde03 ---'
R "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"0x06fdde03\"},\"latest\"],\"id\":1}"
echo
echo '--- balanceOf(起早王) ---'
DATA="0x70a08231000000000000000000000000${U#0x}"
R "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$C\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}"
echo
echo '--- Transfer logs to 起早王 ---'
TOPIC0='0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
TOPIC2="0x000000000000000000000000${U#0x}"
R "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getLogs\",\"params\":[{\"fromBlock\":\"0x0\",\"toBlock\":\"latest\",\"address\":\"$C\",\"topics\":[\"$TOPIC0\",null,\"$TOPIC2\"]}],\"id\":1}"
echo