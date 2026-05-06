#!/usr/bin/env python3
HID = {
    0x04:'a',0x05:'b',0x06:'c',0x07:'d',0x08:'e',0x09:'f',0x0a:'g',0x0b:'h',
    0x0c:'i',0x0d:'j',0x0e:'k',0x0f:'l',0x10:'m',0x11:'n',0x12:'o',0x13:'p',
    0x14:'q',0x15:'r',0x16:'s',0x17:'t',0x18:'u',0x19:'v',0x1a:'w',0x1b:'x',
    0x1c:'y',0x1d:'z',
    0x1e:'1',0x1f:'2',0x20:'3',0x21:'4',0x22:'5',0x23:'6',0x24:'7',0x25:'8',
    0x26:'9',0x27:'0',
    0x28:'\n',0x29:'<ESC>',0x2a:'<BS>',0x2b:'\t',0x2c:' ',
    0x2d:'-',0x2e:'=',0x2f:'[',0x30:']',0x31:'\\',
    0x33:';',0x34:"'",0x35:'`',
    0x36:',',0x37:'.',0x38:'/',
}
SHIFT = {
    'a':'A','b':'B','c':'C','d':'D','e':'E','f':'F','g':'G','h':'H','i':'I','j':'J',
    'k':'K','l':'L','m':'M','n':'N','o':'O','p':'P','q':'Q','r':'R','s':'S','t':'T',
    'u':'U','v':'V','w':'W','x':'X','y':'Y','z':'Z',
    '1':'!','2':'@','3':'#','4':'$','5':'%','6':'^','7':'&','8':'*','9':'(','0':')',
    '-':'_','=':'+','[':'{',']':'}','\\':'|',';':':',"'":'"','`':'~',',':'<','.':'>','/':'?',
}

prev_keys = set()
caps_on = False
out = []
for line in open('/tmp/kbd.tsv'):
    parts = line.rstrip('\n').split('\t')
    if len(parts) < 2 or not parts[1]: continue
    data = bytes.fromhex(parts[1])
    mod = data[1]
    keys = set(k for k in data[3:9] if k != 0)
    pressed = keys - prev_keys
    shift = bool(mod & 0x22)
    for k in pressed:
        if k == 0x39:  # CapsLock toggle on press
            caps_on = not caps_on
            continue
        ch = HID.get(k, f'<0x{k:02x}>')
        if ch.isalpha() and len(ch)==1:
            # caps XOR shift
            upper = caps_on ^ shift
            ch = ch.upper() if upper else ch.lower()
        elif shift and ch in SHIFT:
            ch = SHIFT[ch]
        out.append(ch)
    prev_keys = keys

text = ''.join(out)
# Split on \n to get commands
lines = text.split('\n')
print('=== full text ===')
print(text)
print('=== per-line ===')
for i,l in enumerate(lines):
    print(f'[{i}] {l!r}')

import hashlib
# N08 shadow account md5
shadow_name = 'qianqianwoaini$'
shadow_pwd = 'abcdefghijkImn'
print(f'N08 name={shadow_name} pwd={shadow_pwd}')
print(f'N08 md5({shadow_name}_{shadow_pwd}) = ' + hashlib.md5(f'{shadow_name}_{shadow_pwd}'.encode()).hexdigest())

# N09 last command md5 candidates
for i,l in enumerate(lines):
    if l.strip() and i>=1:
        last_cmd = l
print(f'N09 last_cmd = {last_cmd!r}')
print(f'N09 md5(last_cmd) = ' + hashlib.md5(last_cmd.encode()).hexdigest())