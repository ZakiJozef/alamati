import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<User> _users = [];
  String? _selectedRole;
  String _searchQuery = '';
  int _currentPage = 1;
  int _lastPage = 1;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _users = [];
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.getUsers(
        role: _selectedRole,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: _currentPage,
      );
      
      final List<dynamic> data = response['data'] ?? [];
      final users = data.map((json) => User.fromJson(json)).toList();
      
      setState(() {
        _users = users;
        _lastPage = response['last_page'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(User user, String newRole) async {
    try {
      await _api.updateUserRole(user.id, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName} role updated to ${_getRoleLabel(newRole)}')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteUser(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName} deleted')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _impersonateUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.swap_horiz, color: Colors.orange.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Login As User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to login as:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                      style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will see the app as this user. Use "Exit Impersonation" to return.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Login As'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.impersonate(user.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now logged in as ${user.displayName}'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      // Navigate to main shell to show the impersonated view
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to impersonate: ${authProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    String username = '';
    String email = '';
    String password = '';
    String role = 'visitor';
    String? pseudoname;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  onSaved: (v) => username = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  onSaved: (v) => email = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                  onSaved: (v) => password = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Display Name (optional)'),
                  onSaved: (v) => pseudoname = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'visitor', child: Text('Customer')),
                    DropdownMenuItem(value: 'store_owner', child: Text('Store Owner')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                  ],
                  onChanged: (v) => role = v ?? 'visitor',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                formKey.currentState?.save();
                Navigator.pop(context);
                try {
                  await _api.createUser(
                    username: username,
                    email: email,
                    password: password,
                    role: role,
                    pseudoname: pseudoname,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User created successfully')),
                  );
                  _loadUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'store_owner':
        return 'Store Owner';
      default:
        return 'Customer';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'store_owner':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showCreateUserDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadUsers(refresh: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      setState(() => _searchQuery = value);
                      _loadUsers(refresh: true);
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(null, 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('super_admin', 'Admins'),
                      const SizedBox(width: 8),
                      _buildFilterChip('store_owner', 'Store Owners'),
                      const SizedBox(width: 8),
                      _buildFilterChip('visitor', 'Customers'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadUsers(refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _users.length,
                              itemBuilder: (context, index) => _buildUserCard(_users[index]),
                            ),
                          ),
          ),

          // Pagination
          if (!_isLoading && _users.isNotEmpty && _lastPage > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage = 1);
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.first_page),
                  ),
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_currentPage of $_lastPage'),
                  IconButton(
                    onPressed: _currentPage < _lastPage
                        ? () {
                            setState(() => _currentPage++);
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    onPressed: _currentPage < _lastPage
                        ? () {
                            setState(() => _currentPage = _lastPage);
                            _loadUsers();
                          }
                        : null,
                    icon: const Icon(Icons.last_page),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? role, String label) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedRole = selected ? role : null);
        _loadUsers(refresh: true);
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
          backgroundImage: user.profilePic != null
              ? CachedNetworkImageProvider(user.profilePic!)
              : null,
          child: user.profilePic == null
              ? Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleLabel(user.role),
                style: TextStyle(
                  fontSize: 11,
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') {
              _deleteUser(user);
            } else if (value == 'impersonate') {
              _impersonateUser(user);
            } else {
              _updateUserRole(user, value);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'impersonate',
              child: Row(
                children: [
                  Icon(Icons.login, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Text('Login As'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'visitor', child: Text('Make Customer')),
            const PopupMenuItem(value: 'store_owner', child: Text('Make Store Owner')),
            const PopupMenuItem(value: 'super_admin', child: Text('Make Admin')),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete User', style: TextStyle(color: Colors.red.shade700)),
            ),
          ],
        ),
      ),
    );
  }
}
