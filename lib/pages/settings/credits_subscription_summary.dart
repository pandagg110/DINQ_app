import '../../models/user_models.dart';

String? subscriptionBillingLabel(Subscription? subscription) {
  if (subscription == null || subscription.isFree) return null;

  return switch (subscription.billingPeriod) {
    'yearly' => 'Billed annually',
    'monthly' => 'Billed monthly',
    _ => null,
  };
}

String? subscriptionRenewalLabel(Subscription? subscription) {
  if (subscription == null || subscription.isFree) return null;

  final date = DateTime.tryParse(subscription.currentPeriodEnd ?? '');
  if (date == null) return null;

  final prefix = subscription.cancelAtPeriodEnd ? 'Ends on' : 'Renews on';
  return '$prefix ${_fullDate(date)}';
}

String _fullDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
