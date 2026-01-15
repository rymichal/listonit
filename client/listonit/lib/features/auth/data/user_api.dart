import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/user.dart';

class UserApi {
  final ApiClient _client;

  UserApi(this._client);

  Future<List<User>> searchUsers({String query = ''}) async {
    return _client.get<List<User>>(
      '/users/search',
      queryParameters: {
        if (query.isNotEmpty) 'q': query,
      },
      fromJson: (data) => (data as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

final userApiProvider = Provider<UserApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserApi(client);
});
