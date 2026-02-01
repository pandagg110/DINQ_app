import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/card_models.dart';
import '../../cards/factory/card_definition.dart';
import '../../../stores/card_store.dart';
import 'card_form_base.dart';

/// Network (ACHIEVEMENT_NETWORK) 类型的表单：GitHub、Google Scholar、LinkedIn、OpenReview URL 输入
class NetworkForm extends CardFormBase {
  final GlobalKey<_NetworkFormContentState> _formKey = GlobalKey<_NetworkFormContentState>();

  CardItem? _findCard(List<CardItem> cards, String type) {
    final matches = cards.where((c) => c.data.type.toUpperCase() == type).toList();
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context, CardDefinition definition) {
    final cardStore = context.read<CardStore>();
    final cards = cardStore.cards;

    final githubCard = _findCard(cards, 'GITHUB');
    final scholarCard = _findCard(cards, 'SCHOLAR');
    final linkedinCard = _findCard(cards, 'LINKEDIN');
    final openReviewCard = _findCard(cards, 'OPENREVIEW');

    final initialUrls = (
      github: (githubCard?.data.metadata['url'] ?? '').toString().trim(),
      googleScholar: (scholarCard?.data.metadata['url'] ?? '').toString().trim(),
      linkedin: (linkedinCard?.data.metadata['url'] ?? '').toString().trim(),
      openReview: (openReviewCard?.data.metadata['url'] ?? '').toString().trim(),
    );

    return _NetworkFormContent(
      key: _formKey,
      initialUrls: initialUrls,
    );
  }

  @override
  Future<Map<String, dynamic>?> getFormData() async {
    return _formKey.currentState?.getData();
  }
}

class _NetworkFormContent extends StatefulWidget {
  const _NetworkFormContent({
    super.key,
    required this.initialUrls,
  });

  final ({String github, String googleScholar, String linkedin, String openReview}) initialUrls;

  @override
  State<_NetworkFormContent> createState() => _NetworkFormContentState();
}

class _NetworkFormContentState extends State<_NetworkFormContent> {
  late final TextEditingController _githubController;
  late final TextEditingController _googleScholarController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _openReviewController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _githubController = TextEditingController(text: widget.initialUrls.github);
    _googleScholarController = TextEditingController(text: widget.initialUrls.googleScholar);
    _linkedinController = TextEditingController(text: widget.initialUrls.linkedin);
    _openReviewController = TextEditingController(text: widget.initialUrls.openReview);
  }

  @override
  void dispose() {
    _githubController.dispose();
    _googleScholarController.dispose();
    _linkedinController.dispose();
    _openReviewController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getData() async {
    final urls = <String>[];
    if (_githubController.text.trim().isNotEmpty) urls.add(_githubController.text.trim());
    if (_googleScholarController.text.trim().isNotEmpty) urls.add(_googleScholarController.text.trim());
    if (_linkedinController.text.trim().isNotEmpty) urls.add(_linkedinController.text.trim());
    if (_openReviewController.text.trim().isNotEmpty) urls.add(_openReviewController.text.trim());

    if (urls.isEmpty) {
      setState(() => _error = 'Please enter at least 1 social account URL.');
      return null;
    }
    return {'urls': urls};
  }

  void _onChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      hintStyle: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 14,
        color: Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF171717), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField('GitHub', 'Enter GitHub URL', _githubController, inputDecoration),
          const SizedBox(height: 16),
          _buildField('Google Scholar', 'Enter Google Scholar URL', _googleScholarController, inputDecoration),
          const SizedBox(height: 16),
          _buildField('LinkedIn', 'Enter LinkedIn URL', _linkedinController, inputDecoration),
          const SizedBox(height: 16),
          _buildField('OpenReview', 'Enter OpenReview URL', _openReviewController, inputDecoration),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'The more social accounts you add, the more accurate the network analysis will be. '
              'Please enter at least 1 social account URL.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller,
    InputDecoration decoration,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: decoration.copyWith(hintText: hint),
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF171717),
          ),
          onChanged: (_) => _onChanged(),
        ),
      ],
    );
  }
}
