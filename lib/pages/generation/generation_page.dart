import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/upload_service.dart';
import '../../services/flow_service.dart';
import '../../models/user_models.dart';
import '../../stores/user_store.dart';
import '../../utils/toast_util.dart';

class GenerationPage extends StatefulWidget {
  const GenerationPage({super.key});

  @override
  State<GenerationPage> createState() => _GenerationPageState();
}

class _GenerationPageState extends State<GenerationPage> {
  GenerationStep _currentStep = GenerationStep.domain;
  final _domainController = TextEditingController();
  final _resumeController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _scholarController = TextEditingController();
  bool _isUploading = false;
  bool _isSubmitting = false;
  String? _error;
  final UploadService _uploadService = UploadService();
  final FlowService _flowService = FlowService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = GoRouterState.of(context).uri.queryParameters;
    final domain = query['domain'];
    if (domain != null && _domainController.text.isEmpty) {
      _domainController.text = domain;
    }
  }

  @override
  void dispose() {
    _domainController.dispose();
    _resumeController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _scholarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isResult =
        _currentStep == GenerationStep.success ||
        _currentStep == GenerationStep.error;
    final progress = _progressValue();

    return Scaffold(
      body: Column(
        children: [
          if (!isResult)
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: const Color(0xFFD4D4D4),
                    color: const Color(0xFF171717),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subtitleForStep(_currentStep),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildStepContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case GenerationStep.domain:
        return _buildDomainStep(context);
      case GenerationStep.resume:
        return _buildResumeStep(context);
      case GenerationStep.social:
        return _buildSocialStep(context);
      case GenerationStep.success:
        return _buildSuccessStep(context);
      case GenerationStep.error:
        return _buildErrorStep(context);
    }
  }

  Widget _buildDomainStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Claim your DINQ domain',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose a unique handle for your DINQ card.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _domainController,
          decoration: const InputDecoration(
            prefixText: 'dinq.me/',
            labelText: 'Domain',
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _nextFromDomain,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildResumeStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Upload your resume',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'PDF resumes work best. This step is optional.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _resumeController,
          readOnly: true,
          decoration: const InputDecoration(labelText: 'Resume file'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isUploading ? null : _pickResume,
          child: Text(_isUploading ? 'Uploading...' : 'Select file'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _currentStep = GenerationStep.domain),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextFromResume,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Connect your social profiles',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Add links so DINQ can pull your latest highlights.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _twitterController,
          decoration: const InputDecoration(labelText: 'Twitter / X'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _linkedinController,
          decoration: const InputDecoration(labelText: 'LinkedIn'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _githubController,
          decoration: const InputDecoration(labelText: 'GitHub'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _scholarController,
          decoration: const InputDecoration(labelText: 'Google Scholar'),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _currentStep = GenerationStep.resume),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitGeneration,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Generate DINQ'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 12),
        const Text(
          'Your DINQ Card is ready!',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('We are preparing your profile data.'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => context.go('/admin/mydinq'),
          child: const Text('Go to My DINQ'),
        ),
      ],
    );
  }

  Widget _buildErrorStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.error, size: 64, color: Colors.redAccent),
        const SizedBox(height: 12),
        const Text(
          'Something went wrong',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_error ?? 'Please try again later.'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = GenerationStep.domain),
          child: const Text('Try again'),
        ),
      ],
    );
  }

  double _progressValue() {
    switch (_currentStep) {
      case GenerationStep.domain:
        return 0.16;
      case GenerationStep.resume:
        return 0.5;
      case GenerationStep.social:
        return 0.83;
      case GenerationStep.success:
      case GenerationStep.error:
        return 1.0;
    }
  }

  String _subtitleForStep(GenerationStep step) {
    switch (step) {
      case GenerationStep.domain:
        return 'Get your personalized DINQ Card in just a few steps.';
      case GenerationStep.resume:
        return "Let's start creating your DINQ Card.";
      case GenerationStep.social:
        return 'Last step! Your DINQ Card is almost ready!';
      case GenerationStep.success:
      case GenerationStep.error:
        return '';
    }
  }

  void _nextFromDomain() {
    if (_domainController.text.trim().isEmpty) {
      setState(() => _error = 'Please choose a domain.');
      return;
    }
    setState(() {
      _error = null;
      _currentStep = GenerationStep.resume;
    });
  }

  Future<void> _pickResume() async {
    setState(() => _isUploading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      _resumeController.text = file.name;
      try {
        await _uploadService.uploadFile(
          bytes: file.bytes!,
          filename: file.name,
        );
      } catch (error) {
        setState(() => _error = error.toString());
      }
    }
    setState(() => _isUploading = false);
  }

  void _nextFromResume() {
    setState(() {
      _error = null;
      _currentStep = GenerationStep.social;
    });
  }

  Future<void> _submitGeneration() async {
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      final domain = _domainController.text.trim();

      // 1. 先占用域名
      final claimedFlow = await _flowService.claimDomain(domain: domain);

      // 2. 收集社交链接
      final socialLinks = <Map<String, dynamic>>[];
      if (_twitterController.text.trim().isNotEmpty) {
        socialLinks.add({
          'type': 'twitter',
          'url': _twitterController.text.trim(),
        });
      }
      if (_linkedinController.text.trim().isNotEmpty) {
        socialLinks.add({
          'type': 'linkedin',
          'url': _linkedinController.text.trim(),
        });
      }
      if (_githubController.text.trim().isNotEmpty) {
        socialLinks.add({
          'type': 'github',
          'url': _githubController.text.trim(),
        });
      }
      if (_scholarController.text.trim().isNotEmpty) {
        socialLinks.add({
          'type': 'scholar',
          'url': _scholarController.text.trim(),
        });
      }
      // 3. 调用生成 API
      final response = await _flowService.generate({
        'social_links': socialLinks,
      });

      // 4. 更新用户流程状态
      final userStore = context.read<UserStore>();
      final flowData = response['flow'] as Map<String, dynamic>?;
      if (flowData != null) {
        final flow = UserFlow.fromJson(flowData);
        userStore.setMyFlow(flow);
      } else {
        // 如果没有返回 flow，使用已占用的域名信息
        userStore.setMyFlow(claimedFlow);
      }
      await userStore.getCurrentUser();
      // 5. 显示成功提示
      ToastUtil.showSuccess(
        context: context,
        title: '生成成功',
        description: '您的 DINQ Card 正在准备中...',
      );

      setState(() {
        _currentStep = GenerationStep.success;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _currentStep = GenerationStep.error;
      });
      ToastUtil.showError(
        context: context,
        title: '生成失败',
        description: error.toString(),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

enum GenerationStep { domain, resume, social, success, error }
