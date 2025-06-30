import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/cart_model.dart';

/// Custom exception for cart service errors
class CartServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  CartServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'CartServiceException: $message';
}

/// Service for managing shopping cart
class CartService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Add item to cart
  Future<void> addToCart(String productId, int quantity) async {
    try {
      if (productId.isEmpty) {
        throw CartServiceException('Product ID cannot be empty',
            code: 'INVALID_PRODUCT_ID');
      }
      if (quantity <= 0) {
        throw CartServiceException('Quantity must be greater than 0',
            code: 'INVALID_QUANTITY');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw CartServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      await _client.rpc('add_to_cart', params: {
        'user_id_param': userId,
        'product_id_param': productId,
        'quantity_param': quantity,
      });
    } on PostgrestException catch (e) {
      throw CartServiceException(
        'Database error while adding item to cart: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException(
        'Failed to add item to cart: $e',
        originalError: e,
      );
    }
  }

  /// Get cart items for current user
  Future<CartSummary> getCartItems({
    double taxRate = 0.0,
    double deliveryFee = 0.0,
    double discountAmount = 0.0,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw CartServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      final response = await _client.rpc('get_cart_items', params: {
        'user_id_param': userId,
      });

      if (response == null || (response as List).isEmpty) {
        return CartSummary.fromItems(
          [],
          taxRate: taxRate,
          deliveryFee: deliveryFee,
          discountAmount: discountAmount,
        );
      }

      final items =
          response.map<CartItem>((json) => CartItem.fromJson(json)).toList();

      return CartSummary.fromItems(
        items,
        taxRate: taxRate,
        deliveryFee: deliveryFee,
        discountAmount: discountAmount,
      );
    } on PostgrestException catch (e) {
      throw CartServiceException(
        'Database error while fetching cart items: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException(
        'Failed to fetch cart items: $e',
        originalError: e,
      );
    }
  }

  /// Update cart item quantity
  Future<void> updateCartItemQuantity(String productId, int quantity) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (quantity <= 0) {
        await removeFromCart(productId);
        return;
      }

      await _client
          .from(SupabaseTables.shoppingCart)
          .update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from(SupabaseTables.shoppingCart)
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from(SupabaseTables.shoppingCart)
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  /// Get cart item count
  Future<int> getCartItemCount() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        return 0;
      }

      final response = await _client
          .from(SupabaseTables.shoppingCart)
          .select('quantity')
          .eq('user_id', userId);

      if (response.isEmpty) return 0;

      return response.fold<int>(
          0, (sum, item) => sum + (item['quantity'] as int));
    } catch (e) {
      throw Exception('Failed to get cart item count: $e');
    }
  }

  /// Check if product is in cart
  Future<bool> isProductInCart(String productId) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        return false;
      }

      final response = await _client
          .from(SupabaseTables.shoppingCart)
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get cart item quantity for a specific product
  Future<int> getCartItemQuantity(String productId) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        return 0;
      }

      final response = await _client
          .from(SupabaseTables.shoppingCart)
          .select('quantity')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .single();

      return response['quantity'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// Get cart total value
  Future<double> getCartTotal() async {
    try {
      final cartSummary = await getCartItems();
      return cartSummary.totalAmount;
    } catch (e) {
      throw CartServiceException(
        'Failed to get cart total: $e',
        originalError: e,
      );
    }
  }

  /// Update multiple cart items at once
  Future<void> updateMultipleCartItems(
      Map<String, int> productQuantities) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw CartServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      for (final entry in productQuantities.entries) {
        await updateCartItemQuantity(entry.key, entry.value);
      }
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException(
        'Failed to update multiple cart items: $e',
        originalError: e,
      );
    }
  }

  /// Validate cart items (check availability and pricing)
  Future<List<String>> validateCartItems() async {
    try {
      final cartSummary = await getCartItems();
      final issues = <String>[];

      for (final item in cartSummary.items) {
        if (!item.isAvailable) {
          issues.add('${item.productName} is no longer available');
        }
        if (item.quantity > item.availableQuantity) {
          issues.add(
              '${item.productName}: Only ${item.availableQuantity} items available, but ${item.quantity} requested');
        }
      }

      return issues;
    } catch (e) {
      throw CartServiceException(
        'Failed to validate cart items: $e',
        originalError: e,
      );
    }
  }
}
