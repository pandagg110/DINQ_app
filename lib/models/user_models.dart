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

/// 分享卡片主题配置，对应 Web UserData.theme
class ShareCardTheme {
  ShareCardTheme({
    this.mode = 'classic',
    this.color = 'default',
    this.logo,
    this.leftCard,
    this.rightCard,
  });

  /// classic | card
  final String mode;
  /// default | colorful
  final String color;
  final String? logo;
  /// LINKEDIN | GITHUB | SCHOLAR | BIO
  final String? leftCard;
  /// ACHIEVEMENT_NETWORK | CAREER_TRAJECTORY
  final String? rightCard;

  factory ShareCardTheme.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return ShareCardTheme();
    return ShareCardTheme(
      mode: json['mode']?.toString() ?? 'classic',
      color: json['color']?.toString() ?? 'default',
      logo: json['logo']?.toString(),
      leftCard: json['left_card']?.toString() ?? json['leftCard']?.toString(),
      rightCard: json['right_card']?.toString() ?? json['rightCard']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'color': color,
        if (logo != null && logo!.isNotEmpty) 'logo': logo,
        if (leftCard != null && leftCard!.isNotEmpty) 'left_card': leftCard,
        if (rightCard != null && rightCard!.isNotEmpty) 'right_card': rightCard,
      };

  ShareCardTheme copyWith({
    String? mode,
    String? color,
    String? logo,
    String? leftCard,
    String? rightCard,
  }) =>
      ShareCardTheme(
        mode: mode ?? this.mode,
        color: color ?? this.color,
        logo: logo ?? this.logo,
        leftCard: leftCard ?? this.leftCard,
        rightCard: rightCard ?? this.rightCard,
      );
}

class UserData {
  UserData({
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.domain,
    this.email = '',
    this.fullPosition = '',
    this.fullDegree = '',
    this.location = '',
    this.timezone,
    this.tags = '',
    this.jobStatus,
    this.theme,
  });

  final String name;
  final String avatarUrl;
  final String bio;
  final String domain;
  final String email;
  final String fullPosition;
  final String fullDegree;
  final String location;
  final String? timezone;
  final String tags;
  final String? jobStatus; // "Hiring" | "Open_to_work" | "Internship" | "Freelance" | "Hidden"
  final ShareCardTheme? theme;

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullPosition: json['full_position']?.toString() ?? '',
      fullDegree: json['full_degree']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      timezone: json['timezone']?.toString(),
      tags: json['tags']?.toString() ?? '',
      jobStatus: json['job_status']?.toString(),
      theme: ShareCardTheme.fromJson(json['theme'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatar_url': avatarUrl,
        'bio': bio,
        'domain': domain,
        if (email.isNotEmpty) 'email': email,
        if (fullPosition.isNotEmpty) 'full_position': fullPosition,
        if (fullDegree.isNotEmpty) 'full_degree': fullDegree,
        if (location.isNotEmpty) 'location': location,
        if (timezone != null) 'timezone': timezone,
        if (tags.isNotEmpty) 'tags': tags,
        if (jobStatus != null) 'job_status': jobStatus,
        if (theme != null) 'theme': theme!.toJson(),
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


