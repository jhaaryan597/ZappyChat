import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zappychat/models/chat_user.dart';
import 'package:zappychat/models/message.dart';
import '../api/apis.dart';

final messagesProvider = StreamProvider.family<List<Message>, ChatUser>((
  ref,
  user,
) {
  return APIs.getAllMessages(
    user,
  ).map((data) => data.map((e) => Message.fromJson(e)).toList());
});

final textControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  return TextEditingController();
});

final showEmojiProvider = StateProvider<bool>((ref) => false);

final userInfoProvider = StreamProvider.family<ChatUser, ChatUser>((ref, user) {
  return APIs.getUserInfo(user).map((data) {
    final list = data.map((e) => ChatUser.fromJson(e)).toList();
    return list.isNotEmpty ? list[0] : user;
  });
});
