import 'package:flutter/foundation.dart';

import '../models/resume_models.dart';
import '../services/account_service.dart';

class ResumeStore extends ChangeNotifier {
  final AccountService _service = AccountService();

  List<ResumeItem> resumes = [];
  ResumeItem? selectedResume;
  bool isLoadingList = false;
  bool isLoadingDetail = false;

  Future<void> loadResumes() async {
    isLoadingList = true;
    notifyListeners();
    try {
      final raw = await _service.getResumes();
      resumes = raw
          .map((e) => ResumeItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // 与最新列表对账：selectedResume 若已不在列表中（例如登出后换新账号、
      // 或新注册用户本无简历），必须清掉。否则残留上一用户的 selectedResume
      // 会让「空状态」判定（resumes.isNotEmpty || selectedResume != null）失效，
      // 新账号明明没简历却展示出一份简历。
      if (selectedResume != null &&
          !resumes.any((r) => r.id == selectedResume!.id)) {
        selectedResume = null;
      }
    } finally {
      isLoadingList = false;
      notifyListeners();
    }
  }

  /// 登出/切换账号时清空，避免跨用户残留（配合 UserStore.logout 调用）。
  void clear() {
    resumes = [];
    selectedResume = null;
    isLoadingList = false;
    isLoadingDetail = false;
    notifyListeners();
  }

  Future<ResumeItem?> selectResume(
    String id, {
    bool force = false,
    bool silent = false,
  }) async {
    if (!force && selectedResume?.id == id) {
      return selectedResume;
    }
    if (!silent) {
      isLoadingDetail = true;
      notifyListeners();
    }
    try {
      final data = await _service.getResume(id);
      final item = ResumeItem.fromJson(data);
      selectedResume = item;
      final idx = resumes.indexWhere((r) => r.id == id);
      if (idx >= 0) {
        resumes[idx] = item;
      }
      notifyListeners();
      return item;
    } finally {
      if (!silent) {
        isLoadingDetail = false;
        notifyListeners();
      }
    }
  }

  Future<ResumeItem> createResume({
    required String title,
    required String sourceUrl,
    required String fileName,
    bool select = true,
  }) async {
    final data = await _service.createResume(
      title: title,
      sourceUrl: sourceUrl,
      fileName: fileName,
    );
    final item = ResumeItem.fromJson(data);
    resumes = [item, ...resumes];
    if (select) {
      selectedResume = item;
    }
    notifyListeners();
    return item;
  }

  Future<void> updateResume(String id, {String? title}) async {
    final data = await _service.updateResume(id, title: title);
    final item = ResumeItem.fromJson(data);
    final idx = resumes.indexWhere((r) => r.id == id);
    if (idx >= 0) resumes[idx] = item;
    if (selectedResume?.id == id) selectedResume = item;
    notifyListeners();
  }

  Future<void> deleteResume(String id) async {
    await _service.deleteResume(id);
    resumes = resumes.where((r) => r.id != id).toList();
    if (selectedResume?.id == id) {
      selectedResume = resumes.isNotEmpty ? resumes.first : null;
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedResume = null;
    notifyListeners();
  }
}
