import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'venue.g.dart';

@JsonSerializable()
class Venue extends Equatable {
  final String id;
  final String name;
  @JsonKey(defaultValue: '')
  final String sport;
  @JsonKey(defaultValue: '')
  final String location;
  @JsonKey(defaultValue: 0)
  final int pricePerHour;
  @JsonKey(defaultValue: 'INR')
  final String currency;
  @JsonKey(defaultValue: '🏟️')
  final String emoji;
  @JsonKey(defaultValue: 6)
  final int openHour;
  @JsonKey(defaultValue: 22)
  final int closeHour;

  const Venue({
    required this.id,
    required this.name,
    required this.sport,
    required this.location,
    required this.pricePerHour,
    required this.currency,
    required this.emoji,
    required this.openHour,
    required this.closeHour,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);
  Map<String, dynamic> toJson() => _$VenueToJson(this);

  String get currencySymbol {
    switch (currency) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '';
    }
  }

  /// "₹400/hr"
  String get priceLabel => '$currencySymbol$pricePerHour/hr';

  @override
  List<Object?> get props =>
      [id, name, sport, location, pricePerHour, currency, emoji, openHour, closeHour];
}
