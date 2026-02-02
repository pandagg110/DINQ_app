import '../utils/cache_manager.dart';

enum HttpEnv { release, staging }

extension HttpEnvEx on HttpEnv {
  int get rawValue {
    switch (this) {
      case HttpEnv.release:
        return 0;
      case HttpEnv.staging:
        return 1;
    }
  }

  static HttpEnv? init(int? value) {
    switch (value) {
      case 0:
        return HttpEnv.release;
      case 1:
        return HttpEnv.staging;
      default:
        return null;
    }
  }
}

class HttpUrls {
  HttpUrls._();

  static HttpEnv _httpEnv = HttpEnv.release;

  static set httpEnv(HttpEnv env) {
    _httpEnv = env;
  }

  static HttpEnv get httpEnv {
    return CacheManager.instance.httpEnv ?? _httpEnv;
  }

  static String get baseHost {
    switch (HttpUrls.httpEnv) {
      case HttpEnv.release:
        return "";
      case HttpEnv.staging:
        return "";
    }
  }

  static String get baseApiHost {
    switch (HttpUrls.httpEnv) {
      case HttpEnv.release:
        return "";
      case HttpEnv.staging:
        return "";
    }
  }

  static String get wsHost {
    switch (HttpUrls.httpEnv) {
      case HttpEnv.release:
        return "wss://wss.rwabd.com";
      case HttpEnv.staging:
        return "wss://test-socket.moveft.com";
    }
  }

  static String get h5Host {
    switch (HttpUrls.httpEnv) {
      case HttpEnv.release:
        return "";
      case HttpEnv.staging:
        return "";
    }
  }
}

// MARK: - Common

class CommonURLs {}
