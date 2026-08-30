import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

// Auth state
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  bool get hasRemoteSession =>
      user != null && user!.email != AuthRepository.localUser.email;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await _repo.isLoggedIn();
    if (loggedIn) {
      try {
        final user = await _repo.getMe();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          user: AuthRepository.localUser,
        );
      }
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        user: AuthRepository.localUser,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.login(email: email, password: password);
      final user = await _repo.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        user: AuthRepository.localUser,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repo.getMe();
      state = state.copyWith(user: user, status: AuthStatus.authenticated);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: AuthRepository.localUser,
      );
    }
  }

  Future<bool> resendVerification(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.resendVerification(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.register(name: name, email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      user: AuthRepository.localUser,
    );
  }

  /// Updates the user's display name and refreshes auth state.
  Future<bool> updateProfile({required String name}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repo.updateProfile(name: name);
      state = state.copyWith(isLoading: false, user: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword(String oldPass, String newPass) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.changePassword(oldPassword: oldPass, newPassword: newPass);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
