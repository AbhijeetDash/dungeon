import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/app_user.dart';

/// Holds the currently selected user (light auth). State is simply the user, or
/// null when signed out.
///
/// Why a Cubit (not a full Bloc): there are no meaningful discrete "events" here
/// — just set/clear the user. Isolating "who am I" in this one class is also what
/// makes swapping in real Firebase Auth later a single-file change: populate it
/// from FirebaseAuth.instance.authStateChanges() instead of the picker.
class SessionCubit extends Cubit<AppUser?> {
  SessionCubit() : super(null);

  void signIn(AppUser user) => emit(user);
  void signOut() => emit(null);

  bool get isSignedIn => state != null;
}
