// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
  id: json['id'] as String,
  userId: json['userId'] as String,
  venueId: json['venueId'] as String,
  date: json['date'] as String,
  hour: (json['hour'] as num).toInt(),
  slotId: json['slotId'] as String? ?? '',
  status: json['status'] as String? ?? 'active',
  createdAt: json['createdAt'] as String? ?? '',
);

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'venueId': instance.venueId,
  'date': instance.date,
  'hour': instance.hour,
  'slotId': instance.slotId,
  'status': instance.status,
  'createdAt': instance.createdAt,
};
