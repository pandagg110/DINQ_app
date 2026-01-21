import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class PaymentService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取价格信息（展示定价页）
  /// 无需认证
  Future<Map<String, dynamic>> getPricing() async {
    final response = await _dio.get('/payment/pricing');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取当前订阅状态（设置页/用户信息）
  /// 需要认证
  Future<Subscription> getSubscription() async {
    final response = await _dio.get('/payment/subscription');
    return Subscription.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// 新用户订阅（跳转 Airwallex 支付页）
  /// 需要认证
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> data) async {
    final response = await _dio.post('/payment/checkout', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 升级/降级套餐（跳转 Airwallex 支付页）
  /// 需要认证
  Future<Map<String, dynamic>> changePlan(Map<String, dynamic> data) async {
    final response = await _dio.post('/payment/change-plan', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 取消/恢复自动续费
  /// 需要认证
  Future<Map<String, dynamic>> setAutoRenew({required bool autoRenew}) async {
    final response = await _dio.post('/payment/auto-renew', data: {'auto_renew': autoRenew});
    return Map<String, dynamic>.from(response.data as Map);
  }
}


