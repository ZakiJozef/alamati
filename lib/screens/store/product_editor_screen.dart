import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../models/category.dart' as models;
import '../../models/unit.dart';
import '../../services/api_service.dart';
import '../../providers/categories_provider.dart';
import '../../providers/units_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class ProductEditorScreen extends StatefulWidget {
  final Store store;
  final Product? product;

  const ProductEditorScreen({
    super.key,
    required this.store,
    this.product,
  });

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _imageController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  
  // Image list
  List<String> _images = [];
  final _newImageController = TextEditingController();
  
  // State
  String _type = 'product';
  String? _selectedServiceType;
  int? _selectedProductCategoryId; // Main product category ID
  int? _selectedProductSubcategoryId; // Product subcategory ID
  int? _selectedPriceUnitId; // Price unit for services
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (isEdit) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descController.text = p.description ?? '';
      _priceController.text = p.price?.toString() ?? '';
      _discountController.text = p.discountPrice?.toString() ?? '';
      _imageController.text = p.image ?? '';
      _categoryController.text = p.category ?? '';
      _stockController.text = p.stock.toString();
      _type = p.type;
      _isActive = p.isActive;
      _images = List.from(p.images);
      _selectedPriceUnitId = p.priceUnitId;
      
      // Store category IDs for editing
      _selectedProductCategoryId = p.categoryId;
      _selectedProductSubcategoryId = p.subcategoryId;
      _selectedServiceType = p.type == 'service' ? p.category : null;
    } else {
      _stockController.text = '10';
    }
    
    // Load categories and units from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadCategories();
      context.read<UnitsProvider>().loadUnits();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _imageController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _newImageController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'discount_price': _discountController.text.isEmpty ? null : double.tryParse(_discountController.text),
      'image': _imageController.text.trim().isEmpty ? null : _imageController.text.trim(),
      'images': _images,
      'category': _type == 'service' && _selectedServiceType != null 
          ? _selectedServiceType 
          : (_categoryController.text.trim().isEmpty ? null : _categoryController.text.trim()),
      'category_id': _type == 'product' ? _selectedProductCategoryId : null,
      'subcategory_id': _type == 'product' ? _selectedProductSubcategoryId : null,
      'stock': int.tryParse(_stockController.text) ?? 10,
      'type': _type,
      'is_active': _isActive,
      'price_unit_id': _type == 'service' ? _selectedPriceUnitId : null,
    };

    try {
      if (isEdit) {
        await _api.put('/products/${widget.product!.id}', data);
      } else {
        await _api.post('/stores/${widget.store.id}/products', data);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Product updated successfully' : 'Product created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addImage() {
    final url = _newImageController.text.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true) {
      setState(() {
        _images.add(url);
        _newImageController.clear();
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveProduct,
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
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Basic Info'),
            Tab(icon: Icon(Icons.image_outlined), text: 'Images'),
            Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildImagesTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isSaving ? null : _saveProduct,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isEdit ? 'UPDATE PRODUCT' : 'CREATE PRODUCT',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          _buildSectionTitle('Product Name *'),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('Enter product name'),
            validator: (v) => v?.trim().isEmpty == true ? 'Product name is required' : null,
          ),
          const SizedBox(height: 24),
          
          // Description
          _buildSectionTitle('Description'),
          TextFormField(
            controller: _descController,
            decoration: _inputDecoration('Enter product description...'),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          
          // Type Selection (moved before category)
          _buildSectionTitle('Type'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeCard(
                  'Product',
                  Icons.shopping_bag,
                  'product',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeCard(
                  'Service',
                  Icons.handyman,
                  'service',
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Product Category Picker (only shown when product is selected)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _type == 'product' ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Category'),
                const SizedBox(height: 8),
                Text(
                  'Select a category for better product discovery',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                _buildProductCategoryPicker(),
                const SizedBox(height: 24),
              ],
            ) : const SizedBox.shrink(),
          ),
          
          // Service Type Selector (only shown when service is selected)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _type == 'service' ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Service Type *'),
                const SizedBox(height: 8),
                Text(
                  'Select a service category for better filtering',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                _buildServiceTypeSelector(),
              ],
            ) : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          
          // Pricing
          _buildSectionTitle('Pricing'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price (DZD) *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _priceController,
                      decoration: _inputDecoration('0.00'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Price is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Discount Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('SALE', style: TextStyle(fontSize: 9, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _discountController,
                      decoration: _inputDecoration('0.00'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Price Unit Selector (only for services)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _type == 'service' ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Price per', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Optional', style: TextStyle(fontSize: 9, color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Consumer<UnitsProvider>(
                  builder: (context, unitsProvider, _) {
                    if (unitsProvider.isLoading) {
                      return const LinearProgressIndicator();
                    }
                    return DropdownButtonFormField<int?>(
                      value: _selectedPriceUnitId,
                      decoration: _inputDecoration('Select unit (e.g., Hour, Meter)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('No unit (flat price)')),
                        ...unitsProvider.activeUnits.map((unit) => DropdownMenuItem<int?>(
                          value: unit.id,
                          child: Text('${unit.name} (${unit.symbol})'),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedPriceUnitId = value),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'e.g., 5000 DZD/hour for hourly services',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ) : const SizedBox.shrink(),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Image
          _buildSectionTitle('Main Image (Thumbnail)'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imageController.text.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _imageController.text,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(Icons.broken_image, color: Colors.grey.shade400),
                        ),
                      )
                    : Icon(Icons.image, size: 40, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _imageController,
                      decoration: _inputDecoration('Paste image URL here...'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will be the main product thumbnail shown in listings',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Additional Images
          _buildSectionTitle('Additional Images (Gallery)'),
          const SizedBox(height: 8),
          Text(
            'Add multiple images for the product gallery carousel',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          
          // Add Image Field
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _newImageController,
                  decoration: _inputDecoration('Paste image URL...'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _addImage,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Images Grid
          if (_images.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('No additional images', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _images.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: entry.value,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _removeImage(entry.key),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock
          _buildSectionTitle('Inventory'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.blue.shade700),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stock Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('How many items available?', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Status
          _buildSectionTitle('Visibility'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isActive = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isActive ? Colors.green : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, color: _isActive ? Colors.white : Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Published',
                            style: TextStyle(
                              color: _isActive ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isActive = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: !_isActive ? Colors.orange : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility_off, color: !_isActive ? Colors.white : Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Draft',
                            style: TextStyle(
                              color: !_isActive ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isActive
                ? 'Product is visible to customers'
                : 'Product is hidden from customers (draft mode)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          
          // Store Info
          _buildSectionTitle('Store'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.store.profileImage != null
                      ? CachedNetworkImage(
                          imageUrl: widget.store.profileImage!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Icon(Icons.store, color: AppTheme.primaryColor),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.store.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(widget.store.category ?? 'Store', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: Colors.green.shade400),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTypeCard(String label, IconData icon, String value, Color color) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey.shade500, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildProductCategoryPicker() {
    return Consumer<CategoriesProvider>(
      builder: (context, categoriesProvider, child) {
        final productCategories = categoriesProvider.productCategories;
        
        // Find matching category for subcategory support
        models.Category? selectedCat;
        if (_selectedProductCategoryId != null && productCategories.isNotEmpty) {
          selectedCat = productCategories.cast<models.Category?>().firstWhere(
            (c) => c?.id == _selectedProductCategoryId,
            orElse: () => null,
          );
        }
        
        final subcategories = selectedCat?.children ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categoriesProvider.isLoading)
              const LinearProgressIndicator()
            else if (productCategories.isEmpty)
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
                    const Expanded(child: Text('No product categories available.')),
                  ],
                ),
              )
            else ...[
              // Main Category Dropdown
              DropdownButtonFormField<int>(
                value: productCategories.any((c) => c.id == _selectedProductCategoryId) ? _selectedProductCategoryId : null,
                decoration: InputDecoration(
                  labelText: 'Main Category',
                  prefixIcon: Icon(Icons.category, color: Colors.blue),
                  hintText: 'Select a category',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: productCategories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text('${category.emoji ?? ''} ${category.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductCategoryId = value;
                    _selectedProductSubcategoryId = null; // Reset subcategory
                  });
                },
              ),
              
              // Subcategory Dropdown (only shown when main category has subcategories)
              if (subcategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: subcategories.any((c) => c.id == _selectedProductSubcategoryId) ? _selectedProductSubcategoryId : null,
                  decoration: InputDecoration(
                    labelText: 'Subcategory (Optional)',
                    prefixIcon: Icon(Icons.subdirectory_arrow_right, color: Colors.blue.shade300),
                    hintText: 'Select a subcategory',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...subcategories.map((sub) {
                      return DropdownMenuItem(
                        value: sub.id,
                        child: Text(sub.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedProductSubcategoryId = value);
                  },
                ),
              ],
              
              // Selected category display
              if (selectedCat != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedProductSubcategoryId != null
                              ? '${selectedCat.name} > ${subcategories.firstWhere((s) => s.id == _selectedProductSubcategoryId, orElse: () => models.Category(id: 0, name: '', type: 'product')).name}'
                              : selectedCat.name,
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.blue.shade400, size: 18),
                        onPressed: () => setState(() {
                          _selectedProductCategoryId = null;
                          _selectedProductSubcategoryId = null;
                        }),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildServiceTypeSelector() {
    return Column(
      children: [
        // Selected service type display
        if (_selectedServiceType != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.purple.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedServiceType!,
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.purple.shade400),
                  onPressed: () => setState(() => _selectedServiceType = null),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        
        // Service categories grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: AppConstants.serviceCategories.length,
          itemBuilder: (context, index) {
            final category = AppConstants.serviceCategories[index];
            return _buildServiceCategoryCard(category);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCategoryCard(ServiceCategory category) {
    return GestureDetector(
      onTap: () => _showServiceTypesBottomSheet(category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: category.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Color(category.color).withValues(alpha: 0.3),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Color(category.color).withValues(alpha: 0.3),
                  child: Icon(Icons.image, color: Color(category.color)),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              // Category name
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Service count badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(category.color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${category.services.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceTypesBottomSheet(ServiceCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle
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
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(category.color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.handyman,
                          color: Color(category.color),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${category.services.length} services available',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Service list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: category.services.length,
                    itemBuilder: (context, index) {
                      final service = category.services[index];
                      final isSelected = _selectedServiceType == service.name;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: service.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade200,
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 56,
                              height: 56,
                              color: Color(category.color).withValues(alpha: 0.2),
                              child: Icon(Icons.build, color: Color(category.color)),
                            ),
                          ),
                        ),
                        title: Text(
                          service.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Color(category.color) : null,
                          ),
                        ),
                        subtitle: Text(
                          service.nameEn,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Color(category.color))
                            : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                        onTap: () {
                          setState(() {
                            _selectedServiceType = service.name;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
