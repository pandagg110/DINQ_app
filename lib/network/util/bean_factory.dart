class BeanFactory {
  /// json解析
  static T parseObject<T>(dynamic jsonData) {
    switch (T) {
      case const (Map):
        return jsonData as T;
    }
    return jsonData as T;
  }
}
