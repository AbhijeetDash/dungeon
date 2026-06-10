import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/slot.dart';

/// A single slot pill. Three visual states matching the mockup:
///   • available → white with a border, tappable
///   • selected  → filled blue
///   • booked    → grey, strikethrough, not tappable
class SlotChip extends StatelessWidget {
  const SlotChip({
    super.key,
    required this.slot,
    required this.selected,
    required this.onTap,
  });
  final Slot slot;
  final bool selected;
  final VoidCallback? onTap;

  static String _fmt(int h) {
    final period = h < 12 ? 'AM' : 'PM';
    final hr = (h % 12 == 0) ? 12 : h % 12;
    return '${hr.toString().padLeft(2, '0')}:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    final booked = slot.booked;

    late Color bg;
    late Color fg;
    Border? border;
    if (booked) {
      bg = AppColors.chipBg;
      fg = AppColors.textSecondary;
    } else if (selected) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else {
      bg = AppColors.surface;
      fg = AppColors.textPrimary;
      border = Border.all(color: AppColors.border);
    }

    return InkWell(
      onTap: booked ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Text(
          _fmt(slot.hour),
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            decoration: booked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
