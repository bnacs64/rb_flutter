import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/services/category_service.dart';
import 'package:shop/screens/search/views/components/search_form.dart';

import 'components/expansion_category.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final categories =
          await _categoryService.getCategoriesWithSubcategories();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: SearchForm(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: defaultPadding / 2),
              child: Text(
                "Categories",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Text(
                    'Error loading categories: $_error',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              )
            else if (_categories.isEmpty)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Text('No categories found'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) => ExpansionCategory(
                    svgSrc: _getSvgForCategory(_categories[index].name),
                    title: _categories[index].name,
                    subCategory: _categories[index].subCategories ?? [],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  String _getSvgForCategory(String categoryName) {
    // Map category names to SVG assets
    switch (categoryName.toLowerCase()) {
      case 'fruits':
      case 'vegetables':
        return 'assets/icons/Sale.svg';
      case 'dairy':
        return 'assets/icons/Man.svg';
      case 'meat':
        return 'assets/icons/Woman.svg';
      case 'bakery':
        return 'assets/icons/Child.svg';
      default:
        return 'assets/icons/Sale.svg';
    }
  }
}
