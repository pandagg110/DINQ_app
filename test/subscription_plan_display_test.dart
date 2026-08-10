import 'package:flutter_test/flutter_test.dart';
import 'package:dinq_app/pages/marketing/subscription_plan_display.dart';

void main() {
  group('pricing upgrade state', () {
    final pricing = <String, dynamic>{
      'free': <String, dynamic>{'upgrade': false},
      'basic_yearly': <String, dynamic>{'upgrade': null},
      'pro_monthly': <String, dynamic>{'upgrade': false},
      'pro_yearly': <String, dynamic>{'upgrade': true},
    };

    test('uses the backend upgrade flag as the source of truth', () {
      expect(
        pricingPlanAction(pricing: pricing, plan: 'pro_yearly'),
        PricingPlanAction.upgrade,
      );
      expect(
        pricingPlanAction(pricing: pricing, plan: 'pro_monthly'),
        PricingPlanAction.unavailable,
      );
      expect(
        pricingPlanAction(pricing: pricing, plan: 'basic_yearly'),
        PricingPlanAction.current,
      );
    });

    test('treats a missing or malformed upgrade flag as unknown', () {
      expect(
        pricingPlanAction(pricing: pricing, plan: 'basic_monthly'),
        PricingPlanAction.unknown,
      );
      expect(
        pricingPlanAction(
          pricing: <String, dynamic>{
            'basic_monthly': <String, dynamic>{'upgrade': 'true'},
          },
          plan: 'basic_monthly',
        ),
        PricingPlanAction.unknown,
      );
    });

    test('maps backend states to user-facing button labels', () {
      expect(
        subscriptionButtonLabel(
          action: PricingPlanAction.upgrade,
          fallbackLabel: 'Subscribe',
        ),
        'Upgrade',
      );
      expect(
        subscriptionButtonLabel(
          action: PricingPlanAction.unavailable,
          fallbackLabel: 'Downgrade to Monthly',
        ),
        'Unavailable',
      );
      expect(
        subscriptionButtonLabel(
          action: PricingPlanAction.current,
          fallbackLabel: 'Subscribe',
        ),
        'Current Plan',
      );
      expect(
        subscriptionButtonLabel(
          action: PricingPlanAction.unknown,
          fallbackLabel: 'Subscribe',
        ),
        'Subscribe',
      );
    });
  });

  group('subscription plan visibility', () {
    test('hides Pro Yearly unless it is the current plan', () {
      expect(
        visibleSubscriptionBasePlans(
          billingPeriod: 'yearly',
          currentPlan: 'free',
        ),
        ['free', 'basic'],
      );
      expect(
        visibleSubscriptionBasePlans(
          billingPeriod: 'yearly',
          currentPlan: 'pro_yearly',
        ),
        ['free', 'basic', 'pro'],
      );
    });

    test('shows all monthly plans', () {
      expect(
        visibleSubscriptionBasePlans(
          billingPeriod: 'monthly',
          currentPlan: 'basic_yearly',
        ),
        ['free', 'basic', 'pro'],
      );
    });
  });

  group('subscription action labels', () {
    final cases = <(String, String, String, String)>[
      ('free', 'free', 'yearly', 'Current Plan'),
      ('free', 'basic', 'monthly', 'Subscribe'),
      ('free', 'basic', 'yearly', 'Subscribe'),
      ('free', 'pro', 'monthly', 'Subscribe'),
      ('basic_monthly', 'free', 'monthly', 'Switch to Free'),
      ('basic_monthly', 'basic', 'monthly', 'Current Plan'),
      ('basic_monthly', 'pro', 'monthly', 'Upgrade to Pro'),
      ('basic_monthly', 'basic', 'yearly', 'Switch to Yearly'),
      ('pro_monthly', 'free', 'monthly', 'Switch to Free'),
      ('pro_monthly', 'basic', 'monthly', 'Downgrade to Basic'),
      ('pro_monthly', 'pro', 'monthly', 'Current Plan'),
      ('pro_monthly', 'basic', 'yearly', 'Switch to Basic Yearly'),
      ('basic_yearly', 'free', 'yearly', 'Switch to Free'),
      ('basic_yearly', 'basic', 'monthly', 'Downgrade to Monthly'),
      ('basic_yearly', 'pro', 'monthly', 'Switch to Pro Monthly'),
      ('basic_yearly', 'basic', 'yearly', 'Current Plan'),
      ('pro_yearly', 'free', 'yearly', 'Switch to Free'),
      ('pro_yearly', 'basic', 'monthly', 'Downgrade to Basic'),
      ('pro_yearly', 'pro', 'monthly', 'Downgrade to Monthly'),
      ('pro_yearly', 'basic', 'yearly', 'Downgrade to Basic'),
      ('pro_yearly', 'pro', 'yearly', 'Current Plan'),
    ];

    for (final testCase in cases) {
      final (currentPlan, targetBasePlan, targetPeriod, expected) = testCase;
      test('$currentPlan -> ${targetBasePlan}_$targetPeriod', () {
        expect(
          subscriptionActionLabel(
            currentPlan: currentPlan,
            targetBasePlan: targetBasePlan,
            targetBillingPeriod: targetPeriod,
          ),
          expected,
        );
      });
    }

    test('uses Subscribe rather than Subscriber for signed-out users', () {
      expect(
        subscriptionActionLabel(
          currentPlan: 'free',
          targetBasePlan: 'basic',
          targetBillingPeriod: 'monthly',
          isLoggedIn: false,
        ),
        'Subscribe',
      );
    });

    test('shows a scheduled state after store cancellation is confirmed', () {
      expect(
        subscriptionActionLabel(
          currentPlan: 'pro_monthly',
          targetBasePlan: 'free',
          targetBillingPeriod: 'monthly',
          cancelAtPeriodEnd: true,
        ),
        'Cancellation scheduled',
      );
    });
  });

  group('initial selection', () {
    test('recommends Basic Yearly for free users', () {
      expect(initialSubscriptionSelection('free'), ('basic', 'yearly'));
    });

    test('selects the paid current plan', () {
      expect(initialSubscriptionSelection('basic_monthly'), (
        'basic',
        'monthly',
      ));
      expect(initialSubscriptionSelection('pro_yearly'), ('pro', 'yearly'));
    });
  });

  test('warns before a Pro Yearly user leaves that plan', () {
    expect(
      requiresProYearlyExitConfirmation(
        currentPlan: 'pro_yearly',
        targetBasePlan: 'basic',
        targetBillingPeriod: 'yearly',
      ),
      isTrue,
    );
    expect(
      requiresProYearlyExitConfirmation(
        currentPlan: 'pro_yearly',
        targetBasePlan: 'pro',
        targetBillingPeriod: 'yearly',
      ),
      isFalse,
    );
  });
}
