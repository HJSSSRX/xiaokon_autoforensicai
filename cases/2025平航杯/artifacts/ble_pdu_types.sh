#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/BLE"
# list packet types
echo '=== BLE PDU types ==='
tshark -r "$PCAP" -T fields -e btle.advertising_header.pdu_type 2>/dev/null | sort | uniq -c | sort -rn | head -10

echo '=== Scan Response packets ==='
tshark -r "$PCAP" -Y 'btle.advertising_header.pdu_type==0x4' 2>/dev/null | wc -l

echo '=== Samples of SCAN_RSP ==='
tshark -r "$PCAP" -Y 'btle.advertising_header.pdu_type==0x4' -T fields -e btle.advertising_address -e btcommon.eir_ad.entry.device_name -e btcommon.eir_ad.entry.data 2>/dev/null | sort -u | head -20

echo '=== All unique AD entry types ==='
tshark -r "$PCAP" -T fields -e btcommon.eir_ad.entry.type 2>/dev/null | tr ',' '\n' | sort -u | head -20

echo '=== TX Power Level entries ==='
tshark -r "$PCAP" -Y 'btcommon.eir_ad.entry.power_level' 2>/dev/null | head -5

echo '=== Connection packets (data channel) ==='
tshark -r "$PCAP" -Y 'btatt' -T fields -e btatt.opcode -e btatt.value 2>/dev/null | head -20