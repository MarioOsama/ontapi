import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial());

  void proceedToStageTwo({required String email, required String password}) {
    emit(AuthSignUpStageOne(email: email, password: password));
  }

  void backToStageOne() {
    emit(AuthUnauthenticated()); // Go back to start
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String businessName,
    String? description,
    Uint8List? logoBytes,
    String? logoExtension,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        businessName: businessName,
        description: description,
        logoBytes: logoBytes,
        logoExtension: logoExtension,
      );
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        emit(
          const AuthError(
            'A tenant admin account already exists for this user.',
          ),
        );
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resolveRole(String userId, String email) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.resolveUserRole(userId, email);

      if (user.branchIds.length > 1) {
        emit(AuthBranchSelection(user));
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Method requested by bloc/UI to cleanly emit unauthenticated state
  void setUnauthenticated() {
    emit(AuthUnauthenticated());
  }
}
