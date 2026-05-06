# Windows Registry Forensics — Quick Reference

## Registry Hive Files Location
| Hive | Path |
|------|------|
| SYSTEM | `C:\Windows\System32\config\SYSTEM` |
| SOFTWARE | `C:\Windows\System32\config\SOFTWARE` |
| SAM | `C:\Windows\System32\config\SAM` |
| SECURITY | `C:\Windows\System32\config\SECURITY` |
| DEFAULT | `C:\Windows\System32\config\DEFAULT` |
| NTUSER.DAT | `C:\Users\{username}\NTUSER.DAT` |
| UsrClass.dat | `C:\Users\{username}\AppData\Local\Microsoft\Windows\UsrClass.dat` |

## Key Registry Paths for Forensics

### System Info
```
# OS install time
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion → InstallDate

# Last shutdown time (FILETIME format)
HKLM\SYSTEM\ControlSet001\Control\Windows → ShutdownTime

# Computer name
HKLM\SYSTEM\ControlSet001\Control\ComputerName\ComputerName → ComputerName
```

### User Info
```
# Local users
HKLM\SAM\SAM\Domains\Account\Users\Names

# Last logged-in user
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI

# Current logged-in user
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData\1
```

### USB / External Devices
```
# USB device history (vendor, product, serial)
HKLM\SYSTEM\ControlSet001\Enum\USBSTOR

# Volume label names
HKLM\SOFTWARE\Microsoft\Windows Portable Devices\Devices
```

### Program Execution
```
# Installed programs
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths

# Uninstalled programs
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall

# Recent files (Open/Save dialogs)
HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU

# Recent Run commands
HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU
```

## BitLocker Decryption
- **密码查找**: 从所有检材中收集密码相关数据，整理成字典暴力破解
- **恢复密钥**: 
  - 加密时会生成恢复密钥，通常保存为 TXT 文件
  - 即使被删除，底层明文可通过关键字搜索恢复
  - 关键字: `Recovery Key`, `恢复密钥`, 48位数字格式 `XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX`
- **自动解锁**: 如果 U盘/移动硬盘设置了自动解锁，接到对应电脑即可解锁
- **内存提取**: 从解密过 BitLocker 的电脑内存镜像中提取密钥

## EFS Decryption
- EFS 加密依赖用户证书，需要用户密码或导出的证书
- 证书位置: `C:\Users\{username}\AppData\Roaming\Microsoft\Crypto\RSA`

## PowerShell History
```
%USERPROFILE%\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
```
