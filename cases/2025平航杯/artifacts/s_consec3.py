#!/usr/bin/env python3
import re
from datetime import datetime, timezone, timedelta
from collections import defaultdict

CST = timezone(timedelta(hours=8))
T1 = int(datetime(2016,4,1,0,0,0,tzinfo=CST).timestamp())
T2 = int(datetime(2025,4,1,0,0,0,tzinfo=CST).timestamp())

F = '/tmp/binlog_decoded/mysql-bin.000026.sql'

orders = {}
with open(F, 'r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        if 'INSERT INTO `tp_order`' not in line: continue
        m = re.search(r"VALUES\s*\((.+)\)\s*$", line.strip())
        if not m: continue
        parts = re.findall(r"NULL|'(?:[^'\\]|\\.)*'", m.group(1))
        if len(parts) < 31: continue
        try:
            oid = parts[0].strip("'")
            uid = parts[2].strip("'")
            t = int(parts[29].strip("'"))
            orders[oid] = (uid, t)
        except: pass

filtered = [(oid, uid, t) for oid,(uid,t) in orders.items() if T1 <= t < T2]
# 全数据集（不限范围）
all_filt = list(orders.values())

print(f'Range: {len(filtered)}, All: {len(all_filt)}')

def consec_users(orders_list, mode):
    user_dates = defaultdict(set)
    for o in orders_list:
        if isinstance(o, tuple) and len(o)==3:
            _, uid, t = o
        else:
            uid, t = o
        d = datetime.fromtimestamp(t, CST).date()
        user_dates[uid].add(d)
    res = set()
    for uid, dates in user_dates.items():
        sorted_d = sorted(dates)
        if mode == 'consec3':
            for i in range(len(sorted_d)-2):
                if (sorted_d[i+1]-sorted_d[i]).days == 1 and (sorted_d[i+2]-sorted_d[i+1]).days == 1:
                    res.add(uid); break
        elif mode == '3in3':
            # 3 单在任意 3 个日历日窗口
            ts_sorted = sorted(t for _,uid2,t in orders_list if uid2 == uid)
            n = len(ts_sorted)
            for i in range(n-2):
                if ts_sorted[i+2] - ts_sorted[i] <= 3*86400:
                    res.add(uid); break
    return res

print('\n# 解释1: 任意连续 3 个日历日每天 ≥1 单 (range)')
r1 = consec_users(filtered, 'consec3')
print(f'  count={len(r1)} users={sorted(r1, key=int)}')

print('\n# 解释1 (all data, no range):')
r1a = consec_users([(o, uid, t) for o,(uid,t) in orders.items()], 'consec3')
print(f'  count={len(r1a)} users={sorted(r1a, key=int)}')

print('\n# 解释2: 同用户 3 单在 ≤3 日历日内 (range):')
r2 = consec_users(filtered, '3in3')
print(f'  count={len(r2)}')

print('\n# 用户订单数分布 (range):')
ucnt = defaultdict(int)
for _, uid, _ in filtered:
    ucnt[uid] += 1
from collections import Counter
top = Counter(ucnt).most_common(10)
print(f'  top users by order count: {top}')