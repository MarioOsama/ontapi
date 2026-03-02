import 'package:equatable/equatable.dart';

enum UserRole { tenantAdmin, branchManager, branchStaff }

class AppUser extends Equatable {
  final String id;
  final String email;
  final UserRole role;
  final String tenantId;
  final String? branchId;
  final List<String> branchIds;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.tenantId,
    this.branchId,
    this.branchIds = const [],
  });

  @override
  List<Object?> get props => [id, email, role, tenantId, branchId, branchIds];

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      role: _parseRole(json['role']),
      tenantId: json['tenant_id'],
      branchId: json['branch_id'],
      branchIds: List<String>.from(json['branch_ids'] ?? []),
    );
  }

  static UserRole _parseRole(String role) {
    switch (role) {
      case 'tenant_admin':
        return UserRole.tenantAdmin;
      case 'branch_manager':
        return UserRole.branchManager;
      case 'branch_staff':
        return UserRole.branchStaff;
      default:
        throw Exception('Invalid role: $role');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': _roleToString(role),
      'tenant_id': tenantId,
      'branch_id': branchId,
      'branch_ids': branchIds,
    };
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.tenantAdmin:
        return 'tenant_admin';
      case UserRole.branchManager:
        return 'branch_manager';
      case UserRole.branchStaff:
        return 'branch_staff';
    }
  }
}
