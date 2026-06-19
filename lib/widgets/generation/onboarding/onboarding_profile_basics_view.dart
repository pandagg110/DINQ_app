import 'package:flutter/material.dart';

import 'onboarding_top_bar.dart';

/// 对齐 Web `/onboarding/profile/basics/page.tsx`（核心字段）。
class OnboardingProfileBasicsView extends StatefulWidget {
  const OnboardingProfileBasicsView({
    super.key,
    required this.nameController,
    required this.positionController,
    required this.companyController,
    required this.locationController,
    required this.onBack,
    required this.onContinue,
  });

  final TextEditingController nameController;
  final TextEditingController positionController;
  final TextEditingController companyController;
  final TextEditingController locationController;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<OnboardingProfileBasicsView> createState() =>
      _OnboardingProfileBasicsViewState();
}

class _OnboardingProfileBasicsViewState
    extends State<OnboardingProfileBasicsView> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingTopBar(step: 1, onBack: widget.onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Basic information',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is the identity block people see first on your DINQ page.',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: Color(0xFF6B6862),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _Field(
                  label: 'Full name',
                  required: true,
                  controller: widget.nameController,
                  placeholder: 'Ada Lovelace',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Position',
                        controller: widget.positionController,
                        placeholder: 'Researcher',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label: 'Company',
                        controller: widget.companyController,
                        placeholder: 'OpenAI',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'Location',
                  controller: widget.locationController,
                  placeholder: 'San Francisco, CA',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPad),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.nameController.text.trim().isEmpty
                  ? null
                  : widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.nameController.text.trim().isEmpty
                    ? const Color(0xFFE5E5E5)
                    : const Color(0xFF171717),
                foregroundColor: widget.nameController.text.trim().isEmpty
                    ? const Color.fromRGBO(48, 48, 48, 0.4)
                    : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue →',
                style: TextStyle(
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.placeholder,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B6862),
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEEEDE9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEEEDE9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF171717)),
            ),
          ),
        ),
      ],
    );
  }
}
