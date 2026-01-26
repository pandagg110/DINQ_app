import 'package:dinq_app/pages/auth/verify_code_page.dart';
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
import '../pages/settings/settings_account_page.dart';
import '../pages/settings/settings_dinqcard_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/settings/settings_profile_page.dart';
import '../pages/settings/settings_subscription_page.dart';
import '../pages/settings/settings_verification_page.dart';
import '../pages/web_view_page.dart';

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/',
      errorBuilder: (context, state) => const NotFoundPage(),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LandingPage()),
        GoRoute(path: '/landing', builder: (context, state) => const LandingPage()),
        GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
        GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
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
        GoRoute(path: '/reset/callback', builder: (context, state) => const ResetCallbackPage()),
        GoRoute(path: '/demo', builder: (context, state) => const DemoPage()),
        GoRoute(path: '/waiting-list', builder: (context, state) => const WaitingListPage()),
        GoRoute(path: '/generation', builder: (context, state) => const GenerationPage()),
        GoRoute(path: '/pricing', builder: (context, state) => const PricingPage()),
        GoRoute(path: '/blogs', builder: (context, state) => const BlogsPage()),
        GoRoute(
          path: '/blogs/:slug',
          builder: (context, state) => BlogDetailPage(slug: state.pathParameters['slug'] ?? ''),
        ),
        GoRoute(path: '/terms', builder: (context, state) => const TermsPage()),
        GoRoute(path: '/privacy', builder: (context, state) => const PrivacyPage()),
        GoRoute(path: '/guidelines', builder: (context, state) => const GuidelinesPage()),
        GoRoute(path: '/cookies', builder: (context, state) => const CookiesPage()),
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
        GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
        GoRoute(
          path: '/settings/profile',
          builder: (context, state) => const SettingsProfilePage(),
        ),
        GoRoute(
          path: '/settings/account',
          builder: (context, state) => const SettingsAccountPage(),
        ),
        GoRoute(
          path: '/settings/verification',
          builder: (context, state) => const SettingsVerificationPage(),
        ),
        GoRoute(
          path: '/settings/dinqcard',
          builder: (context, state) => const SettingsDinqCardPage(),
        ),
        GoRoute(
          path: '/settings/subscription',
          builder: (context, state) => const SettingsSubscriptionPage(),
        ),
        GoRoute(path: '/payment/success', builder: (context, state) => const PaymentSuccessPage()),
        GoRoute(
          path: '/payment/cancelled',
          builder: (context, state) => const PaymentCancelledPage(),
        ),
        GoRoute(path: '/social-callback', builder: (context, state) => const SocialCallbackPage()),
        GoRoute(
          path: '/account-callback',
          builder: (context, state) => const AccountCallbackPage(),
        ),
        GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
        GoRoute(path: '/admin/mydinq', builder: (context, state) => const AdminMyDinqPage()),
        GoRoute(path: '/admin/search', builder: (context, state) => const AdminSearchPage()),
        GoRoute(path: '/admin/openings', builder: (context, state) => const AdminOpeningsPage()),
        GoRoute(path: '/admin/inbox', builder: (context, state) => const AdminInboxPage()),
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
        GoRoute(path: '/analysis', builder: (context, state) => const AnalysisPage()),
        GoRoute(path: '/analysis/github', builder: (context, state) => const GitHubAnalysisPage()),
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
