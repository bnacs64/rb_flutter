import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/cart_model.dart';

/// Service for managing shopping cart
class CartService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Add item to cart
  Future<void> addToCart(String productId, int quantity) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _client.rpc('add_to_cart', params: {
        'user_id_param': userId,
        'product_id_param': productId,
        'quantity_param': quantity,
      });
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  /// Get cart items for current user
  Future<CartSummary> getCartItems() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client.rpc('get_cart_items', params: {
        'user_id_param': userId,
      });

      if (response == null) {
        return CartSummary(
          items: [],
          subtotal: 0,
          totalAmount: 0,
          totalItems: 0,
        );
      }

      return CartSummary.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch cart items: $e');
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
          .update({'quantity': quantity, 'updated_at': DateTime.now().toIso8601String()})
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

      return response.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
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
}
