#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/BLE"
# Public BLE addresses (txadd bit = 0)
echo '=== Public addresses and their top device names ==='
tshark -r "$PCAP" -Y 'btle.advertising_header.randomized_tx==0' -T fields -e btle.advertising_address -e btcommon.eir_ad.entry.device_name 2>/dev/null | sort -u | head -30

echo '=== All unique advertising addresses with their tx_add bit ==='
tshark -r "$PCAP" -T fields -e btle.advertising_address -e btle.advertising_header.randomized_tx -e btcommon.eir_ad.entry.device_name 2>/dev/null | sort -u | awk -F"\t" 'length($3) >= 4 && $3 ~ /^[ -~]+$/' | head -30