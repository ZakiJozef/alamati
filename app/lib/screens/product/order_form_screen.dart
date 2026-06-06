import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../providers/locations_provider.dart';
import '../../models/location.dart';

class OrderFormScreen extends StatefulWidget {
  final Product product;

  const OrderFormScreen({super.key, required this.product});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final ApiService _api = ApiService();

  int _quantity = 1;
  
  // Location selection
  Wilaya? _selectedWilayaObj;
  Commune? _selectedCommuneObj;
  List<Commune> _communes = []; // Dynamic communes list
  bool _isLoadingCommunes = false;
  
  String? _selectedWilaya; // For backward compatibility/API
  String? _selectedCommune; // For backward compatibility/API
  
  bool _isLoading = false;
  String _deliveryType = 'home'; // 'home' or 'desk'

  @override
  void initState() {
    super.initState();
    // Load wilayas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationsProvider>().loadWilayas();
    });

    // Pre-fill user data if authenticated
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user != null) {
      _nameController.text = authProvider.user!.displayName;
    }
  }

  Future<void> _loadCommunes(int wilayaId) async {
    setState(() {
      _isLoadingCommunes = true;
      _communes = [];
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get subtotal => widget.product.effectivePrice * _quantity;
  double get total => subtotal;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Only require location for home delivery
    if (_deliveryType == 'home' && (_selectedWilaya == null || _selectedCommune == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select wilaya and commune for home delivery')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _api.post('/orders', {
        'product_id': widget.product.id,
        'quantity': _quantity,
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'delivery_type': _deliveryType,
        'wilaya': _deliveryType == 'home' ? _selectedWilaya : null,
        'commune': _deliveryType == 'home' ? _selectedCommune : null,
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            title: const Text('Order Placed!'),
            content: const Text(
              'Thank you for your order! We will contact you shortly to confirm.',
              textAlign: TextAlign.center,
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isService = widget.product.isService;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isService ? 'Request Service' : 'Place Order'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isService ? Colors.purple.shade50 : Colors.grey.shade100,
              child: Text(
                isService 
                    ? 'Fill out your details and we will contact you\nto schedule your service.'
                    : 'To place an order, fill out the form\nand we will contact you as soon as possible.',
                style: TextStyle(
                  color: isService ? Colors.purple.shade700 : Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.product.thumbnailUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unit Price: ${widget.product.effectivePriceFormatted}',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.product.effectivePriceFormatted,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Quantity selector (only for products, not services)
                    if (!isService) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: Icon(Icons.remove, color: AppTheme.primaryColor),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity < widget.product.stock
                                ? () => setState(() => _quantity++)
                                : null,
                            icon: Icon(Icons.add, color: AppTheme.primaryColor),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                          ),
                        ],
                      ),
                    ),
                    ],
                    const SizedBox(height: 24),
                    
                    // Full Name
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    const Text('Phone', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone',
                        hintStyle: TextStyle(color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Delivery Type
                    const Text('Delivery Method', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _deliveryType = 'home'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _deliveryType == 'home'
                                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _deliveryType == 'home'
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                                  width: _deliveryType == 'home' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.home,
                                    size: 32,
                                    color: _deliveryType == 'home'
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade500,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Home Delivery',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _deliveryType == 'home'
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Deliver to my address',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _deliveryType = 'desk'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _deliveryType == 'desk'
                                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _deliveryType == 'desk'
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                                  width: _deliveryType == 'desk' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.store,
                                    size: 32,
                                    color: _deliveryType == 'desk'
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade500,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pickup at Desk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _deliveryType == 'desk'
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'I\'ll pick it up myself',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_deliveryType == 'home') ...[
                      const SizedBox(height: 16),
                      
                      // Wilaya
                      const Text('Wilaya', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Consumer<LocationsProvider>(
                        builder: (context, locations, child) {
                          if (locations.isLoading && locations.wilayas.isEmpty) {
                            return const Center(child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ));
                          }
                          return DropdownButtonFormField<Wilaya>(
                            value: _selectedWilayaObj,
                            decoration: InputDecoration(
                              hintText: 'Select Wilaya',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: locations.wilayas.map((w) => DropdownMenuItem(
                              value: w,
                              child: Text('${w.code} - ${w.name}'),
                            )).toList(),
                            onChanged: (w) {
                              if (w == null) return;
                              setState(() {
                                _selectedWilayaObj = w;
                                _selectedWilaya = w.name;
                                _selectedCommuneObj = null;
                                _selectedCommune = null;
                                _communes = [];
                              });
                              _loadCommunes(w.id);
                            },
                            validator: (v) => v == null ? 'Please select a wilaya' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Commune
                      const Text('Commune', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Commune>(
                        value: _selectedCommuneObj,
                        decoration: InputDecoration(
                          hintText: 'Select Commune',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        items: _communes.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        )).toList(),
                        onChanged: _selectedWilayaObj == null ? null : (c) {
                          setState(() {
                            _selectedCommuneObj = c;
                            _selectedCommune = c?.name;
                          });
                        },
                        validator: (v) => v == null ? 'Please select a commune' : null,
                        disabledHint: _isLoadingCommunes 
                            ? const Text('Loading communes...') 
                            : (_selectedWilayaObj == null ? const Text('Select a wilaya first') : null),
                      ),
                    ],
                    const SizedBox(height: 32),
                    
                    // Totals
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('SUB-TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${subtotal.toStringAsFixed(2)} DZD',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Cash on delivery'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(
                                '${total.toStringAsFixed(2)} DZD',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _placeOrder,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isService ? 'SUBMIT REQUEST' : 'CONFIRM ORDER',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
