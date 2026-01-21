import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/contact_request_service.dart';
import '../../utils/toast_util.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _jobController = TextEditingController();
  final _affiliationController = TextEditingController();
  final _detailsController = TextEditingController();
  final ContactRequestService _service = ContactRequestService();
  String? _country;
  String? _reason;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _jobController.dispose();
    _affiliationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request a Demo')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thank you for your interest.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('Our team will be in touch shortly.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Request a Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'See DINQ in action',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Work email'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: _countries
                      .map((country) => DropdownMenuItem(value: country, child: Text(country)))
                      .toList(),
                  onChanged: (value) => setState(() => _country = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jobController,
                  decoration: const InputDecoration(labelText: 'Job title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _affiliationController,
                  decoration: const InputDecoration(labelText: 'Affiliation'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _reason,
                  decoration: const InputDecoration(labelText: 'Reason for demo'),
                  items: _reasons
                      .map((item) => DropdownMenuItem(value: item.value, child: Text(item.label)))
                      .toList(),
                  onChanged: (value) => setState(() => _reason = value),
                ),
                const SizedBox(height: 12),
                if (_reason == 'other')
                  TextField(
                    controller: _detailsController,
                    decoration: const InputDecoration(labelText: 'Tell us more'),
                    maxLines: 3,
                  ),
                const SizedBox(height: 12),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator())
                      : const Text('Submit'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _testToast,
                  icon: const Icon(Icons.notifications),
                  label: const Text('测试 Toast 提示'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final jobTitle = _jobController.text.trim();
    final affiliation = _affiliationController.text.trim();
    final reason = _reason ?? '';
    final details = _detailsController.text.trim();

    if (email.isEmpty || name.isEmpty || jobTitle.isEmpty || affiliation.isEmpty || _country == null || reason.isEmpty) {
      setState(() => _error = 'Please fill all required fields.');
      return;
    }
    if (reason == 'other' && details.isEmpty) {
      setState(() => _error = 'Please provide details for your request.');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      await _service.submit(
        name: name,
        email: email,
        country: _country!,
        affiliation: affiliation,
        jobTitle: jobTitle,
        reason: reason,
        details: details.isEmpty ? null : details,
      );
      setState(() => _isSuccess = true);
      // 显示成功提示
      ToastUtil.showSuccess(
        context: context,
        title: '提交成功',
        description: '您的请求已成功提交，我们会尽快与您联系。',
        duration: const Duration(seconds: 4),
      );
    } catch (error) {
      // 显示错误提示
      ToastUtil.showError(
        context: context,
        title: '提交失败',
        description: error.toString(),
        duration: const Duration(seconds: 5),
      );
      setState(() => _error = error.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _testToast() {
    // 显示成功提示
    ToastUtil.showSuccess(
      context: context,
      title: '成功提示',
      description: '这是一个成功类型的 Toast 提示',
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      ToastUtil.showInfo(
        context: context,
        title: '信息提示',
        description: '这是一个信息类型的 Toast 提示',
      );
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      ToastUtil.showWarning(
        context: context,
        title: '警告提示',
        description: '这是一个警告类型的 Toast 提示',
      );
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      ToastUtil.showError(
        context: context,
        title: '错误提示',
        description: '这是一个错误类型的 Toast 提示',
      );
    });
  }
}

class _ReasonOption {
  const _ReasonOption({required this.value, required this.label});

  final String value;
  final String label;
}

const List<_ReasonOption> _reasons = [
  _ReasonOption(value: 'screening_bottleneck', label: 'AI team expansion faces bottlenecks in screening qualified candidates'),
  _ReasonOption(value: 'hiring_cost', label: 'High costs from incorrect hiring due to lack of professional assessment in technical recruitment'),
  _ReasonOption(value: 'verification_time', label: 'Need to reduce time and cost of AI talent background verification'),
  _ReasonOption(value: 'identify_talent', label: 'Looking for tools to identify top talent in specific AI specialty areas'),
  _ReasonOption(value: 'evaluate_skills', label: 'Existing recruitment systems fail to effectively evaluate open-source contributions and practical skills'),
  _ReasonOption(value: 'other', label: 'Other'),
];

const List<String> _countries = [
  'United States',
  'Canada',
  'United Kingdom',
  'Germany',
  'France',
  'China',
  'Japan',
  'Singapore',
  'India',
  'Australia',
];

