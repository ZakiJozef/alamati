import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/message.dart';

/// Service for store-specific chat operations
class StoreChatService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Get all conversations for a store
  Future<List<StoreConversation>> getStoreConversations(int storeId) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/stores/$storeId/chat/conversations'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StoreConversation.fromJson(json)).toList();
      } else {
        debugPrint('Failed to get store conversations: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting store conversations: $e');
      return [];
    }
  }

  /// Get messages with a customer
  Future<List<Message>> getStoreMessages(int storeId, int customerId, {int limit = 50, int? before}) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      String url = '${AppConstants.apiBaseUrl}/stores/$storeId/chat/messages/$customerId?limit=$limit';
      if (before != null) {
        url += '&before=$before';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        debugPrint('Failed to get store messages: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting store messages: $e');
      return [];
    }
  }

  /// Send a message as the store
  Future<Message?> sendStoreMessage({
    required int storeId,
    required int receiverId,
    required String content,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/stores/$storeId/chat/send'),
        headers: _headers(token),
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        return Message.fromJson(jsonDecode(response.body));
      } else {
        debugPrint('Failed to send store message: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error sending store message: $e');
      return null;
    }
  }

  /// Mark messages from a customer as read
  Future<bool> markStoreMessagesRead(int storeId, int customerId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/stores/$storeId/chat/mark-read/$customerId'),
        headers: _headers(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking store messages read: $e');
      return false;
    }
  }

  /// Get unread message count for a store
  Future<int> getStoreUnreadCount(int storeId) async {
    try {
      final token = await _getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/stores/$storeId/chat/unread-count'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting store unread count: $e');
      return 0;
    }
  }
}

