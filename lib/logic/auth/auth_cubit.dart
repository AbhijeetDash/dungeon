import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;
  final bool submitting; // an auth action is in flight (disables the form)
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.submitting = false,
    this.error,
  });

  @override
  List<Object?> get props => [status, user, submitting, error];
}

/// Single source of truth for "who is signed in". Subscribes to Firebase's
/// authStateChanges so routing reacts automatically to sign-in/out, and exposes
/// the sign-in actions for the login screen.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState()) {
    _sub = _repo.authState().listen((user) {
      emit(AuthState(
        status:
            user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
      ));
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<AppUser?> _sub;

  Future<void> signInEmail(String email, String password) =>
      _guard(() => _repo.signInWithEmail(email, password));

  Future<void> register(String email, String password, {String? name}) =>
      _guard(() => _repo.registerWithEmail(email, password, name: name));

  Future<void> signInGoogle() => _guard(_repo.signInWithGoogle);

  Future<void> signOut() => _repo.signOut();

  void clearError() =>
      emit(AuthState(status: state.status, user: state.user));

  /// Runs an auth action with submitting/error bookkeeping. On success, the
  /// authState stream emits the authenticated state (so we don't emit it here).
  Future<void> _guard(Future<void> Function() action) async {
    emit(AuthState(status: state.status, user: state.user, submitting: true));
    try {
      await action();
    } catch (e) {
      emit(AuthState(
        status: state.status,
        user: state.user,
        submitting: false,
        error: _message(e),
      ));
    }
  }

  String _message(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'That email is already registered.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'network-request-failed':
          return 'Network error — check your connection.';
        case 'cancelled':
          return 'Sign-in cancelled.';
        default:
          return e.message ?? 'Authentication failed (${e.code}).';
      }
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
