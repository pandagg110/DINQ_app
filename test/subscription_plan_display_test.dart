import 'package:flutter_test/flutter_test.dart';
import 'package:dinq_app/pages/marketing/subscription_plan_display.dart';

void main() {
  group('pricing plan action', () {
    final actionCases = <String, PricingPlanAction>{
      'CURRENT_PLAN': PricingPlanAction.currentPlan,
      'UPGRADE_TIER': PricingPlanAction.upgradeTier,
      'UPGRADE_PERIOD': PricingPlanAction.upgradePeriod,
      'UPGRADE_TIER_AND_PERIOD': PricingPlanAction.upgradeTierAndPeriod,
      'SWITCH_TO_FREE': PricingPlanAction.switchToFree,
      'PENDING_SWITCH_TO_FREE': PricingPlanAction.pendingSwitchToFree,
      'BLOCKED_TIER_DOWNGRADE': PricingPlanAction.blockedTierDowngrade,
      'BLOCKED_PERIOD_DOWNGRADE': PricingPlanAction.blockedPeriodDowngrade,
    };

    for (final entry in actionCases.entries) {
      test('parses ${entry.key}', () {
        expect(
          pricingPlanAction(
            pricing: <String, dynamic>{
              'target': <String, dynamic>{'action': entry.key},
            },
            plan: 'target',
          ),
          entry.value,
        );
      });
    }

    test('maps all actions to button labels', () {
      final labels = <PricingPlanAction, String>{
        PricingPlanAction.currentPlan: 'Current plan',
        PricingPlanAction.upgradeTier: 'Upgrade',
        PricingPlanAction.upgradePeriod: 'Switch to Yearly',
        PricingPlanAction.upgradeTierAndPeriod: 'Upgrade',
        PricingPlanAction.switchToFree: 'Switch to Free',
        PricingPlanAction.pendingSwitchToFree: 'Switching to Free',
        PricingPlanAction.blockedTierDowngrade: 'Included with Basic',
        PricingPlanAction.blockedPeriodDowngrade: 'Yearly plan active',
      };

      for (final entry in labels.entries) {
        expect(
          subscriptionButtonLabel(
            action: entry.key,
            currentPlan: 'basic_yearly',
            fallbackLabel: 'Fallback',
          ),
          entry.value,
        );
      }
    });

    test('only upgrade and switch-to-free actions are clickable', () {
      for (final action in const [
        PricingPlanAction.upgradeTier,
        PricingPlanAction.upgradePeriod,
        PricingPlanAction.upgradeTierAndPeriod,
        PricingPlanAction.switchToFree,
        PricingPlanAction.legacyUpgrade,
      ]) {
        expect(pricingPlanActionEnabled(action), isTrue);
      }
      for (final action in const [
        PricingPlanAction.currentPlan,
        PricingPlanAction.pendingSwitchToFree,
        PricingPlanAction.blockedTierDowngrade,
        PricingPlanAction.blockedPeriodDowngrade,
        PricingPlanAction.legacyUnavailable,
      ]) {
        expect(pricingPlanActionEnabled(action), isFalse);
      }
      expect(pricingPlanActionEnabled(PricingPlanAction.unknown), isNull);
    });

    test('falls back to the legacy upgrade field during rollout', () {
      expect(
        pricingPlanAction(
          pricing: <String, dynamic>{
            'upgrade': <String, dynamic>{'upgrade': true},
            'blocked': <String, dynamic>{'upgrade': false},
            'current': <String, dynamic>{'upgrade': null},
          },
          plan: 'upgrade',
        ),
        PricingPlanAction.legacyUpgrade,
      );
      expect(
        pricingPlanAction(
          pricing: <String, dynamic>{
            'blocked': <String, dynamic>{'upgrade': false},
          },
          plan: 'blocked',
        ),
        PricingPlanAction.legacyUnavailable,
      );
      expect(
        pricingPlanAction(
          pricing: <String, dynamic>{
            'current': <String, dynamic>{'upgrade': null},
          },
          plan: 'current',
        ),
        PricingPlanAction.currentPlan,
      );
    });

    test('treats unknown action values as unknown instead of guessing', () {
      expect(
        pricingPlanAction(
          pricing: <String, dynamic>{
            'target': <String, dynamic>{
              'action': 'NEW_ACTION',
              'upgrade': true,
            },
          },
          plan: 'target',
        ),
        PricingPlanAction.unknown,
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
