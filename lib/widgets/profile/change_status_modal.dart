import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/user_store.dart';
import '../../utils/toast_util.dart';

class ChangeStatusModal extends StatefulWidget {
  const ChangeStatusModal({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.currentStatus,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String currentStatus;

  @override
  State<ChangeStatusModal> createState() => _ChangeStatusModalState();
}

class _ChangeStatusModalState extends State<ChangeStatusModal> {
  late String _selectedStatus;
  bool _isUpdating = false;

  static const List<Map<String, String>> _jobStatuses = [
    {'value': '', 'label': 'Not set'},
    {'value': 'Hiring', 'label': 'Hiring'},
    {'value': 'Open_to_work', 'label': 'Open to work'},
    {'value': 'Internship', 'label': 'Internship'},
    {'value': 'Freelance', 'label': 'Freelance'},
    {'value': 'Hidden', 'label': 'Hidden'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  void didUpdateWidget(ChangeStatusModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && oldWidget.currentStatus != widget.currentStatus) {
      _selectedStatus = widget.currentStatus;
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedStatus == widget.currentStatus) {
      widget.onClose();
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final userStore = context.read<UserStore>();
      await userStore.updateUserData({'job_status': _selectedStatus});
      widget.onClose();
      ToastUtil.showSuccess(
        context: context,
        title: '更新成功',
        description: '工作状态已更新',
      );
    } catch (error) {
      ToastUtil.showError(
        context: context,
        title: '更新失败',
        description: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Change Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 24),
                  color: const Color(0xFF171717),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus.isEmpty ? null : _selectedStatus,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF171717)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text(
                    'Not set',
                    style: TextStyle(color: Color(0x66303030)),
                  ),
                  items: _jobStatuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status['value']!.isEmpty ? null : status['value'],
                      child: Text(
                        status['label']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171717),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? '';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isUpdating ? null : widget.onClose,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF171717)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF171717),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

