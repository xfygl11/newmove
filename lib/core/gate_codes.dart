/// 本地质量门码的唯一登记表（M24 T25.4）。
///
/// 门码是稳定机器码，是日志与下游对账的凭据，也是 `GateLogs` 里 `gateId` 的取值域。
/// 「从没响」榜单需要全量门码作对照面——没有这张表，从未触发的门无法被识别。
///
/// 各门实现文件仍然写字面量（避免把纯机械替换铺进 8 个文件），本文件负责
/// 维护全集：`GateIssue` 构造时校验码在表内，写错码或未登记的码在测试里立刻炸。
/// 新增门码必须先在 `AGENTS.md` 门码登记表与 `docs/04` 对应章节登记，再在本文件
/// 与门实现里同时出现。
library;

abstract final class GateCodes {
  // ── 分段预算（SegmentBudget）────────────────────────────────
  static const overLimit = 'over_limit';
  static const underLimit = 'under_limit';
  static const dialogueOverflow = 'dialogue_overflow';
  static const totalMismatch = 'total_mismatch';
  static const tooFewSegments = 'too_few_segments';
  static const batchTooLarge = 'batch_too_large';

  // ── 单句时长（DurationGate）────────────────────────────────
  static const lineTooLong = 'line_too_long';
  static const totalOverBudget = 'total_over_budget';
  static const totalUnderBudget = 'total_under_budget';

  // ── 剧本场次（ScriptGate）──────────────────────────────────
  static const hasAction = 'has_action';
  static const actionProse = 'action_prose';
  static const speakerUnknown = 'speaker_unknown';

  // ── 分镜镜头（ShotGate）────────────────────────────────────
  static const crowdCheck = 'crowd_check';
  static const segmentSeq = 'segment_seq';
  static const frameEmpty = 'frame_empty';
  static const phraseMissing = 'phrase_missing';
  static const videoNoNames = 'video_no_names';

  // ── 角色服装（CostumeGate）─────────────────────────────────
  static const costumeOrphan = 'costume_orphan';
  static const costumeDuplicate = 'costume_duplicate';
  static const costumeUnknown = 'costume_unknown';

  // ── 资产提示词（PromptGate）────────────────────────────────
  static const promptSimilar = 'prompt_similar';
  static const anchorCount = 'anchor_count';
  static const lightingMissing = 'lighting_missing';
  static const propStates = 'prop_states';
  static const propScale = 'prop_scale';
  static const propWhiteBg = 'prop_white_bg';
  static const sceneNotEmpty = 'scene_not_empty';
  static const propHasHand = 'prop_has_hand';
  static const sceneNamedCharacter = 'scene_named_character';
  static const styleConflict = 'style_conflict';

  // ── 骨架认领（SkeletonGate）────────────────────────────────
  static const coverage = 'coverage';

  // ── 角色画像（CharacterGate）───────────────────────────────
  static const tierMissing = 'tier_missing';
  static const tierCap = 'tier_cap';
  static const evidenceUnverified = 'evidence_unverified';
  static const relationSelf = 'relation_self';
  static const relationOrphan = 'relation_orphan';

  /// 全量门码，报表页的「从没响」用它与已记录的码做差集。
  static const all = <String>[
    overLimit,
    underLimit,
    dialogueOverflow,
    totalMismatch,
    tooFewSegments,
    batchTooLarge,
    lineTooLong,
    totalOverBudget,
    totalUnderBudget,
    hasAction,
    actionProse,
    speakerUnknown,
    crowdCheck,
    segmentSeq,
    frameEmpty,
    phraseMissing,
    videoNoNames,
    costumeOrphan,
    costumeDuplicate,
    costumeUnknown,
    promptSimilar,
    anchorCount,
    lightingMissing,
    propStates,
    propScale,
    propWhiteBg,
    sceneNotEmpty,
    propHasHand,
    sceneNamedCharacter,
    styleConflict,
    coverage,
    tierMissing,
    tierCap,
    evidenceUnverified,
    relationSelf,
    relationOrphan,
  ];
}
