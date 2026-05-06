#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/USBPcap"
# show descriptors for each device (strings descriptors contain manufacturer name)
echo '=== All USB string descriptors ==='
tshark -r "$PCAP" -Y 'usb.bDescriptorType==0x03' -T fields -e usb.src -e usb.bString 2>/dev/null | sort -u

echo '=== Device descriptors (iManufacturer, iProduct strings) ==='
tshark -r "$PCAP" -Y 'usb.bDescriptorType==0x01 && usb.idVendor' -T fields -e usb.src -e usb.idVendor -e usb.idProduct 2>/dev/null | sort -u

echo '=== Full HID reports from all endpoints with data_len>8 ==='
for ep in 2.1.1 2.2.1 2.3.1 2.5.1; do
    echo "-- $ep --"
    tshark -r "$PCAP" -Y "usb.src==\"$ep\"" -T fields -e usb.data_len -e usbhid.data 2>/dev/null | sort -u | head -5
done