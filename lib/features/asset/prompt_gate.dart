/// 资产提示词的本地质量门（M19 T21.1 / T21.4 / T21.5，M22 T23.1 增补五门）。
///
/// 纯函数、不写库、只提示不阻塞。所有门都是本地机械校验，放在消耗算力之前
/// 拦下，比写进提示词碰运气可靠得多。
///
/// 门码（稳定机器码，不要改）：
/// - `prompt_similar`（warn）两个角色外观描述 Jaccard 超过 [PromptGate.jaccardMax]，
///   出图会撞脸。只查 `appearanceAnchor` 描述性字段——四视图排版模板是
///   固定文本，角色之间本来就有高重合，查全量 prompt 会全红。
/// - `anchor_count`（warn）外观锚点字段数不在 3-5 之间。三种资产类型都查：
///   角色 age/gender/hair/outfit/key，场景 location/time/lighting/key，
///   道具 material/size/color/key。锚点为空或坏 JSON 跳过（缺字段照常通过）。
/// - `lighting_missing`（warn）提示词或外观锚点都没有光照描述，出图光感靠
///   模型默认。光照是布光指令，两处任一命中即算已描述。
/// - `scene_not_empty`（error）场景提示词没写空景表述，图像模型会自动补人。
/// - `scene_named_character`（warn）场景提示词出现角色名，会诱发模型画出该角色。
/// - `prop_has_hand`（error）道具提示词没显式排除手部——最常见的污染就是
///   一只握着道具的手。
/// - `prop_states`（warn）道具提示词与外观锚点都没有状态描述
///   （正常 / 破损 / 使用中 / 隐藏）。
/// - `prop_scale`（warn）道具提示词与外观锚点都没有尺度描述，与人物比例会失控。
/// - `prop_white_bg`（warn）道具提示词没有白底 / 孤立表述，贴进分镜会带原背景。
/// - `style_conflict`（warn）同一批提示词出现互斥画风族。
library;

import 'dart:convert';

import '../../core/gate_issue.dart';
import '../../core/json_values.dart';
import '../../data/app_database.dart';

abstract final class PromptGate {
  PromptGate._();

  /// Jaccard 相似度上限。量测依据见 `docs/01` §11.3：
  /// 区分良好的角色约 0.1-0.3，仅改一处外观的同模板克隆可达 0.8+。
  static const double jaccardMax = 0.75;

  /// 参与比较的最小词元数。外观锚点很短，词元太少时词集合比较没有意义。
  static const int minTokens = 6;

  /// 按词元集合算 Jaccard 相似度，[a] 或 [b] 词元数不足 [minTokens] 时返回 0。
  static double jaccard(String? a, String? b) {
    final x = tokens(a ?? '');
    final y = tokens(b ?? '');
    if (x.length < minTokens || y.length < minTokens) return 0;
    var inter = 0;
    for (final t in x) {
      if (y.contains(t)) inter++;
    }
    final union = {...x, ...y};
    return union.isEmpty ? 0 : inter / union.length;
  }

  /// 分词：连续的 CJK 字逐字算词元，连续的字母数字串算一个词元，
  /// 长度不超过 1 的英文/数字词元丢弃。
  ///
  /// 中文没有词边界，整段提示词会被 `split` 成寥寥几个长串，词元集合没有
  /// 区分度——所以 CJK 必须逐字切，这是本门能用中文提示词的前提。
  static Set<String> tokens(String text) {
    final result = <String>{};
    final word = StringBuffer();
    var inWord = false;
    for (var i = 0; i < text.length; i++) {
      final lower = text[i].toLowerCase();
      final code = lower.codeUnitAt(0);
      if (code >= 0x4e00 && code <= 0x9fff) {
        if (inWord) {
          _flushWord(word, result);
          inWord = false;
        }
        result.add(lower);
      } else if (_isWordChar(code)) {
        word.write(lower);
        inWord = true;
      } else if (inWord) {
        _flushWord(word, result);
        inWord = false;
      }
    }
    if (inWord) _flushWord(word, result);
    return result;
  }

  static bool _isWordChar(int code) =>
      (code >= 0x30 && code <= 0x39) || (code >= 0x61 && code <= 0x7a);

  static void _flushWord(StringBuffer word, Set<String> result) {
    final value = word.toString();
    word.clear();
    if (value.length > 1) result.add(value);
  }

  /// 角色外观锚点拼成的描述文本。空锚点返回空串（会被 [jaccard] 判为不参与比较）。
  static String descriptorOf(Asset asset) {
    final raw = (asset.appearanceAnchor ?? '').trim();
    if (raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return raw;
      final parts = decoded.values.map(jsonString).where((v) => v.trim().isNotEmpty);
      return parts.join(' ');
    } on FormatException {
      return raw;
    }
  }

  /// 角色雷同门：两两比对同批角色的外观描述。
  static List<GateIssue> similarCharacters(List<Asset> assets) {
    final entries = [
      for (final asset in assets)
        if (asset.type == '角色' && descriptorOf(asset).trim().isNotEmpty) asset,
    ];
    final issues = <GateIssue>[];
    for (var i = 0; i < entries.length; i++) {
      for (var j = i + 1; j < entries.length; j++) {
        final a = entries[i];
        final b = entries[j];
        final sim = jaccard(descriptorOf(a), descriptorOf(b));
        if (sim >= jaccardMax) {
          issues.add(
            GateIssue(
              code: 'prompt_similar',
              severity: GateSeverity.warn,
              locator: '${a.name} / ${b.name}',
              message: '外观描述相似度 ${(sim * 100).toStringAsFixed(1)}%'
                  '（>= ${jaccardMax * 100} %），出图会撞脸，至少区分发型、'
                  '服装或一个独有细节',
            ),
          );
        }
      }
    }
    return issues;
  }

  /// 外观锚点的字段数下限：角色是 age/gender/hair/outfit/key，
  /// 场景是 location/time/lighting/key，道具是 material/size/color/key，
  /// 三种类型都在这个区间内（见 `assets/skills/asset/asset_design.md`）。
  static const int anchorMin = 3;

  /// 外观锚点的字段数上限：超过 5 个字段通常是在写散文而非结构化锚点，
  /// 出图时模型会挑最显眼的忽略其余。
  static const int anchorMax = 5;

  /// 光照描述标记：缺这个，出图的光感全靠模型默认。
  ///
  /// 「必须有」型标记，不做否定语境豁免——写「不要强光」也是在描述光，
  /// 门的目的只是确认提示词提到了这件事。
  static const List<String> lightingMarkers = [
    '光照', '光线', '光源', '逆光', '侧光', '顶光', '环境光', '氛围光',
    '柔光', '硬光', '布光', '高光', '轮廓光',
    'lighting', 'light source', 'rim light', 'backlight', 'soft light', 'hard light',
  ];

  /// 道具状态标记：道具的可用性是剧情信息，缺失会让后续镜头无法表达「已用掉」。
  static const List<String> propStateMarkers = [
    '正常', '破损', '完好', '损坏', '使用中', '隐藏', '状态', 'state',
  ];

  /// 道具尺度标记：缺少尺度会让道具与人物比例失控。含长度单位——
  /// 用户写「10 厘米」也是在给尺度。
  static const List<String> propScaleMarkers = [
    '尺度', '比例', '尺寸', '大小', '长度', '身高',
    '厘米', '公分', '毫米', '英寸', 'cm', 'mm', 'inch',
    'scale', 'ratio',
  ];

  /// 道具白底 / 孤立表述标记：道具图不孤立，后续分镜里会带着原背景一起贴。
  static const List<String> whiteBgMarkers = [
    '白底', '白色背景', '纯白', '透明背景', 'isolated', 'white background',
    'transparent background',
  ];

  /// 外观锚点解析成结构化 Map；空值或非法 JSON 返回 null（按未指定处理，不误报）。
  static Map<String, dynamic>? anchorMap(Asset asset) {
    final raw = (asset.appearanceAnchor ?? '').trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return jsonMap(decoded);
    } on FormatException {
      // 落库前已校验过；这里兜底避免损坏数据让整个门崩掉。
    }
    return null;
  }

  /// 锚点非空字段数。
  static int anchorCount(Asset asset) {
    final map = anchorMap(asset);
    if (map == null) return 0;
    return map.values
        .map((v) => jsonString(v).trim())
        .where((v) => v.isNotEmpty)
        .length;
  }

  /// 光照 / 尺度 / 状态这类标记的检索面：prompt 与外观锚点合并。
  ///
  /// skill 里场景锚点有 `lighting` 字段、道具锚点有 `size` 字段，
  /// 而同类信息也可能写在 prompt 正文里；两处都算「已描述」。
  static String surfaceOf(Asset asset) =>
      '${asset.prompt} ${descriptorOf(asset)}';

  /// 外观锚点字段数门：三种资产类型都查。
  /// 锚点为空或解析失败跳过（缺字段的旧数据照常通过）。
  static List<GateIssue> anchorCountGate(List<Asset> assets) {
    return [
      for (final asset in assets)
        if (anchorMap(asset) != null) ...anchorCountOf(asset),
    ];
  }

  static List<GateIssue> anchorCountOf(Asset asset) {
    final count = anchorCount(asset);
    if (count == 0) return const [];
    if (count < anchorMin) {
      return [
        GateIssue(
          code: 'anchor_count',
          severity: GateSeverity.warn,
          locator: asset.name,
          message: '外观锚点只有 $count 个字段（建议 $anchorMin-$anchorMax 个）：'
              '发型、服装、身形之外至少再给一个辨识锚点，否则出图辨识度靠运气',
        ),
      ];
    }
    if (count > anchorMax) {
      return [
        GateIssue(
          code: 'anchor_count',
          severity: GateSeverity.warn,
          locator: asset.name,
          message: '外观锚点有 $count 个字段（建议 $anchorMin-$anchorMax 个）：'
              '字段太多时模型会挑显眼的忽略其余，请合并成 $anchorMax 个以内',
        ),
      ];
    }
    return const [];
  }

  /// 光照门：扫 [Asset.prompt] 与 [Asset.appearanceAnchor] 合并面，所有资产类型都查。
  ///
  /// skill 里场景锚点有 `lighting` 字段、角色锚点没有，但光照也可能写在
  /// prompt 正文里，两处都算「已描述」。
  static List<GateIssue> lightingMissing(List<Asset> assets) {
    return [
      for (final asset in assets)
        if (!_containsAny(surfaceOf(asset), lightingMarkers))
          GateIssue(
            code: 'lighting_missing',
            severity: GateSeverity.warn,
            locator: asset.name,
            message: '提示词与外观锚点都没有光照描述（逆光 / 侧光 / 环境光等）：'
                '出图光感全靠模型默认，与场景图的布光对不上',
          ),
    ];
  }

  /// 道具状态门。
  static List<GateIssue> propStates(List<Asset> assets) {
    return [
      for (final asset in assets)
        if (asset.type == '道具')
          if (!_containsAny(surfaceOf(asset), propStateMarkers))
            GateIssue(
              code: 'prop_states',
              severity: GateSeverity.warn,
              locator: asset.name,
              message: '道具提示词或外观锚点没有状态描述（正常 / 破损 / 使用中 / 隐藏）：'
                  '道具的可用性是剧情信息，缺失会让后续镜头表达不了「已用掉」',
            ),
    ];
  }

  /// 道具尺度门。
  static List<GateIssue> propScale(List<Asset> assets) {
    return [
      for (final asset in assets)
        if (asset.type == '道具')
          if (!_containsAny(surfaceOf(asset), propScaleMarkers))
            GateIssue(
              code: 'prop_scale',
              severity: GateSeverity.warn,
              locator: asset.name,
              message: '道具提示词或外观锚点没有尺度描述（相对手掌或人物的高度）：'
                  '缺尺度会让道具与人物比例失控',
            ),
    ];
  }

  /// 道具白底门。查 [Asset.prompt] 而非锚点：这是给图像模型的排版要求，
  /// 锚点是给人看的描述。
  static List<GateIssue> propWhiteBg(List<Asset> assets) {
    return [
      for (final asset in assets)
        if (asset.type == '道具')
          if (!_containsAny(asset.prompt, whiteBgMarkers))
            GateIssue(
              code: 'prop_white_bg',
              severity: GateSeverity.warn,
              locator: asset.name,
              message: '道具提示词没有白底 / 孤立表述：道具图不孤立时，'
                  '贴进分镜会带着原背景一起被画进去',
            ),
    ];
  }

  /// 空景标记：提示词里必须出现其中之一，图像模型才不会自动补人。
  static const List<String> emptySceneMarkers = ['empty scene', 'no people', '无人物', '无人'];

  /// 手部排除标记：道具提示词必须显式排除手部。
  static const List<String> noHandMarkers = ['手部', '无手', 'hands', 'fingers'];

  static bool _containsAny(String text, List<String> markers) {
    final lowered = text.toLowerCase();
    return markers.any(lowered.contains);
  }

  /// 空景与无手门。
  ///
  /// 角色类资产跳过（角色本来就该有主体）；正文（[Beat] / [Shot]）不在这里查，
  /// 正文本来就该出现角色名。
  static List<GateIssue> emptyScene(List<Asset> assets) {
    final issues = <GateIssue>[];
    for (final asset in assets) {
      if (asset.type != '场景' && asset.type != '道具') continue;
      final prompt = asset.prompt.trim();
      if (!_containsAny(prompt, emptySceneMarkers)) {
        issues.add(
          GateIssue(
            code: 'scene_not_empty',
            severity: GateSeverity.error,
            locator: asset.name,
            message: '${asset.type}提示词没有空景表述（empty scene / no people / '
                '无人物），图像模型会自动补人',
          ),
        );
      }
      if (asset.type == '道具') {
        if (!_containsAny(prompt, noHandMarkers)) {
          issues.add(
            GateIssue(
              code: 'prop_has_hand',
              severity: GateSeverity.error,
              locator: asset.name,
              message: '道具提示词没有显式排除手部——最常见的污染是一只握着道具的手',
            ),
          );
        }
      }
    }
    return issues;
  }

  /// 场景提示词出现角色名门。[characterNames] 为空时不检查。
  static List<GateIssue> namedCharactersInScene({
    required List<Asset> assets,
    required List<String> characterNames,
  }) {
    if (characterNames.isEmpty) return const [];
    final names = characterNames
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    final issues = <GateIssue>[];
    for (final asset in assets) {
      if (asset.type != '场景') continue;
      final prompt = asset.prompt;
      for (final name in names) {
        if (prompt.contains(name) && !_inNegation(prompt, name)) {
          issues.add(
            GateIssue(
              code: 'scene_named_character',
              severity: GateSeverity.warn,
              locator: asset.name,
              message: '场景提示词出现角色名「$name」，图像模型会把它认出来的东西画进去',
            ),
          );
          break;
        }
      }
    }
    return issues;
  }

  /// 术语是否处在否定语境里：命中时跳过告警，避免「不能出现人物」被误判成画人。
  ///
  /// 英文角色名带大写，必须与文本同步转小写再比对，否则 `indexOf` 匹配不上、
  /// 否定检测被跳过，英文名角色在场景提示词里 100% 误报。
  static bool _inNegation(String text, String term) {
    const negators = [
      '不能出现', '不要出现', '不出现', '避免出现', '避免', '禁止', '不能',
      '不要', '没有', '不含', '排除', '不画', 'no', 'without', 'never', 'not ',
    ];
    final lowered = text.toLowerCase();
    final loweredTerm = term.toLowerCase();
    var index = lowered.indexOf(loweredTerm);
    while (index >= 0) {
      final start = index > 4 ? index - 4 : 0;
      final window = lowered.substring(start, index);
      if (negators.any(window.contains)) return true;
      index = lowered.indexOf(loweredTerm, index + loweredTerm.length);
    }
    return false;
  }

  /// 画风族：互斥族同时出现说明风格没确认。
  ///
  /// 关键词必须覆盖 `ArtStyleCatalog` 每条风格的提示词（含其中夹带的英文
  /// style token）：画风提示词会被注入每条资产 / 分镜 / 视频提示词，
  /// 负向分句里的跨族词也会命中（族判定不看否定语境），所以风格提示词
  /// 只能出现本族的关键词。
  static const Map<String, List<String>> styleFamilies = {
    '写实': [
      'photorealistic', 'realistic', 'photograph', 'cinematic', 'live-action',
      '真人实拍', '摄影写实', '胶片',
    ],
    '动漫': [
      'anime', 'cel-shading', 'watercolor', 'manga', 'clean line art',
      'soft cel', '手绘', '水彩', '日式 2d 动画', '干净线稿', '柔和上色',
      '国漫', '水墨', '工笔',
    ],
    '三维': [
      '3d render', 'octane', 'blender', '三维渲染', '数字绘画',
      'claymation', '黏土', 'low poly', '低多边形',
    ],
  };

  /// 画风互斥门：同一批提示词里 A 含写实族、B 含动漫族即报警。
  ///
  /// 画风由 `effectiveArtStyle` 统一注入，正常情况全批同族；跨族意味着某个
  /// 资产被单独指定了别的风格。
  static List<GateIssue> styleConflicts(List<Asset> assets) {
    final byFamily = <String, List<String>>{};
    for (final asset in assets) {
      final family = styleFamilyOf(asset.prompt);
      if (family.isEmpty) continue;
      byFamily.putIfAbsent(family, () => []).add(asset.name);
    }
    if (byFamily.length < 2) return const [];
    final locator = byFamily.entries
        .map((e) => '${e.key}(${e.value.join('、')})')
        .join(' / ');
    final families = byFamily.keys.join('、');
    return [
      GateIssue(
        code: 'style_conflict',
        severity: GateSeverity.warn,
        locator: locator,
        message: '同一批资产出现互斥画风族：$families。画风由 effectiveArtStyle '
            '统一注入，跨族说明有资产被单独指定了别的风格，会画出两套视觉体系',
      ),
    ];
  }

  /// 返回 [prompt] 命中的画风族名，未命中返回空串。
  ///
  /// 公开以便词表测试逐条校验画风提示词命中自己声明的族。
  static String styleFamilyOf(String prompt) {
    final lowered = prompt.toLowerCase();
    for (final entry in styleFamilies.entries) {
      if (entry.value.any((term) => _containsAny(lowered, [term]))) {
        return entry.key;
      }
    }
    return '';
  }

  /// 资产提示词全部质量门。
  static List<GateIssue> validate({
    required List<Asset> assets,
    List<String> characterNames = const [],
  }) {
    return [
      ...similarCharacters(assets),
      ...anchorCountGate(assets),
      ...lightingMissing(assets),
      ...emptyScene(assets),
      ...namedCharactersInScene(assets: assets, characterNames: characterNames),
      ...propStates(assets),
      ...propScale(assets),
      ...propWhiteBg(assets),
      ...styleConflicts(assets),
    ];
  }
}
