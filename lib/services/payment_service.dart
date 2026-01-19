import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class PaymentService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Subscription> getSubscription() async {
    final response = await _dio.get('/payment/subscription');
    return Subscription.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}


