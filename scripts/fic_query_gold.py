#!/usr/bin/env python3
import sqlite3

conn = sqlite3.connect('/tmp/pc_data/home/lha/.config/browser/Default/History')
cursor = conn.cursor()

# Query for gold/黄金
cursor.execute("SELECT url, title, visit_count FROM urls WHERE title LIKE '%黄金%' LIMIT 10")
print("=== 黄金相关记录 ===")
for row in cursor.fetchall():
    print(f"URL: {row[0]}")
    print(f"Title: {row[1]}")
    print(f"Visits: {row[2]}")
    print()

# Query for ransom/勒索
cursor.execute("SELECT url, title FROM urls WHERE title LIKE '%勒索%' OR title LIKE '%decrypt%' OR title LIKE '%ransom%' LIMIT 10")
print("=== 勒索相关记录 ===")
for row in cursor.fetchall():
    print(f"URL: {row[0]}")
    print(f"Title: {row[1]}")
    print()

conn.close()
