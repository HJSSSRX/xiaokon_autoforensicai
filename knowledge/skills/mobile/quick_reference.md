# Mobile Forensics — Quick Reference

## Android
```bash
# ALEAPP (automated extraction)
aleapp -t tar -i {backup.tar} -o {output_dir}
aleapp -t fs -i {extracted_dir} -o {output_dir}

# ADB (live device)
adb devices
adb shell pm list packages              # Installed packages
adb shell dumpsys battery               # Battery stats
adb pull /data/data/{package}/          # Pull app data
adb backup -all -f backup.ab           # Full backup
```

## iOS
```bash
# iLEAPP (automated extraction)
ileapp -t tar -i {backup.tar} -o {output_dir}
ileapp -t fs -i {backup_dir} -o {output_dir}

# Manifest.db — master index of backup files
sqlite3 Manifest.db "SELECT fileID, relativePath, flags FROM Files WHERE relativePath LIKE '%sms%';"
```

## SQLite Database Analysis
```bash
sqlite3 {db}
.tables                                 # List tables
.schema {table}                         # Table structure
SELECT * FROM {table} LIMIT 10;        # Sample data
SELECT * FROM messages ORDER BY date DESC LIMIT 50;  # Recent messages
```

## WeChat Forensics (Android)
- DB path: `/data/data/com.tencent.mm/MicroMsg/{hash}/EnMicroMsg.db`
- Encrypted with SQLCipher, key derived from IMEI + UIN
- Key extraction: `md5(IMEI + uin)[:7]`
- Open with: `sqlcipher EnMicroMsg.db` → `PRAGMA key = '{key}';`

## WeChat Forensics (iOS)
- DB path: `AppDomain-com.tencent.xin/Documents/{hash}/DB/MM.sqlite`
- Not encrypted on iOS (accessible from backup)

## Common Timestamps
- Android: Unix milliseconds (`date / 1000`)
- iOS: Core Data (seconds since 2001-01-01, add 978307200 for Unix)
- SQLite: varies by app
