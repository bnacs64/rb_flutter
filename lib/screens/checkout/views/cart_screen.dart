import 'package:flutter/material.dart';
import 'package:shop/models/cart_model.dart';
import 'package:shop/models/address_model.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/address_service.dart';
import 'package:shop/services/wishlist_service.dart';
import 'package:shop/components/network_image_with_loader.dart';

import '../../../constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final AddressService _addressService = AddressService();
  final WishlistService _wishlistService = WishlistService();

  CartSummary? _cartSummary;
  List<CustomerAddress> _addresses = [];
  CustomerAddress? _selectedAddress;
  bool _isLoading = true;
  bool _isUpdatingCart = false;
  String? _error;

  // Promo code
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;
  double _discountAmount = 0.0;

  // Delivery options
  String _selectedDeliveryOption = 'standard';
  double _deliveryFee = 5.99;
  DateTime? _selectedDeliveryDate;
  String? _selectedTimeSlot;
  final TextEditingController _specialInstructionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadCartData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load cart items and addresses in parallel
      final results = await Future.wait([
        _cartService.getCartItems(
          deliveryFee: _deliveryFee,
          discountAmount: _discountAmount,
        ),
        _addressService.getUserAddresses(),
      ]);

      final cartSummary = results[0] as CartSummary;
      final addresses = results[1] as List<CustomerAddress>;

      setState(() {
        _cartSummary = cartSummary;
        _addresses = addresses;
        _selectedAddress = addresses.isNotEmpty ? addresses.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCartItemQuantity(
      String productId, int newQuantity) async {
    if (_isUpdatingCart) return;

    setState(() {
      _isUpdatingCart = true;
    });

    try {
      if (newQuantity <= 0) {
        await _cartService.removeFromCart(productId);
      } else {
        await _cartService.updateCartItemQuantity(productId, newQuantity);
      }

      // Reload cart data
      await _loadCartData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingCart = false;
      });
    }
  }

  Future<void> _removeCartItem(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text(
            'Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateCartItemQuantity(productId, 0);
    }
  }

  Future<void> _moveToWishlist(CartItem item) async {
    try {
      await _wishlistService.addToWishlist(item.productId);
      await _cartService.removeFromCart(item.productId);
      await _loadCartData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.productName} moved to wishlist'),
          action: SnackBarAction(
            label: 'View Wishlist',
            onPressed: () {
              // Navigate to wishlist
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error moving to wishlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    // Simulate promo code validation
    // In a real app, this would call an API
    if (code.toLowerCase() == 'save10') {
      setState(() {
        _appliedPromoCode = code;
        _discountAmount = (_cartSummary?.subtotal ?? 0) * 0.1; // 10% discount
      });
      _loadCartData(); // Reload with discount
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo code applied successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _discountAmount = 0.0;
      _promoCodeController.clear();
    });
    _loadCartData(); // Reload without discount
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (_cartSummary != null && _cartSummary!.items.isNotEmpty)
            IconButton(
              onPressed: _showCartOptions,
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: _buildCartContent(),
    );
  }

  void _showCartOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Cart'),
              onTap: () {
                Navigator.pop(context);
                _clearCart();
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Move All to Wishlist'),
              onTap: () {
                Navigator.pop(context);
                _moveAllToWishlist();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Cart'),
              onTap: () {
                Navigator.pop(context);
                _shareCart();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cartService.clearCart();
        await _loadCartData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart cleared successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _moveAllToWishlist() async {
    try {
      for (final item in _cartSummary!.items) {
        await _wishlistService.addToWishlist(item.productId);
      }
      await _cartService.clearCart();
      await _loadCartData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All items moved to wishlist')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error moving items to wishlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareCart() {
    // Implement cart sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cart sharing feature coming soon!')),
    );
  }

  Widget _buildCartContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading cart: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCartData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cartSummary == null || _cartSummary!.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add some products to get started',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Cart Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(defaultPadding),
                  itemCount: _cartSummary!.items.length,
                  itemBuilder: (context, index) {
                    final item = _cartSummary!.items[index];
                    return _buildEnhancedCartItem(item);
                  },
                ),

                // Promo Code Section
                _buildPromoCodeSection(),

                // Delivery Options Section
                _buildDeliveryOptionsSection(),

                // Order Summary Section
                _buildOrderSummarySection(),
              ],
            ),
          ),
        ),
        // Cart summary
        Container(
          padding: const EdgeInsets.all(defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${_cartSummary!.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_cartSummary?.items.isNotEmpty ?? false)
                      ? () {
                          // Navigate to checkout
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Checkout functionality coming soon!')),
                          );
                        }
                      : null,
                  child: const Text('Proceed to Checkout'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.productImage != null &&
                            item.productImage!.isNotEmpty
                        ? NetworkImageWithLoader(
                            item.productImage!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: defaultPadding),

                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.brand,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${item.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity controls and total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _isUpdatingCart
                                ? null
                                : () => _updateCartItemQuantity(
                                      item.productId,
                                      item.quantity - 1,
                                    ),
                            icon: const Icon(Icons.remove),
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _isUpdatingCart
                                ? null
                                : () => _updateCartItemQuantity(
                                      item.productId,
                                      item.quantity + 1,
                                    ),
                            icon: const Icon(Icons.add),
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Total price
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _moveToWishlist(item),
                    icon: const Icon(Icons.favorite_border, size: 16),
                    label: const Text('Move to Wishlist'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _removeCartItem(item.productId),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promo Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_appliedPromoCode != null) ...[
            // Applied promo code display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Promo code "$_appliedPromoCode" applied',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _removePromoCode,
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Promo code input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    decoration: const InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryOptionsSection() {
    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Delivery speed options
          RadioListTile<String>(
            title: const Text('Standard Delivery'),
            subtitle: const Text('5-7 business days • \$5.99'),
            value: 'standard',
            groupValue: _selectedDeliveryOption,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryOption = value!;
                _deliveryFee = 5.99;
              });
              _loadCartData();
            },
          ),
          RadioListTile<String>(
            title: const Text('Express Delivery'),
            subtitle: const Text('2-3 business days • \$12.99'),
            value: 'express',
            groupValue: _selectedDeliveryOption,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryOption = value!;
                _deliveryFee = 12.99;
              });
              _loadCartData();
            },
          ),
          RadioListTile<String>(
            title: const Text('Next Day Delivery'),
            subtitle: const Text('Next business day • \$19.99'),
            value: 'next_day',
            groupValue: _selectedDeliveryOption,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryOption = value!;
                _deliveryFee = 19.99;
              });
              _loadCartData();
            },
          ),

          const SizedBox(height: 16),

          // Special instructions
          TextField(
            controller: _specialInstructionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Special Instructions (Optional)',
              hintText: 'Leave at door, ring bell, etc.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    if (_cartSummary == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('\$${_cartSummary!.subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),

          // Delivery fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Fee'),
              Text('\$${_deliveryFee.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),

          // Discount
          if (_discountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount'),
                Text(
                  '-\$${_discountAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Tax (estimated)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax (estimated)'),
              Text('\$${_cartSummary!.taxAmount.toStringAsFixed(2)}'),
            ],
          ),

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${_cartSummary!.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
