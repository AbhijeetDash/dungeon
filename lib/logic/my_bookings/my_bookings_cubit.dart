import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../core/date_x.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/venue_repository.dart';

enum MyBookingsStatus { loading, success, failure }

class MyBookingsState extends Equatable {
  final MyBookingsStatus status;
  final List<Booking> bookings;
  final String? error;
  final String? cancellingId; // id of the booking mid-cancel (per-card spinner)

  const MyBookingsState({
    this.status = MyBookingsStatus.loading,
    this.bookings = const [],
    this.error,
    this.cancellingId,
  });

  static bool _isPast(Booking b) {
    final d = DateX.parseYmd(b.date);
    return d != null && d.isBefore(DateX.today());
  }

  /// Active bookings for today or later — the "Upcoming" tab (cancellable).
  List<Booking> get upcoming =>
      bookings.where((b) => b.isActive && !_isPast(b)).toList();

  /// Everything else — cancelled, or active-but-past — the "Past" tab.
  List<Booking> get past =>
      bookings.where((b) => !b.isActive || _isPast(b)).toList();

  @override
  List<Object?> get props => [status, bookings, error, cancellingId];
}

class MyBookingsCubit extends Cubit<MyBookingsState> {
  MyBookingsCubit(this._bookings, this._venues) : super(const MyBookingsState());
  final BookingRepository _bookings;
  final VenueRepository _venues;

  Future<void> load(String userId) async {
    emit(const MyBookingsState(status: MyBookingsStatus.loading));
    try {
      // Warm the venue cache first so cards can resolve venue names/emoji.
      await _venues.getVenues();
      final items = await _bookings.getForUser(userId);
      emit(MyBookingsState(status: MyBookingsStatus.success, bookings: items));
    } on ApiException catch (e) {
      emit(MyBookingsState(status: MyBookingsStatus.failure, error: e.message));
    }
  }

  Future<void> cancel({required String bookingId, required String userId}) async {
    // Keep the list visible; mark just this card as cancelling.
    emit(MyBookingsState(
      status: MyBookingsStatus.success,
      bookings: state.bookings,
      cancellingId: bookingId,
    ));
    try {
      await _bookings.cancel(bookingId);
      await load(userId); // refresh → fresh state clears cancellingId
    } on ApiException catch (e) {
      emit(MyBookingsState(
        status: MyBookingsStatus.success,
        bookings: state.bookings,
        error: e.message,
      ));
    }
  }
}
