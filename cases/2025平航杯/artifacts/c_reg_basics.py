#!/usr/bin/env python3
import sys
from Registry import Registry
from datetime import datetime

SYSTEM = '/mnt/win_c/Windows/System32/config/SYSTEM'
NTUSER = '/mnt/win_c/Users/起早王/NTUSER.DAT'
SOFTWARE = '/mnt/win_c/Windows/System32/config/SOFTWARE'

# ===== C01 USB serial numbers =====
print('=== C01 USB ===')
r = Registry.Registry(SYSTEM)
# find Current ControlSet
sel = r.open('Select')
current = sel.value('Current').value()
cs = f'ControlSet{current:03d}'
print(f'Current ControlSet = {cs}')

try:
    usbstor = r.open(rf'{cs}\Enum\USBSTOR')
    for dev in usbstor.subkeys():
        print(f'\n[{dev.name()}]')
        for inst in dev.subkeys():
            # inst.name() 最后 &0 前是序列号
            sn = inst.name()
            try:
                friendly = inst.value('FriendlyName').value()
            except: friendly = '-'
            print(f'  instance={sn}  friendly={friendly}')
except Exception as e:
    print('no USBSTOR:', e)

try:
    usb = r.open(rf'{cs}\Enum\USB')
    print('\n-- USB devices --')
    for dev in usb.subkeys():
        for inst in dev.subkeys():
            try:
                friendly = inst.value('FriendlyName').value()
            except: friendly = None
            if friendly and ('disk' in friendly.lower() or 'storage' in friendly.lower() or 'flash' in friendly.lower()):
                print(f'  {dev.name()}\\{inst.name()}  {friendly}')
except Exception as e:
    pass

# ===== C05 Last shutdown time =====
print('\n=== C05 Last shutdown time ===')
try:
    k = r.open(rf'{cs}\Control\Windows')
    shut = k.value('ShutdownTime').value()
    # ShutdownTime is FILETIME (8 bytes LE)
    import struct
    if isinstance(shut, bytes):
        ft = struct.unpack('<Q', shut)[0]
        # FILETIME 100ns since 1601
        secs = ft / 10_000_000 - 11644473600
        dt = datetime.utcfromtimestamp(secs)
        print(f'  ShutdownTime UTC: {dt}')
        print(f'  ShutdownTime +8: {datetime.utcfromtimestamp(secs+8*3600)}')
except Exception as e:
    print('err:', e)

# ===== C03 Default browser =====
print('\n=== C03 Default browser (UserChoice) ===')
ru = Registry.Registry(NTUSER)
try:
    k = ru.open(r'Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice')
    progid = k.value('ProgId').value()
    print(f'  https ProgId = {progid}')
    k2 = ru.open(r'Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice')
    progid2 = k2.value('ProgId').value()
    print(f'  http ProgId  = {progid2}')
except Exception as e:
    print('err:', e)

# Check installed browsers
print('\n-- Installed browsers --')
try:
    rs = Registry.Registry(SOFTWARE)
    for path in [r'Clients\StartMenuInternet', r'WOW6432Node\Clients\StartMenuInternet']:
        try:
            k = rs.open(path)
            for sk in k.subkeys():
                print(f'  {sk.name()}')
        except: pass
except Exception as e:
    print(e)