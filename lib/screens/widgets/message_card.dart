import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zappychat/api/apis.dart';
import 'package:zappychat/helper/dialogs.dart';
import 'package:zappychat/helper/my_date_util.dart';
import 'package:zappychat/screens/image_question_screen.dart';
import '../../main.dart';
import '../../models/message.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.id == widget.message.fromId;
    return InkWell(
      onLongPress: () {
        _showBottomSheet(isMe);
      },
      child: isMe ? _greenMessage() : _blueMessage(),
    );
  }

  Widget _blueMessage() {
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: _buildMessageContent(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            MyDateUtil.getFormattedTime(
              context: context,
              time: widget.message.sent,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _greenMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.message.read.isNotEmpty)
            const Icon(Icons.done_all_rounded, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            MyDateUtil.getFormattedTime(
              context: context,
              time: widget.message.sent,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: _buildMessageContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return widget.message.type == Type.text
        ? Text(
          widget.message.msg,
          style: TextStyle(
            color:
                APIs.user.id == widget.message.fromId
                    ? Colors.white
                    : Colors.black,
          ),
        )
        : ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              FutureBuilder<String>(
                future: APIs.createSignedUrl(widget.message.msg),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Icon(Icons.image, size: 70);
                  }
                  return CachedNetworkImage(
                    imageUrl: snapshot.data!,
                    placeholder:
                        (context, url) => const CircularProgressIndicator(),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.image, size: 70),
                  );
                },
              ),
            ],
          ),
        );
  }

  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: [
            Container(
              height: 4,
              margin: EdgeInsets.symmetric(
                vertical: mq.height * 0.02,
                horizontal: mq.width * 0.4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            _OptionItem(
              icon: Icon(Icons.copy_all_rounded, color: Colors.blue, size: 26),
              name: 'Copy Text',
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: widget.message.msg),
                ).then((value) {
                  Navigator.pop(context);
                  Dialogs.showSnackbar(context, 'Text Copied!');
                });
              },
            ),
            Divider(
              color: Colors.black54,
              endIndent: mq.width * 0.05,
              indent: mq.width * 0.05,
            ),
            if (isMe)
              _OptionItem(
                icon: Icon(Icons.edit, color: Colors.blue, size: 26),
                name: 'Edit Message',
                onTap: () {
                  Navigator.pop(context);
                  _showMessageUpdateDialog();
                },
              ),
            if (isMe)
              _OptionItem(
                icon: Icon(Icons.delete_forever, color: Colors.red, size: 26),
                name: 'Delete Message',
                onTap: () {
                  APIs.deleteMessage(widget.message).then((value) {
                    Navigator.pop(context);
                  });
                },
              ),
            if (isMe)
              Divider(
                color: Colors.black54,
                endIndent: mq.width * 0.05,
                indent: mq.width * 0.05,
              ),
            _OptionItem(
              icon: Icon(Icons.remove_red_eye, color: Colors.blue),
              name:
                  'Send At: ${MyDateUtil.getMessageTime(context: context, lastTime: widget.message.sent)}',
              onTap: () {},
            ),
            _OptionItem(
              icon: Icon(Icons.remove_red_eye, color: Colors.green),
              name:
                  widget.message.read.isEmpty
                      ? 'Read At: Not seen yet'
                      : 'Read At: ${MyDateUtil.getMessageTime(context: context, lastTime: widget.message.read)}',
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  void _showMessageUpdateDialog() {
    String updatedMsg = widget.message.msg;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            contentPadding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.message, color: Colors.blue, size: 28),
                Text(' Updated Message'),
              ],
            ),
            content: TextFormField(
              initialValue: updatedMsg,
              maxLines: null,
              onChanged: (value) => updatedMsg = value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.pop(context);
                  APIs.updateMessage(widget.message, updatedMsg);
                },
                child: const Text(
                  'Update',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: mq.height * 0.02,
          horizontal: mq.width * 0.05,
        ),
        child: Row(
          children: [
            icon,
            SizedBox(width: mq.width * 0.03),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
