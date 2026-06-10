import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'slot.g.dart';

/// Enum values match the API's `timeOfDay` strings exactly, so json_serializable
/// maps them by name with no custom converter.
enum TimeOfDayBand { morning, afternoon, evening }

extension TimeOfDayBandX on TimeOfDayBand {
  String get label {
    switch (this) {
      case TimeOfDayBand.morning:
        return 'Morning';
      case TimeOfDayBand.afternoon:
        return 'Afternoon';
      case TimeOfDayBand.evening:
        return 'Evening';
    }
  }
}

@JsonSerializable()
class Slot extends Equatable {
  final String id;
  final String venueId;
  final String date;
  final int hour;
  final String label; // "06:00 - 07:00"

  @JsonKey(name: 'timeOfDay', unknownEnumValue: TimeOfDayBand.evening)
  final TimeOfDayBand band;

  final String status; // 'available' | 'booked'

  const Slot({
    required this.id,
    required this.venueId,
    required this.date,
    required this.hour,
    required this.label,
    required this.band,
    required this.status,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);
  Map<String, dynamic> toJson() => _$SlotToJson(this);

  bool get booked => status == 'booked';
  bool get available => !booked;

  @override
  List<Object?> get props => [id, venueId, date, hour, label, band, status];
}
