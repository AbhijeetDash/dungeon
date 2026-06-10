import 'package:equatable/equatable.dart';

import '../../data/models/slot.dart';

enum SlotsStatus { loading, success, failure }

class SlotsState extends Equatable {
  final SlotsStatus status;
  final List<Slot> slots; // all slots for [selectedDate]
  final DateTime selectedDate;
  final TimeOfDayBand? bandFilter; // null == All
  final int? selectedHour; // currently selected slot's hour, if any
  final String? error;

  const SlotsState({
    required this.selectedDate,
    this.status = SlotsStatus.loading,
    this.slots = const [],
    this.bandFilter,
    this.selectedHour,
    this.error,
  });

  /// Slots grouped by time-of-day band, honoring the active filter. Only bands
  /// that actually contain slots are returned (so the UI shows no empty
  /// "Morning Sessions" header). This is exactly the design's grouped layout
  /// AND the "filter by time of day" bonus, in one derived getter.
  Map<TimeOfDayBand, List<Slot>> get groupedVisible {
    final bands =
        bandFilter == null ? TimeOfDayBand.values : <TimeOfDayBand>[bandFilter!];
    final map = <TimeOfDayBand, List<Slot>>{};
    for (final band in bands) {
      final list = slots.where((s) => s.band == band).toList();
      if (list.isNotEmpty) map[band] = list;
    }
    return map;
  }

  bool get hasAnyVisible => groupedVisible.isNotEmpty;

  /// The selected slot, if it is still available (defensive: a refresh may have
  /// flipped it to booked, in which case selection is treated as cleared).
  Slot? get selectedSlot {
    if (selectedHour == null) return null;
    for (final s in slots) {
      if (s.hour == selectedHour && s.available) return s;
    }
    return null;
  }

  @override
  List<Object?> get props =>
      [status, slots, selectedDate, bandFilter, selectedHour, error];
}
