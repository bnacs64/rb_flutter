/// Custom exception for product model errors
class ProductModelException implements Exception {
  final String message;
  final String? field;

  ProductModelException(this.message, {this.field});

  @override
  String toString() =>
      'ProductModelException: $message${field != null ? ' (field: $field)' : ''}';
}

/// Product model that matches Supabase database schema
class Product {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String? categoryName;
  final String brand;
  final double price;
  final String unit;
  final String? weightVolume;
  final Map<String, dynamic>? nutritionalInfo;
  final String? ingredients;
  final List<String> allergens;
  final String? storageInstructions;
  final String? originCountry;
  final bool isOrganic;
  final bool isActive;
  final List<String> images;
  final List<String> tags;
  final int availableQuantity;
  final double? averageRating;
  final int reviewCount;
  final bool isInStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    this.categoryName,
    required this.brand,
    required this.price,
    required this.unit,
    this.weightVolume,
    this.nutritionalInfo,
    this.ingredients,
    this.allergens = const [],
    this.storageInstructions,
    this.originCountry,
    this.isOrganic = false,
    this.isActive = true,
    this.images = const [],
    this.tags = const [],
    this.availableQuantity = 0,
    this.averageRating,
    this.reviewCount = 0,
    this.isInStock = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      final id = json['id']?.toString();
      if (id == null || id.isEmpty) {
        throw ProductModelException('Product ID is required', field: 'id');
      }

      final name = json['name']?.toString();
      if (name == null || name.isEmpty) {
        throw ProductModelException('Product name is required', field: 'name');
      }

      final price = json['price'];
      if (price == null) {
        throw ProductModelException('Product price is required',
            field: 'price');
      }

      // Handle different response formats for category name
      String? categoryName = json['category_name']?.toString();
      if (categoryName == null && json['categories'] != null) {
        // Handle table join format: categories: { name: "..." }
        final categories = json['categories'];
        if (categories is Map<String, dynamic>) {
          categoryName = categories['name']?.toString();
        }
      }

      // Handle different response formats for inventory data
      int availableQuantity = 0;
      bool isInStock = false;

      if (json['available_quantity'] != null) {
        availableQuantity = (json['available_quantity'] as num).toInt();
      } else if (json['inventory'] != null) {
        // Handle table join format: inventory: { quantity_available: ... }
        final inventory = json['inventory'];
        if (inventory is Map<String, dynamic>) {
          availableQuantity =
              (inventory['quantity_available'] as num?)?.toInt() ?? 0;
        }
      }

      if (json['is_in_stock'] != null) {
        isInStock = json['is_in_stock'] as bool;
      } else {
        isInStock = availableQuantity > 0;
      }

      // Handle different response formats for rating data
      double? averageRating;
      int reviewCount = 0;

      if (json['average_rating'] != null) {
        averageRating = (json['average_rating'] as num).toDouble();
      }

      if (json['review_count'] != null) {
        reviewCount = (json['review_count'] as num).toInt();
      } else if (json['product_reviews'] != null) {
        // Handle table join format: product_reviews: [{ rating: ... }, ...]
        final reviews = json['product_reviews'];
        if (reviews is List) {
          reviewCount = reviews.length;
          if (reviews.isNotEmpty) {
            final totalRating = reviews.fold<double>(0, (sum, review) {
              return sum + ((review['rating'] as num?)?.toDouble() ?? 0);
            });
            averageRating = totalRating / reviews.length;
          }
        }
      }

      return Product(
        id: id,
        name: name,
        description: json['description']?.toString() ?? '',
        categoryId: json['category_id']?.toString() ?? '',
        categoryName: categoryName,
        brand: json['brand']?.toString() ?? '',
        price: (price as num).toDouble(),
        unit: json['unit']?.toString() ?? '',
        weightVolume: json['weight_volume']?.toString(),
        nutritionalInfo: json['nutritional_info'] as Map<String, dynamic>?,
        ingredients: json['ingredients']?.toString(),
        allergens: _parseStringList(json['allergens']),
        storageInstructions: json['storage_instructions']?.toString(),
        originCountry: json['origin_country']?.toString(),
        isOrganic: json['is_organic'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        images: _parseStringList(json['images']),
        tags: _parseStringList(json['tags']),
        availableQuantity: availableQuantity,
        averageRating: averageRating,
        reviewCount: reviewCount,
        isInStock: isInStock,
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
    } catch (e) {
      if (e is ProductModelException) rethrow;
      throw ProductModelException('Failed to parse product JSON: $e');
    }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'brand': brand,
      'price': price,
      'unit': unit,
      'weight_volume': weightVolume,
      'nutritional_info': nutritionalInfo,
      'ingredients': ingredients,
      'allergens': allergens,
      'storage_instructions': storageInstructions,
      'origin_country': originCountry,
      'is_organic': isOrganic,
      'is_active': isActive,
      'images': images,
      'tags': tags,
      'available_quantity': availableQuantity,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'is_in_stock': isInStock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get the primary image URL
  String get primaryImage => images.isNotEmpty ? images.first : '';

  /// Check if product has discount
  bool get hasDiscount => false; // Will be calculated based on promotions

  /// Get discount percentage (will be calculated from promotions)
  int get discountPercent => 0;

  /// Get discounted price (will be calculated from promotions)
  double get discountedPrice => price;

  /// Validate product data
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) {
      errors.add('Product ID is required');
    }
    if (name.isEmpty) {
      errors.add('Product name is required');
    }
    if (price < 0) {
      errors.add('Product price cannot be negative');
    }
    if (categoryId.isEmpty) {
      errors.add('Category ID is required');
    }
    if (brand.isEmpty) {
      errors.add('Brand is required');
    }
    if (unit.isEmpty) {
      errors.add('Unit is required');
    }
    if (availableQuantity < 0) {
      errors.add('Available quantity cannot be negative');
    }
    if (averageRating != null && (averageRating! < 0 || averageRating! > 5)) {
      errors.add('Average rating must be between 0 and 5');
    }
    if (reviewCount < 0) {
      errors.add('Review count cannot be negative');
    }

    return errors;
  }

  /// Check if product is valid
  bool get isValid => validate().isEmpty;

  /// Create a copy of the product with updated fields
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    String? brand,
    double? price,
    String? unit,
    String? weightVolume,
    Map<String, dynamic>? nutritionalInfo,
    String? ingredients,
    List<String>? allergens,
    String? storageInstructions,
    String? originCountry,
    bool? isOrganic,
    bool? isActive,
    List<String>? images,
    List<String>? tags,
    int? availableQuantity,
    double? averageRating,
    int? reviewCount,
    bool? isInStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      weightVolume: weightVolume ?? this.weightVolume,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      originCountry: originCountry ?? this.originCountry,
      isOrganic: isOrganic ?? this.isOrganic,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      isInStock: isInStock ?? this.isInStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
