class UserModel {
  final String name;
  final String email;
  final String? avatar;
  final bool hasCompletedScreening;
  final Map<String, dynamic>? screeningData;

  const UserModel({
    required this.name,
    required this.email,
    this.avatar,
    this.hasCompletedScreening = false,
    this.screeningData,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
    bool? hasCompletedScreening,
    Map<String, dynamic>? screeningData,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      hasCompletedScreening:
          hasCompletedScreening ?? this.hasCompletedScreening,
      screeningData: screeningData ?? this.screeningData,
    );
  }
}

