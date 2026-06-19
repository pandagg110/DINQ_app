import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../widgets/common/base_page.dart';
import 'onboarding_icons.dart';
import 'onboarding_secondary_card.dart';

/// 组织上下文（对齐 Web `OnboardingContext` 展示字段）。
class OnboardingOrgContext {
  const OnboardingOrgContext({
    this.orgName,
    this.orgLogoUrl,
    this.orgMemberCount,
  });

  final String? orgName;
  final String? orgLogoUrl;
  final int? orgMemberCount;

  bool get hasOrg => orgName != null && orgName!.isNotEmpty;
}

/// 移动端：选项列表；桌面端：Web `/onboarding/start` 布局。
class OnboardingStartView extends StatefulWidget {
  const OnboardingStartView({
    super.key,
    required this.urlController,
    required this.error,
    this.orgContext,
    required this.onGenerate,
    required this.onUploadResume,
    required this.onStartManual,
    required this.onSkip,
    this.onBack,
  });

  final TextEditingController urlController;
  final String? error;
  final OnboardingOrgContext? orgContext;
  final VoidCallback onGenerate;
  final VoidCallback onUploadResume;
  final VoidCallback onStartManual;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  static const _textPrimary = Color(0xFF171717);
  static const _textSecondary = Color(0xFF6B6862);
  static const _border = Color(0xFFEEEDE9);

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  @override
  State<OnboardingStartView> createState() => _OnboardingStartViewState();
}

class _OnboardingStartViewState extends State<OnboardingStartView> {
  bool _showLinkedInEntry = false;

  @override
  Widget build(BuildContext context) {
    if (OnboardingStartView._isMobile(context)) {
      if (_showLinkedInEntry) {
        return _MobileLinkedInEntry(
          urlController: widget.urlController,
          error: widget.error,
          onBack: () => setState(() => _showLinkedInEntry = false),
          onGenerate: widget.onGenerate,
        );
      }
      return _MobileStartLayout(
        orgContext: widget.orgContext,
        onBack: widget.onBack,
        onLinkedIn: () => setState(() => _showLinkedInEntry = true),
        onUploadResume: widget.onUploadResume,
        onStartManual: widget.onStartManual,
      );
    }
    return _DesktopStartLayout(
      urlController: widget.urlController,
      error: widget.error,
      orgContext: widget.orgContext,
      onGenerate: widget.onGenerate,
      onUploadResume: widget.onUploadResume,
      onStartManual: widget.onStartManual,
      onSkip: widget.onSkip,
    );
  }
}

/// 移动端首屏：三卡片列表（对齐设计稿）。
class _MobileStartLayout extends StatelessWidget {
  const _MobileStartLayout({
    this.orgContext,
    this.onBack,
    required this.onLinkedIn,
    required this.onUploadResume,
    required this.onStartManual,
  });

  final OnboardingOrgContext? orgContext;
  final VoidCallback? onBack;
  final VoidCallback onLinkedIn;
  final VoidCallback onUploadResume;
  final VoidCallback onStartManual;

  @override
  Widget build(BuildContext context) {
    final org = orgContext;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _CircleBackButton(onTap: onBack ?? () => Navigator.maybePop(context)),
          ),
          const SizedBox(height: 24),
          if (org?.hasOrg == true) ...[
            _OrgHeader(org: org!),
            const SizedBox(height: 24),
          ],
          Text(
            org?.hasOrg == true ? 'Create a DINQ Page and Join' : 'Create your DINQ Page',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: OnboardingStartView._textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            org?.hasOrg == true
                ? 'Get started — choose a method'
                : "Choose how you'd like to get started with DINQ.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: OnboardingStartView._textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          _MobileOptionCard(
            onTap: onLinkedIn,
            icon: _LinkedInIconBadge(),
            title: 'Import from LinkedIn',
            subtitle: 'Fastest and most comprehensive',
          ),
          const SizedBox(height: 12),
          _MobileOptionCard(
            onTap: onUploadResume,
            icon: _TintedIconBadge(
              backgroundColor: Color(0xFFEAF3FF),
              child: OnboardingSvgIcon(
                OnboardingIcons.fileUp,
                size: 22,
                color: Color(0xFF2563EB),
              ),
            ),
            title: 'Upload Resume',
            subtitle: 'Parse a PDF or Word doc',
          ),
          const SizedBox(height: 12),
          _MobileOptionCard(
            onTap: onStartManual,
            icon: _TintedIconBadge(
              backgroundColor: Color(0xFFFFF0E6),
              child: OnboardingSvgIcon(
                OnboardingIcons.userPlus,
                size: 22,
                color: Color(0xFFE87A35),
              ),
            ),
            title: 'Start from Scratch',
            subtitle: 'Build manually step by step',
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: AssetImageView('nav_back', width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}

class _MobileOptionCard extends StatelessWidget {
  const _MobileOptionCard({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final Widget icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: OnboardingStartView._textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: OnboardingStartView._textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const OnboardingSvgIcon(
                  OnboardingIcons.chevronRight,
                  size: 18,
                  color: Color(0xFFD1D5DB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkedInIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SvgPicture.asset(
        OnboardingIcons.linkedin,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _TintedIconBadge extends StatelessWidget {
  const _TintedIconBadge({required this.backgroundColor, required this.child});

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// 移动端 LinkedIn URL 输入（点击首屏卡片后）。
class _MobileLinkedInEntry extends StatelessWidget {
  const _MobileLinkedInEntry({
    required this.urlController,
    required this.error,
    required this.onBack,
    required this.onGenerate,
  });

  final TextEditingController urlController;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _CircleBackButton(onTap: onBack),
          ),
          const SizedBox(height: 24),
          const Text(
            'Import from LinkedIn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: OnboardingStartView._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Or any personal website',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15,
              color: OnboardingStartView._textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _LinkedInHeroCard(
            urlController: urlController,
            error: error,
            isMobile: true,
            onGenerate: onGenerate,
            showRecommendedBadge: true,
          ),
        ],
      ),
    );
  }
}

/// 桌面端 Web 布局。
class _DesktopStartLayout extends StatelessWidget {
  const _DesktopStartLayout({
    required this.urlController,
    required this.error,
    this.orgContext,
    required this.onGenerate,
    required this.onUploadResume,
    required this.onStartManual,
    required this.onSkip,
  });

  final TextEditingController urlController;
  final String? error;
  final OnboardingOrgContext? orgContext;
  final VoidCallback onGenerate;
  final VoidCallback onUploadResume;
  final VoidCallback onStartManual;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final org = orgContext;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (org?.hasOrg == true) ...[
                _OrgHeader(org: org!),
                const SizedBox(height: 40),
              ],
              _TitleSection(hasOrg: org?.hasOrg == true, isMobile: false),
              const SizedBox(height: 40),
              _LinkedInHeroCard(
                urlController: urlController,
                error: error,
                isMobile: false,
                onGenerate: onGenerate,
                showRecommendedBadge: true,
              ),
              const SizedBox(height: 40),
              const _OtherOptionsDivider(),
              const SizedBox(height: 16),
              _SecondaryOptions(
                isMobile: false,
                onUploadResume: onUploadResume,
                onStartManual: onStartManual,
              ),
              const SizedBox(height: 24),
              _SkipButton(
                hasOrg: org?.hasOrg == true,
                isMobile: false,
                onSkip: onSkip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgHeader extends StatelessWidget {
  const _OrgHeader({required this.org});

  final OnboardingOrgContext org;

  @override
  Widget build(BuildContext context) {
    final name = org.orgName!;
    return Column(
      children: [
        if (org.orgLogoUrl != null && org.orgLogoUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              org.orgLogoUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _OrgLogoFallback(name: name),
            ),
          )
        else
          _OrgLogoFallback(name: name),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: OnboardingStartView._textPrimary,
          ),
        ),
        if (org.orgMemberCount != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OnboardingSvgIcon(OnboardingIcons.users, size: 14),
              const SizedBox(width: 4),
              Text(
                '${org.orgMemberCount} members joined',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: OnboardingStartView._textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OrgLogoFallback extends StatelessWidget {
  const _OrgLogoFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEE8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B6862),
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.hasOrg, required this.isMobile});

  final bool hasOrg;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          hasOrg ? 'Create a DINQ Page and Join' : 'Create your DINQ Page',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: OnboardingStartView._textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hasOrg
              ? 'Get started — choose a method'
              : "Choose how you'd like to get started with DINQ.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: OnboardingStartView._textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _LinkedInHeroCard extends StatelessWidget {
  const _LinkedInHeroCard({
    required this.urlController,
    required this.error,
    required this.isMobile,
    required this.onGenerate,
    this.showRecommendedBadge = false,
  });

  final TextEditingController urlController;
  final String? error;
  final bool isMobile;
  final VoidCallback onGenerate;
  final bool showRecommendedBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OnboardingStartView._border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isMobile) ...[
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SvgPicture.asset(
                        OnboardingIcons.linkedin,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import from LinkedIn',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: OnboardingStartView._textPrimary,
                            ),
                          ),
                          Text(
                            'Or any personal website',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 14,
                              color: OnboardingStartView._textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (isMobile) ...[
                _UrlField(urlController: urlController, error: error, onSubmit: onGenerate),
                const SizedBox(height: 12),
                _GenerateButton(onGenerate: onGenerate),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _UrlField(
                        urlController: urlController,
                        error: error,
                        onSubmit: onGenerate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _GenerateButton(onGenerate: onGenerate),
                  ],
                ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const OnboardingSvgIcon(
                      OnboardingIcons.alertCircle,
                      size: 14,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (showRecommendedBadge && !isMobile)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF6D4),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('👍', style: TextStyle(fontSize: 11)),
                  SizedBox(width: 4),
                  Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8B6B00),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _UrlField extends StatelessWidget {
  const _UrlField({
    required this.urlController,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController urlController;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: urlController,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 14,
        color: OnboardingStartView._textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'https://linkedin.com/in/... or any URL',
        hintStyle: TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          color: const Color(0xFF303030).withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: error != null ? Colors.red : OnboardingStartView._border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: error != null ? Colors.red : OnboardingStartView._border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: error != null ? Colors.red : OnboardingStartView._textPrimary,
          ),
        ),
        isDense: true,
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onGenerate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF171717),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Generate Page',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Text('→', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _OtherOptionsDivider extends StatelessWidget {
  const _OtherOptionsDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: OnboardingStartView._border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OTHER OPTIONS',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: Color(0xFF9E9B93),
            ),
          ),
        ),
        Expanded(child: Divider(color: OnboardingStartView._border, height: 1)),
      ],
    );
  }
}

class _SecondaryOptions extends StatelessWidget {
  const _SecondaryOptions({
    required this.isMobile,
    required this.onUploadResume,
    required this.onStartManual,
  });

  final bool isMobile;
  final VoidCallback onUploadResume;
  final VoidCallback onStartManual;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        OnboardingSecondaryCard(
          iconAsset: OnboardingIcons.fileUp,
          title: 'Upload Resume',
          description: 'Parse a PDF resume',
          onTap: onUploadResume,
        ),
        OnboardingSecondaryCard(
          iconAsset: OnboardingIcons.pencilLine,
          title: 'Start from Scratch',
          description: 'Build manually step by step',
          onTap: onStartManual,
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.hasOrg,
    required this.isMobile,
    required this.onSkip,
  });

  final bool hasOrg;
  final bool isMobile;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final label = hasOrg
        ? 'Skip all steps, go straight to your page and join'
        : 'Skip all steps and go straight to your page';

    return TextButton(
      onPressed: onSkip,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6B6862),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text('→', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
