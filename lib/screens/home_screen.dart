import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zappychat/screens/auth/login_screen.dart';
import 'package:zappychat/screens/profile_screen.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/chat_user.dart';
import 'ai_screen.dart';
import 'widgets/chat_user_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for Storing all users
  List<ChatUser> _list = [];
  // for storing searched users
  final List<ChatUser> _searchList = [];
  // search status
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message : $message');
      if (APIs.supabase.auth.currentUser != null) {
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
      }
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),

      child: Scaffold(
        backgroundColor: Color(0xFFE3F0FB),
        // app bar
        appBar: AppBar(
          leading: Icon(CupertinoIcons.home),
          title:
          _isSearching
              ? TextField(
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Name, Email, ...',
            ),
            style: const TextStyle(
              fontSize: 17,
              letterSpacing: 1,
              color: Colors.black54,
            ),
            autofocus: true,
            onChanged: (val) {
              // search logic
              _searchList.clear();
              for (var i in _list) {
                if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                    i.email.toLowerCase().contains(val.toLowerCase())) {
                  _searchList.add(i);
                }
                setState(() {
                  _searchList;
                });
              }
            },
          )
              : Text('ZappyChat'),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                });
              },
              icon: Icon(
                _isSearching
                    ? CupertinoIcons.clear_circled_solid
                    : Icons.search,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: APIs.me),
                  ),
                );
              },
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        // floating buttons
        floatingActionButton: Stack(
          children: [
            // AI Button
            Positioned(
              bottom: 80,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'ai_button',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AiScreen()), // Replace LoginPage() with your actual login screen widget
                  );
                },
                backgroundColor: Colors.green,
                child: Icon(Icons.android, color: Colors.white),
              ),
            ),
            // logout button
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'logout_button',
                onPressed: () async {
                  // sign out
                  await APIs.supabase.auth.signOut();
                  await GoogleSignIn().signOut();

                  // navigate to the login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()), // Replace LoginPage() with your actual login screen widget
                  );
                },
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.add_comment_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
        // chat card
        body: FutureBuilder(
          future: APIs.getSelfInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return GestureDetector(
              // hide the keyboard
              onTap: () => FocusScope.of(context).unfocus(),
              child: StreamBuilder(
                stream: APIs.getAllUsers(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    // if data is loading
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const Center(child: CircularProgressIndicator());
                    // If some or all data is loaded then how it
                    case ConnectionState.active:
                    case ConnectionState.done:
                      final data = snapshot.data;
                      _list =
                          data?.map((e) => ChatUser.fromJson(e)).toList() ??
                              [];

                      if (_list.isNotEmpty) {
                        return ListView.builder(
                          itemCount:
                              _isSearching ? _searchList.length : _list.length,
                          padding: EdgeInsets.only(top: mq.height * 0.01),
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return ChatUserCard(
                              user: _isSearching
                                  ? _searchList[index]
                                  : _list[index],
                            );
                          },
                        );
                      } else {
                        return const Center(
                          child: Text(
                            'No Connections Found!',
                            style: TextStyle(fontSize: 20),
                          ),
                        );
                      }
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
