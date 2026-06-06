import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/stores_provider.dart';
import '../../models/store.dart';
import '../store_detail/store_detail_screen.dart';
import '../store/edit_store_screen.dart';
import '../store/create_store_screen.dart';
import '../store/manage_products_screen.dart';
import '../store/manage_sections_screen.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/locations_provider.dart';
import '../../models/location.dart';

class ManageStoresScreen extends StatefulWidget {
  const ManageStoresScreen({super.key});

  @override
  State<ManageStoresScreen> createState() => _ManageStoresScreenState();
}

class _ManageStoresScreenState extends State<ManageStoresScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedWilaya;
  String _sortOrder = 'newest'; // newest, oldest, rating_high, rating_low, name_asc, name_desc
  String? _statusFilter; // null = all, 'open', 'closed'
  double _minRating = 0;
  
  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _perPageOptions = [10, 20, 50, 100];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure data loads after widget tree is built
    // and auth token is fully propagated (fixes post-login loading issue)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStores();
      context.read<LocationsProvider>().loadWilayas();
    });
  }

  Future<void> _loadStores() async {
    await context.read<StoresProvider>().loadMyStores(
      page: _currentPage,
      limit: _itemsPerPage,
      search: _searchQuery,
      category: _selectedCategory,
      wilaya: _selectedWilaya,
      status: _statusFilter,
      minRating: _minRating,
      sort: _sortOrder,
    );
  }

  Future<void> _deleteStore(Store store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Store'),
        content: Text('Are you sure you want to delete "${store.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<StoresProvider>().deleteStore(store.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Store deleted successfully' : 'Failed to delete store'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedWilaya = null;
      _sortOrder = 'newest';
      _statusFilter = null;
      _minRating = 0;
      _searchQuery = '';
      _currentPage = 1;
    });
    _loadStores();
  }

  // Pagination helpers
  int get _totalPages {
    final total = context.read<StoresProvider>().myStoresTotal;
    return (total / _itemsPerPage).ceil();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedWilaya != null) count++;
    if (_sortOrder != 'newest') count++;
    if (_statusFilter != null) count++;
    if (_minRating > 0) count++;
    return count;
  }
  @override
  Widget build(BuildContext context) {
    final storesProvider = context.watch<StoresProvider>();
    final stores = storesProvider.myStores;
    final totalCount = storesProvider.myStoresTotal;
    final totalPages = (totalCount / _itemsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Stores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateStoreScreen(),
                ),
              );
              if (result == true) {
                _loadStores();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with Filter Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search stores...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                                _loadStores();
                              }),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                        setState(() {
                          _searchQuery = value;
                          _currentPage = 1;
                        });
                        _loadStores();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Button with Badge
                Stack(
                  children: [
                    IconButton(
                      onPressed: _showFilterBottomSheet,
                      icon: Icon(
                        Icons.tune,
                        color: _activeFilterCount > 0 ? AppTheme.primaryColor : Colors.grey.shade600,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _activeFilterCount > 0 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Sort & Per Page Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Quick sort chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickSortChip('Newest', 'newest'),
                        const SizedBox(width: 8),
                        _buildQuickSortChip('Oldest', 'oldest'),
                        const SizedBox(width: 8),
                        _buildQuickSortChip('A-Z', 'name_asc'),
                        const SizedBox(width: 8),
                        _buildQuickSortChip('Rating ↑', 'rating_high'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Per page dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _itemsPerPage,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      isDense: true,
                      items: _perPageOptions.map((n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (value) => setState(() {
                        _itemsPerPage = value!;
                        _currentPage = 1;
                        _loadStores();
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results count and active filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '$totalCount stores found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (totalPages > 1) ...[
                  Text(
                    ' • Page $_currentPage of $totalPages',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
                const Spacer(),
                if (_activeFilterCount > 0)
                  TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),

          // Active Filters Chips
          if (_activeFilterCount > 0)
            _buildActiveFilterChips(),
          
          // Stores List
          Expanded(
            child: storesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty && _activeFilterCount == 0 
                                  ? Icons.store_outlined 
                                  : Icons.search_off, 
                              size: 64, 
                              color: Colors.grey.shade300
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty && _activeFilterCount == 0 
                                  ? 'No stores found' 
                                  : 'No stores match your filters',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (_activeFilterCount > 0) ...[
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _clearAllFilters,
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear all filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStores,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: stores.length,
                          itemBuilder: (context, index) {
                            final store = stores[index];
                            return _buildStoreManagementCard(store);
                          },
                        ),
                      ),
          ),

          // Pagination Controls
          if (totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage = 1);
                            _loadStores();
                          }
                        : null,
                    icon: const Icon(Icons.first_page),
                  ),
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadStores();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_currentPage of $totalPages'),
                  IconButton(
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadStores();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() => _currentPage = totalPages);
                            _loadStores();
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



  Widget _buildQuickSortChip(String label, String value) {
    final isSelected = _sortOrder == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _sortOrder = value;
        _currentPage = 1;
        _loadStores();
      }),
      selectedColor: AppTheme.primaryColor.withOpacity(0.15),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }



  void _showFilterBottomSheet() {
    // Create local copies that will be modified in the sheet
    String? tempCategory = _selectedCategory;
    String? tempWilaya = _selectedWilaya;
    String tempSortOrder = _sortOrder;
    String? tempStatusFilter = _statusFilter;
    double tempMinRating = _minRating;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
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
                    const Text(
                      'Filters',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          tempCategory = null;
                          tempWilaya = null;
                          tempSortOrder = 'newest';
                          tempStatusFilter = null;
                          tempMinRating = 0;
                        });
                      },
                      child: Text('Clear All', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
              ),
              // Filter Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sort By
                      const Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSheetSortChip('Newest', 'newest', Icons.arrow_downward, tempSortOrder, (v) => setSheetState(() => tempSortOrder = v)),
                          _buildSheetSortChip('Oldest', 'oldest', Icons.arrow_upward, tempSortOrder, (v) => setSheetState(() => tempSortOrder = v)),
                          _buildSheetSortChip('Rating ↑', 'rating_high', Icons.star, tempSortOrder, (v) => setSheetState(() => tempSortOrder = v)),
                          _buildSheetSortChip('Rating ↓', 'rating_low', Icons.star_border, tempSortOrder, (v) => setSheetState(() => tempSortOrder = v)),
                          _buildSheetSortChip('A-Z', 'name_asc', Icons.sort_by_alpha, tempSortOrder, (v) => setSheetState(() => tempSortOrder = v)),
                          _buildSheetSortChip('Z-A', 'name_desc', Icons.sort_by_alpha, tempSortOrder, (v) => setSheetState(() => tempSortOrder = v)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Category
                      const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: tempCategory == null,
                            onSelected: (_) => setSheetState(() => tempCategory = null),
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                          ...AppConstants.storeCategories.map((cat) => FilterChip(
                            label: Text('${cat.emoji} ${cat.name}'),
                            selected: tempCategory == cat.name,
                            onSelected: (_) => setSheetState(() => tempCategory = cat.name),
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Region/Wilaya
                      const Text('Region', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: tempWilaya == null,
                            onSelected: (_) => setSheetState(() => tempWilaya = null),
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                          ...['Alger', 'Oran', 'Constantine', 'Blida', 'Sétif', 'Annaba', 'Batna', 'Tizi Ouzou'].map((w) => FilterChip(
                            label: Text(w),
                            selected: tempWilaya == w,
                            onSelected: (_) => setSheetState(() => tempWilaya = w),
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          )),
                          ActionChip(
                            label: const Text('More...'),
                            onPressed: () async {
                              final selected = await _showWilayaPickerDialog();
                              if (selected != null) {
                                setSheetState(() => tempWilaya = selected);
                              }
                            },
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status
                      const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: tempStatusFilter == null,
                            onSelected: (_) => setSheetState(() => tempStatusFilter = null),
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                          FilterChip(
                            label: const Text('Open'),
                            selected: tempStatusFilter == 'open',
                            onSelected: (_) => setSheetState(() => tempStatusFilter = 'open'),
                            selectedColor: Colors.green.withOpacity(0.2),
                            checkmarkColor: Colors.green,
                          ),
                          FilterChip(
                            label: const Text('Closed'),
                            selected: tempStatusFilter == 'closed',
                            onSelected: (_) => setSheetState(() => tempStatusFilter = 'closed'),
                            selectedColor: Colors.red.withOpacity(0.2),
                            checkmarkColor: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Rating
                      Text('Minimum Rating', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Slider(
                        value: tempMinRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: tempMinRating.toStringAsFixed(1),
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) => setSheetState(() => tempMinRating = value),
                      ),
                      Text('Min: ${tempMinRating.toStringAsFixed(1)} ⭐'),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Apply Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = tempCategory;
                        _selectedWilaya = tempWilaya;
                        _sortOrder = tempSortOrder;
                        _statusFilter = tempStatusFilter;
                        _minRating = tempMinRating;
                      });
                      _loadStores();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetSortChip(String label, String value, IconData icon, String currentSort, Function(String) onSelect) {
    final isSelected = currentSort == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontSize: 12,
      ),
    );
  }

  Future<String?> _showWilayaPickerDialog() async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Consumer<LocationsProvider>(
          builder: (context, locations, _) {
            if (locations.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Region',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: locations.wilayas.length,
                    itemBuilder: (context, index) {
                      final wilaya = locations.wilayas[index];
                      return ListTile(
                        title: Text(wilaya.name),
                        trailing: _selectedWilaya == wilaya.name 
                            ? Icon(Icons.check, color: AppTheme.primaryColor) 
                            : null,
                        onTap: () => Navigator.pop(context, wilaya.name),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedCategory != null)
            _buildRemovableChip(_selectedCategory!, () => setState(() => _selectedCategory = null)),
          if (_selectedWilaya != null)
            _buildRemovableChip(_selectedWilaya!, () => setState(() => _selectedWilaya = null)),
          if (_sortOrder != 'newest')
            _buildRemovableChip('Sort: ${_getSortLabel(_sortOrder)}', () => setState(() => _sortOrder = 'newest')),
          if (_statusFilter != null)
            _buildRemovableChip(_statusFilter == 'open' ? 'Open' : 'Closed', () => setState(() => _statusFilter = null)),
          if (_minRating > 0)
            _buildRemovableChip('${_minRating.toStringAsFixed(1)}+ ⭐', () => setState(() => _minRating = 0)),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: const Text('Clear All'),
              onPressed: _clearAllFilters,
              avatar: const Icon(Icons.clear_all, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'oldest': return 'Oldest';
      case 'rating_high': return 'Rating ↑';
      case 'rating_low': return 'Rating ↓';
      case 'name_asc': return 'A-Z';
      case 'name_desc': return 'Z-A';
      default: return 'Newest';
    }
  }

  Widget _buildRemovableChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        deleteIconColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildStoreManagementCard(Store store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Top Row: Image + Name + Status
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoreDetailScreen(slugOrId: store.slug ?? store.id),
              ),
            ),
            child: Row(
              children: [
                // Store Image
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: store.profileImage != null
                        ? CachedNetworkImage(
                            imageUrl: store.profileImage!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Icon(
                              Icons.store,
                              color: Colors.grey.shade400,
                              size: 18,
                            ),
                          )
                        : Icon(
                            Icons.store,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // Store Name
                Expanded(
                  child: Text(
                    store.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: store.isOpen ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    store.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: store.isOpen ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Bottom Row: Action Buttons
          Row(
            children: [
              _buildCompactActionButton(
                icon: Icons.visibility_outlined,
                label: 'View',
                color: Colors.grey.shade600,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoreDetailScreen(slugOrId: store.slug ?? store.id),
                  ),
                ),
              ),
              _buildCompactActionButton(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                color: Colors.orange.shade600,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageProductsScreen(store: store),
                  ),
                ),
              ),
              _buildCompactActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: AppTheme.primaryColor,
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditStoreScreen(store: store),
                    ),
                  );
                  if (result == true) {
                    _loadStores();
                  }
                },
              ),
              const Spacer(),
              _buildCompactActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Colors.red.shade400,
                onPressed: () => _deleteStore(store),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}
