import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/review_model.dart';

/// Custom exception for review service errors
class ReviewServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  ReviewServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'ReviewServiceException: $message';
}

/// Service for managing product reviews
class ReviewService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get paginated reviews for a product
  Future<List<ProductReview>> getProductReviews(
    String productId, {
    int limit = 20,
    int offset = 0,
    String sortBy = 'created_at_desc',
  }) async {
    try {
      if (productId.isEmpty) {
        throw ReviewServiceException('Product ID cannot be empty',
            code: 'INVALID_PRODUCT_ID');
      }
      if (limit <= 0 || limit > 100) {
        throw ReviewServiceException('Limit must be between 1 and 100',
            code: 'INVALID_LIMIT');
      }
      if (offset < 0) {
        throw ReviewServiceException('Offset must be non-negative',
            code: 'INVALID_OFFSET');
      }

      // Determine sort order
      String orderColumn = 'created_at';
      bool ascending = false;
      switch (sortBy) {
        case 'created_at_asc':
          orderColumn = 'created_at';
          ascending = true;
          break;
        case 'created_at_desc':
          orderColumn = 'created_at';
          ascending = false;
          break;
        case 'rating_asc':
          orderColumn = 'rating';
          ascending = true;
          break;
        case 'rating_desc':
          orderColumn = 'rating';
          ascending = false;
          break;
        case 'helpful_desc':
          orderColumn = 'helpful_count';
          ascending = false;
          break;
      }

      final response = await _client
          .from(SupabaseTables.productReviews)
          .select('''
            *,
            user_profiles!inner(full_name, avatar_url),
            products!inner(name, images)
          ''')
          .eq('product_id', productId)
          .eq('is_approved', true)
          .order(orderColumn, ascending: ascending)
          .range(offset, offset + limit - 1);

      return response.map((json) => ProductReview.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ReviewServiceException(
        'Database error while fetching product reviews: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ReviewServiceException(
        'Failed to fetch product reviews: $e',
        originalError: e,
      );
    }
  }

  /// Add a new product review
  Future<ProductReview> addReview(
    String productId,
    int rating, {
    String? title,
    String? comment,
    List<String>? images,
  }) async {
    try {
      if (productId.isEmpty) {
        throw ReviewServiceException('Product ID cannot be empty',
            code: 'INVALID_PRODUCT_ID');
      }
      if (rating < 1 || rating > 5) {
        throw ReviewServiceException('Rating must be between 1 and 5',
            code: 'INVALID_RATING');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw ReviewServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // Validate title and comment length
      if (title != null && title.length > 100) {
        throw ReviewServiceException('Title must be 100 characters or less',
            code: 'TITLE_TOO_LONG');
      }
      if (comment != null && comment.length > 1000) {
        throw ReviewServiceException('Comment must be 1000 characters or less',
            code: 'COMMENT_TOO_LONG');
      }

      // Check if user has already reviewed this product
      final existingReview = await _client
          .from(SupabaseTables.productReviews)
          .select('id')
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingReview != null) {
        throw ReviewServiceException('You have already reviewed this product',
            code: 'REVIEW_EXISTS');
      }

      final response =
          await _client.from(SupabaseTables.productReviews).insert({
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'title': title,
        'comment': comment,
        'images': images ?? [],
        'is_approved': true, // Auto-approve for now
      }).select('''
            *,
            user_profiles!inner(full_name, avatar_url),
            products!inner(name, images)
          ''').single();

      return ProductReview.fromJson(response);
    } on PostgrestException catch (e) {
      throw ReviewServiceException(
        'Database error while adding review: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is ReviewServiceException) rethrow;
      throw ReviewServiceException(
        'Failed to add review: $e',
        originalError: e,
      );
    }
  }

  /// Update an existing review (user's own only)
  Future<ProductReview> updateReview(
    String reviewId, {
    int? rating,
    String? title,
    String? comment,
  }) async {
    try {
      if (reviewId.isEmpty) {
        throw ReviewServiceException('Review ID cannot be empty',
            code: 'INVALID_REVIEW_ID');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw ReviewServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // Validate inputs
      if (rating != null && (rating < 1 || rating > 5)) {
        throw ReviewServiceException('Rating must be between 1 and 5',
            code: 'INVALID_RATING');
      }
      if (title != null && title.length > 100) {
        throw ReviewServiceException('Title must be 100 characters or less',
            code: 'TITLE_TOO_LONG');
      }
      if (comment != null && comment.length > 1000) {
        throw ReviewServiceException('Comment must be 1000 characters or less',
            code: 'COMMENT_TOO_LONG');
      }

      // Build update data
      final updateData = <String, dynamic>{};
      if (rating != null) updateData['rating'] = rating;
      if (title != null) updateData['title'] = title;
      if (comment != null) updateData['comment'] = comment;

      if (updateData.isEmpty) {
        throw ReviewServiceException('No fields to update',
            code: 'NO_UPDATE_DATA');
      }

      final response = await _client
          .from(SupabaseTables.productReviews)
          .update(updateData)
          .eq('id', reviewId)
          .eq('user_id',
              userId) // Ensure user can only update their own reviews
          .select('''
            *,
            user_profiles!inner(full_name, avatar_url),
            products!inner(name, images)
          ''').single();

      return ProductReview.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw ReviewServiceException(
            'Review not found or you do not have permission to update it',
            code: 'REVIEW_NOT_FOUND');
      }
      throw ReviewServiceException(
        'Database error while updating review: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is ReviewServiceException) rethrow;
      throw ReviewServiceException(
        'Failed to update review: $e',
        originalError: e,
      );
    }
  }

  /// Delete a review (user's own only)
  Future<void> deleteReview(String reviewId) async {
    try {
      if (reviewId.isEmpty) {
        throw ReviewServiceException('Review ID cannot be empty',
            code: 'INVALID_REVIEW_ID');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw ReviewServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      await _client
          .from(SupabaseTables.productReviews)
          .delete()
          .eq('id', reviewId)
          .eq('user_id',
              userId); // Ensure user can only delete their own reviews
    } on PostgrestException catch (e) {
      throw ReviewServiceException(
        'Database error while deleting review: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ReviewServiceException(
        'Failed to delete review: $e',
        originalError: e,
      );
    }
  }

  /// Get user's reviews across all products
  Future<List<ProductReview>> getMyReviews({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw ReviewServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      if (limit <= 0 || limit > 100) {
        throw ReviewServiceException('Limit must be between 1 and 100',
            code: 'INVALID_LIMIT');
      }
      if (offset < 0) {
        throw ReviewServiceException('Offset must be non-negative',
            code: 'INVALID_OFFSET');
      }

      final response = await _client
          .from(SupabaseTables.productReviews)
          .select('''
            *,
            user_profiles!inner(full_name, avatar_url),
            products!inner(name, images)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => ProductReview.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ReviewServiceException(
        'Database error while fetching user reviews: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ReviewServiceException(
        'Failed to fetch user reviews: $e',
        originalError: e,
      );
    }
  }

  /// Mark a review as helpful or unhelpful
  Future<void> markReviewHelpful(String reviewId, bool isHelpful) async {
    try {
      if (reviewId.isEmpty) {
        throw ReviewServiceException('Review ID cannot be empty',
            code: 'INVALID_REVIEW_ID');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw ReviewServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // For now, we'll just increment/decrement the helpful count
      // In a more sophisticated system, we'd track individual user votes
      final currentReview = await _client
          .from(SupabaseTables.productReviews)
          .select('helpful_count')
          .eq('id', reviewId)
          .single();

      final currentCount = currentReview['helpful_count'] as int? ?? 0;
      final newCount = isHelpful ? currentCount + 1 : currentCount - 1;

      await _client.from(SupabaseTables.productReviews).update({
        'helpful_count': newCount.clamp(0, double.infinity).toInt()
      }).eq('id', reviewId);
    } on PostgrestException catch (e) {
      throw ReviewServiceException(
        'Database error while marking review helpful: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ReviewServiceException(
        'Failed to mark review helpful: $e',
        originalError: e,
      );
    }
  }

  /// Report a review as inappropriate
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      if (reviewId.isEmpty) {
        throw ReviewServiceException('Review ID cannot be empty',
            code: 'INVALID_REVIEW_ID');
      }
      if (reason.isEmpty) {
        throw ReviewServiceException('Report reason cannot be empty',
            code: 'INVALID_REASON');
      }

      final userId = SupabaseConfig.currentUserId;
      if (userId == null) {
        throw ReviewServiceException('User not authenticated',
            code: 'NOT_AUTHENTICATED');
      }

      // Mark the review as reported
      await _client
          .from(SupabaseTables.productReviews)
          .update({'is_reported': true}).eq('id', reviewId);

      // In a real system, you might also log the report details
      // to a separate reports table for admin review
    } on PostgrestException catch (e) {
      throw ReviewServiceException(
        'Database error while reporting review: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ReviewServiceException(
        'Failed to report review: $e',
        originalError: e,
      );
    }
  }

  /// Get review statistics and summary for a product
  Future<ReviewSummary> getReviewSummary(String productId) async {
    try {
      if (productId.isEmpty) {
        throw ReviewServiceException('Product ID cannot be empty',
            code: 'INVALID_PRODUCT_ID');
      }

      final response = await _client
          .from(SupabaseTables.productReviews)
          .select('rating')
          .eq('product_id', productId)
          .eq('is_approved', true);

      if (response.isEmpty) {
        return ReviewSummary(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
          recentReviews: [],
        );
      }

      // Calculate statistics
      final ratings = response.map((r) => r['rating'] as int).toList();
      final totalReviews = ratings.length;
      final averageRating = ratings.reduce((a, b) => a + b) / totalReviews;

      // Calculate rating distribution
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = ratings.where((rating) => rating == i).length;
      }

      // Get recent reviews (last 5)
      final recentReviewsResponse = await _client
          .from(SupabaseTables.productReviews)
          .select('''
            *,
            user_profiles!inner(full_name, avatar_url),
            products!inner(name, images)
          ''')
          .eq('product_id', productId)
          .eq('is_approved', true)
          .order('created_at', ascending: false)
          .limit(5);

      final recentReviews = recentReviewsResponse
          .map((json) => ProductReview.fromJson(json))
          .toList();

      return ReviewSummary(
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        recentReviews: recentReviews,
      );
    } on PostgrestException catch (e) {
      throw ReviewServiceException(
        'Database error while fetching review summary: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ReviewServiceException(
        'Failed to fetch review summary: $e',
        originalError: e,
      );
    }
  }
}
