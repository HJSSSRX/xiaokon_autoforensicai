# 安装后验证清单

运行完安装脚本后，逐项确认：

## WSL 工具

```bash
# 在 WSL 中运行
sqlite3 --version          # 应输出 3.37+
strings --version          # GNU strings
r2 -v                      # radare2 5.x
jadx --version             # jadx 1.5+
fls -V                     # sleuthkit 4.x
openssl version            # OpenSSL 3.x
python3 --version          # Python 3.10+
exiftool -ver              # 12.x
```

## Python 包

```bash
source ~/.venv-forensics/bin/activate
python3 -c "from Cryptodome.Cipher import AES; print('pycryptodome OK')"
python3 -c "import sqlcipher3; print('sqlcipher3 OK')"
python3 -c "import openpyxl; print('openpyxl OK')"
python3 -c "import pandas; print('pandas OK')"
```

## Windows 工具

```powershell
7z                         # 7-Zip
git --version              # Git
```

## 常见问题

### sqlcipher3 安装失败
```bash
# 先装系统依赖
sudo apt-get install -y libsqlcipher-dev
# 再装 Python 包（二进制版本避免编译）
pip install sqlcipher3-binary
```

### jadx 需要 Java
```bash
sudo apt-get install -y default-jdk-headless
java -version  # 应输出 OpenJDK 17+
```

### radare2 版本太老
```bash
# 从 GitHub 下载最新 deb
R2_VER="5.9.8"
curl -fsSL -o /tmp/r2.deb "https://github.com/radareorg/radare2/releases/download/${R2_VER}/radare2_${R2_VER}_amd64.deb"
sudo dpkg -i /tmp/r2.deb
```

### WSL 磁盘空间不足
```powershell
# 压缩 WSL 虚拟磁盘
wsl --shutdown
Optimize-VHD -Path "$env:LOCALAPPDATA\Packages\CanonicalGroupLimited*\LocalState\ext4.vhdx" -Mode Full
```

### PowerShell 执行策略
```powershell
# 如果 .ps1 脚本无法运行
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
