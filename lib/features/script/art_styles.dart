/// 画面风格的可选词表（单一来源）。
///
/// 风格是**选择**而不是自由文本：每条由短名 [ArtStyle.name] 与完整提示词
/// [ArtStyle.prompt] 组成。库里只存短名（默认值存 null），完整提示词由
/// `script_models.dart` 的 `effectiveArtStyle` 按名解析——这样改词表即自动
/// 影响存量剧本，且不用在库里重复存同一段长文本。
///
/// 族关键词必须与 `PromptGate.styleFamilies` 同步：画风提示词会被注入每一
/// 条资产 / 分镜 / 视频提示词，跨族关键词混入负向分句会让画风互斥门误判
/// （族判定按「写实 → 动漫 → 三维」顺序首个命中即返回，负向里的
/// 「不要胶片颗粒」也会被当成写实族）。
library;

/// 一条可选画面风格。
class ArtStyle {
  const ArtStyle({
    required this.name,
    required this.family,
    required this.prompt,
  });

  /// UI 展示与入库的短名。
  final String name;

  /// 所属画风族（写实 / 动漫 / 三维），与 `PromptGate.styleFamilies` 键一致。
  final String family;

  /// 注入资产 / 分镜 / 视频提示词的完整风格描述。
  final String prompt;
}

abstract final class ArtStyleCatalog {
  ArtStyleCatalog._();

  /// 默认画风的短名（入库值）。
  static const String defaultName = '日式 2D 动画';

  /// 默认画风的完整提示词——风格提示词的唯一字面量来源。
  static const String defaultPrompt =
      '日式 2D 动画风格：干净线稿，柔和上色，'
      '赛璐璐平涂为主，色块边缘清晰；光影只用简单的高光与阴影分层，'
      '不做体积光；色彩明快饱和，天空与阴影偏冷蓝，皮肤保留暖调；'
      '人物比例修长、五官简化精致，表情有弹性；背景为插画式透视、'
      '细节密度中等。避免照片质感、避免厚重油画笔触。';

  /// 默认画风。
  static const ArtStyle defaultStyle = ArtStyle(
    name: defaultName,
    family: '动漫',
    prompt: defaultPrompt,
  );

  /// 词表化之前库里存的默认风格字面量。
  ///
  /// 旧编辑器的「恢复默认」把这句短文案原样写进库，所以这批剧本存的是
  /// 提示词而不是风格名；按「未设置」处理，让默认画风升级成下面的完整
  /// 描述后这批剧本也跟着用新文案。
  static const String legacyDefaultPrompt = '日式 2D 动画，干净线稿，柔和上色';

  /// 库里未设置或存的是历史默认文案。
  static bool isDefaultOrEmpty(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty || trimmed == legacyDefaultPrompt;
  }

  /// 动漫族。
  static const List<ArtStyle> anime = [
    defaultStyle,
    cn2d,
    americanComic,
    inkWash,
    watercolorBook,
    cyberNeon,
    retro80s,
    gongbi,
  ];

  /// 写实族。
  static const List<ArtStyle> realistic = [
    filmReal,
    vintageFilm,
    documentary,
    darkThriller,
  ];

  /// 三维族。
  static const List<ArtStyle> threeDimensional = [
    pixar3d,
    realistic3d,
    clayStop,
    lowPoly,
  ];

  /// 全部风格（按族顺序铺开）。
  static const List<ArtStyle> styles = [
    ...anime,
    ...realistic,
    ...threeDimensional,
  ];

  /// 按族分组的视图，插入顺序即 UI 展示顺序。
  static const Map<String, List<ArtStyle>> grouped = {
    '动漫': anime,
    '写实': realistic,
    '三维': threeDimensional,
  };

  /// 短名 → 风格；未登记返回 null。
  static ArtStyle? byName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    for (final style in styles) {
      if (style.name == trimmed) return style;
    }
    return null;
  }

  /// 短名对应的完整提示词；未登记返回 null。
  static String? promptOf(String? name) => byName(name)?.prompt;

  static const ArtStyle cn2d = ArtStyle(
    name: '国漫 2D 动画',
    family: '动漫',
    prompt:
        '国漫 2D 动画风格：干净线稿，柔和上色，线宽有主次变化；人物五官修长俊美，'
        '发丝呈束状高光，衣纹流畅；色彩浓郁饱和、主色对比强，背景厚涂加光影分层，'
        '场景细节密度高；构图大气，常用斜角与纵深透视。避免照片质感、避免 3D 塑料感。',
  );

  static const ArtStyle americanComic = ArtStyle(
    name: '美式漫画',
    family: '动漫',
    prompt:
        '美式漫画风格：粗黑墨线手绘勾边，交叉排线阴影，半调网点；色块饱和对比强烈，'
        '人物肌肉与透视夸张，常用低角度仰视与动态对角线构图；背景简略，靠线条与色块'
        '表现体积。避免柔焦晕染、避免 3D 塑料感。',
  );

  static const ArtStyle inkWash = ArtStyle(
    name: '水墨国风',
    family: '动漫',
    prompt:
        '水墨国风风格：宣纸底纹上的水墨晕染，墨分五色，笔触飞白，留白讲究；'
        '线条以书法笔意为主，人物衣纹简练，背景为山水皴法与淡彩渲染；色调以墨黑为主，'
        '朱砂与石青点缀。避免厚涂上色、避免 3D 塑料感。',
  );

  static const ArtStyle watercolorBook = ArtStyle(
    name: '水彩绘本',
    family: '动漫',
    prompt:
        '水彩绘本风格：湿画法晕染，水痕边缘自然，色彩透明柔和，留白处透出纸纹；'
        '线稿纤细若隐若现，阴影用湿色叠染而非排线；整体明亮通透，适合温馨日常场景。'
        '避免粗黑墨线、避免 3D 塑料感。',
  );

  static const ArtStyle cyberNeon = ArtStyle(
    name: '赛博霓虹',
    family: '动漫',
    prompt:
        '赛博霓虹风格：cel-shading 平涂，霓虹高光勾边，夜色为主，青色与品红强对比；'
        '雨夜街景、全息广告牌、机械义体细节丰富；阴影浓重、明暗对比强烈，人物剪影清晰。'
        '避免暖黄日光基调、避免灰蒙雾感。',
  );

  static const ArtStyle retro80s = ArtStyle(
    name: '复古 80 年代动画',
    family: '动漫',
    prompt:
        '复古 80 年代动画风格：anime 手绘赛璐璐，色数有限、色块分明，高光呈硬边条状；'
        '色彩偏粉紫与橙黄的霓虹渐变，带噪点与扫描线质感；人物大眼、腮红明显，'
        '背景多为扁平几何构图。避免 3D 塑料感、避免现代高清锐利。',
  );

  static const ArtStyle gongbi = ArtStyle(
    name: '国风工笔',
    family: '动漫',
    prompt:
        '国风工笔风格：工笔重彩手绘，双钩细线勾勒，矿物颜料层层罩染，色彩沉稳华贵；'
        '人物发饰衣纹装饰繁复，纹样对称工整，背景以青绿山水与金色勾边点缀；'
        '线条精度极高，几乎无明暗体积光。避免厚涂上色、避免 3D 塑料感。',
  );

  static const ArtStyle filmReal = ArtStyle(
    name: '电影写实',
    family: '写实',
    prompt:
        '电影写实风格：photorealistic，真人实拍质感，电影镜头光学特性，浅景深与'
        '变形宽荧幕比例；布光为三点布光加环境反射，皮肤纹理与毛孔可见；色调偏青橙对比，'
        '画面有轻微颗粒与镜头光晕。避免卡通化线条、避免平涂色块。',
  );

  static const ArtStyle vintageFilm = ArtStyle(
    name: '复古胶片',
    family: '写实',
    prompt:
        '复古胶片风格：70 年代胶片摄影质感，颗粒粗大可见，色彩偏橙黄与暗绿，'
        '高光溢出成柔光晕；低对比、暗部偏灰，边缘轻微暗角；画面有轻微色差与光斑，'
        '情绪怀旧。避免数码锐利、避免平涂色块。',
  );

  static const ArtStyle documentary = ArtStyle(
    name: '纪实摄影',
    family: '写实',
    prompt:
        '纪实摄影风格：documentary photograph，手持纪实，自然光为主，画面真实不修饰；'
        '景深适中、对焦略松散，构图随意而有生活气息；色调中性偏冷，肤色还原真实。'
        '避免戏剧化布光、避免平涂色块。',
  );

  static const ArtStyle darkThriller = ArtStyle(
    name: '暗黑悬疑',
    family: '写实',
    prompt:
        '暗黑悬疑风格：cinematic 低照度布光，大面积阴影，单一光源侧逆光；'
        '色调以墨蓝、铁灰与血红为主，画面颗粒与轻微雾气，细节藏在暗部；气氛压抑克制，'
        '构图常用框架式遮挡。避免明亮高调、避免平涂色块。',
  );

  static const ArtStyle pixar3d = ArtStyle(
    name: '皮克斯式 3D',
    family: '三维',
    prompt:
        '皮克斯式三维风格：octane render 柔和全局光照，皮肤与布料有次表面散射，'
        '材质细腻有物理感；卡通化比例、大眼睛，动作夸张富有弹性；色彩明快饱和，'
        '景深与镜头光晕营造氛围。避免 2D 扁平色块、避免粗黑墨线。',
  );

  static const ArtStyle realistic3d = ArtStyle(
    name: '写实 3D 渲染',
    family: '三维',
    prompt:
        '写实 3D 风格：blender 三维渲染，PBR 材质，皮肤与金属有真实反射与粗糙度'
        '变化；全局光照物理准确，阴影柔和过渡；人物皮肤纹理与衣物褶皱精细，'
        '镜头有真实景深与色散。避免卡通比例、避免平涂色块。',
  );

  static const ArtStyle clayStop = ArtStyle(
    name: '黏土定格',
    family: '三维',
    prompt:
        '黏土定格风格：claymation 质感，材质表面有指纹与黏土颗粒，边缘圆润软糯；'
        '光线为柔光棚灯，阴影柔和，画面有轻微抖动与定格步幅感；色彩饱和温暖，'
        '像儿童手作玩具。避免数字光滑、避免 2D 扁平上色。',
  );

  static const ArtStyle lowPoly = ArtStyle(
    name: '低多边形',
    family: '三维',
    prompt:
        '低多边形风格：low poly，硬朗几何面片构成形体，硬边着色，无平滑曲面；'
        '色彩为纯色块分面，光影用阶梯状色阶表现；整体极简、轮廓分明，'
        '适合图标化与风格化场景。避免厚重笔触、避免平涂渐变。',
  );
}
