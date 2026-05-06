#!/bin/bash
cd /tmp
for url in \
    https://github.com/Lil-House/Pyarmor-Static-Unpack-1-API.git \
    https://gh.api.99988866.xyz/https://github.com/Lil-House/Pyarmor-Static-Unpack-1-API.git \
    https://kkgithub.com/Lil-House/Pyarmor-Static-Unpack-1-API.git \
    https://gitclone.com/github.com/Lil-House/Pyarmor-Static-Unpack-1-API.git
do
    echo "== $url =="
    rm -rf ph
    git clone --depth 1 "$url" ph 2>&1 | tail -3
    if [ -d ph/.git ]; then echo OK; break; fi
done
echo
ls ph 2>/dev/null
echo '---'
# 备选: zip 下载
if [ ! -d ph/.git ]; then
    for u in \
        https://kkgithub.com/Lil-House/Pyarmor-Static-Unpack-1-API/archive/refs/heads/main.zip \
        https://github.com/Lil-House/Pyarmor-Static-Unpack-1-API/archive/refs/heads/main.zip \
        https://codeload.github.com/Lil-House/Pyarmor-Static-Unpack-1-API/zip/refs/heads/main; do
        echo "ZIP: $u"
        curl -sL --max-time 30 -o /tmp/ph.zip "$u"
        sz=$(stat -c%s /tmp/ph.zip 2>/dev/null)
        echo "  size=$sz"
        if [ "$sz" -gt 1000 ]; then
            cd /tmp && unzip -oq ph.zip && ls -d Pyarmor-Static-Unpack-1-API-* && break
        fi
    done
fi