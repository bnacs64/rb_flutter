import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/promotion_model.dart';

/// Service for managing promotions and offers
class PromotionService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get active promotions for banners/carousel
  Future<List<Promotion>> getActivePromotions({int limit = 5}) async {
    try {
      final response = await _client
          .from(SupabaseTables.promotions)
          .select('*')
          .eq('is_active', true)
          .gte('end_date', DateTime.now().toIso8601String())
          .lte('start_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => Promotion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch active promotions: $e');
    }
  }

  /// Get all promotions
  Future<List<Promotion>> getAllPromotions() async {
    try {
      final response = await _client
          .from(SupabaseTables.promotions)
          .select('*')
          .order('created_at', ascending: false);

      return response.map((json) => Promotion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch promotions: $e');
    }
  }

  /// Get promotion by ID
  Future<Promotion?> getPromotionById(String promotionId) async {
    try {
      final response = await _client
          .from(SupabaseTables.promotions)
          .select('*')
          .eq('id', promotionId)
          .single();

      return Promotion.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch promotion: $e');
    }
  }

  /// Get promotions applicable to specific categories
  Future<List<Promotion>> getPromotionsForCategories(List<String> categoryIds) async {
    try {
      final response = await _client
          .from(SupabaseTables.promotions)
          .select('*')
          .eq('is_active', true)
          .gte('end_date', DateTime.now().toIso8601String())
          .lte('start_date', DateTime.now().toIso8601String())
          .overlaps('applicable_categories', categoryIds);

      return response.map((json) => Promotion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch category promotions: $e');
    }
  }

  /// Get promotions applicable to specific products
  Future<List<Promotion>> getPromotionsForProducts(List<String> productIds) async {
    try {
      final response = await _client
          .from(SupabaseTables.promotions)
          .select('*')
          .eq('is_active', true)
          .gte('end_date', DateTime.now().toIso8601String())
          .lte('start_date', DateTime.now().toIso8601String())
          .overlaps('applicable_products', productIds);

      return response.map((json) => Promotion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch product promotions: $e');
    }
  }

  /// Calculate discount for a given amount and promotion
  double calculateDiscount(Promotion promotion, double orderAmount) {
    if (!promotion.isCurrentlyActive || orderAmount < promotion.minimumOrderAmount) {
      return 0;
    }

    if (promotion.discountType == 'percentage') {
      return orderAmount * (promotion.discountValue / 100);
    } else if (promotion.discountType == 'fixed_amount') {
      return promotion.discountValue;
    }

    return 0;
  }

  /// Check if promotion is applicable to cart
  Future<bool> isPromotionApplicable(String promotionId, List<String> productIds, List<String> categoryIds) async {
    try {
      final promotion = await getPromotionById(promotionId);
      if (promotion == null || !promotion.isCurrentlyActive) {
        return false;
      }

      // If no specific products/categories are set, promotion applies to all
      if (promotion.applicableProducts.isEmpty && promotion.applicableCategories.isEmpty) {
        return true;
      }

      // Check if any products match
      if (promotion.applicableProducts.isNotEmpty) {
        for (String productId in productIds) {
          if (promotion.applicableProducts.contains(productId)) {
            return true;
          }
        }
      }

      // Check if any categories match
      if (promotion.applicableCategories.isNotEmpty) {
        for (String categoryId in categoryIds) {
          if (promotion.applicableCategories.contains(categoryId)) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
