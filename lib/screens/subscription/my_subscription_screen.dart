import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import 'subscription_plans_screen.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  final SubscriptionService _service = SubscriptionService();
  Subscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    final subscription = await _service.getMySubscription();
    setState(() {
      _subscription = subscription;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getGradientColor(),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _subscription == null
                  ? _buildNoSubscription()
                  : _buildSubscriptionDetails(),
        ),
      ),
    );
  }

  Color _getGradientColor() {
    if (_subscription?.plan == null) return Colors.grey.shade100;
    switch (_subscription!.plan!.slug) {
      case 'gold':
        return const Color(0xFFFFD700).withValues(alpha: 0.2);
      case 'silver':
        return const Color(0xFFC0C0C0).withValues(alpha: 0.2);
      default:
        return AppTheme.primaryColor.withValues(alpha: 0.1);
    }
  }

  Widget _buildNoSubscription() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildAppBar(),
          const Spacer(),
          Icon(
            Icons.card_membership,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active Subscription',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Subscribe to unlock premium features',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToPlans(),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('View Plans'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    final plan = _subscription!.plan!;
    final isGold = plan.slug == 'gold';
    final isSilver = plan.slug == 'silver';
    final badgeColor = Color(plan.badgeColor);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 24),

            // Premium Badge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: isGold
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : isSilver
                        ? const LinearGradient(
                            colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isGold
                        ? Icons.workspace_premium
                        : isSilver
                            ? Icons.star
                            : Icons.rocket_launch,
                    size: 64,
                    color: isGold || isSilver ? Colors.white : Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isGold ? Colors.black87 : Colors.white,
                    ),
                  ),
                  Text(
                    _subscription!.isActive ? 'ACTIVE' : _subscription!.statusText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: isGold ? Colors.black54 : Colors.white70,
                    ),
                  ),
                  if (plan.isFreeTrial && _subscription!.isActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_subscription!.daysRemaining} days remaining',
                        style: TextStyle(
                          color: isGold ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Status & Dates
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.circle,
                    iconColor: Color(_subscription!.statusColor),
                    label: 'Status',
                    value: _subscription!.statusText,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFFFFD700),
                    label: 'Price Paid',
                    value: plan.formattedPrice,
                    isPriceHighlight: true,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    label: 'Started',
                    value: _subscription!.startsAt != null
                        ? _formatDate(_subscription!.startsAt!)
                        : 'Not started',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.event,
                    iconColor: _subscription!.daysRemaining <= 7 ? Colors.red : Colors.green,
                    label: 'Expires',
                    value: _subscription!.expiresAt != null
                        ? _formatDate(_subscription!.expiresAt!)
                        : 'N/A',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.access_time,
                    iconColor: Colors.purple,
                    label: 'Duration',
                    value: plan.durationText,
                  ),
                  if (_subscription!.isActive && _subscription!.daysRemaining <= 30) ...[
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.timer,
                      iconColor: _subscription!.daysRemaining <= 7 ? Colors.red : Colors.orange,
                      label: 'Days Left',
                      value: '${_subscription!.daysRemaining} days',
                      isHighlighted: _subscription!.daysRemaining <= 7,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plan Features
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Plan Includes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.store,
                    text: '${plan.maxStores} Store${plan.maxStores > 1 ? 's' : ''}',
                  ),
                  _FeatureItem(
                    icon: Icons.inventory_2,
                    text: plan.hasUnlimitedProducts
                        ? 'Unlimited Products'
                        : '${plan.maxProducts} Products',
                  ),
                  _FeatureItem(
                    icon: Icons.photo_library,
                    text: '${plan.maxPortfolio} Portfolio Items',
                  ),
                  _FeatureItem(
                    icon: Icons.dashboard_customize,
                    text: plan.maxSections == -1
                        ? 'Unlimited Store Sections'
                        : '${plan.maxSections} Store Sections',
                  ),
                  if (plan.canUseSponsoredZones)
                    _FeatureItem(
                      icon: Icons.workspace_premium,
                      text: 'Sponsored Zones Access',
                      isGold: true,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upgrade button (if not gold)
            if (plan.slug != 'gold') ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToPlans(),
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Upgrade Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],

            // Payment info (if pending)
            if (_subscription!.isPending) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.amber.shade700, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Awaiting Payment Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payment via ${_subscription!.paymentMethodLabel}',
                      style: TextStyle(color: Colors.amber.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            'My Subscription',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadSubscription,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _navigateToPlans() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
    );
    if (result == true) {
      _loadSubscription();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isHighlighted;
  final bool isPriceHighlight;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.isPriceHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        if (isPriceHighlight)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isHighlighted ? Colors.red : Colors.black87,
            ),
          ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isGold;

  const _FeatureItem({required this.icon, required this.text, this.isGold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: isGold ? const Color(0xFFFFD700) : Colors.green, size: 20),
          const SizedBox(width: 12),
          Icon(icon, color: isGold ? const Color(0xFFFFD700) : Colors.grey.shade600, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isGold ? const Color(0xFFFFD700) : null,
              fontWeight: isGold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
