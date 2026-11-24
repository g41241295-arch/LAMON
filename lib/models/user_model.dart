class UserModel {
  final String name;
  final String email;
  final String? avatar;
  final bool hasCompletedScreening;
  final Map<String, dynamic>? screeningData;

  // Field Integrasi SatuSehat FHIR Kemenkes (Resource Patient)
  final String? nik;
  final String? ihsNumber;
  final bool satusehatLinked;
  final String? satusehatVerifiedName;

  const UserModel({
    required this.name,
    required this.email,
    this.avatar,
    this.hasCompletedScreening = false,
    this.screeningData,
    this.nik,
    this.ihsNumber,
    this.satusehatLinked = false,
    this.satusehatVerifiedName,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
    bool? hasCompletedScreening,
    Map<String, dynamic>? screeningData,
    String? nik,
    String? ihsNumber,
    bool? satusehatLinked,
    String? satusehatVerifiedName,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      hasCompletedScreening:
          hasCompletedScreening ?? this.hasCompletedScreening,
      screeningData: screeningData ?? this.screeningData,
      nik: nik ?? this.nik,
      ihsNumber: ihsNumber ?? this.ihsNumber,
      satusehatLinked: satusehatLinked ?? this.satusehatLinked,
      satusehatVerifiedName:
          satusehatVerifiedName ?? this.satusehatVerifiedName,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: (map['name'] ?? map['nama'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      avatar: map['avatar'] ?? map['photo_url'] ?? map['photoUrl'],
      hasCompletedScreening: map['hasCompletedScreening'] ?? false,
      screeningData: map['screeningData'] as Map<String, dynamic>?,
      nik: map['nik']?.toString(),
      ihsNumber: map['ihsNumber']?.toString(),
      satusehatLinked: map['satusehatLinked'] == true,
      satusehatVerifiedName: map['satusehatVerifiedName']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatar': avatar,
      'hasCompletedScreening': hasCompletedScreening,
      'screeningData': screeningData,
      'nik': nik,
      'ihsNumber': ihsNumber,
      'satusehatLinked': satusehatLinked,
      'satusehatVerifiedName': satusehatVerifiedName,
    };
  }
}
