class ChatUser {
  ChatUser({
    required this.image,
    required this.name,
    required this.about,
    required this.createdAt,
    required this.lastActive,
    required this.isOnline,
    required this.id,
    required this.email,
    required this.pushToken,
  });
  late String image;
  late String name;
  late String about;
  late String createdAt;
  late String lastActive;
  late bool isOnline;
  late String id;
  late String email;
  late String pushToken;

  ChatUser.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? '';
    name = json['name'] ?? '';
    email = json['email'] ?? '';
    about = json['about'] ?? '';
    image = json['image'] ?? '';
    createdAt = json['created_at'] ?? '';
    isOnline = json['online_at'] != null;
    lastActive = json['online_at'] ?? '';
    pushToken = json['push_token'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['image'] = image;
    data['name'] = name;
    data['about'] = about;
    data['created_at'] = createdAt;
    data['last_active'] = lastActive;
    data['is_online'] = isOnline;
    data['id'] = id;
    data['email'] = email;
    data['push_token'] = pushToken;
    return data;
  }

  ChatUser copyWith({
    String? image,
    String? name,
    String? about,
    String? createdAt,
    String? lastActive,
    bool? isOnline,
    String? id,
    String? email,
    String? pushToken,
  }) {
    return ChatUser(
      image: image ?? this.image,
      name: name ?? this.name,
      about: about ?? this.about,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
      id: id ?? this.id,
      email: email ?? this.email,
      pushToken: pushToken ?? this.pushToken,
    );
  }
}
