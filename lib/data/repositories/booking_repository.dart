import '../../core/api_client.dart';
import '../models/booking.dart';

class BookingRepository {
  BookingRepository(this._api);
  final ApiClient _api;

  /// POST /bookings — may throw ApiException(409, 'SLOT_TAKEN', ...).
  Future<Booking> create({
    required String userId,
    required String venueId,
    required String date,
    required int hour,
  }) async {
    final json = await _api.post(
      '/bookings',
      userId: userId,
      body: {'venueId': venueId, 'date': date, 'hour': hour},
    ) as Map<String, dynamic>;
    return Booking.fromJson(json);
  }

  /// GET /users/:id/bookings
  Future<List<Booking>> getForUser(String userId) async {
    final json =
        await _api.get('/users/$userId/bookings', userId: userId) as Map<String, dynamic>;
    final list = (json['bookings'] as List).cast<Map<String, dynamic>>();
    return list.map(Booking.fromJson).toList();
  }

  /// DELETE /bookings/:id
  Future<void> cancel({required String bookingId, required String userId}) async {
    await _api.delete('/bookings/$bookingId', userId: userId);
  }
}
