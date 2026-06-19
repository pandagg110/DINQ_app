import 'package:flutter/material.dart';

import '../../../utils/onboarding_draft_mapping.dart';
import 'onboarding_footer.dart';
import 'onboarding_profile_preview.dart';
import 'onboarding_top_bar.dart';

const _suggestedTags = [
  'AI',
  'LLM',
  'Machine Learning',
  'Python',
  'Research',
  'Product',
  'Frontend',
  'Backend',
  'Data',
  'Design',
  'Robotics',
  'Infra',
];

/// 对齐 Web `/onboarding/profile/expertise/page.tsx`。
class OnboardingProfileExpertiseView extends StatefulWidget {
  const OnboardingProfileExpertiseView({
    super.key,
    required this.tags,
    required this.bio,
    required this.onTagsChanged,
    required this.onBioChanged,
    required this.previewName,
    required this.previewPosition,
    required this.previewCompany,
    required this.previewSchool,
    required this.previewLocation,
    required this.previewTimezone,
    required this.previewAvatarUrl,
    required this.onBack,
    required this.onContinue,
  });

  final List<String> tags;
  final String bio;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<String> onBioChanged;
  final String previewName;
  final String previewPosition;
  final String previewCompany;
  final String previewSchool;
  final String previewLocation;
  final String previewTimezone;
  final String previewAvatarUrl;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<OnboardingProfileExpertiseView> createState() =>
      _OnboardingProfileExpertiseViewState();
}

class _OnboardingProfileExpertiseViewState
    extends State<OnboardingProfileExpertiseView> {
  final _customTagController = TextEditingController();
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.bio);
    _customTagController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant OnboardingProfileExpertiseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bio != widget.bio && _bioController.text != widget.bio) {
      _bioController.text = widget.bio;
    }
  }

  @override
  void dispose() {
    _customTagController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final tags = normalizeProfileTags(widget.tags);
    if (tags.contains(tag)) {
      widget.onTagsChanged(tags.where((item) => item != tag).toList());
    } else if (tags.length < profileTagLimit) {
      widget.onTagsChanged(normalizeProfileTags([...tags, tag]));
    }
  }

  void _addCustomTag() {
    final raw = _customTagController.text
        .replaceAll(RegExp(r'[\r\n,]+'), ' ')
        .trim();
    if (raw.isEmpty) return;
    final tags = normalizeProfileTags(widget.tags);
    if (tags.length >= profileTagLimit) return;
    final nextTags = normalizeProfileTags([...tags, raw]);
    if (nextTags.length == tags.length) return;
    widget.onTagsChanged(nextTags);
    _customTagController.clear();
  }

  OnboardingProfilePreview _buildPreview() {
    return OnboardingProfilePreview(
      name: widget.previewName,
      position: widget.previewPosition,
      company: widget.previewCompany,
      school: widget.previewSchool,
      location: widget.previewLocation,
      timezone: widget.previewTimezone,
      bio: _bioController.text,
      avatarUrl: widget.previewAvatarUrl,
      tags: widget.tags,
    );
  }

  Widget _buildForm() {
    final tags = normalizeProfileTags(widget.tags);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Detailed profile',
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
          'Add the signals that help people understand your work quickly.',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF6B6862),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Expertise tags (${tags.length}/$profileTagLimit)',
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B6862),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedTags.map((tag) {
            final active = tags.contains(tag);
            final disabled = !active && tags.length >= profileTagLimit;
            return Material(
              color: active ? const Color(0xFF171717) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: disabled ? null : () => _toggleTag(tag),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF171717)
                          : const Color(0xFFEEEDE9),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      color: active ? Colors.white : const Color(0xFF6B6862),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customTagController,
                maxLength: profileTagCharLimit,
                enabled: tags.length < profileTagLimit,
                decoration: InputDecoration(
                  hintText: 'Add custom tag',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
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
                onSubmitted: (_) => _addCustomTag(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: tags.length >= profileTagLimit ||
                        _customTagController.text.trim().isEmpty
                    ? null
                    : _addCustomTag,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7F6F2),
                  side: const BorderSide(color: Color(0xFFEEEDE9)),
                  foregroundColor: const Color(0xFF6B6862),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Short bio',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B6862),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLines: 5,
          maxLength: profileBioLimit,
          onChanged: (value) {
            final next = value.length > profileBioLimit
                ? value.substring(0, profileBioLimit)
                : value;
            widget.onBioChanged(next);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText:
                'A concise intro about your work, focus, and current interests.',
            filled: true,
            fillColor: Colors.white,
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
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_bioController.text.length}/$profileBioLimit',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFF9E9B93),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(56, 64, 56, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnboardingTopBar(step: 2, onBack: widget.onBack),
                  const SizedBox(height: 32),
                  _buildForm(),
                  const SizedBox(height: 32),
                  OnboardingDualActionFooter(
                    onBack: widget.onBack,
                    onContinue: widget.onContinue,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFFAFAFA),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
              child: Center(child: _buildPreview()),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingTopBar(step: 2, onBack: widget.onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: _buildForm(),
          ),
        ),
        OnboardingDualActionFooter(
          onBack: widget.onBack,
          onContinue: widget.onContinue,
        ),
      ],
    );
  }
}
