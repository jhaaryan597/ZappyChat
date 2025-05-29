import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zappychat/helper/dialogs.dart';
import 'package:zappychat/screens/auth/login_screen.dart';
import '../api/apis.dart';
import '../main.dart';
import '../models/chat_user.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

// profile screen
class _ProfileScreen extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

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
        appBar: AppBar(title: const Text('Profile Screen')),
        // niche wala button
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: FloatingActionButton.extended(
            onPressed: () async {
              //show progress dialog
              Dialogs.showProgressBar(context);

              await APIs.updateActiveStatus(false);

              // sign out from app
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  // hide progress dialog
                  Navigator.pop(context);
                  // move from home screen
                  Navigator.pop(context);

                  APIs.auth = FirebaseAuth.instance;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                });
              });
            },
            backgroundColor: Colors.redAccent,
            icon: Icon(Icons.logout, color: Colors.white),
            label: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ),
        // chat card
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // add some space
                  SizedBox(width: mq.width, height: mq.height * 0.03),
                  // user profile picture
                  Stack(
                    children: [
                      // local image
                      _image != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              mq.height * 0.1,
                            ),
                            child: Image.file(
                              File(_image!),
                              width: mq.height * 0.2,
                              height: mq.height * 0.2,
                              fit: BoxFit.cover,
                            ),
                          )
                          :
                          // image from server
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              mq.height * 0.1,
                            ),
                            child: CachedNetworkImage(
                              width: mq.height * 0.2,
                              height: mq.height * 0.2,
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
                                    child: Icon(
                                      CupertinoIcons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),

                      //edit image button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: () {
                            _showBottomSheet();
                          },
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: Icon(Icons.edit, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  // add some space
                  SizedBox(height: mq.height * 0.03),
                  Text(
                    widget.user.email,
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  // add some space
                  SizedBox(height: mq.height * 0.05),
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator:
                        (val) =>
                            val != null && val.isNotEmpty
                                ? null
                                : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Ayush Ravi',
                      label: Text('Name'),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.02),
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator:
                        (val) =>
                            val != null && val.isNotEmpty
                                ? null
                                : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.info_outline, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'eg. Feeling Happy',
                      label: Text('About'),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.05),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        log('Saving Name: ${APIs.me.name}');
                        log('Saving About: ${APIs.me.about}');

                        APIs.updateUserInfo()
                            .then((value) {
                              log('Update complete');
                              Dialogs.showSnackbar(
                                context,
                                'Profile Updated Successfully!',
                              );
                            })
                            .catchError((e) {
                              log('Update failed: $e');
                            });
                      }
                    },
                    icon: Icon(Icons.edit),
                    label: Text('UPDATE', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // bottom sheet for selecting profile picture
  void _showBottomSheet() {
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
              // Profile pick kar bhai
              'Pick Profile Picture ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            // Adding some space
            SizedBox(height: mq.height * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // gallary se kar le pick
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: Size(mq.width * 0.3, mq.height * 0.15),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    // pick an image
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      log(
                        'Image Path: ${image.path} -- MimeType: ${image.mimeType}',
                      );
                      setState(() {
                        _image = image.path;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/gallery.png'),
                ),
                // Ek photo khich le bhai  
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: Size(mq.width * 0.3, mq.height * 0.15),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    // pick an image
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      log(
                        'Image Path: ${image.path}',
                      );
                      setState(() {
                        _image = image.path;
                      });
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
}
