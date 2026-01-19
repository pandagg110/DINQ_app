class User {
  User({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
      };
}

class UserData {
  UserData({
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.domain,
  });

  final String name;
  final String avatarUrl;
  final String bio;
  final String domain;

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatar_url': avatarUrl,
        'bio': bio,
        'domain': domain,
      };
}

class UserProfile {
  UserProfile({required this.user, required this.userData});

  final User user;
  final UserData userData;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      user: User.fromJson(json['user'] ?? {}),
      userData: UserData.fromJson(json['user_data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'user_data': userData.toJson(),
      };
}

class UserFlow {
  UserFlow({
    required this.status,
    required this.domain,
  });

  final String status;
  final String domain;

  factory UserFlow.fromJson(Map<String, dynamic> json) {
    return UserFlow(
      status: json['status']?.toString() ?? 'pending',
      domain: json['domain']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'domain': domain,
      };
}

class Subscription {
  Subscription({
    required this.plan,
    required this.status,
    required this.creditsBalance,
    required this.monthlyCredits,
    required this.cancelAtPeriodEnd,
  });

  final String plan;
  final String status;
  final int creditsBalance;
  final int monthlyCredits;
  final bool cancelAtPeriodEnd;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      plan: json['plan']?.toString() ?? 'free',
      status: json['status']?.toString() ?? 'active',
      creditsBalance: json['credits_balance'] is int
          ? json['credits_balance'] as int
          : int.tryParse(json['credits_balance']?.toString() ?? '0') ?? 0,
      monthlyCredits: json['monthly_credits'] is int
          ? json['monthly_credits'] as int
          : int.tryParse(json['monthly_credits']?.toString() ?? '0') ?? 0,
      cancelAtPeriodEnd: json['cancel_at_period_end'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'status': status,
        'credits_balance': creditsBalance,
        'monthly_credits': monthlyCredits,
        'cancel_at_period_end': cancelAtPeriodEnd,
      };
}


