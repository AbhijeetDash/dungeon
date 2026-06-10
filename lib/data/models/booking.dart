import 'package:equatable/equatable.dart';

class Booking extends Equatable {
  final String id;
  final String userId;
  final String venueId;
  final String date;
  final int hour;
  final String slotId;
  final String status; // 'active' | 'cancelled'
  final String createdAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.date,
    required this.hour,
    required this.slotId,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        userId: json['userId'] as String,
        venueId: json['venueId'] as String,
        date: json['date'] as String,
        hour: (json['hour'] as num).toInt(),
        slotId: (json['slotId'] ?? '') as String,
        status: (json['status'] ?? 'active') as String,
        createdAt: (json['createdAt'] ?? '') as String,
      );

  bool get isActive => status == 'active';

  /// "06:00 - 07:00" derived from the hour.
  String get timeLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(hour)}:00 - ${two(hour + 1)}:00';
  }

  @override
  List<Object?> get props =>
      [id, userId, venueId, date, hour, slotId, status, createdAt];
}
