import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/booking.dart';
import '../../data/repositories/venue_repository.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/my_bookings/my_bookings_cubit.dart';
import '../widgets/booking_card.dart';
import '../widgets/state_views.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select((AuthCubit c) => c.state.user?.id) ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past')],
          ),
        ),
        body: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            switch (state.status) {
              case MyBookingsStatus.loading:
                return const LoadingView(label: 'Loading your bookings…');
              case MyBookingsStatus.failure:
                return AppErrorView(
                  message: state.error ?? 'Could not load bookings.',
                  onRetry: () => context.read<MyBookingsCubit>().load(uid),
                );
              case MyBookingsStatus.success:
                return TabBarView(
                  children: [
                    _BookingList(
                      bookings: state.upcoming,
                      cancellingId: state.cancellingId,
                      uid: uid,
                      emptyTitle: 'No upcoming bookings',
                      emptySubtitle: 'Book a slot from the Explore tab.',
                    ),
                    _BookingList(
                      bookings: state.past,
                      cancellingId: state.cancellingId,
                      uid: uid,
                      cancellable: false,
                      emptyTitle: 'Nothing here yet',
                      emptySubtitle: 'Past and cancelled bookings show up here.',
                    ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.cancellingId,
    required this.uid,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.cancellable = true,
  });

  final List<Booking> bookings;
  final String? cancellingId;
  final String uid;
  final String emptyTitle;
  final String emptySubtitle;
  final bool cancellable;

  Future<void> _confirmCancel(BuildContext context, Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This frees the slot for others to book.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<MyBookingsCubit>().cancel(bookingId: b.id, userId: uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyView(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: Icons.event_available_outlined,
      );
    }
    final venues = context.read<VenueRepository>();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final b = bookings[i];
        return BookingCard(
          booking: b,
          venue: venues.venueById(b.venueId),
          cancelling: cancellingId == b.id,
          onCancel: cancellable ? () => _confirmCancel(context, b) : null,
        );
      },
    );
  }
}
