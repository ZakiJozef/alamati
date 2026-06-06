import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../models/message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _token;
  int? _userId;
  String? _socketId;
  Timer? _pingTimer;

  // Stream controllers for real-time events
  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _messagesReadController = StreamController<int>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<int> get messagesReadStream => _messagesReadController.stream;
  bool get isConnected => _isConnected;

  /// Connect to Laravel Reverb WebSocket server
  Future<void> connect(String token, int userId) async {
    if (_isConnected) {
      debugPrint('Reverb already connected');
      return;
    }

    _token = token;
    _userId = userId;

    try {
      final wsUri = Uri.parse(AppConstants.reverbWsUrl);
      debugPrint('🔌 Connecting to Reverb: $wsUri');
      
      _channel = WebSocketChannel.connect(wsUri);
      
      _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (error) {
          debugPrint('❌ Reverb error: $error');
          _handleDisconnect();
        },
      );

      // Start ping timer to keep connection alive
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _sendPing();
      });

    } catch (e) {
      debugPrint('❌ Failed to connect to Reverb: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String);
      debugPrint('📩 Reverb message: $message');

      final event = message['event'] as String?;
      final messageData = message['data'];

      switch (event) {
        case 'pusher:connection_established':
          _handleConnectionEstablished(messageData);
          break;
        case 'pusher_internal:subscription_succeeded':
          debugPrint('✅ Subscribed to channel');
          break;
        case 'message.sent':
          _handleNewMessage(messageData);
          break;
        case 'messages.read':
          _handleMessagesRead(messageData);
          break;
        case 'typing.start':
          _handleTyping(messageData, true);
          break;
        case 'typing.stop':
          _handleTyping(messageData, false);
          break;
        case 'pusher:error':
          debugPrint('❌ Pusher error: $messageData');
          break;
      }
    } catch (e) {
      debugPrint('Error parsing Reverb message: $e');
    }
  }

  void _handleConnectionEstablished(dynamic data) {
    try {
      final parsedData = data is String ? jsonDecode(data) : data;
      _socketId = parsedData['socket_id'];
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('✅ Reverb connected, socket_id: $_socketId');

      // Subscribe to private chat channel
      if (_userId != null) {
        _subscribeToPrivateChannel('chat.$_userId');
      }
    } catch (e) {
      debugPrint('Error handling connection: $e');
    }
  }

  Future<void> _subscribeToPrivateChannel(String channelName) async {
    if (_socketId == null || _token == null) {
      debugPrint('Cannot subscribe: missing socket_id or token');
      return;
    }

    try {
      // Get channel auth from Laravel
      final authResponse = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/broadcasting/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'socket_id': _socketId,
          'channel_name': 'private-$channelName',
        }),
      );

      if (authResponse.statusCode == 200) {
        final authData = jsonDecode(authResponse.body);
        
        // Subscribe to the private channel
        _sendToChannel({
          'event': 'pusher:subscribe',
          'data': {
            'channel': 'private-$channelName',
            'auth': authData['auth'],
          },
        });
        
        debugPrint('📡 Subscribing to private-$channelName');
      } else {
        debugPrint('❌ Auth failed: ${authResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error subscribing to channel: $e');
    }
  }

  void _handleNewMessage(dynamic data) {
    try {
      final parsedData = data is String ? jsonDecode(data) : data;
      final message = Message.fromJson(parsedData);
      _messageController.add(message);
      debugPrint('📩 New message from ${message.senderId}');
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _handleMessagesRead(dynamic data) {
    try {
      final parsedData = data is String ? jsonDecode(data) : data;
      final readBy = parsedData['read_by'] as int;
      _messagesReadController.add(readBy);
      debugPrint('👁️ Messages read by $readBy');
    } catch (e) {
      debugPrint('Error parsing messages read: $e');
    }
  }

  void _handleTyping(dynamic data, bool isTyping) {
    try {
      final parsedData = data is String ? jsonDecode(data) : data;
      _typingController.add({
        'typing': isTyping,
        'userId': parsedData['user_id'],
        'username': parsedData['username'],
      });
    } catch (e) {
      debugPrint('Error parsing typing: $e');
    }
  }

  void _handleDisconnect() {
    debugPrint('❌ Reverb disconnected');
    _isConnected = false;
    _socketId = null;
    _pingTimer?.cancel();
    _connectionController.add(false);
  }

  void _sendToChannel(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _sendPing() {
    if (_isConnected) {
      _sendToChannel({'event': 'pusher:ping', 'data': {}});
    }
  }

  /// Disconnect from Reverb
  void disconnect() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _socketId = null;
    _connectionController.add(false);
  }

  // REST API methods - Using Laravel API

  /// Helper for API requests
  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get conversations via REST
  Future<List<Conversation>> getConversations() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/chat/conversations'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((c) => Conversation.fromJson(c)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      return [];
    }
  }

  /// Get messages via REST
  Future<List<Message>> getMessages(int otherUserId, {int limit = 50, int? before}) async {
    try {
      String endpoint = '${AppConstants.apiBaseUrl}/chat/messages/$otherUserId?limit=$limit';
      if (before != null) {
        endpoint += '&before=$before';
      }
      final headers = await _headers;
      final response = await http.get(Uri.parse(endpoint), headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((m) => Message.fromJson(m)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  /// Send message via REST (broadcasts automatically via Laravel)
  Future<Message?> sendMessage({
    required int receiverId,
    required String content,
    int? storeId,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/chat/messages'),
        headers: headers,
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': content,
          'store_id': storeId,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Message.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  /// Mark messages as read via REST
  Future<void> markMessagesAsRead(int otherUserId) async {
    try {
      final headers = await _headers;
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/chat/mark-read/$otherUserId'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Send typing indicator via REST
  Future<void> sendTypingIndicator(int receiverId, bool isTyping) async {
    try {
      final headers = await _headers;
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/chat/typing'),
        headers: headers,
        body: jsonEncode({
          'receiver_id': receiverId,
          'is_typing': isTyping,
        }),
      );
    } catch (e) {
      debugPrint('Error sending typing indicator: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/chat/unread-count'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['unread'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
    _messagesReadController.close();
  }
}
