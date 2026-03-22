class UserModel {
  final int id;
  final String name;
  final String email;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'is_verified': isVerified,
      };
}
