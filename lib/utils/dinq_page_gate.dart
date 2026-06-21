import '../models/user_models.dart';

/// 对齐 Web `utils/dinqPageGate.ts`。
bool hasLiveDinqPage(UserFlow? flow) {
  return flow?.status == 'success' && flow!.domain.isNotEmpty;
}

bool hasExistingDinqPage(UserFlow? flow, UserData? userData) {
  return hasLiveDinqPage(flow) || userData?.domain.trim().isNotEmpty == true;
}

String? resolveDinqDomain(UserFlow? flow, UserData? userData) {
  if (hasLiveDinqPage(flow)) return flow!.domain;
  final fromUser = userData?.domain.trim();
  if (fromUser != null && fromUser.isNotEmpty) return fromUser;
  return null;
}
