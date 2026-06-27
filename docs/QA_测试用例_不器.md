# DINQ 移动端 · 不器 模块 测试用例

> 范围：Notion《DINQ 移动端 App 功能开发列表》中**负责人 = 不器**的全部条目。
> 验证状态来自 2026-06-20 模拟器(iPhone 16 Pro, testapi.dinq.me) + 早期 web 代理验证。
> 前置标记：`[权限]`需 task 权限账号 / `[会话]`需有会话账号 / `[组织]`需组织成员账号 / `[真机]`需真机+证书。

---

## 一、项目清单（按 Notion，不器名下）

| 模块 | 功能 | 优先级 | 排期 | 进度(Notion) | 实测 |
|---|---|---|---|---|---|
| 注册登录 | 登录 / 注册 / 登录态管理 | P0 | 6.16 | 开发完毕 | ✅ 登录已验 |
| 注册登录 | 密码管理 | P1 | 6.16 | 开发完毕 | — |
| Inbox 消息中心 | 消息列表 / 聊天详情 | P0 | 6.16 | 开发完毕 | ⚠️ 无会话 |
| Inbox 消息中心 | Team Recruit | P0 | 6.16 | 开发完毕 | ⚠️ 无会话 |
| Inbox 消息中心 | 实时更新(WebSocket) | P0 | 6.20 | 开发完毕 | ⚠️ 无会话 |
| Inbox 消息推送 | 系统 Push | P0 | 6.16 | 待证书 @Elon | ⚠️ 真机 |
| Inbox 消息推送 | 设备 Token | P0 | 6.16 | 待后端接口 | ⚠️ 真机 |
| Inbox 消息推送 | 点击跳转 / 权限管理 | P0 | 6.16/6.20 | 开发完毕 | ⚠️ 真机 |
| Inbox 消息推送 | 未读状态 | P0 | 6.16 | 开发完毕 | ⚠️ 无数据 |
| Inbox 消息推送 | 通知中心 | P1 | 6.16 | 开发完毕 | ⚠️ 无数据 |
| Inbox 消息推送 | 推送设置 | P1 | 6.25 | 未做 | ❌ |
| My 账户概览 | 当前套餐 / Credits / 邀请赚积分 | P0/P1 | 6.16/6.20 | 开发完毕 | — |
| My 账号设置 | Profile / Account | P0 | 6.20 | 开发完毕 | — |
| My 账号设置 | Verification / Invite Friends / Subscription | P1 | 6.20 | 开发完毕 | — |
| My 开发者 | Integration | P1 | 6.20 | 开发完毕 | ✅ 已验 |
| My 开发者 | API Keys | P3 | 6.20 | 开发完毕 | ✅ 已验 |
| My 账户概览 | Invite(邀请) | P1 | 6.20 | 开发完毕 | ✅ 已验(真数据) |
| My 帮助与合规 | 帮助 / 法务页面 | P1 | 6.20 | 开发完毕 | — |
| My Organization | Organization 列表 | P2 | 6.20 | 开发完毕 | ✅ 空态已验 |
| My Organization | 组织轻管理 | P2 | 6.20 | 开发完毕 | ⚠️ 需组织 |
| Talent Radar | Radar 列表 / 操作 | P2 | 6.25 | 开发完毕 | ⚠️ 4013 |
| Talent Radar | 创建 Radar | P2 | 6.25(延期) | 我已做 | ⚠️ 4013 |
| Talent Radar | 详情 / 新增候选人 / 搜索日志 / Credits | P2 | 6.25(延期) | 未做 | ❌ |

---

## 二、测试用例

### A. 注册登录
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| AUTH-01 | 邮箱+密码登录 | 有效账号 | 输入邮箱密码 → Sign in | 进入主 Tab（Search） |
| AUTH-02 | 错误密码 | — | 输入错误密码 → Sign in | 提示错误，停留登录页 |
| AUTH-03 | OAuth 登录 | — | 点 Continue with Google/GitHub | 拉起第三方授权并回跳登录成功 |
| AUTH-04 | 自动登录 | 已登录过 | 杀掉 App 重开 | 直接进主 Tab，无需重登 |
| AUTH-05 | 退出登录 | 已登录 | My → 退出 | 回到登录页，token 清除 |
| AUTH-06 | Token 过期 | — | 用过期 token 请求 | 自动登出并引导重登 |
| AUTH-07 | 忘记/重置密码 | — | Forgot password → 流程 | 收到验证码并能重置成功 |

### B. Inbox 消息 `[会话]`
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| MSG-01 | 会话列表展示 | 有会话 | 进 Inbox | 列出会话，含名称/最后消息/时间/未读数 |
| MSG-02 | 搜索会话 | 有会话 | 顶部搜索输入 | 按关键字过滤会话 |
| MSG-03 | 进入聊天详情 | 有会话 | 点会话 | 显示历史消息，最新在底 |
| MSG-04 | 发送消息 | 有会话 | 输入并发送 | 消息上屏，对方可收 |
| MSG-05 | 加载更多历史 | 长会话 | 上滑到顶 | 加载更早消息 |
| MSG-06 | 实时更新 | 双端 | 对方发消息 | 本端 WebSocket 实时上屏 + 未读角标+1 |
| MSG-07 | Team Recruit 卡片 | 有招募消息 | 进含 team_recruit 的会话 | 显示卡片：标题+状态徽章(Full/Closed/数/上限)+头像簇(发起人皇冠) |
| MSG-08 | TR 加入 | 非发起人/未满 | 点 Join › | 调 join，成员+1，满员跳子群 |
| MSG-09 | TR 退出 | 已加入非发起人 | 点 Leave | 调 leave，成员-1 |
| MSG-10 | TR 关闭/Assemble | 发起人≥2人 | 点 Assemble›/Cancel | close(spawn/cancel)，状态变 closed |
| MSG-11 | TR 删除 | 发起人 | 点垃圾桶→确认 | 卡片从聊天隐藏 |

### C. 消息推送 `[真机]`
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| PUSH-01 | 通知权限请求 | 真机首登 | 登录后 | 弹系统通知权限框 |
| PUSH-02 | 权限被拒提示 | 拒绝过 | 进推送相关页 | 提示去系统设置开启 |
| PUSH-03 | 设备 Token 注册 | 真机+后端 | 登录成功 | 后端 /devices 收到 token |
| PUSH-04 | 登出解绑 | 已注册 | 退出登录 | 调 DELETE /devices/{token} |
| PUSH-05 | 后台收私信推送 | 真机+证书 | App 后台时对方发私信 | 系统通知栏弹出 |
| PUSH-06 | 点击跳转-会话 | 同上 | 点私信通知 | 进对应会话页 |
| PUSH-07 | 点击跳转-系统/Radar | 同上 | 点系统/Radar 通知 | 进通知中心 / 候选人 |
| PUSH-08 | 通知中心列表 | 有通知 | Inbox→通知中心 | 列出系统/Radar/私信/TR 通知 |
| PUSH-09 | 全部已读 | 有未读通知 | 点"全部已读" | 未读清零 |
| PUSH-10 | Tab 红点 | 有未读 | 看底部 Tab | 显示总未读红点数 |
| PUSH-11 | 推送设置开关 | — | 进推送设置 | ❌ 未做（应有私信/Radar/系统通知开关） |

### D. My — 账户/账号设置
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| MY-01 | 当前套餐展示 | 已登录 | 进 My | 顶部显示套餐 + Upgrade 入口 |
| MY-02 | Credits 展示 | — | 进 My | 显示可用积分，可进详情 |
| MY-03 | Profile 编辑 | — | My→Profile | 改头像/用户名/资料并保存成功 |
| MY-04 | Account 安全 | — | My→Account | 改邮箱/密码/删除账号入口 |
| MY-05 | Verification | — | My→Verification | 教育/职业认证提交与状态 |
| MY-06 | Subscription | — | My→Subscription | 套餐/Credits/订单/账单 |

### E. My — Invite（邀请）✅已验
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| INV-01 | 统计展示 | 已登录 | 进 Invite | 3 个统计 Total/Used/Left（✅实测 5/0/5） |
| INV-02 | 邀请码列表 | 有码 | 看列表 | 每行码+子行(Available/Used by)，未用带 Copy link（✅5码） |
| INV-03 | 复制邀请链接 | — | 点 Copy link | 变"Copied!"，剪贴板=https://dinq.me/invite/CODE |
| INV-04 | 邀请历史 | 有记录 | 看 History | 表 Name/Code/Date/Reward(+N 绿) |
| INV-05 | 输入邀请码 | — | Enter invite code→输入 | 兑换成功并刷新 |
| INV-06 | 空历史 | 无记录 | 看 History | "No history yet…"（✅实测） |

### F. My — Integration ✅已验
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| INT-01 | 未连接展示 | 无邮箱 | 进 Integration | Email integration 三卡 Gmail/Microsoft/IMAP（✅实测） |
| INT-02 | 发起连接 | 后端正常 | 点 Sign in with Gmail | 跳外部浏览器走 OAuth |
| INT-03 | 已连接卡 | 有连接 | 进 Integration | 邮箱+状态点(Connected/Token expired)+Sender/Signature |
| INT-04 | 编辑发件人/签名 | 已连接 | ⋯→Edit settings→保存 | 更新成功 |
| INT-05 | 断开连接 | 已连接 | ⋯→Disconnect | 账号移除 |
| INT-06 | API access 卡 | — | 看下半部 | People Search/DINQ Skill/Remote MCP 三卡，点开链接（✅实测） |

### G. My — API Keys ✅已验
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| KEY-01 | 空态 | 无 key | 进 API Keys | 钥匙图标+"No API keys yet"（✅实测） |
| KEY-02 | 创建命名 | — | Create→输入名→Create | 弹复制框(MCP URL+API key)，列表新增 |
| KEY-03 | 显示/隐藏 | 有 key | 点眼睛 | 掩码↔明文切换 |
| KEY-04 | 复制 | 有 key | 点复制 | 弹复制框 |
| KEY-05 | 删除确认 | 有 key | 点垃圾桶→确认 | 二次确认含 key 名，确认后删除 |
| KEY-06 | Disabled 徽章 | 停用 key | 看行 | 显示 Disabled + 半透明 + Created 日期 |

### H. My — 帮助/法务/组织
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| HELP-01 | 帮助页 | — | My→Help | webview 打开 FAQ |
| HELP-02 | 法务页 | — | My→Terms/Privacy | webview 打开对应页 |
| ORG-01 | 组织列表/空态 | — | My→Organization | 有组织列出/无则"No organizations yet"（✅空态实测） |
| ORG-02 | 进详情 `[组织]` | 是成员 | 点组织 | 详情：邀请链接+成员+(管理者)申请 |
| ORG-03 | 成员卡 `[组织]` | — | 看成员 | 角色色徽章(Owner绿/Admin金)+职位·地区，点名跳主页 |
| ORG-04 | 邀请链接 `[组织]` | admin/owner | Copy/Refresh | 复制 dinq.me/invite/CODE，刷新换码 |
| ORG-05 | 加入申请审批 `[组织]` | admin/owner | ✓通过/✗拒绝 | 申请处理并消失 |
| ORG-06 | 成员管理 `[组织]` | admin/owner | ⋯→改管理员/移除 | 角色变更/移除成功 |

### I. Talent Radar `[权限]`（4013 需有 task 权限账号）
| ID | 用例 | 前置 | 步骤 | 预期 |
|---|---|---|---|---|
| RAD-01 | 空状态 | 无 Radar | 进 Radar | 标语+Create Your First Radar+三步引导（✅实测） |
| RAD-02 | Radar 列表 | 有 Radar | 进 Radar | 卡片：状态徽章(Active/Paused/Completed/Failed)+SCANNED/HIGH MATCH/RESULTS |
| RAD-03 | new today | 有新增 | 看卡片 | 标题旁红标 +N new today |
| RAD-04 | 创建-描述 | 有权限 | Create→输入需求→Start | 进 AI 追问细化 |
| RAD-05 | 创建-细化 | — | 答 follow-up/选 chips→Continue | 维度齐备后进执行设置 |
| RAD-06 | 创建-设置启动 | — | 选频率/数量/邮箱→Launch | 创建成功，回列表刷新 |
| RAD-07 | 暂停/恢复 | 有 Radar | 长按/⋯→暂停/恢复 | 状态切换 |
| RAD-08 | 删除 | 有 Radar | ⋯→删除 | 卡片移除 |
| RAD-09 | 无权限提示 | 4013 账号 | Start 提交 | 友好提示"task access denied"（已修，非裸 DioException） |
| RAD-10 | Radar 详情 | — | 点卡片 | ❌ 未做（延期） |

---

## 三、阻塞项（要把对应用例验完，需提供）
1. **有 task/Radar 权限的账号** → RAD-02~08、创建链路（现 mark@dinqlabs.com 是 4013）
2. **有会话/招募消息的账号** → MSG-01~11
3. **属于某组织(admin/owner)的账号** → ORG-02~06
4. **真机 + Firebase(google-services.json/APNs) + 后端 /devices** → PUSH-01~10
5. **推送设置** 仍未做（PUSH-11）、Radar 详情/日志/Credits 未做（延期）
</content>
