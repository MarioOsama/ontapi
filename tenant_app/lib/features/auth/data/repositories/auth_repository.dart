import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/auth_service.dart';
import '../models/app_user.dart';

class AuthRepository {
  final AuthService _authService;
  final SupabaseClient _client = Supabase.instance.client;

  AuthRepository({required AuthService authService})
    : _authService = authService;

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String businessName,
    String? description,
    Uint8List? logoBytes,
    String? logoExtension,
  }) async {
    final response = await _authService.signUp(
      email: email,
      password: password,
      businessName: businessName,
    );

    if (response.user == null) {
      throw Exception('Signup failed: No user returned.');
    }

    final user = await resolveUserRole(response.user!.id, email);

    // Update description and logo if provided
    if (description != null && description.isNotEmpty || logoBytes != null) {
      String? logoUrl;

      if (logoBytes != null && logoExtension != null) {
        final ext = logoExtension.replaceFirst('.', '');
        final filePath = '${user.tenantId}/logo.$ext';

        await _client.storage
            .from('tenant-logos')
            .uploadBinary(
              filePath,
              logoBytes,
              fileOptions: FileOptions(upsert: true),
            );

        logoUrl = _client.storage.from('tenant-logos').getPublicUrl(filePath);
      }

      await _client
          .from('tenants')
          .update({
            if (description != null && description.isNotEmpty)
              'description': description,
            if (logoUrl != null) 'logo_url': logoUrl,
          })
          .eq('id', user.tenantId);
    }

    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _authService.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign-in failed: No user returned.');
    }

    return await resolveUserRole(response.user!.id, email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<AppUser> resolveUserRole(String userId, String email) async {
    // 1. Check if user is a Tenant Admin
    final tenantUserResponse = await _client
        .from('tenant_users')
        .select('tenant_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (tenantUserResponse != null) {
      return AppUser(
        id: userId,
        email: email,
        role: UserRole.tenantAdmin,
        tenantId: tenantUserResponse['tenant_id'] as String,
      );
    }

    // 2. Check if user has Branch Roles
    final branchUsersResponse = await _client
        .from('branch_users')
        .select('branch_id, role, branches(tenant_id)')
        .eq('user_id', userId);

    final List<Map<String, dynamic>> branchUsers =
        List<Map<String, dynamic>>.from(branchUsersResponse);

    if (branchUsers.isEmpty) {
      throw Exception('User has no assigned roles.');
    }

    if (branchUsers.length == 1) {
      final bu = branchUsers.first;
      return AppUser(
        id: userId,
        email: email,
        role: AppUser.fromJson(
          {'role': bu['role']},
        ).role, // Handle enum conversion gracefully or define a helper. Wait, I will use a helper.
        tenantId: bu['branches']['tenant_id'] as String,
        branchId: bu['branch_id'] as String,
      );
    }

    // Handle multiple branch memberships
    final List<String> branchIds = branchUsers
        .map((bu) => bu['branch_id'] as String)
        .toList();

    // Defaulting to the first branch for now until branch selector is fully implemented in US5
    final firstBranch = branchUsers.first;
    return AppUser(
      id: userId,
      email: email,
      role: AppUser.fromJson({'role': firstBranch['role']}).role,
      tenantId: firstBranch['branches']['tenant_id'] as String,
      branchId: firstBranch['branch_id'] as String,
      branchIds: branchIds,
    );
  }
}
