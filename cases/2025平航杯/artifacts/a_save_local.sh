#!/bin/bash
SRC=/tmp/afad/knowledge/solved
DST=/mnt/f/cloud/DD/share/to_autoforensicai_data/knowledge/solved
mkdir -p $DST

cp -v $SRC/2025pinghang_*.md $SRC/pattern_microsoft_pinyin_udp_dict.md $SRC/pattern_metamask_leveldb_sepolia.md $SRC/pattern_sandboxie_artifact_path.md $SRC/pattern_sillytavern_chat_artifact.md $DST/

ls -la $DST/

# 写一个 README
cat > /mnt/f/cloud/DD/share/to_autoforensicai_data/README_HOWTO_UPLOAD.md << 'EOF'
# 上传到 autoforensicai_data 仓库

## 文件清单（共 8 个 .md，约 60KB）

放在 `share/to_autoforensicai_data/knowledge/solved/` 下：

**4 个板块解题报告**（来自 2025 平航杯初赛）
- `2025pinghang_network_traffic.md` (N01-N09，8/9)
- `2025pinghang_mobile_forensics.md` (M01-M13，11/13)
- `2025pinghang_server_forensics.md` (S01-S16，16/16)
- `2025pinghang_computer_forensics.md` (C01-C21，14/21)

**4 个可复用 pattern**
- `pattern_microsoft_pinyin_udp_dict.md`
- `pattern_metamask_leveldb_sepolia.md`
- `pattern_sandboxie_artifact_path.md`
- `pattern_sillytavern_chat_artifact.md`

## 上传步骤

```bash
# 1. clone 你的仓库（首次）
git clone https://github.com/HJSSSRX/autoforensicai_data.git
cd autoforensicai_data

# 2. 把这 8 个文件拷进去
cp F:\cloud\DD\share\to_autoforensicai_data\knowledge\solved\*.md knowledge/solved/

# 3. commit + push
git add knowledge/solved/
git commit -m "2025 平航杯初赛: 4 板块解题报告 (49/73) + 4 个新 pattern"
git push origin main
```

## 格式说明
所有文件都按线上库标准（YAML frontmatter + Markdown）：
- frontmatter: `tags / tools / category / difficulty / source / date / verified`
- body: `# Title / ## Problem / ## Solution Steps / ## Key Takeaways / ## Real Case` 等

可以直接被 `search.py` 索引：
```bash
python search.py --tags microsoft_pinyin
python search.py --tools curl_jsonrpc
python search.py --text "BIP39 助记词"
```
EOF

echo
echo '=== 已保存 ==='
ls -la /mnt/f/cloud/DD/share/to_autoforensicai_data/