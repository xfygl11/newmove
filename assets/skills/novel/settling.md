# 状态固化（Settler）

章节定稿后，根据本章正文更新真相状态（TruthFiles）。只提交**有正文证据**的增量，不臆测。

## 7 类状态

1. 世界事实（world_facts）：SPO 三元组 `{subject, predicate, object, validFromChapter, validUntilChapter, sourceChapter}`。
2. 角色矩阵（character_matrix）：`{name, role, goal, state, relations}` 的最新状态。
3. 资源与道具（resources）：`{name, owner, location, state, sourceChapter}`。
4. 伏笔钩子（hooks）：`{id, type, status, startChapter, expectedPayoff, notes}`，status ∈ open/progressing/deferred/resolved/superseded。
5. 章节摘要（chapter_summaries）：`{chapter, title, characters, events, stateChanges, hookActivity, mood, chapterType}`。
6. 作者意图（author_intent）：长期方向，本章若未改变则不变。
7. 当前焦点（current_focus）：近 1-3 章要关注什么。

## 规则

- 事实三元组带生效区间：本章新事实 `validFromChapter=本章`，被推翻的旧事实 `validUntilChapter=本章`。
- 伏笔只新增有正文依据的钩子；回收/推进必须引用具体章节证据。
- 章节摘要概括本章的人物、事件、状态变化、钩子活动与情绪。

## 输出格式（JSON）

```json
{
  "factOps": {
    "upsert": [{"subject":"", "predicate":"", "object":"", "validFromChapter":0, "sourceChapter":0}],
    "expire": [{"subject":"", "predicate":"", "object":""}]
  },
  "characterOps": [{"name":"", "goal":"", "state":"", "relations":""}],
  "resourceOps": [{"name":"", "owner":"", "location":"", "state":"", "sourceChapter":0}],
  "hookOps": {
    "upsert": [{"id":"", "type":"", "status":"", "startChapter":0, "expectedPayoff":"", "notes":""}],
    "resolve": ["hookId"]
  },
  "chapterSummary": {"chapter":0, "title":"", "characters":"", "events":"", "stateChanges":"", "hookActivity":"", "mood":"", "chapterType":""},
  "authorIntent": "未变则留空",
  "currentFocus": "本章后的关注点"
}
```
