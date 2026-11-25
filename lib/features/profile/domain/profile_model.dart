class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.address,
    required this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final String address;
  final String avatarUrl;

  static const ProfileModel empty = ProfileModel(
    id: '',
    fullName: '',
    email: '',
    phone: '',
    gender: 'ذكر',
    address: '',
    avatarUrl: '',
  );

  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : 'د';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  ProfileModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? gender,
    String? address,
    String? avatarUrl,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final g = json['gender']?.toString() ?? 'ذكر';
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: (g == 'أنثى' || g == 'ذكر') ? g : 'ذكر',
      address: json['address']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'address': address,
      'avatar_url': avatarUrl,
    };
  }
}
