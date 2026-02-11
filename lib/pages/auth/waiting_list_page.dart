import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/waiting_list_service.dart';
import '../../utils/color_util.dart';
import '../../utils/toast_util.dart';
import '../../widgets/common/country_select.dart';

class WaitingListPage extends StatefulWidget {
  const WaitingListPage({super.key});

  @override
  State<WaitingListPage> createState() => _WaitingListPageState();
}

class _WaitingListPageState extends State<WaitingListPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _jobController = TextEditingController();
  final _institutionController = TextEditingController();
  final _schoolController = TextEditingController();
  final WaitingListService _service = WaitingListService();
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _error;
  String? _country;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _jobController.dispose();
    _institutionController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Scaffold(
        appBar: DefaultAppBar(context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: 1),
              Text(
                'Thank you for your interest.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: ColorUtil.textColor,
                  fontFamily: 'Editor Note',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Our team will be in touch shortly.',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorUtil.sub1TextColor,
                  fontFamily: 'Tomato Grotesk',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                child: const Text('Back'),
              ),
              Spacer(flex: 2),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: DefaultAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Join waiting list',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w600,
                fontFamily: "Editor Note",
                color: ColorUtil.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Submit your application. After approval, you will receive an invite code sent to your email.",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Tomato Grotesk",
                color: ColorUtil.sub1TextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              title: 'Email Address',
              isRequired: true,
              controller: _emailController,
              hintText: "name@example.com",
            ),
            const SizedBox(height: 10),
            _buildTextField(
              title: 'Full Name',
              isRequired: true,
              controller: _nameController,
              hintText: "Your full name",
            ),
            const SizedBox(height: 10),
            CountrySelect(
              selectedCountry: _country,
              onCountryChanged: (value) => setState(() => _country = value),
              required: true,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              title: 'Title/Position',
              isRequired: true,
              controller: _jobController,
              hintText: "e.g.Product Manager",
            ),
            const SizedBox(height: 10),
            _buildTextField(
              title: 'Institution/Organization',
              isRequired: true,
              controller: _institutionController,
              hintText: "Your company or organization",
            ),
            const SizedBox(height: 10),
            _buildTextField(
              title: 'School/University',
              isRequired: true,
              controller: _schoolController,
              hintText: "Your school or university",
            ),
            const SizedBox(height: 10),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 10),
            Text(
              "Your information is secure and will only be used to notify you about our launch. Werespect your privacy and won't share your details with third parties.",
              style: TextStyle(
                fontSize: 12,
                color: ColorUtil.sub1TextColor,
                fontFamily: 'Tomato Grotesk',
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? Center(
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String title,
    required bool isRequired,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: ColorUtil.textColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'Tomato Grotesk',
              ),
            ),
            if (isRequired) const Text(' *', style: TextStyle(color: Color(0xFFC81E1D))),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Color(0x66303030), fontSize: 14),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: ColorUtil.textColor, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final jobTitle = _jobController.text.trim();
    final institution = _institutionController.text.trim();

    if (email.isEmpty ||
        fullName.isEmpty ||
        jobTitle.isEmpty ||
        institution.isEmpty ||
        _country == null) {
      setState(() => _error = 'Please fill all required fields.');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      await _service.join({
        'name': fullName,
        'email': email,
        'country': _country,
        'institution': institution,
        'school': _schoolController.text.trim().isEmpty ? null : _schoolController.text.trim(),
        'role': jobTitle,
      });
      setState(() => _isSuccess = true);
    } catch (error) {
      // setState(() => _error = error.toString());
      await ToastUtil.show(error.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
