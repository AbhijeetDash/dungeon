import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/date_x.dart';
import '../../core/theme.dart';
import '../../data/models/slot.dart';
import '../../data/models/venue.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/venue_repository.dart';
import '../../logic/booking/booking_cubit.dart';
import '../../logic/slots/slots_bloc.dart';
import '../../logic/slots/slots_event.dart';
import '../../logic/slots/slots_state.dart';
import '../widgets/date_strip.dart';
import '../widgets/slot_chip.dart';
import '../widgets/state_views.dart';
import '../widgets/time_filter_chips.dart';
import '../widgets/venue_image.dart';
import 'booking_confirmed_screen.dart';

class VenueDetailScreen extends StatelessWidget {
  const VenueDetailScreen({super.key, required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) =>
              SlotsBloc(repo: ctx.read<VenueRepository>(), venue: venue)
                ..add(const SlotsStarted()),
        ),
        BlocProvider(
          create: (ctx) => BookingCubit(ctx.read<BookingRepository>()),
        ),
      ],
      child: _VenueDetailView(venue: venue),
    );
  }
}

class _VenueDetailView extends StatelessWidget {
  const _VenueDetailView({required this.venue});
  final Venue venue;

  void _confirm(BuildContext context, Slot slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm booking'),
        content: Text(
          '${venue.name}\n'
          '${DateX.prettyShort(DateX.parseYmd(slot.date) ?? DateTime.now())} · ${slot.label}\n'
          '${venue.priceLabel}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(96, 44)),
            child: const Text('Book'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<BookingCubit>().book(venue: venue, slot: slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<BookingCubit, BookingState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          switch (state.status) {
            case BookingStatus.success:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BookingConfirmedScreen(
                    booking: state.booking!,
                    venue: venue,
                  ),
                ),
              );
              break;
            case BookingStatus.slotTaken:
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('That slot was just booked by someone else.'),
                ));
              context.read<SlotsBloc>().add(const SlotsRefreshed());
              context.read<BookingCubit>().reset();
              break;
            case BookingStatus.failure:
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.message ?? 'Booking failed.'),
                ));
              context.read<BookingCubit>().reset();
              break;
            default:
              break;
          }
        },
        child: Column(
          children: [
            _Hero(venue: venue),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: BlocBuilder<SlotsBloc, SlotsState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(venue.location,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                            ),
                            Text(venue.priceLabel,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('Select Date',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        DateStrip(
                          dates: DateX.upcoming(14),
                          selected: state.selectedDate,
                          onSelect: (d) =>
                              context.read<SlotsBloc>().add(SlotsDateSelected(d)),
                        ),
                        const SizedBox(height: 18),
                        TimeFilterChips(
                          selected: state.bandFilter,
                          onSelect: (b) => context
                              .read<SlotsBloc>()
                              .add(SlotsBandFilterChanged(b)),
                        ),
                        const SizedBox(height: 18),
                        _SlotsSection(state: state),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BookBar(venue: venue, onBook: _confirm),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VenueImage(venue: venue, height: 200),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.35),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotsSection extends StatelessWidget {
  const _SlotsSection({required this.state});
  final SlotsState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SlotsStatus.loading:
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: LoadingView(label: 'Loading slots…'),
        );
      case SlotsStatus.failure:
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: AppErrorView(
            message: state.error ?? 'Could not load slots.',
            onRetry: () => context.read<SlotsBloc>().add(const SlotsRefreshed()),
          ),
        );
      case SlotsStatus.success:
        if (!state.hasAnyVisible) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyView(
              title: 'No slots here',
              subtitle: 'Try another date or time of day.',
              icon: Icons.event_busy_rounded,
            ),
          );
        }
        final grouped = state.groupedVisible;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key.label} Sessions',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: entry.value.map((slot) {
                      return SlotChip(
                        slot: slot,
                        selected: state.selectedHour == slot.hour,
                        onTap: () =>
                            context.read<SlotsBloc>().add(SlotSelected(slot)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
    }
  }
}

class _BookBar extends StatelessWidget {
  const _BookBar({required this.venue, required this.onBook});
  final Venue venue;
  final void Function(BuildContext, Slot) onBook;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlotsBloc, SlotsState>(
      builder: (context, slotsState) {
        final slot = slotsState.selectedSlot;
        return BlocBuilder<BookingCubit, BookingState>(
          builder: (context, bookingState) {
            final busy = bookingState.status == BookingStatus.submitting;
            final canBook = slot != null && !busy;
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot == null ? 'Select a slot' : 'Selected',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            slot == null ? venue.priceLabel : slot.label,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: canBook ? () => onBook(context, slot) : null,
                        child: busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Book Now'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
