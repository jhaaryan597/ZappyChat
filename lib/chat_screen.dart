import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zappychat/helper/my_date_util.dart';
import 'package:zappychat/models/chat_user.dart';
import 'package:zappychat/providers/chat_providers.dart';
import 'package:zappychat/screens/home_screen.dart';
import 'package:zappychat/screens/view_profile_screen.dart';
import 'package:zappychat/screens/widgets/message_card.dart';
import 'api/apis.dart';
import 'main.dart';
import 'models/message.dart';

class ChatScreen extends ConsumerWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = ref.watch(textControllerProvider);
    final showEmoji = ref.watch(showEmojiProvider);
    final messages = ref.watch(messagesProvider(user));
    final userInfo = ref.watch(userInfoProvider(user));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE3F0FB),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blueAccent,
          toolbarHeight: 80,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.blueAccent,
            statusBarIconBrightness: Brightness.light,
          ),
          title: SafeArea(child: AppBarContent(user: user)),
        ),
        body: Column(
          children: [
            Expanded(
              child: messages.when(
                data: (list) {
                  if (list.isNotEmpty) {
                    return ListView.builder(
                      reverse: true,
                      itemCount: list.length,
                      padding: EdgeInsets.only(top: mq.height * 0.01),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return MessageCard(message: list[index]);
                      },
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'Say Hii! 👋🏻',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
            ChatInput(user: user),
            if (showEmoji)
              SizedBox(
                height: mq.height * 0.35,
                child: EmojiPicker(
                  textEditingController: textController,
                  config: Config(
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax:
                          28 *
                          (foundation.defaultTargetPlatform ==
                                  TargetPlatform.iOS
                              ? 1.20
                              : 1.0),
                      backgroundColor: const Color(0xFFE3F0FB),
                      columns: 8,
                    ),
                    categoryViewConfig: const CategoryViewConfig(),
                    bottomActionBarConfig: const BottomActionBarConfig(
                      enabled: true,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppBarContent extends ConsumerWidget {
  final ChatUser user;
  const AppBarContent({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider(user));
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewProfileScreen(user: user)),
        );
      },
      child: userInfo.when(
        data:
            (chatUser) => Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * 0.03),
                  child: CachedNetworkImage(
                    width: mq.height * 0.05,
                    height: mq.height * 0.05,
                    fit: BoxFit.fill,
                    imageUrl: chatUser.image,
                    errorWidget:
                        (context, url, error) => const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(
                            CupertinoIcons.person,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
                SizedBox(width: mq.width * 0.02),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatUser.name,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chatUser.isOnline
                          ? 'Online'
                          : MyDateUtil.getLastActiveTime(
                            context: context,
                            lastActive: chatUser.lastActive,
                          ),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => const Text('Error'),
      ),
    );
  }
}

class ChatInput extends ConsumerWidget {
  final ChatUser user;
  const ChatInput({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = ref.watch(textControllerProvider);
    final showEmoji = ref.watch(showEmojiProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: mq.height * 0.01,
        horizontal: mq.width * 0.025,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          ref.read(showEmojiProvider.notifier).state =
                              !showEmoji;
                        },
                        icon: const Icon(
                          Icons.emoji_emotions,
                          color: Colors.blueAccent,
                          size: 25,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: textController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          onTap: () {
                            if (showEmoji) {
                              ref.read(showEmojiProvider.notifier).state =
                                  false;
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Type Something...',
                            hintStyle: TextStyle(color: Colors.blueAccent),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            final imageUrl = await APIs.uploadFile(
                              File(image.path),
                              'images/${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}',
                            );
                            await APIs.sendMessage(
                              user,
                              imageUrl,
                              type: Type.image,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.image,
                          color: Colors.blueAccent,
                          size: 26,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (image != null) {
                            final imageUrl = await APIs.uploadFile(
                              File(image.path),
                              'images/${DateTime.now().millisecondsSinceEpoch}.${image.path.split('.').last}',
                            );
                            await APIs.sendMessage(
                              user,
                              imageUrl,
                              type: Type.image,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.blueAccent,
                          size: 26,
                        ),
                      ),
                      SizedBox(width: mq.width * 0.02),
                    ],
                  ),
                ),
              ),
              MaterialButton(
                onPressed: () {
                  if (textController.text.trim().isNotEmpty) {
                    APIs.sendMessage(user, textController.text.trim());
                    textController.clear();
                  }
                },
                shape: const CircleBorder(),
                minWidth: 0,
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 5,
                  left: 10,
                ),
                color: Colors.green,
                child: const Icon(Icons.send, color: Colors.black87, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
