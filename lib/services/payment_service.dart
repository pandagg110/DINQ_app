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

  /// Pay-as-you-go 设置（enabled/status/has_payment_method/monthly_limit_cents 等，
  /// 对齐 web paymentApi.getPayg）
  /// 需要认证
  Future<Map<String, dynamic>> getPayg() async {
    final response = await _dio.get('/payment/payg');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 发起 Pay-as-you-go 绑卡（返回 Stripe 收银台 url，对齐 web setupPayg）
  /// 需要认证
  Future<Map<String, dynamic>> setupPayg({required int monthlyLimitCents}) async {
    final response = await _dio.post(
      '/payment/payg/setup',
      data: {'monthly_limit_cents': monthlyLimitCents},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 更新 Pay-as-you-go 开关/月度上限（对齐 web updatePayg）
  /// 需要认证
  Future<Map<String, dynamic>> updatePayg({
    required bool enabled,
    required int monthlyLimitCents,
  }) async {
    final response = await _dio.post(
      '/payment/payg',
      data: {'enabled': enabled, 'monthly_limit_cents': monthlyLimitCents},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 积分流水列表（分页，Credits 页 Usage tab；对齐 web getCreditTransactions）
  /// 需要认证
  Future<Map<String, dynamic>> getCreditTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/payment/credit-transactions',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 支付订单列表（分页，Credits 页 Billing tab；对齐 web getOrders）
  /// 需要认证
  Future<Map<String, dynamic>> getOrders({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      '/payment/orders',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}


