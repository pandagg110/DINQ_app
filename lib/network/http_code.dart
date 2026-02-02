enum HttpCode {
  success,
  tokenError,
  paramError,
  connectTimeout,
  sendTimeout,
  receiveTimeout,
  cancel,
  networkError,
  serverError,
  other,
}

extension HttpCodeEx on HttpCode {
  static HttpCode getTypeValue(int number) {
    switch (number) {
      case 0:
        return HttpCode.success;
      case 10003:
        return HttpCode.tokenError;
      case 10005:
        return HttpCode.paramError;
      case -991:
        return HttpCode.connectTimeout;
      case -992:
        return HttpCode.sendTimeout;
      case -993:
        return HttpCode.receiveTimeout;
      case -994:
        return HttpCode.cancel;
      case -995:
        return HttpCode.networkError;
      case -996:
        return HttpCode.serverError;
      case -990:
        return HttpCode.other;
    }
    return HttpCode.other;
  }

  static int rawValue(HttpCode code) {
    switch (code) {
      case HttpCode.success:
        return 0;
      case HttpCode.tokenError:
        return 10003;
      case HttpCode.paramError:
        return 10005;
      case HttpCode.connectTimeout:
        return -991;
      case HttpCode.sendTimeout:
        return -992;
      case HttpCode.receiveTimeout:
        return -993;
      case HttpCode.cancel:
        return -994;
      case HttpCode.networkError:
        return -995;
      case HttpCode.serverError:
        return -996;
      case HttpCode.other:
        return -990;
    }
  }

  static String desc(HttpCode code) {
    switch (code) {
      case HttpCode.success:
        return "success";
      case HttpCode.tokenError:
        return "tokenError";
      case HttpCode.paramError:
        return "paramError";
      case HttpCode.connectTimeout:
        return "connectTimeout";
      case HttpCode.sendTimeout:
        return "sendTimeout";
      case HttpCode.receiveTimeout:
        return "receiveTimeout";
      case HttpCode.cancel:
        return "cancel";
      case HttpCode.networkError:
        return "networkError";
      case HttpCode.serverError:
        return "serverError";
      case HttpCode.other:
        return "other";
    }
  }
}
