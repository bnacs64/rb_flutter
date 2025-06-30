import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/category_model.dart';

/// Service for managing categories
class CategoryService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get all root categories (categories without parent)
  Future<List<Category>> getRootCategories() async {
    try {
      final response = await _client
          .from(SupabaseTables.categories)
          .select('*')
          .isFilter('parent_id', null)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch root categories: $e');
    }
  }

  /// Get all categories with their subcategories
  Future<List<Category>> getCategoriesWithSubcategories() async {
    try {
      // First get all root categories
      final rootCategories = await getRootCategories();

      // Then get subcategories for each root category
      for (int i = 0; i < rootCategories.length; i++) {
        final subcategories = await getSubcategories(rootCategories[i].id);
        rootCategories[i] = Category(
          id: rootCategories[i].id,
          name: rootCategories[i].name,
          description: rootCategories[i].description,
          imageUrl: rootCategories[i].imageUrl,
          parentId: rootCategories[i].parentId,
          sortOrder: rootCategories[i].sortOrder,
          isActive: rootCategories[i].isActive,
          createdAt: rootCategories[i].createdAt,
          updatedAt: rootCategories[i].updatedAt,
          subCategories: subcategories,
        );
      }

      return rootCategories;
    } catch (e) {
      throw Exception('Failed to fetch categories with subcategories: $e');
    }
  }

  /// Get subcategories for a parent category
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      final response = await _client
          .from(SupabaseTables.categories)
          .select('*')
          .eq('parent_id', parentId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch subcategories: $e');
    }
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final response = await _client
          .from(SupabaseTables.categories)
          .select('*')
          .eq('id', categoryId)
          .eq('is_active', true)
          .single();

      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Get all categories (flat list)
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _client
          .from(SupabaseTables.categories)
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all categories: $e');
    }
  }

  /// Search categories by name
  Future<List<Category>> searchCategories(String query) async {
    try {
      final response = await _client
          .from(SupabaseTables.categories)
          .select('*')
          .ilike('name', '%$query%')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search categories: $e');
    }
  }
}
