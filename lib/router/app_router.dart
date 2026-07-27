import 'package:dinq_app/pages/auth/verify_code_page.dart';
import 'package:dinq_app/pages/settings/career_verification_page.dart';
import 'package:dinq_app/pages/settings/education_verification_page.dart';
import 'package:dinq_app/pages/settings/settings_set_email_page.dart';
import 'package:dinq_app/pages/settings/settings_set_password_page.dart';
import 'package:dinq_app/pages/settings/verification_success_page.dart';
import 'package:go_router/go_router.dart';

import '../pages/admin/admin_mydinq_page.dart';
import '../pages/admin/admin_openings_page.dart';
import '../pages/admin/admin_page.dart';
import '../pages/admin/admin_search_page.dart';
import '../pages/admin/inbox/admin_inbox_conversation_page.dart';
import '../pages/admin/inbox/admin_inbox_notifications_page.dart';
import '../pages/admin/inbox/admin_inbox_page.dart';
import '../pages/analysis/analysis_page.dart';
import '../pages/analysis/github_compare_page.dart';
import '../pages/analysis/github_page.dart';
import '../pages/analysis/linkedin_compare_page.dart';
import '../pages/analysis/linkedin_page.dart';
import '../pages/analysis/scholar_compare_page.dart';
import '../pages/analysis/scholar_page.dart';
import '../pages/auth/demo_page.dart';
import '../pages/auth/reset_callback_page.dart';
import '../pages/auth/reset_page.dart';
import '../pages/auth/signin_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/auth/waiting_list_page.dart';
import '../pages/callback/account_callback_page.dart';
import '../pages/callback/social_callback_page.dart';
import '../pages/generation/generation_page.dart';
import '../pages/landing/landing_page.dart';
import '../pages/main_tab/main_tab_page.dart';
import '../pages/marketing/blog_detail_page.dart';
import '../pages/marketing/blogs_page.dart';
import '../pages/marketing/cookies_page.dart';
import '../pages/marketing/guidelines_page.dart';
import '../pages/marketing/pricing_page.dart';
import '../pages/marketing/privacy_page.dart';
import '../pages/marketing/terms_page.dart';
import '../pages/not_found_page.dart';
import '../pages/payment/payment_cancelled_page.dart';
import '../pages/payment/payment_success_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/settings/edit_profile_page.dart';
import '../pages/settings/settings_account_page.dart';
import '../pages/settings/settings_dinqcard_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/settings/settings_profile_page.dart';
import '../pages/settings/settings_credits_page.dart';
import '../pages/settings/settings_subscription_page.dart';
import '../pages/settings/settings_verification_page.dart';
import '../pages/splash_page.dart';
import '../pages/web_view_page.dart';
import '../pages/me/invite_page.dart';
import '../pages/me/api_keys_page.dart';
import '../pages/me/organization_page.dart';
import '../pages/me/organization_detail_page.dart';
import '../pages/me/integration_page.dart';
import '../pages/me/push_settings_page.dart';
import '../pages/mydinq/mydinq_page.dart';
import '../stores/user_store.dart';

class AppRouter {
  // 不需要登录就能访问的公开路由
  static const _publicRoutes = [
    '/splash',
    '/webview',
    '/signin',
    '/signup',
    '/reset',
    '/reset/callback',
    '/verify',
    '/landing',
    '/demo',
    '/waiting-list',
    '/terms',
    '/privacy',
    '/guidelines',
    '/cookies',
    '/pricing',
    '/blogs',
    '/social-callback',
    '/account-callback',
  ];

  static bool _isPublicRoute(String location) {
    // 精确匹配公开路由
    if (_publicRoutes.contains(location)) return true;
    // 匹配 /blogs/:slug 路由
    if (location.startsWith('/blogs/')) return true;
    // 匹配用户资料页 /:username（排除其他路由前缀）
    if (location.startsWith('/') &&
        !location.contains('/') &&
        location.length > 1)
      return true;
    return false;
  }

  static GoRouter create(
    UserStore userStore, {
    bool showFirstLaunchSplash = false,
  }) {
    var firstLaunchSplashPending = showFirstLaunchSplash;
    return GoRouter(
      initialLocation: showFirstLaunchSplash
          ? '/splash'
          : (userStore.isLoggedIn() ? '/search' : '/signin'),
      errorBuilder: (context, state) => const NotFoundPage(),
      refreshListenable: userStore,
      redirect: (context, state) {
        final isLoggedIn = userStore.isLoggedIn();
        final isInitialized = userStore.isInitialized;
        final location = state.matchedLocation;
        // 如果还未初始化完成，停留在启动页
        if (!isInitialized) {
          return location == '/splash' ? null : '/splash';
        }

        // 初始化完成后，如果还在启动页，根据登录状态跳转
        if (location == '/splash') {
          if (firstLaunchSplashPending) return null;
          if (!isLoggedIn) return '/signin';
          return '/search';
        }

        // 判断当前是否在登录/注册页
        final isOnAuthPage = location == '/signin' || location == '/signup';

        // 如果已登录且在登录/注册页，跳转到 Search
        if (isLoggedIn && isOnAuthPage) {
          return '/search';
        }

        // 如果未登录且不在公开路由，跳转到登录页
        if (!isLoggedIn && !_isPublicRoute(location)) {
          return '/signin';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => SplashPage(
            onComplete: () {
              firstLaunchSplashPending = false;
              context.go(userStore.isLoggedIn() ? '/search' : '/signin');
            },
          ),
        ),
        GoRoute(path: '/', builder: (context, state) => const MainTabPage()),
        GoRoute(path: '/me', builder: (context, state) => const MainTabPage()),
        GoRoute(path: '/shortlist', builder: (context, state) => const MainTabPage()),
        GoRoute(
          path: '/landing',
          builder: (context, state) => const LandingPage(),
        ),
        GoRoute(
          path: '/signin',
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(path: '/reset', builder: (context, state) => const ResetPage()),
        GoRoute(
          path: '/verify',
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            // 获取路径参数
            final email = (map['email'] ?? "").toString();
            final password = (map['password'] ?? "").toString();
            return VerifyCodePage(email: email, password: password);
          },
        ),
        GoRoute(
          path: '/reset/callback',
          builder: (context, state) => const ResetCallbackPage(),
        ),
        GoRoute(path: '/demo', builder: (context, state) => const DemoPage()),
        GoRoute(
          path: '/waiting-list',
          builder: (context, state) => const WaitingListPage(),
        ),
        GoRoute(
          path: '/generation',
          builder: (context, state) => const GenerationPage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const MainTabPage(),
        ),
        GoRoute(
          path: '/search/:id',
          builder: (context, state) => const MainTabPage(),
        ),
        GoRoute(
          path: '/search/:type/:id',
          builder: (context, state) => const MainTabPage(),
        ),
        GoRoute(path: '/discover', redirect: (context, state) => '/search'),
        GoRoute(
          path: '/pricing',
          builder: (context, state) => const PricingPage(),
        ),
        GoRoute(path: '/blogs', builder: (context, state) => const BlogsPage()),
        GoRoute(
          path: '/blogs/:slug',
          builder: (context, state) =>
              BlogDetailPage(slug: state.pathParameters['slug'] ?? ''),
        ),
        GoRoute(path: '/terms', builder: (context, state) => const TermsPage()),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const PrivacyPage(),
        ),
        GoRoute(
          path: '/guidelines',
          builder: (context, state) => const GuidelinesPage(),
        ),
        GoRoute(
          path: '/cookies',
          builder: (context, state) => const CookiesPage(),
        ),
        GoRoute(
          path: '/webview',
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final url = map['url'] ?? '';
            final navTitle = map['navTitle'];
            final showAppBar = map['showAppBar'] != 'false';
            return WebViewPage(
              url: Uri.decodeComponent(url),
              navTitle: navTitle,
              showAppBar: showAppBar,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        // My 子页（邀请/开发者/组织等，线上H5 对应的原生实现）
        GoRoute(
          path: '/me/invite',
          builder: (context, state) => const InvitePage(),
        ),
        GoRoute(
          path: '/me/api-keys',
          builder: (context, state) => const ApiKeysPage(),
        ),
        GoRoute(
          path: '/me/organization',
          builder: (context, state) => const OrganizationPage(),
        ),
        GoRoute(
          path: '/me/organization/detail',
          builder: (context, state) => OrganizationDetailPage(
            org: Map<String, dynamic>.from(state.extra as Map? ?? const {}),
          ),
        ),
        GoRoute(
          path: '/me/integration',
          builder: (context, state) => const IntegrationPage(),
        ),
        GoRoute(
          path: '/me/push-settings',
          builder: (context, state) => const PushSettingsPage(),
        ),
        GoRoute(
          path: '/me/resume',
          redirect: (context, state) => '/admin/mydinq/resume',
        ),
        GoRoute(
          path: '/settings/profile',
          builder: (context, state) => const SettingsProfilePage(),
        ),
        GoRoute(
          path: '/settings/profile/edit',
          builder: (context, state) => const EditProfilePage(),
        ),
        GoRoute(
          path: '/settings/account',
          builder: (context, state) => const SettingsAccountPage(),
        ),
        GoRoute(
          path: '/settings/account/password',
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            // 获取路径参数
            final hasPassword = map['hasPassword'];
            return SettingsSetPasswordPage(hasPassword: hasPassword);
          },
        ),
        GoRoute(
          path: '/settings/account/email',
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            // 获取路径参数
            final currentEmail = map['currentEmail'].toString();
            final onSuccess = map['onSuccess'];
            return SettingsSetEmailPage(
              currentEmail: currentEmail,
              onSuccess: onSuccess,
            );
          },
        ),
        GoRoute(
          path: '/settings/verification',
          builder: (context, state) => const SettingsVerificationPage(),
        ),
        GoRoute(
          path: '/settings/verification/education',
          builder: (context, state) => const EducationVerificationPage(),
        ),
        GoRoute(
          path: '/settings/verification/career',
          builder: (context, state) => const CareerVerificationPage(),
        ),
        GoRoute(
          path: '/settings/verification/success',
          builder: (context, state) => const VerificationSuccessPage(),
        ),
        GoRoute(
          path: '/settings/dinqcard',
          builder: (context, state) => const SettingsDinqCardPage(),
        ),
        GoRoute(
          path: '/settings/subscription',
          builder: (context, state) => const SettingsSubscriptionPage(),
        ),
        GoRoute(
          path: '/settings/credits',
          builder: (context, state) => const SettingsCreditsPage(),
        ),
        GoRoute(
          path: '/payment/success',
          builder: (context, state) => const PaymentSuccessPage(),
        ),
        GoRoute(
          path: '/payment/cancelled',
          builder: (context, state) => const PaymentCancelledPage(),
        ),
        GoRoute(
          path: '/social-callback',
          builder: (context, state) => const SocialCallbackPage(),
        ),
        GoRoute(
          path: '/account-callback',
          builder: (context, state) => const AccountCallbackPage(),
        ),
        GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
        GoRoute(
          path: '/admin/mydinq',
          builder: (context, state) => const AdminMyDinqPage(),
          routes: [
            GoRoute(
              path: 'resume',
              builder: (context, state) =>
                  const AdminMyDinqPage(initialTab: MyDinqTab.resume),
            ),
          ],
        ),
        GoRoute(
          path: '/admin/search',
          builder: (context, state) => const AdminSearchPage(),
        ),
        GoRoute(
          path: '/admin/openings',
          builder: (context, state) => const AdminOpeningsPage(),
        ),
        GoRoute(
          path: '/admin/inbox',
          builder: (context, state) => const AdminInboxPage(),
        ),
        GoRoute(
          path: '/admin/inbox/notifications',
          builder: (context, state) => const AdminInboxNotificationsPage(),
        ),
        GoRoute(
          path: '/admin/inbox/:conversationId',
          builder: (context, state) => AdminInboxConversationPage(
            conversationId: state.pathParameters['conversationId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/analysis',
          builder: (context, state) => const AnalysisPage(),
        ),
        GoRoute(
          path: '/analysis/github',
          builder: (context, state) => const GitHubAnalysisPage(),
        ),
        GoRoute(
          path: '/analysis/github_compare',
          builder: (context, state) => const GitHubComparePage(),
        ),
        GoRoute(
          path: '/analysis/linkedin',
          builder: (context, state) => const LinkedInAnalysisPage(),
        ),
        GoRoute(
          path: '/analysis/linkedin_compare',
          builder: (context, state) => const LinkedInComparePage(),
        ),
        GoRoute(
          path: '/analysis/scholar',
          builder: (context, state) => const ScholarAnalysisPage(),
        ),
        GoRoute(
          path: '/analysis/scholar_compare',
          builder: (context, state) => const ScholarComparePage(),
        ),
        GoRoute(
          path: '/:username',
          builder: (context, state) =>
              ProfilePage(username: state.pathParameters['username'] ?? ''),
        ),
      ],
    );
  }
}
