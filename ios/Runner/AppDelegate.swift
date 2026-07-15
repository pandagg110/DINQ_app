import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Debug 构建内置 Firebase Analytics DebugView 开关：等价于 Xcode 启动参数
    // -FIRDebugEnabled，QA 装 debug 测试包即可在 DebugView 看实时埋点，
    // 无需连 Xcode。必须在 Firebase 初始化（插件注册）之前注入。
    // Release/正式包不含此代码，埋点走正常上报。
    #if DEBUG
    var arguments = ProcessInfo.processInfo.arguments
    if !arguments.contains("-FIRDebugEnabled") {
      arguments.append("-FIRDebugEnabled")
      ProcessInfo.processInfo.setValue(arguments, forKey: "arguments")
    }
    #endif
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
