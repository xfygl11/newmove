import 'package:dio/dio.dart';

/// 连接超时基线：15 秒。
///
/// Dio 的 `connectTimeout` 默认为 0，即**禁用**。`sendTimeout` 与
/// `receiveTimeout` 都从握手完成之后才开始计时，弱网半连接（TCP 三次握手
/// 挂住、供应商只建链不回包）下不设这项会让所有请求无限期挂起，移动端
/// 用户没有任何可感知的反馈。
const Duration defaultConnectTimeout = Duration(seconds: 15);

/// 用统一基线创建 Dio 实例。
///
/// 全部网络出口必须经由此函数，禁止直接 `Dio()`——基线散落在每个适配器里
/// 迟早会漏掉新的调用点（`update_checker.dart` 与 `model_fetcher.dart` 就是
/// 两个后来才加的入口，各自重抄了一份 options）。
Dio createDio() {
  return Dio(BaseOptions(connectTimeout: defaultConnectTimeout));
}
