class UserModel {
  final String name;
  final String email;
  final String? avatar;

  const UserModel({
    required this.name,
    required this.email,
    this.avatar,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
    );
  }
}
