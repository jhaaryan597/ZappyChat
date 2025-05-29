import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zappychat/helper/dialogs.dart';
import 'package:zappychat/helper/my_date_util.dart';
import 'package:zappychat/screens/auth/login_screen.dart';
import '../api/apis.dart';
import '../main.dart';
import '../models/chat_user.dart';

class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ViewProfileScreen({super.key, required this.user});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreen();
}

// view profile screen
class _ViewProfileScreen extends State<ViewProfileScreen> {
  @override
  void initState() {
    super.initState();
    APIs.me = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // app bar
        appBar: AppBar(title: Text(widget.user.name)),

        //floating btn
        floatingActionButton: // user about
            Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Joined On: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            Text(
              MyDateUtil.getLastMessageTime(
                context: context,
                time: widget.user.createdAt,
                showYear: true
              ),
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ],
        ),

        // chat card
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // add some space
                SizedBox(width: mq.width, height: mq.height * 0.03),
                // user image
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.width * 0.25),
                  child: CachedNetworkImage(
                    width: mq.width * 0.5,
                    fit: BoxFit.fill,
                    placeholder:
                        (context, url) => Image.network(
                      '${widget.user.image}', // 👈 fallback image while loading
                      fit: BoxFit.cover,
                    ),
                    imageUrl: widget.user.image,
                    errorWidget:
                        (context, url, error) => const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(CupertinoIcons.person, color: Colors.white),
                    ),
                  ),
                ),

                // add some space
                SizedBox(height: mq.height * 0.03),
                Text(
                  widget.user.email,
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                // add some space
                SizedBox(height: mq.height * 0.02),

                // user about
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'About: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      widget.user.about,
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
