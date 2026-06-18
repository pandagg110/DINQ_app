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
    } finally {
      isLoadingList = false;
      notifyListeners();
    }
  }

  Future<ResumeItem?> selectResume(
    String id, {
    bool force = false,
    bool silent = false,
  }) async {
    if (!force && selectedResume?.id == id && selectedResume?.status != ResumeStatus.processing) {
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
