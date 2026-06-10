import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme.dart';
import '../../logic/venues/venues_cubit.dart';
import '../widgets/state_views.dart';
import '../widgets/venue_card.dart';
import 'venue_detail_screen.dart';

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QuickSlot',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text('Find a Venue',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (q) => context.read<VenuesCubit>().search(q),
              decoration: InputDecoration(
                hintText: 'Search arenas, courts, clubs…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<VenuesCubit, VenuesState>(
              builder: (context, state) {
                switch (state.status) {
                  case VenuesStatus.loading:
                    return const LoadingView(label: 'Loading venues…');
                  case VenuesStatus.failure:
                    return AppErrorView(
                      message: state.error ?? 'Could not load venues.',
                      onRetry: () => context.read<VenuesCubit>().load(),
                    );
                  case VenuesStatus.success:
                    final venues = state.visible;
                    return Column(
                      children: [
                        _CategoryChips(state: state),
                        const SizedBox(height: 4),
                        Expanded(
                          child: venues.isEmpty
                              ? const EmptyView(
                                  title: 'No venues match',
                                  subtitle: 'Try a different search or category.',
                                  icon: Icons.search_off_rounded,
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: venues.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (_, i) {
                                    final venue = venues[i];
                                    return VenueCard(
                                      venue: venue,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              VenueDetailScreen(venue: venue),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.state});
  final VenuesState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final category = state.categories[i];
          final selected = category == state.category;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => context.read<VenuesCubit>().selectCategory(category),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}
