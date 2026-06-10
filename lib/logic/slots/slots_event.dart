import 'package:equatable/equatable.dart';

import '../../data/models/slot.dart';

/// Slots is a full BLoC (not a Cubit) because it has genuinely distinct events
/// worth modelling explicitly — load, change date, change filter, select, and
/// refresh-after-conflict. Sealed so the handler switch is exhaustive.
sealed class SlotsEvent extends Equatable {
  const SlotsEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load for the default (today) date.
class SlotsStarted extends SlotsEvent {
  const SlotsStarted();
}

/// User picked a different date in the strip.
class SlotsDateSelected extends SlotsEvent {
  final DateTime date;
  const SlotsDateSelected(this.date);
  @override
  List<Object?> get props => [date];
}

/// Reload the current date — used after a successful booking, and crucially
/// after a 409 so the grid reflects the slot another user just took.
class SlotsRefreshed extends SlotsEvent {
  const SlotsRefreshed();
}

/// Time-of-day filter changed (null == "All"). Pure client-side; no reload.
class SlotsBandFilterChanged extends SlotsEvent {
  final TimeOfDayBand? band;
  const SlotsBandFilterChanged(this.band);
  @override
  List<Object?> get props => [band];
}

/// User tapped a slot chip (toggles selection; ignored for booked slots).
class SlotSelected extends SlotsEvent {
  final Slot slot;
  const SlotSelected(this.slot);
  @override
  List<Object?> get props => [slot];
}
