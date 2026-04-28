# MODE_SOLO — 单人快速模式

> 适用：一人一机，题型熟悉，要**最快拿分**。
> 核心：AI 少问多跑，直扑答案，只在**必要时**才打断用户。

---

## 开场 5 步（不要拖，5 分钟内完成）

```
1. ls cases/<比赛>/             看检材清单
2. 读 questions.md              一次把所有题读完，分类
3. 读 handover.md（若存在）      看前次进度
4. 环境健康检查（默认省略，除非怀疑坏）
5. 直接报告"我打算按 Q01-Q05 开始做 Windows 磁盘题，开工"
```

**不做**：
- ❌ 不一题题问"先做哪个"（题目熟 → AI 自己决策）
- ❌ 不要列 10 条 triage（直接干就行）
- ❌ 不要求用户确认每个工具命令

---

## 战术：按题型批量干

同类型题**一次跑工具，多次查结果**。例：

```bash
# 对 Windows 镜像一次性跑完所有 Zimmerman 工具
$A = 'artifacts\windows'; $O = 'artifacts\parsed'
tools\EZ\MFTECmd.exe  -f "$A\$MFT"          --csv $O --csvf mft.csv
tools\EZ\EvtxECmd.exe -d "$A\winevt\Logs"   --csv $O --csvf evtx.csv
tools\EZ\PECmd.exe    -d "$A\Prefetch"      --csv $O --csvf prefetch.csv
tools\EZ\RECmd\RECmd.exe --bn tools\EZ\RECmd\BatchExamples\Kroll_Batch.reb -d $A --csv $O
```

然后**所有 Windows 题都从这些 CSV 里查**，不再重复跑。

---

## 什么时候打断用户（SOLO 模式极少，但必须）

| 情景 | 打断方式 |
|------|---------|
| 需要密码/口令（VeraCrypt、7z、SQLCipher） | 一次列出所有需要的，让用户一起给 |
| 需要火眼 GUI 操作（解密备份、仿真桌面） | 明确说"请在火眼 XX 做 YY，导出到 Z，告诉我目录" |
| 题目意图真的歧义 | 列 2-3 个解读让用户选 |
| 跑到第 3 题发现前提错了 | 立刻停，报告原因 |

---

## 每 5 题硬交付

生成 `cases/<比赛>/wp_batches/Q<NN>-Q<MM>.md`（格式见 `WP_FORMAT.md`），然后：

```
✅ Q01-Q05 (5/71)
| Q | 答 | 置信 |
|---|---|------|
| 01 | xxx | 高 |
| 02 | xxx | 高 |
| 03 | 未解 | - |
| 04 | xxx | 中 |
| 05 | xxx | 高 |

下一批建议：Q06-Q10（安卓微信）。需先解密 EnMicroMsg.db，需要用户给 IMEI。
继续？
```

---

## 弃权指标（SOLO 必须狠）

遇到 **任一** 就跳：
- 卡 20 分钟无进展（SOLO 比 COOP 更快放弃）
- 需要离线爆破 > 1 小时
- 需要逆向大型 native 代码
- 火眼也做不了

跳过时在 `answers.md` 留一行 `## Q<NN> [跳过] 原因：...`。

---

## SOLO 模式 AI 性格调校

- **少问**：一次决策，不反复 triage
- **多跑**：遇到不确定的先跑命令看结果再推理
- **快报**：每题 30-60 秒内要么出答案要么说卡点
- **不啰嗦**：答题用表格和短句，不要写长段落
- **不美化**：答案对就行，不美化格式、不修邻近代码
