class UserProfile {
  final String id;
  final String alias;
  final int karma;
  final int trustLevel;
  final Map<String, String> lastRatings; // BusinessID -> ISO String

  UserProfile({
    required this.id,
    required this.alias,
    this.karma = 0,
    this.trustLevel = 1,
    this.lastRatings = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      alias: json['alias'],
      karma: json['karma'] ?? 0,
      trustLevel: json['trust_level'] ?? 1,
      lastRatings: Map<String, String>.from(json['last_ratings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alias': alias,
      'karma': karma,
      'trust_level': trustLevel,
      'last_ratings': lastRatings,
    };
  }

  UserProfile copyWith({int? karma, int? trustLevel, Map<String, String>? lastRatings}) {
    return UserProfile(
      id: id,
      alias: alias,
      karma: karma ?? this.karma,
      trustLevel: trustLevel ?? this.trustLevel,
      lastRatings: lastRatings ?? this.lastRatings,
    );
  }
}
