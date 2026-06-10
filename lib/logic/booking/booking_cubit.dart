import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../data/models/booking.dart';
import '../../data/models/slot.dart';
import '../../data/models/venue.dart';
import '../../data/repositories/booking_repository.dart';

/// `slotTaken` is split out from `failure` on purpose: it is the ONE outcome the
/// UI must handle gracefully (show a friendly message + refresh the grid) rather
/// than as a generic error. It maps to the API's 409.
enum BookingStatus { initial, submitting, success, slotTaken, failure }

class BookingState extends Equatable {
  final BookingStatus status;
  final Booking? booking;
  final String? message;

  const BookingState({
    this.status = BookingStatus.initial,
    this.booking,
    this.message,
  });

  @override
  List<Object?> get props => [status, booking, message];
}

class BookingCubit extends Cubit<BookingState> {
  BookingCubit(this._repo) : super(const BookingState());
  final BookingRepository _repo;

  Future<void> book({
    required String userId,
    required Venue venue,
    required Slot slot,
  }) async {
    emit(const BookingState(status: BookingStatus.submitting));
    try {
      final booking = await _repo.create(
        userId: userId,
        venueId: venue.id,
        date: slot.date,
        hour: slot.hour,
      );
      emit(BookingState(status: BookingStatus.success, booking: booking));
    } on ApiException catch (e) {
      emit(
        BookingState(
          status: e.isSlotTaken ? BookingStatus.slotTaken : BookingStatus.failure,
          message: e.message,
        ),
      );
    }
  }

  void reset() => emit(const BookingState());
}
