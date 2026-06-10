import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/slot.dart';

/// "Filter slots by time of day" (the bonus). null == All.
class TimeFilterChips extends StatelessWidget {
  const TimeFilterChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final TimeOfDayBand? selected;
  final ValueChanged<TimeOfDayBand?> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TimeOfDayBand? band) {
      final isSelected = selected == band;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => onSelect(band),
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', null),
          chip('Morning', TimeOfDayBand.morning),
          chip('Afternoon', TimeOfDayBand.afternoon),
          chip('Evening', TimeOfDayBand.evening),
        ],
      ),
    );
  }
}
