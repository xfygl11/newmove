import '../../agent/active_image.dart';
import '../../agent/active_llm.dart';
import '../../agent/active_video.dart';
import '../../core/network/protocols.dart';
import '../../core/storage/secure_key_store.dart';
import '../../data/app_database.dart';
import '../../data/daos/agent_binding_dao.dart';
import '../../data/daos/provider_dao.dart';
import 'provider_models.dart';

/// 项目 × Agent 绑定服务（M34）。
///
/// 解析某项目某类别的有效供应商：优先用绑定，回落全局 ActiveX。
class AgentBindingService {
  final AgentBindingDao _bindingDao;
  final ProviderDao _providerDao;
  final SecureKeyStore _keyStore;

  AgentBindingService({
    required this._bindingDao,
    required this._providerDao,
    required this._keyStore,
  });

  /// 某项目的 LLM 供应商（绑定 > 全局）。
  Future<ActiveLlm?> resolveLlm({int? projectId}) async {
    if (projectId != null) {
      final binding = await _bindingDao.findByProjectAndCategory(
        projectId,
        'llm',
      );
      if (binding != null) {
        return _resolveLlmById(binding.agentId);
      }
    }
    return _resolveGlobalLlm();
  }

  /// 某项目的图片供应商（绑定 > 全局）。
  Future<ActiveImage?> resolveImage({int? projectId}) async {
    if (projectId != null) {
      final binding = await _bindingDao.findByProjectAndCategory(
        projectId,
        'image',
      );
      if (binding != null) {
        return _resolveImageById(binding.agentId);
      }
    }
    return _resolveGlobalImage();
  }

  /// 某项目的视频供应商（绑定 > 全局）。
  Future<ActiveVideo?> resolveVideo({int? projectId}) async {
    if (projectId != null) {
      final binding = await _bindingDao.findByProjectAndCategory(
        projectId,
        'video',
      );
      if (binding != null) {
        return _resolveVideoById(binding.agentId);
      }
    }
    return _resolveGlobalVideo();
  }

  /// 获取项目的全部绑定。
  Future<List<AgentBinding>> listBindings(int projectId) {
    return _bindingDao.listByProject(projectId);
  }

  /// 创建绑定。
  Future<int> createBinding({
    required int projectId,
    required String category,
    required String agentId,
  }) {
    return _bindingDao.insertBinding(
      projectId: projectId,
      category: category,
      agentId: agentId,
    );
  }

  /// 更新绑定。
  Future<void> updateBinding(int id, String agentId) {
    return _bindingDao.updateBinding(id, agentId);
  }

  /// 删除绑定。
  Future<void> deleteBinding(int id) {
    return _bindingDao.deleteBinding(id);
  }

  /// 删除项目的所有绑定。
  Future<void> deleteByProject(int projectId) {
    return _bindingDao.deleteByProject(projectId);
  }

  Future<ActiveLlm?> _resolveGlobalLlm() async {
    final providers = await _providerDao.listByGroup('llm');
    for (final p in providers) {
      if (!Protocols.isSupported('llm', p.protocol)) continue;
      final key = await _keyStore.readKey(p.id);
      final models = ProviderModelCodec.decode(p.models)
          .where((m) => m.enabled)
          .toList();
      if (key != null && key.isNotEmpty && models.isNotEmpty) {
        return ActiveLlm(provider: p, apiKey: key, model: models.first);
      }
    }
    return null;
  }

  Future<ActiveImage?> _resolveGlobalImage() async {
    final providers = await _providerDao.listByGroup('image');
    for (final p in providers) {
      if (!Protocols.isSupported('image', p.protocol)) continue;
      final key = await _keyStore.readKey(p.id);
      final models = ProviderModelCodec.decode(p.models)
          .where((m) => m.enabled)
          .toList();
      if (key != null && key.isNotEmpty && models.isNotEmpty) {
        return ActiveImage(provider: p, apiKey: key, model: models.first);
      }
    }
    return null;
  }

  Future<ActiveVideo?> _resolveGlobalVideo() async {
    final providers = await _providerDao.listByGroup('video');
    for (final p in providers) {
      if (!Protocols.isSupported('video', p.protocol)) continue;
      final key = await _keyStore.readKey(p.id);
      final models = ProviderModelCodec.decode(p.models)
          .where((m) => m.enabled)
          .toList();
      if (key != null && key.isNotEmpty && models.isNotEmpty) {
        return ActiveVideo(provider: p, apiKey: key, model: models.first);
      }
    }
    return null;
  }

  Future<ActiveLlm?> _resolveLlmById(String providerId) async {
    final providers = await _providerDao.listByGroup('llm');
    ProviderConfig? p;
    for (final candidate in providers) {
      if (candidate.id == providerId) {
        p = candidate;
        break;
      }
    }
    if (p == null) return null;
    if (!Protocols.isSupported('llm', p.protocol)) return null;
    final key = await _keyStore.readKey(p.id);
    final models = ProviderModelCodec.decode(p.models)
        .where((m) => m.enabled)
        .toList();
    if (key == null || key.isEmpty || models.isEmpty) return null;
    return ActiveLlm(provider: p, apiKey: key, model: models.first);
  }

  Future<ActiveImage?> _resolveImageById(String providerId) async {
    final providers = await _providerDao.listByGroup('image');
    ProviderConfig? p;
    for (final candidate in providers) {
      if (candidate.id == providerId) {
        p = candidate;
        break;
      }
    }
    if (p == null) return null;
    if (!Protocols.isSupported('image', p.protocol)) return null;
    final key = await _keyStore.readKey(p.id);
    final models = ProviderModelCodec.decode(p.models)
        .where((m) => m.enabled)
        .toList();
    if (key == null || key.isEmpty || models.isEmpty) return null;
    return ActiveImage(provider: p, apiKey: key, model: models.first);
  }

  Future<ActiveVideo?> _resolveVideoById(String providerId) async {
    final providers = await _providerDao.listByGroup('video');
    ProviderConfig? p;
    for (final candidate in providers) {
      if (candidate.id == providerId) {
        p = candidate;
        break;
      }
    }
    if (p == null) return null;
    if (!Protocols.isSupported('video', p.protocol)) return null;
    final key = await _keyStore.readKey(p.id);
    final models = ProviderModelCodec.decode(p.models)
        .where((m) => m.enabled)
        .toList();
    if (key == null || key.isEmpty || models.isEmpty) return null;
    return ActiveVideo(provider: p, apiKey: key, model: models.first);
  }
}
