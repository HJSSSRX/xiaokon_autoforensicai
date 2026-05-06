#!/bin/bash
rm -rf /tmp/ph /tmp/ph.dl
for u in \
    "https://gitee.com/api/v5/repos/mirrors_github_lil-house/Pyarmor-Static-Unpack-1-API" \
    "https://kkgithub.com/Lil-House/Pyarmor-Static-Unpack-1-API/archive/refs/heads/main.zip" \
    "https://kkgithub.com/Lil-House/Pyarmor-Static-Unpack-1-API/archive/refs/heads/main.tar.gz"; do
    echo "=== $u ==="
    curl -sL --max-time 60 -o /tmp/ph.dl "$u"
    sz=$(stat -c%s /tmp/ph.dl 2>/dev/null)
    echo "size=$sz"
    if [ "$sz" -gt 5000 ]; then
        file /tmp/ph.dl
        # 试解
        cd /tmp
        if file ph.dl | grep -q Zip; then unzip -oq ph.dl; fi
        if file ph.dl | grep -q gzip; then tar xzf ph.dl; fi
        ls -d Pyarmor-Static-Unpack-1-API* 2>/dev/null && break
    fi
done