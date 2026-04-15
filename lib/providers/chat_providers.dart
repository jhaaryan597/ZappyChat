import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zappychat/models/chat_user.dart';
import 'package:zappychat/models/message.dart';
import '../api/apis.dart';

// ── Paginated messages state ───────────────────────────────────────────────

class MessagesState {
  final List<Message> messages;
  final bool hasMore;
  final bool isLoadingMore;

  const MessagesState({
    this.messages = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  MessagesState copyWith({
    List<Message>? messages,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      MessagesState(
        messages: messages ?? this.messages,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class MessagesNotifier
    extends StateNotifier<AsyncValue<MessagesState>> {
  static const int _pageSize = 50;

  MessagesNotifier(this._user) : super(const AsyncValue.loading()) {
    _init();
  }

  final ChatUser _user;
  StreamSubscription? _sub;

  // Single accumulator: id → Message. Grows as pages are loaded; stream updates
  // are merged in without discarding paginated messages.
  final Map<String, Message> _loaded = {};
  bool _hasMore = true;
  bool _isLoadingMore = false;

  void _init() {
    _sub = APIs.getAllMessages(_user, limit: _pageSize).listen(
      (rawData) {
        final streamData =
            rawData.map((e) => Message.fromJson(e)).toList();

        if (streamData.isNotEmpty) {
          // Messages inside the stream window that are no longer present
          // have been deleted — remove them from the accumulator.
          final oldestSent =
              int.tryParse(streamData.last.sent) ?? 0;
          final streamIds = streamData.map((m) => m.id).toSet();
          _loaded.removeWhere((id, m) {
            final inWindow =
                (int.tryParse(m.sent) ?? 0) >= oldestSent;
            return inWindow && !streamIds.contains(id);
          });
        }

        // Add or refresh all messages from the stream.
        for (final m in streamData) {
          _loaded[m.id] = m;
        }

        // If the stream returned a full page there may be more; otherwise we
        // already have everything recent (pagination may still have older ones).
        if (streamData.length < _pageSize) _hasMore = false;

        _rebuild();
      },
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    final current = state.asData?.value;
    if (current == null || current.messages.isEmpty) return;

    _isLoadingMore = true;
    _rebuild();

    try {
      final oldestSent = current.messages.last.sent;
      final older =
          await APIs.getOlderMessages(_user, oldestSent, _pageSize);
      for (final m in older) {
        _loaded[m.id] = m;
      }
      if (older.length < _pageSize) _hasMore = false;
    } catch (_) {
      // Silently reset — user can retry by tapping Load more again.
    } finally {
      _isLoadingMore = false;
      _rebuild();
    }
  }

  void _rebuild() {
    final sorted = _loaded.values.toList()
      ..sort((a, b) =>
          (int.tryParse(b.sent) ?? 0)
              .compareTo(int.tryParse(a.sent) ?? 0));
    state = AsyncValue.data(MessagesState(
      messages: sorted,
      hasMore: _hasMore,
      isLoadingMore: _isLoadingMore,
    ));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final messagesProvider = StateNotifierProvider.autoDispose
    .family<MessagesNotifier, AsyncValue<MessagesState>, ChatUser>(
  (ref, user) => MessagesNotifier(user),
);

// ── Other chat providers ───────────────────────────────────────────────────

final textControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final showEmojiProvider = StateProvider<bool>((ref) => false);

final userInfoProvider =
    StreamProvider.family<ChatUser, ChatUser>((ref, user) {
  return APIs.getUserInfo(user).map((data) {
    final list = data.map((e) => ChatUser.fromJson(e)).toList();
    return list.isNotEmpty ? list[0] : user;
  });
});
