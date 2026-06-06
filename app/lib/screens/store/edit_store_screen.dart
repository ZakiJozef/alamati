import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/store.dart';
import '../../models/category.dart' as models;
import '../../providers/stores_provider.dart';
import '../../providers/categories_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../providers/locations_provider.dart';
import '../../models/location.dart';

class EditStoreScreen extends StatefulWidget {
  final Store store;

  const EditStoreScreen({super.key, required this.store});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  // Basic Info
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  int? _selectedCategoryId;
  List<int> _selectedCategoryIds = [];
  int? _selectedSubcategoryId;
  List<int> _selectedSubcategoryIds = [];
  bool _providesServices = false;
  List<int> _selectedServiceCategoryIds = [];

  // Contact Info
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  List<String> _additionalPhones = [];

  // Location
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _mapUrlController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  int? _selectedWilayaId;
  int? _selectedCommuneId;

  // Social Media
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _whatsappController;
  late TextEditingController _tiktokController;
  late TextEditingController _linkedinController;
  late TextEditingController _youtubeController;
  late TextEditingController _telegramController;

  // Images - now using image picker instead of URL controllers
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
    _initializeControllers();
    // Load categories and locations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadCategories();
      context.read<LocationsProvider>().loadWilayas();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _slugController.dispose();
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

  void _initializeControllers() {
    final store = widget.store;

    // Basic Info
    _nameController = TextEditingController(text: store.name);
    _slugController = TextEditingController(text: store.slug ?? '');
    _descriptionController = TextEditingController(text: store.description ?? '');
    // Store category IDs
    _selectedCategoryId = store.categoryId;
    _selectedCategoryIds = List.from(store.categoryIds);
    _selectedSubcategoryId = store.subcategoryId;
    _selectedSubcategoryIds = List.from(store.subcategoryIds);
    _providesServices = store.providesServices;
    _selectedServiceCategoryIds = List.from(store.serviceCategoryIds);

    // Contact Info
    _phoneController = TextEditingController(text: store.phone ?? '');
    _emailController = TextEditingController(text: store.email ?? '');
    _websiteController = TextEditingController(text: store.website ?? '');
    _additionalPhones = List.from(store.phones);

    // Location
    _addressController = TextEditingController(text: store.address ?? '');
    _cityController = TextEditingController(text: store.city ?? '');
    _stateController = TextEditingController(text: store.state ?? '');
    _mapUrlController = TextEditingController(text: store.mapUrl ?? '');
    _latController = TextEditingController(text: store.lat?.toString() ?? '');
    _lngController = TextEditingController(text: store.lng?.toString() ?? '');
    _selectedWilayaId = store.wilayaId;
    _selectedCommuneId = store.communeId;

    // Social Media
    final social = store.socialLinks;
    _facebookController = TextEditingController(text: social['facebook'] ?? '');
    _instagramController = TextEditingController(text: social['instagram'] ?? '');
    _whatsappController = TextEditingController(text: social['whatsapp'] ?? '');
    _tiktokController = TextEditingController(text: social['tiktok'] ?? '');
    _linkedinController = TextEditingController(text: social['linkedin'] ?? '');
    _youtubeController = TextEditingController(text: social['youtube'] ?? '');
    _telegramController = TextEditingController(text: social['telegram'] ?? '');

    // Images - initialize with existing URLs
    _coverImageUrl = store.coverImage;
    _profileImageUrl = store.profileImage;

    // Status
    _isOpen = store.isOpen;
    
    // Business Hours - initialize with store data or defaults
    _businessHours = {};
    for (final day in _weekDays) {
      if (store.businessHours.containsKey(day) && store.businessHours[day] is Map) {
        _businessHours[day] = Map<String, dynamic>.from(store.businessHours[day]);
      } else {
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
    }
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
                isCover ? 'Change Cover Image' : 'Change Profile Image',
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

  /// Extracts latitude and longitude from Google Maps URL
  void _extractCoordinatesFromUrl() {
    final url = _mapUrlController.text.trim();
    
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Google Maps URL first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final coords = _parseCoordinatesFromUrl(url);
    
    if (coords != null) {
      setState(() {
        _latController.text = coords['lat']!;
        _lngController.text = coords['lng']!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coordinates extracted: ${coords['lat']}, ${coords['lng']}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not extract coordinates from this URL. Try using the full Google Maps URL.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Parses coordinates from various Google Maps URL formats
  Map<String, String>? _parseCoordinatesFromUrl(String url) {
    // Pattern 1: /@lat,lng,zoom format (most common in full URLs)
    // Example: https://www.google.com/maps/place/.../@36.7266616,3.1833652,221m/...
    final atPattern = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final atMatch = atPattern.firstMatch(url);
    if (atMatch != null) {
      return {
        'lat': atMatch.group(1)!,
        'lng': atMatch.group(2)!,
      };
    }

    // Pattern 2: !3d and !4d format (embedded in data parameter)
    // Example: ...!3d36.7269273!4d3.1837043...
    final dataPattern = RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)');
    final dataMatch = dataPattern.firstMatch(url);
    if (dataMatch != null) {
      return {
        'lat': dataMatch.group(1)!,
        'lng': dataMatch.group(2)!,
      };
    }

    // Pattern 3: ll= or q= parameter format
    // Example: ...?ll=36.7269273,3.1837043 or ?q=36.7269273,3.1837043
    final llPattern = RegExp(r'[?&](?:ll|q)=(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final llMatch = llPattern.firstMatch(url);
    if (llMatch != null) {
      return {
        'lat': llMatch.group(1)!,
        'lng': llMatch.group(2)!,
      };
    }

    // Pattern 4: /place/ followed by coordinates
    // Example: /place/36.7269273,3.1837043
    final placePattern = RegExp(r'/place/(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final placeMatch = placePattern.firstMatch(url);
    if (placeMatch != null) {
      return {
        'lat': placeMatch.group(1)!,
        'lng': placeMatch.group(2)!,
      };
    }

    return null;
  }

  Future<void> _saveStore() async {
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
        'slug': _slugController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category_id': _selectedCategoryId,
        'category_ids': _selectedCategoryIds,
        'subcategory_id': _selectedSubcategoryId,
        'subcategory_ids': _selectedSubcategoryIds,
        'provides_services': _providesServices,
        'service_category_ids': _selectedServiceCategoryIds,
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

      final success = await context.read<StoresProvider>().updateStore(widget.store.id, data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate successful update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update store. Please try again.'),
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
        title: const Text('Edit Store'),
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
              onPressed: _saveStore,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
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
            onPressed: _isLoading ? null : _saveStore,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'SAVE CHANGES',
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
          // Slug field (editable with generate button)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _slugController,
                  decoration: InputDecoration(
                    labelText: 'Store URL Slug',
                    prefixIcon: Icon(Icons.link, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    helperText: _slugController.text.isNotEmpty 
                        ? 'https://3alamati.com/store/${_slugController.text}'
                        : 'Enter a URL-friendly slug',
                  ),
                  onChanged: (_) => setState(() {}), // Update helper text
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton.filled(
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'Generate from store name',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a store name first'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    // Generate slug from name
                    final slug = name
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Remove special chars
                        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
                        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
                        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing hyphens
                    setState(() {
                      _slugController.text = slug;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Slug generated: $slug'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ],
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
          const SizedBox(height: 24),
          
          // Provides Services Toggle (moved here between Website and Store Status)
          _buildSectionHeader('مزود خدمات', Icons.handyman),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _providesServices ? Colors.blue.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _providesServices ? Colors.blue.shade200 : Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_providesServices ? Icons.check_circle : Icons.handyman_outlined, color: _providesServices ? Colors.blue : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('هل تقدم خدمات؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _providesServices ? 'سيتم إشعارك بالطلبات المتعلقة بالخدمات' : 'فعّل لتلقي إشعارات الطلبات',
                            style: TextStyle(fontSize: 12, color: _providesServices ? Colors.blue.shade700 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _providesServices,
                      onChanged: (value) => setState(() { _providesServices = value; if (!value) _selectedServiceCategoryIds.clear(); }),
                      activeTrackColor: Colors.blue.shade300,
                    ),
                  ],
                ),
                if (_providesServices) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Consumer<CategoriesProvider>(
                    builder: (context, categoriesProvider, _) {
                      final serviceCategories = categoriesProvider.serviceCategories;
                      if (serviceCategories.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Row(children: [Icon(Icons.info_outline, color: Colors.orange), SizedBox(width: 8), Text('لا توجد فئات خدمات متاحة')]),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('اختر فئات الخدمات:', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          const SizedBox(height: 12),
                          ...serviceCategories.map((cat) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FilterChip(
                                  avatar: cat.emoji != null ? Text(cat.emoji!, style: const TextStyle(fontSize: 16)) : null,
                                  label: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  selected: _selectedServiceCategoryIds.contains(cat.id),
                                  onSelected: (selected) => setState(() {
                                    if (selected) { _selectedServiceCategoryIds.add(cat.id); } 
                                    else { _selectedServiceCategoryIds.remove(cat.id); for (final c in cat.children) _selectedServiceCategoryIds.remove(c.id); }
                                  }),
                                  selectedColor: Colors.blue.shade100,
                                  checkmarkColor: Colors.blue.shade700,
                                ),
                                if (cat.children.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
                                    child: Wrap(
                                      spacing: 6, runSpacing: 6,
                                      children: cat.children.map((sub) => FilterChip(
                                        label: Text(sub.name, style: const TextStyle(fontSize: 12)),
                                        selected: _selectedServiceCategoryIds.contains(sub.id),
                                        onSelected: (selected) => setState(() => selected ? _selectedServiceCategoryIds.add(sub.id) : _selectedServiceCategoryIds.remove(sub.id)),
                                        selectedColor: Colors.blue.shade50,
                                        checkmarkColor: Colors.blue,
                                        visualDensity: VisualDensity.compact,
                                      )).toList(),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
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
          
          // Store Categories Section (moved to bottom)
          _buildSectionHeader('فئات المتجر', Icons.category),
          const SizedBox(height: 16),
          Consumer<CategoriesProvider>(
            builder: (context, categoriesProvider, child) {
              final storeCategories = categoriesProvider.storeCategories;
              
              if (categoriesProvider.isLoading) {
                return const LinearProgressIndicator();
              }
              
              if (storeCategories.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('لا توجد فئات متاحة')),
                    ],
                  ),
                );
              }
              
              // Count selected subcategories for each category
              int totalSelectedSubs = _selectedSubcategoryIds.length;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary of selections
                  if (_selectedCategoryIds.isNotEmpty || totalSelectedSubs > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedCategoryIds.length} فئة • $totalSelectedSubs تخصص',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Accordion categories
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: storeCategories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final isSelected = _selectedCategoryIds.contains(category.id);
                          final selectedSubCount = category.children
                              .where((sub) => _selectedSubcategoryIds.contains(sub.id))
                              .length;
                          
                          return Column(
                            children: [
                              if (index > 0) Divider(height: 1, color: Colors.grey.shade300),
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        category.emoji ?? '📁',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          category.name,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? AppTheme.primaryColor : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isSelected || selectedSubCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            selectedSubCount > 0 ? '$selectedSubCount' : '✓',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${category.children.length} تخصص',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  children: [
                                    Container(
                                      color: Colors.grey.shade50,
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Select/Deselect this category
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedCategoryIds.remove(category.id);
                                                  for (final sub in category.children) {
                                                    _selectedSubcategoryIds.remove(sub.id);
                                                  }
                                                  if (_selectedCategoryId == category.id) {
                                                    _selectedCategoryId = _selectedCategoryIds.isNotEmpty 
                                                        ? _selectedCategoryIds.first : null;
                                                  }
                                                } else {
                                                  _selectedCategoryIds.add(category.id);
                                                  _selectedCategoryId ??= category.id;
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                                    color: isSelected ? AppTheme.primaryColor : Colors.grey,
                                                    size: 22,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isSelected ? 'فئة مختارة' : 'اختر هذه الفئة',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          // Subcategories
                                          if (category.children.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              'التخصصات:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: category.children.map((sub) {
                                                final isSubSelected = _selectedSubcategoryIds.contains(sub.id);
                                                return FilterChip(
                                                  label: Text(sub.name),
                                                  selected: isSubSelected,
                                                  onSelected: (selected) {
                                                    setState(() {
                                                      if (selected) {
                                                        _selectedSubcategoryIds.add(sub.id);
                                                        // Auto-select parent category
                                                        if (!_selectedCategoryIds.contains(category.id)) {
                                                          _selectedCategoryIds.add(category.id);
                                                          _selectedCategoryId ??= category.id;
                                                        }
                                                      } else {
                                                        _selectedSubcategoryIds.remove(sub.id);
                                                      }
                                                    });
                                                  },
                                                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                                                  checkmarkColor: AppTheme.primaryColor,
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
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
          const SizedBox(height: 12),
          // Extract Coordinates Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _extractCoordinatesFromUrl,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Extract Coordinates from URL'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4285F4),
                side: const BorderSide(color: Color(0xFF4285F4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    prefixIcon: Icon(Icons.north, color: Colors.green.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'e.g. 36.7269',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    prefixIcon: Icon(Icons.east, color: Colors.blue.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'e.g. 3.1837',
                  ),
                ),
              ),
            ],
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
                        child: imageBytes != null
                            ? Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorWidget: (_, __, ___) => _buildPlaceholder(isCover),
                              ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
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
          'Tap to ${isCover ? 'change cover' : 'change profile'} image',
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
