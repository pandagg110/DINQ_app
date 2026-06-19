import 'package:flutter/material.dart';

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

const _tagLimit = 10;
const _bioLimit = 280;
const _tagCharLimit = 24;

/// 对齐 Web `/onboarding/profile/expertise/page.tsx`。
class OnboardingProfileExpertiseView extends StatefulWidget {
  const OnboardingProfileExpertiseView({
    super.key,
    required this.tags,
    required this.bio,
    required this.onTagsChanged,
    required this.onBioChanged,
    required this.onBack,
    required this.onContinue,
  });

  final List<String> tags;
  final String bio;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<String> onBioChanged;
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
    final tags = List<String>.from(widget.tags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else if (tags.length < _tagLimit) {
      tags.add(tag);
    }
    widget.onTagsChanged(tags);
  }

  void _addCustomTag() {
    final raw = _customTagController.text
        .replaceAll(RegExp(r'[\r\n,]+'), ' ')
        .trim();
    if (raw.isEmpty || widget.tags.length >= _tagLimit) return;
    final tag =
        raw.length > _tagCharLimit ? raw.substring(0, _tagCharLimit) : raw;
    if (widget.tags.contains(tag)) return;
    widget.onTagsChanged([...widget.tags, tag]);
    _customTagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingTopBar(step: 2, onBack: widget.onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
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
                  'Expertise tags (${widget.tags.length}/$_tagLimit)',
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
                    final active = widget.tags.contains(tag);
                    final disabled =
                        !active && widget.tags.length >= _tagLimit;
                    return FilterChip(
                      label: Text(tag),
                      selected: active,
                      onSelected: disabled ? null : (_) => _toggleTag(tag),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        color:
                            active ? Colors.white : const Color(0xFF6B6862),
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF171717),
                      side: BorderSide(
                        color: active
                            ? const Color(0xFF171717)
                            : const Color(0xFFEEEDE9),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
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
                        maxLength: _tagCharLimit,
                        enabled: widget.tags.length < _tagLimit,
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
                            borderSide:
                                const BorderSide(color: Color(0xFFEEEDE9)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFEEEDE9)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFF171717)),
                          ),
                        ),
                        onSubmitted: (_) => _addCustomTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: widget.tags.length >= _tagLimit ||
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
                  maxLength: _bioLimit,
                  onChanged: widget.onBioChanged,
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
              onPressed: widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
                foregroundColor: Colors.white,
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
