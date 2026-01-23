# DINQ App 项目文档

> 本文档用于帮助开发者快速了解项目结构，便于后续开发和 AI 协助。

## 📋 项目概述

DINQ App 是一个 **人才展示与发现平台**，核心功能是生成和管理个人展示卡片（DINQ Card），整合多个平台数据（GitHub、LinkedIn、Google Scholar），提供人才搜索和匹配能力。

### 技术栈
- **框架**: Flutter (Dart)
- **状态管理**: Provider + ChangeNotifier
- **路由**: go_router
- **网络请求**: Dio
- **本地存储**: shared_preferences
- **实时通信**: WebSocket

---

## 🏗️ 项目架构

采用分层架构设计：

```
lib/
├── main.dart              # 应用入口
├── app.dart               # 应用根组件，配置 Provider 和路由
├── constants/             # 常量配置
├── models/                # 数据模型
├── pages/                 # 页面/屏幕
├── router/                # 路由配置
├── services/              # API 服务层
├── stores/                # 状态管理
├── theme/                 # 主题配置
├── utils/                 # 工具类
└── widgets/               # 可复用组件
```

---

## 📁 核心目录详解

### 1. 入口文件

| 文件 | 说明 |
|------|------|
| `lib/main.dart` | 应用入口，初始化并启动 DinqApp |
| `lib/app.dart` | 应用根组件，配置 Provider 和路由 |

### 2. 状态管理 (`lib/stores/`)

| 文件 | 说明 |
|------|------|
| `user_store.dart` | 用户状态（登录、个人信息、订阅） |
| `card_store.dart` | 卡片状态（卡片列表、布局、视图模式） |
| `messages_store.dart` | 消息状态（会话、消息列表） |
| `notifications_store.dart` | 通知状态 |
| `search_store.dart` | 搜索状态（标签页、搜索查询） |
| `settings_store.dart` | 设置状态（主题、语言、网格配置） |

### 3. 数据模型 (`lib/models/`)

| 文件 | 模型 | 说明 |
|------|------|------|
| `user_models.dart` | `User` | 基础用户信息（id, email, name） |
| | `UserData` | 用户数据（name, avatarUrl, bio, domain） |
| | `UserProfile` | 用户资料（User + UserData） |
| | `UserFlow` | 用户流程状态 |
| | `Subscription` | 订阅信息（plan, status, credits 等） |
| `card_models.dart` | `CardItem` | 卡片项（id, data, layout） |
| | `CardData` | 卡片数据（type, title, description, metadata） |
| | `CardLayout` | 卡片布局（desktop, mobile） |
| | `CardPosition` | 位置信息（x, y, w, h） |
| | `ViewMode` | 视图模式枚举（desktop, mobile） |

### 4. API 服务层 (`lib/services/`)

| 文件 | 说明 |
|------|------|
| `api_client.dart` | 基于 Dio 的 API 客户端（单例模式、Token 管理、统一错误处理） |
| `auth_service.dart` | 认证服务（登录、注册、验证码、密码重置） |
| `profile_service.dart` | 用户资料服务（获取/更新用户数据、验证） |
| `card_service.dart` | 卡片服务（获取/更新/初始化 Card Board） |
| `datasource_service.dart` | 数据源服务（社交链接、数据源 CRUD） |
| `message_service.dart` | 消息服务（会话管理、WebSocket） |
| `payment_service.dart` | 支付服务（订阅、结账、套餐变更） |
| `flow_service.dart` | 流程服务（用户流程状态、域名检查） |
| `upload_service.dart` | 上传服务（OSS 上传） |
| `waiting_list_service.dart` | 等待列表服务 |
| `top_talents_service.dart` | 顶级人才服务 |
| `contact_request_service.dart` | 联系请求服务 |

### 5. 路由配置 (`lib/router/`)

路由文件：`app_router.dart`

**主要路由表：**

| 路由 | 页面 | 说明 |
|------|------|------|
| `/` `/landing` | LandingPage | 落地页/首页 |
| `/signin` | SigninPage | 登录页 |
| `/signup` | SignupPage | 注册页 |
| `/reset` | ResetPage | 重置密码 |
| `/demo` | DemoPage | 演示页 |
| `/generation` | GenerationPage | 卡片生成 |
| `/pricing` | PricingPage | 定价页 |
| `/blogs` | BlogsPage | 博客列表 |
| `/blogs/:slug` | BlogDetailPage | 博客详情 |
| `/settings/*` | Settings* | 设置相关页面 |
| `/admin/*` | Admin* | 管理后台 |
| `/analysis/*` | Analysis* | 数据分析 |
| `/:username` | ProfilePage | 用户个人资料（动态路由） |

---

## 📱 页面模块

### 认证模块 (`lib/pages/auth/`)
- `signin_page.dart` - 登录页
- `signup_page.dart` - 注册页
- `reset_page.dart` - 重置密码页
- `reset_callback_page.dart` - 重置密码回调页
- `demo_page.dart` - 演示页
- `waiting_list_page.dart` - 等待列表页

### 分析模块 (`lib/pages/analysis/`)
- `analysis_page.dart` - 分析主页
- `github_page.dart` / `github_compare_page.dart` - GitHub 分析
- `linkedin_page.dart` / `linkedin_compare_page.dart` - LinkedIn 分析
- `scholar_page.dart` / `scholar_compare_page.dart` - Google Scholar 分析

### 设置模块 (`lib/pages/settings/`)
- `settings_page.dart` - 设置主页
- `settings_profile_page.dart` - 个人资料设置
- `settings_account_page.dart` - 账号设置
- `settings_verification_page.dart` - 验证设置
- `settings_dinqcard_page.dart` - DINQ Card 设置
- `settings_subscription_page.dart` - 订阅设置

### 管理后台 (`lib/pages/admin/`)
- `admin_page.dart` - 管理主页
- `admin_mydinq_page.dart` - 我的 DINQ 管理
- `admin_search_page.dart` - 搜索管理
- `admin_openings_page.dart` - 职位管理
- `admin_inbox_page.dart` - 收件箱
- `admin_inbox_conversation_page.dart` - 会话详情
- `admin_inbox_notifications_page.dart` - 通知页

### 营销模块 (`lib/pages/marketing/`)
- `blogs_page.dart` / `blog_detail_page.dart` - 博客
- `pricing_page.dart` - 定价页
- `terms_page.dart` / `privacy_page.dart` / `guidelines_page.dart` / `cookies_page.dart` - 法律条款

---

## 🎨 组件 (`lib/widgets/`)

| 目录/文件 | 说明 |
|-----------|------|
| `widgets/cards/` | 卡片相关组件 |
| `widgets/common/` | 通用组件（AssetIcon, Badge, BasePage, DefaultAppBar, LottieView） |
| `widgets/landing/` | 落地页组件 |
| `widgets/layout/` | 布局组件（AppHeader, AppFooter） |
| `widgets/logo.dart` | Logo 组件 |

---

## 🔧 工具类 (`lib/utils/`)

| 文件 | 说明 |
|------|------|
| `asset_path.dart` | 资源路径工具 |
| `color_util.dart` | 颜色工具 |
| `toast_util.dart` | Toast 提示工具 |

---

## ⚙️ 配置文件 (`lib/constants/`)

| 文件 | 说明 |
|------|------|
| `app_constants.dart` | 应用常量配置 |
| `blogs.dart` | 博客元数据 |
| `landing.dart` | 落地页内容配置 |

**API 配置（app_constants.dart）：**
- Gateway URL: `https://api.dinq.me`
- App URL: `http://dinq.me`

---

## 🎯 业务模块

### 1. 用户认证与授权
登录/注册、密码重置、邮箱验证、社交登录、账号激活

### 2. 用户资料管理
个人资料编辑、头像/简介、域名设置、账号绑定/解绑

### 3. DINQ Card 系统（核心功能）
卡片生成、布局管理、数据源集成、卡片渲染、桌面/移动视图切换

### 4. 数据源集成
GitHub、LinkedIn、Google Scholar、简历上传、数据同步、卡片重新生成

### 5. 分析与对比
GitHub/LinkedIn/Scholar 分析、多平台对比、数据可视化

### 6. 验证系统
职业验证、教育验证、社交账号验证、验证状态管理

### 7. 消息与通知
私信、会话管理、通知中心、WebSocket 实时通信

### 8. 支付与订阅
套餐管理、支付集成（Airwallex）、订阅状态、积分系统

### 9. 搜索与发现
人才搜索、多标签页管理、搜索结果展示

### 10. 管理后台
用户管理、内容审核、职位管理、收件箱管理

---

## 📦 主要依赖

```yaml
dependencies:
  dio: ^5.7.0                          # HTTP 客户端
  go_router: ^14.6.1                   # 路由管理
  provider: ^6.1.2                     # 状态管理
  shared_preferences: ^2.3.2           # 本地存储
  cached_network_image: ^3.4.1         # 图片缓存
  flutter_svg: ^2.0.10+1               # SVG 支持
  flutter_markdown: ^0.7.4             # Markdown 渲染
  flutter_staggered_grid_view: ^0.7.0  # 瀑布流网格
  lottie: ^3.1.3                       # Lottie 动画
  file_picker: ^8.1.7                  # 文件选择
  url_launcher: ^6.3.1                 # URL 启动
  web_socket_channel: ^3.0.3           # WebSocket 支持
  toastification: ^1.0.0               # Toast 提示
  uuid: ^4.5.1                         # UUID 生成
  intl: ^0.19.0                        # 国际化
```

---

## 🔑 开发要点

### API 客户端使用
```dart
// 所有 API 请求通过 ApiClient 单例进行
final response = await ApiClient.instance.get('/endpoint');
final response = await ApiClient.instance.post('/endpoint', data: {...});
```

### 状态管理使用
```dart
// 读取状态
final userStore = context.read<UserStore>();
final user = context.watch<UserStore>().user;

// 更新状态
userStore.setUser(user);
```

### 路由导航
```dart
// 跳转页面
context.go('/path');
context.push('/path');

// 带参数跳转
context.go('/profile/$username');
```

---

## 📝 开发建议

1. **新增页面**：在 `lib/pages/` 对应模块目录下创建，并在 `lib/router/app_router.dart` 中添加路由
2. **新增 API**：在 `lib/services/` 中对应的 service 文件中添加方法
3. **新增状态**：在 `lib/stores/` 中创建新的 Store，并在 `lib/app.dart` 中注册 Provider
4. **新增模型**：在 `lib/models/` 中创建对应的模型类
5. **新增组件**：在 `lib/widgets/` 对应目录下创建可复用组件

---

## 📂 资源文件

- `assets/` - 静态资源目录
  - 130+ SVG 图标
  - 61 PNG 图片
  - Markdown 文档

---

*文档生成时间：2026-01-23*
