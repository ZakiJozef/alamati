import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> with SingleTickerProviderStateMixin {
  final SubscriptionService _service = SubscriptionService();
  late TabController _tabController;
  List<Subscription> _allSubscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    // Load all subscriptions without filter
    final subs = await _service.getAdminSubscriptions();
    setState(() {
      _allSubscriptions = subs;
      _isLoading = false;
    });
  }

  List<Subscription> get _filteredSubscriptions {
    final index = _tabController.index;
    switch (index) {
      case 0: // All
        return _allSubscriptions;
      case 1: // Pending
        return _allSubscriptions.where((s) => s.status == 'pending').toList();
      case 2: // Active
        return _allSubscriptions.where((s) => s.status == 'active').toList();
      case 3: // Expired
        return _allSubscriptions.where((s) => s.status == 'expired' || s.status == 'cancelled').toList();
      default:
        return _allSubscriptions;
    }
  }

  String get _currentFilterName {
    final names = ['', 'pending', 'active', 'expired'];
    return names[_tabController.index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscriptions'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSubscriptionList(0), // All
                _buildSubscriptionList(1), // Pending
                _buildSubscriptionList(2), // Active
                _buildSubscriptionList(3), // Expired
              ],
            ),
    );
  }

  Widget _buildSubscriptionList(int tabIndex) {
    List<Subscription> subscriptions;
    switch (tabIndex) {
      case 0:
        subscriptions = _allSubscriptions;
        break;
      case 1:
        subscriptions = _allSubscriptions.where((s) => s.status == 'pending').toList();
        break;
      case 2:
        subscriptions = _allSubscriptions.where((s) => s.status == 'active').toList();
        break;
      case 3:
        subscriptions = _allSubscriptions.where((s) => s.status == 'expired' || s.status == 'cancelled').toList();
        break;
      default:
        subscriptions = _allSubscriptions;
    }

    if (subscriptions.isEmpty) {
      final filterNames = ['', 'pending', 'active', 'expired'];
      return _buildEmptyState(filterNames[tabIndex]);
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          return _SubscriptionCard(
            subscription: subscription,
            onApprove: () => _approveSubscription(subscription),
            onReject: () => _showRejectDialog(subscription),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No ${filter.isEmpty ? '' : filter} subscriptions',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveSubscription(Subscription subscription) async {
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    final success = await _service.approveSubscription(
      subscription.id,
      paymentMethod: paymentMethod,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription approved'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload subscriptions
      _loadSubscriptions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve subscription'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showPaymentMethodDialog() async {
    String? selected;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PaymentOption(
                label: 'CCP',
                icon: Icons.account_balance,
                isSelected: selected == 'ccp',
                onTap: () => setState(() => selected = 'ccp'),
              ),
              _PaymentOption(
                label: 'BaridiMob',
                icon: Icons.phone_android,
                isSelected: selected == 'baridimob',
                onTap: () => setState(() => selected = 'baridimob'),
              ),
              _PaymentOption(
                label: 'Cash',
                icon: Icons.payments,
                isSelected: selected == 'cash',
                onTap: () => setState(() => selected = 'cash'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selected != null
                  ? () => Navigator.pop(context, selected)
                  : null,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(Subscription subscription) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Subscription'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    final success = await _service.rejectSubscription(subscription.id, reason);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      // Reload subscriptions
      _loadSubscriptions();
    }
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SubscriptionCard({
    required this.subscription,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final plan = subscription.plan;
    final planName = plan?.name ?? 'Unknown Plan';
    final badgeColor = plan != null ? Color(plan.badgeColor) : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    plan?.slug == 'gold'
                        ? Icons.workspace_premium
                        : plan?.slug == 'silver'
                            ? Icons.star
                            : Icons.rocket_launch,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subscription.userName ?? 'User #${subscription.userId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(subscription.statusColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subscription.statusText,
                    style: TextStyle(
                      color: Color(subscription.statusColor),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Details
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    icon: Icons.payment,
                    label: 'Payment',
                    value: subscription.paymentMethodLabel,
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    icon: Icons.verified,
                    label: 'Verified',
                    value: subscription.paymentVerified ? 'Yes' : 'No',
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    value: '${subscription.createdAt.day}/${subscription.createdAt.month}',
                  ),
                ),
              ],
            ),

            // Payment Proof Preview
            if (subscription.paymentProof != null && subscription.paymentProof!.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showPaymentProofDialog(context, subscription.paymentProof!),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'View Payment Proof',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.open_in_new, color: Colors.blue.shade700, size: 18),
                    ],
                  ),
                ),
              ),
            ],

            // Actions for pending
            if (subscription.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentProofDialog(BuildContext context, String proofPath) {
    // Get the base URL without /api
    final baseUrl = AppConstants.apiBaseUrl.replaceAll('/api', '');
    final imageUrl = '$baseUrl/storage/$proofPath';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.white,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
          : null,
      onTap: onTap,
      selected: isSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
