import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../core/date_x.dart';
import '../../data/models/venue.dart';
import '../../data/repositories/venue_repository.dart';
import 'slots_event.dart';
import 'slots_state.dart';

class SlotsBloc extends Bloc<SlotsEvent, SlotsState> {
  SlotsBloc({required VenueRepository repo, required Venue venue})
      : _repo = repo,
        _venue = venue,
        super(SlotsState(selectedDate: DateX.today())) {
    on<SlotsStarted>((e, emit) => _load(state.selectedDate, emit));
    on<SlotsDateSelected>((e, emit) => _load(e.date, emit));
    on<SlotsRefreshed>((e, emit) => _load(state.selectedDate, emit));
    on<SlotsBandFilterChanged>(_onFilter);
    on<SlotSelected>(_onSelect);
  }

  final VenueRepository _repo;
  final Venue _venue;

  /// Fetches slots for [date]. Always resets the selection (a reload may have
  /// changed availability) but preserves the active time-of-day filter.
  Future<void> _load(DateTime date, Emitter<SlotsState> emit) async {
    emit(SlotsState(
      status: SlotsStatus.loading,
      selectedDate: date,
      bandFilter: state.bandFilter,
    ));
    try {
      final slots = await _repo.getSlots(_venue.id, DateX.ymd(date));
      emit(SlotsState(
        status: SlotsStatus.success,
        slots: slots,
        selectedDate: date,
        bandFilter: state.bandFilter,
      ));
    } on ApiException catch (e) {
      emit(SlotsState(
        status: SlotsStatus.failure,
        selectedDate: date,
        bandFilter: state.bandFilter,
        error: e.message,
      ));
    }
  }

  void _onFilter(SlotsBandFilterChanged e, Emitter<SlotsState> emit) {
    emit(SlotsState(
      status: state.status,
      slots: state.slots,
      selectedDate: state.selectedDate,
      bandFilter: e.band,
      selectedHour: state.selectedHour,
    ));
  }

  void _onSelect(SlotSelected e, Emitter<SlotsState> emit) {
    if (e.slot.booked) return; // can't select a taken slot
    final next = state.selectedHour == e.slot.hour ? null : e.slot.hour; // toggle
    emit(SlotsState(
      status: state.status,
      slots: state.slots,
      selectedDate: state.selectedDate,
      bandFilter: state.bandFilter,
      selectedHour: next,
    ));
  }
}
