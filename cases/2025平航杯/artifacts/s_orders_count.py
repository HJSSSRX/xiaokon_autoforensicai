#!/usr/bin/env python3
import re, sys
from datetime import datetime, timezone, timedelta

CST = timezone(timedelta(hours=8))
T1 = int(datetime(2016,4,1,0,0,0,tzinfo=CST).timestamp())   # 1459440000
T2 = int(datetime(2025,4,1,0,0,0,tzinfo=CST).timestamp())   # 1743436800

# Parse all tp_order INSERTs
orders = []  # (order_id, add_time, total_amount, user_id)
with open('/tmp/binlog_decoded/mysql-bin.000026.sql', 'r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        if 'INSERT INTO `tp_order`' not in line:
            continue
        # grab values inside VALUES (....)
        m = re.search(r"VALUES\s*\((.+)\)\s*$", line.strip())
        if not m: continue
        vals = m.group(1)
        # split by ',' but careful — fields are 'xxx' or NULL
        parts = re.findall(r"NULL|'(?:[^'\\]|\\.)*'", vals)
        # order_id col1, user_id col3, total_amount col29, add_time col30
        if len(parts) < 31: continue
        try:
            oid = parts[0].strip("'")
            user_id = parts[2].strip("'")
            total = parts[28].strip("'")
            add_t = int(parts[29].strip("'"))
            orders.append((oid, user_id, total, add_t))
        except Exception:
            pass

print(f'Total tp_order INSERT rows parsed: {len(orders)}')
# distinct by order_id (binlog can have duplicates if same row inserted twice)
unique = {}
for oid, uid, tot, t in orders:
    unique[oid] = (uid, tot, t)
print(f'Distinct order_id: {len(unique)}')

in_range = [(oid,uid,tot,t) for oid,(uid,tot,t) in unique.items() if T1 <= t < T2]
print(f'Orders with add_time in [2016-04-01, 2025-04-01): {len(in_range)}')

# all date range
ts_list = [v[2] for v in unique.values()]
print(f'add_time min={datetime.fromtimestamp(min(ts_list),CST)}  max={datetime.fromtimestamp(max(ts_list),CST)}')

# per-month count (S15 哪个月订单最多)
from collections import Counter
months = Counter()
for oid,uid,tot,t in in_range:
    dt = datetime.fromtimestamp(t, CST)
    months[(dt.year, dt.month)] += 1
print('\nTop 10 months by order count:')
for (y,m), c in months.most_common(10):
    print(f'  {y}-{m:02d}  count={c}')

# Save filtered
with open('/tmp/orders_in_range.tsv','w') as f:
    f.write('order_id\tuser_id\ttotal\tadd_time\tdate\n')
    for oid,uid,tot,t in sorted(in_range, key=lambda x: x[3]):
        f.write(f'{oid}\t{uid}\t{tot}\t{t}\t{datetime.fromtimestamp(t,CST).isoformat()}\n')
print('\nSaved to /tmp/orders_in_range.tsv')