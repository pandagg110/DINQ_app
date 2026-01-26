import 'package:shared_preferences/shared_preferences.dart';

import '../../network/http_urls.dart';

/// 缓存
class CacheManager {
  static CacheManager? _instance;

  static CacheManager get instance => _getInstance();

  CacheManager._internal();

  factory CacheManager() => _getInstance();

  static _getInstance() {
    _instance ??= CacheManager._internal();
    return _instance;
  }

  static SharedPreferences? preferences;

  static Future<SharedPreferences> getSharedPreferences() async {
    preferences ??= await SharedPreferences.getInstance();
    return preferences!;
  }

  /// Api 环境
  HttpEnv? _httpEnv;

  /// Api 环境
  HttpEnv? get httpEnv {
    if (_httpEnv != null) {
      return _httpEnv;
    }
    return HttpEnvEx.init(preferences?.getInt("api_env_key"));
  }

  /// Api 环境
  set httpEnv(HttpEnv? httpEnv) {
    _httpEnv = httpEnv;
    if (httpEnv != null) {
      preferences?.setInt("api_env_key", httpEnv.rawValue);
    } else {
      preferences?.remove("api_env_key");
    }
  }

  /// debug 抓包代理
  String? proxy;

  /// 是否同意隐私协议
  set agreePrivacy(bool value) {
    CacheManager.preferences?.setBool('agree_privacy_status_key', value);
  }

  bool get agreePrivacy {
    bool res = CacheManager.preferences?.getBool('agree_privacy_status_key') ?? false;
    return res;
  }

  /// 注册的账号，首次登录时需要弹出弹框
  String? signUpAccount;
}
