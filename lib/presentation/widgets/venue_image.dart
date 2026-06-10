import 'package:flutter/material.dart';

import '../../data/models/venue.dart';

/// A gradient "photo" header keyed by sport, with the venue's emoji centered.
/// Deliberately asset-free so the app runs anywhere with no image downloads —
/// reliable for the demo, and it still gives each card a distinct look.
class VenueImage extends StatelessWidget {
  const VenueImage({super.key, required this.venue, this.height = 150});
  final Venue venue;
  final double height;

  static List<Color> _gradient(String sport) {
    switch (sport) {
      case 'Badminton':
        return const [Color(0xFF2A6FF0), Color(0xFF14357A)];
      case 'Football':
        return const [Color(0xFF1FA45C), Color(0xFF0C5C32)];
      case 'Tennis':
        return const [Color(0xFFE08A2B), Color(0xFFB35711)];
      default:
        return const [Color(0xFF5B6472), Color(0xFF2B313B)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient(venue.sport),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(venue.emoji, style: const TextStyle(fontSize: 56)),
      ),
    );
  }
}
