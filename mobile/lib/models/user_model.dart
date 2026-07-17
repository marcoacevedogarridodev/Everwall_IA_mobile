/// Modelo de usuario. El parsing es tolerante (campos opcionales con
/// default) porque aún no tenemos el serializer exacto del backend —
/// cuando lo compartas, ajusta los nombres de campo en `fromJson` si
/// difieren (ej. snake_case vs camelCase, `photo` vs `avatar_url`, etc).
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isVerified;
  final String? avatarUrl;
  final int pixelsCount;
  final int likesReceived;
  final DateTime? dateJoined;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.isVerified = false,
    this.avatarUrl,
    this.pixelsCount = 0,
    this.likesReceived = 0,
    this.dateJoined,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final combined = ('$f$l').toUpperCase();
    return combined.isNotEmpty ? combined : '?';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['pk'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName: json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ??
          json['email_verified'] as bool? ??
          false,
      avatarUrl: json['avatar_url'] as String? ?? json['avatar'] as String?,
      pixelsCount: (json['pixels_count'] as num?)?.toInt() ?? 0,
      likesReceived: (json['likes_received'] as num?)?.toInt() ?? 0,
      dateJoined: json['date_joined'] != null
          ? DateTime.tryParse(json['date_joined'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_verified': isVerified,
      'avatar_url': avatarUrl,
      'pixels_count': pixelsCount,
      'likes_received': likesReceived,
      'date_joined': dateJoined?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    bool? isVerified,
    String? avatarUrl,
    int? pixelsCount,
    int? likesReceived,
  }) {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pixelsCount: pixelsCount ?? this.pixelsCount,
      likesReceived: likesReceived ?? this.likesReceived,
      dateJoined: dateJoined,
    );
  }
}
