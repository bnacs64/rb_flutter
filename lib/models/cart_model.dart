/// Cart item model that matches Supabase database schema
class CartItem {
  final String cartId;
  final String productId;
  final String productName;
  final String? productImage;
  final String brand;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final int availableQuantity;
  final bool isAvailable;

  CartItem({
    required this.cartId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.brand,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.availableQuantity,
    required this.isAvailable,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cart_id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      brand: json['brand'] ?? '',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      availableQuantity: json['available_quantity'] ?? 0,
      isAvailable: json['is_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'brand': brand,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
      'available_quantity': availableQuantity,
      'is_available': isAvailable,
    };
  }
}

/// Shopping cart summary
class CartSummary {
  final List<CartItem> items;
  final double subtotal;
  final double taxAmount;
  final double deliveryFee;
  final double discountAmount;
  final double totalAmount;
  final int totalItems;

  CartSummary({
    required this.items,
    required this.subtotal,
    this.taxAmount = 0,
    this.deliveryFee = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    required this.totalItems,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      items: (json['items'] as List? ?? [])
          .map((item) => CartItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      totalItems: json['total_items'] ?? 0,
    );
  }

  /// Create CartSummary from a list of CartItems
  factory CartSummary.fromItems(
    List<CartItem> items, {
    double taxRate = 0.0,
    double deliveryFee = 0.0,
    double discountAmount = 0.0,
  }) {
    final subtotal =
        items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final taxAmount = subtotal * taxRate;
    final totalAmount = subtotal + taxAmount + deliveryFee - discountAmount;
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);

    return CartSummary(
      items: items,
      subtotal: subtotal,
      taxAmount: taxAmount,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      totalItems: totalItems,
    );
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;
}
