class AppUser {
  final int? userId; // Nullable for guest users
  final String userName;
  final String? userImage;
  final UserType userType;
  final String? authProviderId;
  final String? email;
  final bool isGuest;

  AppUser({
    this.userId,
    required this.userName,
    this.userImage,
    required this.userType,
    this.authProviderId,
    this.isGuest = false,
    this.email,
  });

  // Factory for guest users
  factory AppUser.guest() {
    return AppUser(
      userId: null,
      userName: 'Guest User',
      userType: UserType.normalUser,
      isGuest: true,
    );
  }

  factory AppUser.fromSupabase(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      userImage: json['user_image'] as String?,
      userType: UserType.fromInt(json['user_type'] as int),
      authProviderId: json['auth_provider_id'] as String?,
      isGuest: false,
    );
  }

  Map<String, dynamic> toSupabaseInsert() {
    return {
      'user_name': userName,
      'user_image': userImage,
      'user_type': userType.value,
      'auth_provider_id': authProviderId,
    };
  }

  bool get isAdmin => userType == UserType.admin;
  bool get isClubAdmin => userType == UserType.clubAdmin;
  bool get isNormalUser => userType == UserType.normalUser;
  bool get canCreateEvents => !isGuest && userType != UserType.normalUser;
  bool get canRSVP => !isGuest; // Only registered users can RSVP

  AppUser copyWith({
    int? userId,
    String? userName,
    String? userImage,
    UserType? userType,
    String? authProviderId,
    bool? isGuest,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      userType: userType ?? this.userType,
      authProviderId: authProviderId ?? this.authProviderId,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  String toString() {
    return 'AppUser(userId: $userId, userName: $userName, userType: ${userType.displayName}, isGuest: $isGuest)';
  }
}

enum UserType {
  admin(0),
  clubAdmin(1),
  normalUser(2);

  const UserType(this.value);
  final int value;

  static UserType fromInt(int value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.normalUser,
    );
  }

  String get displayName {
    switch (this) {
      case UserType.admin:
        return 'Admin';
      case UserType.clubAdmin:
        return 'Club Admin';
      case UserType.normalUser:
        return 'User';
    }
  }
}
