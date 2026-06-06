class User {
  final int id;
  final String username;
  final String email;
  final String? profilePic;
  final String role;
  final String? pseudoname;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profilePic,
    required this.role,
    this.pseudoname,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePic: json['profile_pic'] as String?,
      role: json['role'] as String? ?? 'visitor',
      pseudoname: json['pseudoname'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_pic': profilePic,
      'role': role,
      'pseudoname': pseudoname,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isStoreOwner => role == 'store_owner';
  bool get isVisitor => role == 'visitor';

  String get displayName => pseudoname ?? username;
}
