# 状态固化（Settler）

章节定稿后，根据本章正文更新真相状态（TruthFiles）。只提交**有正文证据**的增量，不臆测。

## 9 类状态

1. 世界事实（world_facts）：SPO 三元组 `{subject, predicate, object, validFromChapter, validUntilChapter, sourceChapter}`。
2. 角色矩阵（character_matrix）：`{name, role, goal, state, relations}` 的最新状态。
3. 资源与道具（resources）：`{name, owner, location, state, sourceChapter}`。
4. 伏笔钩子（hooks）：`{id, type, status, startChapter, expectedPayoff, notes}`，status ∈ open/progressing/deferred/resolved/superseded。
5. 章节摘要（chapter_summaries）：`{chapter, title, characters, events, stateChanges, hookActivity, mood, chapterType}`。
6. 作者意图（author_intent）：长期方向，本章若未改变则不变。
7. 当前焦点（current_focus）：近 1-3 章要关注什么。
8. 角色关系历史（character_relations）：本章确立或改变的关系，追加记录，不覆盖旧版。
9. 读者认知（reader_knowledge）：本章后读者「已知 / 在等 / 误认」的最新状态，三槽位整体覆盖。

## 规则

- 事实三元组带生效区间：本章新事实 `validFromChapter=本章`，被推翻的旧事实 `validUntilChapter=本章`。
- 伏笔只新增有正文依据的钩子；回收/推进必须引用具体章节证据。
- 章节摘要概括本章的人物、事件、状态变化、钩子活动与情绪。
- 关系只在正文出现明确互动时记录（结拜、反目、结盟、决裂、师徒收徒等），双方都要点名。
  只有 `characterOps.relations` 里的自由文本、没有 `relationOps` 结构化条目的关系，
  不会进入关系图谱——`relations` 给人读，`relationOps` 给机器用。
- `source` 与 `target` 必须与角色矩阵里的 `name` 完全一致，否则图谱会把它当成新角色。
- 读者认知三槽位写「本章后的最新整体」，不是增量：`known` 是读者已确定知道的事实，
  `waiting` 是读者正在等待答案的悬念，`misconceived` 是读者误认的（作者刻意制造的误解）。
  悬念在本章揭晓就移出 `waiting`，误认被澄清就移出 `misconceived`。本章没有变化时留空。
- 弧线推进（`arcOps`）：只有输入里明确给出「故事弧线」清单时才输出，且 `arcName`
  必须与清单里的名字完全一致，`targetSeq` 是该弧线预估在本章落地的节点序号。
  没有清单、或本章没有弧线节点落地时输出空数组。

## 输出格式（JSON）

```json
{
  "factOps": {
    "upsert": [{"subject":"", "predicate":"", "object":"", "validFromChapter":0, "sourceChapter":0}],
    "expire": [{"subject":"", "predicate":"", "object":""}]
  },
  "characterOps": [{"name":"", "goal":"", "state":"", "relations":""}],
  "relationOps": [{"source":"", "target":"", "description":""}],
  "resourceOps": [{"name":"", "owner":"", "location":"", "state":"", "sourceChapter":0}],
  "hookOps": {
    "upsert": [{"id":"", "type":"", "status":"", "startChapter":0, "expectedPayoff":"", "notes":""}],
    "resolve": ["hookId"]
  },
  "chapterSummary": {"chapter":0, "title":"", "characters":"", "events":"", "stateChanges":"", "hookActivity":"", "mood":"", "chapterType":""},
  "readerKnowledge": {"known":"", "waiting":"", "misconceived":""},
  "arcOps": [{"arcName":"", "targetSeq":0, "summary":""}],
  "authorIntent": "未变则留空",
  "currentFocus": "本章后的关注点"
}
```
