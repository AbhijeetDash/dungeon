import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/venue_repository.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/my_bookings/my_bookings_cubit.dart';
import '../../logic/venues/venues_cubit.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'venues_screen.dart';

/// The signed-in app shell: bottom navigation across Explore / Bookings /
/// Profile. Provides the VenuesCubit and MyBookingsCubit to the whole subtree.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => VenuesCubit(ctx.read<VenueRepository>())..load(),
        ),
        BlocProvider(
          create: (ctx) => MyBookingsCubit(
            ctx.read<BookingRepository>(),
            ctx.read<VenueRepository>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          const pages = [VenuesScreen(), MyBookingsScreen(), ProfileScreen()];
          return Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                setState(() => _index = i);
                if (i == 1) {
                  // Refresh My Bookings each time the tab is opened.
                  final uid = context.read<AuthCubit>().state.user?.id;
                  if (uid != null) context.read<MyBookingsCubit>().load(uid);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Bookings',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
