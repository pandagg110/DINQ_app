import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorTheme { blue, purple, green, orange, red }

enum SettingsSection { profile, account, verification, dinqcard, subscription }

class GridConfig {
  const GridConfig({
    required this.desktopColumns,
    required this.desktopUnitSize,
    required this.desktopGap,
    required this.mobileColumns,
    required this.mobileUnitSize,
    required this.mobileGap,
  });

  final int desktopColumns;
  final double desktopUnitSize;
  final double desktopGap;
  final int mobileColumns;
  final double mobileUnitSize;
  final double mobileGap;

  GridConfig copyWith({
    int? desktopColumns,
    double? desktopUnitSize,
    double? desktopGap,
    int? mobileColumns,
    double? mobileUnitSize,
    double? mobileGap,
  }) {
    return GridConfig(
      desktopColumns: desktopColumns ?? this.desktopColumns,
      desktopUnitSize: desktopUnitSize ?? this.desktopUnitSize,
      desktopGap: desktopGap ?? this.desktopGap,
      mobileColumns: mobileColumns ?? this.mobileColumns,
      mobileUnitSize: mobileUnitSize ?? this.mobileUnitSize,
      mobileGap: mobileGap ?? this.mobileGap,
    );
  }
}

class SettingsStore extends ChangeNotifier {
  SettingsStore() {
    _loadFromStorage();
  }

  ColorTheme colorTheme = ColorTheme.blue;
  String language = 'en';
  bool isMobile = false;
  bool isMobileHeaderVisible = true;
  GridConfig gridConfig = const GridConfig(
    desktopColumns: 8,
    desktopUnitSize: 72.5,
    desktopGap: 30,
    mobileColumns: 4,
    mobileUnitSize: 72.5,
    mobileGap: 30,
  );
  bool isProfileSettingsOpen = false;
  SettingsSection profileSettingsSection = SettingsSection.profile;
  bool isShareModalOpen = false;
  bool skipInviteCode = false;
  bool showActivation = false;
  int? activationDismissedAt;

  double mobileMaxWidth() {
    final config = gridConfig;
    return config.mobileColumns * config.mobileUnitSize + (config.mobileColumns - 1) * config.mobileGap;
  }

  void setColorTheme(ColorTheme theme) {
    colorTheme = theme;
    _persist();
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    _persist();
    notifyListeners();
  }

  void setIsMobile(bool value) {
    isMobile = value;
    notifyListeners();
  }

  void setMobileHeaderVisible(bool value) {
    isMobileHeaderVisible = value;
    notifyListeners();
  }

  void updateGridConfig(GridConfig config) {
    gridConfig = config;
    notifyListeners();
  }

  void openProfileSettings([SettingsSection section = SettingsSection.profile]) {
    if (isMobile) {
      return;
    }
    isProfileSettingsOpen = true;
    profileSettingsSection = section;
    notifyListeners();
  }

  void closeProfileSettings() {
    isProfileSettingsOpen = false;
    notifyListeners();
  }

  void setProfileSettingsSection(SettingsSection section) {
    profileSettingsSection = section;
    notifyListeners();
  }

  void openShareModal() {
    isShareModalOpen = true;
    notifyListeners();
  }

  void closeShareModal() {
    isShareModalOpen = false;
    notifyListeners();
  }

  void setHasSkippedInviteCode(bool value) {
    skipInviteCode = value;
    _persist();
    notifyListeners();
  }

  void setShowActivation(bool value) {
    showActivation = value;
    notifyListeners();
  }

  void dismissActivation() {
    showActivation = false;
    activationDismissedAt = DateTime.now().millisecondsSinceEpoch;
    _persist();
    notifyListeners();
  }

  bool canShowActivation() {
    if (activationDismissedAt == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - activationDismissedAt!;
    return elapsed >= const Duration(hours: 24).inMilliseconds;
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('settings.colorTheme');
    final storedLanguage = prefs.getString('settings.language');
    final skippedInvite = prefs.getBool('settings.skipInviteCode');
    final dismissedAt = prefs.getInt('settings.activationDismissedAt');

    if (theme != null) {
      colorTheme = ColorTheme.values.firstWhere(
        (value) => value.name == theme,
        orElse: () => ColorTheme.blue,
      );
    }
    if (storedLanguage != null) {
      language = storedLanguage;
    }
    if (skippedInvite != null) {
      skipInviteCode = skippedInvite;
    }
    activationDismissedAt = dismissedAt;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings.colorTheme', colorTheme.name);
    await prefs.setString('settings.language', language);
    await prefs.setBool('settings.skipInviteCode', skipInviteCode);
    if (activationDismissedAt != null) {
      await prefs.setInt('settings.activationDismissedAt', activationDismissedAt!);
    }
  }
}


