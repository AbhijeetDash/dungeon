// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Venue _$VenueFromJson(Map<String, dynamic> json) => Venue(
  id: json['id'] as String,
  name: json['name'] as String,
  sport: json['sport'] as String? ?? '',
  location: json['location'] as String? ?? '',
  pricePerHour: (json['pricePerHour'] as num?)?.toInt() ?? 0,
  currency: json['currency'] as String? ?? 'INR',
  emoji: json['emoji'] as String? ?? '🏟️',
  openHour: (json['openHour'] as num?)?.toInt() ?? 6,
  closeHour: (json['closeHour'] as num?)?.toInt() ?? 22,
);

Map<String, dynamic> _$VenueToJson(Venue instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sport': instance.sport,
  'location': instance.location,
  'pricePerHour': instance.pricePerHour,
  'currency': instance.currency,
  'emoji': instance.emoji,
  'openHour': instance.openHour,
  'closeHour': instance.closeHour,
};
