import 'package:dinq_app/models/user_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith updates credits without losing subscription metadata', () {
    final subscription = Subscription.fromJson({
      'plan': 'pro_yearly',
      'status': 'active',
      'channel': 'apple',
      'credits_balance': 120,
      'monthly_credits': 100,
      'referral_credits': 20,
      'cancel_at_period_end': true,
      'current_period_end': '2027-07-22T00:00:00Z',
      'payg': {'enabled': true, 'status': 'active'},
    });

    final updated = subscription.copyWith(creditsBalance: 119);

    expect(updated.creditsBalance, 119);
    expect(updated.plan, 'pro_yearly');
    expect(updated.status, 'active');
    expect(updated.channel, 'apple');
    expect(updated.monthlyCredits, 100);
    expect(updated.referralCredits, 20);
    expect(updated.cancelAtPeriodEnd, isTrue);
    expect(updated.currentPeriodEnd, '2027-07-22T00:00:00Z');
    expect(updated.paygEnabled, isTrue);
    expect(updated.paygStatus, 'active');
  });

  test('serializes payment channel for locally preserved state', () {
    final subscription = Subscription.fromJson({
      'plan': 'basic_monthly',
      'status': 'active',
      'channel': 'apple',
      'credits_balance': 10,
      'monthly_credits': 10,
      'cancel_at_period_end': false,
    });

    expect(subscription.toJson()['channel'], 'apple');
  });
}
