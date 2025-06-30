import 'package:flutter/material.dart';
import 'package:shop/components/product/enhanced_product_card.dart';
import 'package:shop/components/search/advanced_filter_panel.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/models/search_filter_model.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/search/views/components/search_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  List<SearchHistoryItem> _searchHistory = [];
  List<SearchSuggestion> _searchSuggestions = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;
  bool _showSuggestions = false;
  SearchFilters _currentFilters = const SearchFilters();

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
      });
    } else if (query.length >= 2) {
      _generateSearchSuggestions(query);
    }
  }

  void _generateSearchSuggestions(String query) {
    // Generate suggestions based on search history and common terms
    final suggestions = <SearchSuggestion>[];

    // Add recent searches that match
    for (final historyItem in _searchHistory) {
      if (historyItem.query.toLowerCase().contains(query.toLowerCase()) &&
          historyItem.query != query) {
        suggestions.add(SearchSuggestion(
          text: historyItem.query,
          type: SearchSuggestionType.recent,
        ));
      }
    }

    // Add common product suggestions (in a real app, this would come from an API)
    final commonSuggestions = [
      'organic vegetables',
      'fresh fruits',
      'dairy products',
      'whole wheat bread',
      'chicken breast',
      'basmati rice',
    ];

    for (final suggestion in commonSuggestions) {
      if (suggestion.toLowerCase().contains(query.toLowerCase()) &&
          !suggestions.any((s) => s.text == suggestion)) {
        suggestions.add(SearchSuggestion(
          text: suggestion,
          type: SearchSuggestionType.product,
        ));
      }
    }

    setState(() {
      _searchSuggestions = suggestions.take(5).toList();
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('search_history') ?? [];
      final history = historyJson
          .map((json) => SearchHistoryItem.fromJson(jsonDecode(json)))
          .toList();

      // Sort by timestamp, most recent first
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _searchHistory =
            history.take(10).toList(); // Keep only last 10 searches
      });
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> _saveSearchToHistory(String query, int resultCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyItem = SearchHistoryItem(
        query: query,
        timestamp: DateTime.now(),
        resultCount: resultCount,
      );

      // Remove existing entry with same query
      _searchHistory.removeWhere((item) => item.query == query);

      // Add new entry at the beginning
      _searchHistory.insert(0, historyItem);

      // Keep only last 10 searches
      _searchHistory = _searchHistory.take(10).toList();

      // Save to preferences
      final historyJson =
          _searchHistory.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList('search_history', historyJson);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _performSearch([String? query]) async {
    final searchQuery = query ?? _searchController.text.trim();
    if (searchQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
      _showSuggestions = false;
    });

    try {
      final filters = _currentFilters.copyWith(searchQuery: searchQuery);
      final results = await _productService.searchProducts(
        searchQuery,
        categoryIds: filters.categoryIds,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        isOrganic: filters.isOrganic,
        inStockOnly: filters.inStockOnly,
        sortBy: filters.sortBy,
        limit: filters.limit,
        offset: filters.offset,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // Save to search history
      await _saveSearchToHistory(searchQuery, results.length);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterPanel(
        initialFilters: _currentFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _currentFilters = filters;
          });
        },
        onApplyFilters: () {
          _performSearch();
        },
        onClearFilters: () {
          setState(() {
            _currentFilters = const SearchFilters();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar with Filter Button
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SearchForm(
                controller: _searchController,
                onSubmitted: _performSearch,
                onTabFilter: _showFilterPanel,
                onChanged: (value) {
                  // Real-time suggestions are handled by listener
                },
              ),
            ),

            // Active Filters Display
            if (_currentFilters.hasActiveFilters)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _buildActiveFilterChips(),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentFilters = const SearchFilters();
                        });
                        if (_hasSearched) _performSearch();
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

            // Search Results Count
            if (_hasSearched && !_isLoading && _error == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_searchResults.length} products found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    // Sort dropdown
                    DropdownButton<String>(
                      value: _currentFilters.sortBy,
                      underline: const SizedBox(),
                      items: SortOption.options.map((option) {
                        return DropdownMenuItem(
                          value: option.value,
                          child: Text(option.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _currentFilters =
                                _currentFilters.copyWith(sortBy: value);
                          });
                          _performSearch();
                        }
                      },
                    ),
                  ],
                ),
              ),

            Expanded(
              child: Stack(
                children: [
                  _buildSearchContent(),

                  // Search Suggestions Overlay
                  if (_showSuggestions && _searchSuggestions.isNotEmpty)
                    _buildSuggestionsOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Search for products',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _performSearch(_searchController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(defaultPadding),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
        mainAxisSpacing: defaultPadding,
        crossAxisSpacing: defaultPadding,
        childAspectRatio: 0.66,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return EnhancedProductCard(
          product: _searchResults[index],
          onTap: () {
            Navigator.pushNamed(context, productDetailsScreenRoute,
                arguments: _searchResults[index]);
          },
        );
      },
    );
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    // Price range chip
    if (_currentFilters.minPrice != null || _currentFilters.maxPrice != null) {
      String priceText = '';
      if (_currentFilters.minPrice != null &&
          _currentFilters.maxPrice != null) {
        priceText =
            '\$${_currentFilters.minPrice!.toStringAsFixed(0)} - \$${_currentFilters.maxPrice!.toStringAsFixed(0)}';
      } else if (_currentFilters.minPrice != null) {
        priceText = 'Over \$${_currentFilters.minPrice!.toStringAsFixed(0)}';
      } else {
        priceText = 'Under \$${_currentFilters.maxPrice!.toStringAsFixed(0)}';
      }

      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(priceText),
            onDeleted: () {
              setState(() {
                _currentFilters = _currentFilters.copyWith(
                  minPrice: null,
                  maxPrice: null,
                );
              });
              if (_hasSearched) _performSearch();
            },
          ),
        ),
      );
    }

    // Category chips
    if (_currentFilters.categoryIds != null &&
        _currentFilters.categoryIds!.isNotEmpty) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text('${_currentFilters.categoryIds!.length} categories'),
            onDeleted: () {
              setState(() {
                _currentFilters = _currentFilters.copyWith(categoryIds: null);
              });
              if (_hasSearched) _performSearch();
            },
          ),
        ),
      );
    }

    // Organic filter chip
    if (_currentFilters.isOrganic != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(_currentFilters.isOrganic! ? 'Organic' : 'Non-Organic'),
            onDeleted: () {
              setState(() {
                _currentFilters = _currentFilters.copyWith(isOrganic: null);
              });
              if (_hasSearched) _performSearch();
            },
          ),
        ),
      );
    }

    // Rating filter chip
    if (_currentFilters.minRating != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label:
                Text('${_currentFilters.minRating!.toStringAsFixed(0)}+ stars'),
            onDeleted: () {
              setState(() {
                _currentFilters = _currentFilters.copyWith(minRating: null);
              });
              if (_hasSearched) _performSearch();
            },
          ),
        ),
      );
    }

    return chips;
  }

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      top: 0,
      left: defaultPadding,
      right: defaultPadding,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _searchSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _searchSuggestions[index];
              return ListTile(
                leading: Icon(
                  suggestion.type == SearchSuggestionType.recent
                      ? Icons.history
                      : Icons.search,
                  color: Colors.grey[600],
                ),
                title: Text(suggestion.text),
                onTap: () {
                  _searchController.text = suggestion.text;
                  _performSearch(suggestion.text);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
