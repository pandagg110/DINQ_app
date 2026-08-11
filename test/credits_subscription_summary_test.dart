import 'package:dinq_app/models/user_models.dart';
import 'package:dinq_app/pages/settings/credits_subscription_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yearly subscriptions show billing period and renewal date', () {
    final subscription = _subscription(
      plan: 'pro_yearly',
      currentPeriodEnd: '2027-07-28T00:00:00Z',
    );

    expect(subscriptionBillingLabel(subscription), 'Billed annually');
    expect(subscriptionRenewalLabel(subscription), 'Renews on July 28, 2027');
  });

  test('monthly subscriptions show monthly billing', () {
    final subscription = _subscription(
      plan: 'basic_monthly',
      currentPeriodEnd: '2026-08-11T00:00:00Z',
    );

    expect(subscriptionBillingLabel(subscription), 'Billed monthly');
  });

  test('cancelled subscriptions show their access end date', () {
    final subscription = _subscription(
      plan: 'basic_yearly',
      currentPeriodEnd: '2027-07-28T00:00:00Z',
      cancelAtPeriodEnd: true,
    );

    expect(subscriptionRenewalLabel(subscription), 'Ends on July 28, 2027');
  });

  test('free and incomplete subscriptions omit billing metadata', () {
    expect(subscriptionBillingLabel(_subscription(plan: 'free')), isNull);
    expect(subscriptionRenewalLabel(_subscription(plan: 'free')), isNull);
    expect(subscriptionRenewalLabel(_subscription(plan: 'pro_yearly')), isNull);
  });
}

Subscription _subscription({
  required String plan,
  String? currentPeriodEnd,
  bool cancelAtPeriodEnd = false,
}) => Subscription(
  plan: plan,
  status: 'active',
  creditsBalance: 0,
  monthlyCredits: 0,
  cancelAtPeriodEnd: cancelAtPeriodEnd,
  currentPeriodEnd: currentPeriodEnd,
);
