import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/category.dart' as models;
import '../../providers/stores_provider.dart';
import '../../providers/categories_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../providers/locations_provider.dart';
import '../../models/location.dart';

class CreateStoreScreen extends StatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  // Basic Info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;

  // Contact Info
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  List<String> _additionalPhones = [];

  // Location
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  int? _selectedWilayaId;
  int? _selectedCommuneId;

  // Social Media
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _telegramController = TextEditingController();

  // Images
  XFile? _coverImage;
  Uint8List? _coverImageBytes;
  String? _coverImageUrl;
  bool _isUploadingCover = false;

  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  bool _isUploadingProfile = false;

  // Status
  bool _isOpen = true;

  // Business Hours - Map of day -> schedule
  late Map<String, Map<String, dynamic>> _businessHours;
  
  static const List<String> _weekDays = [
    'saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'
  ];
  
  static const Map<String, String> _dayLabels = {
    'sunday': 'Sunday',
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize business hours with defaults
    _businessHours = {};
    for (final day in _weekDays) {
      // Default: weekdays open, weekend closed
      final isWeekday = day != 'friday' && day != 'saturday';
      _businessHours[day] = {
        'is_open': isWeekday,
        'morning_start': '08:00',
        'morning_end': '12:00',
        'afternoon_start': '13:00',
        'afternoon_end': '16:30',
      };
    }
    // Load categories and wilayas from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadCategories();
      context.read<LocationsProvider>().loadWilayas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _mapUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    _tiktokController.dispose();
    _linkedinController.dispose();
    _youtubeController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {required bool isCover}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: isCover ? 1200 : 800,
        maxHeight: isCover ? 600 : 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (isCover) {
          setState(() {
            _coverImage = image;
            _coverImageBytes = bytes;
          });
          await _uploadImage(isCover: true);
        } else {
          setState(() {
            _profileImage = image;
            _profileImageBytes = bytes;
          });
          await _uploadImage(isCover: false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage({required bool isCover}) async {
    final image = isCover ? _coverImage : _profileImage;
    if (image == null) return;
    
    setState(() {
      if (isCover) {
        _isUploadingCover = true;
      } else {
        _isUploadingProfile = true;
      }
    });
    
    try {
      final api = ApiService();
      final bytes = await image.readAsBytes();
      final response = await api.uploadFile('/upload', bytes, image.name);
      final url = response['url'] as String?;
      
      if (mounted && url != null) {
        setState(() {
          if (isCover) {
            _coverImageUrl = url;
          } else {
            _profileImageUrl = url;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isCover ? 'Cover' : 'Profile'} image uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          if (isCover) {
            _coverImage = null;
            _coverImageBytes = null;
          } else {
            _profileImage = null;
            _profileImageBytes = null;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isCover) {
            _isUploadingCover = false;
          } else {
            _isUploadingProfile = false;
          }
        });
      }
    }
  }

  void _showImagePickerOptions({required bool isCover}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isCover ? 'Add Cover Image' : 'Add Profile Image',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isCover: isCover);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select from your photo library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isCover: isCover);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before saving')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final socialLinks = <String, String>{};
      if (_facebookController.text.isNotEmpty) socialLinks['facebook'] = _facebookController.text;
      if (_instagramController.text.isNotEmpty) socialLinks['instagram'] = _instagramController.text;
      if (_whatsappController.text.isNotEmpty) socialLinks['whatsapp'] = _whatsappController.text;
      if (_tiktokController.text.isNotEmpty) socialLinks['tiktok'] = _tiktokController.text;
      if (_linkedinController.text.isNotEmpty) socialLinks['linkedin'] = _linkedinController.text;
      if (_youtubeController.text.isNotEmpty) socialLinks['youtube'] = _youtubeController.text;
      if (_telegramController.text.isNotEmpty) socialLinks['telegram'] = _telegramController.text;

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category_id': _selectedCategoryId,
        'subcategory_id': _selectedSubcategoryId,
        'phone': _phoneController.text.trim(),
        'phones': _additionalPhones,
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'wilaya_id': _selectedWilayaId,
        'commune_id': _selectedCommuneId,
        'map_url': _mapUrlController.text.trim(),
        'lat': _latController.text.isNotEmpty ? double.tryParse(_latController.text.trim()) : null,
        'lng': _lngController.text.isNotEmpty ? double.tryParse(_lngController.text.trim()) : null,
        'cover_image': _coverImageUrl ?? '',
        'profile_image': _profileImageUrl ?? '',
        'social_links': socialLinks,
        'is_open': _isOpen,
        'business_hours': _businessHours,
      };

      final success = await context.read<StoresProvider>().createStore(data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create store. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Store'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _createStore,
              icon: const Icon(Icons.check),
              label: const Text('Create'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Info'),
            Tab(icon: Icon(Icons.location_on_outlined), text: 'Location'),
            Tab(icon: Icon(Icons.share_outlined), text: 'Social'),
            Tab(icon: Icon(Icons.image_outlined), text: 'Media'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildLocationTab(),
            _buildSocialTab(),
            _buildMediaTab(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isLoading ? null : _createStore,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'CREATE STORE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
          ),
        ),
      ),
    );
  }

  // Tab 1: Basic Info + Contact
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Information', Icons.store),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('Store Name *', Icons.store),
            validator: (value) => value?.isEmpty == true ? 'Store name is required' : null,
          ),
          const SizedBox(height: 16),
          // Main Category dropdown - using dynamic categories from API
          Consumer<CategoriesProvider>(
            builder: (context, categoriesProvider, child) {
              final storeCategories = categoriesProvider.storeCategories;
              
              // Find matching category for subcategory support
              models.Category? selectedCat;
              if (_selectedCategoryId != null && storeCategories.isNotEmpty) {
                selectedCat = storeCategories.cast<models.Category?>().firstWhere(
                  (c) => c?.id == _selectedCategoryId,
                  orElse: () => null,
                );
              }
              
              final subcategories = selectedCat?.children ?? [];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoriesProvider.isLoading)
                    const LinearProgressIndicator()
                  else if (storeCategories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('No categories available. Please add categories first.')),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: storeCategories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                      decoration: _inputDecoration('Main Category *', Icons.category),
                      items: storeCategories.map((category) {
                        return DropdownMenuItem(
                          value: category.id, 
                          child: Text('${category.emoji ?? ''} ${category.name}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                          _selectedSubcategoryId = null;
                        });
                      },
                      validator: (value) => value == null ? 'Category is required' : null,
                    ),
                  // Subcategory dropdown (only shown when main category has subcategories)
                  if (subcategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: subcategories.any((c) => c.id == _selectedSubcategoryId) ? _selectedSubcategoryId : null,
                      decoration: InputDecoration(
                        labelText: 'Subcategory (Optional)',
                        prefixIcon: Icon(Icons.subdirectory_arrow_right, color: AppTheme.primaryColor.withOpacity(0.7)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('None - Use main category'),
                        ),
                        ...subcategories.map((sub) {
                          return DropdownMenuItem(
                            value: sub.id,
                            child: Text(sub.name),
                          );
                        }),
                      ],
                      onChanged: (value) => setState(() => _selectedSubcategoryId = value),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: _inputDecoration('Description', Icons.description),
          ),
          const SizedBox(height: 32),
          
          _buildSectionHeader('Contact Information', Icons.phone),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Primary Phone', Icons.phone),
          ),
          // Additional phones
          ..._additionalPhones.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: entry.value,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Phone ${entry.key + 2}', Icons.phone_android),
                      onChanged: (value) => _additionalPhones[entry.key] = value,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() => _additionalPhones.removeAt(entry.key)),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => _showAddPhoneDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Another Phone'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email', Icons.email),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            decoration: _inputDecoration('Website', Icons.language),
          ),
          const SizedBox(height: 32),
          
          // Store Status
          _buildSectionHeader('Store Status', Icons.toggle_on),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isOpen ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isOpen ? Colors.green.shade200 : Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(_isOpen ? Icons.check_circle : Icons.cancel, color: _isOpen ? Colors.green : Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Store Status', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _isOpen ? 'Currently Open' : 'Currently Closed',
                        style: TextStyle(color: _isOpen ? Colors.green.shade700 : Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isOpen,
                  onChanged: (value) => setState(() => _isOpen = value),
                  activeTrackColor: Colors.green.shade300,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Business Hours Section
          _buildSectionHeader('Business Hours', Icons.access_time),
          const SizedBox(height: 12),
          _buildBusinessHoursSection(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
  
  Widget _buildBusinessHoursSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: _weekDays.map((day) {
          final schedule = _businessHours[day]!;
          final isOpen = schedule['is_open'] == true;
          
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: day != 'saturday' 
                    ? BorderSide(color: Colors.grey.shade200)
                    : BorderSide.none,
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOpen ? Icons.check_circle : Icons.cancel,
                  color: isOpen ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text(
                _dayLabels[day]!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isOpen ? Colors.black87 : Colors.grey,
                ),
              ),
              subtitle: Text(
                isOpen 
                    ? '${schedule['morning_start']} - ${schedule['morning_end']} | ${schedule['afternoon_start']} - ${schedule['afternoon_end']}'
                    : 'Closed',
                style: TextStyle(
                  fontSize: 12,
                  color: isOpen ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
              trailing: Switch(
                value: isOpen,
                onChanged: (value) {
                  setState(() {
                    _businessHours[day]!['is_open'] = value;
                  });
                },
                activeColor: Colors.green,
              ),
              children: [
                if (isOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Morning Period
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.wb_sunny, color: Colors.orange.shade600, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Morning',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTimePickerButton(
                                      day, 'morning_start', schedule['morning_start'],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('to', style: TextStyle(color: Colors.grey)),
                                  ),
                                  Expanded(
                                    child: _buildTimePickerButton(
                                      day, 'morning_end', schedule['morning_end'],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Afternoon Period
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.wb_twilight, color: Colors.blue.shade600, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Afternoon',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTimePickerButton(
                                      day, 'afternoon_start', schedule['afternoon_start'],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('to', style: TextStyle(color: Colors.grey)),
                                  ),
                                  Expanded(
                                    child: _buildTimePickerButton(
                                      day, 'afternoon_end', schedule['afternoon_end'],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildTimePickerButton(String day, String field, String currentTime) {
    return InkWell(
      onTap: () async {
        final parts = currentTime.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          setState(() {
            _businessHours[day]![field] = 
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              currentTime,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 2: Location
  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Address', Icons.location_on),
          const SizedBox(height: 16),
          // State/Wilaya
          Consumer<LocationsProvider>(
            builder: (context, locations, _) {
              final selectedWilaya = locations.getWilayaByName(_stateController.text);
              
              return DropdownSearch<Wilaya>(
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search wilaya...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                items: (filter, props) => locations.wilayas,
                itemAsString: (w) => '${w.code} - ${w.name}',
                selectedItem: selectedWilaya,
                compareFn: (i, s) => i.id == s.id,
                decoratorProps: DropDownDecoratorProps(
                  decoration: _inputDecoration('State/Wilaya *', Icons.map),
                ),
                onChanged: (value) {
                  setState(() {
                    _stateController.text = value?.name ?? '';
                    _selectedWilayaId = value?.id;
                    _cityController.text = ''; // Reset city
                    _selectedCommuneId = null;
                  });
                },
              );
            }
          ),
          const SizedBox(height: 16),
          // City/Commune
          Consumer<LocationsProvider>(
            builder: (context, locations, _) {
              final wilaya = locations.getWilayaByName(_stateController.text);
              
              return DropdownSearch<Commune>(
                enabled: wilaya != null,
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search commune...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                items: (filter, props) async {
                  if (wilaya == null) return [];
                  return await locations.getCommunes(wilaya.id);
                },
                itemAsString: (c) => c.name,
                selectedItem: _cityController.text.isNotEmpty 
                    ? Commune(id: 0, wilayaId: 0, name: _cityController.text) 
                    : null,
                compareFn: (i, s) => i.name == s.name,
                decoratorProps: DropDownDecoratorProps(
                  decoration: _inputDecoration('City/Commune *', Icons.location_city),
                ),
                onChanged: (value) {
                  setState(() {
                    _cityController.text = value?.name ?? '';
                    _selectedCommuneId = value?.id;
                  });
                },
              );
            }
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: _inputDecoration('Street Address', Icons.home),
          ),
          const SizedBox(height: 32),
          
          _buildSectionHeader('Map Location', Icons.pin_drop),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mapUrlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Google Maps URL',
              prefixIcon: Icon(Icons.pin_drop, color: const Color(0xFF4285F4)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'https://maps.google.com/...',
              helperText: 'Paste your Google Maps share link here',
            ),
          ),
          const SizedBox(height: 24),
          
          // GPS Coordinates
          _buildSectionHeader('GPS Coordinates', Icons.gps_fixed),
          const SizedBox(height: 8),
          Text(
            'Enter coordinates manually for precise location (used for nearby search)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _latController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: 'Latitude',
              prefixIcon: Icon(Icons.north, color: Colors.green.shade600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'e.g. 36.7269',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lngController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: 'Longitude',
              prefixIcon: Icon(Icons.east, color: Colors.blue.shade600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'e.g. 3.1837',
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // Tab 3: Social Media
  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Social Media Links', Icons.share),
          const SizedBox(height: 8),
          Text(
            'Add your social media links to help customers find you',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _buildSocialField(_facebookController, 'Facebook', Icons.facebook, const Color(0xFF1877F2), 'facebook.com/yourpage'),
          _buildSocialField(_instagramController, 'Instagram', Icons.camera_alt, const Color(0xFFE4405F), '@yourusername'),
          _buildSocialField(_whatsappController, 'WhatsApp', Icons.chat, const Color(0xFF25D366), '+213XXXXXXXXX'),
          _buildSocialField(_tiktokController, 'TikTok', Icons.music_note, Colors.black, '@yourusername'),
          _buildSocialField(_telegramController, 'Telegram', Icons.send, const Color(0xFF0088CC), '@yourusername'),
          _buildSocialField(_linkedinController, 'LinkedIn', Icons.work, const Color(0xFF0A66C2), 'linkedin.com/company/...'),
          _buildSocialField(_youtubeController, 'YouTube', Icons.play_circle, const Color(0xFFFF0000), 'youtube.com/@yourchannel'),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // Tab 4: Images
  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Cover Image', Icons.panorama),
          const SizedBox(height: 8),
          Text('Recommended size: 1200x600px', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          _buildImagePicker(
            isCover: true,
            imageBytes: _coverImageBytes,
            imageUrl: _coverImageUrl,
            isUploading: _isUploadingCover,
          ),
          const SizedBox(height: 32),

          _buildSectionHeader('Profile Image', Icons.account_circle),
          const SizedBox(height: 8),
          Text('Square image recommended', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          _buildImagePicker(
            isCover: false,
            imageBytes: _profileImageBytes,
            imageUrl: _profileImageUrl,
            isUploading: _isUploadingProfile,
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }

  Widget _buildSocialField(TextEditingController controller, String label, IconData icon, Color color, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: color),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required bool isCover,
    required Uint8List? imageBytes,
    required String? imageUrl,
    required bool isUploading,
  }) {
    final hasImage = imageBytes != null || (imageUrl != null && imageUrl.isNotEmpty);
    
    return GestureDetector(
      onTap: isUploading ? null : () => _showImagePickerOptions(isCover: isCover),
      child: Container(
        height: isCover ? 150 : 120,
        width: isCover ? double.infinity : 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppTheme.primaryColor : Colors.grey.shade300,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: isUploading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            : hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildPlaceholder(isCover),
      ),
    );
  }

  Widget _buildPlaceholder(bool isCover) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isCover ? Icons.add_photo_alternate : Icons.person_add_alt_1,
          size: 40,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add ${isCover ? 'cover' : 'profile'} image',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Icon(Icons.photo_library, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ],
    );
  }

  void _showAddPhoneDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Phone Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+213...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _additionalPhones.add(controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
