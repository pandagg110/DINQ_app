# 消息推送（FCM / APNs）接入说明

Dart 侧代码已完成（`lib/services/push_service.dart` + 登录/登出/启动钩子 + 聊天跳转）。
推送要在**真机**生效，还需补齐以下**只有项目持有人/后端能提供**的配置。代码对未配置环境做了
安全降级：Web、模拟器、未配置 Firebase 时会静默跳过，**不影响 App 其它功能**。

负责人：@pandagg110（Firebase 项目、证书、后端 `/devices` 接口）

---

## 1. Firebase 项目
在 Firebase 控制台创建/使用 DINQ 项目，添加 Android 与 iOS 两个 App：
- Android 包名：`me.dinq.app`
- iOS Bundle ID：与 `PRODUCT_BUNDLE_IDENTIFIER` 一致

## 2. Android
- 用真实 `google-services.json` **替换** `android/app/google-services.json`
  （当前是占位文件，仅为让构建通过；不替换则收不到推送）。
- gradle 插件已接好（`settings.gradle.kts` + `app/build.gradle.kts` 的
  `com.google.gms.google-services`），无需改动。

## 3. iOS
- 把 `GoogleService-Info.plist` 放进 `ios/Runner/`，并加入 Xcode 工程（Runner target）。
- 在 Xcode → Signing & Capabilities 添加 **Push Notifications** 和
  **Background Modes**（勾选 Remote notifications）。`Info.plist` 的 `UIBackgroundModes`
  已预置。
- 在 Apple Developer 配置 **APNs Key/证书**，并上传到 Firebase 项目设置。

## 4. 后端接口（需确认实际路径/字段）
`push_service.dart` 里目前按约定调用，请后端确认或告知实际契约（已用 TODO 标注）：
- 注册/更新 Token：`POST /api/v1/devices`，body `{ "token": "...", "platform": "ios|android" }`
- 登出解绑：`DELETE /api/v1/devices/{token}`
- 推送 payload 的 `data` 里约定带 `conversation_id`（或 `route`），用于点击通知后跳转。
  当前映射：`conversation_id` → `/admin/inbox/{id}`。

## 5. 已实现的客户端能力（对应 Notion「消息推送」）
- ✅ 设备 Token：注册 / 刷新自动上报 / 登出解绑
- ✅ 权限管理：`requestPermission()`（首登触发）
- ✅ 系统 Push：后台/终止态由 FCM 直接展示
- ✅ 前台展示：`flutter_local_notifications` 自建渠道 `dinq_default`
- ✅ 点击跳转：后台 / 冷启动点击 → go_router 跳对应页
- ⏳ 推送设置（各类开关，P1）：UI 未做，待后端给偏好接口后补

## 6. 真机自测步骤
1. 替换上面两个配置文件，`flutter pub get`。
2. `flutter run --release`（或 debug）到真机，登录测试账号。
3. 确认控制台打出设备 Token 上报成功（无 `[PushService] ... failed`）。
4. 从 Firebase Console「Cloud Messaging」发测试通知，验证：前台弹通知、
   后台系统通知、点击跳转到会话页。
