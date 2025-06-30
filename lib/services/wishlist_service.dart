import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/product_model.dart';
import 'cart_service.dart';

/// Custom exception for wishlist service errors
class WishlistServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  WishlistServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'WishlistServiceException: $message';
}

/// Service for managing user wishlists
class WishlistService {
  final SupabaseClient _client = SupabaseConfig.client;
  final CartService _cartService = CartService();

  /// Get user's wishlist items with pagination
  Future<List<Product>> getWishlistItems({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw WishlistServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      if (limit <= 0 || limit > 100) {
        throw WishlistServiceException('Limit must be between 1 and 100',
            code: 'INVALID_LIMIT');
      }
      if (offset < 0) {
        throw WishlistServiceException('Offset must be non-negative',
            code: 'INVALID_OFFSET');
      }

      final response = await _client
          .from(SupabaseTables.wishlist)
          .select('''
            *,
            products!inner(
              *,
              categories!inner(name),
              inventory!inner(quantity_available)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) {
        final productData = json['products'];
        return Product.fromJson({
          ...productData,
          'category_name': productData['categories']['name'],
          'available_quantity': productData['inventory']['quantity_available'],
          'is_in_stock': productData['inventory']['quantity_available'] > 0,
        });
      }).toList();
    } on PostgrestException catch (e) {
      throw WishlistServiceException(
        'Database error while fetching wishlist items: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw WishlistServiceException(
        'Failed to fetch wishlist items: $e',
        originalError: e,
      );
    }
  }

  /// Add a product to the wishlist
  Future<void> addToWishlist(String productId) async {
    try {
      if (productId.isEmpty) {
        throw WishlistServiceException('Product ID cannot be empty',
            code: 'INVALID_PRODUCT_ID');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw WishlistServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // Check if product exists and is active
      final productExists = await _client
          .from(SupabaseTables.products)
          .select('id')
          .eq('id', productId)
          .eq('is_active', true)
          .maybeSingle();

      if (productExists == null) {
        throw WishlistServiceException('Product not found or inactive',
            code: 'PRODUCT_NOT_FOUND');
      }

      // Check if already in wishlist
      final existingItem = await _client
          .from(SupabaseTables.wishlist)
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItem != null) {
        throw WishlistServiceException('Product already in wishlist',
            code: 'ALREADY_IN_WISHLIST');
      }

      await _client.from(SupabaseTables.wishlist).insert({
        'user_id': userId,
        'product_id': productId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation
        throw WishlistServiceException('Product already in wishlist',
            code: 'ALREADY_IN_WISHLIST');
      }
      throw WishlistServiceException(
        'Database error while adding to wishlist: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is WishlistServiceException) rethrow;
      throw WishlistServiceException(
        'Failed to add to wishlist: $e',
        originalError: e,
      );
    }
  }

  /// Remove a product from the wishlist
  Future<void> removeFromWishlist(String productId) async {
    try {
      if (productId.isEmpty) {
        throw WishlistServiceException('Product ID cannot be empty',
            code: 'INVALID_PRODUCT_ID');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw WishlistServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      await _client
          .from(SupabaseTables.wishlist)
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } on PostgrestException catch (e) {
      throw WishlistServiceException(
        'Database error while removing from wishlist: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw WishlistServiceException(
        'Failed to remove from wishlist: $e',
        originalError: e,
      );
    }
  }

  /// Check if a product is in the user's wishlist
  Future<bool> isInWishlist(String productId) async {
    try {
      if (productId.isEmpty) {
        throw WishlistServiceException('Product ID cannot be empty',
            code: 'INVALID_PRODUCT_ID');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        return false; // Not authenticated, so not in wishlist
      }

      final result = await _client
          .from(SupabaseTables.wishlist)
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return result != null;
    } on PostgrestException catch (e) {
      throw WishlistServiceException(
        'Database error while checking wishlist: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw WishlistServiceException(
        'Failed to check wishlist: $e',
        originalError: e,
      );
    }
  }

  /// Clear the entire wishlist
  Future<void> clearWishlist() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw WishlistServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      await _client
          .from(SupabaseTables.wishlist)
          .delete()
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw WishlistServiceException(
        'Database error while clearing wishlist: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw WishlistServiceException(
        'Failed to clear wishlist: $e',
        originalError: e,
      );
    }
  }

  /// Get the total number of items in the wishlist
  Future<int> getWishlistCount() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        return 0; // Not authenticated, so count is 0
      }

      final response = await _client
          .from(SupabaseTables.wishlist)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId);

      return response.count ?? 0;
    } on PostgrestException catch (e) {
      throw WishlistServiceException(
        'Database error while getting wishlist count: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw WishlistServiceException(
        'Failed to get wishlist count: $e',
        originalError: e,
      );
    }
  }

  /// Move a wishlist item to cart
  Future<void> moveToCart(String productId, int quantity) async {
    try {
      if (productId.isEmpty) {
        throw WishlistServiceException('Product ID cannot be empty',
            code: 'INVALID_PRODUCT_ID');
      }
      if (quantity <= 0) {
        throw WishlistServiceException('Quantity must be greater than 0',
            code: 'INVALID_QUANTITY');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw WishlistServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // Check if product is in wishlist
      final wishlistItem = await _client
          .from(SupabaseTables.wishlist)
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (wishlistItem == null) {
        throw WishlistServiceException('Product not found in wishlist',
            code: 'NOT_IN_WISHLIST');
      }

      // Add to cart using CartService
      await _cartService.addToCart(productId, quantity);

      // Remove from wishlist
      await removeFromWishlist(productId);
    } catch (e) {
      if (e is WishlistServiceException) rethrow;
      throw WishlistServiceException(
        'Failed to move item to cart: $e',
        originalError: e,
      );
    }
  }

  /// Generate a shareable wishlist link
  Future<String> shareWishlist() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw WishlistServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // Get wishlist items
      final wishlistItems = await getWishlistItems();

      if (wishlistItems.isEmpty) {
        throw WishlistServiceException('Wishlist is empty',
            code: 'EMPTY_WISHLIST');
      }

      // Create a simple shareable link with product IDs
      // In a real app, you might want to create a more sophisticated sharing system
      final productIds = wishlistItems.map((product) => product.id).join(',');
      final shareableLink =
          'https://yourapp.com/shared-wishlist?products=$productIds&user=$userId';

      return shareableLink;
    } catch (e) {
      if (e is WishlistServiceException) rethrow;
      throw WishlistServiceException(
        'Failed to generate shareable link: $e',
        originalError: e,
      );
    }
  }

  /// Toggle wishlist status for a product (add if not in wishlist, remove if in wishlist)
  Future<bool> toggleWishlist(String productId) async {
    try {
      final isCurrentlyInWishlist = await isInWishlist(productId);

      if (isCurrentlyInWishlist) {
        await removeFromWishlist(productId);
        return false; // Removed from wishlist
      } else {
        await addToWishlist(productId);
        return true; // Added to wishlist
      }
    } catch (e) {
      if (e is WishlistServiceException) rethrow;
      throw WishlistServiceException(
        'Failed to toggle wishlist: $e',
        originalError: e,
      );
    }
  }

  /// Get wishlist items with their current stock status
  Future<List<Map<String, dynamic>>> getWishlistWithStockStatus() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw WishlistServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      final response = await _client.from(SupabaseTables.wishlist).select('''
            *,
            products!inner(
              *,
              categories!inner(name),
              inventory!inner(quantity_available, reserved_quantity)
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return response.map((json) {
        final productData = json['products'];
        final inventoryData = productData['inventory'];
        final availableQuantity = inventoryData['quantity_available'] as int;

        return {
          'product': Product.fromJson({
            ...productData,
            'category_name': productData['categories']['name'],
            'available_quantity': availableQuantity,
            'is_in_stock': availableQuantity > 0,
          }),
          'stock_status': availableQuantity > 0 ? 'in_stock' : 'out_of_stock',
          'stock_level':
              availableQuantity < 5 && availableQuantity > 0 ? 'low' : 'normal',
          'added_at': DateTime.parse(json['created_at']),
        };
      }).toList();
    } on PostgrestException catch (e) {
      throw WishlistServiceException(
        'Database error while fetching wishlist with stock status: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw WishlistServiceException(
        'Failed to fetch wishlist with stock status: $e',
        originalError: e,
      );
    }
  }
}
