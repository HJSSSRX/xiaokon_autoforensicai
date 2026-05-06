#!/usr/bin/env python3
import re
from datetime import datetime, timezone, timedelta
from collections import defaultdict

CST = timezone(timedelta(hours=8))
T1 = int(datetime(2016,4,1,0,0,0,tzinfo=CST).timestamp())
T2 = int(datetime(2025,4,1,0,0,0,tzinfo=CST).timestamp())

F = '/tmp/binlog_decoded/mysql-bin.000026.sql'

# Parse tp_users: user_id (col1), reg_time (col13)
# CREATE TABLE tp_users 字段顺序需先确认
# 用 backup sql 找
USER_BACKUP = '/mnt/server/www/wwwroot/www.tpshop.com/backup/www_TPshop_com1.sql'

# Parse tp_users INSERTs from binlog
users = {}  # user_id -> reg_time
with open(F, 'r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        if 'INSERT INTO `tp_users`' not in line:
            continue
        m = re.search(r"VALUES\s*\((.+)\)\s*$", line.strip())
        if not m: continue
        vals = m.group(1)
        parts = re.findall(r"NULL|'(?:[^'\\]|\\.)*'", vals)
        # tp_users: user_id col1, ...
        if len(parts) < 14: continue
        try:
            uid = parts[0].strip("'")
            reg_time = int(parts[12].strip("'"))  # col 13: reg_time
            users[uid] = reg_time
        except Exception:
            pass
print(f'tp_users distinct: {len(users)}')

# Parse tp_order again
orders = {}  # order_id -> (user_id, add_time)
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

# 在范围内的订单
filtered = [(oid, uid, t) for oid,(uid,t) in orders.items() if T1 <= t < T2]
print(f'Orders in range: {len(filtered)}')

# 每用户首单
first_order = {}
for oid, uid, t in filtered:
    if uid not in first_order or t < first_order[uid]:
        first_order[uid] = t
print(f'Users with at least one order in range: {len(first_order)}')

# S14: 注册→首单 间隔最短的用户
gaps = []
for uid, ft in first_order.items():
    if uid in users:
        gap = ft - users[uid]
        if gap >= 0:
            gaps.append((gap, uid, users[uid], ft))
gaps.sort()
print('\nTop 5 shortest reg→first_order gaps:')
for g, uid, rt, ft in gaps[:5]:
    print(f'  uid={uid}  gap={g}s  reg={datetime.fromtimestamp(rt,CST)}  first_order={datetime.fromtimestamp(ft,CST)}')

# S16: 连续三天下单的用户
user_dates = defaultdict(set)
for oid, uid, t in filtered:
    d = datetime.fromtimestamp(t, CST).date()
    user_dates[uid].add(d)

consec3 = set()
for uid, dates in user_dates.items():
    sorted_d = sorted(dates)
    for i in range(len(sorted_d)-2):
        d1, d2, d3 = sorted_d[i], sorted_d[i+1], sorted_d[i+2]
        if (d2 - d1).days == 1 and (d3 - d2).days == 1:
            consec3.add(uid)
            break

print(f'\nS16: Users with 3 consecutive days of orders: {len(consec3)}')
print(f'Sample: {sorted(consec3, key=int)[:20]}')