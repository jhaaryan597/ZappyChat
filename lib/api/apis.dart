import 'dart:developer';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zappychat/models/message.dart';
import 'package:mime/mime.dart';

import '../models/chat_user.dart';

class APIs {
  static SupabaseClient supabase = Supabase.instance.client;
  static const _uuid = Uuid();
  // for storing self info
  static late ChatUser me;
  // return currentUser
  static User get user => supabase.auth.currentUser!;

  // check karo user exist karta hai ya nhi
  static Future<bool> userExists() async {
    final data = await supabase.from('users').select('id').eq('id', user.id);
    return data.isNotEmpty;
  }

  // for getting current user info — returns the fetched user directly
  static Future<ChatUser> getSelfInfo() async {
    final data = await supabase.from('users').select().eq('id', user.id);
    if (data.isNotEmpty) {
      me = ChatUser.fromJson(data[0]);
      updateActiveStatus(true);
      log('My data: $data');
      return me;
    } else {
      await createUser();
      return getSelfInfo();
    }
  }

  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
      id: user.id,
      name: user.userMetadata?['name'] ?? 'ZappyChat User',
      email: user.email!,
      about: "Hey, I am using ZappyChat!",
      image: user.userMetadata?['picture'] ?? '',
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );
    await supabase.from('users').insert(chatUser.toJson());
  }

  // getting all users from firestore database
  static Stream<List<Map<String, dynamic>>> getAllUsers() {
    return supabase.from('users').stream(primaryKey: ['id']).neq('id', user.id);
  }

  // update user info (name + about)
  static Future<void> updateUserInfo() async {
    try {
      await supabase
          .from('users')
          .update({'name': me.name, 'about': me.about})
          .eq('id', me.id);
    } catch (e) {
      log('Error updating user info: $e');
      rethrow;
    }
  }

  // upload new profile picture and persist the URL
  static Future<void> updateProfileImage(File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final path = 'profile_images/${user.id}.$ext';
      await uploadFile(imageFile, path);
      // Use a long-lived signed URL for profile pictures (1 year)
      final url = await supabase.storage
          .from('chat-files')
          .createSignedUrl(path, 365 * 24 * 60 * 60);
      me.image = url;
      await supabase.from('users').update({'image': url}).eq('id', me.id);
    } catch (e) {
      log('Error updating profile image: $e');
      rethrow;
    }
  }

  // getting specific user info
  static Stream<List<Map<String, dynamic>>> getUserInfo(ChatUser chatUser) {
    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', chatUser.id);
  }

  static RealtimeChannel? channel;

  //update online or last active status
  static void updateActiveStatus(bool isOnline) {
    if (channel == null) {
      channel = supabase.channel(
        'online-users',
        opts: const RealtimeChannelConfig(self: true),
      );
      channel!.subscribe();
    }
    channel!.track({
      'online_at': isOnline ? DateTime.now().toIso8601String() : null,
    });
  }

  // getting conversation id
  static String getConversationID(String id) =>
      user.id.hashCode <= id.hashCode ? '${user.id}_$id' : '${id}_${user.id}';

  // chat screen related apis — streams the most recent [limit] messages
  static Stream<List<Map<String, dynamic>>> getAllMessages(
    ChatUser user, {
    int limit = 50,
  }) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', getConversationID(user.id))
        .order('sent', ascending: false)
        .limit(limit);
  }

  // fetch messages older than [beforeSent] (cursor-based pagination)
  static Future<List<Message>> getOlderMessages(
    ChatUser chatUser,
    String beforeSent,
    int limit,
  ) async {
    try {
      final data = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', getConversationID(chatUser.id))
          .lt('sent', beforeSent)
          .order('sent', ascending: false)
          .limit(limit);
      return data.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      log('Error fetching older messages: $e');
      rethrow;
    }
  }

  // for sending msg
  static Future<void> sendMessage(
    ChatUser chatUser,
    String msg, {
    Type type = Type.text,
  }) async {
    try {
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final Message message = Message(
        id: _uuid.v4(),
        msg: msg,
        read: '',
        told: chatUser.id,
        type: type,
        sent: time,
        fromId: user.id,
      );
      await supabase
          .from('messages')
          .insert(
            message.toJson()
              ..['conversation_id'] = getConversationID(chatUser.id),
          );
    } catch (e) {
      log('Error sending message: $e');
      rethrow;
    }
  }

  // update read msg status
  static Future<void> updateMessageReadStatus(Message message) async {
    try {
      await supabase
          .from('messages')
          .update({'read': DateTime.now().millisecondsSinceEpoch.toString()})
          .eq('id', message.id);
    } catch (e) {
      log('Error updating read status: $e');
    }
  }

  // get last msg of a specific chat
  static Stream<List<Map<String, dynamic>>> getLastMessage(ChatUser user) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', getConversationID(user.id))
        .order('sent', ascending: false)
        .limit(1);
  }

  //  delete msg
  static Future<void> deleteMessage(Message message) async {
    try {
      await supabase.from('messages').delete().eq('id', message.id);
    } catch (e) {
      log('Error deleting message: $e');
      rethrow;
    }
  }

  //  update msg
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    try {
      await supabase
          .from('messages')
          .update({'msg': updatedMsg})
          .eq('id', message.id);
    } catch (e) {
      log('Error updating message: $e');
      rethrow;
    }
  }

  static Future<String> uploadFile(File file, String path) async {
    try {
      final contentType = lookupMimeType(file.path);
      await supabase.storage
          .from('chat-files')
          .upload(
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
