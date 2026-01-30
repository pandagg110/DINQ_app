# Dinq API 接口文档

## 通用响应格式

```json
{
  "code": 0,
  "data": {},
  "message": "Success message"
}
```

- `code`: 0 表示成功，其他值表示错误
- `data`: 响应数据
- `message`: 提示信息

---

## Waiting List 等待列表接口

### 1. 加入等待列表

**POST** `/api/v1/waiting-list`

**认证**: 不需要

**请求参数**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone_number": "+1234567890",
  "country": "United States",
  "institution": "Stanford University",
  "school": "School of Engineering",
  "role": "Software Engineer",
  "status": "pending"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 全名，2-100字符 |
| email | string | 是 | 邮箱地址 |
| phone_number | string | 否 | 电话号码 |
| country | string | 是 | 国家，2-100字符 |
| institution | string | 是 | 机构/组织，2-200字符 |
| school | string | 否 | 学校/大学 |
| role | string | 是 | 职位，2-100字符 |
| status | string | 否 | 状态: pending/approved/rejected |

**响应示例**:
```json
{
  "message": "Successfully joined waiting list",
  "position": 156
}
```

---

### 2. 获取等待列表

**GET** `/api/v1/waiting-list`

**认证**: 需要 (Bearer Token)

**Query 参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| status | string | 否 | 过滤状态: pending/approved/rejected |
| limit | int | 否 | 每页数量，默认 20 |
| offset | int | 否 | 偏移量，默认 0 |

**响应示例**:
```json
{
  "items": [
    {
      "id": "uuid-string",
      "full_name": "John Doe",
      "email_address": "john@example.com",
      "phone_number": "+1234567890",
      "country": "United States",
      "institution_organization": "Stanford University",
      "school_university": "School of Engineering",
      "job_title_position": "Software Engineer",
      "status": "pending",
      "created_at": "2025-01-20T10:00:00Z",
      "updated_at": "2025-01-20T10:00:00Z"
    }
  ],
  "total": 156,
  "limit": 20,
  "offset": 0
}
```

---

### 3. 更新等待列表状态

**POST** `/api/v1/waiting-list/update-status`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "email_address": "john@example.com",
  "status": "approved",
  "full_name": "John Doe Updated",
  "phone_number": "+1234567890",
  "country": "United States",
  "institution_organization": "Stanford University",
  "school_university": "School of Engineering",
  "job_title_position": "Senior Engineer"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email_address | string | 是 | 邮箱地址（用于定位记录） |
| status | string | 否 | 状态: pending/approved/rejected |
| full_name | string | 否 | 全名 |
| phone_number | string | 否 | 电话号码 |
| country | string | 否 | 国家 |
| institution_organization | string | 否 | 机构/组织 |
| school_university | string | 否 | 学校 |
| job_title_position | string | 否 | 职位 |

**响应示例**:
```json
{
  "message": "Waiting list information updated successfully"
}
```

---

## Account 账号绑定接口

### 1. 获取已连接账号

**GET** `/api/v1/user/accounts`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "accounts": [
      {
        "provider": "email",
        "connected": true,
        "email": "john@example.com",
        "display_url": "jo***@example.com"
      },
      {
        "provider": "google",
        "connected": true,
        "email": "john@gmail.com",
        "display_url": "jo***@gmail.com"
      },
      {
        "provider": "github",
        "connected": false,
        "email": null,
        "display_url": null
      }
    ]
  },
  "message": "Connected accounts retrieved successfully"
}
```

---

### 2. 解绑账号

**POST** `/api/v1/user/accounts/unlink`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "provider": "google"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| provider | string | 是 | 要解绑的账号类型: email/google/github |

**响应示例**:
```json
{
  "code": 0,
  "data": null,
  "message": "Account unlinked successfully"
}
```

**错误码**:
| code | 说明 |
|------|------|
| 40011 | 账号已绑定到其他用户 |
| 40012 | 必须保留至少一种登录方式 |
| 40013 | 账号未绑定 |

---

### 3. 初始化 Google 绑定

**GET** `/api/v1/user/accounts/link/google`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "auth_url": "https://accounts.google.com/o/oauth2/v2/auth?..."
  },
  "message": "Google auth URL generated successfully"
}
```

---

### 4. 初始化 GitHub 绑定

**GET** `/api/v1/user/accounts/link/github`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "auth_url": "https://github.com/login/oauth/authorize?..."
  },
  "message": "GitHub auth URL generated successfully"
}
```

---

### 5. 完成 Google 绑定

**POST** `/api/v1/user/accounts/link/google`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "code": "authorization_code_from_google",
  "redirect_uri": "https://dinq.me/account-callback"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| code | string | 是 | OAuth authorization code |
| redirect_uri | string | 否 | 回调地址，默认使用配置的地址 |

**响应示例**:
```json
{
  "code": 0,
  "data": null,
  "message": "Google account linked successfully"
}
```

---

### 6. 完成 GitHub 绑定

**POST** `/api/v1/user/accounts/link/github`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "code": "authorization_code_from_github",
  "redirect_uri": "https://dinq.me/account-callback"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| code | string | 是 | OAuth authorization code |
| redirect_uri | string | 否 | 回调地址 |

**响应示例**:
```json
{
  "code": 0,
  "data": null,
  "message": "GitHub account linked successfully"
}
```

---

## Profile 个人信息接口

### 1. 获取用户资料

**GET** `/api/v1/user/profile`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "user": {
      "id": "uuid-string",
      "email": "john@example.com",
      "name": "John Doe",
      "email_verified": true,
      "tier": "free",
      "created_at": "2025-01-20T10:00:00Z",
      "has_password": true,
      "activated": true,
      "google_id": "123456789",
      "google_email": "john@gmail.com",
      "github_id": "987654321",
      "github_login": "johndoe",
      "invite_code": "DINQ2025"
    },
    "user_data": {
      "domain": "johndoe",
      "display_name": "John Doe",
      "headline": "Software Engineer",
      "location": "San Francisco, CA"
    }
  },
  "message": "User profile retrieved successfully"
}
```

---

### 2. 修改密码

**POST** `/api/v1/auth/change-password`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "currentPassword": "old_password_123",
  "newPassword": "new_password_456"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| currentPassword | string | 条件必填 | 当前密码（已有密码时必填，OAuth用户首次设置可不填） |
| newPassword | string | 是 | 新密码，至少6位 |

**响应示例**:
```json
{
  "code": 0,
  "data": null,
  "message": "Password changed successfully"
}
```

---

### 3. 更换邮箱 - 发送验证码

**POST** `/api/v1/auth/change-email/send-code`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "newEmail": "newemail@example.com"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| newEmail | string | 是 | 新邮箱地址 |

**响应示例**:
```json
{
  "code": 0,
  "data": null,
  "message": "Verification code sent"
}
```

---

### 4. 更换邮箱 - 确认更换

**POST** `/api/v1/auth/change-email`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "newEmail": "newemail@example.com",
  "code": "123456"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| newEmail | string | 是 | 新邮箱地址 |
| code | string | 是 | 6位验证码 |

**响应示例**:
```json
{
  "code": 0,
  "data": null,
  "message": "Email changed successfully"
}
```

---

### 5. 注销账号

**GET** `/api/v1/auth/delete-account`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": null,
  "message": "Account deleted successfully"
}
```

---

## Subscription 订阅接口

### 1. 获取价格信息

**GET** `/api/v1/payment/pricing`

**认证**: 不需要

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "free": {
      "name": "Free",
      "price": 0,
      "features": ["Basic profile", "5 searches/month"]
    },
    "basic": {
      "name": "Basic",
      "price": 9.99,
      "features": ["Verified badge", "50 searches/month", "Priority support"]
    },
    "pro": {
      "name": "Pro",
      "price": 29.99,
      "features": ["All Basic features", "Unlimited searches", "API access"]
    }
  },
  "message": "success"
}
```

---

### 2. 获取订阅状态

**GET** `/api/v1/payment/subscription`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "plan": "basic",
    "status": "active",
    "auto_renew": true,
    "current_period_start": "2025-01-01T00:00:00Z",
    "current_period_end": "2025-02-01T00:00:00Z",
    "credits_remaining": 45,
    "credits_total": 50
  },
  "message": "success"
}
```

---

### 3. 创建订阅

**POST** `/api/v1/payment/checkout`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "plan": "basic"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| plan | string | 是 | 套餐: basic/pro/plus（不能是 free） |

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "session_id": "checkout_session_123",
    "url": "https://checkout.airwallex.com/..."
  },
  "message": "checkout session created"
}
```

---

### 4. 升降级套餐

**POST** `/api/v1/payment/change-plan`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "target_plan": "pro"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| target_plan | string | 是 | 目标套餐 |

**响应示例 (升级)**:
```json
{
  "code": 0,
  "data": {
    "type": "upgrade",
    "session_id": "checkout_session_456",
    "url": "https://checkout.airwallex.com/..."
  },
  "message": "upgrade checkout created"
}
```

**响应示例 (降级)**:
```json
{
  "code": 0,
  "data": {
    "type": "downgrade",
    "message": "Plan will be changed at the end of current billing period"
  },
  "message": "downgrade scheduled"
}
```

---

### 5. 设置自动续费

**POST** `/api/v1/payment/auto-renew`

**认证**: 需要 (Bearer Token)

**请求参数**:
```json
{
  "auto_renew": true
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| auto_renew | bool | 是 | true: 开启自动续费，false: 关闭 |

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "auto_renew": true
  },
  "message": "auto-renewal enabled"
}
```

---

### 6. 获取订单列表

**GET** `/api/v1/payment/orders`

**认证**: 需要 (Bearer Token)

**Query 参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认 1 |
| page_size | int | 否 | 每页数量，默认 20 |

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "orders": [
      {
        "id": "order_123",
        "user_id": "uuid-string",
        "amount": 999,
        "currency": "USD",
        "status": "succeeded",
        "plan": "basic",
        "order_type": "subscription",
        "paid_at": "2025-01-20T10:00:00Z",
        "created_at": "2025-01-20T09:55:00Z",
        "updated_at": "2025-01-20T10:00:00Z"
      }
    ],
    "total": 5,
    "page": 1,
    "page_size": 20,
    "total_pages": 1
  },
  "message": "success"
}
```

---

### 7. 获取订单详情

**GET** `/api/v1/payment/orders/{id}`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "id": "order_123",
    "user_id": "uuid-string",
    "payment_intent_id": "pi_xxx",
    "checkout_id": "checkout_xxx",
    "subscription_id": "sub_xxx",
    "customer_id": "cus_xxx",
    "amount": 999,
    "currency": "USD",
    "status": "succeeded",
    "plan": "basic",
    "order_type": "subscription",
    "metadata": {},
    "paid_at": "2025-01-20T10:00:00Z",
    "created_at": "2025-01-20T09:55:00Z",
    "updated_at": "2025-01-20T10:00:00Z"
  },
  "message": "success"
}
```

---

## Verification 身份认证接口

### Career Verification 职业认证

#### 1. 提交职业认证

**POST** `/api/v1/user/profile/career-verification`

**认证**: 需要 (Bearer Token)

**权限**: 需要 Basic/Pro/Plus 套餐

**请求参数**:
```json
{
  "company": "Google",
  "job_title": "Software Engineer",
  "verification_email": "john@google.com",
  "verification_email_verified": true,
  "document_urls": [
    "https://oss.dinq.me/documents/employee_badge.jpg",
    "https://oss.dinq.me/documents/offer_letter.pdf"
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| company | string | 是 | 公司名称 |
| job_title | string | 是 | 职位 |
| verification_email | string | 否 | 公司邮箱 |
| verification_email_verified | bool | 否 | 邮箱是否已验证 |
| document_urls | string[] | 否 | 证明文件 URL 列表 |

**响应示例**:
```json
{
  "message": "Career verification submitted successfully",
  "verification_id": "uuid-string"
}
```

---

#### 2. 获取职业认证状态

**GET** `/api/v1/user/profile/career-verification/status`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "verified": false,
  "status": "pending",
  "submitted_at": "2025-01-20T10:00:00Z",
  "reviewed_at": null,
  "rejection_reason": "",
  "data": {
    "company": "Google",
    "job_title": "Software Engineer"
  }
}
```

**status 值说明**:
| 状态 | 说明 |
|------|------|
| pending | 待审核 |
| approved | 已通过 |
| rejected | 已拒绝 |

---

#### 3. 获取职业认证完整数据

**GET** `/api/v1/user/profile/career-verification`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "id": "uuid-string",
  "user_id": "uuid-string",
  "type": "career",
  "status": "approved",
  "data": {
    "company": "Google",
    "job_title": "Software Engineer",
    "verification_email": "john@google.com",
    "verification_email_verified": true,
    "document_urls": ["https://..."]
  },
  "submitted_at": "2025-01-20T10:00:00Z",
  "reviewed_at": "2025-01-21T10:00:00Z",
  "reviewer_notes": ""
}
```

---

### Education Verification 教育认证

#### 4. 提交教育认证

**POST** `/api/v1/user/profile/education-verification`

**认证**: 需要 (Bearer Token)

**权限**: 需要 Basic/Pro/Plus 套餐

**请求参数**:
```json
{
  "student_type": "graduated",
  "university": "Stanford University",
  "degree": "Master",
  "department": "Computer Science",
  "enroll_month": "09",
  "enroll_year": "2020",
  "verification_email": "john@stanford.edu",
  "verification_email_verified": true,
  "document_urls": [
    "https://oss.dinq.me/documents/diploma.pdf"
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| student_type | string | 是 | 学生类型: current/graduated |
| university | string | 是 | 大学名称 |
| degree | string | 是 | 学位 |
| department | string | 是 | 院系 |
| enroll_month | string | 否 | 入学月份 |
| enroll_year | string | 否 | 入学年份 |
| verification_email | string | 否 | 学校邮箱 |
| verification_email_verified | bool | 否 | 邮箱是否已验证 |
| document_urls | string[] | 否 | 证明文件 URL 列表 |

**响应示例**:
```json
{
  "message": "Education verification submitted successfully",
  "verification_id": "uuid-string"
}
```

---

#### 5. 获取教育认证状态

**GET** `/api/v1/user/profile/education-verification/status`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "verified": true,
  "status": "approved",
  "submitted_at": "2025-01-20T10:00:00Z",
  "reviewed_at": "2025-01-21T10:00:00Z",
  "rejection_reason": "",
  "data": {
    "student_type": "graduated",
    "university": "Stanford University",
    "degree": "Master",
    "department": "Computer Science"
  }
}
```

---

#### 6. 获取教育认证完整数据

**GET** `/api/v1/user/profile/education-verification`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "id": "uuid-string",
  "user_id": "uuid-string",
  "type": "education",
  "status": "approved",
  "data": {
    "student_type": "graduated",
    "university": "Stanford University",
    "degree": "Master",
    "department": "Computer Science",
    "enroll_month": "09",
    "enroll_year": "2020",
    "verification_email": "john@stanford.edu",
    "verification_email_verified": true,
    "document_urls": ["https://..."]
  },
  "submitted_at": "2025-01-20T10:00:00Z",
  "reviewed_at": "2025-01-21T10:00:00Z"
}
```

---

#### 7. 获取认证汇总

**GET** `/api/v1/user/profile/verification/overview`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "career": {
      "verified": false,
      "status": "pending"
    },
    "education": {
      "verified": true,
      "status": "approved"
    },
    "social": {
      "verified": true,
      "linked_count": 2
    }
  },
  "message": "success"
}
```

---

### Social Verification 社交账号认证

#### 8. 获取 OAuth 授权 URL

**GET** `/api/v1/user/profile/social-verification/oauth-url`

**认证**: 需要 (Bearer Token)

**Query 参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| platform | string | 是 | 平台: Twitter/LinkedIn/Github/Youtube/Huggingface/Instagram |

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "url": "https://twitter.com/i/oauth2/authorize?..."
  },
  "message": "success"
}
```

---

#### 9. 绑定社交账号

**POST** `/api/v1/user/profile/social-verification/link`

**认证**: 需要 (Bearer Token)

**权限**: 需要 Basic/Pro/Plus 套餐

**请求参数**:
```json
{
  "platform": "Twitter",
  "authorization_code": "oauth_code_from_platform",
  "redirect_uri": "https://dinq.me/callback",
  "state": "optional_state_string",
  "code_verifier": "pkce_code_verifier_for_twitter"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| platform | string | 是 | 平台名称 |
| authorization_code | string | 是 | OAuth 授权码 |
| redirect_uri | string | 是 | 回调地址 |
| state | string | 否 | 状态验证 |
| code_verifier | string | 否 | PKCE 验证码（Twitter 需要） |

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "message": "Account linked successfully",
    "account": {
      "platform": "Twitter",
      "platform_user_id": "123456789",
      "platform_username": "johndoe",
      "linked": true,
      "linked_at": "2025-01-20T10:00:00Z"
    }
  },
  "message": "success"
}
```

---

#### 10. 解绑社交账号

**POST** `/api/v1/user/profile/social-verification/unlink`

**认证**: 需要 (Bearer Token)

**权限**: 需要 Basic/Pro/Plus 套餐

**请求参数**:
```json
{
  "platform": "Twitter"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| platform | string | 是 | 平台名称 |

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "message": "Account unlinked successfully"
  },
  "message": "success"
}
```

---

#### 11. 获取社交认证状态

**GET** `/api/v1/user/profile/social-verification/status`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "verified": true,
    "linked_count": 2
  },
  "message": "success"
}
```

---

#### 12. 获取所有已绑定社交账号

**GET** `/api/v1/user/profile/social-verification`

**认证**: 需要 (Bearer Token)

**响应示例**:
```json
{
  "code": 0,
  "data": {
    "linked_accounts": [
      {
        "platform": "Twitter",
        "platform_user_id": "123456789",
        "platform_username": "johndoe",
        "linked": true,
        "linked_at": "2025-01-20T10:00:00Z"
      },
      {
        "platform": "Github",
        "platform_user_id": "987654321",
        "platform_username": "johndoe",
        "linked": true,
        "linked_at": "2025-01-15T10:00:00Z"
      }
    ]
  },
  "message": "success"
}
```

