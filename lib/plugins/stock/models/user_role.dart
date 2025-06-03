// lib/plugins/stock/models/user_role.dart

enum UserRole { ADMIN, STOCK_MANAGER, VIEWER }

class UserPermissions {
  final String userId;
  final UserRole role;

  UserPermissions({
    required this.userId,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.name,
    };
  }

  factory UserPermissions.fromMap(Map<String, dynamic> map) {
    return UserPermissions(
      userId: map['userId'] as String? ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.name == (map['role'] as String? ?? 'VIEWER'),
        orElse: () => UserRole.VIEWER,
      ),
    );
  }
}
