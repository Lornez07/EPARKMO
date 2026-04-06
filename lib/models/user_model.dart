class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'guest' | 'admin'

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        role: map['role'] ?? 'guest',
      );
}
