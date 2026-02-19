class UserProfile {
  String name;
  String email;

  UserProfile({
    this.name = 'User',
    this.email = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
    );
  }
}
