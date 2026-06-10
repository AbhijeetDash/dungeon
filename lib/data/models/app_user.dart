import 'package:equatable/equatable.dart';

/// A hardcoded user (light auth). Sent to the API as the `X-User-Id` header.
class AppUser extends Equatable {
  final String id;
  final String name;

  const AppUser({required this.id, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  /// First-letter avatar fallback.
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  List<Object?> get props => [id, name];
}
