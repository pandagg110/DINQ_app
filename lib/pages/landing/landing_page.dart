import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../constants/landing.dart';
import '../../stores/user_store.dart';
import '../../utils/asset_path.dart';
import '../../widgets/common/badge.dart';
import '../../widgets/landing/hero_animation.dart';
import '../../widgets/landing/hand_decoration.dart';
import '../../widgets/landing/radiant_background.dart';
import '../../widgets/landing/roles_marquee.dart';
import '../../widgets/landing/tabs_media.dart';
import '../../widgets/landing/title_block.dart';
import '../../widgets/layout/app_footer.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/lottie_view.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showHeader = true;
  double _lastOffset = 0;
  int _activeTabIndex = 0;
  String _claimUsername = '';
  bool _faqExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final current = _scrollController.offset;
    if (current < 80) {
      if (!_showHeader) setState(() => _showHeader = true);
    } else {
      if (current > _lastOffset && _showHeader) {
        setState(() => _showHeader = false);
      } else if (current < _lastOffset && !_showHeader) {
        setState(() => _showHeader = true);
      }
    }
    _lastOffset = current;
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final isAuthenticated = userStore.isLoggedIn();
    final hasFlow = userStore.myFlow != null && userStore.myFlow!.status == 'success';

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(context, isAuthenticated, hasFlow),
                _buildTabsSection(),
                _buildRolesSection(),
                _buildCtaSection(context, isAuthenticated, hasFlow),
                _buildFaqSection(),
                _buildClosingSection(),
                const AppFooter(),
              ],
            ),
          ),
          AnimatedSlide(
            offset: _showHeader ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 300),
            child: const AppHeader(variant: HeaderVariant.glass),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isAuthenticated, bool hasFlow) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          const SizedBox(height: 64),
          Stack(
            children: [
              Positioned(
                left: 12,
                top: 40,
                child: SvgPicture.asset(assetPath('images/landing/1-bg-magic.svg'), width: 48, height: 48),
              ),
              Positioned(
                left: 96,
                top: 180,
                child: SvgPicture.asset(assetPath('images/landing/1-bg-user.svg'), width: 48, height: 48),
              ),
              Positioned(
                right: 24,
                top: 160,
                child: SvgPicture.asset(assetPath('images/landing/1-bg-network.svg'), width: 48, height: 48),
              ),
              Positioned(
                right: 8,
                top: 60,
                child: SvgPicture.asset(assetPath('images/landing/1-bg-cup.svg'), width: 48, height: 48),
              ),
              Column(
                children: [
                  AppBadge(
                    borderColor: const Color(0xFF171717),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(assetPath('images/landing/1-tag-icon.svg'), width: 24, height: 24),
                        const SizedBox(width: 8),
                        Text(HERO.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Editor Note',
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: Color(0xFF171717),
                      ),
                      children: [
                        TextSpan(text: '${HERO.titlePrefix} '),
                        TextSpan(
                          text: HERO.titleHighlight,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const TextSpan(text: '\n'),
                        TextSpan(text: HERO.titleSecondaryLeft),
                        const TextSpan(text: ' '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Image.asset(
                            assetPath('images/landing/1-zuck-eyes.png'),
                            height: 40,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(text: HERO.titleSecondaryRight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: HERO.subtitle
                        .map((line) => Text(
                              line,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF303030)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  if (!isAuthenticated || !hasFlow) _buildClaimSection(context),
                  if (isAuthenticated && hasFlow) _buildLoggedInActions(context),
                  const SizedBox(height: 32),
                  const HeroAnimation(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaimSection(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 520;
    Widget buildClaimButton({bool fullWidth = false}) {
      final button = ElevatedButton(
        onPressed: () => _handleClaim(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF171717),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        child: const Text('Claim your DINQ'),
      );
      if (!fullWidth) {
        return button;
      }
      return SizedBox(width: double.infinity, child: button);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF171717), width: 2),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Text('dinq.me/', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'yourname',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
                    setState(() => _claimUsername = sanitized);
                  },
                ),
              ),
              if (!isNarrow) buildClaimButton(),
            ],
          ),
        ),
        if (isNarrow) ...[
          const SizedBox(height: 12),
          buildClaimButton(fullWidth: true),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => context.go('/demo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF171717),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: const Text('Request a Demo'),
        ),
      ],
    );
  }

  Widget _buildLoggedInActions(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.go('/admin/mydinq'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF171717),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: SvgPicture.asset(assetPath('images/card/dinq-card-white.svg'), width: 24, height: 24),
          label: const Text('My DINQ'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/admin/search'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF171717),
            side: const BorderSide(color: Color(0xFF171717)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: SvgPicture.asset(assetPath('images/card/discover.svg'), width: 24, height: 24),
          label: const Text('Discover'),
        ),
      ],
    );
  }

  void _handleClaim(BuildContext context) {
    final userStore = context.read<UserStore>();
    final username = _claimUsername.trim();
    if (!userStore.isLoggedIn()) {
      final redirect = username.isEmpty ? '/generation' : '/generation?domain=$username';
      context.go('/signin?redirect=$redirect');
      return;
    }
    if (username.isEmpty) {
      context.go('/generation');
      return;
    }
    context.go('/generation?domain=$username');
  }

  Widget _buildTabsSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
      child: Column(
        children: [
          const TitleBlock(title: 'AI Career Agent\nfor you'),
          const SizedBox(height: 24),
          TabsMedia(
            items: TABS,
            selectedIndex: _activeTabIndex,
            onChanged: (index) => setState(() => _activeTabIndex = index),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const TitleBlock(title: 'Designed for\nAI-era Professionals'),
          const SizedBox(height: 24),
          RolesMarquee(items: ROLES),
        ],
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context, bool isAuthenticated, bool hasFlow) {
    return RadiantBackground(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 780),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF171717)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(color: const Color(0xFF171717), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        _windowDot(const Color(0xFFF87171)),
                        const SizedBox(width: 8),
                        _windowDot(const Color(0xFFFDE277)),
                        const SizedBox(width: 8),
                        _windowDot(const Color(0xFFDDFEBC)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (CTA.eyebrow.isNotEmpty)
                    Text(
                      CTA.eyebrow.toUpperCase(),
                      style: const TextStyle(letterSpacing: 3, fontSize: 12, color: Color(0xFF303030)),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    CTA.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Editor Note',
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(width: 1, height: 60, color: const Color(0xFF171717)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => isAuthenticated && hasFlow ? context.go('/admin/mydinq') : _handleClaim(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF171717),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isAuthenticated && hasFlow ? 'My DINQ' : CTA.buttonLabel),
                  ),
                ],
              ),
              const Positioned(
                right: -20,
                bottom: -30,
                child: HandDecoration(size: 140),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _windowDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildFaqSection() {
    final displayFaqs = _faqExpanded ? FAQ : FAQ.take(5).toList();
    return Container(
      width: double.infinity,
      color: const Color(0xFFEDEDE5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const TitleBlock(title: 'Frequently\nAsked Questions'),
          const SizedBox(height: 24),
          ExpansionPanelList.radio(
            children: displayFaqs
                .map(
                  (item) => ExpansionPanelRadio(
                    value: item.question,
                    headerBuilder: (context, isExpanded) => ListTile(
                      title: Text(item.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(item.answer, style: const TextStyle(color: Color(0xFF4B5563))),
                    ),
                  ),
                )
                .toList(),
          ),
          if (FAQ.length > 5)
            TextButton(
              onPressed: () => setState(() => _faqExpanded = !_faqExpanded),
              child: Text(_faqExpanded ? 'Show Less' : 'Show All Questions'),
            ),
        ],
      ),
    );
  }

  Widget _buildClosingSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFBDCFD8),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          height: 240,
          child: const LottieView(asset: 'animations/Footer-Logo.json'),
        ),
      ),
    );
  }
}

