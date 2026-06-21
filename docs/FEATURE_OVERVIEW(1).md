# DINQ Client 功能与改动说明

> 截至 2026-06-20。本文档描述当前代码库的主要功能模块与近期改动，按功能维度组织，文中文件路径均可在源码中直接定位。

---

## 0. 总览

近期工作集中在三条主线，外加若干增量功能与修复：

1. **深度搜索升级改版（Deep Search v2.5）** —— 体量最大的功能升级，集中在 `src/app/(authenticated)/(workspace)/search/`。
2. **国际化 i18n（en / zh-CN / zh-TW）** —— 横切整个应用，基于 next-intl。
3. **API Playground 重做** —— 面向开发者的 People Search API 试验台。

其余涉及：候选人补全（enrich）、组织（org）、按量计费（billing/PAYG）、消息（messages）、邀请、设置、营销页等。

---

## 1. 深度搜索升级改版（Deep Search v2.5）— 主线一

涉及目录：`src/app/(authenticated)/(workspace)/search/`、`src/store/deep-search/`、`src/services/websocket.ts`、`src/app/api/proxy/deep-search/`、`src/types/api/deep-search.ts`。这是体量最大的纵向功能（核心文件如 `DeepSearchResults.tsx`、`AgenticChat/index.tsx`、`SubAgentTracker.tsx`）。

### 1.1 新增能力

- **模型通道（Model Channels）**：新增代理路由 `src/app/api/proxy/deep-search/channels/route.ts` 拉取后端可用的「provider/model」组合；配套 hook `search/components/ui/useModelChannels.ts`（本地缓存、5 分钟过期、provider 图标）。SearchBox 中可切换模型，内置 DeepSeek / Claude (Sonnet 4.6) / GLM (5.1) 兜底列表。新增图标 `public/icons/search/glm.svg`。
- **结果侧栏（Result Side Rail）**：`DeepSearchResults.tsx` 支持 `inline | rail | mobile` 三种形态；`EnrichDetailPanel.tsx` 支持 `inline | overlay` 两种展示，并新增 `onRefresh()` 无需关闭即可刷新候选资料。
- **结果分组与「已核验」标记**：引入 `ResultSourceGroup`（带颜色徽标的编号分组）；`CandidateRow` / `DeepSearchResultRecord` 增加可选 `verified` 字段，对未核验结果做视觉区分。
- **结果轮次切换（Result Rounds）**：支持在多轮搜索结果间切换。
- **子代理追踪器（SubAgentTracker）**：新增实时活动行 `SearchActivityLine`，显示当前工具名、参数（query / max_results）、思考块；来源域名标签可弹出 popover 查看该域名下全部 URL。
- **搜索链路 trace**：抽出 `search/components/DeepSearch/traceStatus.ts` 统一工具/思考状态判定与时态文案（gerund/past），并识别隐藏的 ToolSearch 内部调用。

### 1.2 架构与数据流

- **新类型 / 信封**：`DeepSearchChannel`（provider 改为开放字符串）、`DeepSearchTextEnvelope`（`{ type, content, option[] }`，支持把 confirm 块解析成结构化信封）；`DeepSearchRequest.query` 改为可选 → 支持**仅附件搜索**。
- **流式处理优化**（`src/store/deep-search/eventHandlers.ts`）：思考增量 100ms 批量合并（`enqueueThinkingDelta`）、思考文本 12,000 字封顶并滚动淘汰、`syncVirtualAgentCandidateCount()` 保持候选计数与实际行同步；文本经 `normalizeAssistantTextContent()`（`utils/parseQuickReplies.ts`）清洗。
- **信封解析健壮性**：修复嵌套/内联 summary 信封的解析。
- **流关闭**：流结束时自动收尾未闭合的思考/推理块，轮次状态置为 done。
- **WebSocket**：`services/websocket.ts` 新增 `TEAM_RECRUIT_DELETED_EVENT`，团队招募被删除时实时标记消息为撤回。
- **Enrich Store 迁移**：`store/deepSearchEnrichStore.ts` v2→v3 迁移，清理陈旧的邮箱揭示状态，并保存 `requestParams` 供刷新/重试。

### 1.3 UI/UX 重做

- **结果入口卡**：进入 enrich 面板前先展示状态卡（候选数 + 工具数 + 搜索中/已完成区分），点击展开内联结果表或侧栏。
- **结果工作区**：内联结果表新增冻结的选择框列、来源分组徽标列；逐行/逐格交错动画（尊重 `prefers-reduced-motion`）；移动端冻结头像列 + 紧凑结果表。
- **思考气泡重做**：轮换 i18n 文案 + 脉冲点；完成后显示「思考耗时 2.3s」；流式时用预格式化、完成后用 markdown，避免解析卡顿。
- **叙述 markdown**：confirm 块改用 `parseEnvelope().type === "confirm"` 判定而非硬编码正则；复制行为简化为**仅复制摘要文本**。

---

## 2. 国际化 i18n（en / zh-CN / zh-TW）— 主线二

横切整个应用，采用 **next-intl v4.9.1**（`without-i18n-routing` 模式）。

### 2.1 基础设施

- 新增 `src/i18n/`：`config.ts`（`SUPPORTED_LOCALES = ["en","zh-CN","zh-TW"]`，默认 `en`）、`request.ts`、`loadMessages.ts`、`useLocaleSwitch.ts`。
- **中间件改造** `src/middleware.ts`：在原有 `analysis.dinq.me` 子域名重写之上，叠加 locale 检测 —— 读 `NEXT_LOCALE` cookie → `accept-language`（`zh-TW/HK/MO/Hant` → 繁体，其余 `zh` → 简体）；通过 `x-locale` **请求头**注入 RSC（edge runtime 下响应头不保证回传），并持久化 cookie（生产域 `.dinq.me`）。matcher 排除 `api`。
- 翻译资源 `messages/{en,zh-CN,zh-TW}/`，**19 个命名空间**：`analysis / auth / cards / common / dinqbot / history / home / inbox / integration / marketing / mydinq / onboarding / organization / payment / publicProfile / search / settings / shortlist / task`。另有 `messages/STYLE_GUIDE.md`。
- 配套脚本 `scripts/i18n-inventory.mjs`、计划文档 `docs/I18N_PLAN.md`。

### 2.2 业务面迁移

迁移波次覆盖：**/shortlist → 应用骨架（Sidebar/Header/Footer）→ common 叶子组件 → settings（账号/验证/订阅/API Keys/Profile/DINQ Page）→ auth 登录注册 → mydinq / inbox / integration / payment / history → 组织 / task(talent-radar) / 卡片工厂(cards) → 公开主页 homepage → marketing 营销页 → analysis 分析页 → 公开个人页 [username] → dinqbot → search 深搜 → onboarding → mobile（MobileTabBar + My 页）**。

- **zh-TW 繁体**：在 `zh → zh-CN` 规整之后新增繁体，并做了人工审校台湾用语。
- **语言切换器**：账号菜单分段切换、Footer、登出态桌面 Header、设置页 `settings/language/page.tsx` + `LanguageCard.tsx` + `LanguageMenuItems.tsx`；切换走 `router.refresh()` 而非整页刷新。新增图标 `public/icons/settings/language.svg`。
- **卡片工厂 i18n**：`card-factory/definitions/*/render.tsx` 几乎全部接入 `cards` 全局命名空间（github / linkedin / youtube / reddit / huggingface / vibe 等 20+ 卡片）。

### 2.3 Cloudflare 部署适配（i18n 引发）

- 让 `pages:build` 在动态 i18n 下通过。
- **blog markdown 构建期预打包**：新增 `scripts/gen-blog-content.mjs` + `blogs/config/content.ts`，`build` 脚本改为 `gen-blog-content && next build`（edge runtime 无法运行时读 markdown）。
- **语言中立 404**：新增 `global-not-found.tsx` / `NotFoundContent.tsx` / `NotFoundActions.tsx`。
- 修复运行时 locale + `MISSING_MESSAGE` 等问题。

---

## 3. API Playground 重做 — 主线三

涉及 `src/components/business/ApiPlayground/`（`OutputPanel.tsx`、`PlaygroundForm.tsx`、`useCodeGenerator.ts`）与 `src/app/(authenticated)/(workspace)/api-playground/page.tsx`、`src/types/api/search.ts`。

**定位**：面向开发者的 People Search **API v2** 试验台 —— 直接、单次、即时 JSON/可视化输出；区别于深度搜索（对话式、多轮、agentic）。

### 主要改动

- **People Search v2 契约**：升级请求/响应结构，支持更丰富的 metrics / assets / time 字段。
- **来源单选**：source selector 由多选改为单选（GitHub / HuggingFace / Company / Scholar / LinkedIn）。
- **活跃时间筛选**：预设（任意 / 近 30d / 180d / 1y）+ 自定义区间，发送 `time.active.from/to`。
- **可视化输出重做（分层卡片）**：头像 + 姓名/质量指示/来源徽标 + 操作按钮（Analyze/Open）→ 来源化副标题 → headline → 指标网格 + 可折叠溢出 pills → 资产/经历/教育预览卡 → 链接页脚。默认从 JSON 改为 **Visual** tab；响应式 `auto-fill minmax(450px)` 多列。
- **各来源定制**：Scholar（论文卡、h-index/引用/一作、可折叠学术标签）、LinkedIn（解析 markdown → 标题/地点/连接数，两行卡头）、HuggingFace（模型/数据集/空间类型图标、解析 JSON 摘要）、Company（资产去重、投资/任职计数、crunchbaseRank）。
- **顶栏分段控件 + 全屏切换**：Code/Output 切换并入 TopBar，右栏可全屏；移动端搜索后自动滚动到输出。
- **SDK 代码示例 + Skill/MCP 模式**：代码 tab 输出 Python/TypeScript/Curl SDK 片段；新增 **Skill 模式**（可复制的 DINQ Search skill 定义）与 **MCP 模式**（远程 MCP 连接器 + 工具签名 `dinq_search_start/poll/search/health`），按 hash（`#api/#skill/#mcp`）切换。
- **结果上限引导**：单次最多 100，超限阻断并引导「联系我们」。
- **分析深链**：结果名按环境路由到 `analysis.dinq.me` 的 `/github`、`/linkedin`、`/scholar`；HuggingFace/X 暂「敬请期待」。可恢复失败（502/504/408）时保留上次结果。

---

## 4. 其他功能改动

### 4.1 候选人补全 Enrich
- 新增手动刷新动作。
- 适配后端 profile-email 接口由 `email` 改为 `emails` 数组；只显示首个邮箱、清理陈旧 reveal 状态；请求加 `session_id`；修复外联弹窗邮箱选择器 z-index；隐藏 ding 搜索工具标签。

### 4.2 组织 Organization
- 新增**品牌编辑器** `OrgBrandingEditor.tsx`，配套新 hook `src/hooks/useImageCropUpload.ts`（图片裁剪上传）。
- 透明 logo 加背景；限制资料摘要行数；允许多个团队招募；修复创建弹窗滚动。

### 4.3 计费 Billing / 邀请 Invite / 消息 Messages
- **Pay-as-you-go（PAYG）**：新增按量付费控件、支付方式移除、setup toast 简化；`SubscriptionCard.tsx`；订阅跳转标记为 edge；`types/api/payment.ts`。
- **邀请**：支持注册后兑换邀请码（`utils/applyPendingInvite.ts`）。
- **消息**：新增回复与团队删除，配合上面的 WebSocket 撤回事件；`types/entity/message.ts`。

### 4.4 设置 / 导航 / 营销
- **DINQ Card → DINQ Page 重命名**：路由 `settings/dinqcard` → `settings/dinqpage`。
- Header：重做移动端菜单 + 新增桌面产品导航；登出态桌面语言切换。
- Sidebar：工作区导航重排序。
- 营销/首页：FAQ 数据源数量统一为 **500+**、紧凑 hero 统计、zh/zh-TW 文案打磨、登录页 tagline 重定位为「AI talent discovery platform」、demo 页新增「预约通话」CTA、pricing 联系销售弹窗打磨。
- 其他修复：导出 CSV 保留 UTF-8 编码、禁用公开可见性弹窗（consent）等。

---

## 5. 基础设施 / 构建 / 依赖

| 项 | 说明 |
|---|---|
| 依赖 | 新增 **`next-intl@^4.9.1`** |
| 构建脚本 | `build` 为 `gen-blog-content.mjs && next build`；新增 `blogs:gen` |
| 脚本 | `scripts/gen-blog-content.mjs`、`scripts/i18n-inventory.mjs` |
| 类型声明 | `src/global.d.ts` |
| 样式 | `styles/custom.css`、`styles/tailwind.css` |
| 布局壳 | 多路由的 `layout.tsx`（search / shortlist / organization / integration / history / talent-radar / api-playground / dinqbot / payment / [username] / marketing）用于注入按需 i18n 命名空间 |
| Mock 数据 | 深搜录制以日期前缀命名（`0320-…` / `0323-…` / `0325-…`），并新增 `0618-deep-search-aaai-2026-chinese-nlp-authors.json` |

---

## 6. 风险与回归关注点

1. **中间件 locale 注入**在 Cloudflare edge 下依赖 `x-locale` 请求头透传 —— 部署后需验证 RSC 实际读到的语言、cookie 跨子域（`.dinq.me`）行为。
2. **深搜流式**改动集中（信封解析、思考批量、轮次收尾）—— 重点回归多轮搜索、仅附件搜索、流中断恢复。
3. **API Playground v2 契约** —— 需与后端 `/v2/people/search` 字段对齐，关注各来源（scholar/linkedin/hf/company）渲染分支。
4. **PAYG 计费**与订阅跳转涉及支付，建议端到端验证。
5. 19 × 3 = 57 个翻译文件，关注 `MISSING_MESSAGE` 与 CJK 排版（hero 标题衬线兜底）。
