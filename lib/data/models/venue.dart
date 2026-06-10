import 'package:equatable/equatable.dart';

class Venue extends Equatable {
  final String id;
  final String name;
  final String sport;
  final String location;
  final int pricePerHour;
  final String currency;
  final String emoji;
  final int openHour;
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

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        id: json['id'] as String,
        name: json['name'] as String,
        sport: (json['sport'] ?? '') as String,
        location: (json['location'] ?? '') as String,
        pricePerHour: (json['pricePerHour'] ?? 0) as int,
        currency: (json['currency'] ?? 'INR') as String,
        emoji: (json['emoji'] ?? '🏟️') as String,
        openHour: (json['openHour'] ?? 6) as int,
        closeHour: (json['closeHour'] ?? 22) as int,
      );

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
