import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

/// Admin screen to manage sponsored stores
class ManageSponsoredStoresScreen extends StatefulWidget {
  const ManageSponsoredStoresScreen({super.key});

  @override
  State<ManageSponsoredStoresScreen> createState() => _ManageSponsoredStoresScreenState();
}

class _ManageSponsoredStoresScreenState extends State<ManageSponsoredStoresScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _stores = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _showOnlySponsored = true;
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStores();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreStores();
    }
  }

  Future<void> _loadStores({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });
    }

    try {
      String url = '/admin/stores/sponsored?page=$_currentPage&limit=20';
      if (_searchQuery.isNotEmpty) {
        url += '&search=$_searchQuery';
      }
      if (_showOnlySponsored) {
        url += '&sponsored=true';
      }

      final response = await _api.get(url);
      final data = response as Map<String, dynamic>;

      setState(() {
        if (reset) {
          _stores = data['data'] as List;
        } else {
          _stores.addAll(data['data'] as List);
        }
        _currentPage = data['current_page'] ?? 1;
        _lastPage = data['last_page'] ?? 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stores: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreStores() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadStores(reset: false);
  }

  Future<void> _toggleSponsored(Map<String, dynamic> store) async {
    final storeId = store['id'];
    final storeName = store['name'];
    final currentlySponsored = store['is_sponsored'] == true;

    try {
      final response = await _api.post('/admin/stores/$storeId/toggle-sponsored', {});

      // Update local state
      final index = _stores.indexWhere((s) => s['id'] == storeId);
      if (index != -1) {
        if (_showOnlySponsored && currentlySponsored) {
          // Remove from list if we're only showing sponsored and we just unsponsored it
          setState(() {
            _stores.removeAt(index);
          });
        } else {
          setState(() {
            _stores[index]['is_sponsored'] = response['is_sponsored'];
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Status updated for "$storeName"'),
            backgroundColor: response['is_sponsored'] == true ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _loadStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text('Sponsored Stores'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStores(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stores...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Sponsored Only'),
                      selected: _showOnlySponsored,
                      onSelected: (value) {
                        setState(() => _showOnlySponsored = value);
                        _loadStores();
                      },
                      selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('All Stores'),
                      selected: !_showOnlySponsored,
                      onSelected: (value) {
                        setState(() => _showOnlySponsored = !value);
                        _loadStores();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stores count header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Color(0xFF8B5CF6), size: 20),
                const SizedBox(width: 8),
                Text(
                  _showOnlySponsored
                      ? 'Sponsored Stores (${_stores.length})'
                      : 'All Stores (${_stores.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),

          // Stores list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _stores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _showOnlySponsored ? 'No sponsored stores yet' : 'No stores found',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                            ),
                            if (_showOnlySponsored) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() => _showOnlySponsored = false);
                                  _loadStores();
                                },
                                child: const Text('Browse all stores to add'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _stores.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _stores.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final store = _stores[index];
                          final isSponsored = store['is_sponsored'] == true;
                          final owner = store['owner'];
                          final ownerName = owner?['pseudoname'] ?? owner?['username'] ?? 'Unknown';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSponsored
                                  ? const BorderSide(color: Color(0xFF8B5CF6), width: 2)
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: store['profile_image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: store['profile_image'],
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => _buildPlaceholder(),
                                      )
                                    : _buildPlaceholder(),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      store['name'] ?? 'Unknown Store',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (isSponsored)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.campaign_rounded, size: 14, color: Color(0xFF8B5CF6)),
                                          SizedBox(width: 4),
                                          Text(
                                            'SPONSORED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF8B5CF6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    store['category'] ?? 'No category',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  Text(
                                    'Owner: $ownerName',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: Switch(
                                value: isSponsored,
                                onChanged: (value) => _toggleSponsored(store),
                                activeColor: const Color(0xFF8B5CF6),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.store_rounded, color: Colors.grey.shade400),
    );
  }
}
