import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/category.dart' as models;
import '../../providers/categories_provider.dart';

class CategoryFormScreen extends StatefulWidget {
  final String type;
  final models.Category? category; // For editing
  final models.Category? parentCategory; // For adding subcategory

  const CategoryFormScreen({
    super.key,
    required this.type,
    this.category,
    this.parentCategory,
  });

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _emojiController = TextEditingController();
  final _iconController = TextEditingController();
  final _colorController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _sortOrderController = TextEditingController();
  bool _isActive = true;
  bool _isSubmitting = false;

  bool get isEditing => widget.category != null;
  bool get isSubcategory => widget.parentCategory != null || widget.category?.parentId != null;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _nameEnController.text = widget.category!.nameEn ?? '';
      _emojiController.text = widget.category!.emoji ?? '';
      _iconController.text = widget.category!.icon ?? '';
      _colorController.text = widget.category!.color ?? '';
      _imageUrlController.text = widget.category!.imageUrl ?? '';
      _sortOrderController.text = widget.category!.sortOrder.toString();
      _isActive = widget.category!.isActive;
    } else {
      _sortOrderController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _emojiController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    _imageUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = isEditing ? 'Edit Category' : 'New Category';
    if (isSubcategory) {
      title = isEditing ? 'Edit Subcategory' : 'New Subcategory';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getIconForType(widget.type), color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Type: ${widget.type.toUpperCase()}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.parentCategory != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.subdirectory_arrow_right, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Parent: ${widget.parentCategory!.name}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Category name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Name (English)
            TextFormField(
              controller: _nameEnController,
              decoration: const InputDecoration(
                labelText: 'Name (English)',
                hintText: 'Optional English translation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Emoji and Icon (for parent categories)
            if (!isSubcategory) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emojiController,
                      decoration: const InputDecoration(
                        labelText: 'Emoji',
                        hintText: '🍽️',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _iconController,
                      decoration: const InputDecoration(
                        labelText: 'Icon Name',
                        hintText: 'construction',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Color
              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: 'Color (Hex)',
                  hintText: '#FF5722',
                  border: const OutlineInputBorder(),
                  suffixIcon: _colorController.text.isNotEmpty
                      ? Container(
                          margin: const EdgeInsets.all(8),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _parseColor(_colorController.text),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Image URL (mainly for service categories)
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
            ],

            // Sort Order
            TextFormField(
              controller: _sortOrderController,
              decoration: const InputDecoration(
                labelText: 'Sort Order',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Active toggle
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Inactive categories won\'t appear in forms'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Update Category' : 'Create Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      String cleanHex = hex.replaceFirst('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'store':
        return Icons.store;
      case 'product':
        return Icons.shopping_bag;
      case 'service':
        return Icons.handyman;
      default:
        return Icons.category;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<CategoriesProvider>();

    try {
      bool success;
      
      if (isEditing) {
        // Update existing category
        success = await provider.updateCategory(widget.category!.id, {
          'name': _nameController.text.trim(),
          'name_en': _nameEnController.text.trim().isNotEmpty 
              ? _nameEnController.text.trim() 
              : null,
          'emoji': _emojiController.text.trim().isNotEmpty 
              ? _emojiController.text.trim() 
              : null,
          'icon': _iconController.text.trim().isNotEmpty 
              ? _iconController.text.trim() 
              : null,
          'color': _colorController.text.trim().isNotEmpty 
              ? _colorController.text.trim() 
              : null,
          'image_url': _imageUrlController.text.trim().isNotEmpty 
              ? _imageUrlController.text.trim() 
              : null,
          'sort_order': int.tryParse(_sortOrderController.text) ?? 0,
          'is_active': _isActive,
        });
      } else {
        // Create new category
        final result = await provider.createCategory(
          type: widget.type,
          name: _nameController.text.trim(),
          nameEn: _nameEnController.text.trim().isNotEmpty 
              ? _nameEnController.text.trim() 
              : null,
          parentId: widget.parentCategory?.id,
          emoji: _emojiController.text.trim().isNotEmpty 
              ? _emojiController.text.trim() 
              : null,
          icon: _iconController.text.trim().isNotEmpty 
              ? _iconController.text.trim() 
              : null,
          color: _colorController.text.trim().isNotEmpty 
              ? _colorController.text.trim() 
              : null,
          imageUrl: _imageUrlController.text.trim().isNotEmpty 
              ? _imageUrlController.text.trim() 
              : null,
          sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
        );
        success = result != null;
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
