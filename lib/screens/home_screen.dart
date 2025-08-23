import 'dart:developer';

import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zappychat/helper/theme.dart';
import 'package:zappychat/providers/home_providers.dart';
import 'package:zappychat/screens/auth/login_screen.dart';
import 'package:zappychat/screens/profile_screen.dart';

import '../api/apis.dart';
import '../main.dart';
import 'ai_screen.dart';
import 'widgets/chat_user_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              appBar: AppBar(
                elevation: 0,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                ),
                title: const Text(
                  'ZappyChat',
                  style: TextStyle(color: Colors.white),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      ref.read(isSearchingProvider.notifier).state =
                          !isSearching;
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    icon: Icon(
                      isSearching
                          ? cupertino.CupertinoIcons.clear_circled_solid
                          : Icons.search,
                      color: Colors.white,
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
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiScreen()),
                  );
                },
                icon: const Icon(Icons.android),
                label: const Text('Ask AI'),
              ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Column(
                  children: [
                    if (isSearching)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.search, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white24,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                        ),
                      ),
                    Expanded(
                      child: ref
                          .watch(allUsersProvider)
                          .when(
                            data: (users) {
                              if (searchedUsers.isNotEmpty) {
                                return ListView.builder(
                                  itemCount: searchedUsers.length,
                                  itemBuilder: (context, index) {
                                    return FadeTransition(
                                      opacity: _animation,
                                      child: ChatUserCard(
                                        user: searchedUsers[index],
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return const Center(
                                  child: Text('No users found'),
                                );
                              }
                            },
                            loading:
                                () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            error:
                                (error, stack) =>
                                    Center(child: Text('Error: $error')),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
