enum StoreSubscriptionChannel { apple, googlePlay }

StoreSubscriptionChannel? storeSubscriptionChannelFromApi(String? channel) {
  return switch (channel) {
    'apple' => StoreSubscriptionChannel.apple,
    'google_play' => StoreSubscriptionChannel.googlePlay,
    _ => null,
  };
}

class StoreCancellationCopy {
  const StoreCancellationCopy({
    required this.title,
    required this.description,
    required this.continueLabel,
  });

  final String title;
  final String description;
  final String continueLabel;
}

StoreCancellationCopy storeCancellationCopy({
  required StoreSubscriptionChannel channel,
  required String expirationDate,
}) {
  return switch (channel) {
    StoreSubscriptionChannel.apple => StoreCancellationCopy(
      title: 'Switch to Free?',
      description:
          'Your current plan will remain active until $expirationDate. '
          'To switch to Free, you’ll need to cancel your subscription '
          'through Apple.',
      continueLabel: 'Continue to Apple',
    ),
    StoreSubscriptionChannel.googlePlay => StoreCancellationCopy(
      title: 'Switch to Free?',
      description:
          'Your current plan will remain active until $expirationDate. '
          'To switch to Free, you’ll need to cancel your subscription '
          'in Google Play.',
      continueLabel: 'Continue to Google Play',
    ),
  };
}

String? confirmedStoreCancellationMessage({
  required bool cancelAtPeriodEnd,
  required String expirationDate,
}) {
  if (!cancelAtPeriodEnd) return null;
  return 'Your plan will remain active until $expirationDate, then switch to '
      'the Free plan. You will not be charged again.';
}

typedef StoreCancellationWait = Future<void> Function(Duration duration);

Future<bool> refreshUntilStoreCancellationConfirmed({
  required Future<void> Function() refresh,
  required bool Function() isConfirmed,
  List<Duration> retryDelays = const [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 4),
  ],
  StoreCancellationWait wait = Future<void>.delayed,
}) async {
  for (final delay in retryDelays) {
    if (delay > Duration.zero) await wait(delay);
    await refresh();
    if (isConfirmed()) return true;
  }
  return false;
}
