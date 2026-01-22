import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/landing.dart';
import '../../stores/user_store.dart';
import '../../utils/asset_path.dart';
import '../../widgets/common/badge.dart';
import '../../widgets/common/lottie_view.dart';
import '../../widgets/landing/hand_decoration.dart';
import '../../widgets/landing/hero_animation.dart';
import '../../widgets/landing/radiant_background.dart';
import '../../widgets/landing/roles_marquee.dart';
import '../../widgets/landing/tabs_media.dart';
import '../../widgets/landing/title_block.dart';
import '../../widgets/layout/app_footer.dart';
import '../../widgets/layout/app_header.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _claimController = TextEditingController();
  final GlobalKey _tabsKey = GlobalKey();
  final GlobalKey _rolesKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _closingKey = GlobalKey();
  bool _showHeader = true;
  double _lastOffset = 0;
  double _scrollOffset = 0;
  int _activeTabIndex = 0;
  String _claimUsername = '';
  String _claimWarning = '';
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
    _claimController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final current = _scrollController.offset;
    bool nextShowHeader = true;
    if (current >= 80) {
      nextShowHeader = current <= _lastOffset;
    }
    if (nextShowHeader != _showHeader || (_scrollOffset - current).abs() > 0.5) {
      setState(() {
        _showHeader = nextShowHeader;
        _scrollOffset = current;
      });
    }
    _lastOffset = current;
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final isAuthenticated = userStore.isLoggedIn();
    final hasFlow = userStore.myFlow != null && userStore.myFlow!.status == 'success';
    final viewportHeight = MediaQuery.of(context).size.height;
    final tabsProgress = _sectionProgress(_tabsKey, viewportHeight);
    final rolesProgress = _sectionProgress(_rolesKey, viewportHeight);
    final faqProgress = _sectionProgress(_faqKey, viewportHeight);
    final closingProgress = _sectionProgress(_closingKey, viewportHeight);
    final ctaProgress = _sectionProgress(_ctaKey, viewportHeight);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(context, isAuthenticated, hasFlow),
                _buildTabsSection(tabsProgress),
                _buildRolesSection(rolesProgress),
                _buildCtaSection(context, isAuthenticated, hasFlow, ctaProgress),
                _buildFaqSection(faqProgress),
                _buildClosingSection(closingProgress),
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
    final parallaxIcons = _scrollOffset * 0.3;
    final heroMinHeight = MediaQuery.of(context).size.height - 120;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: heroMinHeight),
        child: Column(
          children: [
            const SizedBox(height: 64),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 12,
                  top: 40,
                  child: Transform.translate(
                    offset: Offset(0, parallaxIcons * 0.15),
                    child: SvgPicture.asset(
                      assetPath('images/landing/1-bg-magic.svg'),
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
                Positioned(
                  left: 96,
                  top: 180,
                  child: Transform.translate(
                    offset: Offset(0, parallaxIcons * 0.12),
                    child: SvgPicture.asset(
                      assetPath('images/landing/1-bg-user.svg'),
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: 160,
                  child: Transform.translate(
                    offset: Offset(0, parallaxIcons * 0.18),
                    child: SvgPicture.asset(
                      assetPath('images/landing/1-bg-network.svg'),
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 60,
                  child: Transform.translate(
                    offset: Offset(0, parallaxIcons * 0.1),
                    child: SvgPicture.asset(
                      assetPath('images/landing/1-bg-cup.svg'),
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
                Column(
                  children: [
                    AppBadge(
                      borderColor: const Color(0xFF171717),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            assetPath('images/landing/1-tag-icon.svg'),
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            HERO.label,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
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
                          .map(
                            (line) => Text(
                              line,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF303030),
                              ),
                            ),
                          )
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
        Column(
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
                  const Text(
                    'dinq.me/',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _claimController,
                      decoration: const InputDecoration(
                        hintText: 'yourname',
                        border: InputBorder.none,
                      ),
                      onChanged: _onClaimChanged,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleClaim(context),
                    ),
                  ),
                  if (!isNarrow) buildClaimButton(),
                ],
              ),
            ),
            if (_claimWarning.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _claimWarning,
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        if (isNarrow) ...[const SizedBox(height: 12), buildClaimButton(fullWidth: true)],
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

  void _onClaimChanged(String raw) {
    final sanitized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final hasInvalidChars = raw != sanitized;
    if (sanitized != raw) {
      _claimController.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
    setState(() {
      _claimUsername = sanitized;
      _claimWarning = hasInvalidChars ? 'Only letters, numbers, _ and - are allowed' : '';
    });
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
          icon: SvgPicture.asset(
            assetPath('images/card/dinq-card-white.svg'),
            width: 24,
            height: 24,
          ),
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
      context.push('/signin?redirect=$redirect');
      return;
    }
    if (username.isEmpty) {
      context.go('/generation');
      return;
    }
    context.go('/generation?domain=$username');
  }

  Widget _buildTabsSection(double progress) {
    final scale = lerpDouble(0.85, 1.0, progress) ?? 1;
    final translateY = lerpDouble(100, 0, progress) ?? 0;
    final opacity = lerpDouble(0.3, 1.0, progress) ?? 1;

    return Container(
      key: _tabsKey,
      width: double.infinity,
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
      child: Column(
        children: [
          Transform.translate(
            offset: Offset(0, translateY * 0.35),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: const TitleBlock(title: 'AI Career Agent\nfor you'),
              ),
            ),
          ),
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

  Widget _buildRolesSection(double progress) {
    final translateY = lerpDouble(60, 0, progress) ?? 0;
    final opacity = lerpDouble(0.3, 1.0, progress) ?? 1;
    final line1X = lerpDouble(-120, 0, (progress / 0.6).clamp(0.0, 1.0)) ?? 0;
    final delayedProgress = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
    final line2X = lerpDouble(120, 0, delayedProgress) ?? 0;

    return Container(
      key: _rolesKey,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Transform.translate(
            offset: Offset(0, translateY),
            child: Opacity(
              opacity: opacity,
              child: Column(
                children: [
                  Transform.translate(
                    offset: Offset(line1X, 0),
                    child: const Text(
                      'Designed for',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Editor Note',
                        fontSize: 42,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Transform.translate(
                    offset: Offset(line2X, 0),
                    child: const Text(
                      'AI-era Professionals',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Editor Note',
                        fontSize: 42,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          RolesMarquee(items: ROLES),
        ],
      ),
    );
  }

  Widget _buildCtaSection(
    BuildContext context,
    bool isAuthenticated,
    bool hasFlow,
    double progress,
  ) {
    final cardScale = lerpDouble(0.85, 1.0, progress) ?? 1;
    final cardTranslateY = lerpDouble(80, 0, progress) ?? 0;
    final cardRotation = lerpDouble(-15, -5.6, progress) ?? -5.6;
    final cardOpacity = lerpDouble(0.5, 1.0, progress) ?? 1;
    final handX = lerpDouble(0, 36, progress) ?? 0;
    final handY = lerpDouble(0, 48, progress) ?? 0;
    final titleOffset = lerpDouble(24, 0, progress) ?? 0;
    final buttonOffset = lerpDouble(32, 0, progress) ?? 0;

    return RadiantBackground(
      key: _ctaKey,
      child: Center(
        child: Transform.translate(
          offset: Offset(0, cardTranslateY),
          child: Transform.rotate(
            angle: cardRotation * 0.0174533,
            child: Transform.scale(
              scale: cardScale,
              alignment: Alignment.center,
              child: Opacity(
                opacity: cardOpacity,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 780),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF171717)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF171717),
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              style: const TextStyle(
                                letterSpacing: 3,
                                fontSize: 12,
                                color: Color(0xFF303030),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Transform.translate(
                            offset: Offset(0, titleOffset),
                            child: Text(
                              CTA.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Editor Note',
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(width: 1, height: 60, color: const Color(0xFF171717)),
                          const SizedBox(height: 16),
                          Transform.translate(
                            offset: Offset(0, buttonOffset),
                            child: ElevatedButton(
                              onPressed: () => isAuthenticated && hasFlow
                                  ? context.go('/admin/mydinq')
                                  : _handleClaim(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF171717),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(isAuthenticated && hasFlow ? 'My DINQ' : CTA.buttonLabel),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: -20 + handX,
                        bottom: -30 + handY,
                        child: Transform.scale(
                          scale: lerpDouble(0.95, 1.0, progress) ?? 1,
                          child: const HandDecoration(size: 140),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  Widget _buildFaqSection(double progress) {
    final displayFaqs = _faqExpanded ? FAQ : FAQ.take(5).toList();
    final titleOffset = lerpDouble(30, 0, progress) ?? 0;
    final listOffset = lerpDouble(30, 0, progress) ?? 0;
    final opacity = lerpDouble(0.3, 1.0, progress) ?? 1;
    return Container(
      key: _faqKey,
      width: double.infinity,
      color: const Color(0xFFEDEDE5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Transform.translate(
            offset: Offset(0, titleOffset),
            child: Opacity(
              opacity: opacity,
              child: const TitleBlock(title: 'Frequently\nAsked Questions'),
            ),
          ),
          const SizedBox(height: 24),
          Transform.translate(
            offset: Offset(0, listOffset),
            child: Opacity(
              opacity: opacity,
              child: ExpansionPanelList.radio(
                children: displayFaqs
                    .map(
                      (item) => ExpansionPanelRadio(
                        value: item.question,
                        headerBuilder: (context, isExpanded) => ListTile(
                          title: Text(
                            item.question,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        body: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            item.answer,
                            style: const TextStyle(color: Color(0xFF4B5563)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
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

  Widget _buildClosingSection(double progress) {
    final translateY = lerpDouble(40, 0, progress) ?? 0;
    return Container(
      key: _closingKey,
      width: double.infinity,
      color: const Color(0xFFBDCFD8),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Transform.translate(
          offset: Offset(0, translateY),
          child: SizedBox(
            height: 240,
            child: const LottieView(asset: 'animations/Footer-Logo.json'),
          ),
        ),
      ),
    );
  }

  double _sectionProgress(GlobalKey key, double viewportHeight) {
    final ctx = key.currentContext;
    if (ctx == null) return 0;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 0;
    final position = box.localToGlobal(Offset.zero);
    final top = position.dy;
    final height = box.size.height;
    final start = viewportHeight;
    final end = -height;
    final progress = ((start - top) / (start - end)).clamp(0.0, 1.0);
    return progress;
  }
}
