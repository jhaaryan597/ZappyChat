import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zappychat/models/chat_user.dart';
import 'package:zappychat/models/message.dart';
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

  // Filter by search query (if any)
  List<ChatUser> filtered = searchQuery.isEmpty
      ? List.of(allUsers)
      : allUsers
          .where(
            (user) => user.name
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                user.email
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()),
          )
          .toList();

  // Sort by latest activity/message time (desc):
  // 1) latest message.sent if exists
  // 2) fallback to user's lastActive
  // 3) fallback to user's createdAt
  int tsFor(ChatUser u) {
    final lastMsg = ref.watch(lastMessageProvider(u)).asData?.value;
    if (lastMsg != null) {
      return int.tryParse(lastMsg.sent) ?? 0;
    }
    return int.tryParse(u.lastActive) ?? int.tryParse(u.createdAt) ?? 0;
  }

  filtered.sort((a, b) => tsFor(b).compareTo(tsFor(a)));

  return filtered;
});

final selfInfoProvider = FutureProvider.autoDispose<ChatUser>((ref) async {
  await APIs.getSelfInfo();
  return APIs.me;
});

// Stream of the latest message for a given user (or null if never messaged)
final lastMessageProvider =
    StreamProvider.family<Message?, ChatUser>((ref, user) {
  return APIs.getLastMessage(user).map((data) {
    final list = data.map((e) => Message.fromJson(e)).toList();
    return list.isNotEmpty ? list.first : null;
  });
});
