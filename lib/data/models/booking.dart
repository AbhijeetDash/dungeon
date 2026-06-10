import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking extends Equatable {
  final String id;
  final String userId;
  final String venueId;
  final String date;
  final int hour;
  @JsonKey(defaultValue: '')
  final String slotId;
  @JsonKey(defaultValue: 'active')
  final String status; // 'active' | 'cancelled'
  @JsonKey(defaultValue: '')
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

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);

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
