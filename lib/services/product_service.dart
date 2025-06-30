import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/product_model.dart';

/// Custom exception for product service errors
class ProductServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  ProductServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'ProductServiceException: $message';
}

/// Service for managing products
class ProductService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get products with optional filtering and pagination
  Future<List<Product>> getProducts({
    String? categoryFilter,
    String? searchTerm,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (limit <= 0 || limit > 100) {
        throw ProductServiceException('Limit must be between 1 and 100',
            code: 'INVALID_LIMIT');
      }
      if (offset < 0) {
        throw ProductServiceException('Offset must be non-negative',
            code: 'INVALID_OFFSET');
      }

      final response = await _client.rpc('get_products_with_details', params: {
        'category_filter': categoryFilter,
        'search_term': searchTerm,
        'limit_count': limit,
        'offset_count': offset,
      });

      if (response == null) return [];

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ProductServiceException(
        'Database error while fetching products: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ProductServiceException(
        'Failed to fetch products: $e',
        originalError: e,
      );
    }
  }

  /// Get popular products
  Future<List<Product>> getPopularProducts({int limit = 10}) async {
    try {
      final response = await _client
          .from(SupabaseTables.products)
          .select('''
            *,
            categories!inner(name),
            inventory!inner(quantity_available)
          ''')
          .eq('is_active', true)
          .gte('inventory.quantity_available', 1)
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map((json) => Product.fromJson({
                ...json,
                'category_name': json['categories']['name'],
                'available_quantity': json['inventory']['quantity_available'],
                'is_in_stock': json['inventory']['quantity_available'] > 0,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch popular products: $e');
    }
  }

  /// Get products on sale/flash sale
  Future<List<Product>> getFlashSaleProducts({int limit = 10}) async {
    try {
      // Get products with active promotions
      final response = await _client
          .from(SupabaseTables.products)
          .select('''
            *,
            categories!inner(name),
            inventory!inner(quantity_available),
            promotions!inner(
              id,
              discount_percentage,
              discount_amount,
              start_date,
              end_date
            )
          ''')
          .eq('is_active', true)
          .eq('promotions.is_active', true)
          .gte('inventory.quantity_available', 1)
          .lte('promotions.start_date', DateTime.now().toIso8601String())
          .gte('promotions.end_date', DateTime.now().toIso8601String())
          .order('promotions.discount_percentage', ascending: false)
          .limit(limit);

      return response
          .map((json) => Product.fromJson({
                ...json,
                'category_name': json['categories']['name'],
                'available_quantity': json['inventory']['quantity_available'],
                'is_in_stock': json['inventory']['quantity_available'] > 0,
              }))
          .toList();
    } catch (e) {
      // Fallback to products sorted by price if promotions query fails
      try {
        final fallbackResponse = await _client
            .from(SupabaseTables.products)
            .select('''
              *,
              categories!inner(name),
              inventory!inner(quantity_available)
            ''')
            .eq('is_active', true)
            .gte('inventory.quantity_available', 1)
            .order('price', ascending: true)
            .limit(limit);

        return fallbackResponse
            .map((json) => Product.fromJson({
                  ...json,
                  'category_name': json['categories']['name'],
                  'available_quantity': json['inventory']['quantity_available'],
                  'is_in_stock': json['inventory']['quantity_available'] > 0,
                }))
            .toList();
      } catch (fallbackError) {
        throw Exception('Failed to fetch flash sale products: $fallbackError');
      }
    }
  }

  /// Get best selling products based on actual sales data
  Future<List<Product>> getBestSellersProducts({int limit = 10}) async {
    try {
      // Get products with highest sales volume from order_items
      final response = await _client
          .from(SupabaseTables.products)
          .select('''
            *,
            categories!inner(name),
            inventory!inner(quantity_available),
            order_items!inner(quantity)
          ''')
          .eq('is_active', true)
          .gte('inventory.quantity_available', 1)
          .order('order_items.quantity.sum', ascending: false)
          .limit(limit);

      return response
          .map((json) => Product.fromJson({
                ...json,
                'category_name': json['categories']['name'],
                'available_quantity': json['inventory']['quantity_available'],
                'is_in_stock': json['inventory']['quantity_available'] > 0,
              }))
          .toList();
    } catch (e) {
      // Fallback to products with highest review count if sales data query fails
      try {
        final fallbackResponse = await _client
            .from(SupabaseTables.products)
            .select('''
              *,
              categories!inner(name),
              inventory!inner(quantity_available),
              product_reviews(rating)
            ''')
            .eq('is_active', true)
            .gte('inventory.quantity_available', 1)
            .order('product_reviews.count', ascending: false)
            .limit(limit);

        return fallbackResponse
            .map((json) => Product.fromJson({
                  ...json,
                  'category_name': json['categories']['name'],
                  'available_quantity': json['inventory']['quantity_available'],
                  'is_in_stock': json['inventory']['quantity_available'] > 0,
                  'review_count':
                      (json['product_reviews'] as List?)?.length ?? 0,
                  'average_rating': json['product_reviews'] != null &&
                          (json['product_reviews'] as List).isNotEmpty
                      ? (json['product_reviews'] as List)
                              .map((r) => r['rating'] as double)
                              .reduce((a, b) => a + b) /
                          (json['product_reviews'] as List).length
                      : 0.0,
                }))
            .toList();
      } catch (fallbackError) {
        throw Exception('Failed to fetch best sellers: $fallbackError');
      }
    }
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from(SupabaseTables.products)
          .select('''
            *,
            categories!inner(name),
            inventory!inner(quantity_available)
          ''')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .gte('inventory.quantity_available', 1)
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map((json) => Product.fromJson({
                ...json,
                'category_name': json['categories']['name'],
                'available_quantity': json['inventory']['quantity_available'],
                'is_in_stock': json['inventory']['quantity_available'] > 0,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  /// Search products with advanced filters
  Future<List<Product>> searchProducts(
    String query, {
    List<String>? categoryIds,
    double? minPrice,
    double? maxPrice,
    bool? isOrganic,
    bool inStockOnly = true,
    String sortBy = 'name_asc',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc('search_products', params: {
        'search_query': query,
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
          .map((json) => Product.fromJson({
                ...json,
                'category_id': json['category_id'] ?? '',
                'is_in_stock': (json['available_quantity'] ?? 0) > 0,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final response = await _client.from(SupabaseTables.products).select('''
            *,
            categories!inner(name),
            inventory!inner(quantity_available)
          ''').eq('id', productId).eq('is_active', true).single();

      return Product.fromJson({
        ...response,
        'category_name': response['categories']['name'],
        'available_quantity': response['inventory']['quantity_available'],
        'is_in_stock': response['inventory']['quantity_available'] > 0,
      });
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }
}
