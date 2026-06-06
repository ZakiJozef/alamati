import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_plans_provider.dart';
import '../../models/subscription_plan.dart';

/// Admin screen for managing subscription plans (CRUD)
class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionPlansProvider>().loadPlans(forceRefresh: true);
    });
  }

  void _showPlanDialog({SubscriptionPlan? plan}) {
    final nameController = TextEditingController(text: plan?.name ?? '');
    final slugController = TextEditingController(text: plan?.slug ?? '');
    final descriptionController = TextEditingController(text: plan?.description ?? '');
    final priceController = TextEditingController(text: plan?.price.toString() ?? '0');
    final durationController = TextEditingController(text: plan?.durationDays.toString() ?? '30');
    final maxStoresController = TextEditingController(text: plan?.maxStores.toString() ?? '1');
    final maxProductsController = TextEditingController(text: plan?.maxProducts.toString() ?? '50');
    final maxPortfolioController = TextEditingController(text: plan?.maxPortfolio.toString() ?? '10');
    final maxSectionsController = TextEditingController(text: plan?.maxSections.toString() ?? '5');
    final sortOrderController = TextEditingController(text: plan?.sortOrder.toString() ?? '0');
    bool canUseSponsoredZones = plan?.canUseSponsoredZones ?? false;
    bool isActive = plan?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(plan == null ? 'Add Plan' : 'Edit Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g., Gold, Silver, Free',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: slugController,
                  decoration: const InputDecoration(
                    labelText: 'Slug',
                    hintText: 'e.g., gold, silver, free',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (DA) *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (days) *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxStoresController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Stores',
                          helperText: '-1 = unlimited',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxProductsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Products',
                          helperText: '-1 = unlimited',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxPortfolioController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Portfolio',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxSectionsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Sections',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Can Use Sponsored Zones'),
                  subtitle: const Text('Allow featured store/product placement'),
                  value: canUseSponsoredZones,
                  onChanged: (v) => setDialogState(() => canUseSponsoredZones = v),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Show in user plan selection'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }

                final provider = context.read<SubscriptionPlansProvider>();
                bool success;

                if (plan == null) {
                  final result = await provider.createPlan(
                    name: nameController.text,
                    slug: slugController.text.isNotEmpty ? slugController.text : null,
                    description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    price: double.tryParse(priceController.text) ?? 0,
                    durationDays: int.tryParse(durationController.text) ?? 30,
                    maxStores: int.tryParse(maxStoresController.text) ?? 1,
                    maxProducts: int.tryParse(maxProductsController.text) ?? 50,
                    maxPortfolio: int.tryParse(maxPortfolioController.text) ?? 10,
                    maxSections: int.tryParse(maxSectionsController.text) ?? 5,
                    canUseSponsoredZones: canUseSponsoredZones,
                    isActive: isActive,
                    sortOrder: int.tryParse(sortOrderController.text) ?? 0,
                  );
                  success = result != null;
                } else {
                  success = await provider.updatePlan(
                    plan.id,
                    name: nameController.text,
                    slug: slugController.text.isNotEmpty ? slugController.text : null,
                    description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    price: double.tryParse(priceController.text) ?? 0,
                    durationDays: int.tryParse(durationController.text) ?? 30,
                    maxStores: int.tryParse(maxStoresController.text) ?? 1,
                    maxProducts: int.tryParse(maxProductsController.text) ?? 50,
                    maxPortfolio: int.tryParse(maxPortfolioController.text) ?? 10,
                    maxSections: int.tryParse(maxSectionsController.text) ?? 5,
                    canUseSponsoredZones: canUseSponsoredZones,
                    isActive: isActive,
                    sortOrder: int.tryParse(sortOrderController.text) ?? 0,
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Plan ${plan == null ? 'created' : 'updated'} successfully'
                        : 'Failed to save plan'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: Text(plan == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePlan(SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: Text('Are you sure you want to delete "${plan.name}"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await context.read<SubscriptionPlansProvider>().deletePlan(plan.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? 'Plan deleted successfully'
                      : 'Failed to delete plan (may have active subscriptions)'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getPlanColor(String slug) {
    switch (slug) {
      case 'gold':
        return const Color(0xFFD97706);
      case 'silver':
        return const Color(0xFF6B7280);
      case 'free':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _formatLimit(int value) {
    return value == -1 ? '∞' : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Plans'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SubscriptionPlansProvider>().loadPlans(forceRefresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanDialog(),
        backgroundColor: const Color(0xFFD97706),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Plan', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<SubscriptionPlansProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_membership_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No plans found',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showPlanDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add your first plan'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.plans.length,
            itemBuilder: (context, index) {
              final plan = provider.plans[index];
              final color = _getPlanColor(plan.slug);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: plan.isActive 
                    ? BorderSide(color: color.withValues(alpha: 0.3), width: 1)
                    : BorderSide.none,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              plan.slug == 'free' ? Icons.card_giftcard 
                                : plan.slug == 'gold' ? Icons.workspace_premium
                                : Icons.star,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!plan.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Inactive',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  '${plan.formattedPrice} / ${plan.durationText}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Actions
                          IconButton(
                            icon: Icon(Icons.edit, color: color),
                            onPressed: () => _showPlanDialog(plan: plan),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePlan(plan),
                          ),
                        ],
                      ),
                    ),
                    // Limits
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildLimitChip(Icons.store, 'Stores', _formatLimit(plan.maxStores)),
                              const SizedBox(width: 8),
                              _buildLimitChip(Icons.inventory_2, 'Products', _formatLimit(plan.maxProducts)),
                              const SizedBox(width: 8),
                              _buildLimitChip(Icons.photo_library, 'Portfolio', _formatLimit(plan.maxPortfolio)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildLimitChip(Icons.view_module, 'Sections', _formatLimit(plan.maxSections)),
                              const SizedBox(width: 8),
                              if (plan.canUseSponsoredZones)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.campaign, size: 14, color: Colors.amber.shade800),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sponsored Zones',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.amber.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (plan.description != null && plan.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              plan.description!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLimitChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$label: $value',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
