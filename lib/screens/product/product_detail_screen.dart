import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../core/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../cart/cart_screen.dart';
import '../auth/login_screen.dart';
import 'order_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Product? product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _api = ApiService();
  final PageController _pageController = PageController();
  
  Product? _product;
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  int _cartQuantity = 1;
  bool _isAddingToCart = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadProduct();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _api.get('/products/${widget.productId}');
      final reviewsResponse = await _api.get('/products/${widget.productId}/reviews');
      
      setState(() {
        _product = Product.fromJson(response);
        _reviews = reviewsResponse['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _shareProduct() {
    if (_product == null) return;
    Share.share(
      '${_product!.name}\n${_product!.effectivePriceFormatted}\n\nCheck out this product!\nhttps://3alamati.com/product/${_product!.id}',
      subject: _product!.name,
    );
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: 'https://3alamati.com/product/${widget.productId}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard!')),
    );
  }

  void _openOrderForm() {
    if (_product == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderFormScreen(product: _product!),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    // Check if user is logged in
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login to add items to cart'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'LOGIN',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addToCart(_product!.id, quantity: _cartQuantity);

    if (mounted) {
      setState(() => _isAddingToCart = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_product!.name} added to cart'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        // Reset quantity after adding
        setState(() => _cartQuantity = 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cartProvider.error ?? 'Failed to add to cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _buyViaWhatsApp() async {
    if (_product == null) return;
    
    // Get WhatsApp number from the store's social links
    final store = _product!.store;
    String? whatsappNumber;
    
    if (store != null && store.socialLinks.containsKey('whatsapp')) {
      whatsappNumber = store.socialLinks['whatsapp'];
    } else if (store != null && store.phone != null) {
      // Fallback to store phone if no WhatsApp
      whatsappNumber = store.phone;
    }
    
    if (whatsappNumber == null || whatsappNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No WhatsApp number available for this store')),
        );
      }
      return;
    }
    
    // Clean the phone number
    final cleanNumber = whatsappNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Build the message with product details
    final productUrl = 'https://3alamati.com/product/${_product!.id}';
    final imageUrl = _product!.thumbnailUrl;
    
    final message = '''
🛒 *Order Request*

📦 *Product:* ${_product!.name}
${_product!.category != null ? '📁 *Category:* ${_product!.category}\n' : ''}💰 *Price:* ${_product!.effectivePriceFormatted}
${_product!.hasDiscount ? '🏷️ *Original Price:* ${_product!.priceFormatted}\n' : ''}
${_product!.description != null && _product!.description!.isNotEmpty ? '📝 *Description:*\n${_product!.description}\n\n' : ''}🔗 *Link:* $productUrl
${imageUrl.isNotEmpty ? '\n🖼️ *Image:* $imageUrl' : ''}

---
_Sent via 3alamati App_
''';
    
    final encodedMessage = Uri.encodeComponent(message.trim());
    final whatsappUrl = 'https://wa.me/$cleanNumber?text=$encodedMessage';
    
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Error loading product'),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadProduct, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final images = product.allImages;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Image Carousel
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.45,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Main Image Carousel
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) => setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullScreenImage(images[index]),
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported, size: 64),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Zoom button
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.zoom_in, color: Colors.white),
                        onPressed: () => _showFullScreenImage(images[_currentImageIndex]),
                      ),
                    ),
                  ),
                  
                  // Navigation arrows
                  if (images.length > 1) ...[
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(Icons.chevron_left, size: 40, color: AppTheme.primaryColor),
                          onPressed: _currentImageIndex > 0
                              ? () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut)
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(Icons.chevron_right, size: 40, color: AppTheme.primaryColor),
                          onPressed: _currentImageIndex < images.length - 1
                              ? () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut)
                              : null,
                        ),
                      ),
                    ),
                  ],
                  
                  // Page indicators
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == index ? 10 : 8,
                            height: _currentImageIndex == index ? 10 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? AppTheme.primaryColor
                                  : Colors.white.withValues(alpha: 0.7),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Thumbnails
          if (images.length > 1)
            SliverToBoxAdapter(
              child: Container(
                height: 80,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _currentImageIndex == index
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: _currentImageIndex == index ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Product Info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Category tag
                  if (product.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        product.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Price
                  Row(
                    children: [
                      Text(
                        product.effectivePriceFormatted,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 12),
                        Text(
                          product.priceFormatted,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating
                  if (product.reviewsCount > 0)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < product.averageRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${product.averageRating} (${product.reviewsCount} reviews)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Actions Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
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
                children: [
                  // Favorites and Share row
                  Row(
                    children: [
                      // Favorite
                      InkWell(
                        onTap: () => setState(() => _isFavorite = !_isFavorite),
                        child: Row(
                          children: [
                            Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add to Favorites',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Share buttons
                      _ShareButton(icon: Icons.facebook, color: const Color(0xFF1877F2), onTap: _shareProduct),
                      _ShareButton(icon: Icons.share, color: Colors.blue, onTap: _shareProduct),
                      _ShareButton(icon: Icons.whatshot, color: const Color(0xFF25D366), onTap: _shareProduct),
                      _ShareButton(icon: Icons.link, color: Colors.grey, onTap: _copyLink),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Add to Cart section (for products only)
                  if (!product.isService && product.inStock) ...[
                    // Quantity selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Quantity: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: _cartQuantity > 1 ? () => setState(() => _cartQuantity--) : null,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.remove, color: AppTheme.primaryColor),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              '$_cartQuantity',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          InkWell(
                            onTap: _cartQuantity < product.stock ? () => setState(() => _cartQuantity++) : null,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add, color: AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Add to Cart button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isAddingToCart ? null : _addToCart,
                        icon: _isAddingToCart 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.shopping_cart_outlined),
                        label: Text(
                          _isAddingToCart ? 'ADDING...' : 'ADD TO CART',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Direct Order button (or Request Service for services)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: product.isService || !product.inStock
                        ? FilledButton(
                            onPressed: (product.isService || product.inStock) ? _openOrderForm : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              product.isService 
                                  ? 'REQUEST SERVICE' 
                                  : 'OUT OF STOCK',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: _openOrderForm,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'BUY NOW',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                  ),
                  if (product.isService)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Submit a request and we will contact you shortly.',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Buy via WhatsApp button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _buyViaWhatsApp,
                      icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                      label: const Text(
                        'BUY VIA WHATSAPP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Color(0xFF25D366),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF25D366), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Description
          if (product.description != null && product.description!.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.description!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Reviews
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${product.reviewsCount} reviews',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No reviews yet',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    ...(_reviews.take(3).map((review) => _buildReviewCard(review))),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final user = review['user'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: user['profile_pic'] != null
                    ? CachedNetworkImageProvider(user['profile_pic'])
                    : null,
                child: user['profile_pic'] == null
                    ? Text((user['pseudoname'] ?? user['username'] ?? 'U')[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['pseudoname'] ?? user['username'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review['comment'],
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
