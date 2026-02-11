import 'package:dinq_app/utils/toast_util.dart';
import 'package:flutter/material.dart';

import '../../utils/color_util.dart';

/// 个人资料表单相关的常量配置
class ProfileFormConfig {
  // 性别选项
  static const List<String> genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  // 工作状态选项（value -> label 映射）
  static const Map<String, String> jobStatusOptions = {
    'Hiring': 'Hiring',
    'Open_to_work': 'Open to work',
    'Internship': 'Internship',
    'Freelance': 'Freelance',
  };

  // 获取工作状态的显示标签
  static String getJobStatusLabel(String? status) {
    if (status == null || status.isEmpty) return '';
    return jobStatusOptions[status] ?? status;
  }

  // 格式化日期为显示格式 (January 10, 1998)
  static String formatDateForDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  // 格式化日期为 API 格式 (2024-01-10)
  static String formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 个人资料表单的通用选择器工具类
class ProfileFormPickers {
  /// 显示日期选择器
  static Future<String?> showMyDatePicker({
    required BuildContext context,
    String? initialDateStr,
  }) async {
    DateTime initialDate;
    try {
      initialDate = initialDateStr != null && initialDateStr.isNotEmpty
          ? DateTime.parse(initialDateStr)
          : DateTime(1998, 1, 10);
    } catch (_) {
      initialDate = DateTime(1998, 1, 10);
    }

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorUtil.textColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ColorUtil.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      return ProfileFormConfig.formatDateForApi(picked);
    }
    return null;
  }

  /// 显示通用的底部选择器
  static Future<String?> showBottomPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    Map<String, String>? itemLabels,
    String? selectedValue,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
                color: ColorUtil.textColor,
              ),
            ),
            const SizedBox(height: 8),
            // Items
            ...items.map((item) {
              final displayLabel = itemLabels?[item] ?? item;
              final isSelected = item == selectedValue;
              return ListTile(
                title: Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Geist',
                    color: ColorUtil.textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: ColorUtil.textColor, size: 20)
                    : null,
                onTap: () => Navigator.pop(context, item),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 显示性别选择器
  static Future<String?> showGenderPicker({required BuildContext context, String? currentGender}) {
    return showBottomPicker(
      context: context,
      title: 'Select Gender',
      items: ProfileFormConfig.genderOptions,
      selectedValue: currentGender,
    );
  }

  /// 显示工作状态选择器
  static Future<String?> showJobStatusPicker({
    required BuildContext context,
    String? currentStatus,
  }) {
    return showBottomPicker(
      context: context,
      title: 'Select Status',
      items: ProfileFormConfig.jobStatusOptions.keys.toList(),
      itemLabels: ProfileFormConfig.jobStatusOptions,
      selectedValue: currentStatus,
    );
  }

  /// 显示文本编辑对话框
  static Future<String?> showTextEditDialog({
    required BuildContext context,
    required String title,
    String? initialValue,
    String? hintText,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
            color: ColorUtil.textColor,
          ),
        ),
        content: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(fontSize: 14, fontFamily: 'Geist', color: ColorUtil.textColor),
            decoration: InputDecoration(
              hintText: hintText ?? 'Enter $title',
              hintStyle: TextStyle(
                fontSize: 14,
                fontFamily: 'Geist',
                color: ColorUtil.sub3TextColor,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 14, fontFamily: 'Geist', color: ColorUtil.sub1TextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isEmpty) {
                ToastUtil.show("Cannot be empty");
              } else {
                Navigator.pop(context, controller.text);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
                color: ColorUtil.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
