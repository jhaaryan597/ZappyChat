import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zappychat/models/chat_user.dart';
import 'package:zappychat/screens/view_profile_screen.dart';
import '../../../main.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white.withAlpha(230), // 128 = 50% opacity
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: mq.width * .6,
        height: mq.height * .35,
        child: Stack(
          children: [
            // user profile picture
            Positioned(
              top: mq.height * .085,
              left: mq.width * .06,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(mq.width * 0.25),
                child: CachedNetworkImage(
                  width: mq.width * 0.5,
                  fit: BoxFit.fill,
                  placeholder:
                      (context, url) => Image.network(
                        '${user.image}', // 👈 fallback image while loading
                        fit: BoxFit.cover,
                      ),
                  imageUrl: user.image,
                  errorWidget:
                      (context, url, error) => const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(CupertinoIcons.person, color: Colors.white),
                      ),
                ),
              ),
            ),

            // user ka naam
            Positioned(
              left: mq.width * 0.04,
              top: mq.height * 0.02,
              width: mq.width * 0.55,
              child: Text(
                user.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),

            // info icon
            Positioned(
              top: 6,
              right: 8,
              child: MaterialButton(
                minWidth: 0,
                padding: const EdgeInsets.all(0),
                shape: const CircleBorder(),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewProfileScreen(user: user),
                    ),
                  );
                },
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
