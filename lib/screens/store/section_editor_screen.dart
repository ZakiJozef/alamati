import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stores_provider.dart';
import '../../models/store.dart';
import '../../models/store_section.dart';
import '../../models/product.dart';
import '../../core/theme.dart';

/// Screen for creating/editing a store section
class SectionEditorScreen extends StatefulWidget {
  final Store store;
  final StoreSection? section;

  const SectionEditorScreen({
    super.key,
    required this.store,
    this.section,
  });

  @override
  State<SectionEditorScreen> createState() => _SectionEditorScreenState();
}

class _SectionEditorScreenState extends State<SectionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  StoreSectionType _selectedType = StoreSectionType.slider;
  List<Product> _selectedProducts = [];
  DateTime? _countdownEndTime;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoadingProducts = true;
  List<Product> _storeProducts = [];
  
  // Sponsored zone banner fields
  final TextEditingController _bannerLinkController = TextEditingController();
  String? _bannerImageUrl;

  bool get isEditing => widget.section != null;

  @override
  void initState() {
    super.initState();
    _loadStoreProducts();
    
    if (isEditing) {
      _titleController.text = widget.section!.title ?? '';
      _selectedType = widget.section!.type;
      _selectedProducts = List.from(widget.section!.products);
      _countdownEndTime = widget.section!.countdownEnd;
      _isActive = widget.section!.isActive;
      
      // Load banner fields from config
      if (widget.section!.config != null) {
        _bannerImageUrl = widget.section!.config!['banner_image'];
        _bannerLinkController.text = widget.section!.config!['banner_link'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bannerLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreProducts() async {
    final provider = context.read<StoresProvider>();
    await provider.loadStoreProducts(widget.store.id.toString());
    setState(() {
      _storeProducts = provider.storeProducts;
      _isLoadingProducts = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final provider = context.read<StoresProvider>();
    final productIds = _selectedProducts.map((p) => p.id).toList();
    
    Map<String, dynamic>? config;
    if (_selectedType == StoreSectionType.countdown && _countdownEndTime != null) {
      config = {'end_time': _countdownEndTime!.toIso8601String()};
    } else if (_selectedType == StoreSectionType.sponsoredZone) {
      config = {
        'banner_image': _bannerImageUrl,
        'banner_link': _bannerLinkController.text.isEmpty ? null : _bannerLinkController.text,
      };
    }
    
    bool success;
    if (isEditing) {
      final result = await provider.updateSection(
        widget.store.id,
        widget.section!.id,
        type: _selectedType.value,
        title: _titleController.text.isEmpty ? null : _titleController.text,
        isActive: _isActive,
        config: config,
        productIds: productIds,
      );
      success = result != null;
    } else {
      final result = await provider.createSection(
        widget.store.id,
        type: _selectedType.value,
        title: _titleController.text.isEmpty ? null : _titleController.text,
        isActive: _isActive,
        config: config,
        productIds: productIds,
      );
      success = result != null;
    }
    
    setState(() => _isSaving = false);
    
    if (success && mounted) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save section'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickCountdownTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _countdownEndTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date == null) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_countdownEndTime ?? DateTime.now()),
    );
    
    if (time == null) return;
    
    setState(() {
      _countdownEndTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductPickerSheet(
        storeProducts: _storeProducts,
        selectedProducts: _selectedProducts,
        onSelectionChanged: (products) {
          setState(() => _selectedProducts = products);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Section' : 'New Section'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Type Selector
            _buildSectionCard(
              title: 'Section Type',
              icon: Icons.category,
              child: _buildTypeSelector(),
            ),
            const SizedBox(height: 16),
            
            // Section Title
            _buildSectionCard(
              title: 'Section Title',
              icon: Icons.title,
              subtitle: 'Optional - Uses type name if empty',
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Hot Deals, New Arrivals',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Countdown Settings (if countdown type)
            if (_selectedType == StoreSectionType.countdown) ...[
              _buildSectionCard(
                title: 'Countdown End Time',
                icon: Icons.timer,
                child: InkWell(
                  onTap: _pickCountdownTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _countdownEndTime != null
                                ? DateFormat('MMM d, yyyy • h:mm a').format(_countdownEndTime!)
                                : 'Select end date and time',
                            style: TextStyle(
                              color: _countdownEndTime != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Sponsored Zone Banner Fields
            if (_selectedType == StoreSectionType.sponsoredZone) ...[
              _buildSectionCard(
                title: 'Banner Configuration',
                icon: Icons.image,
                subtitle: 'Configure the sponsored banner',
                child: Column(
                  children: [
                    // Banner Link URL
                    TextFormField(
                      controller: _bannerLinkController,
                      decoration: InputDecoration(
                        labelText: 'Link URL (optional)',
                        hintText: 'https://example.com/promo',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    // Banner Image Note
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
                              'Banner image will use the section title as the banner text. The title field above serves as the banner headline.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Products Selection
            _buildSectionCard(
              title: 'Products',
              icon: Icons.shopping_bag,
              subtitle: 'Select products to display in this section',
              child: Column(
                children: [
                  // Add products button
                  InkWell(
                    onTap: _isLoadingProducts ? null : _showProductPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _isLoadingProducts
                                ? 'Loading products...'
                                : 'Select Products (${_selectedProducts.length} selected)',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Selected products preview
                  if (_selectedProducts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedProducts.length,
                        itemBuilder: (context, index) {
                          final product = _selectedProducts[index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: product.thumbnailUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(product.thumbnailUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Colors.grey.shade200,
                            ),
                            child: Stack(
                              children: [
                                if (product.thumbnailUrl.isEmpty)
                                  const Center(child: Icon(Icons.image, color: Colors.grey)),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedProducts.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Active Toggle
            _buildSectionCard(
              title: 'Section Status',
              icon: Icons.visibility,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: Text(
                  _isActive ? 'Section is visible to customers' : 'Section is hidden',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEditing ? 'Update Section' : 'Create Section',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final provider = context.read<StoresProvider>();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: StoreSectionType.values.map((type) {
        final isSelected = _selectedType == type;
        final isSponsored = type.isSponsored;
        final isAvailable = !isSponsored || provider.canUseSponsoredZones;
        
        return GestureDetector(
          onTap: isAvailable
              ? () => setState(() => _selectedType = type)
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Upgrade to Gold for sponsored sections'),
                      backgroundColor: Colors.orange,
                      action: SnackBarAction(
                        label: 'Upgrade',
                        textColor: Colors.white,
                        onPressed: () {
                          // Navigate to upgrade
                        },
                      ),
                    ),
                  );
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isSponsored ? Colors.amber.shade100 : AppTheme.primaryColor.withOpacity(0.1))
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (isSponsored ? Colors.amber.shade700 : AppTheme.primaryColor)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTypeIcon(type),
                  size: 18,
                  color: isAvailable
                      ? (isSelected
                          ? (isSponsored ? Colors.amber.shade700 : AppTheme.primaryColor)
                          : Colors.grey.shade700)
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: TextStyle(
                    color: isAvailable
                        ? (isSelected
                            ? (isSponsored ? Colors.amber.shade700 : AppTheme.primaryColor)
                            : Colors.grey.shade700)
                        : Colors.grey.shade400,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (isSponsored && !isAvailable) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.lock, size: 14, color: Colors.grey.shade400),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getTypeIcon(StoreSectionType type) {
    switch (type) {
      case StoreSectionType.slider:
        return Icons.view_carousel;
      case StoreSectionType.sponsoredSlider:
        return Icons.star;
      case StoreSectionType.featuredTrending:
        return Icons.trending_up;
      case StoreSectionType.sponsoredZone:
        return Icons.workspace_premium;
      case StoreSectionType.countdown:
        return Icons.timer;
      case StoreSectionType.productGrid:
        return Icons.grid_view;
    }
  }
}

/// Bottom sheet for selecting products
class _ProductPickerSheet extends StatefulWidget {
  final List<Product> storeProducts;
  final List<Product> selectedProducts;
  final ValueChanged<List<Product>> onSelectionChanged;

  const _ProductPickerSheet({
    required this.storeProducts,
    required this.selectedProducts,
    required this.onSelectionChanged,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  late List<Product> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedProducts);
  }

  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) return widget.storeProducts;
    return widget.storeProducts
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleProduct(Product product) {
    setState(() {
      if (_selected.any((p) => p.id == product.id)) {
        _selected.removeWhere((p) => p.id == product.id);
      } else {
        _selected.add(product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Select Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selected.length} selected',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Products list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final isSelected = _selected.any((p) => p.id == product.id);
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: product.thumbnailUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.thumbnailUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey.shade200,
                    ),
                    child: product.thumbnailUrl.isEmpty
                        ? const Icon(Icons.image, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    product.effectivePriceFormatted,
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleProduct(product),
                    activeColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onTap: () => _toggleProduct(product),
                );
              },
            ),
          ),
          
          // Done button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSelectionChanged(_selected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done (${_selected.length} products)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
