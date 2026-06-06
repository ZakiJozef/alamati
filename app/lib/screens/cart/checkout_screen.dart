import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locations_provider.dart';
import '../../models/cart.dart';
import '../../models/location.dart';
import '../../core/theme.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _deliveryType = 'home';
  Wilaya? _selectedWilaya;
  Commune? _selectedCommune;
  List<Commune> _communes = [];
  bool _isLoadingCommunes = false;
  bool _isSubmitting = false;
  bool _showOrderSummary = true;

  @override
  void initState() {
    super.initState();
    // Load wilayas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationsProvider>().loadWilayas();
    });

    // Pre-fill user data
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user != null) {
      _nameController.text = authProvider.user!.displayName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunes(int wilayaId) async {
    setState(() {
      _isLoadingCommunes = true;
      _communes = [];
      _selectedCommune = null;
    });

    try {
      final communes = await context.read<LocationsProvider>().getCommunes(wilayaId);
      setState(() {
        _communes = communes;
        _isLoadingCommunes = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCommunes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading communes: $e')),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deliveryType == 'home' && (_selectedWilaya == null || _selectedCommune == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select wilaya and commune for home delivery')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cartProvider = context.read<CartProvider>();
      final result = await cartProvider.checkout(
        fullName: _nameController.text,
        phone: _phoneController.text,
        deliveryType: _deliveryType,
        wilaya: _selectedWilaya?.name,
        commune: _selectedCommune?.name,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (result != null && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cartProvider.error ?? 'Failed to place order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Placed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for your order!\nWe will contact you shortly to confirm.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close checkout
                Navigator.pop(context); // Close cart
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('CONTINUE SHOPPING'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order Summary (collapsible)
            _buildOrderSummaryCard(),
            const SizedBox(height: 16),

            // Customer Information
            _buildSectionCard(
              title: 'Customer Information',
              icon: Icons.person_outline,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Full Name', Icons.person),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration('Phone Number', Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Delivery Method
            _buildSectionCard(
              title: 'Delivery Method',
              icon: Icons.local_shipping_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDeliveryOption(
                        type: 'home',
                        icon: Icons.home,
                        label: 'Home Delivery',
                        subtitle: 'Deliver to my address',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDeliveryOption(
                        type: 'desk',
                        icon: Icons.store,
                        label: 'Pickup',
                        subtitle: 'Pick up at store',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address (only for home delivery)
            if (_deliveryType == 'home') ...[
              _buildSectionCard(
                title: 'Delivery Address',
                icon: Icons.location_on_outlined,
                children: [
                  // Wilaya
                  Consumer<LocationsProvider>(
                    builder: (context, locations, child) {
                      if (locations.isLoading && locations.wilayas.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return DropdownButtonFormField<Wilaya>(
                        value: _selectedWilaya,
                        decoration: _inputDecoration('Wilaya', Icons.map),
                        hint: const Text('Select Wilaya'),
                        items: locations.wilayas.map((w) => DropdownMenuItem(
                          value: w,
                          child: Text('${w.code} - ${w.name}'),
                        )).toList(),
                        onChanged: (w) {
                          if (w == null) return;
                          setState(() => _selectedWilaya = w);
                          _loadCommunes(w.id);
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Commune
                  DropdownButtonFormField<Commune>(
                    value: _selectedCommune,
                    decoration: _inputDecoration('Commune', Icons.location_city),
                    hint: const Text('Select Commune'),
                    items: _communes.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: _selectedWilaya == null ? null : (c) {
                      setState(() => _selectedCommune = c);
                    },
                    validator: (v) => v == null ? 'Required' : null,
                    disabledHint: _isLoadingCommunes
                        ? const Text('Loading...')
                        : (_selectedWilaya == null ? const Text('Select wilaya first') : null),
                  ),
                  const SizedBox(height: 16),

                  // Address details
                  TextFormField(
                    controller: _addressController,
                    decoration: _inputDecoration('Address Details (Optional)', Icons.home_work),
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            _buildSectionCard(
              title: 'Order Notes',
              icon: Icons.notes_outlined,
              children: [
                TextFormField(
                  controller: _notesController,
                  decoration: _inputDecoration('Additional notes (Optional)', Icons.note_add),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Method
            _buildSectionCard(
              title: 'Payment',
              icon: Icons.payment_outlined,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.money, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash on Delivery',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Pay when you receive your order',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Total and Place Order
            Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('${widget.cart.subtotal.toStringAsFixed(2)} DZD'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.cart.subtotal.toStringAsFixed(2)} DZD',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _placeOrder,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'PLACE ORDER',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
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
          // Header
          InkWell(
            onTap: () => setState(() => _showOrderSummary = !_showOrderSummary),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${widget.cart.itemCount} item${widget.cart.itemCount > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showOrderSummary ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Items list (collapsible)
          if (_showOrderSummary) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: widget.cart.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = widget.cart.items[index];
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.productImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.unitPriceFormatted} × ${item.quantity}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.totalPriceFormatted,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String type,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _deliveryType == type;
    return GestureDetector(
      onTap: () => setState(() => _deliveryType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }
}
