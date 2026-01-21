import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../stores/user_store.dart';
import '../logo.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key, this.showAuthButtons = true, this.variant = HeaderVariant.solid});

  final bool showAuthButtons;
  final HeaderVariant variant;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  bool mobileMenuOpen = false;
  bool productExpanded = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final userStore = context.watch<UserStore>();
    final isAuthenticated = userStore.isLoggedIn();

    final headerContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.variant == HeaderVariant.glass ? Colors.white.withOpacity(0.7) : const Color(0xFFF9F9F9),
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          AppLogo(
            size: LogoSize.lg,
            onTap: () => context.go('/'),
            isAnalysis: GoRouterState.of(context).fullPath?.startsWith('/analysis') ?? false,
          ),
          const SizedBox(width: 24),
          if (isDesktop) _buildDesktopNav(context),
          const Spacer(),
          if (widget.showAuthButtons) _buildAuthControls(context, isDesktop, isAuthenticated, userStore),
          if (!isDesktop) _buildMobileMenuButton(),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        headerContent,
        if (!isDesktop) _buildMobileMenu(context, isAuthenticated),
      ],
    );
  }

  Widget _buildDesktopNav(BuildContext context) {
    return Row(
      children: [
        _NavButton(label: 'Home', onTap: () => context.go('/')),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (value) => _handleProductSelection(context, value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: '/admin/mydinq', child: Text('My DINQ')),
            PopupMenuItem(value: '/admin/search', child: Text('Discover')),
            PopupMenuItem(value: '/analysis', child: Text('Analysis')),
          ],
          child: _NavButton(label: 'Product', onTap: () {}),
        ),
        const SizedBox(width: 8),
        _NavButton(label: 'Pricing', onTap: () => context.go('/pricing')),
        const SizedBox(width: 8),
        _NavButton(label: 'Blogs', onTap: () => context.go('/blogs')),
      ],
    );
  }

  Widget _buildAuthControls(
    BuildContext context,
    bool isDesktop,
    bool isAuthenticated,
    UserStore userStore,
  ) {
    if (!isDesktop) {
      return const SizedBox.shrink();
    }

    if (isAuthenticated) {
      return Row(
        children: [
          TextButton(
            onPressed: () => context.go('/demo'),
            child: const Text('Request a Demo', style: TextStyle(color: Color(0xFF171717))),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.go('/pricing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF171717),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Upgrade'),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                userStore.logout();
                context.go('/');
                return;
              }
              _authNavigate(context, userStore, value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/admin/mydinq', child: Text('My DINQ')),
              PopupMenuItem(value: '/settings/profile', child: Text('Settings')),
              PopupMenuItem(value: '/demo', child: Text('Request a Demo')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundImage: userStore.user?.userData.avatarUrl.isNotEmpty == true
                  ? NetworkImage(userStore.user!.userData.avatarUrl)
                  : null,
              backgroundColor: const Color(0xFFE5E5E5),
              child: userStore.user?.userData.avatarUrl.isNotEmpty == true
                  ? null
                  : const Icon(Icons.person, color: Colors.black54),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        TextButton(
          onPressed: () => context.go('/demo'),
          child: const Text('Request a Demo', style: TextStyle(color: Color(0xFF171717))),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => context.go('/signup'),
          child: const Text('Sign up', style: TextStyle(color: Color(0xFF171717))),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => context.go('/signin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF171717),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Sign in'),
        ),
      ],
    );
  }

  Widget _buildMobileMenuButton() {
    return IconButton(
      icon: Icon(mobileMenuOpen ? Icons.close : Icons.menu, color: const Color(0xFF171717)),
      onPressed: () {
        setState(() {
          mobileMenuOpen = !mobileMenuOpen;
          if (!mobileMenuOpen) {
            productExpanded = false;
          }
        });
      },
    );
  }

  Widget _buildMobileMenu(BuildContext context, bool isAuthenticated) {
    if (!mobileMenuOpen) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileNavItem(label: 'Home', onTap: () => _navigate(context, '/')),
          _MobileNavItem(
            label: 'Product',
            trailing: Icon(productExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                productExpanded = !productExpanded;
              });
            },
          ),
          if (productExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  _MobileNavItem(label: 'My DINQ', onTap: () => _authNavigate(context, context.read<UserStore>(), '/admin/mydinq')),
                  _MobileNavItem(label: 'Discover', onTap: () => _authNavigate(context, context.read<UserStore>(), '/admin/search')),
                  _MobileNavItem(label: 'Analysis', onTap: () => _navigate(context, '/analysis')),
                ],
              ),
            ),
          _MobileNavItem(label: 'Pricing', onTap: () => _navigate(context, '/pricing')),
          _MobileNavItem(label: 'Blogs', onTap: () => _navigate(context, '/blogs')),
          const Divider(height: 1),
          if (isAuthenticated) ...[
            _MobileNavItem(label: 'Settings', onTap: () => _authNavigate(context, context.read<UserStore>(), '/settings/profile')),
            _MobileNavItem(label: 'Sign out', onTap: () {
              context.read<UserStore>().logout();
              _navigate(context, '/');
            }),
          ] else ...[
            _MobileNavItem(label: 'Sign up', onTap: () => _navigate(context, '/signup')),
            _MobileNavItem(label: 'Sign in', onTap: () => _navigate(context, '/signin')),
          ],
          _MobileNavItem(label: 'Request a Demo', onTap: () => _navigate(context, '/demo')),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String path) {
    setState(() {
      mobileMenuOpen = false;
      productExpanded = false;
    });
    context.go(path);
  }

  void _handleProductSelection(BuildContext context, String path) {
    final userStore = context.read<UserStore>();
    if (path.startsWith('/admin')) {
      _authNavigate(context, userStore, path);
      return;
    }
    context.go(path);
  }

  void _authNavigate(BuildContext context, UserStore userStore, String path) {
    if (!userStore.isLoggedIn()) {
      context.go('/signin');
      return;
    }
    final flow = userStore.myFlow;
    if (path.startsWith('/admin') && (flow == null || flow.status != 'success' || flow.domain.isEmpty)) {
      context.go('/generation');
      return;
    }
    context.go(path);
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF171717),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({required this.label, required this.onTap, this.trailing});

  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}

enum HeaderVariant { solid, glass }


