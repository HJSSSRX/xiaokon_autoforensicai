#!/bin/bash

echo '=== WindowsImageBackup ==='
sudo ls '/mnt/win_c/System Volume Information/WindowsImageBackup' 2>&1 | head
sudo find '/mnt/win_c/System Volume Information/WindowsImageBackup' -type f 2>&1 | head -30

echo
echo '=== crack.zip 概要 (A 板块关键) ==='
sudo ls -la '/mnt/win_c/Users/起早王/Downloads/crack.zip'
sudo unzip -l '/mnt/win_c/Users/起早王/Downloads/crack.zip' 2>&1 | head -30

echo
echo '=== SYSTEM hive BitLocker ==='
# BitLocker 保护项的 SID/GUID 在 HKLM\System\CurrentControlSet\Services\BitLocker 或 Policies
python3 -c "
from Registry import Registry
r = Registry.Registry('/mnt/win_c/Windows/System32/config/SYSTEM')
sel = r.open('Select')
cs = f'ControlSet{sel.value(\"Current\").value():03d}'
# BitLocker 相关注册键
for path in [rf'{cs}\Services\BitLocker', rf'{cs}\Services\FveBase', r'Microsoft\FVE']:
    try:
        k = r.open(path)
        print('##', path)
        for v in k.values():
            print(f'  {v.name()} = {v.value()[:200] if isinstance(v.value(),(str,bytes)) else v.value()}')
    except Exception as e:
        print('miss', path)
"

echo
echo '=== 搜 48 位密钥 in RAM dumps / hiberfil / swap ==='
sudo ls -la /mnt/win_c/*.sys 2>&1 | head
sudo find /mnt/win_c -maxdepth 2 -iname '*.dmp' 2>&1 | head

echo
echo '=== BitLocker .BEK on USB / other drives ==='
# BEK = BitLocker External Key
sudo find /mnt/win_c -iname '*.bek' 2>/dev/null | head