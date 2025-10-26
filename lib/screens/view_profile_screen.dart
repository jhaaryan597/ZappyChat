import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zappychat/helper/my_date_util.dart';
import '../helper/theme.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // app bar
        appBar: AppBar(
          elevation: 0,
          title: Text(widget.user.name),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          ),
        ),

        //floating btn
        floatingActionButton: // user about
            Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Joined On: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            Text(
              MyDateUtil.getLastMessageTime(
                context: context,
                time: widget.user.createdAt,
                showYear: true,
              ),
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),

        // chat card
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: Padding(
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
                            '${widget.user.image}', // fallback image while loading
                            fit: BoxFit.cover,
                          ),
                      imageUrl: widget.user.image,
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

                  // add some space
                  SizedBox(height: mq.height * 0.03),
                  Text(
                    widget.user.email,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  // add some space
                  SizedBox(height: mq.height * 0.02),

                  // user about
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'About: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        widget.user.about,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
