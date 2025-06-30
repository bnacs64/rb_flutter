/// Promotion model that matches Supabase database schema
class Promotion {
  final String id;
  final String name;
  final String description;
  final String discountType; // 'percentage' or 'fixed_amount'
  final double discountValue;
  final double minimumOrderAmount;
  final DateTime startDate;
  final DateTime endDate;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;
  final List<String> applicableCategories;
  final List<String> applicableProducts;
  final String? bannerImageUrl;
  final String? bannerTitle;
  final String? bannerSubtitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount = 0,
    required this.startDate,
    required this.endDate,
    this.usageLimit,
    this.usageCount = 0,
    this.isActive = true,
    this.applicableCategories = const [],
    this.applicableProducts = const [],
    this.bannerImageUrl,
    this.bannerTitle,
    this.bannerSubtitle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      minimumOrderAmount: (json['minimum_order_amount'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      usageLimit: json['usage_limit'],
      usageCount: json['usage_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      applicableCategories: List<String>.from(json['applicable_categories'] ?? []),
      applicableProducts: List<String>.from(json['applicable_products'] ?? []),
      bannerImageUrl: json['banner_image_url'],
      bannerTitle: json['banner_title'],
      bannerSubtitle: json['banner_subtitle'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'minimum_order_amount': minimumOrderAmount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'is_active': isActive,
      'applicable_categories': applicableCategories,
      'applicable_products': applicableProducts,
      'banner_image_url': bannerImageUrl,
      'banner_title': bannerTitle,
      'banner_subtitle': bannerSubtitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if promotion is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDate) && 
           now.isBefore(endDate) &&
           (usageLimit == null || usageCount < usageLimit!);
  }

  /// Get discount percentage for display
  int get discountPercent {
    if (discountType == 'percentage') {
      return discountValue.round();
    }
    return 0;
  }

  /// Get discount amount for display
  double get discountAmount {
    if (discountType == 'fixed_amount') {
      return discountValue;
    }
    return 0;
  }

  /// Get banner title or fallback to name
  String get displayTitle => bannerTitle ?? name;

  /// Get banner subtitle or fallback to description
  String get displaySubtitle => bannerSubtitle ?? description;
}
