import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stores_provider.dart';
import '../../models/store.dart';
import '../../models/store_section.dart';
import '../../core/theme.dart';
import 'section_editor_screen.dart';

/// Screen for managing store sections with drag-to-reorder
class ManageSectionsScreen extends StatefulWidget {
  final Store store;

  const ManageSectionsScreen({super.key, required this.store});

  @override
  State<ManageSectionsScreen> createState() => _ManageSectionsScreenState();
}

class _ManageSectionsScreenState extends State<ManageSectionsScreen> {
  bool _isLoading = true;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<StoresProvider>();
    await Future.wait([
      provider.loadStoreSections(widget.store.id),
      provider.loadSectionTypes(widget.store.id),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    
    setState(() => _isReordering = true);
    
    final provider = context.read<StoresProvider>();
    final sections = List<StoreSection>.from(provider.storeSections);
    
    // Adjust index for removal
    if (newIndex > oldIndex) newIndex--;
    
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    
    // Save new order
    await provider.reorderSections(
      widget.store.id,
      sections.map((s) => s.id).toList(),
    );
    
    setState(() => _isReordering = false);
  }

  void _addSection() {
    final provider = context.read<StoresProvider>();
    
    if (!provider.canAddMoreSections) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${provider.maxSections} sections allowed for your plan'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Upgrade',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to subscription upgrade
            },
          ),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionEditorScreen(
          store: widget.store,
          section: null,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _editSection(StoreSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionEditorScreen(
          store: widget.store,
          section: section,
        ),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _deleteSection(StoreSection section) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete "${section.title ?? section.type.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await context.read<StoresProvider>().deleteSection(widget.store.id, section.id);
    }
  }

  Future<void> _toggleActive(StoreSection section) async {
    await context.read<StoresProvider>().updateSection(
      widget.store.id,
      section.id,
      isActive: !section.isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Manage Sections'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_isReordering)
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<StoresProvider>(
              builder: (context, provider, _) {
                return Column(
                  children: [
                    // Header info
                    _buildHeaderCard(provider),
                    
                    // Sections list
                    Expanded(
                      child: provider.storeSections.isEmpty
                          ? _buildEmptyState()
                          : _buildSectionsList(provider),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSection,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Section'),
      ),
    );
  }

  Widget _buildHeaderCard(StoresProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: provider.canUseSponsoredZones
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (provider.canUseSponsoredZones ? Colors.amber : AppTheme.primaryColor)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              provider.canUseSponsoredZones ? Icons.workspace_premium : Icons.view_module,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.canUseSponsoredZones ? 'Gold Plan' : 'Standard Plan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.maxSections == -1
                      ? '${provider.currentSectionCount} sections (unlimited)'
                      : '${provider.currentSectionCount}/${provider.maxSections} sections used',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!provider.canUseSponsoredZones)
            TextButton(
              onPressed: () {
                // Navigate to upgrade
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dashboard_customize,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Sections Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create custom sections to showcase your products beautifully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add),
              label: const Text('Create First Section'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsList(StoresProvider provider) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      onReorder: _handleReorder,
      itemCount: provider.storeSections.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevateAnimation = Curves.easeInOut.transform(animation.value);
            return Material(
              elevation: 8 * elevateAnimation,
              borderRadius: BorderRadius.circular(16),
              shadowColor: AppTheme.primaryColor.withOpacity(0.3),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final section = provider.storeSections[index];
        return _buildSectionCard(section, index);
      },
    );
  }

  Widget _buildSectionCard(StoreSection section, int index) {
    final isSponsored = section.type.isSponsored;
    
    return Container(
      key: ValueKey(section.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSponsored
            ? Border.all(color: Colors.amber.shade400, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editSection(section),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_indicator,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Section type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getSectionColor(section.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSectionIcon(section.type),
                    color: _getSectionColor(section.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Section info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              section.title ?? section.type.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSponsored)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'GOLD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${section.type.label} • ${section.products.length} products',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Active toggle
                    Switch(
                      value: section.isActive,
                      onChanged: (_) => _toggleActive(section),
                      activeColor: AppTheme.primaryColor,
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade400,
                      onPressed: () => _deleteSection(section),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSectionIcon(StoreSectionType type) {
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

  Color _getSectionColor(StoreSectionType type) {
    switch (type) {
      case StoreSectionType.slider:
        return AppTheme.primaryColor;
      case StoreSectionType.sponsoredSlider:
        return Colors.amber.shade700;
      case StoreSectionType.featuredTrending:
        return Colors.purple;
      case StoreSectionType.sponsoredZone:
        return Colors.amber.shade700;
      case StoreSectionType.countdown:
        return Colors.red;
      case StoreSectionType.productGrid:
        return Colors.teal;
    }
  }
}
