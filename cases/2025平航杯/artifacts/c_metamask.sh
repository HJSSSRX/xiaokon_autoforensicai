#!/bin/bash
U='/mnt/win_c/Users/起早王'

echo '=== MetaMask Edge 扩展 ID = nkbihfbeogaeaoehlefnkodbefgpgknn ==='
MM="$U/AppData/Local/Microsoft/Edge/User Data/Default/Local Extension Settings/nkbihfbeogaeaoehlefnkodbefgpgknn"
sudo ls -la "$MM" 2>&1
echo
sudo find "$MM" -type f 2>&1 | head

echo
echo '=== IndexedDB leveldb ==='
sudo find "$U/AppData/Local/Microsoft/Edge/User Data/Default" -iname '*metamask*' 2>&1 | head
sudo ls "$U/AppData/Local/Microsoft/Edge/User Data/Default/IndexedDB" 2>&1 | head

echo
echo '=== 其他扩展 ==='
sudo ls "$U/AppData/Local/Microsoft/Edge/User Data/Default/Extensions" 2>&1 | head
sudo ls "$U/AppData/Local/Microsoft/Edge/User Data/Default/Local Extension Settings" 2>&1 | head

echo
echo '=== Extensions 详查 ==='
EXT="$U/AppData/Local/Microsoft/Edge/User Data/Default/Extensions"
for d in $(sudo ls $EXT 2>/dev/null); do
    manifest=$(sudo find $EXT/$d -maxdepth 3 -name 'manifest.json' 2>/dev/null | head -1)
    if [ -n "$manifest" ]; then
        name=$(sudo cat "$manifest" 2>/dev/null | python3 -c "import json,sys; m=json.load(sys.stdin); print(m.get('name','?'), m.get('version','?'))" 2>/dev/null)
        echo "  $d  ->  $name"
    fi
done