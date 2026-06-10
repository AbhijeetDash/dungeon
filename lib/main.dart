import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/venue_repository.dart';
import 'firebase_options.dart';
import 'logic/auth/auth_cubit.dart';
import 'presentation/screens/home_shell.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/widgets/state_views.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QuickSlotApp());
}

class QuickSlotApp extends StatelessWidget {
  const QuickSlotApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Built once at the root. The ApiClient's auth interceptor pulls the Firebase
    // ID token from the AuthRepository on every request.
    final authRepo = AuthRepository();
    final apiClient = ApiClient(tokenProvider: authRepo.idToken);
    final venueRepo = VenueRepository(apiClient);
    final bookingRepo = BookingRepository(apiClient);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: venueRepo),
        RepositoryProvider.value(value: bookingRepo),
      ],
      child: BlocProvider(
        create: (_) => AuthCubit(authRepo),
        child: MaterialApp(
          title: 'Dungeon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Routes on auth state: splash while unknown, app when signed in, login otherwise.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
            return const Scaffold(body: LoadingView());
          case AuthStatus.authenticated:
            return const HomeShell();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}
