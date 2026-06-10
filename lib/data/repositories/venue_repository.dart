import '../../core/api_client.dart';
import '../models/slot.dart';
import '../models/venue.dart';

class VenueRepository {
  VenueRepository(this._api);
  final ApiClient _api;

  // Small in-memory cache so other features (e.g. My Bookings) can resolve a
  // venue name from an id without a second round-trip. Populated by getVenues().
  final Map<String, Venue> _byId = {};

  Venue? venueById(String id) => _byId[id];

  /// GET /venues
  Future<List<Venue>> getVenues() async {
    final json = await _api.get('/venues') as Map<String, dynamic>;
    final list = (json['venues'] as List).cast<Map<String, dynamic>>();
    final venues = list.map(Venue.fromJson).toList();
    for (final v in venues) {
      _byId[v.id] = v;
    }
    return venues;
  }

  /// GET /venues/:id/slots?date=YYYY-MM-DD
  Future<List<Slot>> getSlots(String venueId, String date) async {
    final json =
        await _api.get('/venues/$venueId/slots?date=$date') as Map<String, dynamic>;
    final list = (json['slots'] as List).cast<Map<String, dynamic>>();
    return list.map(Slot.fromJson).toList();
  }
}
