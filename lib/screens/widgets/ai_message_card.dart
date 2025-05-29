import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/message.dart';

class AiMessageCard extends StatelessWidget {
  final AiMessage message;

  const AiMessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(16);

    final boxShadow = [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 6,
        offset: Offset(2, 2),
      )
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.msgType == MessageType.user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (message.msgType == MessageType.bot) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Image.asset('images/logo.png', width: 24),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              margin: message.msgType == MessageType.user
                  ? EdgeInsets.only(left: 30)
                  : EdgeInsets.only(right: 30),
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: message.msgType == MessageType.bot
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                border: Border.all(
                  color: message.msgType == MessageType.bot
                      ? Colors.blue
                      : Colors.green,
                ),
                borderRadius: message.msgType == MessageType.bot
                    ? const BorderRadius.only(
                    topLeft: r, topRight: r, bottomRight: r)
                    : const BorderRadius.only(
                    topLeft: r, topRight: r, bottomLeft: r),
                boxShadow: boxShadow,
              ),
              child: Text(
                message.msg,
                textAlign: message.msgType == MessageType.bot
                    ? TextAlign.start
                    : TextAlign.end,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          if (message.msgType == MessageType.user)
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}
