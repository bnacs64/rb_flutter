/// Custom exception for review model errors
class ReviewModelException implements Exception {
  final String message;
  final String? field;

  ReviewModelException(this.message, {this.field});

  @override
  String toString() => 'ReviewModelException: $message${field != null ? ' (field: $field)' : ''}';
}

/// Product review model
class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String? orderId;
  final int rating; // 1-5 stars
  final String? title;
  final String? comment;
  final List<String> images; // Review images
  final bool isVerifiedPurchase;
  final bool isHelpful;
  final int helpfulCount;
  final bool isReported;
  final DateTime createdAt;
  final DateTime updatedAt;

  // User information (populated from joins)
  final String? userName;
  final String? userAvatar;

  // Product information (populated from joins)
  final String? productName;
  final String? productImage;

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    this.orderId,
    required this.rating,
    this.title,
    this.comment,
    this.images = const [],
    this.isVerifiedPurchase = false,
    this.isHelpful = false,
    this.helpfulCount = 0,
    this.isReported = false,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
    this.productName,
    this.productImage,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString();
      if (id == null || id.isEmpty) {
        throw ReviewModelException('Review ID is required', field: 'id');
      }

      final productId = json['product_id']?.toString();
      if (productId == null || productId.isEmpty) {
        throw ReviewModelException('Product ID is required', field: 'product_id');
      }

      final userId = json['user_id']?.toString();
      if (userId == null || userId.isEmpty) {
        throw ReviewModelException('User ID is required', field: 'user_id');
      }

      final rating = json['rating'] as int?;
      if (rating == null || rating < 1 || rating > 5) {
        throw ReviewModelException('Rating must be between 1 and 5', field: 'rating');
      }

      // Handle user information from joins
      String? userName;
      String? userAvatar;
      if (json['user_profiles'] != null) {
        final userProfile = json['user_profiles'];
        userName = userProfile['full_name']?.toString();
        userAvatar = userProfile['avatar_url']?.toString();
      } else {
        userName = json['user_name']?.toString();
        userAvatar = json['user_avatar']?.toString();
      }

      // Handle product information from joins
      String? productName;
      String? productImage;
      if (json['products'] != null) {
        final product = json['products'];
        productName = product['name']?.toString();
        final productImages = product['images'] as List?;
        if (productImages != null && productImages.isNotEmpty) {
          productImage = productImages.first?.toString();
        }
      } else {
        productName = json['product_name']?.toString();
        productImage = json['product_image']?.toString();
      }

      return ProductReview(
        id: id,
        productId: productId,
        userId: userId,
        orderId: json['order_id']?.toString(),
        rating: rating,
        title: json['title']?.toString(),
        comment: json['comment']?.toString(),
        images: _parseStringList(json['images']),
        isVerifiedPurchase: json['is_verified_purchase'] as bool? ?? false,
        isHelpful: json['is_helpful'] as bool? ?? false,
        helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
        isReported: json['is_reported'] as bool? ?? false,
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
        userName: userName,
        userAvatar: userAvatar,
        productName: productName,
        productImage: productImage,
      );
    } catch (e) {
      if (e is ReviewModelException) rethrow;
      throw ReviewModelException('Failed to parse product review JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'order_id': orderId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'is_verified_purchase': isVerifiedPurchase,
      'is_helpful': isHelpful,
      'helpful_count': helpfulCount,
      'is_reported': isReported,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_name': userName,
      'user_avatar': userAvatar,
      'product_name': productName,
      'product_image': productImage,
    };
  }

  /// Helper method to parse string lists safely
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  /// Helper method to parse DateTime safely
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Get star rating display
  String get starRating => '★' * rating + '☆' * (5 - rating);

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years} year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months} month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get reviewer display name
  String get reviewerName {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }
    return 'Anonymous';
  }

  /// Check if review has content
  bool get hasContent {
    return (title != null && title!.isNotEmpty) || 
           (comment != null && comment!.isNotEmpty) || 
           images.isNotEmpty;
  }

  /// Validate review data
  List<String> validate() {
    final errors = <String>[];

    if (productId.isEmpty) {
      errors.add('Product ID is required');
    }
    if (userId.isEmpty) {
      errors.add('User ID is required');
    }
    if (rating < 1 || rating > 5) {
      errors.add('Rating must be between 1 and 5');
    }
    if (title != null && title!.length > 100) {
      errors.add('Title must be 100 characters or less');
    }
    if (comment != null && comment!.length > 1000) {
      errors.add('Comment must be 1000 characters or less');
    }

    return errors;
  }

  /// Check if review is valid
  bool get isValid => validate().isEmpty;

  /// Create a copy with updated fields
  ProductReview copyWith({
    String? id,
    String? productId,
    String? userId,
    String? orderId,
    int? rating,
    String? title,
    String? comment,
    List<String>? images,
    bool? isVerifiedPurchase,
    bool? isHelpful,
    int? helpfulCount,
    bool? isReported,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatar,
    String? productName,
    String? productImage,
  }) {
    return ProductReview(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      isHelpful: isHelpful ?? this.isHelpful,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isReported: isReported ?? this.isReported,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
    );
  }
}

/// Review summary for products
class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // rating -> count
  final List<ProductReview> recentReviews;

  ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.recentReviews,
  });

  factory ReviewSummary.fromReviews(List<ProductReview> reviews) {
    if (reviews.isEmpty) {
      return ReviewSummary(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        recentReviews: [],
      );
    }

    final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    final ratingDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = reviews.where((review) => review.rating == i).length;
    }

    // Get recent reviews (last 10)
    final sortedReviews = List<ProductReview>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentReviews = sortedReviews.take(10).toList();

    return ReviewSummary(
      averageRating: averageRating,
      totalReviews: reviews.length,
      ratingDistribution: ratingDistribution,
      recentReviews: recentReviews,
    );
  }

  /// Get percentage for a specific rating
  double getPercentageForRating(int rating) {
    if (totalReviews == 0) return 0.0;
    final count = ratingDistribution[rating] ?? 0;
    return (count / totalReviews) * 100;
  }

  /// Get star rating display
  String get starRating {
    final fullStars = averageRating.floor();
    final hasHalfStar = (averageRating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return '★' * fullStars + 
           (hasHalfStar ? '☆' : '') + 
           '☆' * emptyStars;
  }

  /// Get formatted average rating
  String get formattedRating => averageRating.toStringAsFixed(1);
}
