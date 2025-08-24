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
import 'helper/theme.dart';
import 'main.dart';
import 'models/message.dart';
import 'providers/smart_reply_provider.dart';
import 'providers/suggestion_provider.dart';

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
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          ),
          title: AppBarContent(user: user),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: Column(
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
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ),
              ChatInput(user: user, messages: messages.value ?? []),
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
      ),
    );
  }
}

class SmartReply extends ConsumerWidget {
  final List<Message> messages;
  const SmartReply({super.key, required this.messages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smartReplies = ref.watch(smartReplyProvider(messages));
    return smartReplies.when(
      data: (replies) {
        if (replies.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: replies.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ActionChip(
                  label: Text(
                    replies[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    ref.read(textControllerProvider).text = replies[index];
                  },
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
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
                  onPressed: () => Navigator.pop(context),
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
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chatUser.isOnline
                          ? 'Online'
                          : MyDateUtil.getLastActiveTime(
                            context: context,
                            lastActive:
                                DateTime.tryParse(
                                  chatUser.lastActive,
                                )?.millisecondsSinceEpoch.toString() ??
                                '',
                          ),
                      style: const TextStyle(
                        color: Colors.white70,
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

class ChatInput extends ConsumerStatefulWidget {
  final ChatUser user;
  final List<Message> messages;
  const ChatInput({super.key, required this.user, required this.messages});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textController = ref.watch(textControllerProvider);
    final showEmoji = ref.watch(showEmojiProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (_imageFile != null)
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          ref.read(showEmojiProvider.notifier).state =
                              !showEmoji;
                        },
                        icon: const Icon(Icons.emoji_emotions_outlined),
                      ),
                      Expanded(
                        child: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: 'Message',
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
                            setState(() {
                              _imageFile = File(image.path);
                            });
                          }
                        },
                        icon: const Icon(Icons.image_outlined),
                      ),
                      IconButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (image != null) {
                            setState(() {
                              _imageFile = File(image.path);
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () async {
                  if (_imageFile != null) {
                    final imageUrl = await APIs.uploadFile(
                      _imageFile!,
                      'images/${DateTime.now().millisecondsSinceEpoch}.${_imageFile!.path.split('.').last}',
                    );
                    await APIs.sendMessage(
                      widget.user,
                      imageUrl,
                      type: Type.image,
                    );
                    setState(() {
                      _imageFile = null;
                    });
                  } else if (textController.text.trim().isNotEmpty) {
                    APIs.sendMessage(widget.user, textController.text.trim());
                    textController.clear();
                  }
                },
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
