import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zappychat/providers/home_providers.dart';
import 'package:zappychat/screens/auth/login_screen.dart';
import 'package:zappychat/screens/profile_screen.dart';

import '../api/apis.dart';
import '../main.dart';
import 'ai_screen.dart';
import 'widgets/chat_user_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(isSearchingProvider);
    final searchedUsers = ref.watch(searchedUsersProvider);
    final selfInfo = ref.watch(selfInfoProvider);

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

    return selfInfo.when(
      data:
          (me) => GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: const Color(0xFFE3F0FB),
              appBar: AppBar(
                leading: const Icon(CupertinoIcons.home),
                title:
                    isSearching
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
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                        )
                        : const Text('ZappyChat'),
                actions: [
                  IconButton(
                    onPressed: () {
                      ref.read(isSearchingProvider.notifier).state =
                          !isSearching;
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    icon: Icon(
                      isSearching
                          ? CupertinoIcons.clear_circled_solid
                          : Icons.search,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(user: me),
                        ),
                      );
                    },
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              floatingActionButton: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'ai_button',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AiScreen(),
                        ),
                      );
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.android, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'logout_button',
                    onPressed: () async {
                      await APIs.supabase.auth.signOut();
                      await GoogleSignIn().signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(
                      Icons.add_comment_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              body: ref
                  .watch(allUsersProvider)
                  .when(
                    data: (users) {
                      if (searchedUsers.isNotEmpty) {
                        return ListView.builder(
                          itemCount: searchedUsers.length,
                          padding: EdgeInsets.only(top: mq.height * 0.01),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return ChatUserCard(user: searchedUsers[index]);
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
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stack) => Center(child: Text('Error: $error')),
                  ),
            ),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
