import '../../core/api_client.dart';
import '../models/app_user.dart';

class UserRepository {
  UserRepository(this._api);
  final ApiClient _api;

  /// GET /users → the hardcoded user list (powers the login/select screen).
  Future<List<AppUser>> getUsers() async {
    final json = await _api.get('/users') as Map<String, dynamic>;
    final users = (json['users'] as List).cast<Map<String, dynamic>>();
    return users.map(AppUser.fromJson).toList();
  }
}
