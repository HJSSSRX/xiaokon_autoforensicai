#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/USBPcap"
# approach: try all URB_INTERRUPT in packets
echo '--- count interrupt ---'
tshark -r "$PCAP" -Y 'usb.transfer_type==0x01' 2>/dev/null | wc -l
echo '--- src/dst of non-control packets ---'
tshark -r "$PCAP" -T fields -e usb.src -e usb.dst -e usb.transfer_type -e usb.data_len 2>/dev/null | sort -u | head -30
echo '--- sample HID data ---'
tshark -r "$PCAP" -Y 'usb.capdata' -T fields -e frame.number -e usb.src -e usb.dst -e usb.capdata 2>/dev/null | head -10