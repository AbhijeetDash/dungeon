import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../data/models/venue.dart';
import '../../data/repositories/venue_repository.dart';

enum VenuesStatus { loading, success, failure }

class VenuesState extends Equatable {
  final VenuesStatus status;
  final List<Venue> all;
  final String query;
  final String category; // 'All' or a sport name
  final String? error;

  const VenuesState({
    this.status = VenuesStatus.loading,
    this.all = const [],
    this.query = '',
    this.category = 'All',
    this.error,
  });

  /// Filter chips: 'All' + each distinct sport, in first-seen order.
  List<String> get categories {
    final set = <String>{'All'};
    for (final v in all) {
      set.add(v.sport);
    }
    return set.toList();
  }

  /// Venues after the search query + category filter. Derived in the state so a
  /// widget never filters business data itself (keeps logic out of the UI).
  List<Venue> get visible {
    final q = query.trim().toLowerCase();
    return all.where((v) {
      final byCategory = category == 'All' || v.sport == category;
      final byQuery = q.isEmpty ||
          v.name.toLowerCase().contains(q) ||
          v.location.toLowerCase().contains(q) ||
          v.sport.toLowerCase().contains(q);
      return byCategory && byQuery;
    }).toList();
  }

  VenuesState copyWith({
    VenuesStatus? status,
    List<Venue>? all,
    String? query,
    String? category,
    String? error,
  }) {
    return VenuesState(
      status: status ?? this.status,
      all: all ?? this.all,
      query: query ?? this.query,
      category: category ?? this.category,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, all, query, category, error];
}

class VenuesCubit extends Cubit<VenuesState> {
  VenuesCubit(this._repo) : super(const VenuesState());
  final VenueRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: VenuesStatus.loading));
    try {
      final venues = await _repo.getVenues();
      emit(state.copyWith(status: VenuesStatus.success, all: venues));
    } on ApiException catch (e) {
      emit(state.copyWith(status: VenuesStatus.failure, error: e.message));
    }
  }

  void search(String query) => emit(state.copyWith(query: query));
  void selectCategory(String category) =>
      emit(state.copyWith(category: category));
}
