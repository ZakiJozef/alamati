import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/category.dart' as models;
import '../../providers/categories_provider.dart';
import 'category_form_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().loadCategories(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Stores'),
            Tab(text: 'Products'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      body: Consumer<CategoriesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error loading categories',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.loadCategories(forceRefresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(provider.storeCategories, 'store'),
              _buildCategoryList(provider.productCategories, 'product'),
              _buildCategoryList(provider.serviceCategories, 'service'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryList(List<models.Category> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No $type categories yet',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CategoriesProvider>().loadCategories(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(category, type);
        },
      ),
    );
  }

  Widget _buildCategoryCard(models.Category category, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: category.colorValue != null
                ? Color(category.colorValue!).withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: category.emoji != null && category.emoji!.isNotEmpty
                ? Text(category.emoji!, style: const TextStyle(fontSize: 22))
                : Icon(
                    _getIconForType(type),
                    color: category.colorValue != null
                        ? Color(category.colorValue!)
                        : AppTheme.primaryColor,
                  ),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${category.children.length} subcategories',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editCategory(category),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteCategory(category),
              tooltip: 'Delete',
            ),
          ],
        ),
        children: [
          if (category.children.isNotEmpty)
            ...category.children.map((sub) => _buildSubcategoryTile(sub, category)),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.green),
            title: const Text('Add Subcategory', style: TextStyle(color: Colors.green)),
            onTap: () => _addSubcategory(category),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryTile(models.Category subcategory, models.Category parent) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Text(subcategory.name),
      subtitle: subcategory.nameEn != null
          ? Text(subcategory.nameEn!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!subcategory.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Inactive',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade800)),
            ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editCategory(subcategory),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _deleteCategory(subcategory),
          ),
        ],
      ),
    );
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

  void _addCategory() async {
    final type = ['store', 'product', 'service'][_tabController.index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(type: type),
      ),
    );
    if (result == true) {
      context.read<CategoriesProvider>().loadCategories(forceRefresh: true);
    }
  }

  void _addSubcategory(models.Category parent) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(type: parent.type, parentCategory: parent),
      ),
    );
    if (result == true) {
      context.read<CategoriesProvider>().loadCategories(forceRefresh: true);
    }
  }

  void _editCategory(models.Category category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(type: category.type, category: category),
      ),
    );
    if (result == true) {
      context.read<CategoriesProvider>().loadCategories(forceRefresh: true);
    }
  }

  void _deleteCategory(models.Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          category.hasChildren
              ? 'This will also delete all ${category.children.length} subcategories. Are you sure?'
              : 'Are you sure you want to delete "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<CategoriesProvider>();
      final success = await provider.deleteCategory(category.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${category.name} deleted')),
        );
      } else if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
