import 'dart:developer';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zappychat/models/message.dart';
import 'package:mime/mime.dart';

import '../models/chat_user.dart';

class APIs {
  static SupabaseClient supabase = Supabase.instance.client;
  // for storing self info
  static late ChatUser me;
  // return currentUser
  static User get user => supabase.auth.currentUser!;

  // check karo user exist karta hai ya nhi
  static Future<bool> userExists() async {
    final data = await supabase.from('users').select('id').eq('id', user.id);
    return data.isNotEmpty;
  }

  // for getting current user info
  static Future<void> getSelfInfo() async {
    final data = await supabase.from('users').select().eq('id', user.id);
    if (data.isNotEmpty) {
      me = ChatUser.fromJson(data[0]);
      await updateActiveStatus(true);
      log('My data: $data');
    } else {
      await createUser().then((value) => getSelfInfo());
    }
  }

  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
      id: user.id,
      name: user.userMetadata!['name'],
      email: user.email!,
      about: "Hey, I am using ZappyChat!",
      image: user.userMetadata!['picture'],
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );
    await supabase.from('users').insert(chatUser.toJson());
  }

  // getting all users from firestore database
  static Stream<List<Map<String, dynamic>>> getAllUsers() {
    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .neq('id', user.id);
  }

  // update user info
  static Future<void> updateUserInfo() async {
    await supabase
        .from('users')
        .update({'name': me.name, 'about': me.about}).eq('id', me.id);
  }

  // getting specific user info
  static Stream<List<Map<String, dynamic>>> getUserInfo(ChatUser chatUser) {
    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', chatUser.id);
  }

  //update online or last active status
  static Future<void> updateActiveStatus(bool isOnline) async {
    await supabase.from('users').update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken
    }).eq('id', user.id);
  }

  // getting conversation id
  static String getConversationID(String id) =>
      user.id.hashCode <= id.hashCode ? '${user.id}_$id' : '${id}_${user.id}';
  // chats (collection) --> conversation_id (doc) --> messages (collection) --> messages (doc)

  // chat screen related apis
  static Stream<List<Map<String, dynamic>>> getAllMessages(ChatUser user) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['sent'])
        .eq('conversation_id', getConversationID(user.id))
        .order('sent', ascending: false);
  }

  // for sending msg
  static Future<void> sendMessage(ChatUser chatUser, String msg, {Type type = Type.text}) async {
    // msg sending time used as id
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // msg to send
    final Message message = Message(
      msg: msg,
      read: '',
      told: chatUser.id,
      type: type,
      sent: time,
      fromId: user.id,
    );

    await supabase
        .from('messages')
        .insert(message.toJson()..['conversation_id'] = getConversationID(chatUser.id));
  }

  // update read msg status
  static Future<void> updateMessageReadStatus(Message message) async {
    await supabase
        .from('messages')
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()})
        .eq('sent', message.sent);
  }

  // get all msg of a specific chat
  static Stream<List<Map<String, dynamic>>> getLastMessage(ChatUser user) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['sent'])
        .eq('conversation_id', getConversationID(user.id))
        .order('sent', ascending: false)
        .limit(1);
  }

  //  delete msg
  static Future<void> deleteMessage(Message message) async {
    await supabase.from('messages').delete().eq('sent', message.sent);
  }

  //  update msg
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await supabase
        .from('messages')
        .update({'msg': updatedMsg})
        .eq('sent', message.sent);
  }

  static Future<String> uploadFile(File file, String path) async {
    try {
      final contentType = lookupMimeType(file.path);
      await supabase.storage.from('chat-files').upload(
            path,
            file,
            fileOptions: FileOptions(contentType: contentType),
          );
      return path;
    } catch (e) {
      log('Error uploading file: $e');
      rethrow;
    }
  }

  static Future<String> createSignedUrl(String path) async {
    try {
      final signedUrl = await supabase.storage
          .from('chat-files')
          .createSignedUrl(path, 60);
      return signedUrl;
    } catch (e) {
      log('Error creating signed url: $e');
      rethrow;
    }
  }
}
