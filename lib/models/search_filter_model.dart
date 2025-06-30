/// Search filter model for advanced product filtering
class SearchFilters {
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? categoryIds;
  final List<String>? brandIds;
  final bool? isOrganic;
  final bool inStockOnly;
  final double? minRating;
  final String sortBy;
  final int limit;
  final int offset;

  const SearchFilters({
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.categoryIds,
    this.brandIds,
    this.isOrganic,
    this.inStockOnly = true,
    this.minRating,
    this.sortBy = 'relevance',
    this.limit = 20,
    this.offset = 0,
  });

  /// Create a copy with updated fields
  SearchFilters copyWith({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    List<String>? categoryIds,
    List<String>? brandIds,
    bool? isOrganic,
    bool? inStockOnly,
    double? minRating,
    String? sortBy,
    int? limit,
    int? offset,
  }) {
    return SearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      categoryIds: categoryIds ?? this.categoryIds,
      brandIds: brandIds ?? this.brandIds,
      isOrganic: isOrganic ?? this.isOrganic,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Clear all filters except search query
  SearchFilters clearFilters() {
    return SearchFilters(
      searchQuery: searchQuery,
      sortBy: 'relevance',
      inStockOnly: true,
      limit: limit,
      offset: 0,
    );
  }

  /// Check if any filters are applied
  bool get hasActiveFilters {
    return minPrice != null ||
           maxPrice != null ||
           (categoryIds != null && categoryIds!.isNotEmpty) ||
           (brandIds != null && brandIds!.isNotEmpty) ||
           isOrganic != null ||
           !inStockOnly ||
           minRating != null ||
           sortBy != 'relevance';
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (minPrice != null || maxPrice != null) count++;
    if (categoryIds != null && categoryIds!.isNotEmpty) count++;
    if (brandIds != null && brandIds!.isNotEmpty) count++;
    if (isOrganic != null) count++;
    if (!inStockOnly) count++;
    if (minRating != null) count++;
    if (sortBy != 'relevance') count++;
    return count;
  }

  /// Convert to map for API calls
  Map<String, dynamic> toMap() {
    return {
      'search_query': searchQuery,
      'min_price': minPrice,
      'max_price': maxPrice,
      'category_ids': categoryIds,
      'brand_ids': brandIds,
      'is_organic_filter': isOrganic,
      'in_stock_only': inStockOnly,
      'min_rating': minRating,
      'sort_by': sortBy,
      'limit_count': limit,
      'offset_count': offset,
    };
  }

  @override
  String toString() {
    return 'SearchFilters(query: $searchQuery, filters: ${activeFilterCount})';
  }
}

/// Sort options for search results
class SortOption {
  final String value;
  final String label;
  final String description;

  const SortOption({
    required this.value,
    required this.label,
    required this.description,
  });

  static const List<SortOption> options = [
    SortOption(
      value: 'relevance',
      label: 'Relevance',
      description: 'Most relevant results first',
    ),
    SortOption(
      value: 'price_asc',
      label: 'Price: Low to High',
      description: 'Cheapest products first',
    ),
    SortOption(
      value: 'price_desc',
      label: 'Price: High to Low',
      description: 'Most expensive products first',
    ),
    SortOption(
      value: 'rating_desc',
      label: 'Customer Rating',
      description: 'Highest rated products first',
    ),
    SortOption(
      value: 'newest',
      label: 'Newest First',
      description: 'Recently added products first',
    ),
    SortOption(
      value: 'best_selling',
      label: 'Best Selling',
      description: 'Most popular products first',
    ),
    SortOption(
      value: 'name_asc',
      label: 'A-Z',
      description: 'Alphabetical order',
    ),
    SortOption(
      value: 'name_desc',
      label: 'Z-A',
      description: 'Reverse alphabetical order',
    ),
  ];

  static SortOption? findByValue(String value) {
    try {
      return options.firstWhere((option) => option.value == value);
    } catch (e) {
      return null;
    }
  }
}

/// Price range options for quick selection
class PriceRange {
  final double? min;
  final double? max;
  final String label;

  const PriceRange({
    this.min,
    this.max,
    required this.label,
  });

  static const List<PriceRange> ranges = [
    PriceRange(label: 'Any Price'),
    PriceRange(min: 0, max: 10, label: 'Under \$10'),
    PriceRange(min: 10, max: 25, label: '\$10 - \$25'),
    PriceRange(min: 25, max: 50, label: '\$25 - \$50'),
    PriceRange(min: 50, max: 100, label: '\$50 - \$100'),
    PriceRange(min: 100, label: 'Over \$100'),
  ];

  bool matches(double? minPrice, double? maxPrice) {
    return min == minPrice && max == maxPrice;
  }
}

/// Rating filter options
class RatingFilter {
  final double? minRating;
  final String label;
  final String description;

  const RatingFilter({
    this.minRating,
    required this.label,
    required this.description,
  });

  static const List<RatingFilter> options = [
    RatingFilter(
      label: 'Any Rating',
      description: 'All products',
    ),
    RatingFilter(
      minRating: 4.0,
      label: '4+ Stars',
      description: 'Highly rated products',
    ),
    RatingFilter(
      minRating: 3.0,
      label: '3+ Stars',
      description: 'Good rated products',
    ),
    RatingFilter(
      minRating: 2.0,
      label: '2+ Stars',
      description: 'Fair rated products',
    ),
  ];

  bool matches(double? currentMinRating) {
    return minRating == currentMinRating;
  }
}

/// Search suggestion model
class SearchSuggestion {
  final String text;
  final SearchSuggestionType type;
  final String? categoryId;
  final String? productId;

  const SearchSuggestion({
    required this.text,
    required this.type,
    this.categoryId,
    this.productId,
  });
}

enum SearchSuggestionType {
  product,
  category,
  brand,
  recent,
}

/// Search history item
class SearchHistoryItem {
  final String query;
  final DateTime timestamp;
  final int resultCount;

  const SearchHistoryItem({
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['result_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'result_count': resultCount,
    };
  }
}
