# Discover 页面迁移说明

## 已迁移的组件

1. **主页面** (`discover_page.dart`)
   - ⚠️ **仅移动端布局**：主聊天区域 + BottomSheet 用户信息面板 + 侧滑聊天历史面板
   - 桌面端布局已移除，只保留移动端样式

2. **子组件** (位于 `lib/widgets/discover/`)
   - `tab_bar_widget.dart` - 标签栏组件（支持普通模式和迷你模式）
   - `user_info_widget.dart` - 用户信息展示组件
   - `chat_history_mobile_widget.dart` - 移动端聊天历史面板（基础结构）
   - `agentic_chat_widget.dart` - 主聊天组件（占位实现）
   - ⚠️ `chat_history_sidebar_widget.dart` - 桌面端组件，已不再使用（但文件保留）

3. **Store 扩展**
   - `SearchStore` - 已扩展支持 `tabClickVersion`, `networkLoading`, `enrichLoading` 等功能
   - `ChatHistoryStore` - 新建，用于管理聊天历史状态

## 需要注释/实现的第三方依赖

### 1. React 第三方库对应关系

#### ✅ 已有对应实现
- **lucide-react** (图标库)
  - Flutter 使用 Material Icons (`Icons.*`) 替代
  - 部分自定义图标需要 SVG 资源文件

- **framer-motion** (动画库)
  - Flutter 使用内置动画组件 (`AnimatedContainer`, `AnimatedSlide` 等) 替代
  - 已使用 `flutter_animate` (pubspec.yaml 中已有)

- **sonner** (Toast 通知)
  - Flutter 使用 `toastification` 或 `flutter_easyloading` (pubspec.yaml 中已有)

#### ⚠️ 需要实现的功能

1. **ahooks 的 useDebounce**
   ```dart
   // 需要实现防抖功能
   // 可以使用 Timer 或第三方包如 `debounce` 包
   // 当前在 ChatHistoryStore 中搜索功能需要防抖
   ```

2. **ahooks 的 useInViewport**
   ```dart
   // 需要实现滚动到底部检测功能
   // 可以使用 ScrollController 监听滚动位置
   // 当前在 ChatHistoryStore 的无限滚动加载中需要
   ```

3. **BottomSheet 组件**
   ```dart
   // React 版本使用了自定义 BottomSheet 组件
   // Flutter 使用 DraggableScrollableSheet 替代
   // 已在 discover_page.dart 中实现基础版本
   ```

### 2. API 调用需要实现

以下 API 调用在代码中已注释，需要根据实际后端 API 实现：

1. **ChatHistoryStore**
   - `discoverApi.getConversations()` - 获取会话列表
   - `discoverApi.getConversationDetail()` - 获取会话详情
   - `discoverApi.updateConversation()` - 更新会话标题
   - `discoverApi.deleteConversation()` - 删除会话

2. **SearchStore / UserInfoWidget**
   - `discoverApi.enrich()` - 丰富用户信息
   - `discoverApi.getProfile()` - 获取用户详细资料
   - `discoverApi.getNetwork()` - 获取用户网络关系

### 3. 需要完善的功能

1. **AgenticChatWidget**
   - 当前只有占位实现
   - 需要实现完整的聊天界面、消息展示、搜索功能等
   - 涉及多个子组件：SearchBox, MessageGroup, PromptTemplateGrid, RecommendedPapers 等

2. **ChatHistoryMobileWidget**
   - 需要添加搜索框（仅 Pro/Plus 用户）
   - 需要添加 New Chat 按钮
   - 需要实现会话列表展示

4. **UserInfoWidget**
   - 需要添加社交链接展示和交互
   - 需要添加 Network 和 Profile 按钮功能
   - 需要添加 Analyze 按钮功能
   - 需要实现 NetworkModal 和 Profile 展开功能

### 4. 图标资源

以下图标需要添加到 `assets/icons/search/` 目录：
- `history.svg` - 历史图标
- `fold.svg` - 折叠图标
- `network.svg` - 网络图标
- `enrich.svg` - 丰富信息图标
- `analyze.svg` - 分析图标
- `lineicons/github.svg` - GitHub 图标
- `lineicons/linkedin.svg` - LinkedIn 图标
- `lineicons/scholar.svg` - Google Scholar 图标
- `lineicons/website.svg` - 网站图标
- `lineicons/huggingface.svg` - HuggingFace 图标

### 5. 样式和主题

- 颜色值已硬编码，建议提取到主题配置中
- 字体大小和间距已按照 React 版本实现
- ⚠️ **仅移动端布局**：已移除桌面端相关代码和响应式判断

## 下一步工作

1. 创建 `discover_service.dart` 实现所有 API 调用
2. 完善 `AgenticChatWidget` 及其子组件
3. 完善 `ChatHistoryMobileWidget`（移动端聊天历史面板）
4. 完善 `UserInfoWidget` 的交互功能
5. 添加缺失的图标资源
6. 实现防抖和滚动检测工具函数
7. 测试移动端布局
