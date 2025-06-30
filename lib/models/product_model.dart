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
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'],
      brand: json['brand'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      weightVolume: json['weight_volume'],
      nutritionalInfo: json['nutritional_info'] as Map<String, dynamic>?,
      ingredients: json['ingredients'],
      allergens: List<String>.from(json['allergens'] ?? []),
      storageInstructions: json['storage_instructions'],
      originCountry: json['origin_country'],
      isOrganic: json['is_organic'] ?? false,
      isActive: json['is_active'] ?? true,
      images: List<String>.from(json['images'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      availableQuantity: json['available_quantity'] ?? 0,
      averageRating: json['average_rating']?.toDouble(),
      reviewCount: json['review_count'] ?? 0,
      isInStock: json['is_in_stock'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
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
}
