import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/flow_service.dart';
import '../services/payment_service.dart';
import '../services/profile_service.dart';

class UserStore extends ChangeNotifier {
  UserStore() {
    _authService = AuthService();
    _profileService = ProfileService();
    _flowService = FlowService();
    _paymentService = PaymentService();
    ApiClient.instance.setUnauthorizedHandler(logout);
    _loadToken();
  }

  late final AuthService _authService;
  late final ProfileService _profileService;
  late final FlowService _flowService;
  late final PaymentService _paymentService;

  UserProfile? user;
  UserData? cardOwner;
  String? authToken;
  bool isLoading = false;
  UserFlow? myFlow;
  bool isLoadingFlow = false;
  bool isInitialized = false;
  Map<String, dynamic>? verify;
  List<dynamic> connectedAccounts = [];
  bool isUnlinkingAccount = false;
  Subscription? subscription;
  bool isLoadingSubscription = false;

  bool isLoggedIn() => authToken != null && authToken!.isNotEmpty;

  Future<void> initialize() async {
    if (authToken == null || authToken!.isEmpty) {
      isInitialized = true;
      notifyListeners();
      return;
    }

    await Future.wait([
      getCurrentUser(),
      getFlow(),
      loadSubscription(),
    ]);
    isInitialized = true;
    notifyListeners();
    await loadVerifications();
    await loadUserAccounts();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('user.authToken');
    ApiClient.instance.setAuthToken(authToken);
    await initialize();
  }

  Future<void> _persistToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (authToken == null) {
      await prefs.remove('user.authToken');
    } else {
      await prefs.setString('user.authToken', authToken!);
    }
  }

  void setCardOwner(UserData? data) {
    cardOwner = data;
    notifyListeners();
  }

  Future<UserProfile?> login({required String email, required String password}) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.login(email: email, password: password);
      authToken = result['token']?.toString();
      ApiClient.instance.setAuthToken(authToken);
      await _persistToken();
      await initialize();
      isLoading = false;
      notifyListeners();
      return user;
    } catch (_) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String verificationCode,
    String? inviteCode,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        verificationCode: verificationCode,
        inviteCode: inviteCode,
      );
      authToken = result['token']?.toString();
      ApiClient.instance.setAuthToken(authToken);
      await _persistToken();
      await initialize();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    user = null;
    authToken = null;
    myFlow = null;
    verify = null;
    subscription = null;
    ApiClient.instance.setAuthToken(null);
    _persistToken();
    notifyListeners();
  }

  Future<UserProfile?> getCurrentUser() async {
    if (authToken == null || authToken!.isEmpty) return null;
    try {
      user = await _authService.getUserProfile();
      notifyListeners();
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserBase(Map<String, dynamic> payload) async {
    if (user == null) return;
    user = UserProfile(
      user: User.fromJson({...user!.user.toJson(), ...payload}),
      userData: user!.userData,
    );
    notifyListeners();
  }

  Future<void> updateUserData(Map<String, dynamic> payload) async {
    if (user == null) return;
    user = UserProfile(
      user: user!.user,
      userData: UserData.fromJson({...user!.userData.toJson(), ...payload}),
    );
    notifyListeners();
    await _profileService.updateUserData(payload);
  }

  Future<Map<String, dynamic>?> loadVerifications() async {
    if (!isLoggedIn()) {
      verify = null;
      notifyListeners();
      return null;
    }
    try {
      verify = await _profileService.getVerificationOverview();
      notifyListeners();
      return verify;
    } catch (_) {
      return null;
    }
  }

  void updateVerify(String type, Map<String, dynamic> updates) {
    verify ??= {};
    final current = Map<String, dynamic>.from(verify!);
    current[type] = {...(current[type] ?? {}), ...updates};
    verify = current;
    notifyListeners();
  }

  Future<void> loadUserAccounts() async {
    try {
      final response = await _profileService.getAccounts();
      connectedAccounts = response['accounts'] as List<dynamic>? ?? [];
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> unlinkAccount({required String provider}) async {
    isUnlinkingAccount = true;
    notifyListeners();
    try {
      await _profileService.unlinkAccount(provider: provider);
      await loadUserAccounts();
    } finally {
      isUnlinkingAccount = false;
      notifyListeners();
    }
  }

  Future<UserFlow?> getFlow() async {
    if (!isLoggedIn()) {
      myFlow = null;
      notifyListeners();
      return null;
    }
    isLoadingFlow = true;
    notifyListeners();
    try {
      myFlow = await _flowService.getFlow();
      return myFlow;
    } catch (_) {
      myFlow = null;
      return null;
    } finally {
      isLoadingFlow = false;
      notifyListeners();
    }
  }

  void setMyFlow(UserFlow? flow) {
    myFlow = flow;
    notifyListeners();
  }

  Future<void> resetFlow() async {
    await _flowService.resetFlow();
    await getFlow();
  }

  Future<Subscription?> loadSubscription() async {
    if (!isLoggedIn()) {
      subscription = null;
      notifyListeners();
      return null;
    }
    isLoadingSubscription = true;
    notifyListeners();
    try {
      subscription = await _paymentService.getSubscription();
      return subscription;
    } catch (_) {
      subscription = Subscription(
        plan: 'free',
        status: 'active',
        creditsBalance: 3,
        monthlyCredits: 3,
        cancelAtPeriodEnd: false,
      );
      return subscription;
    } finally {
      isLoadingSubscription = false;
      notifyListeners();
    }
  }

  Future<void> refreshSubscription() async {
    await loadSubscription();
  }

  void deductCredit([int amount = 1]) {
    if (subscription == null) return;
    subscription = Subscription(
      plan: subscription!.plan,
      status: subscription!.status,
      creditsBalance: (subscription!.creditsBalance - amount).clamp(0, 999999),
      monthlyCredits: subscription!.monthlyCredits,
      cancelAtPeriodEnd: subscription!.cancelAtPeriodEnd,
    );
    notifyListeners();
  }
}


