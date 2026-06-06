import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/demand.dart';
import '../../providers/demands_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locations_provider.dart';
import '../../models/location.dart';
import 'create_demand_screen.dart';
import 'demand_detail_screen.dart';
import 'my_demands_screen.dart';

class DemandsScreen extends StatefulWidget {
  const DemandsScreen({super.key});

  @override
  State<DemandsScreen> createState() => _DemandsScreenState();
}

class _DemandsScreenState extends State<DemandsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  final Set<int> _expandedDemands = {};
  
  // Filter state
  int? _selectedWilayaId;
  String? _selectedWilayaName; // For display purposes
  String _sortBy = 'recent'; // 'recent', 'oldest', 'most_offers'
  int _activeFiltersCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemandsProvider>().loadDemands();
      context.read<LocationsProvider>().loadWilayas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    context.read<DemandsProvider>().setCategory(category);
    _applyFilters();
  }

  void _updateActiveFiltersCount() {
    int count = 0;
    if (_selectedWilayaId != null) count++;
    if (_sortBy != 'recent') count++;
    setState(() => _activeFiltersCount = count);
  }

  void _applyFilters() {
    context.read<DemandsProvider>().loadDemands(
      search: _searchController.text,
      wilayaId: _selectedWilayaId,
      sort: _sortBy,
    );
    _updateActiveFiltersCount();
  }

  void _clearFilters() {
    setState(() {
      _selectedWilayaId = null;
      _selectedWilayaName = null;
      _sortBy = 'recent';
      _activeFiltersCount = 0;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Demandes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mes demandes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyDemandsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Search field with filter button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _applyFilters(),
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une demande...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter button
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.tune, color: Colors.grey),
                            if (_activeFiltersCount > 0)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_activeFiltersCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Active filters chips
                if (_activeFiltersCount > 0) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_selectedWilayaName != null)
                          _buildActiveFilterChip(
                            label: _selectedWilayaName!,
                            onRemove: () {
                              setState(() {
                                _selectedWilayaId = null;
                                _selectedWilayaName = null;
                              });
                              _applyFilters();
                            },
                          ),
                        if (_sortBy != 'recent')
                          _buildActiveFilterChip(
                            label: _sortBy == 'oldest' ? 'Plus anciennes' : 'Plus d\'offres',
                            onRemove: () {
                              setState(() => _sortBy = 'recent');
                              _applyFilters();
                            },
                          ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all, size: 16, color: Colors.white70),
                          label: const Text('Effacer tout', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Category filter chips
          Container(
            height: 100,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: AppConstants.serviceCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(
                    name: 'Tout',
                    imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=200',
                    color: AppTheme.primaryColor,
                    isSelected: _selectedCategory == null,
                    onTap: () => _onCategorySelected(null),
                  );
                }
                final cat = AppConstants.serviceCategories[index - 1];
                return _buildCategoryChip(
                  name: cat.name,
                  imageUrl: cat.imageUrl,
                  color: Color(cat.color),
                  isSelected: _selectedCategory == cat.name,
                  onTap: () => _onCategorySelected(cat.name),
                );
              },
            ),
          ),

          // Demands list
          Expanded(
            child: Consumer<DemandsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.demands.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null && provider.demands.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Erreur de chargement', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadDemands(),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.demands.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_off_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune demande',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Soyez le premier à poster une demande!',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadDemands(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.demands.length,
                    itemBuilder: (context, index) {
                      final demand = provider.demands[index];
                      return _buildDemandCard(demand);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final auth = context.read<AuthProvider>();
          if (!auth.isAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Veuillez vous connecter pour poster une demande')),
            );
            return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateDemandScreen()),
          );
          if (result == true) {
            context.read<DemandsProvider>().loadDemands();
          }
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required String imageUrl,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: color.withValues(alpha: 0.3)),
                errorWidget: (_, __, ___) => Container(
                  color: color.withValues(alpha: 0.3),
                  child: Icon(Icons.build, color: color),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                ),
              Positioned(
                left: 4,
                right: 4,
                bottom: 6,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    shadows: const [Shadow(blurRadius: 2, color: Colors.black54)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemandCard(Demand demand) {
    final isExpanded = _expandedDemands.contains(demand.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedDemands.remove(demand.id);
            } else {
              _expandedDemands.add(demand.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and meta
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: demand.isOpen ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          demand.isOpen ? 'Ouverte' : 'Fermée',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        demand.timeAgo ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          demand.location,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (demand.offersCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.handshake, size: 12, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '${demand.offersCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    demand.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedContent(demand),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Demand demand) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          
          // Client info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: demand.displayImage != null
                    ? CachedNetworkImageProvider(demand.displayImage!)
                    : null,
                child: demand.displayImage == null
                    ? Icon(Icons.person, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(demand.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              Text(demand.timeAgo ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Address
          _buildInfoRow(
            Icons.location_on, 
            'Adresse', 
            demand.location, 
            Colors.teal, 
            'Voir sur Maps',
            onAction: () async {
              final location = Uri.encodeComponent(demand.location);
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$location');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 12),

          // Phone
          _buildInfoRow(Icons.phone, 'Téléphone', 'Voir le numéro', Colors.blue, null),
          const SizedBox(height: 16),

          // Description
          const Text('DÉTAILS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(demand.description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DemandDetailScreen(demand: demand)),
                  ),
                  icon: const Icon(Icons.pan_tool, size: 18),
                  label: const Text('Faire une offre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          // Offers preview
          if (demand.offers.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'OFFRES (${demand.offersCount})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Cliquer sur un professionnel pour voir son profil complet',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            ...demand.offers.take(2).map((offer) => _buildOfferPreview(offer)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, String? actionText, {VoidCallback? onAction}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        if (actionText != null) ...[
          const Spacer(),
          TextButton(
            onPressed: onAction,
            child: Text(actionText, style: TextStyle(color: color)),
          ),
        ],
      ],
    );
  }

  Widget _buildOfferPreview(DemandOffer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: offer.displayImage != null
                ? CachedNetworkImageProvider(offer.displayImage!)
                : null,
            child: offer.displayImage == null
                ? Icon(Icons.person, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      offer.displayName,
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    if (offer.proposedPrice != null) ...[
                      const Text(' · '),
                      Text('${offer.proposedPrice!.toStringAsFixed(0)} DZD'),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: offer.isAccepted
                        ? Colors.green.shade100
                        : offer.isRejected
                            ? Colors.red.shade100
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    offer.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: offer.isAccepted
                          ? Colors.green.shade700
                          : offer.isRejected
                              ? Colors.red.shade700
                              : AppTheme.primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    int? tempWilayaId = _selectedWilayaId;
    String? tempWilayaName = _selectedWilayaName;
    String tempSort = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Wilaya selector
              const Text(
                'Région (Wilaya)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Consumer<LocationsProvider>(
                  builder: (context, locations, _) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: tempWilayaId,
                        isExpanded: true,
                        hint: const Text('Toutes les régions'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Toutes les régions'),
                          ),
                          ...locations.wilayas.map((w) => DropdownMenuItem(
                            value: w.id,
                            child: Text('${w.code} - ${w.name}'),
                          )),
                        ],
                        onChanged: (v) {
                          setModalState(() {
                            tempWilayaId = v;
                            tempWilayaName = v != null 
                                ? locations.wilayas.firstWhere((w) => w.id == v).name 
                                : null;
                          });
                        },
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(height: 24),

              // Sort options
              const Text(
                'Trier par',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildSortOption(
                label: 'Plus récentes',
                value: 'recent',
                groupValue: tempSort,
                onChanged: (v) => setModalState(() => tempSort = v),
              ),
              _buildSortOption(
                label: 'Plus anciennes',
                value: 'oldest',
                groupValue: tempSort,
                onChanged: (v) => setModalState(() => tempSort = v),
              ),
              _buildSortOption(
                label: 'Plus d\'offres',
                value: 'most_offers',
                groupValue: tempSort,
                onChanged: (v) => setModalState(() => tempSort = v),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          tempWilayaId = null;
                          tempWilayaName = null;
                          tempSort = 'recent';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedWilayaId = tempWilayaId;
                          _selectedWilayaName = tempWilayaName;
                          _sortBy = tempSort;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
