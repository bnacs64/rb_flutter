import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/services/category_service.dart';

import '../../../../constants.dart';

class Categories extends StatefulWidget {
  const Categories({
    super.key,
  });

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;

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

      final categories = await _categoryService.getRootCategories();
      
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
    if (_isLoading) {
      return const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Text(
          'Error loading categories: $_error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    // Add "All Categories" as the first item
    final allCategories = [
      Category(
        id: 'all',
        name: 'All Categories',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ..._categories,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...List.generate(
            allCategories.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                  left: index == 0 ? defaultPadding : defaultPadding / 2,
                  right: index == allCategories.length - 1 ? defaultPadding : 0),
              child: CategoryBtn(
                category: allCategories[index].name,
                svgSrc: _getSvgForCategory(allCategories[index].name),
                isActive: index == _selectedIndex,
                press: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  _handleCategoryPress(allCategories[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getSvgForCategory(String categoryName) {
    // Map category names to SVG assets
    switch (categoryName.toLowerCase()) {
      case 'all categories':
        return null;
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

  void _handleCategoryPress(Category category) {
    if (category.id == 'all') {
      // Handle "All Categories" - could navigate to a products screen
      return;
    }

    // Handle specific category navigation
    // You can add navigation logic here based on category
    switch (category.name.toLowerCase()) {
      case 'fruits':
      case 'vegetables':
        Navigator.pushNamed(context, onSaleScreenRoute);
        break;
      case 'bakery':
        Navigator.pushNamed(context, kidsScreenRoute);
        break;
      default:
        // Navigate to a general category products screen
        break;
    }
  }
}

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    this.svgSrc,
    required this.isActive,
    required this.press,
  });

  final String category;
  final String? svgSrc;
  final bool isActive;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : Theme.of(context).dividerColor),
          borderRadius: const BorderRadius.all(Radius.circular(30)),
        ),
        child: Row(
          children: [
            if (svgSrc != null)
              SvgPicture.asset(
                svgSrc!,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.white : Theme.of(context).iconTheme.color!,
                  BlendMode.srcIn,
                ),
              ),
            if (svgSrc != null) const SizedBox(width: defaultPadding / 2),
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
