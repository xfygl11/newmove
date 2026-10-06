/// 创作前「基础设置」的词表与取值边界（单一来源）。
///
/// 词表是作品创作入口的固定枚举，不含用户自定义项——自定义项在运行时
/// 由 UI 追加到已选列表，不落在这里。章节规划的边界与预计总章数计算
/// 也集中在此，避免 UI 各处写死 10 / 50 / 5。
library;

class NovelSetupCatalog {
  NovelSetupCatalog._();

  /// 作品形式（与题材类型区分）：决定结构与篇幅的组织方式。
  static const List<String> workForms = ['长篇', '短篇', '剧本', '影游'];

  static const String defaultWorkForm = '长篇';

  /// 核心受众。
  static const List<String> audiences = ['男频', '女频', '全性别'];

  /// 作品类型：一级分类 → 二级类型。
  static const Map<String, List<String>> workGenreGroups = {
    '玄幻': [
      '东方玄幻',
      '王朝争霸',
      '异世大陆',
      '异术超能',
      '远古神话',
      '转世重生',
      '西方玄幻',
    ],
    '奇幻': [
      '西方奇幻',
      '史诗奇幻',
      '剑与魔法',
      '异界冒险',
      '末日奇幻',
      '奇幻校园',
      '异族入侵',
      '神话传说',
      '暗黑奇幻',
    ],
    '仙侠': [
      '修真升级',
      '古典仙侠',
      '仙侠言情',
      '仙侠玄幻',
      '洪荒流',
      '神话仙侠',
      '仙侠探险',
      '仙侠门派',
      '现代仙侠',
    ],
    '都市': [
      '都市言情',
      '总裁豪门',
      '职场风云',
      '都市重生',
      '都市异能',
      '商战博弈',
      '娱乐圈',
      '校园青春',
      '都市婚姻',
    ],
    '历史': [
      '架空历史',
      '穿越古代',
      '古代言情',
      '宫斗权谋',
      '历史军事',
      '古代江湖',
      '古代商战',
      '古代种田',
    ],
    '军事': [
      '抗战烽火',
      '现代军旅',
      '谍战风云',
      '特种兵王',
      '战争史诗',
      '军事科幻',
      '军旅言情',
    ],
    '游戏': [
      '游戏异界',
      '电竞风云',
      '游戏系统',
      '无限流',
      '网游江湖',
      '游戏穿越',
      '游戏竞技',
    ],
    '科幻': [
      '末世废土',
      '星际文明',
      '赛博朋克',
      '时空穿梭',
      '机甲战士',
      '太空歌剧',
      '外星文明',
      '人工智能',
      '时间旅行',
    ],
    '悬疑': [
      '刑侦推理',
      '心理悬疑',
      '灵异怪谈',
      '盗墓探险',
      '恐怖惊悚',
      '罪案实录',
      '规则怪谈',
      '民俗灵异',
      '无限流',
    ],
    '言情': [
      '现代言情',
      '古代言情',
      '校园言情',
      '总裁言情',
      '玄幻言情',
      '仙侠言情',
      '悬疑言情',
      '军旅言情',
      '穿越言情',
    ],
  };

  /// 全部二级类型（扁平且去重，「无限流」同时属于游戏与悬疑）。
  static final List<String> workGenreAll = workGenreGroups.values
      .expand((types) => types)
      .toSet()
      .toList();

  /// 人设标签。
  static const List<String> personaTags = [
    '龙傲天',
    '废材逆袭',
    '反派觉醒',
    '寒门贵子',
    '隐世高手',
    '战神赘婿',
    '江湖老炮',
    '草根崛起',
    '救世主',
  ];

  /// 背景标签。
  static const List<String> backgroundTags = [
    '古代江湖',
    '修真界',
    '玄幻大陆',
    '星际文明',
    '末日废土',
    '民国谍战',
    '西方奇幻',
    '赛博朋克',
    '无限流',
  ];

  /// 人设 / 背景各自独立的标签上限。
  static const int maxTagsPerGroup = 5;

  static const int minVolumes = 1;
  static const int maxVolumes = 20;
  static const int minChaptersPerVolume = 1;
  static const int maxChaptersPerVolume = 50;

  static const int defaultVolumes = 10;
  static const int defaultChaptersPerVolume = 50;

  /// 预计总章节数：两数均有效时才计算，未规划返回 0。
  static int totalChapters(int volumes, int chaptersPerVolume) {
    if (volumes <= 0 || chaptersPerVolume <= 0) return 0;
    return volumes * chaptersPerVolume;
  }
}
