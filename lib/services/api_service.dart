import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Send token via both headers - X-Authorization works on shared hosting
    // that strips the standard Authorization header
    if (_token != null) 'Authorization': 'Bearer $_token',
    if (_token != null) 'X-Authorization': 'Bearer $_token',
  };

  Uri _uri(String endpoint) => Uri.parse('${AppConstants.apiBaseUrl}$endpoint');

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: body['error'] ?? 'An error occurred',
      );
    }
  }


  // GET request
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(_uri(endpoint), headers: _headers);
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: body['error'] ?? 'An error occurred',
      );
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      _uri(endpoint),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(endpoint),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(_uri(endpoint), headers: _headers);
    return _handleResponse(response);
  }

  // File Upload (multipart) - accepts bytes for cross-platform support
  Future<Map<String, dynamic>> uploadFile(String endpoint, List<int> bytes, String filename) async {
    final request = http.MultipartRequest('POST', _uri(endpoint));
    
    // Add auth headers
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['X-Authorization'] = 'Bearer $_token';
    }
    request.headers['Accept'] = 'application/json';
    
    // Use fromBytes which works on both web and mobile
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post('/auth/login', {
      'email': email,
      'password': password,
    });
    if (response['token'] != null) {
      await setToken(response['token']);
    }
    return response;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String role = 'visitor',
    String? pseudoname,
  }) async {
    final response = await post('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'pseudoname': pseudoname,
    });
    if (response['token'] != null) {
      await setToken(response['token']);
    }
    return response;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await get('/auth/me');
  }

  Future<void> logout() async {
    await setToken(null);
  }

  Future<Map<String, dynamic>> impersonate(int userId) async {
    final response = await post('/auth/impersonate/$userId', {});
    if (response['token'] != null) {
      await setToken(response['token']);
    }
    return response;
  }

  Future<Map<String, dynamic>> stopImpersonation(int adminId) async {
    final response = await post('/auth/stop-impersonation', {
      'adminId': adminId,
    });
    if (response['token'] != null) {
      await setToken(response['token']);
    }
    return response;
  }

  // Admin: User Management
  Future<Map<String, dynamic>> getUsers({String? role, String? search, int page = 1}) async {
    String endpoint = '/users?page=$page';
    if (role != null) endpoint += '&role=$role';
    if (search != null && search.isNotEmpty) endpoint += '&search=$search';
    return await get(endpoint);
  }

  Future<Map<String, dynamic>> getUser(int userId) async {
    return await get('/users/$userId');
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
    required String role,
    String? pseudoname,
  }) async {
    return await post('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'pseudoname': pseudoname,
    });
  }

  Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    return await put('/users/$userId/role', {'role': role});
  }

  Future<Map<String, dynamic>> deleteUser(int userId) async {
    return await delete('/users/$userId');
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    return await get('/users/admin/stats');
  }

  // Employee Management (for store owners)
  Future<dynamic> getEmployees() async {
    return await get('/employees');
  }

  Future<Map<String, dynamic>> createEmployee({
    required String email,
    required String password,
    String? username,
    String? title,
    required List<String> permissions,
    required List<int> storeIds,
  }) async {
    return await post('/employees', {
      'email': email,
      'password': password,
      'username': username,
      'title': title,
      'permissions': permissions,
      'store_ids': storeIds,
    });
  }

  Future<Map<String, dynamic>> updateEmployee({
    required int employeeId,
    String? title,
    required List<String> permissions,
    required List<int> storeIds,
  }) async {
    return await put('/employees/$employeeId', {
      'title': title,
      'permissions': permissions,
      'store_ids': storeIds,
    });
  }

  Future<Map<String, dynamic>> deleteEmployee(int employeeId) async {
    return await delete('/employees/$employeeId');
  }

  Future<dynamic> getEmployeePermissions() async {
    return await get('/employees/permissions');
  }

  Future<dynamic> getMyStoreAccess() async {
    return await get('/employees/my-stores');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
