import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_user.g.dart';

/// A hardcoded user (light auth). Sent to the API as the `X-User-Id` header.
@JsonSerializable()
class AppUser extends Equatable {
  final String id;
  final String name;

  const AppUser({required this.id, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  /// First-letter avatar fallback.
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  List<Object?> get props => [id, name];
}
