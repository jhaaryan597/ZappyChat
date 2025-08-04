import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zappychat/api/apis.dart';
import 'package:zappychat/helper/my_date_util.dart';
import 'package:zappychat/screens/widgets/dialogs/profile_dialog.dart';
import '../../chat_screen.dart';
import '../../main.dart';
import '../../models/chat_user.dart';
import '../../models/message.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  // Last message info
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * 0.04, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Navigate to chat screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)),
          );
        },
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final list =
                data?.map((e) => Message.fromJson(e)).toList() ?? [];
            if (list.isNotEmpty) {
              _message = list[0];
            }

            return ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              leading: InkWell(
                onTap: (){
                  showDialog(context: context, builder: (_) => ProfileDialog(user: widget.user,));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * 0.15),
                  child: CachedNetworkImage(
                    width: mq.height * 0.07,
                    height: mq.height * 0.07,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    imageUrl: widget.user.image,
                    errorWidget: (context, url, error) => CircleAvatar(
                      backgroundColor: Colors.blue.shade300,
                      child: Icon(CupertinoIcons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
              title: Text(
                widget.user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                _message != null
                    ? _message!.type == Type.image
                    ? 'Image'
                    : _message!.msg
                    : widget.user.about,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
              trailing: _message == null
                  ? null
                  : _message!.read.isEmpty && _message!.fromId != APIs.user.id
                  ? Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  borderRadius: BorderRadius.circular(6),
                ),
              )
                  : Text(
                MyDateUtil.getLastMessageTime(
                  context: context,
                  time: _message!.sent,
                ),
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
