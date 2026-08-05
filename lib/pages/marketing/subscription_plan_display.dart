const List<String> subscriptionBasePlanOrder = ['free', 'basic', 'pro'];

List<String> visibleSubscriptionBasePlans({
  required String billingPeriod,
  required String currentPlan,
}) {
  if (billingPeriod != 'yearly' || currentPlan == 'pro_yearly') {
    return List<String>.of(subscriptionBasePlanOrder);
  }
  return const ['free', 'basic'];
}

(String, String) initialSubscriptionSelection(String currentPlan) {
  final parts = _planParts(currentPlan);
  if (parts == null || currentPlan == 'free') return ('basic', 'yearly');
  return parts;
}

String subscriptionActionLabel({
  required String currentPlan,
  required String targetBasePlan,
  required String targetBillingPeriod,
  bool isLoggedIn = true,
}) {
  if (!isLoggedIn) {
    return targetBasePlan == 'free' ? 'Get started' : 'Subscribe';
  }

  final targetPlan = targetBasePlan == 'free'
      ? 'free'
      : '${targetBasePlan}_$targetBillingPeriod';
  if (targetPlan == currentPlan) return 'Current Plan';
  if (targetBasePlan == 'free') return 'Switch to Free';
  if (currentPlan == 'free') return 'Subscribe';

  return switch ((currentPlan, targetPlan)) {
    ('basic_monthly', 'pro_monthly') => 'Upgrade to Pro',
    ('basic_monthly', 'basic_yearly') => 'Switch to Yearly',
    ('pro_monthly', 'basic_monthly') => 'Downgrade to Basic',
    ('pro_monthly', 'basic_yearly') => 'Switch to Basic Yearly',
    ('basic_yearly', 'basic_monthly') => 'Downgrade to Monthly',
    ('basic_yearly', 'pro_monthly') => 'Switch to Pro Monthly',
    ('pro_yearly', 'basic_monthly') => 'Downgrade to Basic',
    ('pro_yearly', 'pro_monthly') => 'Downgrade to Monthly',
    ('pro_yearly', 'basic_yearly') => 'Downgrade to Basic',
    _ => _fallbackActionLabel(
      currentPlan: currentPlan,
      targetBasePlan: targetBasePlan,
      targetBillingPeriod: targetBillingPeriod,
    ),
  };
}

bool requiresProYearlyExitConfirmation({
  required String currentPlan,
  required String targetBasePlan,
  required String targetBillingPeriod,
}) {
  if (currentPlan != 'pro_yearly') return false;
  return targetBasePlan != 'pro' || targetBillingPeriod != 'yearly';
}

String _fallbackActionLabel({
  required String currentPlan,
  required String targetBasePlan,
  required String targetBillingPeriod,
}) {
  final currentParts = _planParts(currentPlan);
  if (currentParts == null) return 'Subscribe';
  final (currentBasePlan, currentPeriod) = currentParts;
  if (currentPeriod != targetBillingPeriod) {
    final targetLabel = _titleCase(targetBasePlan);
    final periodLabel = _titleCase(targetBillingPeriod);
    return 'Switch to $targetLabel $periodLabel';
  }
  final currentLevel = _planLevel(currentBasePlan);
  final targetLevel = _planLevel(targetBasePlan);
  return targetLevel > currentLevel
      ? 'Upgrade to ${_titleCase(targetBasePlan)}'
      : 'Downgrade to ${_titleCase(targetBasePlan)}';
}

(String, String)? _planParts(String plan) {
  if (plan == 'free') return null;
  for (final period in const ['monthly', 'yearly']) {
    final suffix = '_$period';
    if (plan.endsWith(suffix)) {
      final basePlan = plan.substring(0, plan.length - suffix.length);
      if (basePlan == 'basic' || basePlan == 'pro') {
        return (basePlan, period);
      }
    }
  }
  return null;
}

int _planLevel(String plan) => switch (plan) {
  'pro' => 2,
  'basic' => 1,
  _ => 0,
};

String _titleCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
