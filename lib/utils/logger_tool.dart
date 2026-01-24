import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 基于logger库实现的日志工具类
class LoggerTool {
  static final LoggerTool _instance = LoggerTool._internal();

  /// 单例工厂构造函数
  factory LoggerTool() => _instance;

  /// Logger实例
  late Logger _logger;

  /// 是否启用日志
  static bool _isEnabled = true;

  /// 私有构造函数
  LoggerTool._internal() {
    // 设置日志格式和输出选项
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.dateAndTime,
      ),
      filter: kReleaseMode ? ProductionFilter() : DevelopmentFilter(),
      // output: ConsoleOutput(),
      output: MultiOutput([
        // I have a file output here
        DeveloperConsoleOutput(),
      ]),
    );
  }

  /// 设置是否启用日志
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// 打印调试信息
  static void d(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (!_isEnabled) return;
    _instance._logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 打印详细信息
  static void v(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (!_isEnabled) return;
    _instance._logger.v(message, error: error, stackTrace: stackTrace);
  }

  /// 打印信息级别日志
  static void i(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (!_isEnabled) return;
    _instance._logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 打印警告日志
  static void w(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (!_isEnabled) return;
    _instance._logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 打印错误日志
  static void e(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (!_isEnabled) return;
    _instance._logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 打印严重错误
  static void wtf(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    if (!_isEnabled) return;
    _instance._logger.wtf(message, error: error, stackTrace: stackTrace);
  }

  /// 创建自定义配置的Logger实例
  static Logger customLogger({
    LogPrinter? printer,
    LogFilter? filter,
    LogOutput? output,
    Level? level,
  }) {
    return Logger(
      printer: printer ?? PrettyPrinter(),
      filter: filter ?? (_isEnabled ? DevelopmentFilter() : ProductionFilter()),
      output: output ?? ConsoleOutput(),
      level: level,
    );
  }
}

class DeveloperConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    final StringBuffer buffer = StringBuffer();
    event.lines.forEach(buffer.writeln);
    log(buffer.toString());
  }
}
