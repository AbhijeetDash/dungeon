import 'package:flutter/material.dart';

import '../../core/date_x.dart';
import '../../core/theme.dart';
import '../../data/models/booking.dart';
import '../../data/models/venue.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.venue,
    this.onCancel,
    this.cancelling = false,
  });

  final Booking booking;
  final Venue? venue; // resolved from the venue cache; may be null defensively
  final VoidCallback? onCancel; // null → not cancellable (e.g. Past tab)
  final bool cancelling;

  @override
  Widget build(BuildContext context) {
    final date = DateX.parseYmd(booking.date);
    final cancelled = !booking.isActive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(venue?.emoji ?? '🏟️',
                      style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue?.name ?? booking.venueId,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date != null ? DateX.prettyShort(date) : booking.date} · ${booking.timeLabel}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(cancelled: cancelled),
              ],
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: cancelling ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close_rounded, size: 18),
                  label: Text(cancelling ? 'Cancelling…' : 'Cancel booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.cancelled});
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final color = cancelled ? AppColors.textSecondary : AppColors.success;
    final bg = cancelled ? AppColors.chipBg : AppColors.successBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        cancelled ? 'CANCELLED' : 'CONFIRMED',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
