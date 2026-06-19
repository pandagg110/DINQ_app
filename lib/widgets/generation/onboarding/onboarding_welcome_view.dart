import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum OnboardingWelcomeStatus { saving, ready, error }

/// 对齐 Web `/onboarding/welcome/page.tsx`。
class OnboardingWelcomeView extends StatefulWidget {
  const OnboardingWelcomeView({
    super.key,
    required this.status,
    required this.handle,
    this.errorMessage,
    this.shouldUploadAgain = false,
    required this.onRetry,
    required this.onGoSocials,
    required this.onGoMydinq,
    this.orgName,
    this.onGoOrg,
  });

  final OnboardingWelcomeStatus status;
  final String handle;
  final String? errorMessage;
  final bool shouldUploadAgain;
  final VoidCallback onRetry;
  final VoidCallback onGoSocials;
  final VoidCallback onGoMydinq;
  final String? orgName;
  final VoidCallback? onGoOrg;

  @override
  State<OnboardingWelcomeView> createState() => _OnboardingWelcomeViewState();
}

class _OnboardingWelcomeViewState extends State<OnboardingWelcomeView> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
    if (widget.status == OnboardingWelcomeStatus.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _playConfetti());
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingWelcomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != OnboardingWelcomeStatus.ready &&
        widget.status == OnboardingWelcomeStatus.ready) {
      _playConfetti();
    }
  }

  void _playConfetti() {
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _copyLink() async {
    if (widget.handle.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: 'https://dinq.me/${widget.handle}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.status == OnboardingWelcomeStatus.ready)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.15,
              colors: const [
                Color(0xFFFFD700),
                Color(0xFFFF6B6B),
                Color(0xFF4ECDC4),
                Color(0xFF45B7D1),
                Color(0xFF96CEB4),
                Color(0xFFFFEAA7),
              ],
            ),
          ),
        switch (widget.status) {
          OnboardingWelcomeStatus.saving => _SavingView(
              hasOrg: widget.orgName != null && widget.orgName!.isNotEmpty,
            ),
          OnboardingWelcomeStatus.error => _ErrorView(
              message: widget.errorMessage ?? 'Failed to finish onboarding',
              shouldUploadAgain: widget.shouldUploadAgain,
              onRetry: widget.onRetry,
            ),
          OnboardingWelcomeStatus.ready => widget.orgName != null &&
                  widget.orgName!.isNotEmpty
              ? _OrgReadyView(
                  orgName: widget.orgName!,
                  onGoOrg: widget.onGoOrg ?? widget.onGoMydinq,
                  onGoMydinq: widget.onGoMydinq,
                )
              : _ReadyView(
                  handle: widget.handle,
                  onCopyLink: _copyLink,
                  onGoSocials: widget.onGoSocials,
                  onGoMydinq: widget.onGoMydinq,
                ),
        },
      ],
    );
  }
}

class _SavingView extends StatelessWidget {
  const _SavingView({required this.hasOrg});

  final bool hasOrg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF171717),
                  backgroundColor: Color(0xFFDCD9D2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Finishing onboarding',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasOrg
                    ? "We're saving your DINQ Page and accepting your invite."
                    : "We're saving your DINQ Page.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6862),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.shouldUploadAgain,
    required this.onRetry,
  });

  final String message;
  final bool shouldUploadAgain;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade700, size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                "We couldn't finish onboarding",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6862),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    shouldUploadAgain ? 'Upload resume again' : 'Try again',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.handle,
    required this.onCopyLink,
    required this.onGoSocials,
    required this.onGoMydinq,
  });

  final String handle;
  final VoidCallback onCopyLink;
  final VoidCallback onGoSocials;
  final VoidCallback onGoMydinq;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              const Text(
                '🎉 Your DINQ Page is live!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                  height: 1.2,
                ),
              ),
              if (handle.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFEEEDE9)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, size: 16, color: Color(0xFF9E9B93)),
                      const SizedBox(width: 8),
                      Text(
                        'dinq.me/$handle',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: const Color(0xFF171717),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: onCopyLink,
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Copy link',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NEXT UP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: Color(0xFF9E9B93),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onGoSocials,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEDE9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEE8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.link, color: Color(0xFF6B6862)),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add social links',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF171717),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Connect your Instagram, Twitter, and other profiles.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9E9B93),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF9E9B93)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onGoMydinq,
                child: const Text(
                  "I'll do this later",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B6862)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgReadyView extends StatelessWidget {
  const _OrgReadyView({
    required this.orgName,
    required this.onGoOrg,
    required this.onGoMydinq,
  });

  final String orgName;
  final VoidCallback onGoOrg;
  final VoidCallback onGoMydinq;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Text(
                'Welcome to $orgName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "You've successfully joined and your DINQ page is live.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B6862)),
              ),
              const SizedBox(height: 32),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onGoOrg,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEDE9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEE8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              orgName.isNotEmpty
                                  ? orgName[0].toUpperCase()
                                  : 'O',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B6862),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Go to $orgName',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF171717),
                            ),
                          ),
                        ),
                        const Icon(Icons.north_east, size: 16, color: Color(0xFF9E9B93)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onGoMydinq,
                child: const Text(
                  'Edit my DINQ Page →',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B6862)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
