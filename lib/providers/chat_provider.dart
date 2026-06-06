import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isConnected = false;
  int _unreadCount = 0;
  int? _currentChatUserId;
  int? _currentUserId;
  Map<int, bool> _typingUsers = {};

  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _messagesReadSubscription;

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  int get unreadCount => _unreadCount;
  int? get currentChatUserId => _currentChatUserId;
  Map<int, bool> get typingUsers => _typingUsers;

  bool isUserTyping(int userId) => _typingUsers[userId] == true;
  
  // Online status is not tracked in real-time with Reverb, always return false
  bool isUserOnline(int userId) => false;

  /// Initialize chat and connect to Reverb
  Future<void> initialize(String token, int userId) async {
    _currentUserId = userId;
    await _chatService.connect(token, userId);
    _setupListeners();
    loadConversations();
    loadUnreadCount();
  }

  void _setupListeners() {
    // Listen for connection status
    _connectionSubscription = _chatService.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    // Listen for new messages
    _messageSubscription = _chatService.messageStream.listen((message) {
      _handleNewMessage(message);
    });

    // Listen for typing indicators
    _typingSubscription = _chatService.typingStream.listen((data) {
      final userId = data['userId'] as int?;
      final isTyping = data['typing'] as bool? ?? false;
      if (userId != null) {
        _typingUsers[userId] = isTyping;
        notifyListeners();
      }
    });

    // Listen for messages read
    _messagesReadSubscription = _chatService.messagesReadStream.listen((readBy) {
      // Mark messages as read in local state
      for (var message in _messages) {
        if (message.receiverId == readBy) {
          // Message was read by the other user
        }
      }
      notifyListeners();
    });
  }

  void _handleNewMessage(Message message) {
    // Add to messages if in current chat
    if (_currentChatUserId != null) {
      if (message.senderId == _currentChatUserId || 
          message.receiverId == _currentChatUserId) {
        // Check if message already exists
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
          notifyListeners();
        }
      }
    }

    // Update conversations list
    _updateConversationWithMessage(message);
    
    // Update unread count if message is from someone else
    if (message.receiverId != null && message.senderId != _currentChatUserId) {
      loadUnreadCount();
    }
  }

  void _updateConversationWithMessage(Message message) {
    // Find and update the conversation
    final index = _conversations.indexWhere((c) => 
      c.otherUserId == message.senderId || c.otherUserId == message.receiverId
    );
    
    if (index != -1) {
      // Move to top and update last message
      loadConversations();
    }
  }

  /// Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a specific user
  Future<void> loadMessages(int otherUserId) async {
    _currentChatUserId = otherUserId;
    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _chatService.getMessages(otherUserId);
      await _chatService.markMessagesAsRead(otherUserId);
      loadUnreadCount();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (_currentChatUserId == null || _messages.isEmpty) return;

    try {
      final oldestMessageId = _messages.first.id;
      final olderMessages = await _chatService.getMessages(
        _currentChatUserId!,
        before: oldestMessageId,
      );
      _messages.insertAll(0, olderMessages);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required int receiverId,
    required String content,
    int? storeId,
  }) async {
    if (content.trim().isEmpty) return;

    // Use REST API (which broadcasts via Laravel Events)
    final message = await _chatService.sendMessage(
      receiverId: receiverId,
      content: content,
      storeId: storeId,
    );
    
    if (message != null) {
      // Add message to local state immediately
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        notifyListeners();
      }
    }
  }

  /// Start typing indicator
  void startTyping(int receiverId) {
    _chatService.sendTypingIndicator(receiverId, true);
  }

  /// Stop typing indicator
  void stopTyping(int receiverId) {
    _chatService.sendTypingIndicator(receiverId, false);
  }

  /// Mark messages as read
  Future<void> markAsRead(int senderId) async {
    await _chatService.markMessagesAsRead(senderId);
    loadUnreadCount();
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _chatService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  /// Clear current chat
  void clearCurrentChat() {
    _currentChatUserId = null;
    _messages = [];
    notifyListeners();
  }

  /// Disconnect from chat
  void disconnect() {
    _chatService.disconnect();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();
    _messagesReadSubscription?.cancel();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
