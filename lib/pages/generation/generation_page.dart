import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_models.dart';
import '../../services/flow_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/upload_service.dart';
import '../../stores/card_store.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/dinq_page_gate.dart';
import '../../utils/onboarding_draft_mapping.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/account/agreement_protocol_modal.dart';
import '../../widgets/generation/onboarding/onboarding_analyze_view.dart';
import '../../widgets/generation/onboarding/onboarding_footer.dart';
import '../../widgets/generation/onboarding/onboarding_handle_view.dart';
import '../../widgets/generation/onboarding/onboarding_profile_basics_view.dart';
import '../../widgets/generation/onboarding/onboarding_profile_expertise_view.dart';
import '../../widgets/generation/onboarding/onboarding_logo_header.dart';
import '../../widgets/generation/onboarding/onboarding_start_view.dart';
import '../../widgets/generation/onboarding/onboarding_socials_view.dart';
import '../../widgets/generation/onboarding/onboarding_upload_view.dart';
import '../../widgets/generation/onboarding/onboarding_welcome_view.dart';

class GenerationPage extends StatefulWidget {
  const GenerationPage({super.key});

  @override
  State<GenerationPage> createState() => _GenerationPageState();
}

class _GenerationPageState extends State<GenerationPage> {
  GenerationStep _currentStep = GenerationStep.start;
  final _domainController = TextEditingController();
  final _resumeController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _scholarController = TextEditingController();
  final _profileNameController = TextEditingController();
  final _profilePositionController = TextEditingController();
  final _profileCompanyController = TextEditingController();
  final _profileLocationController = TextEditingController();
  final _profileSchoolController = TextEditingController();
  String _profileAvatarUrl = '';
  String _profileEducationLevel = '';
  String _profileTimezone = '';

  // 第三步：社交链接相关
  final List<SocialLink> _socialLinks = [];
  List<String> _profileTags = [];
  String _profileBio = '';
  final TextEditingController _newUrlController = TextEditingController();
  bool _isGenerating = false;
  bool _isSkipping = false;

  bool _isUploading = false;
  int _uploadProgress = 0;
  int? _resumeFileSize; // 保存文件大小（字节）
  bool _hasResume = false; // 标记是否已上传简历
  String? _resumeUrl; // 保存上传后的简历 URL
  String? _resumeFileKey;
  int? _resumeUploadExpiresAt;
  bool _profileDraftReady = false;
  bool _useOnboardingHandle = false;
  String? _handleCharWarning;
  Map<String, dynamic>? _draftUserData;
  String? _analyzeMode; // resume | url
  int _analyzeActiveStep = 0;
  String? _analyzeError;
  bool _isAnalyzing = false; // 分析简历状态
  String? _profileUrlError; // LinkedIn URL 错误信息
  String? _profileUrlWarning; // LinkedIn URL 警告信息
  String? _uploadError; // 文件上传错误信息
  String? _startUrlError; // Start 页 URL 校验错误
  OnboardingOrgContext? _orgContext;

  static const int MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
  }

  bool _isCheckingDomain = false;
  bool _isClaimingDomain = false;
  bool _isReservingHandle = false;
  String? _handleReservationToken;
  int? _handleReservedUntil;
  bool _onboardingFinalized = false;
  OnboardingWelcomeStatus _welcomeStatus = OnboardingWelcomeStatus.saving;
  String? _welcomeError;
  bool _welcomeShouldUploadAgain = false;
  bool _welcomeFinalizeStarted = false;
  List<OnboardingAddedLink> _onboardingSocialLinks = [];
  Map<String, dynamic>? _domainCheckResult;
  Timer? _domainCheckTimer;
  String? _error;
  final UploadService _uploadService = UploadService();
  final FlowService _flowService = FlowService();
  final OnboardingService _onboardingService = OnboardingService();

  // Success 步骤倒计时
  int _redirectCountdown = 3;
  Timer? _redirectTimer;
  String? _onboardingReturnPath;
  bool _isStandaloneSocialsEntry = false;
  bool _isRegenerateEntry = false;
  bool _queryStepApplied = false;

  // Confetti 控制器
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _domainController.addListener(_onDomainChanged);
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 50),
    );
    // 反向守卫（对齐 web onboarding layout）：已有生效 dinq page 的用户
    // 打开创建流程直接回 mydinq。只判 hasLiveDinqPage（flow success），
    // 不判 userData.domain 兜底——Regenerate 会 resetFlow 后进入本页，
    // 此时 domain 仍在，不能被弹回。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final query = GoRouterState.of(context).uri.queryParameters;
      final isRegenerate =
          query['regenerate'] == '1' || query['regenerate'] == 'true';
      if (isRegenerate) return;
      final userStore = context.read<UserStore>();
      if (userStore.isInitialized && hasLiveDinqPage(userStore.myFlow)) {
        context.go('/admin/mydinq');
      }
    });
  }

  void _onDomainChanged() {
    setState(() {});
    final domain = _domainController.text.trim();
    _domainCheckTimer?.cancel();
    if (domain.isEmpty) {
      setState(() {
        _domainCheckResult = null;
        _error = null;
      });
      return;
    }
    if (domain.length < 3) {
      setState(() => _domainCheckResult = null);
      return;
    }
    _domainCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _doCheckDomain(domain);
    });
  }

  Future<void> _doCheckDomain(String domain) async {
    if (_domainController.text.trim() != domain) return;
    setState(() => _isCheckingDomain = true);
    try {
      final result = await _flowService.checkDomain(domain: domain);
      if (!mounted) return;
      if (_domainController.text.trim() != domain) return;
      setState(() {
        _domainCheckResult = result;
        _isCheckingDomain = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _domainCheckResult = null;
        _isCheckingDomain = false;
      });
    }
  }

  bool _isDomainValid() {
    final domain = _domainController.text.trim();
    if (domain.length < 3) return false;
    if (_isCheckingDomain) return false;
    final available = _domainCheckResult?['available'];
    return identical(available, true);
  }

  GenerationStep _getStepFromFlowStatus(String? status) {
    switch (status) {
      case 'init':
        return GenerationStep.start;
      case 'domain':
        return GenerationStep.resume;
      case 'resume':
        return GenerationStep.social;
      case 'success':
        return GenerationStep.success;
      default:
        return GenerationStep.start;
    }
  }

  /// flow 仍为 `init` 时，允许 Start 内的本地导航，不被 flow 同步覆盖。
  bool _shouldSyncStepFromFlow(
    GenerationStep current,
    GenerationStep fromFlow,
  ) {
    if (_isRegenerateEntry) return false;
    if (current == GenerationStep.error) return false;
    if (current == GenerationStep.social && fromFlow == GenerationStep.resume) {
      return false;
    }
    if (fromFlow == GenerationStep.start) {
      switch (current) {
        case GenerationStep.start:
        case GenerationStep.upload:
        case GenerationStep.analyze:
        case GenerationStep.profileBasics:
        case GenerationStep.profileExpertise:
        case GenerationStep.domain:
        case GenerationStep.welcome:
        case GenerationStep.onboardingSocials:
        case GenerationStep.resume:
          return false;
        default:
          return true;
      }
    }
    if (current == GenerationStep.welcome ||
        current == GenerationStep.onboardingSocials) {
      return false;
    }
    return current != fromFlow;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 从 URL query 参数获取（须在 flow 同步之前，Regenerate 入口依赖此顺序）
    final query = GoRouterState.of(context).uri.queryParameters;
    _isRegenerateEntry =
        query['regenerate'] == '1' || query['regenerate'] == 'true';

    if (_isRegenerateEntry) {
      _redirectTimer?.cancel();
      if (_currentStep != GenerationStep.start) {
        setState(() => _currentStep = GenerationStep.start);
      }
    } else {
      // 从 UserStore 获取 flow 状态
      final userStore = context.read<UserStore>();
      final myFlow = userStore.myFlow;

      // 根据 flow.status 设置当前步骤
      if (myFlow != null) {
        final stepFromFlow = _getStepFromFlowStatus(myFlow.status);
        if (_shouldSyncStepFromFlow(_currentStep, stepFromFlow)) {
          setState(() {
            _currentStep = stepFromFlow;
          });
        }

        // 注意：handle 输入框不做任何预填（后端 myFlow.domain 和前端 email/name
        // 候选都不用）。产品要求创建主页地址时输入框默认为空、由用户手动输入，
        // 否则会出现「上传别人的主页却预填成当前账号名(mark)」。

        // 加载社交链接（第三步）
        if (_currentStep == GenerationStep.social && _socialLinks.isEmpty) {
          _loadSocialLinksFromFlow(myFlow);
        }

        // 启动倒计时（成功步骤）
        if (_currentStep == GenerationStep.success) {
          _redirectTimer?.cancel();
          _startRedirectCountdown();
        }
      }
    }

    if (!_queryStepApplied) {
      _queryStepApplied = true;
      final step = query['step']?.trim().toLowerCase();
      if (step == 'socials' || step == 'social-links' || step == 'social') {
        _redirectTimer?.cancel();
        _isStandaloneSocialsEntry = true;
        _onboardingReturnPath ??= '/me';
        setState(() => _currentStep = GenerationStep.onboardingSocials);
      }
    }
    final next = query['next']?.trim();
    if (next != null && next.isNotEmpty) {
      _onboardingReturnPath = next;
    }
    final domain = query['domain'] ?? query['handle'];
    if (domain != null && _domainController.text.isEmpty) {
      final sanitized = domain.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      if (sanitized.isNotEmpty) {
        _domainController.text = sanitized.length > 100
            ? sanitized.substring(0, 100)
            : sanitized;
      }
    }
    final orgName = query['orgName'];
    if (orgName != null && orgName.isNotEmpty) {
      _orgContext = OnboardingOrgContext(
        orgName: orgName,
        orgLogoUrl: query['orgLogoUrl'],
        orgMemberCount: int.tryParse(query['orgMemberCount'] ?? ''),
      );
    }
  }

  void _startRedirectCountdown() {
    _redirectTimer?.cancel();
    setState(() {
      _redirectCountdown = 3;
    });
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _redirectCountdown--;
      });
      // 当倒计时到0时跳转（显示完1后跳转）
      if (_redirectCountdown <= 0) {
        timer.cancel();
        if (mounted) {
          context.go(_onboardingReturnPath ?? '/');
        }
      }
    });
  }

  @override
  void dispose() {
    _domainCheckTimer?.cancel();
    _redirectTimer?.cancel();
    _confettiController.dispose();
    _domainController.removeListener(_onDomainChanged);
    _domainController.dispose();
    _resumeController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _scholarController.dispose();
    _profileNameController.dispose();
    _profilePositionController.dispose();
    _profileCompanyController.dispose();
    _profileLocationController.dispose();
    _profileSchoolController.dispose();
    _newUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听 UserStore 的 myFlow 变化，自动更新步骤
    final userStore = context.watch<UserStore>();
    final myFlow = userStore.myFlow;
    if (!_isRegenerateEntry && myFlow != null) {
      final stepFromFlow = _getStepFromFlowStatus(myFlow.status);
      if (_shouldSyncStepFromFlow(_currentStep, stepFromFlow)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _shouldSyncStepFromFlow(_currentStep, stepFromFlow)) {
            final wasSuccess = _currentStep == GenerationStep.success;
            setState(() {
              _currentStep = stepFromFlow;
            });
            if (stepFromFlow == GenerationStep.success && !wasSuccess) {
              _redirectTimer?.cancel();
              _startRedirectCountdown();
            }
          }
        });
      }
    }

    final isResult =
        _currentStep == GenerationStep.success ||
        _currentStep == GenerationStep.error;
    final isStart = _currentStep == GenerationStep.start;
    final isUpload = _currentStep == GenerationStep.upload;
    final isAnalyze = _currentStep == GenerationStep.analyze;
    final isProfileBasics = _currentStep == GenerationStep.profileBasics;
    final isProfileExpertise = _currentStep == GenerationStep.profileExpertise;
    final progress = _progressValue();

    if (isProfileBasics) {
      return Scaffold(
        backgroundColor: DinqTokens.bgPage,
        body: SafeArea(
          child: OnboardingProfileBasicsView(
            nameController: _profileNameController,
            positionController: _profilePositionController,
            companyController: _profileCompanyController,
            schoolController: _profileSchoolController,
            locationController: _profileLocationController,
            avatarUrl: _profileAvatarUrl,
            educationLevel: _profileEducationLevel,
            timezone: _profileTimezone,
            onAvatarChanged: (url) => setState(() => _profileAvatarUrl = url),
            onEducationLevelChanged: (value) =>
                setState(() => _profileEducationLevel = value),
            onTimezoneChanged: (value) =>
                setState(() => _profileTimezone = value),
            previewTags: _profileTags,
            previewBio: _profileBio,
            onBack: _handleBasicsBack,
            onContinue: _handleBasicsContinue,
          ),
        ),
      );
    }

    if (isProfileExpertise) {
      return Scaffold(
        backgroundColor: DinqTokens.bgPage,
        body: SafeArea(
          child: OnboardingProfileExpertiseView(
            tags: _profileTags,
            bio: _profileBio,
            onTagsChanged: (tags) =>
                setState(() => _profileTags = normalizeProfileTags(tags)),
            onBioChanged: (bio) => setState(() => _profileBio = bio),
            previewName: _profileNameController.text.trim(),
            previewPosition: _profilePositionController.text.trim(),
            previewCompany: _profileCompanyController.text.trim(),
            previewSchool: _profileSchoolController.text.trim(),
            previewLocation: _profileLocationController.text.trim(),
            previewTimezone: _profileTimezone,
            previewAvatarUrl: _profileAvatarUrl,
            onBack: _handleExpertiseBack,
            onContinue: _handleExpertiseContinue,
          ),
        ),
      );
    }

    if (isAnalyze) {
      return Scaffold(
        backgroundColor: DinqTokens.bgPage,
        body: SafeArea(
          child: OnboardingAnalyzeView(
            mode: _analyzeMode ?? 'resume',
            sourceLabel: _analyzeMode == 'resume'
                ? (_resumeController.text.isNotEmpty
                      ? _resumeController.text
                      : 'Resume')
                : _linkedinController.text.trim(),
            activeStep: _analyzeActiveStep,
            error: _analyzeError,
            onRetry: _handleAnalyzeRetry,
          ),
        ),
      );
    }

    if (isUpload) {
      return Scaffold(
        backgroundColor: DinqTokens.bgPage,
        body: SafeArea(
          child: OnboardingUploadView(
            fileName: _resumeController.text,
            fileSizeBytes: _resumeFileSize,
            isUploading: _isUploading,
            uploadProgress: _uploadProgress,
            canContinue:
                _hasResume && _resumeUrl != null && _resumeFileKey != null,
            onPickFile: _pickResume,
            onBack: _handleUploadBack,
            onContinue: _handleUploadContinue,
          ),
        ),
      );
    }

    final isOnboardingHandle =
        _currentStep == GenerationStep.domain &&
        (_useOnboardingHandle || _profileDraftReady);
    if (isOnboardingHandle) {
      final domain = _domainController.text.trim();
      final isTooShort = domain.isNotEmpty && domain.length < 3;
      final isTaken =
          _domainCheckResult != null &&
          _domainCheckResult!['available'] == false;
      final isAvailable = _isDomainValid();
      final suggestions = _domainCheckResult?['suggestions'] as List<dynamic>?;
      final suggestionStrings =
          suggestions?.map((e) => e is String ? e : e.toString()).toList() ??
          <String>[];

      return Scaffold(
        backgroundColor: DinqTokens.bgPage,
        body: SafeArea(
          child: OnboardingHandleView(
            controller: _domainController,
            orgName: _orgContext?.orgName,
            isChecking: _isCheckingDomain,
            isReserving: _isReservingHandle,
            isTooShort: isTooShort,
            isTaken: isTaken,
            isAvailable: isAvailable,
            charWarning: _handleCharWarning,
            suggestions: suggestionStrings,
            onChanged: _onOnboardingHandleChanged,
            onClaim: _reserveHandleAndContinue,
            onBack: _handleHandleBack,
          ),
        ),
      );
    }

    if (_currentStep == GenerationStep.welcome) {
      if (!_welcomeFinalizeStarted && !_onboardingFinalized) {
        _welcomeFinalizeStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _finalizeOnboardingDraft();
        });
      }
      final handle = _domainController.text.trim().isNotEmpty
          ? _domainController.text.trim()
          : (context.read<UserStore>().myFlow?.domain ?? '');
      return Scaffold(
        backgroundColor: DinqTokens.bgPage,
        body: SafeArea(
          child: OnboardingWelcomeView(
            status: _welcomeStatus,
            handle: handle,
            errorMessage: _welcomeError,
            shouldUploadAgain: _welcomeShouldUploadAgain,
            orgName: _orgContext?.orgName,
            onRetry: _handleWelcomeRetry,
            onGoSocials: () => setState(() {
              _currentStep = GenerationStep.onboardingSocials;
            }),
            onGoMydinq: _goToMydinq,
            onGoOrg: _goToMydinq,
          ),
        ),
      );
    }

    if (_currentStep == GenerationStep.onboardingSocials) {
      return Scaffold(
        backgroundColor: DinqTokens.bgPage,
        body: SafeArea(
          child: OnboardingSocialsView(
            initialLinks: _onboardingSocialLinks,
            onBack: () {
              if (_isStandaloneSocialsEntry) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(_onboardingReturnPath ?? '/me');
                }
              } else {
                setState(() => _currentStep = GenerationStep.welcome);
              }
            },
            onFinish: _finishOnboardingSocials,
          ),
        ),
      );
    }

    if (isStart) {
      final isMobile = MediaQuery.sizeOf(context).width < 768;
      return Scaffold(
        backgroundColor: DinqTokens.bgPage,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isMobile) const OnboardingLogoHeader(),
                  Expanded(
                    child: OnboardingStartView(
                      urlController: _linkedinController,
                      error: _startUrlError,
                      orgContext: _orgContext,
                      onGenerate: _handleStartGenerate,
                      onUploadResume: _handleStartUpload,
                      onStartManual: _handleStartManual,
                      onSkip: _handleStartSkip,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (!isMobile)
                OnboardingFixedFooter(
                  child: _StartSkipFooter(
                    hasOrg: _orgContext?.hasOrg == true,
                    onSkip: _handleStartSkip,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // 1. 顶部步骤条（非结果页时显示）
          if (!isResult) _buildStepBar(progress),
          // 2. 中间内容区
          Expanded(
            child: Align(
              alignment: isResult ? Alignment.center : Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  top: _currentStep == GenerationStep.domain ? 80 : 0,
                  left: 24,
                  right: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _buildStepContent(context),
                ),
              ),
            ),
          ),
          // 3. 底部按钮区
          _buildStepActions(context),
        ],
      ),
    );
  }

  Widget _buildStepBar(double progress) {
    return Padding(
      padding: const EdgeInsets.only(top: 76, left: 24, right: 24, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 270,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: const Color(0xFFD4D4D4),
              color: const Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 230,
            child: Text(
              _subtitleForStep(_currentStep),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 22 / 14,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case GenerationStep.start:
        return const SizedBox.shrink();
      case GenerationStep.upload:
        return const SizedBox.shrink();
      case GenerationStep.analyze:
        return const SizedBox.shrink();
      case GenerationStep.profileBasics:
      case GenerationStep.profileExpertise:
        return const SizedBox.shrink();
      case GenerationStep.domain:
        return _buildDomainStep(context);
      case GenerationStep.resume:
        return _buildResumeStep(context);
      case GenerationStep.social:
        return _buildSocialStep(context);
      case GenerationStep.welcome:
      case GenerationStep.onboardingSocials:
        return const SizedBox.shrink();
      case GenerationStep.success:
        return _buildSuccessStep(context);
      case GenerationStep.error:
        return _buildErrorStep(context);
    }
  }

  Widget _buildDomainStep(BuildContext context) {
    final domain = _domainController.text.trim();
    final isTooShort = domain.isNotEmpty && domain.length < 3;
    final isTaken =
        _domainCheckResult != null && _domainCheckResult!['available'] != true;
    final isAvailable = _isDomainValid();
    final hasError = isTooShort || isTaken;
    final suggestions = _domainCheckResult?['suggestions'] as List<dynamic>?;
    final suggestionStrings =
        suggestions?.map((e) => e is String ? e : e.toString()).toList() ??
        <String>[];

    Color borderColor = const Color(0xFF171717);
    if (hasError) borderColor = Colors.red;
    if (isAvailable) borderColor = const Color(0xFF22C55E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Create your DINQ Card',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Editor Note",
            fontWeight: FontWeight.w600,
            fontSize: 24,
            height: 48 / 24,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose your DINQ URL',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontFamily: 'Tomato Grotesk',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 24 / 14,
            letterSpacing: 0,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'dinq.me/',
                  style: TextStyle(
                    fontFamily: 'Tomato Grotesk',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _domainController,
                  onChanged: (_) => _onDomainChanged(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                    LengthLimitingTextInputFormatter(100),
                  ],
                  style: const TextStyle(
                    fontFamily: 'Tomato Grotesk',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF171717),
                  ),
                  decoration: InputDecoration(
                    hintText: 'user name',
                    hintStyle: const TextStyle(
                      fontFamily: 'Tomato Grotesk',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (_isCheckingDomain)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (isAvailable && !_isCheckingDomain)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF22C55E),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
        if (isTooShort) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.red),
              SizedBox(width: 6),
              Text(
                'Domain must be at least 3 characters',
                style: TextStyle(fontSize: 14, color: Colors.red),
              ),
            ],
          ),
        ],
        if (isTaken) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                const Text(
                  'Sorry, this username is taken',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontFamily: 'Tomato Grotesk',
                  ),
                ),
              ],
            ),
          ),
          if (suggestionStrings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Available:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 24 / 14,
                color: Color(0xFF171717),
                fontFamily: 'Tomato Grotesk',
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestionStrings.map((s) {
                return OutlinedButton(
                  onPressed: () {
                    _domainController.text = s;
                    _domainController.selection = TextSelection.collapsed(
                      offset: s.length,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF171717),
                    side: const BorderSide(color: Color(0xFF171717)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Tomato Grotesk',
                      color: Color(0xFF171717),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ],
    );
  }

  Widget _buildResumeStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        // 信息卡片
        Image.asset(
          'assets/images/generation/step2.png',
          fit: BoxFit.contain,
          width: double.infinity,
        ),
        const SizedBox(height: 24),
        // 上传简历区域
        GestureDetector(
          onTap: _isUploading ? null : _pickResume,
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: const Radius.circular(8),
              strokeWidth: 2,
              dashPattern: const [8, 4],
              color: const Color(0xFFD4D4D4),
            ),
            child: Container(
              // padding: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _uploadError != null && !_hasResume
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 24,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload failed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF171717),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _uploadError!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _uploadError = null;
                            });
                          },
                          child: const Text(
                            'Try again',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF171717),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _isUploading && _resumeController.text.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // PDF 图标
                            Image.asset(
                              'assets/images/generation/pdf.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 文件名
                                  Text(
                                    _resumeController.text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF171717),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // 文件大小 + Uploading...
                                  Row(
                                    children: [
                                      if (_resumeFileSize != null) ...[
                                        Text(
                                          _formatFileSize(_resumeFileSize!),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          '·',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Uploading...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _isUploading = false;
                                  _uploadProgress = 0;
                                  _hasResume = false;
                                  _resumeController.text = '';
                                  _resumeUrl = null;
                                  _resumeFileSize = null;
                                  _uploadError = null;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 进度条
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _uploadProgress / 100,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE5E5E5),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF3B82F6),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$_uploadProgress%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : _hasResume && _resumeController.text.isNotEmpty
                  ? Container(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/generation/pdf.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _resumeController.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    if (_resumeFileSize != null) ...[
                                      Text(
                                        _formatFileSize(_resumeFileSize!),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '·',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    const Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: Color(0xFF22C55E),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'validated successfully',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF22C55E),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: (_isAnalyzing || _isUploading)
                                ? null
                                : () {
                                    setState(() {
                                      _hasResume = false;
                                      _resumeController.text = '';
                                      _uploadProgress = 0;
                                      _resumeUrl = null;
                                      _resumeFileSize = null;
                                      _uploadError = null;
                                    });
                                  },
                            child: Image.asset(
                              'assets/images/generation/remove.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF171717),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Upload your resume',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF171717),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload a PDF resume (max 10MB) to create your DINQ Card.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // "or" 分隔符
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFD4D4D4))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFD4D4D4))),
          ],
        ),
        const SizedBox(height: 16),
        // LinkedIn 输入框
        Row(
          children: [
            // LinkedIn 图标
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Image.asset(
                  'assets/icons/logo/LinkedIn.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 输入框（无圆角）
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _profileUrlError != null
                        ? Colors.red
                        : _profileUrlWarning != null
                        ? Colors.amber
                        : const Color(0xFFD8D8D8),
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Center(
                  child: TextField(
                    controller: _linkedinController,
                    enabled: !_isAnalyzing && !_isUploading,
                    onChanged: (value) {
                      setState(() {
                        _profileUrlError = _getUrlError(value);
                        _profileUrlWarning = _getLinkedInWarning(value);
                      });
                    },
                    style: const TextStyle(fontSize: 14, height: 1.0),
                    decoration: InputDecoration(
                      hintText: 'https://linkedin.com/in/your-profile',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.0,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_profileUrlError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: Colors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _profileUrlError!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
        if (_profileUrlError == null && _profileUrlWarning != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Colors.amber,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _profileUrlWarning!,
                  style: const TextStyle(fontSize: 12, color: Colors.amber),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSocialStep(BuildContext context) {
    // 初始化社交链接列表（如果为空）
    if (_socialLinks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final userStore = context.read<UserStore>();
          setState(() {
            _loadSocialLinksFromFlow(userStore.myFlow);
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 信息卡片
        Image.asset(
          'assets/images/generation/step3.png',
          fit: BoxFit.contain,
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        // 添加 URL 输入框
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _newUrlController,
                        enabled: !_isGenerating && !_isSkipping,
                        onSubmitted: (_) => _handleAddUrl(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF171717),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Paste social profile URL (e.g., https://linkedin.com/in/yourname)',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_isGenerating || _isSkipping)
                        ? null
                        : _handleAddUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF171717),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 社交链接列表
              ..._socialLinks.asMap().entries.map((entry) {
                final index = entry.key;
                final link = entry.value;
                final config =
                    PLATFORM_CONFIG[link.type] ??
                    {
                      'icon': 'assets/icons/logo/LinkedIn.png',
                      'placeholder': 'Enter URL',
                    };
                final hasUrl = link.url.trim().isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // 图标
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Image.asset(
                          config['icon']!,
                          width: 40,
                          height: 40,
                          opacity: hasUrl
                              ? const AlwaysStoppedAnimation(1.0)
                              : const AlwaysStoppedAnimation(0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 输入框
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            border: Border.all(
                              color: link.error != null
                                  ? Colors.red
                                  : Colors.transparent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            enabled: !_isGenerating && !_isSkipping,
                            onChanged: (value) {
                              setState(() {
                                _socialLinks[index] = link.copyWith(
                                  url: value,
                                  error: null,
                                );
                              });
                            },
                            onSubmitted: (_) {
                              final error = _validateSocialUrl(
                                _socialLinks[index],
                              );
                              if (error != null) {
                                setState(() {
                                  _socialLinks[index] = _socialLinks[index]
                                      .copyWith(error: error);
                                });
                                TopToastUtil.showError(
                                  context: context,
                                  title: 'Validation Error',
                                  description: error,
                                );
                              }
                            },
                            controller: TextEditingController(text: link.url)
                              ..selection = TextSelection.collapsed(
                                offset: link.url.length,
                              ),
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUrl
                                  ? const Color(0xFF171717)
                                  : const Color(0xFF6B7280).withOpacity(0.4),
                            ),
                            decoration: InputDecoration(
                              hintText: config['placeholder'],
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    // 确保倒计时启动并触发 confetti 动画
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentStep == GenerationStep.success) {
        // 如果倒计时未启动或已结束，重新启动
        if (_redirectTimer == null) {
          _startRedirectCountdown();
        }
        // 触发 confetti 动画
        _confettiController.play();
      }
    });

    return Stack(
      children: [
        // Confetti 动画 - 参考 tsx 配置，合并为一个一次性爆炸效果
        // origin y: 0.6 表示从屏幕 60% 的位置开始
        // 调整喷口方向：
        // - explosive 模式：向各个方向发射（当前模式）
        // - directional 模式：使用 blastDirection 指定方向
        //   blastDirection 值（弧度）：
        //   - 0 或 2*pi = 向右
        //   - pi/2 = 向上
        //   - pi = 向左
        //   - 3*pi/2 = 向下
        // Confetti 动画 - 参考 tsx 配置
        // tsx 中有5个 fire 调用，总共 200 个粒子 (50+40+70+20+20)
        // Confetti 动画 - 参考 goliath 示例，向上半部分发射
        Positioned(
          bottom: 350 + 150, // 发射位置
          left: 0,
          right: 0,
          child: Center(
            child: Stack(
              children: [
                // 向上发射（正上方）- 参考 goliath，但方向改为向上
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection:
                      -pi / 2, // 从底部向上发射（参考 goliath: pi/2 向下，这里用 -pi/2 向上）
                  maxBlastForce: 5, // 参考 goliath
                  minBlastForce: 2, // 参考 goliath
                  emissionFrequency: 0.05, // 参考 goliath
                  numberOfParticles: 50, // 参考 goliath
                  gravity: 0.1, // 向上发射时重力较小，让粒子能飞得更高
                  shouldLoop: false,
                  minimumSize: const Size(4, 4), // 最小粒子大小
                  maximumSize: const Size(8, 8), // 最大粒子大小
                  colors: const [
                    Color(0xFFFFD700), // #FFD700 黄色
                    Color(0xFFFF6B6B), // #FF6B6B 红色
                    Color(0xFF4ECDC4), // #4ECDC4 青色
                    Color(0xFF45B7D1), // #45B7D1 蓝色
                    Color(0xFF96CEB4), // #96CEB4 绿色
                    Color(0xFFFFEAA7), // #FFEAA7 浅黄色
                  ],
                ),
                // 向左上方发射
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -pi / 4, // 左上方（-45度）
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 40,
                  gravity: 0.1,
                  shouldLoop: false,
                  minimumSize: const Size(8, 8), // 最小粒子大小
                  maximumSize: const Size(12, 12), // 最大粒子大小
                  colors: const [
                    Color(0xFFFFD700),
                    Color(0xFFFF6B6B),
                    Color(0xFF4ECDC4),
                    Color(0xFF45B7D1),
                    Color(0xFF96CEB4),
                    Color(0xFFFFEAA7),
                  ],
                ),
                // 向右上方发射
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -3 * pi / 4, // 右上方（-135度）
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 40,
                  gravity: 0.1,
                  shouldLoop: false,
                  minimumSize: const Size(4, 4), // 最小粒子大小
                  maximumSize: const Size(8, 8), // 最大粒子大小
                  colors: const [
                    Color(0xFFFFD700),
                    Color(0xFFFF6B6B),
                    Color(0xFF4ECDC4),
                    Color(0xFF45B7D1),
                    Color(0xFF96CEB4),
                    Color(0xFFFFEAA7),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 主要内容 - 居中显示
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 中心图标组合
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8E6D3), // 浅绿色
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card,
                  size: 40,
                  color: Color(0xFF374151), // 深灰色
                ),
              ),
              const SizedBox(height: 32),
              // 主标题
              const Text(
                'Your DINQ Card has been\ngenerated successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              // 副标题
              const Text(
                'Your personalized DINQ Card is ready!\nYou can now view and share your professional profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // 倒计时提示
              if (_redirectCountdown > 0)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                    children: [
                      const TextSpan(text: 'Automatically redirecting in '),
                      TextSpan(
                        text: '$_redirectCountdown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const TextSpan(text: ' seconds...'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, size: 64, color: Colors.redAccent),
        const SizedBox(height: 12),
        const Text(
          'Something went wrong',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(_error ?? 'Please try again later.'),
      ],
    );
  }

  Widget _buildStepActions(BuildContext context) {
    const bottomPadding = EdgeInsets.fromLTRB(24, 16, 24, 40);

    switch (_currentStep) {
      case GenerationStep.start:
      case GenerationStep.upload:
        return const SizedBox.shrink();
      case GenerationStep.analyze:
      case GenerationStep.profileBasics:
      case GenerationStep.profileExpertise:
      case GenerationStep.welcome:
      case GenerationStep.onboardingSocials:
        return const SizedBox.shrink();
      case GenerationStep.domain:
        return Padding(
          padding: bottomPadding,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isDomainValid() && !_isClaimingDomain)
                  ? _nextFromDomain
                  : null,
              child: _isClaimingDomain
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue'),
            ),
          ),
        );
      case GenerationStep.resume:
        final canContinue =
            !_isAnalyzing &&
            !_isUploading &&
            (_resumeUrl != null ||
                _linkedinController.text.trim().isNotEmpty) &&
            _getUrlError(_linkedinController.text.trim()) == null;

        return Padding(
          padding: bottomPadding,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canContinue ? _nextFromResume : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnalyzing
                        ? const Color(0xFFE5E5E5)
                        : (canContinue
                              ? const Color(0xFF171717)
                              : const Color(0xFFE5E5E5)),
                    foregroundColor: _isAnalyzing
                        ? const Color(0xFF6B7280)
                        : (canContinue
                              ? Colors.white
                              : const Color(0xFF6B7280).withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isAnalyzing
                      ? const Text(
                          'Analyzing...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              // Skip 按钮（文本形式）- analyzing 和 uploading 时隐藏
              if (!_isAnalyzing && !_isUploading) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _handleSkipResume,
                  child: const Text(
                    'Skip',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA3A3A3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      case GenerationStep.social:
        final filledLinksCount = _socialLinks
            .where((l) => l.url.trim().isNotEmpty)
            .length;
        final canContinue =
            !_isGenerating && !_isSkipping && filledLinksCount > 0;

        return Padding(
          padding: bottomPadding,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canContinue ? _handleNextSocial : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isGenerating || _isSkipping
                        ? const Color(0xFFE5E5E5)
                        : (canContinue
                              ? const Color(0xFF171717)
                              : const Color(0xFFE5E5E5)),
                    foregroundColor: _isGenerating || _isSkipping
                        ? const Color(0xFF6B7280)
                        : (canContinue
                              ? Colors.white
                              : const Color(0xFF6B7280).withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isGenerating || _isSkipping
                      ? const Text(
                          'Processing...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              // Skip 按钮（文本形式）
              if (!_isGenerating && !_isSkipping) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _handleSkipSocial,
                  child: const Text(
                    'Skip',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA3A3A3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      case GenerationStep.success:
        return Padding(
          padding: bottomPadding,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _redirectTimer?.cancel();
                context.go(_onboardingReturnPath ?? '/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'My DINQ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        );
      case GenerationStep.error:
        return Padding(
          padding: bottomPadding,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  setState(() => _currentStep = GenerationStep.start),
              child: const Text('Try again'),
            ),
          ),
        );
    }
  }

  double _progressValue() {
    switch (_currentStep) {
      case GenerationStep.start:
      case GenerationStep.upload:
      case GenerationStep.analyze:
      case GenerationStep.profileBasics:
      case GenerationStep.profileExpertise:
        return 0;
      case GenerationStep.domain:
        return 1 / 3;
      case GenerationStep.resume:
        return 2 / 3;
      case GenerationStep.social:
        return 1.0;
      case GenerationStep.welcome:
      case GenerationStep.onboardingSocials:
        return 1.0;
      case GenerationStep.success:
      case GenerationStep.error:
        return 1.0;
    }
  }

  String _subtitleForStep(GenerationStep step) {
    switch (step) {
      case GenerationStep.start:
      case GenerationStep.upload:
      case GenerationStep.analyze:
      case GenerationStep.profileBasics:
      case GenerationStep.profileExpertise:
        return '';
      case GenerationStep.domain:
        return 'Get your personalized DINQ Card in just a few steps.';
      case GenerationStep.resume:
        return "Let's start creating your DINQ Card.";
      case GenerationStep.social:
        return 'Last step! Your DINQ Card is almost ready!';
      case GenerationStep.welcome:
      case GenerationStep.onboardingSocials:
        return '';
      case GenerationStep.success:
      case GenerationStep.error:
        return '';
    }
  }

  Future<void> _nextFromDomain() async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty || !_isDomainValid()) return;
    setState(() {
      _error = null;
      _isClaimingDomain = true;
    });
    try {
      final flow = await _flowService.claimDomain(domain: domain);
      if (!mounted) return;
      context.read<UserStore>().setMyFlow(flow);
      setState(() {
        _currentStep = _profileDraftReady
            ? GenerationStep.social
            : GenerationStep.resume;
        _isClaimingDomain = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isClaimingDomain = false;
      });
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      final file = result.files.single;
      Uint8List? fileBytes = file.bytes;

      // 如果 bytes 为 null，尝试从 path 读取文件
      if (fileBytes == null && file.path != null) {
        try {
          final fileData = await File(file.path!).readAsBytes();
          fileBytes = fileData;
        } catch (e) {
          setState(() {
            _error = 'Failed to read file: $e';
          });
          return;
        }
      }

      if (fileBytes == null) {
        setState(() {
          _error = 'Failed to read file data';
        });
        return;
      }

      // 此时 fileBytes 已确保不为 null
      final fileSize = fileBytes.length;

      // 打印文件信息
      // 验证文件扩展名是否为 PDF
      final fileName = file.name.toLowerCase();
      if (!fileName.endsWith('.pdf')) {
        TopToastUtil.showError(
          context: context,
          title: 'Invalid file',
          description: 'Only PDF files are supported',
        );
        return;
      }

      // 验证文件大小（10MB）
      if (fileSize > MAX_FILE_SIZE) {
        TopToastUtil.showError(
          context: context,
          title: 'File too large',
          description: 'File is larger than 10MB',
        );
        return;
      }

      // 先设置文件名和文件大小，这样 UI 可以立即显示
      setState(() {
        _resumeController.text = file.name;
        _resumeFileSize = fileSize;
        _isUploading = true;
        _uploadProgress = 0;
        _uploadError = null;
      });

      try {
        if (_currentStep == GenerationStep.upload) {
          final credentials = await _onboardingService.uploadResumeFile(
            bytes: fileBytes,
            filename: file.name,
            onSendProgress: (sent, total) {
              final progress = total > 0 ? ((sent / total) * 100).round() : 0;
              if (mounted) {
                setState(() => _uploadProgress = progress);
              }
            },
          );
          final fileUrl = credentials['file_url'] as String;
          final fileKey = credentials['file_key'] as String?;
          final expiresAt = credentials['expires_at'] as String?;
          if (mounted) {
            setState(() {
              _uploadProgress = 100;
              _isUploading = false;
              _hasResume = true;
              _resumeUrl = fileUrl;
              _resumeFileKey = fileKey;
              _resumeUploadExpiresAt = expiresAt != null
                  ? DateTime.parse(expiresAt).millisecondsSinceEpoch
                  : null;
            });
            TopToastUtil.showSuccess(
              context: context,
              title: 'Resume uploaded',
            );
          }
        } else {
          final fileUrl = await _uploadService.uploadFile(
            bytes: fileBytes,
            filename: file.name,
            contentType: 'application/pdf',
            onSendProgress: (sent, total) {
              final progress = total > 0 ? ((sent / total) * 100).round() : 0;
              if (mounted) {
                setState(() {
                  _uploadProgress = progress;
                });
              }
            },
          );
          if (mounted) {
            setState(() {
              _uploadProgress = 100;
              _isUploading = false;
              _hasResume = true;
              _resumeUrl = fileUrl;
            });
            TopToastUtil.showSuccess(
              context: context,
              title: 'Resume uploaded',
            );
          }
        }
      } catch (error) {
        if (mounted) {
          final message = error.toString().replaceAll('Exception: ', '');
          setState(() {
            _uploadError = message.isEmpty
                ? 'Failed to upload resume'
                : message;
            _uploadProgress = 0;
            _isUploading = false;
            _hasResume = false;
            _resumeController.text = '';
            _resumeUrl = null;
            _resumeFileKey = null;
            _resumeUploadExpiresAt = null;
            _resumeFileSize = null;
          });
          TopToastUtil.showError(
            context: context,
            title: 'Upload failed',
            description: _uploadError!,
          );
        }
      }
    }
  }

  // 提取 URL（处理 iframe、协议等）
  String _extractUrlFromInput(String input) {
    if (input.isEmpty) return '';

    String url = input.trim();

    // Step 1: 从 iframe 代码或 data-url 属性中提取 URL
    if (input.contains('<iframe')) {
      // 匹配 src="..." 或 src='...'
      // 先尝试双引号
      final doubleQuotePattern = RegExp(r'src="([^"]+)"');
      var match = doubleQuotePattern.firstMatch(input);
      if (match == null) {
        // 再尝试单引号
        final singleQuotePattern = RegExp(r"src='([^']+)'");
        match = singleQuotePattern.firstMatch(input);
      }
      if (match != null) {
        final extracted = match.group(1);
        if (extracted != null && extracted.isNotEmpty) {
          url = extracted;
        }
      }
    } else if (input.contains('data-url=')) {
      // 匹配 data-url="..." 或 data-url='...'
      // 先尝试双引号
      final doubleQuotePattern = RegExp(r'data-url="([^"]+)"');
      var match = doubleQuotePattern.firstMatch(input);
      if (match == null) {
        // 再尝试单引号
        final singleQuotePattern = RegExp(r"data-url='([^']+)'");
        match = singleQuotePattern.firstMatch(input);
      }
      if (match != null) {
        final extracted = match.group(1);
        if (extracted != null && extracted.isNotEmpty) {
          url = extracted;
        }
      }
    }

    // Step 2: 修复协议相对 URL (// -> https://)
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // Step 3: 如果没有协议，添加 https://
    if (!url.startsWith(RegExp(r'^https?://', caseSensitive: false))) {
      url = 'https://$url';
    }

    return url;
  }

  // 验证 URL 是否有效（与 TypeScript isValidUrl 同步）
  bool _isValidUrl(String urlString) {
    try {
      final uri = Uri.parse(urlString);

      // 检查协议
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return false;
      }

      // 检查 hostname 不为空
      final hostname = uri.host;
      if (hostname.isEmpty) {
        return false;
      }

      // 只允许 ASCII 字符（字母、数字、点、连字符）
      if (!RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(hostname)) {
        return false;
      }

      // 检查 hostname 各部分有效（点之间不为空）
      final parts = hostname.split('.');
      if (parts.any((part) => part.isEmpty)) {
        return false;
      }

      // 拒绝纯数字 hostname
      final hasNonNumericPart = parts.any(
        (part) => !RegExp(r'^\d+$').hasMatch(part),
      );
      if (!hasNonNumericPart) {
        return false;
      }

      // 必须至少有 2 部分（例如 example.com）
      if (parts.length < 2) {
        return false;
      }

      // TLD（最后一部分）不能全是数字
      final tld = parts.last;
      if (RegExp(r'^\d+$').hasMatch(tld)) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // 获取 URL 错误（与 TypeScript getUrlError 同步）
  String? _getUrlError(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final processedUrl = _extractUrlFromInput(url);
    if (!_isValidUrl(processedUrl)) {
      return 'Please enter a valid URL.';
    }
    return null;
  }

  // 检测社交平台类型（用于生成流程）
  String? _detectSocialTypeForGeneration(String urlString) {
    try {
      final url =
          urlString.startsWith(RegExp(r'^https?://', caseSensitive: false))
          ? urlString
          : 'https://$urlString';
      final uri = Uri.parse(url);
      final hostname = uri.host.toLowerCase();

      // LinkedIn 特殊处理
      if (hostname.contains('linkedin.com')) return 'LINKEDIN';

      // 其他平台检测
      if (hostname.contains('github.com')) return 'GITHUB';
      if (hostname.contains('huggingface.co')) return 'HUGGINGFACE';
      if (hostname.contains('scholar.google')) return 'SCHOLAR';
      if (hostname.contains('openreview.net')) return 'OPENREVIEW';
      if (hostname.contains('twitter.com') || hostname.contains('x.com'))
        return 'TWITTER';

      return null;
    } catch (_) {
      return null;
    }
  }

  // 验证 LinkedIn 格式
  bool _isValidLinkedInFormat(String url) {
    return url.contains('/in/');
  }

  // 验证 URL（针对社交链接）
  String? _validateSocialUrl(SocialLink link) {
    final url = link.url.trim();
    if (url.isEmpty) return null;

    final processedUrl = _extractUrlFromInput(url);
    if (!_isValidUrl(processedUrl)) {
      return 'Please enter a valid URL';
    }

    // LINK 类型不需要平台验证
    if (link.type == 'LINK') return null;

    final detectedType = _detectSocialTypeForGeneration(url);
    if (detectedType != link.type) {
      return 'Please enter a valid ${link.platform} URL';
    }

    if (link.type == 'LINKEDIN' && !_isValidLinkedInFormat(url)) {
      return 'Please use LinkedIn profile URL (linkedin.com/in/username)';
    }

    return null;
  }

  // 从 flow 加载社交链接
  void _loadSocialLinksFromFlow(UserFlow? flow) {
    if (flow == null) {
      // 初始化推荐平台列表
      _socialLinks.clear();
      for (final type in RECOMMENDED_PLATFORMS) {
        final platformName = type;
        _socialLinks.add(
          SocialLink(
            platform: platformName,
            type: type,
            url: '',
            isValidated: false,
          ),
        );
      }
      return;
    }

    // 从 flow.social_links 加载（如果 UserFlow 有 social_links 字段）
    // 注意：当前 UserFlow 模型可能没有 social_links 字段，这里先初始化推荐平台
    _socialLinks.clear();
    final flowLinksMap = <String, String>{};

    // 如果有 social_links 数据，可以在这里处理
    // 暂时先初始化推荐平台列表
    for (final type in RECOMMENDED_PLATFORMS) {
      final platformName = type;
      final urlFromFlow = flowLinksMap[type] ?? '';
      _socialLinks.add(
        SocialLink(
          platform: platformName,
          type: type,
          url: urlFromFlow,
          isValidated: urlFromFlow.isNotEmpty,
        ),
      );
    }
  }

  // 添加新的 URL
  void _handleAddUrl() {
    final url = _newUrlController.text.trim();
    if (url.isEmpty) return;

    final processedUrl = _extractUrlFromInput(url);
    if (!_isValidUrl(processedUrl)) {
      TopToastUtil.showError(
        context: context,
        title: 'Invalid URL',
        description: 'Please enter a valid URL',
      );
      return;
    }

    final detectedType = _detectSocialTypeForGeneration(url) ?? 'LINK';

    if (detectedType == 'LINKEDIN' && !_isValidLinkedInFormat(url)) {
      TopToastUtil.showError(
        context: context,
        title: 'Invalid LinkedIn URL',
        description:
            'Please use LinkedIn profile URL (linkedin.com/in/username)',
      );
      return;
    }

    // 检查是否已存在该类型的链接
    final existingIndex = _socialLinks.indexWhere(
      (l) => l.type == detectedType,
    );
    if (existingIndex != -1) {
      if (_socialLinks[existingIndex].url.isNotEmpty) {
        TopToastUtil.showWarning(
          context: context,
          title: 'Notice',
          description:
              'You already have a ${_socialLinks[existingIndex].platform} link',
        );
        return;
      }
      // 更新现有链接
      setState(() {
        _socialLinks[existingIndex] = _socialLinks[existingIndex].copyWith(
          url: url,
          isValidated: true,
          error: null,
        );
      });
    } else {
      // 添加新链接
      final platformName = PLATFORM_CONFIG[detectedType] != null
          ? detectedType
          : 'Website';
      setState(() {
        _socialLinks.add(
          SocialLink(
            platform: platformName,
            type: detectedType,
            url: url,
            isValidated: true,
          ),
        );
      });
    }

    _newUrlController.clear();
  }

  // 获取 LinkedIn 警告（与 TypeScript getLinkedInWarning 同步）
  String? _getLinkedInWarning(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final processedUrl = _extractUrlFromInput(url);
    if (!_isValidUrl(processedUrl)) return null;

    try {
      final uri = Uri.parse(processedUrl);
      if (uri.host.toLowerCase().contains('linkedin')) {
        final pathMatch = RegExp(r'^/in/([^/]+)/?$').firstMatch(uri.path);
        if (pathMatch == null) {
          return 'LinkedIn profile URL should be in format: linkedin.com/in/username';
        }
        final username = pathMatch.group(1);
        if (username == null || username.isEmpty) {
          return 'LinkedIn profile URL should be in format: linkedin.com/in/username';
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _nextFromResume() async {
    // 验证：必须有简历或 LinkedIn URL
    if (_resumeUrl == null && _linkedinController.text.trim().isEmpty) {
      setState(() {
        _profileUrlError = 'Please upload a resume or provide a profile URL';
      });
      return;
    }

    // 验证 LinkedIn URL
    final urlError = _getUrlError(_linkedinController.text.trim());
    if (urlError != null) {
      setState(() {
        _profileUrlError = urlError;
        _profileUrlWarning = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _profileUrlError = null;
      _profileUrlWarning = null;
      _isAnalyzing = true;
    });

    try {
      final requestData = <String, dynamic>{};

      if (_resumeUrl != null) {
        requestData['file_url'] = _resumeUrl;
        requestData['file_name'] = _resumeController.text;
        // 如果有文件大小信息，也添加
        if (_resumeFileSize != null) {
          requestData['file_size'] = _resumeFileSize;
        }
      }

      final profileUrl = _linkedinController.text.trim();
      if (profileUrl.isNotEmpty) {
        requestData['profile_url'] = _extractUrlFromInput(profileUrl);
      }

      final result = await _flowService.analyzeResume(requestData);

      // 如果返回了 social_links，打印日志（与 TypeScript 一致）
      final userData = result['user_data'] as Map<String, dynamic>?;
      if (userData != null && userData['social_links'] != null) {
        // 注意：social_links 会在后续步骤中使用，这里只记录日志
        // TypeScript 中也是通过 setMyFlow({ social_links: ... }) 更新，但 UserFlow 模型简化了
      }

      // 更新 flow 状态为 resume（分析完成后进入 social 步骤）
      final userStore = context.read<UserStore>();
      final currentFlow = userStore.myFlow;
      if (currentFlow != null) {
        final updatedFlow = UserFlow(
          domain: currentFlow.domain,
          status: 'resume', // 分析完成后进入 social 步骤
        );
        userStore.setMyFlow(updatedFlow);
      }

      if (mounted) {
        setState(() {
          _currentStep = GenerationStep.social;
          _isAnalyzing = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        // 提取错误消息（与 TypeScript 一致）
        String errorMessage = 'Failed to analyze your resume.';
        if (error is Exception) {
          final errorStr = error.toString();
          // 尝试提取错误消息
          if (errorStr.contains('Exception: ')) {
            errorMessage = errorStr.split('Exception: ').last;
          } else if (errorStr.contains(':')) {
            errorMessage = errorStr.split(':').last.trim();
          } else {
            errorMessage = errorStr;
          }
        }

        TopToastUtil.showError(
          context: context,
          title: 'Analysis Failed',
          description: errorMessage,
        );
      }
    }
  }

  // 第三步：处理下一步（生成）
  Future<void> _handleNextSocial() async {
    final filledLinks = _socialLinks
        .where((l) => l.url.trim().isNotEmpty)
        .toList();

    if (filledLinks.isEmpty) {
      return;
    }

    // 验证所有 URL
    for (final link in filledLinks) {
      final error = _validateSocialUrl(link);
      if (error != null) {
        setState(() {
          final index = _socialLinks.indexOf(link);
          if (index != -1) {
            _socialLinks[index] = link.copyWith(error: error);
          }
        });
        TopToastUtil.showError(
          context: context,
          title: 'Validation Error',
          description: error,
        );
        return;
      }
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final socialLinksData = filledLinks.map((link) {
        return <String, dynamic>{
          'type': link.type.toLowerCase(),
          'url': _extractUrlFromInput(link.url.trim()),
        };
      }).toList();

      final result = await _flowService.generate({
        'social_links': socialLinksData,
      });

      final userStore = context.read<UserStore>();
      final flowData = result['flow'] as Map<String, dynamic>?;
      if (flowData != null) {
        final flow = UserFlow.fromJson(flowData);
        userStore.setMyFlow(flow);
      }
      await userStore.getCurrentUser();

      if (mounted) {
        setState(() {
          _currentStep = GenerationStep.success;
          _isGenerating = false;
        });
        _startRedirectCountdown();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _currentStep = GenerationStep.error;
          _isGenerating = false;
        });
        TopToastUtil.showError(
          context: context,
          title: 'Failed to generate DINQ Card',
          description: error.toString(),
        );
      }
    }
  }

  // 第二步：跳过简历上传
  void _handleSkipResume() {
    // 直接跳转到 social 步骤，不更新 flow status
    // flow status 保持为 'resume'，但 UI 步骤可以手动跳转到 social
    setState(() {
      _currentStep = GenerationStep.social;
    });
  }

  // 第三步：跳过社交链接
  Future<void> _handleSkipSocial() async {
    setState(() {
      _isSkipping = true;
    });

    try {
      final result = await _flowService.generate({'social_links': []});

      final userStore = context.read<UserStore>();
      final flowData = result['flow'] as Map<String, dynamic>?;
      if (flowData != null) {
        final flow = UserFlow.fromJson(flowData);
        userStore.setMyFlow(flow);
      }
      await userStore.getCurrentUser();

      if (mounted) {
        setState(() {
          _currentStep = GenerationStep.success;
          _isSkipping = false;
        });
        _startRedirectCountdown();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _currentStep = GenerationStep.error;
          _isSkipping = false;
        });
        TopToastUtil.showError(
          context: context,
          title: 'Failed to generate DINQ Card',
          description: error.toString(),
        );
      }
    }
  }

  String? _normalizeImportUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      final uri = Uri.parse(
        trimmed.startsWith('http') ? trimmed : 'https://$trimmed',
      );
      if (uri.scheme != 'http' && uri.scheme != 'https') return null;
      return uri.toString();
    } catch (_) {
      return null;
    }
  }

  void _handleStartGenerate() {
    final normalized = _normalizeImportUrl(_linkedinController.text);
    if (normalized == null) {
      setState(() {
        _startUrlError =
            'Please enter a valid LinkedIn or personal website URL.';
      });
      return;
    }
    setState(() {
      _startUrlError = null;
      _linkedinController.text = normalized;
    });
    _beginAnalyze(mode: 'url');
  }

  void _handleStartUpload() {
    setState(() => _currentStep = GenerationStep.upload);
  }

  void _handleUploadBack() {
    setState(() => _currentStep = GenerationStep.start);
  }

  Future<void> _handleUploadContinue() async {
    if (_isUploading) return;
    if (_resumeUploadExpiresAt != null &&
        _resumeUploadExpiresAt! <= DateTime.now().millisecondsSinceEpoch) {
      setState(() {
        _hasResume = false;
        _resumeUrl = null;
        _resumeFileKey = null;
        _resumeUploadExpiresAt = null;
        _resumeController.text = '';
        _resumeFileSize = null;
      });
      TopToastUtil.showError(
        context: context,
        title: 'Upload expired',
        description:
            'Your resume upload session expired. Please upload the resume again.',
      );
      return;
    }
    if (_resumeUrl == null || _resumeFileKey == null || !_hasResume) {
      TopToastUtil.showError(
        context: context,
        title: 'Upload required',
        description: 'Please upload a resume to continue',
      );
      return;
    }
    await _beginAnalyze(mode: 'resume');
  }

  Future<void> _beginAnalyze({required String mode}) async {
    setState(() {
      _analyzeMode = mode;
      _analyzeActiveStep = 0;
      _analyzeError = null;
      _currentStep = GenerationStep.analyze;
    });
    await _runAnalyze();
  }

  Future<void> _runAnalyze() async {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    for (var i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _analyzeActiveStep = i);
    }

    try {
      late final Map<String, dynamic> result;
      if (_analyzeMode == 'resume') {
        if (_resumeUploadExpiresAt != null &&
            _resumeUploadExpiresAt! <= DateTime.now().millisecondsSinceEpoch) {
          throw Exception(
            'Your resume upload session expired. Please upload the resume again.',
          );
        }
        if (_resumeUrl == null || _resumeFileKey == null) {
          throw Exception('Please upload a resume to continue');
        }
        result = await _onboardingService.createProfileDraft(
          sourceType: 'resume',
          fileUrl: _resumeUrl,
          fileKey: _resumeFileKey,
        );
      } else {
        final url = _extractUrlFromInput(_linkedinController.text.trim());
        if (url.isEmpty) {
          throw Exception(
            'Please enter a valid LinkedIn or personal website URL.',
          );
        }
        result = await _onboardingService.createProfileDraft(
          sourceType: 'url',
          url: url,
        );
      }

      if (!mounted) return;
      setState(() {
        _profileDraftReady = true;
        _useOnboardingHandle = true;
        _draftUserData = result['user_data'] as Map<String, dynamic>?;
        _isAnalyzing = false;
        _currentStep = GenerationStep.profileBasics;
      });
      _prefillProfileFromDraft();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceAll('Exception: ', '');
      setState(() {
        _isAnalyzing = false;
        _analyzeError = message.isEmpty
            ? 'Failed to generate your profile draft'
            : message;
      });
      TopToastUtil.showError(
        context: context,
        title: 'Analysis Failed',
        description: message,
      );
    }
  }

  void _handleAnalyzeRetry() {
    if (_analyzeMode == 'resume') {
      setState(() {
        _analyzeError = null;
        _hasResume = false;
        _resumeUrl = null;
        _resumeFileKey = null;
        _resumeUploadExpiresAt = null;
        _resumeController.text = '';
        _resumeFileSize = null;
        _currentStep = GenerationStep.upload;
      });
    } else {
      setState(() {
        _analyzeError = null;
        _currentStep = GenerationStep.start;
      });
    }
  }

  void _handleStartManual() {
    _resetOnboardingProfileDraft(clearDomain: _domainController.text.isEmpty);
    setState(() {
      _analyzeMode = 'manual';
      _useOnboardingHandle = true;
      _currentStep = GenerationStep.profileBasics;
    });
    _prefillProfileFromDraft();
  }

  void _resetOnboardingProfileDraft({required bool clearDomain}) {
    _profileDraftReady = false;
    _draftUserData = null;
    _profileTags = [];
    _profileBio = '';
    _profileAvatarUrl = '';
    _profileEducationLevel = '';
    _profileTimezone = '';
    _profileNameController.clear();
    _profilePositionController.clear();
    _profileCompanyController.clear();
    _profileSchoolController.clear();
    _profileLocationController.clear();
    _handleReservationToken = null;
    _handleReservedUntil = null;
    _onboardingFinalized = false;
    _welcomeFinalizeStarted = false;
    if (clearDomain) {
      _domainController.clear();
      _domainCheckResult = null;
    }
  }

  void _handleStartSkip() {
    setState(() {
      _useOnboardingHandle = true;
      _currentStep = GenerationStep.domain;
    });
  }

  void _prefillProfileFromDraft() {
    final data = _draftUserData;
    final user = context.read<UserStore>().user;
    final draftPosition = splitFullPosition(data?['full_position']?.toString());
    final draftDegree = splitFullDegree(data?['full_degree']?.toString());

    if (_profileNameController.text.isEmpty) {
      _profileNameController.text =
          data?['name']?.toString() ??
          user?.userData.name ??
          user?.user.name ??
          '';
    }
    if (_profilePositionController.text.isEmpty) {
      _profilePositionController.text =
          data?['position']?.toString() ??
          draftPosition.position ??
          user?.userData.fullPosition ??
          '';
    }
    if (_profileCompanyController.text.isEmpty) {
      _profileCompanyController.text =
          data?['company']?.toString() ?? draftPosition.company ?? '';
    }
    if (_profileSchoolController.text.isEmpty) {
      _profileSchoolController.text =
          data?['school']?.toString() ?? draftDegree.school ?? '';
    }
    if (_profileLocationController.text.isEmpty) {
      _profileLocationController.text =
          data?['location']?.toString() ?? user?.userData.location ?? '';
    }
    if (_profileEducationLevel.isEmpty) {
      _profileEducationLevel = normalizeEducationLevel(
        data?['degree']?.toString() ?? draftDegree.educationLevel,
      );
    }
    if (_profileTimezone.isEmpty) {
      _profileTimezone = normalizeOnboardingTimezone(
        data?['timezone']?.toString() ?? user?.userData.timezone,
      );
    }
    if (_profileAvatarUrl.isEmpty) {
      _profileAvatarUrl =
          data?['avatar_url']?.toString() ?? user?.userData.avatarUrl ?? '';
    }
    if (_profileBio.isEmpty) {
      _profileBio = data?['bio']?.toString() ?? user?.userData.bio ?? '';
    }
    if (_profileTags.isEmpty && data?['tags'] != null) {
      final raw = data!['tags'];
      if (raw is List) {
        _profileTags = normalizeProfileTags(
          raw.map((e) => e.toString()).toList(),
        );
      } else if (raw is String && raw.isNotEmpty) {
        _profileTags = splitTags(raw);
      }
    } else if (_profileTags.isEmpty && user?.userData.tags.isNotEmpty == true) {
      _profileTags = splitTags(user!.userData.tags);
    }
  }

  void _handleBasicsBack() {
    setState(() {
      if (_analyzeMode == 'resume') {
        _currentStep = GenerationStep.upload;
      } else {
        _currentStep = GenerationStep.start;
      }
    });
  }

  void _handleBasicsContinue() {
    setState(() => _currentStep = GenerationStep.profileExpertise);
  }

  void _handleExpertiseBack() {
    setState(() => _currentStep = GenerationStep.profileBasics);
  }

  void _handleExpertiseContinue() {
    setState(() {
      _useOnboardingHandle = true;
      _currentStep = GenerationStep.domain;
    });
  }

  void _handleHandleBack() {
    setState(() => _currentStep = GenerationStep.profileExpertise);
  }

  // handle 输入框不做任何自动预填：产品要求创建主页地址时默认为空、由用户
  // 手动输入（原 email/name 候选预填会把别人的主页预填成当前账号名）。

  void _onOnboardingHandleChanged(String nextValue) {
    final sanitized = nextValue.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final clipped = sanitized.length > 100
        ? sanitized.substring(0, 100)
        : sanitized;
    setState(() {
      _handleCharWarning = clipped != nextValue
          ? 'Only letters, numbers, _ and - are allowed'
          : null;
    });
    if (_domainController.text != clipped) {
      _domainController.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
    } else {
      _onDomainChanged();
    }
  }

  Future<void> _reserveHandleAndContinue() async {
    final handle = _domainController.text.trim();
    if (handle.isEmpty || !_isDomainValid()) return;
    setState(() {
      _error = null;
      _isReservingHandle = true;
    });
    try {
      final reservation = await _onboardingService.reserveHandle(
        handle: handle,
      );
      if (!mounted) return;
      final token = reservation['reservation_token']?.toString();
      final expiresAt = reservation['expires_at']?.toString();
      final reservedUntil = expiresAt != null
          ? DateTime.tryParse(expiresAt)?.millisecondsSinceEpoch
          : null;
      setState(() {
        _isReservingHandle = false;
        _handleReservationToken = token;
        _handleReservedUntil = reservedUntil;
        _welcomeStatus = OnboardingWelcomeStatus.saving;
        _welcomeError = null;
        _welcomeShouldUploadAgain = false;
        _welcomeFinalizeStarted = false;
        _onboardingFinalized = false;
        _currentStep = GenerationStep.welcome;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isReservingHandle = false;
        _domainCheckResult = {'available': false};
      });
      TopToastUtil.showError(
        context: context,
        title: 'Failed to reserve handle',
        description: message.isEmpty
            ? 'Failed to reserve this handle'
            : message,
      );
    }
  }

  Map<String, dynamic> _buildOnboardingUserDataPatch() {
    final data = _draftUserData ?? <String, dynamic>{};
    final user = context.read<UserStore>().user;
    final patch = <String, dynamic>{};

    final name = _profileNameController.text.trim().isNotEmpty
        ? _profileNameController.text.trim()
        : (data['name']?.toString() ??
              user?.userData.name ??
              user?.user.name ??
              '');
    final position = _profilePositionController.text.trim().isNotEmpty
        ? _profilePositionController.text.trim()
        : (data['position']?.toString() ?? user?.userData.fullPosition ?? '');
    final company = _profileCompanyController.text.trim().isNotEmpty
        ? _profileCompanyController.text.trim()
        : (data['company']?.toString() ?? '');
    final location = _profileLocationController.text.trim().isNotEmpty
        ? _profileLocationController.text.trim()
        : (data['location']?.toString() ?? user?.userData.location ?? '');
    final bio = _profileBio.trim().isNotEmpty
        ? _profileBio.trim()
        : (data['bio']?.toString() ?? user?.userData.bio ?? '');
    final tags = _profileTags.isNotEmpty
        ? normalizeProfileTags(_profileTags).join(',')
        : (data['tags']?.toString() ?? user?.userData.tags ?? '');
    final school = _profileSchoolController.text.trim().isNotEmpty
        ? _profileSchoolController.text.trim()
        : (data['school']?.toString() ?? '');
    final degree = _profileEducationLevel.isNotEmpty
        ? _profileEducationLevel
        : (data['degree']?.toString() ?? '');
    final timezone = _profileTimezone.isNotEmpty
        ? _profileTimezone
        : (data['timezone']?.toString() ?? user?.userData.timezone ?? '');
    final avatarUrl = _profileAvatarUrl.isNotEmpty
        ? _profileAvatarUrl
        : (data['avatar_url']?.toString() ?? '');

    if (name.isNotEmpty) patch['name'] = name;
    if (position.isNotEmpty) patch['position'] = position;
    if (company.isNotEmpty) patch['company'] = company;
    if (position.isNotEmpty || company.isNotEmpty) {
      patch['full_position'] = [
        position,
        company,
      ].where((e) => e.isNotEmpty).join(', ');
    }
    if (bio.isNotEmpty) {
      patch['bio'] = bio.length > profileBioLimit
          ? bio.substring(0, profileBioLimit)
          : bio;
    }
    if (location.isNotEmpty) patch['location'] = location;
    if (timezone.isNotEmpty) patch['timezone'] = timezone;
    if (tags.isNotEmpty) patch['tags'] = tags;
    if (school.isNotEmpty) patch['school'] = school;
    if (degree.isNotEmpty) patch['degree'] = degree;
    if (school.isNotEmpty || degree.isNotEmpty) {
      patch['full_degree'] = [
        degree,
        school,
      ].where((e) => e.isNotEmpty).join(', ');
    }
    if (avatarUrl.isNotEmpty) patch['avatar_url'] = avatarUrl;
    if (_resumeUrl != null && _resumeUrl!.isNotEmpty) {
      patch['resume'] = _resumeUrl;
    }
    final email = data['email']?.toString() ?? user?.user.email;
    if (email != null && email.isNotEmpty) patch['email'] = email;
    return patch;
  }

  Map<String, dynamic> _buildOnboardingSource() {
    if (_analyzeMode == 'resume' &&
        _resumeUrl != null &&
        _resumeFileKey != null) {
      return {
        'type': 'resume',
        'file_url': _resumeUrl,
        'file_key': _resumeFileKey,
      };
    }
    final profileUrl = _extractUrlFromInput(_linkedinController.text.trim());
    if (_analyzeMode == 'url' && profileUrl.isNotEmpty) {
      return {'type': 'url', 'profile_url': profileUrl};
    }
    return {'type': 'manual'};
  }

  List<Map<String, dynamic>> _buildOnboardingSocialLinksForComplete() {
    final draftLinks = _draftUserData?['social_links'];
    if (draftLinks is List && draftLinks.isNotEmpty) {
      return draftLinks
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final profileUrl = _extractUrlFromInput(_linkedinController.text.trim());
    if (profileUrl.contains('linkedin.com/')) {
      return [
        {'type': 'linkedin', 'url': profileUrl},
      ];
    }
    return [];
  }

  bool _isOnboardingAccountConflict(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('9006') ||
        message.contains('already has a dinq') ||
        message.contains('already has dinq');
  }

  bool _isOnboardingUploadSessionExpired(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('9002') ||
        message.contains('upload session expired');
  }

  Future<void> _finalizeOnboardingDraft() async {
    if (_onboardingFinalized) return;

    final userStore = context.read<UserStore>();
    if (!userStore.isLoggedIn()) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    final token = _handleReservationToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _welcomeStatus = OnboardingWelcomeStatus.error;
        _welcomeError =
            'Handle reservation expired. Please choose your handle again.';
      });
      return;
    }
    if (_handleReservedUntil != null &&
        _handleReservedUntil! <= DateTime.now().millisecondsSinceEpoch) {
      setState(() {
        _welcomeStatus = OnboardingWelcomeStatus.error;
        _welcomeError =
            'Handle reservation expired. Please choose your handle again.';
      });
      return;
    }

    if (_analyzeMode == 'resume' &&
        _resumeUploadExpiresAt != null &&
        _resumeUploadExpiresAt! <= DateTime.now().millisecondsSinceEpoch) {
      setState(() {
        _hasResume = false;
        _resumeUrl = null;
        _resumeFileKey = null;
        _welcomeStatus = OnboardingWelcomeStatus.error;
        _welcomeError =
            'Your resume upload session expired. Please upload the resume again.';
        _welcomeShouldUploadAgain = true;
      });
      return;
    }

    setState(() {
      _welcomeStatus = OnboardingWelcomeStatus.saving;
      _welcomeError = null;
      _welcomeShouldUploadAgain = false;
    });

    try {
      final result = await _onboardingService.complete(
        reservationToken: token,
        userData: _buildOnboardingUserDataPatch(),
        source: _buildOnboardingSource(),
        socialLinks: _buildOnboardingSocialLinksForComplete(),
      );

      final flowData = result['flow'] as Map<String, dynamic>?;
      if (flowData != null) {
        userStore.setMyFlow(UserFlow.fromJson(flowData));
      }
      await userStore.getCurrentUser();
      await userStore.getFlow();

      if (!mounted) return;
      setState(() {
        _onboardingFinalized = true;
        _welcomeStatus = OnboardingWelcomeStatus.ready;
      });
    } catch (error) {
      if (!mounted) return;
      if (_isOnboardingAccountConflict(error)) {
        context.go('/login');
        return;
      }
      setState(() {
        _welcomeShouldUploadAgain = _isOnboardingUploadSessionExpired(error);
        if (_welcomeShouldUploadAgain) {
          _hasResume = false;
          _resumeUrl = null;
          _resumeFileKey = null;
        }
        _welcomeError = error.toString().replaceAll('Exception: ', '');
        if (_welcomeError!.isEmpty) {
          _welcomeError = 'Failed to finish onboarding';
        }
        _welcomeStatus = OnboardingWelcomeStatus.error;
      });
    }
  }

  void _handleWelcomeRetry() {
    if (_welcomeShouldUploadAgain) {
      setState(() {
        _welcomeFinalizeStarted = false;
        _welcomeShouldUploadAgain = false;
        _welcomeError = null;
        _currentStep = GenerationStep.upload;
      });
      return;
    }
    setState(() {
      _welcomeFinalizeStarted = false;
      _welcomeStatus = OnboardingWelcomeStatus.saving;
    });
    _finalizeOnboardingDraft();
  }

  void _goToMydinq() {
    if (context.mounted) {
      context.go(_onboardingReturnPath ?? '/admin/mydinq');
    }
  }

  Future<void> _finishOnboardingSocials(List<OnboardingAddedLink> links) async {
    // 发布 DINQ Card 前必须先同意「Public Visibility」协议（对齐 web onboarding
    // 最后一步；缺此协议会导致流程走不下去）。Agree 才继续，Cancel 则停留。
    final agreed = await showAgreementProtocolConfirm(context);
    if (!agreed || !mounted) return;

    final domain =
        context.read<UserStore>().myFlow?.domain ??
        _domainController.text.trim();
    try {
      if (links.isNotEmpty) {
        if (domain.isEmpty) {
          throw Exception('DINQ Page is not ready yet');
        }
        final cardStore = context.read<CardStore>();
        await cardStore.loadCards(domain);
        for (final link in links) {
          await cardStore.addCard(type: link.type, metadata: {'url': link.url});
        }
      }

      if (!mounted) return;
      TopToastUtil.showSuccess(
        context: context,
        title: links.isEmpty ? 'Skipped social links' : 'Social links added',
      );
      _goToMydinq();
    } catch (error, stackTrace) {
      rethrow;
    }
  }
}

enum GenerationStep {
  start,
  upload,
  analyze,
  profileBasics,
  profileExpertise,
  domain,
  welcome,
  onboardingSocials,
  resume,
  social,
  success,
  error,
}

/// 移动端 fixed skip（桌面端由 OnboardingStartView 内联展示）。
class _StartSkipFooter extends StatelessWidget {
  const _StartSkipFooter({required this.hasOrg, required this.onSkip});

  final bool hasOrg;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (!isMobile) return const SizedBox.shrink();

    return TextButton(
      onPressed: onSkip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Skip for now',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B6862),
            ),
          ),
          const SizedBox(width: 6),
          const Text('→', style: TextStyle(color: Color(0xFF6B6862))),
        ],
      ),
    );
  }
}

// 社交链接数据模型
class SocialLink {
  final String platform;
  final String type;
  String url;
  bool isValidated;
  String? error;

  SocialLink({
    required this.platform,
    required this.type,
    this.url = '',
    this.isValidated = false,
    this.error,
  });

  SocialLink copyWith({
    String? platform,
    String? type,
    String? url,
    bool? isValidated,
    String? error,
  }) {
    return SocialLink(
      platform: platform ?? this.platform,
      type: type ?? this.type,
      url: url ?? this.url,
      isValidated: isValidated ?? this.isValidated,
      error: error,
    );
  }
}

// 推荐平台列表（按 UI 顺序）
const List<String> RECOMMENDED_PLATFORMS = [
  'LINKEDIN',
  'SCHOLAR',
  'GITHUB',
  'OPENREVIEW',
  'HUGGINGFACE',
  'TWITTER',
];

// 平台配置
const Map<String, Map<String, String>> PLATFORM_CONFIG = {
  'LINKEDIN': {
    'icon': 'assets/icons/logo/LinkedIn.png',
    'placeholder': 'Connect your career journey',
  },
  'SCHOLAR': {
    'icon': 'assets/icons/logo/GoogleScholar.png',
    'placeholder': 'Connect your academic authority',
  },
  'GITHUB': {
    'icon': 'assets/icons/logo/Github.png',
    'placeholder': 'Connect your engineering impact',
  },
  'OPENREVIEW': {
    'icon': 'assets/icons/logo/OpenReview.png',
    'placeholder': 'Connect your latest breakthroughs',
  },
  'HUGGINGFACE': {
    'icon': 'assets/icons/logo/HuggingFace.png',
    'placeholder': 'Connect your model repository',
  },
  'TWITTER': {
    'icon': 'assets/icons/logo/Twitter.png',
    'placeholder': 'Connect your professional voice',
  },
};
