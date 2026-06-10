import 'package:equatable/equatable.dart';

enum TimeOfDayBand { morning, afternoon, evening }

TimeOfDayBand bandFromString(String? s) {
  switch (s) {
    case 'morning':
      return TimeOfDayBand.morning;
    case 'afternoon':
      return TimeOfDayBand.afternoon;
    default:
      return TimeOfDayBand.evening;
  }
}

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

class Slot extends Equatable {
  final String id;
  final String venueId;
  final String date;
  final int hour;
  final String label; // "06:00 - 07:00"
  final TimeOfDayBand band;
  final bool booked;

  const Slot({
    required this.id,
    required this.venueId,
    required this.date,
    required this.hour,
    required this.label,
    required this.band,
    required this.booked,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        id: json['id'] as String,
        venueId: json['venueId'] as String,
        date: json['date'] as String,
        hour: (json['hour'] as num).toInt(),
        label: json['label'] as String,
        band: bandFromString(json['timeOfDay'] as String?),
        booked: (json['status'] as String?) == 'booked',
      );

  bool get available => !booked;

  @override
  List<Object?> get props => [id, venueId, date, hour, label, band, booked];
}
