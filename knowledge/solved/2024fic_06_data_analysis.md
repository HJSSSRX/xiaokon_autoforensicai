---
tags: [data_analysis, mysql, sql_query, mlm_pyramid, hierarchy_analysis, financial_forensics, website_reconstruction]
tools: [mysql, honglian_netju, sql, excel]
category: data_analysis
difficulty: medium
source: 2024FIC_finals
date: 2026-05-05
verified: false
---
# Title: 2024FIC Finals - Data Analysis (9 Questions)

## Problem
After reconstructing the "é²¸æ˜“å…ƒMALLç®¡ç†ç³»ç»Ÿ" website, analyze the database to answer questions about members, hierarchy, orders, and financial transactions in an MLM (ä¼ é”€) scheme.

## Prerequisites
- Website must be reconstructed first (see server forensics writeup)
- MySQL database accessible via Docker container on port 13306
- Admin backend accessible via browser

## Solution Steps

### Q1: Members with "æ€»ä»£" (Top Agent) level count
Admin backend â†?Member Management â†?filter by level "æ€»ä»£".
â†?**248**

### Q2: Total hierarchy depth (using æ¨èäººid as parent)
Export member data from admin backend. Use å¼˜è”ç½‘é’œ (Honglian NetJu) data analysis tool:
1. Import as organizational structure
2. Select **strict mode**
3. Tool calculates max depth automatically
â†?**53**

### Q3: Downstream member count for member sgl01
Filter member ID = sgl01 in ç½‘é’œ, check downstream count.
â†?**18001**

### Q4: Total recharge amount for sgl01's downstream members
From MySQL `member_money` table (contains recharge totals). Cross-reference with `member` table for hierarchy.
Export both tables â†?import into ç½‘é’œ with organizational template.
â†?**8704119** (å…?RMB, note: database stores without decimal places)

### Q5: Paid order count
Admin backend â†?Order Management â†?filter status = "å·²æ”¯ä»? (paid).
â†?**31760**

### Q6: Total payment amount for paid orders
```sql
SELECT SUM(pay_money) FROM `doing_order` WHERE is_pay=1
```
â†?**71979976** (å…?RMB, note two decimal places in raw data)

### Q7: Bank card records in withdrawal account management
Admin backend â†?Withdrawal Management â†?Account Management â†?bank card records.
â†?**6701**

### Q8: Successful withdrawal record count
Withdrawal Management â†?filter status = "æ‰“æ¬¾æˆåŠŸ".
â†?**8403**

### Q9: Total withdrawal amount for successful payouts
```sql
SELECT SUM(need_give_money) FROM `member_deal` WHERE deal_status = 4
```
(deal_status = 4 means successful payout)
â†?**10067655** (å…?RMB)

## Key Takeaways
- **å¼˜è”ç½‘é’œ (NetJu)**: Purpose-built for MLM hierarchy analysis â€?imports member data, calculates depth, downstream counts, financial aggregations automatically
- **Strict mode in NetJu**: Required for accurate hierarchy analysis with æ¨èäººid as parent
- **SQL for financial queries**: When admin UI doesn't show totals, query database directly
- **Key tables**:
  - `sys_user` â€?admin accounts
  - `member` â€?member info, hierarchy (æ¨èäººid)
  - `member_money` â€?recharge/balance data
  - `doing_order` â€?orders (is_pay=1 for paid)
  - `member_deal` â€?withdrawal records (deal_status=4 for success, need_give_money for amount)
- **Decimal precision**: Database may store amounts without trailing zeros; verify decimal places
- **Member count**: Total 52908 members visible in admin backend after reconstruction

## Answer
Q1: 248
Q2: 53
Q3: 18001
Q4: 8704119
Q5: 31760
Q6: 71979976
Q7: 6701
Q8: 8403
Q9: 10067655
