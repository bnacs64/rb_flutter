# Flutter Integration Guide

This guide shows how to integrate the Supabase grocery store backend with your Flutter application.

## Setup

### 1. Add Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  provider: ^6.0.0  # or riverpod for state management
  cached_network_image: ^3.2.0
  geolocator: ^10.1.0
  permission_handler: ^11.0.2
  image_picker: ^1.0.4
  shared_preferences: ^2.2.2
```

### 2. Initialize Supabase

The Supabase configuration is already created in `lib/core/supabase_config.dart` with your project credentials:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://nlizabhdxklazxgiflbb.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5saXphYmhkeGtsYXp4Z2lmbGJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyOTE4NDksImV4cCI6MjA2Njg2Nzg0OX0.8ncdfAJfl4z8AHgYeokzH3xn1-OipXsBu3uhXfS5dFc';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
```

The initialization is already added to your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shop/core/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}
```

## Data Models

### Product Model

```dart
class Product {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final String brand;
  final double price;
  final String unit;
  final String weightVolume;
  final bool isOrganic;
  final List<String> images;
  final List<String> tags;
  final int availableQuantity;
  final double averageRating;
  final int reviewCount;
  final bool isInStock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.brand,
    required this.price,
    required this.unit,
    required this.weightVolume,
    required this.isOrganic,
    required this.images,
    required this.tags,
    required this.availableQuantity,
    required this.averageRating,
    required this.reviewCount,
    required this.isInStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      brand: json['brand'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      weightVolume: json['weight_volume'] ?? '',
      isOrganic: json['is_organic'] ?? false,
      images: List<String>.from(json['images'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      availableQuantity: json['available_quantity'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      isInStock: json['is_in_stock'] ?? false,
    );
  }
}
```

### Cart Item Model

```dart
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
}
```

### Order Model

```dart
class Order {
  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double deliveryFee;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? scheduledDeliveryDate;
  final String? specialInstructions;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.deliveryFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.scheduledDeliveryDate,
    this.specialInstructions,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      scheduledDeliveryDate: json['scheduled_delivery_date'] != null
          ? DateTime.parse(json['scheduled_delivery_date'])
          : null,
      specialInstructions: json['special_instructions'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```

## Services

### Product Service

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Product>> getProducts({
    String? categoryFilter,
    String? searchTerm,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc('get_products_with_details', params: {
        'category_filter': categoryFilter,
        'search_term': searchTerm,
        'limit_count': limit,
        'offset_count': offset,
      });

      if (response == null) return [];

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<List<Product>> searchProducts({
    String? searchQuery,
    List<String>? categoryIds,
    double? minPrice,
    double? maxPrice,
    bool? isOrganic,
    bool inStockOnly = true,
    String sortBy = 'name',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc('search_products', params: {
        'search_query': searchQuery,
        'category_ids': categoryIds,
        'min_price': minPrice,
        'max_price': maxPrice,
        'is_organic_filter': isOrganic,
        'in_stock_only': inStockOnly,
        'sort_by': sortBy,
        'limit_count': limit,
        'offset_count': offset,
      });

      if (response == null) return [];

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select('''
            *,
            categories!inner(name),
            inventory(quantity_available, reserved_quantity),
            product_reviews!inner(rating)
          ''')
          .eq('id', productId)
          .eq('is_active', true)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }
}
```

### Cart Service

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/cart_item.dart';

class CartService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client.rpc('add_to_cart', params: {
        'user_id_param': userId,
        'product_id_param': productId,
        'quantity_param': quantity,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  Future<List<CartItem>> getCartItems() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client.rpc('get_cart_items', params: {
        'user_id_param': userId,
      });

      if (response == null) return [];

      return (response as List)
          .map((json) => CartItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cart items: $e');
    }
  }

  Future<void> updateCartItem({
    required String cartId,
    required int quantity,
  }) async {
    try {
      await _client
          .from('shopping_cart')
          .update({'quantity': quantity})
          .eq('id', cartId);
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  Future<void> removeFromCart(String cartId) async {
    try {
      await _client
          .from('shopping_cart')
          .delete()
          .eq('id', cartId);
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('shopping_cart')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }
}
```

### Order Service

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/order.dart';

class OrderService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> createOrderFromCart({
    required String deliveryAddressId,
    required String deliveryZoneId,
    required String deliverySlotId,
    required DateTime scheduledDeliveryDate,
    required String paymentMethod,
    String? specialInstructions,
    String? promotionId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client.rpc('create_order_from_cart', params: {
        'user_id_param': userId,
        'delivery_address_id_param': deliveryAddressId,
        'delivery_zone_id_param': deliveryZoneId,
        'delivery_slot_id_param': deliverySlotId,
        'scheduled_delivery_date_param': scheduledDeliveryDate.toIso8601String().split('T')[0],
        'payment_method_param': paymentMethod,
        'special_instructions_param': specialInstructions,
        'promotion_id_param': promotionId,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<Order>> getUserOrders() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await _client.rpc('get_order_details', params: {
        'order_id_param': orderId,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }
}
```

## State Management with Provider

### Cart Provider

```dart
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  Future<void> loadCartItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _cartService.getCartItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      final result = await _cartService.addToCart(
        productId: productId,
        quantity: quantity,
      );
      
      if (result['success'] == true) {
        await loadCartItems(); // Refresh cart
      } else {
        _error = result['error'];
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String cartId, int quantity) async {
    try {
      await _cartService.updateCartItem(cartId: cartId, quantity: quantity);
      await loadCartItems(); // Refresh cart
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeItem(String cartId) async {
    try {
      await _cartService.removeFromCart(cartId);
      await loadCartItems(); // Refresh cart
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      await _cartService.clearCart();
      _items.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
```

## UI Components

### Product Card Widget

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      )
                    : const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (product.isInStock)
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              return IconButton(
                                onPressed: () {
                                  cartProvider.addToCart(product.id, 1);
                                },
                                icon: const Icon(Icons.add_shopping_cart),
                                iconSize: 20,
                              );
                            },
                          )
                        else
                          Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
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
```

### Cart Item Widget

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;

  const CartItemWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.productImage != null
                  ? CachedNetworkImage(
                      imageUrl: item.productImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    )
                  : const Icon(Icons.image_not_supported),
            ),
            
            const SizedBox(width: 12),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.brand,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.unitPrice.toStringAsFixed(2)} each',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!item.isAvailable)
                    Text(
                      'Currently unavailable',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
            ),
            
            // Quantity Controls
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: item.quantity > 1
                          ? () {
                              context.read<CartProvider>().updateQuantity(
                                item.cartId,
                                item.quantity - 1,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.quantity.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: item.quantity < item.availableQuantity
                          ? () {
                              context.read<CartProvider>().updateQuantity(
                                item.cartId,
                                item.quantity + 1,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            
            // Remove Button
            IconButton(
              onPressed: () {
                context.read<CartProvider>().removeItem(item.cartId);
              },
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
```

This integration guide provides a solid foundation for connecting your Flutter app to the Supabase grocery store backend. You can extend these examples based on your specific UI requirements and add additional features like real-time updates, offline support, and more sophisticated state management.
