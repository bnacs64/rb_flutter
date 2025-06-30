import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/search_filter_model.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

class AdvancedFilterPanel extends StatefulWidget {
  const AdvancedFilterPanel({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  final SearchFilters initialFilters;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;

  @override
  State<AdvancedFilterPanel> createState() => _AdvancedFilterPanelState();
}

class _AdvancedFilterPanelState extends State<AdvancedFilterPanel> {
  late SearchFilters _currentFilters;
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoadingCategories = false;

  // Price range controllers
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _initializePriceControllers();
    _loadCategories();
  }

  void _initializePriceControllers() {
    if (_currentFilters.minPrice != null) {
      _minPriceController.text = _currentFilters.minPrice!.toStringAsFixed(2);
    }
    if (_currentFilters.maxPrice != null) {
      _maxPriceController.text = _currentFilters.maxPrice!.toStringAsFixed(2);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await _categoryService.getRootCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      debugPrint('Error loading categories: $e');
    }
  }

  void _updateFilters(SearchFilters newFilters) {
    setState(() {
      _currentFilters = newFilters;
    });
    widget.onFiltersChanged(newFilters);
  }

  void _updatePriceRange(double? minPrice, double? maxPrice) {
    _updateFilters(_currentFilters.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    ));
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _updateFilters(_currentFilters.clearFilters());
                    _minPriceController.clear();
                    _maxPriceController.clear();
                    widget.onClearFilters();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range Section
                  _buildSectionTitle('Price Range'),
                  _buildPriceRangeSection(),
                  const SizedBox(height: 24),

                  // Categories Section
                  _buildSectionTitle('Categories'),
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),

                  // Organic Filter
                  _buildSectionTitle('Product Type'),
                  _buildOrganicSection(),
                  const SizedBox(height: 24),

                  // Stock Availability
                  _buildSectionTitle('Availability'),
                  _buildStockSection(),
                  const SizedBox(height: 24),

                  // Rating Filter
                  _buildSectionTitle('Customer Rating'),
                  _buildRatingSection(),
                  const SizedBox(height: 24),

                  // Sort Options
                  _buildSectionTitle('Sort By'),
                  _buildSortSection(),
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Apply Filters${_currentFilters.activeFilterCount > 0 ? ' (${_currentFilters.activeFilterCount})' : ''}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      children: [
        // Quick price range options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PriceRange.ranges.map((range) {
            final isSelected = range.matches(_currentFilters.minPrice, _currentFilters.maxPrice);
            return FilterChip(
              label: Text(range.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _updatePriceRange(range.min, range.max);
                  _minPriceController.text = range.min?.toStringAsFixed(2) ?? '';
                  _maxPriceController.text = range.max?.toStringAsFixed(2) ?? '';
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Custom price range inputs
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final minPrice = double.tryParse(value);
                  _updatePriceRange(minPrice, _currentFilters.maxPrice);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final maxPrice = double.tryParse(value);
                  _updatePriceRange(_currentFilters.minPrice, maxPrice);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _currentFilters.categoryIds?.contains(category.id) ?? false;
        return FilterChip(
          label: Text(category.name),
          selected: isSelected,
          onSelected: (selected) {
            List<String> categoryIds = List.from(_currentFilters.categoryIds ?? []);
            if (selected) {
              categoryIds.add(category.id);
            } else {
              categoryIds.remove(category.id);
            }
            _updateFilters(_currentFilters.copyWith(
              categoryIds: categoryIds.isEmpty ? null : categoryIds,
            ));
          },
        );
      }).toList(),
    );
  }

  Widget _buildOrganicSection() {
    return Column(
      children: [
        RadioListTile<bool?>(
          title: const Text('All Products'),
          value: null,
          groupValue: _currentFilters.isOrganic,
          onChanged: (value) {
            _updateFilters(_currentFilters.copyWith(isOrganic: value));
          },
        ),
        RadioListTile<bool?>(
          title: const Text('Organic Only'),
          value: true,
          groupValue: _currentFilters.isOrganic,
          onChanged: (value) {
            _updateFilters(_currentFilters.copyWith(isOrganic: value));
          },
        ),
        RadioListTile<bool?>(
          title: const Text('Non-Organic Only'),
          value: false,
          groupValue: _currentFilters.isOrganic,
          onChanged: (value) {
            _updateFilters(_currentFilters.copyWith(isOrganic: value));
          },
        ),
      ],
    );
  }

  Widget _buildStockSection() {
    return SwitchListTile(
      title: const Text('In Stock Only'),
      subtitle: const Text('Show only available products'),
      value: _currentFilters.inStockOnly,
      onChanged: (value) {
        _updateFilters(_currentFilters.copyWith(inStockOnly: value));
      },
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: RatingFilter.options.map((option) {
        final isSelected = option.matches(_currentFilters.minRating);
        return RadioListTile<double?>(
          title: Text(option.label),
          subtitle: Text(option.description),
          value: option.minRating,
          groupValue: _currentFilters.minRating,
          onChanged: (value) {
            _updateFilters(_currentFilters.copyWith(minRating: value));
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortSection() {
    return Column(
      children: SortOption.options.map((option) {
        final isSelected = option.value == _currentFilters.sortBy;
        return RadioListTile<String>(
          title: Text(option.label),
          subtitle: Text(option.description),
          value: option.value,
          groupValue: _currentFilters.sortBy,
          onChanged: (value) {
            if (value != null) {
              _updateFilters(_currentFilters.copyWith(sortBy: value));
            }
          },
        );
      }).toList(),
    );
  }
}
