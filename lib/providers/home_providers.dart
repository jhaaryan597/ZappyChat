import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zappychat/models/chat_user.dart';
import '../api/apis.dart';

final allUsersProvider = StreamProvider<List<ChatUser>>((ref) {
  return APIs.getAllUsers().map(
    (data) => data.map((e) => ChatUser.fromJson(e)).toList(),
  );
});

final isSearchingProvider = StateProvider<bool>((ref) => false);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchedUsersProvider = Provider<List<ChatUser>>((ref) {
  final allUsers = ref.watch(allUsersProvider).asData?.value ?? [];
  final searchQuery = ref.watch(searchQueryProvider);

  if (searchQuery.isEmpty) {
    return allUsers;
  }

  return allUsers
      .where(
        (user) =>
            user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(searchQuery.toLowerCase()),
      )
      .toList();
});

final selfInfoProvider = FutureProvider<ChatUser>((ref) async {
  await APIs.getSelfInfo();
  return APIs.me;
});
