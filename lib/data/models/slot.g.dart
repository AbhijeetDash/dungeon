// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Slot _$SlotFromJson(Map<String, dynamic> json) => Slot(
  id: json['id'] as String,
  venueId: json['venueId'] as String,
  date: json['date'] as String,
  hour: (json['hour'] as num).toInt(),
  label: json['label'] as String,
  band: $enumDecode(
    _$TimeOfDayBandEnumMap,
    json['timeOfDay'],
    unknownValue: TimeOfDayBand.evening,
  ),
  status: json['status'] as String,
);

Map<String, dynamic> _$SlotToJson(Slot instance) => <String, dynamic>{
  'id': instance.id,
  'venueId': instance.venueId,
  'date': instance.date,
  'hour': instance.hour,
  'label': instance.label,
  'timeOfDay': _$TimeOfDayBandEnumMap[instance.band]!,
  'status': instance.status,
};

const _$TimeOfDayBandEnumMap = {
  TimeOfDayBand.morning: 'morning',
  TimeOfDayBand.afternoon: 'afternoon',
  TimeOfDayBand.evening: 'evening',
};
