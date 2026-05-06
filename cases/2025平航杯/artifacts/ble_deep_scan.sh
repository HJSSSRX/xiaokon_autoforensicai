#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/BLE"
# all unique device names with occurrence > 3 (filter noise)
echo '=== device names with >=3 occurrences ==='
tshark -r "$PCAP" -Y 'btcommon.eir_ad.entry.device_name' -T fields -e btcommon.eir_ad.entry.device_name 2>/dev/null \
  | sort | uniq -c | sort -rn | awk '$1 >= 3 { $1=""; print }' | head -30

echo '=== all hex-printable strings from manufacturer_data that are ASCII text ==='
tshark -r "$PCAP" -Y 'btcommon.eir_ad.entry.company_id' -T fields -e btcommon.eir_ad.entry.data 2>/dev/null \
  | sort -u | while read hex; do
    [ -z "$hex" ] && continue
    decoded=$(echo -n "$hex" | xxd -r -p 2>/dev/null | tr -cd '\40-\176')
    # only print if >=4 alpha chars
    if [ $(echo -n "$decoded" | tr -cd 'A-Za-z' | wc -c) -ge 4 ]; then
        echo "$hex -> $decoded"
    fi
done | sort -u | head -20

echo '=== URI ADs ==='
tshark -r "$PCAP" -Y 'btcommon.eir_ad.entry.uri' 2>/dev/null | head -5

echo '=== Service Data ADs ==='
tshark -r "$PCAP" -Y 'btcommon.eir_ad.entry.service_data' -T fields -e btcommon.eir_ad.entry.uuid_16 -e btcommon.eir_ad.entry.service_data 2>/dev/null | sort -u | head -20