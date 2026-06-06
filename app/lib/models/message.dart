class Message {
  final int id;
  final int senderId;
  final int? receiverId;
  final int? storeId;
  final String content;
  final bool isRead;
  final bool senderAsStore;
  final DateTime? createdAt;
  final String? senderUsername;
  final String? senderProfilePic;
  final String? displayName;
  final String? displayImage;

  Message({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.storeId,
    required this.content,
    this.isRead = false,
    this.senderAsStore = false,
    this.createdAt,
    this.senderUsername,
    this.senderProfilePic,
    this.displayName,
    this.displayImage,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int? ?? 0,
      senderId: json['sender_id'] as int? ?? 0,
      receiverId: json['receiver_id'] as int?,
      storeId: json['store_id'] as int?,
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      senderAsStore: json['sender_as_store'] == 1 || json['sender_as_store'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      senderUsername: json['sender_username'] as String?,
      senderProfilePic: json['sender_profile_pic'] as String?,
      displayName: json['display_name'] as String?,
      displayImage: json['display_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'store_id': storeId,
      'content': content,
      'is_read': isRead,
      'sender_as_store': senderAsStore,
    };
  }

  /// Get the name to display for this message
  String get effectiveDisplayName => displayName ?? senderUsername ?? 'User';
  
  /// Get the image to display for this message
  String? get effectiveDisplayImage => displayImage ?? senderProfilePic;
}

class Conversation {
  final int id;
  final int user1Id;
  final int user2Id;
  final int? storeId;
  final int? lastMessageId;
  final DateTime? updatedAt;
  final int otherUserId;
  final String? otherUsername;
  final String? otherProfilePic;
  final String? otherPseudoname;
  final String? storeName;
  final String? storeImage;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.storeId,
    this.lastMessageId,
    this.updatedAt,
    required this.otherUserId,
    this.otherUsername,
    this.otherProfilePic,
    this.otherPseudoname,
    this.storeName,
    this.storeImage,
    this.lastMessageContent,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int? ?? 0,
      user1Id: json['user1_id'] as int? ?? 0,
      user2Id: json['user2_id'] as int? ?? 0,
      storeId: json['store_id'] as int?,
      lastMessageId: json['last_message_id'] as int?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      otherUserId: json['other_user_id'] as int? ?? 0,
      otherUsername: json['other_username'] as String?,
      otherProfilePic: json['other_profile_pic'] as String?,
      otherPseudoname: json['other_pseudoname'] as String?,
      storeName: json['store_name'] as String?,
      storeImage: json['store_image'] as String?,
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.parse(json['last_message_time']) 
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  String get displayName => otherPseudoname ?? otherUsername ?? 'User';

  bool get hasUnread => unreadCount > 0;
}

/// Conversation for store inbox (customer-focused)
class StoreConversation {
  final int id;
  final int customerId;
  final String? customerUsername;
  final String? customerProfilePic;
  final String? customerPseudoname;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final bool lastMessageSenderAsStore;
  final int unreadCount;
  final DateTime? updatedAt;

  StoreConversation({
    required this.id,
    required this.customerId,
    this.customerUsername,
    this.customerProfilePic,
    this.customerPseudoname,
    this.lastMessageContent,
    this.lastMessageTime,
    this.lastMessageSenderAsStore = false,
    this.unreadCount = 0,
    this.updatedAt,
  });

  factory StoreConversation.fromJson(Map<String, dynamic> json) {
    return StoreConversation(
      id: json['id'] as int? ?? 0,
      customerId: json['customer_id'] as int? ?? 0,
      customerUsername: json['customer_username'] as String?,
      customerProfilePic: json['customer_profile_pic'] as String?,
      customerPseudoname: json['customer_pseudoname'] as String?,
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.parse(json['last_message_time']) 
          : null,
      lastMessageSenderAsStore: json['last_message_sender_as_store'] == true,
      unreadCount: json['unread_count'] as int? ?? 0,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  String get displayName => customerPseudoname ?? customerUsername ?? 'Customer';

  bool get hasUnread => unreadCount > 0;
}

