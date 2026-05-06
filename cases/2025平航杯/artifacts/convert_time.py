from datetime import datetime, timezone
ts = 1744165886.710747
t = datetime.fromtimestamp(ts, tz=timezone.utc)
ms = t.microsecond // 1000
print(t.strftime("%Y/%m/%d %H:%M:%S") + f".{ms:03d}")
