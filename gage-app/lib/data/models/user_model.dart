class UserModel {
  final String id;
  final String name;
  final String? email;
  final String phone;
  final String? avatarUrl;
  final String role;
  final String membershipTier;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.avatarUrl,
    this.role = 'user',
    this.membershipTier = 'free',
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Pengguna Gage',
      email: json['email'],
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'user',
      membershipTier: json['membership_tier'] ?? 'free',
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'membership_tier': membershipTier,
      'token': token,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? membershipTier,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      membershipTier: membershipTier ?? this.membershipTier,
      token: token,
    );
  }
}
