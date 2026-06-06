import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// Helper for API requests
  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    debugPrint('SubscriptionService: Token from prefs: ${token != null ? "FOUND (${token.substring(0, 10)}...)" : "NULL"}');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (token != null) 'X-Authorization': 'Bearer $token',
    };
  }

  /// Get all available subscription plans
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/subscriptions/plans'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((p) => SubscriptionPlan.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting plans: $e');
      return [];
    }
  }

  /// Get current user's subscription
  Future<Subscription?> getMySubscription() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/subscriptions/my'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['subscription'] != null) {
          return Subscription.fromJson(data['subscription']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting subscription: $e');
      return null;
    }
  }

  /// Subscribe to a plan with optional payment proof image
  Future<Map<String, dynamic>> subscribe({
    required int planId,
    required String paymentMethod,
    XFile? paymentProofImage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/subscriptions/subscribe');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['X-Authorization'] = 'Bearer $token';
      }

      // Add fields
      request.fields['plan_id'] = planId.toString();
      request.fields['payment_method'] = paymentMethod;

      // Add payment proof image if provided
      if (paymentProofImage != null) {
        final bytes = await paymentProofImage.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'payment_proof',
          bytes,
          filename: paymentProofImage.name,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': data['message'] ?? 'Unknown error',
        'subscription': data['subscription'] != null
            ? Subscription.fromJson(data['subscription'])
            : null,
      };
    } catch (e) {
      debugPrint('Error subscribing: $e');
      return {
        'success': false,
        'message': 'Failed to subscribe: $e',
      };
    }
  }

  /// Upgrade to store owner
  Future<Map<String, dynamic>> upgradeToStoreOwner() async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/subscriptions/upgrade-to-store-owner'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': data['message'] ?? 'Unknown error',
        'user': data['user'],
      };
    } catch (e) {
      debugPrint('Error upgrading to store owner: $e');
      return {
        'success': false,
        'message': 'Failed to upgrade: $e',
      };
    }
  }

  /// Check subscription limits
  Future<Map<String, dynamic>?> checkLimits() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/subscriptions/limits'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking limits: $e');
      return null;
    }
  }

  // ========== ADMIN METHODS ==========

  /// Get all subscription requests (admin)
  Future<List<Subscription>> getAdminSubscriptions({String? status, String? paymentMethod}) async {
    try {
      final headers = await _headers;
      var url = '${AppConstants.apiBaseUrl}/admin/subscriptions';
      final params = <String>[];
      if (status != null) params.add('status=$status');
      if (paymentMethod != null) params.add('payment_method=$paymentMethod');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      debugPrint('Fetching admin subscriptions from: $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Handle both paginated and non-paginated responses
        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = data['data'] ?? [];
        } else {
          items = [];
        }
        debugPrint('Found ${items.length} subscriptions');
        return items.map((s) => Subscription.fromJson(s)).toList();
      }
      debugPrint('Failed with status code: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error getting admin subscriptions: $e');
      return [];
    }
  }

  /// Approve subscription (admin)
  Future<bool> approveSubscription(int id, {String? paymentMethod, String? notes}) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/subscriptions/$id/approve'),
        headers: headers,
        body: jsonEncode({
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (notes != null) 'admin_notes': notes,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error approving subscription: $e');
      return false;
    }
  }

  /// Reject subscription (admin)
  Future<bool> rejectSubscription(int id, String reason) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/subscriptions/$id/reject'),
        headers: headers,
        body: jsonEncode({'admin_notes': reason}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error rejecting subscription: $e');
      return false;
    }
  }

  /// Validate store (admin)
  Future<bool> validateStore(int storeId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/stores/$storeId/validate'),
        headers: headers,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error validating store: $e');
      return false;
    }
  }

  /// Invalidate store (admin)
  Future<bool> invalidateStore(int storeId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/admin/stores/$storeId/invalidate'),
        headers: headers,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error invalidating store: $e');
      return false;
    }
  }
}
