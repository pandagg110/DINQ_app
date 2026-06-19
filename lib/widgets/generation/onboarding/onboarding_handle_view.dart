import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onboarding_step_header.dart';

/// 对齐 Web `/onboarding/handle/page.tsx`。
class OnboardingHandleView extends StatelessWidget {
  const OnboardingHandleView({
    super.key,
    required this.controller,
    required this.orgName,
    required this.isChecking,
    required this.isReserving,
    required this.isTooShort,
    required this.isTaken,
    required this.isAvailable,
    this.charWarning,
    this.suggestions = const [],
    required this.onChanged,
    required this.onClaim,
    this.onBack,
  });

  final TextEditingController controller;
  final String? orgName;
  final bool isChecking;
  final bool isReserving;
  final bool isTooShort;
  final bool isTaken;
  final bool isAvailable;
  final String? charWarning;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClaim;
  final VoidCallback? onBack;

  bool get _canClaim =>
      isAvailable && controller.text.trim().length >= 3 && !isReserving;

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  @override
  Widget build(BuildContext context) {
    if (_isMobile(context)) {
      return _MobileHandleLayout(
        controller: controller,
        orgName: orgName,
        isChecking: isChecking,
        isReserving: isReserving,
        isTooShort: isTooShort,
        isTaken: isTaken,
        isAvailable: isAvailable,
        charWarning: charWarning,
        suggestions: suggestions,
        onChanged: onChanged,
        onClaim: _canClaim ? onClaim : null,
        onBack: onBack,
      );
    }
    return _DesktopHandleLayout(
      controller: controller,
      orgName: orgName,
      isChecking: isChecking,
      isReserving: isReserving,
      isTooShort: isTooShort,
      isTaken: isTaken,
      isAvailable: isAvailable,
      charWarning: charWarning,
      suggestions: suggestions,
      onChanged: onChanged,
      onClaim: _canClaim ? onClaim : null,
      onBack: onBack,
    );
  }
}

class _HandleForm extends StatelessWidget {
  const _HandleForm({
    required this.controller,
    required this.orgName,
    required this.isChecking,
    required this.isTooShort,
    required this.isTaken,
    required this.isAvailable,
    this.charWarning,
    this.suggestions = const [],
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? orgName;
  final bool isChecking;
  final bool isTooShort;
  final bool isTaken;
  final bool isAvailable;
  final String? charWarning;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  Color get _borderColor {
    if (isTooShort || isTaken) return const Color(0xFFEF4444);
    if (isAvailable) return const Color(0xFF3C7B4D);
    return const Color(0xFFEEEDE9);
  }

  @override
  Widget build(BuildContext context) {
    final description = orgName != null && orgName!.isNotEmpty
        ? 'Your DINQ handle is your personal page — and your pass to join '
            '$orgName. Pick a unique link that represents you.'
        : 'This is your permanent home on the internet. Choose a unique link '
            'to share your DINQ profile with the world.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(step: 3),
        const SizedBox(height: 24),
        const Text(
          'Claim your handle',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF6B6862),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Your unique URL',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B6862),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              const Text(
                'dinq.me/',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF171717),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                    LengthLimitingTextInputFormatter(100),
                  ],
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: Color(0xFF171717),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'yourname',
                    hintStyle: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      color: Color.fromRGBO(48, 48, 48, 0.4),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    isDense: true,
                  ),
                ),
              ),
              if (isChecking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (isAvailable && !isChecking)
                const Icon(Icons.check_circle,
                    size: 16, color: Color(0xFF3C7B4D)),
            ],
          ),
        ),
        if (charWarning != null && charWarning!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            charWarning!,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFFD97706),
            ),
          ),
        ],
        if (isTooShort) ...[
          const SizedBox(height: 8),
          const Text(
            'Handle must be at least 3 characters.',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
        if (isTaken) ...[
          const SizedBox(height: 8),
          const Text(
            'This handle is already taken.',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
        if (isAvailable) ...[
          const SizedBox(height: 8),
          const Text(
            'Available — claim it before someone else does!',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFF3C7B4D),
            ),
          ),
        ],
        if (isTaken && suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Available suggestions',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFF6B6862),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return OutlinedButton(
                onPressed: () => onChanged(s),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: Color(0xFFEEEDE9)),
                  foregroundColor: const Color(0xFF6B6862),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  s,
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _MobileHandleLayout extends StatelessWidget {
  const _MobileHandleLayout({
    required this.controller,
    required this.orgName,
    required this.isChecking,
    required this.isReserving,
    required this.isTooShort,
    required this.isTaken,
    required this.isAvailable,
    this.charWarning,
    this.suggestions = const [],
    required this.onChanged,
    required this.onClaim,
    this.onBack,
  });

  final TextEditingController controller;
  final String? orgName;
  final bool isChecking;
  final bool isReserving;
  final bool isTooShort;
  final bool isTaken;
  final bool isAvailable;
  final String? charWarning;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClaim;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _HandleForm(
              controller: controller,
              orgName: orgName,
              isChecking: isChecking,
              isTooShort: isTooShort,
              isTaken: isTaken,
              isAvailable: isAvailable,
              charWarning: charWarning,
              suggestions: suggestions,
              onChanged: onChanged,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPad),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: onClaim != null
                    ? const Color(0xFF171717)
                    : const Color(0xFFE5E5E5),
                foregroundColor: onClaim != null
                    ? Colors.white
                    : const Color.fromRGBO(48, 48, 48, 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isReserving ? 'Claiming...' : 'Claim it →',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopHandleLayout extends StatelessWidget {
  const _DesktopHandleLayout({
    required this.controller,
    required this.orgName,
    required this.isChecking,
    required this.isReserving,
    required this.isTooShort,
    required this.isTaken,
    required this.isAvailable,
    this.charWarning,
    this.suggestions = const [],
    required this.onChanged,
    required this.onClaim,
    this.onBack,
  });

  final TextEditingController controller;
  final String? orgName;
  final bool isChecking;
  final bool isReserving;
  final bool isTooShort;
  final bool isTaken;
  final bool isAvailable;
  final String? charWarning;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClaim;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            children: [
              _HandleForm(
                controller: controller,
                orgName: orgName,
                isChecking: isChecking,
                isTooShort: isTooShort,
                isTaken: isTaken,
                isAvailable: isAvailable,
                charWarning: charWarning,
                suggestions: suggestions,
                onChanged: onChanged,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onBack != null)
                    TextButton(
                      onPressed: onBack,
                      child: const Text(
                        '← Back',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          color: Color(0xFF6B6862),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: onClaim != null
                            ? const Color(0xFF171717)
                            : const Color(0xFFE5E5E5),
                        foregroundColor: onClaim != null
                            ? Colors.white
                            : const Color.fromRGBO(48, 48, 48, 0.4),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isReserving ? 'Claiming...' : 'Claim it →',
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
