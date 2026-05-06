#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/BLE"
# look for 3-part names (CamelCase) across both files
echo '=== All printable strings >= 10 chars, unique ==='
strings -n 10 "$PCAP" | sort -u | grep -vE 'Wireshark|nRF|Dumpcap|libpcap|AMD|Windows|QQ_WF|Flipper|Nlipper' | head -40

echo '=== Search USBPcap file too ==='
strings -n 6 "/mnt/f/TEXT(important)/Jian cai/2025平航杯/USBPcap" | sort -u | head -50