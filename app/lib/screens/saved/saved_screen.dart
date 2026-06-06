import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stores_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/store_card.dart';
import '../store_detail/store_detail_screen.dart';
import '../auth/login_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    _loadSavedStores();
  }

  Future<void> _loadSavedStores() async {
    if (context.read<AuthProvider>().isAuthenticated) {
      await context.read<StoresProvider>().loadSavedStores();
    }
  }

  // Track which stores are being unsaved
  final Set<int> _savingStoreIds = {};

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final storesProvider = context.watch<StoresProvider>();

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 24),
                const Text(
                  'Save Your Favorites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to save stores and access them anytime',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Stores')),
      body: RefreshIndicator(
        onRefresh: _loadSavedStores,
        child: storesProvider.savedStores.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No saved stores yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bookmark stores to find them easily later',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: storesProvider.savedStores.length,
                itemBuilder: (context, index) {
                  final store = storesProvider.savedStores[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StoreCard(
                      store: store,
                      viewType: CardViewType.list,
                      isSaving: _savingStoreIds.contains(store.id),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreDetailScreen(slugOrId: store.slug ?? store.id),
                        ),
                      ),
                      onSave: () async {
                        if (_savingStoreIds.contains(store.id)) return;

                        setState(() {
                          _savingStoreIds.add(store.id);
                        });

                        try {
                          await storesProvider.toggleSaveStore(store.id);
                          // No need to remove from set explicitly if success, 
                          // as the item might be removed from the list or re-rendered
                          if (mounted) {
                             setState(() {
                              _savingStoreIds.remove(store.id);
                             });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _savingStoreIds.remove(store.id);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to update save status')),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
