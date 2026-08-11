import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../stores/user_store.dart';
import '../widgets/subscription/subscription_managed_elsewhere_dialog.dart';
import 'app_update_service.dart' show distributionChannel;
import 'payment_channel.dart';

enum SubscriptionPricingNavigationMode { push, go }

Future<void> openSubscriptionPricing(
  BuildContext context, {
  SubscriptionPricingNavigationMode mode =
      SubscriptionPricingNavigationMode.push,
}) async {
  final subscription = context.read<UserStore>().subscription;
  final paymentChannel = resolveSubscriptionPaymentChannel(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    distributionChannel: distributionChannel,
  );

  if (isSubscriptionManagedElsewhere(
    isFree: subscription?.isFree ?? true,
    subscriptionChannel: subscription?.channel,
    paymentChannel: paymentChannel,
  )) {
    await showSubscriptionManagedElsewhereDialog(
      context,
      subscriptionChannel: subscription?.channel,
    );
    return;
  }

  if (!context.mounted) return;
  switch (mode) {
    case SubscriptionPricingNavigationMode.push:
      context.push('/pricing');
      return;
    case SubscriptionPricingNavigationMode.go:
      context.go('/pricing');
      return;
  }
}
