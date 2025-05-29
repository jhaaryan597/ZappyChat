import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zappychat/helper/my_date_util.dart';
import 'package:zappychat/models/chat_user.dart';
import 'package:zappychat/screens/home_screen.dart';
import 'package:zappychat/screens/view_profile_screen.dart';
import 'package:zappychat/screens/widgets/message_card.dart';
import 'api/apis.dart';
import 'main.dart';
import 'models/message.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // storing all msg
  List<Message> _list = [];

  // handle msg text change
  final _textController = TextEditingController();

  // for storing value of showing or hiding emoji
  bool _showEmoji = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Color(0xFFE3F0FB), // ✅ optional, makes it clean
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blueAccent, // ✅ set AppBar color
          toolbarHeight: 80, // ✅ optional height tweak
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.blueAccent, // ✅ this fixes status bar color
            statusBarIconBrightness:
                Brightness.light, // ✅ light icons on dark bg
          ),
          title: SafeArea(
            child: _appBar(),
          ), // ✅ put SafeArea inside AppBar title
        ),

        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: APIs.getAllMessages(widget.user),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    // if data is loading
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const SizedBox();
                    // If some or all data is loaded then how it
                    case ConnectionState.active:
                    case ConnectionState.done:
                      final data = snapshot.data?.docs;
                      _list =
                          data
                              ?.map((e) => Message.fromJson(e.data()))
                              .toList() ??
                          [];

                      if (_list.isNotEmpty) {
                        return ListView.builder(
                          reverse: true,
                          itemCount: _list.length,
                          padding: EdgeInsets.only(top: mq.height * 0.01),
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return MessageCard(message: _list[index]);
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
                  }
                },
              ),
            ),
            _chatInput(),

            //show emoji on keyboard emoji btn
            if (_showEmoji)
              SizedBox(
                height: mq.height * 0.35,
                child: EmojiPicker(
                  textEditingController: _textController,
                  config: Config(
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax:
                          28 *
                          (foundation.defaultTargetPlatform ==
                                  TargetPlatform.iOS
                              ? 1.20
                              : 1.0),
                      backgroundColor: Color(0xFFE3F0FB),
                      columns: 8,
                    ),
                    categoryViewConfig:
                        CategoryViewConfig(), // default config (no params)
                    bottomActionBarConfig: BottomActionBarConfig(
                      enabled: true, // just enables bottom action bar
                    ),
                  ),
                ),
              ),
          ],
        ), // ✅ your chat body goes here
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewProfileScreen(user: widget.user),
          ),
        );
      },
      child: StreamBuilder(
        stream: APIs.getUserInfo(widget.user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list =
              data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

          return Row(
            children: [
              // back btn
              IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                  ); // ✅ optional back
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ), // ✅ white icon
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * 0.03),
                child: CachedNetworkImage(
                  width: mq.height * 0.05,
                  height: mq.height * 0.05,
                  fit: BoxFit.fill,
                  placeholder:
                      (context, url) => Image.network(
                        '${widget.user.image}', // 👈 fallback image while loading
                        fit: BoxFit.cover,
                      ),
                  imageUrl: list.isNotEmpty ? list[0].image : widget.user.image,
                  errorWidget:
                      (context, url, error) => const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(CupertinoIcons.person, color: Colors.white),
                      ),
                ),
              ),
              SizedBox(width: mq.width * 0.02),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.isNotEmpty ? list[0].name : widget.user.name,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    list.isNotEmpty
                        ? list[0].isOnline
                            ? 'Online'
                            : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: list[0].lastActive,
                            )
                        : MyDateUtil.getLastActiveTime(
                          context: context,
                          lastActive: widget.user.lastActive,
                        ),
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: mq.height * 0.01,
        horizontal: mq.width * 0.025,
      ),
      child: Column(
        children: [
          Row(
            // msg sender
            children: [
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      // emoji btn
                      IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _showEmoji = !_showEmoji;
                          });
                        },
                        icon: const Icon(
                          Icons.emoji_emotions,
                          color: Colors.blueAccent,
                          size: 25,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          onTap: () {
                            if (_showEmoji)
                              setState(() {
                                _showEmoji = !_showEmoji;
                              });
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
                          // pick an image
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            log(
                              'Image Path: ${image.path} -- MimeType: ${image.mimeType}',
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
                          // pick an image
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (image != null) {
                            log('Image Path: ${image.path}');
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
                  if (_textController.text.trim().isNotEmpty) {
                    APIs.sendMessage(widget.user, _textController.text.trim());
                    _textController.clear();
                  }

                  // if(_textController.text.isNotEmpty){
                  //   APIs.sendMessage(widget.user, _textController.text);
                  //   _textController.text = '';
                  // }
                },
                shape: CircleBorder(),
                minWidth: 0,
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 5,
                  left: 10,
                ),
                color: Colors.green,
                child: Icon(Icons.send, color: Colors.black87, size: 28),
              ),
            ],
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }
}
