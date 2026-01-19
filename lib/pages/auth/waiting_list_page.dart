import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/waiting_list_service.dart';

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
        appBar: AppBar(title: const Text('Waiting List')),
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
        title: const Text('Join the Waiting List'),
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
                  'Get early access to DINQ',
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
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: _countries
                      .map((country) => DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          ))
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
                  controller: _institutionController,
                  decoration: const InputDecoration(labelText: 'Institution'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _schoolController,
                  decoration: const InputDecoration(labelText: 'School (optional)'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final jobTitle = _jobController.text.trim();
    final institution = _institutionController.text.trim();

    if (email.isEmpty || fullName.isEmpty || jobTitle.isEmpty || institution.isEmpty || _country == null) {
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
      setState(() => _error = error.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

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

