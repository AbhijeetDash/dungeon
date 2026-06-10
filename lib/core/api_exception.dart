/// A single typed error for everything the API layer can throw, carrying the
/// HTTP status and the server's machine-readable `error` code. The UI switches
/// on these to show the right message (notably the double-booking case).
class ApiException implements Exception {
  final int statusCode; // 0 == network/transport failure (never reached server)
  final String code; // e.g. SLOT_TAKEN, INVALID_DATE, NETWORK
  final String message;

  const ApiException(this.statusCode, this.code, this.message);

  /// The one the booking flow cares about: the slot was taken between loading
  /// the grid and tapping Book.
  bool get isSlotTaken => statusCode == 409 || code == 'SLOT_TAKEN';

  bool get isNetwork => statusCode == 0 || code == 'NETWORK';

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
