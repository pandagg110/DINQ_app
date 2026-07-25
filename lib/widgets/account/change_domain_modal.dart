import 'dart:async';
import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/utils/unfocus_on_tap_outside.dart';
import 'package:flutter/material.dart';
import '../../services/flow_service.dart';

class ChangeDomainModal extends StatefulWidget {
  final String currentDomain;
  final void Function(String newDomain)? onSuccess;

  const ChangeDomainModal({
    super.key,
    required this.currentDomain,
    this.onSuccess,
  });

  @override
  State<ChangeDomainModal> createState() => _ChangeDomainModalState();
}

class _ChangeDomainModalState extends State<ChangeDomainModal> {
  final _controller = TextEditingController();
  final _flowService = FlowService();
  Timer? _debounceTimer;

  bool _isChecking = false;
  bool _isSubmitting = false;
  bool _isAvailable = false;
  String? _error;
  String? _charWarning;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.currentDomain;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;

    // 过滤非法字符
    final sanitized = text.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    if (text != sanitized) {
      _controller.text = sanitized;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: sanitized.length),
      );
      setState(() {
        _charWarning = 'Only letters, numbers, _ and - are allowed';
      });
      return;
    } else {
      setState(() {
        _charWarning = null;
      });
    }

    // 长度限制
    if (sanitized.length > 100) {
      _controller.text = sanitized.substring(0, 100);
      _controller.selection = TextSelection.fromPosition(
        const TextPosition(offset: 100),
      );
      return;
    }

    // 重置状态
    setState(() {
      _error = null;
      _isAvailable = false;
      _suggestions = [];
    });

    // Debounce 检查可用性
    _debounceTimer?.cancel();
    if (sanitized.length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _checkDomainAvailability(sanitized);
      });
    }
  }

  Future<void> _checkDomainAvailability(String domain) async {
    if (domain.toLowerCase() == widget.currentDomain.toLowerCase()) {
      setState(() {
        _isAvailable = false;
        _error = null;
      });
      return;
    }

    setState(() => _isChecking = true);
    try {
      final result = await _flowService.checkDomain(domain: domain);
      if (!mounted) return;

      final available = result['available'] == true;
      final suggestions = (result['suggestions'] as List<dynamic>?)?.cast<String>() ?? [];

      setState(() {
        _isAvailable = available;
        _suggestions = suggestions;
        if (!available && suggestions.isEmpty) {
          _error = 'This username is already taken';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to check availability';
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    final domain = _controller.text.trim();

    if (domain.isEmpty) {
      setState(() => _error = 'Please enter a username');
      return;
    }

    if (domain.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters');
      return;
    }

    if (domain.toLowerCase() == widget.currentDomain.toLowerCase()) {
      setState(() => _error = 'Please enter a different username');
      return;
    }

    if (!_isAvailable) {
      setState(() => _error = 'This username is not available');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _flowService.claimDomain(domain: domain);
      if (!mounted) return;

      Navigator.pop(context);
      widget.onSuccess?.call(domain);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to change username: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _checkDomainAvailability(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final domain = _controller.text;
    final isSameUsername = domain.toLowerCase() == widget.currentDomain.toLowerCase();
    final canSubmit = domain.length >= 3 && _isAvailable && !_isChecking && !_isSubmitting;
    return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Change DINQ ID',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorUtil.textColor,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current domain
                    if (widget.currentDomain.isNotEmpty) ...[
                      Text(
                        'Current DINQ ID',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ColorUtil.textColor,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'dinq.me/${widget.currentDomain}',
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorUtil.sub2TextColor,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // New domain
                    Text(
                      'New DINQ ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorUtil.textColor,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _error != null ? Colors.red : ColorUtil.sub4TextColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'dinq.me/',
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorUtil.sub2TextColor,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onTapOutside: unfocusOnTapOutside,
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorUtil.textColor,
                                fontFamily: 'Geist',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter new ID',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: ColorUtil.sub2TextColor,
                                  fontFamily: 'Geist',
                                ),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_isChecking)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else if (domain.length >= 3 && _isAvailable && !isSameUsername)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ),
                        ],
                      ),
                    ),
                    // Character warning
                    if (_charWarning != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _charWarning!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                    // Error message
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Suggestions
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Suggestions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ColorUtil.textColor,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestions.map((suggestion) {
                          return GestureDetector(
                            onTap: () => _selectSuggestion(suggestion),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE6E6E6)),
                              ),
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorUtil.textColor,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    // Hint
                    const SizedBox(height: 16),
                    Text(
                      'Only letters, numbers, _ and - are allowed. 3-100 characters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorUtil.sub2TextColor,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorUtil.textColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: ColorUtil.sub4TextColor,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Geist',
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}
