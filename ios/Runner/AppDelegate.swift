import Flutter
import StoreKit
import UIKit
import WebKit

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
    if let controller = window?.rootViewController as? FlutterViewController {
      StoreKitBridge.register(with: controller)
      GitHubOAuthCookieBridge.register(with: controller)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

enum GitHubOAuthCookieBridge {
  static let channelName = "me.dinq.app/github_oauth"

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "clearGitHubCookies":
        clearGitHubCookies(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func clearGitHubCookies(result: @escaping FlutterResult) {
    let cookieStore = WKWebsiteDataStore.default().httpCookieStore
    cookieStore.getAllCookies { cookies in
      let githubCookies = cookies.filter { cookie in
        let domain = cookie.domain.lowercased()
        return domain == "github.com" || domain.hasSuffix(".github.com")
      }
      guard !githubCookies.isEmpty else {
        result(nil)
        return
      }

      let group = DispatchGroup()
      for cookie in githubCookies {
        group.enter()
        cookieStore.delete(cookie) {
          group.leave()
        }
      }
      group.notify(queue: .main) {
        result(nil)
      }
    }
  }
}

enum StoreKitBridge {
  static let channelName = "me.dinq.app/storekit"

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "showManageSubscriptions":
        showManageSubscriptions(result: result)
      case "beginRefundRequest":
        let args = call.arguments as? [String: Any]
        beginRefundRequest(productId: args?["productId"] as? String, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func foregroundScene() -> UIWindowScene? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
  }

  private static func showManageSubscriptions(result: @escaping FlutterResult) {
    guard #available(iOS 15.0, *) else {
      result(FlutterError(code: "unsupported", message: "Requires iOS 15+", details: nil))
      return
    }
    guard let scene = foregroundScene() else {
      result(FlutterError(code: "no_scene", message: "No active window scene", details: nil))
      return
    }
    Task { @MainActor in
      do {
        try await AppStore.showManageSubscriptions(in: scene)
        result(nil)
      } catch {
        result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private static func beginRefundRequest(productId: String?, result: @escaping FlutterResult) {
    guard #available(iOS 15.0, *) else {
      result(FlutterError(code: "unsupported", message: "Requires iOS 15+", details: nil))
      return
    }
    guard let productId, !productId.isEmpty else {
      result(FlutterError(code: "bad_args", message: "productId is required", details: nil))
      return
    }
    guard let scene = foregroundScene() else {
      result(FlutterError(code: "no_scene", message: "No active window scene", details: nil))
      return
    }
    Task { @MainActor in
      do {
        guard let verification = await Transaction.latest(for: productId),
          case .verified(let transaction) = verification
        else {
          result(FlutterError(code: "no_transaction", message: "No verified purchase found", details: nil))
          return
        }
        let status = try await transaction.beginRefundRequest(in: scene)
        switch status {
        case .success: result("success")
        case .userCancelled: result("userCancelled")
        @unknown default: result("unknown")
        }
      } catch {
        result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
      }
    }
  }
}
