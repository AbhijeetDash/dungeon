import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Wraps FirebaseAuth. Everything auth-related lives here, so the rest of the app
/// depends only on this small surface (and the AppUser model), not on Firebase
/// types. Google sign-in uses Firebase's native provider flow — no extra package.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emits the current user (or null) whenever auth state changes. Drives routing.
  Stream<AppUser?> authState() => _auth.authStateChanges().map(_toAppUser);

  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  AppUser? _toAppUser(User? u) =>
      u == null ? null : AppUser(id: u.uid, name: u.displayName ?? u.email ?? 'User');

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (name != null && name.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(name.trim());
      await cred.user?.reload();
    }
  }

  /// Native Google OAuth through Firebase (Custom Tabs on Android, the system
  /// auth session on iOS). No google_sign_in dependency required.
  Future<void> signInWithGoogle() =>
      _auth.signInWithProvider(GoogleAuthProvider());

  /// The current Firebase ID token (used by the AuthInterceptor). Null if signed
  /// out. firebase_auth refreshes it automatically near expiry.
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  Future<void> signOut() => _auth.signOut();
}
