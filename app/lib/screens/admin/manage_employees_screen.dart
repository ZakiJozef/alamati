import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../models/store.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final ApiService _api = ApiService();
  
  bool _isLoading = true;
  List<dynamic> _employees = [];
  List<Store> _myStores = [];
  Map<String, dynamic> _availablePermissions = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load employees, stores, and available permissions in parallel
      final results = await Future.wait([
        _api.getEmployees(),
        _api.getEmployeePermissions(),
        _api.get('/my-stores'),
      ]);
      
      // Parse stores from API response
      final storesData = results[2] is List ? results[2] as List : [];
      final stores = storesData.map((json) => Store.fromJson(json)).toList();
      
      setState(() {
        _employees = results[0] is List ? results[0] : [];
        _availablePermissions = results[1] is Map ? Map<String, dynamic>.from(results[1]) : {};
        _myStores = stores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  void _showAddEmployeeDialog() {
    if (_myStores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least one store to add employees')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddEmployeeDialog(
        stores: _myStores,
        availablePermissions: _availablePermissions,
        onSave: (email, password, title, permissions, storeIds) async {
          try {
            await _api.createEmployee(
              email: email,
              password: password,
              title: title,
              permissions: permissions,
              storeIds: storeIds,
            );
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Employee created successfully')),
              );
              _loadData();
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showEditEmployeeDialog(Map<String, dynamic> employeeData) {
    final user = employeeData['user'];
    final stores = employeeData['stores'] as List;
    final currentPermissions = stores.isNotEmpty 
        ? List<String>.from(stores.first['permissions'] ?? [])
        : <String>[];
    final currentStoreIds = stores.map<int>((s) => s['store_id'] as int).toList();
    final currentTitle = stores.isNotEmpty ? stores.first['title'] as String? : null;

    showDialog(
      context: context,
      builder: (context) => _EditEmployeeDialog(
        userName: user['pseudoname'] ?? user['username'] ?? user['email'],
        userEmail: user['email'],
        stores: _myStores,
        availablePermissions: _availablePermissions,
        initialPermissions: currentPermissions,
        initialStoreIds: currentStoreIds,
        initialTitle: currentTitle,
        onSave: (title, permissions, storeIds) async {
          try {
            await _api.updateEmployee(
              employeeId: user['id'],
              title: title,
              permissions: permissions,
              storeIds: storeIds,
            );
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Employee updated successfully')),
              );
              _loadData();
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteEmployee(Map<String, dynamic> employeeData) async {
    final user = employeeData['user'];
    final userName = user['pseudoname'] ?? user['username'] ?? user['email'];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Employee'),
        content: Text('Are you sure you want to remove $userName from all your stores?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteEmployee(user['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName removed')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Employees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddEmployeeDialog,
          ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _employees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No employees yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add employees to help manage your stores',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _showAddEmployeeDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Employee'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final employeeData = _employees[index] as Map<String, dynamic>;
                          return _buildEmployeeCard(employeeData);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employeeData) {
    final user = employeeData['user'] as Map<String, dynamic>;
    final stores = employeeData['stores'] as List;
    final storeNames = stores.map((s) => s['store_name']).join(', ');
    final title = stores.isNotEmpty ? stores.first['title'] : null;
    final permissions = stores.isNotEmpty 
        ? (stores.first['permissions'] as List?)?.length ?? 0
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          backgroundImage: user['profile_pic'] != null
              ? CachedNetworkImageProvider(user['profile_pic'])
              : null,
          child: user['profile_pic'] == null
              ? Text(
                  (user['pseudoname'] ?? user['username'] ?? 'E')[0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['pseudoname'] ?? user['username'] ?? user['email'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (title != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user['email'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.store, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    storeNames,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.security, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '$permissions permissions',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditEmployeeDialog(employeeData);
            } else if (value == 'delete') {
              _deleteEmployee(employeeData);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Permissions')),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Text('Remove Employee', style: TextStyle(color: Colors.red.shade700)),
            ),
          ],
        ),
      ),
    );
  }
}

// Add Employee Dialog
class _AddEmployeeDialog extends StatefulWidget {
  final List<Store> stores;
  final Map<String, dynamic> availablePermissions;
  final Future<void> Function(String email, String password, String? title, List<String> permissions, List<int> storeIds) onSave;

  const _AddEmployeeDialog({
    required this.stores,
    required this.availablePermissions,
    required this.onSave,
  });

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _titleController = TextEditingController();
  
  Set<int> _selectedStoreIds = {};
  Set<String> _selectedPermissions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-select first store
    if (widget.stores.isNotEmpty) {
      _selectedStoreIds.add(widget.stores.first.id);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Employee'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (!v!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Title (optional)',
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'e.g., Manager, Assistant',
                  ),
                ),
                const SizedBox(height: 24),
                
                // Store Selection
                const Text('Store Access *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.stores.map((store) {
                    final isSelected = _selectedStoreIds.contains(store.id);
                    return FilterChip(
                      label: Text(store.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStoreIds.add(store.id);
                          } else {
                            _selectedStoreIds.remove(store.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Permissions
                const Text('Permissions *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...widget.availablePermissions.entries.map((entry) {
                  final group = entry.key;
                  final perms = entry.value as List;
                  return ExpansionTile(
                    title: Text(group.toUpperCase(), style: const TextStyle(fontSize: 14)),
                    initiallyExpanded: true,
                    tilePadding: EdgeInsets.zero,
                    children: perms.map<Widget>((perm) {
                      final permName = perm['name'] as String;
                      final isSelected = _selectedPermissions.contains(permName);
                      return CheckboxListTile(
                        title: Text(perm['display_name'], style: const TextStyle(fontSize: 14)),
                        subtitle: perm['description'] != null 
                            ? Text(perm['description'], style: const TextStyle(fontSize: 12))
                            : null,
                        value: isSelected,
                        dense: true,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedPermissions.add(permName);
                            } else {
                              _selectedPermissions.remove(permName);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : () async {
            if (_formKey.currentState?.validate() != true) return;
            if (_selectedStoreIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select at least one store')),
              );
              return;
            }
            if (_selectedPermissions.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select at least one permission')),
              );
              return;
            }
            
            setState(() => _isLoading = true);
            await widget.onSave(
              _emailController.text,
              _passwordController.text,
              _titleController.text.isNotEmpty ? _titleController.text : null,
              _selectedPermissions.toList(),
              _selectedStoreIds.toList(),
            );
            if (mounted) setState(() => _isLoading = false);
          },
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create Employee'),
        ),
      ],
    );
  }
}

// Edit Employee Dialog
class _EditEmployeeDialog extends StatefulWidget {
  final String userName;
  final String userEmail;
  final List<Store> stores;
  final Map<String, dynamic> availablePermissions;
  final List<String> initialPermissions;
  final List<int> initialStoreIds;
  final String? initialTitle;
  final Future<void> Function(String? title, List<String> permissions, List<int> storeIds) onSave;

  const _EditEmployeeDialog({
    required this.userName,
    required this.userEmail,
    required this.stores,
    required this.availablePermissions,
    required this.initialPermissions,
    required this.initialStoreIds,
    required this.initialTitle,
    required this.onSave,
  });

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  final _titleController = TextEditingController();
  
  late Set<int> _selectedStoreIds;
  late Set<String> _selectedPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _selectedStoreIds = widget.initialStoreIds.toSet();
    _selectedPermissions = widget.initialPermissions.toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.userName}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.userEmail, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title (optional)',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 24),
              
              // Store Selection
              const Text('Store Access', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.stores.map((store) {
                  final isSelected = _selectedStoreIds.contains(store.id);
                  return FilterChip(
                    label: Text(store.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedStoreIds.add(store.id);
                        } else {
                          _selectedStoreIds.remove(store.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Permissions
              const Text('Permissions', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...widget.availablePermissions.entries.map((entry) {
                final group = entry.key;
                final perms = entry.value as List;
                return ExpansionTile(
                  title: Text(group.toUpperCase(), style: const TextStyle(fontSize: 14)),
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  children: perms.map<Widget>((perm) {
                    final permName = perm['name'] as String;
                    final isSelected = _selectedPermissions.contains(permName);
                    return CheckboxListTile(
                      title: Text(perm['display_name'], style: const TextStyle(fontSize: 14)),
                      value: isSelected,
                      dense: true,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedPermissions.add(permName);
                          } else {
                            _selectedPermissions.remove(permName);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              }),
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
          onPressed: _isLoading ? null : () async {
            if (_selectedStoreIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select at least one store')),
              );
              return;
            }
            
            setState(() => _isLoading = true);
            await widget.onSave(
              _titleController.text.isNotEmpty ? _titleController.text : null,
              _selectedPermissions.toList(),
              _selectedStoreIds.toList(),
            );
            if (mounted) setState(() => _isLoading = false);
          },
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
