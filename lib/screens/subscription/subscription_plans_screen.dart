import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../models/subscription_plan.dart';
import '../../services/subscription_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  final bool showUpgradeFlow;
  
  const SubscriptionPlansScreen({
    super.key,
    this.showUpgradeFlow = false,
  });

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _service = SubscriptionService();
  final ImagePicker _imagePicker = ImagePicker();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedPlanId;
  String _selectedPaymentMethod = 'ccp';
  bool _isSubscribing = false;
  XFile? _paymentProofImage;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _service.getPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load plans';
        _isLoading = false;
      });
    }
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
              AppTheme.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock powerful features for your business',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Plans
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _plans.length,
                            itemBuilder: (context, index) {
                              final plan = _plans[index];
                              return _PlanCard(
                                plan: plan,
                                isSelected: _selectedPlanId == plan.id,
                                onTap: () => setState(() => _selectedPlanId = plan.id),
                                isPopular: plan.slug == 'gold',
                              );
                            },
                          ),
              ),

              // Payment method & Subscribe button
              if (_selectedPlanId != null) 
                _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final selectedPlan = _plans.firstWhere((p) => p.id == _selectedPlanId);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment method selector (only for paid plans)
          if (!selectedPlan.isFreeTrial) ...[
            Text(
              'Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PaymentMethodChip(
                  label: 'CCP',
                  icon: Icons.account_balance,
                  isSelected: _selectedPaymentMethod == 'ccp',
                  onTap: () => setState(() => _selectedPaymentMethod = 'ccp'),
                ),
                const SizedBox(width: 8),
                _PaymentMethodChip(
                  label: 'BaridiMob',
                  icon: Icons.phone_android,
                  isSelected: _selectedPaymentMethod == 'baridimob',
                  onTap: () => setState(() => _selectedPaymentMethod = 'baridimob'),
                ),
                const SizedBox(width: 8),
                _PaymentMethodChip(
                  label: 'Cash',
                  icon: Icons.payments,
                  isSelected: _selectedPaymentMethod == 'cash',
                  onTap: () => setState(() => _selectedPaymentMethod = 'cash'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Payment proof image upload
            Text(
              'Payment Proof (Required)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickPaymentProof,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _paymentProofImage != null 
                        ? Colors.green 
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: _paymentProofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FutureBuilder<Uint8List>(
                              future: _paymentProofImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _paymentProofImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, 
                              size: 32, color: Colors.grey.shade500),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to upload payment screenshot',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Subscribe button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubscribing ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPlan.slug == 'gold' 
                    ? const Color(0xFFFFD700) 
                    : AppTheme.primaryColor,
                foregroundColor: selectedPlan.slug == 'gold' 
                    ? Colors.black 
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubscribing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      selectedPlan.isFreeTrial
                          ? 'Start Free Trial'
                          : 'Subscribe for ${selectedPlan.formattedPrice}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPaymentProof() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _paymentProofImage = image);
    }
  }

  Future<void> _subscribe() async {
    if (_selectedPlanId == null) return;
    
    final selectedPlan = _plans.firstWhere((p) => p.id == _selectedPlanId);
    
    // Require payment proof for paid plans
    if (!selectedPlan.isFreeTrial && _paymentProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload payment proof'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSubscribing = true);
    
    final result = await _service.subscribe(
      planId: _selectedPlanId!,
      paymentMethod: selectedPlan.isFreeTrial ? 'free' : _selectedPaymentMethod,
      paymentProofImage: _paymentProofImage,
    );
    
    setState(() => _isSubscribing = false);
    
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isPopular;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? (plan.slug == 'gold' ? const Color(0xFFFFD700) : AppTheme.primaryColor)
        : Colors.grey.shade200;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Popular badge
            if (isPopular)
              Positioned(
                top: 0,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan icon and name
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(plan.badgeColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getPlanIcon(plan.slug),
                          color: Color(plan.badgeColor),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              plan.durationText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        plan.formattedPrice,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(plan.badgeColor),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Features
                  _FeatureRow(
                    icon: Icons.store,
                    text: '${plan.maxStores} Store${plan.maxStores > 1 ? 's' : ''}',
                  ),
                  _FeatureRow(
                    icon: Icons.inventory_2,
                    text: plan.hasUnlimitedProducts 
                        ? 'Unlimited Products' 
                        : '${plan.maxProducts} Products',
                  ),
                  _FeatureRow(
                    icon: Icons.photo_library,
                    text: '${plan.maxPortfolio} Portfolio Items',
                  ),
                  _FeatureRow(
                    icon: Icons.dashboard_customize,
                    text: plan.maxSections == -1
                        ? 'Unlimited Store Sections'
                        : '${plan.maxSections} Store Sections',
                  ),
                  if (plan.canUseSponsoredZones)
                    _FeatureRow(
                      icon: Icons.workspace_premium,
                      text: 'Sponsored Zones Access',
                      isGold: true,
                    ),
                  
                  if (plan.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      plan.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlanIcon(String slug) {
    switch (slug) {
      case 'gold':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.star;
      default:
        return Icons.rocket_launch;
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isGold;

  const _FeatureRow({required this.icon, required this.text, this.isGold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: isGold ? const Color(0xFFFFD700) : Colors.green, size: 20),
          const SizedBox(width: 12),
          Icon(icon, color: isGold ? const Color(0xFFFFD700) : Colors.grey.shade600, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isGold ? const Color(0xFFFFD700) : null,
              fontWeight: isGold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
