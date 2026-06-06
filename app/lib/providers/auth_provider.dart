import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  int? _impersonatedByAdminId;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isImpersonating => _impersonatedByAdminId != null;
  
  bool get isSuperAdmin => _user?.isSuperAdmin ?? false;
  bool get isStoreOwner => _user?.isStoreOwner ?? false;
  bool get isVisitor => _user?.isVisitor ?? false;

  Future<void> init() async {
    await _api.init();
    if (_api.isAuthenticated) {
      await _loadCurrentUser();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _api.getCurrentUser();
      _user = User.fromJson(response);
      _error = null;
    } catch (e) {
      _user = null;
      _error = e.toString();
      await _api.setToken(null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _api.login(email, password);
      _user = User.fromJson(response['user']);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String role = 'visitor',
    String? pseudoname,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _api.register(
        username: username,
        email: email,
        password: password,
        role: role,
        pseudoname: pseudoname,
      );
      _user = User.fromJson(response['user']);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? username,
    String? pseudoname,
    String? profilePic,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (pseudoname != null) data['pseudoname'] = pseudoname;
      if (profilePic != null) data['profile_pic'] = profilePic;

      final response = await _api.put('/auth/profile', data);
      _user = User.fromJson(response['user'] ?? response);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    _impersonatedByAdminId = null;
    notifyListeners();
  }

  Future<bool> impersonate(int userId) async {
    if (!isSuperAdmin) return false;
    
    try {
      _isLoading = true;
      notifyListeners();

      final adminId = _user!.id;
      final response = await _api.impersonate(userId);
      _user = User.fromJson(response['user']);
      _impersonatedByAdminId = adminId;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> stopImpersonation() async {
    if (_impersonatedByAdminId == null) return false;
    
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _api.stopImpersonation(_impersonatedByAdminId!);
      _user = User.fromJson(response['user']);
      _impersonatedByAdminId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
