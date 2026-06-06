import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/portfolio_item.dart';
import '../../models/store.dart';
import '../../services/api_service.dart';
import '../../core/theme.dart';

class ManagePortfolioScreen extends StatefulWidget {
  final Store store;

  const ManagePortfolioScreen({super.key, required this.store});

  @override
  State<ManagePortfolioScreen> createState() => _ManagePortfolioScreenState();
}

class _ManagePortfolioScreenState extends State<ManagePortfolioScreen> {
  final ApiService _apiService = ApiService();
  List<PortfolioItem> _portfolioItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get('/stores/${widget.store.id}/portfolio');
      if (response is List) {
        setState(() {
          _portfolioItems = response.map((json) => PortfolioItem.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(PortfolioItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Work'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/portfolio/${item.id}');
        _loadPortfolio();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Work deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting work: $e')),
          );
        }
      }
    }
  }

  void _showAddEditDialog([PortfolioItem? existingItem]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PortfolioEditorSheet(
        storeId: widget.store.id,
        existingItem: existingItem,
        onSaved: () {
          Navigator.pop(ctx);
          _loadPortfolio();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Manage Portfolio'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPortfolio,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Work'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _portfolioItems.isEmpty
                  ? _buildEmptyState()
                  : _buildPortfolioList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Error loading portfolio', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadPortfolio, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.collections, size: 60, color: Colors.purple.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Portfolio Works Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Showcase your best work to attract customers',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioList() {
    return RefreshIndicator(
      onRefresh: _loadPortfolio,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _portfolioItems.length,
        itemBuilder: (ctx, index) => _buildPortfolioCard(_portfolioItems[index]),
      ),
    );
  }

  Widget _buildPortfolioCard(PortfolioItem item) {
    final images = item.displayImages;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel or placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: images.isEmpty
                ? Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  )
                : images.length == 1
                    ? CachedNetworkImage(
                        imageUrl: images.first,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) => Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      )
                    : CarouselSlider.builder(
                        itemCount: images.length,
                        itemBuilder: (ctx, idx, realIdx) => CachedNetworkImage(
                          imageUrl: images[idx],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, url, err) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        ),
                        options: CarouselOptions(
                          height: 180,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: images.length > 1,
                          autoPlay: images.length > 1,
                          autoPlayInterval: const Duration(seconds: 4),
                        ),
                      ),
          ),
          // Title and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (item.description != null && item.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.description!,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.photo_library, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${images.length} ${images.length == 1 ? 'image' : 'images'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  onPressed: () => _showAddEditDialog(item),
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                ),
                // Delete button
                IconButton(
                  onPressed: () => _deleteItem(item),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor sheet for adding/editing portfolio items
class _PortfolioEditorSheet extends StatefulWidget {
  final int storeId;
  final PortfolioItem? existingItem;
  final VoidCallback onSaved;

  const _PortfolioEditorSheet({
    required this.storeId,
    this.existingItem,
    required this.onSaved,
  });

  @override
  State<_PortfolioEditorSheet> createState() => _PortfolioEditorSheetState();
}

class _PortfolioEditorSheetState extends State<_PortfolioEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<String> _imageUrls = [];
  bool _isSaving = false;
  bool _isUploading = false;

  bool get isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _titleController.text = widget.existingItem!.title;
      _descriptionController.text = widget.existingItem!.description ?? '';
      _imageUrls = List.from(widget.existingItem!.displayImages);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _imagePicker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() => _isUploading = true);
        
        int uploadedCount = 0;
        int failedCount = 0;
        
        for (final file in picked) {
          if (_imageUrls.length >= 10) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maximum 10 images allowed')),
              );
            }
            break;
          }
          
          try {
            // Read file bytes for cross-platform support (works on web and mobile)
            debugPrint('Uploading file: ${file.name}');
            final bytes = await file.readAsBytes();
            final response = await _apiService.uploadFile('/upload', bytes, file.name);
            debugPrint('Upload response: $response');
            
            final url = response['url'] as String?;
            if (url != null && mounted) {
              setState(() => _imageUrls.add(url));
              uploadedCount++;
              debugPrint('Added image URL: $url');
            } else {
              failedCount++;
              debugPrint('URL was null in response');
            }
          } catch (e) {
            failedCount++;
            debugPrint('Error uploading image: $e');
          }
        }
        
        if (mounted) {
          setState(() => _isUploading = false);
          
          if (uploadedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$uploadedCount image(s) uploaded successfully')),
            );
          }
          if (failedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$failedCount image(s) failed to upload'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
              const Text(
                'Add Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Upload from your device'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages();
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
                  child: const Icon(Icons.link, color: Colors.purple),
                ),
                title: const Text('Paste Image URL'),
                subtitle: const Text('Use an image from the web'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPasteUrlDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasteUrlDialog() {
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.link, color: Colors.purple),
            const SizedBox(width: 12),
            const Text('Paste Image URL'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com/image.png',
                labelText: 'Image URL',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.image),
              ),
              autofocus: true,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Text(
              'Paste a direct link to an image (jpg, png, webp)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
                if (_imageUrls.length < 10) {
                  setState(() => _imageUrls.add(url));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image added successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maximum 10 images allowed')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid URL starting with http:// or https://'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'store_id': widget.storeId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'images': _imageUrls,
      };

      if (isEditing) {
        await _apiService.put('/portfolio/${widget.existingItem!.id}', data);
      } else {
        await _apiService.post('/portfolio', data);
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Work' : 'Add New Work',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Work Title *',
                        hintText: 'e.g., Plumbing Installation',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Brief description of this work',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // Images section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Images *',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_imageUrls.length}/10',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Image grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _imageUrls.length + 1,
                      itemBuilder: (ctx, index) {
                        if (index == _imageUrls.length) {
                          // Add button
                          return _isUploading
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: CircularProgressIndicator()),
                                )
                              : GestureDetector(
                                  onTap: _imageUrls.length < 10 ? _showAddImageOptions : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey.shade500),
                                        const SizedBox(height: 4),
                                        Text('Add', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                );
                        }
                        
                        // Image tile
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrls[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: (ctx, url, err) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Save button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEditing ? 'Update Work' : 'Add Work', style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
