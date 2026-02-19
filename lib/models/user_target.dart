class UserTarget {
  final int dailyAyahTarget;
  final int dailySurahTarget;

  UserTarget({
    this.dailyAyahTarget = 20, // Default target
    this.dailySurahTarget = 1,
  });

  factory UserTarget.fromJson(Map<String, dynamic> json) {
    return UserTarget(
      dailyAyahTarget: json['dailyAyahTarget'] ?? 20,
      dailySurahTarget: json['dailySurahTarget'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyAyahTarget': dailyAyahTarget,
      'dailySurahTarget': dailySurahTarget,
    };
  }
}
