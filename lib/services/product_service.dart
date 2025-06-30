import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/product_model.dart';

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

      return response.map((json) => Product.fromJson({
        ...json,
        'category_name': json['categories']['name'],
        'available_quantity': json['inventory']['quantity_available'],
        'is_in_stock': json['inventory']['quantity_available'] > 0,
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch popular products: $e');
    }
  }

  /// Get products on sale/flash sale
  Future<List<Product>> getFlashSaleProducts({int limit = 10}) async {
    try {
      // This would typically involve checking for active promotions
      // For now, we'll return products with some sample logic
      final response = await _client
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

      return response.map((json) => Product.fromJson({
        ...json,
        'category_name': json['categories']['name'],
        'available_quantity': json['inventory']['quantity_available'],
        'is_in_stock': json['inventory']['quantity_available'] > 0,
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch flash sale products: $e');
    }
  }

  /// Get best selling products
  Future<List<Product>> getBestSellersProducts({int limit = 10}) async {
    try {
      // This would typically involve order analytics
      // For now, we'll return products ordered by creation date
      final response = await _client
          .from(SupabaseTables.products)
          .select('''
            *,
            categories!inner(name),
            inventory!inner(quantity_available)
          ''')
          .eq('is_active', true)
          .gte('inventory.quantity_available', 1)
          .order('created_at', ascending: true)
          .limit(limit);

      return response.map((json) => Product.fromJson({
        ...json,
        'category_name': json['categories']['name'],
        'available_quantity': json['inventory']['quantity_available'],
        'is_in_stock': json['inventory']['quantity_available'] > 0,
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch best sellers: $e');
    }
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId, {int limit = 20}) async {
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

      return response.map((json) => Product.fromJson({
        ...json,
        'category_name': json['categories']['name'],
        'available_quantity': json['inventory']['quantity_available'],
        'is_in_stock': json['inventory']['quantity_available'] > 0,
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  /// Search products
  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    try {
      final response = await _client.rpc('search_products', params: {
        'search_term': query,
        'limit_count': limit,
      });

      if (response == null) return [];

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final response = await _client
          .from(SupabaseTables.products)
          .select('''
            *,
            categories!inner(name),
            inventory!inner(quantity_available)
          ''')
          .eq('id', productId)
          .eq('is_active', true)
          .single();

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
