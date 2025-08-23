import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zappychat/models/chat_user.dart';
import '../api/apis.dart';

final profileImageProvider = StateProvider<String?>((ref) => null);

final userProvider = StateNotifierProvider<UserNotifier, ChatUser>((ref) {
  return UserNotifier(APIs.me);
});

class UserNotifier extends StateNotifier<ChatUser> {
  UserNotifier(super.state);

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateAbout(String about) {
    state = state.copyWith(about: about);
  }

  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      // Not updating state here, just the local image provider
    }
  }
}
