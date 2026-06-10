import '../../core/api_client.dart';
import '../models/booking.dart';

/// Auth is handled transparently by the AuthInterceptor (Bearer token), so these
/// methods don't pass a user id for authentication. `getForUser` still takes the
/// uid because it's part of the REST path.
class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  /// POST /bookings — may throw ApiException(409, 'SLOT_TAKEN', ...).
  Future<Booking> create({
    required String venueId,
    required String date,
    required int hour,
  }) async {
    final json = await _api.post(
      '/bookings',
      body: {'venueId': venueId, 'date': date, 'hour': hour},
    ) as Map<String, dynamic>;
    return Booking.fromJson(json);
  }

  /// GET /users/:uid/bookings
  Future<List<Booking>> getForUser(String uid) async {
    final json = await _api.get('/users/$uid/bookings') as Map<String, dynamic>;
    final list = (json['bookings'] as List).cast<Map<String, dynamic>>();
    return list.map(Booking.fromJson).toList();
  }

  /// DELETE /bookings/:id
  Future<void> cancel(String bookingId) async {
    await _api.delete('/bookings/$bookingId');
  }
}
