import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zappychat/helper/dialogs.dart';
import 'package:zappychat/providers/profile_providers.dart';
import 'package:zappychat/screens/auth/login_screen.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/chat_user.dart';

class ProfileScreen extends ConsumerWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final image = ref.watch(profileImageProvider);
    final userState = ref.watch(userProvider);

    void showBottomSheet() {
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
            padding: EdgeInsets.only(
              top: mq.height * 0.03,
              bottom: mq.height * 0.05,
            ),
            children: [
              const Text(
                'Pick Profile Picture',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: mq.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      fixedSize: Size(mq.width * 0.3, mq.height * 0.15),
                      shape: const CircleBorder(),
                    ),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? imageFile = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (imageFile != null) {
                        ref.read(profileImageProvider.notifier).state =
                            imageFile.path;
                        Navigator.pop(context);
                      }
                    },
                    child: Image.asset('images/gallery.png'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      fixedSize: Size(mq.width * 0.3, mq.height * 0.15),
                      shape: const CircleBorder(),
                    ),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? imageFile = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (imageFile != null) {
                        ref.read(profileImageProvider.notifier).state =
                            imageFile.path;
                        Navigator.pop(context);
                      }
                    },
                    child: Image.asset('images/camera.png'),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile Screen')),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'profile_logout_button',
          onPressed: () async {
            Dialogs.showProgressBar(context);
            await APIs.updateActiveStatus(false);
            await Supabase.instance.client.auth.signOut();
            await GoogleSignIn().signOut();
            Navigator.pop(context); // for progress dialog
            Navigator.pop(context); // for profile screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          backgroundColor: Colors.redAccent,
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
        body: Form(
          key: formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(width: mq.width, height: mq.height * 0.03),
                  Stack(
                    children: [
                      image != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              mq.height * 0.1,
                            ),
                            child: Image.file(
                              File(image),
                              width: mq.height * 0.2,
                              height: mq.height * 0.2,
                              fit: BoxFit.cover,
                            ),
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(
                              mq.height * 0.1,
                            ),
                            child: CachedNetworkImage(
                              width: mq.height * 0.2,
                              height: mq.height * 0.2,
                              fit: BoxFit.fill,
                              imageUrl: userState.image,
                              errorWidget:
                                  (context, url, error) => const CircleAvatar(
                                    child: Icon(CupertinoIcons.person),
                                  ),
                            ),
                          ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: showBottomSheet,
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(Icons.edit, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mq.height * 0.03),
                  Text(
                    userState.email,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  SizedBox(height: mq.height * 0.05),
                  TextFormField(
                    initialValue: userState.name,
                    onSaved:
                        (val) => ref
                            .read(userProvider.notifier)
                            .updateName(val ?? ''),
                    validator:
                        (val) =>
                            val != null && val.isNotEmpty
                                ? null
                                : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Ayush Ravi',
                      label: const Text('Name'),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.02),
                  TextFormField(
                    initialValue: userState.about,
                    onSaved:
                        (val) => ref
                            .read(userProvider.notifier)
                            .updateAbout(val ?? ''),
                    validator:
                        (val) =>
                            val != null && val.isNotEmpty
                                ? null
                                : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Feeling Happy',
                      label: const Text('About'),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.05),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        APIs.me = userState; // Update the static instance
                        APIs.updateUserInfo().then((value) {
                          Dialogs.showSnackbar(
                            context,
                            'Profile Updated Successfully!',
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
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
