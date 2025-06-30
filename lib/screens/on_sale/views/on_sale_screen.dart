import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/route/route_constants.dart';

import '../../../constants.dart';

class OnSaleScreen extends StatefulWidget {
  const OnSaleScreen({super.key});

  @override
  State<OnSaleScreen> createState() => _OnSaleScreenState();
}

class _OnSaleScreenState extends State<OnSaleScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaleProducts();
  }

  Future<void> _loadSaleProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load flash sale products as sale products
      final products = await _productService.getFlashSaleProducts(limit: 20);

      setState(() {
        _products = products;
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
        child: CustomScrollView(
          slivers: [
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Text(
                    'Error loading sale products: $_error',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              )
            else if (_products.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Text('No sale products found'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.0,
                    mainAxisSpacing: defaultPadding,
                    crossAxisSpacing: defaultPadding,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return ProductCard(
                        image: _products[index].primaryImage,
                        brandName: _products[index].brand,
                        title: _products[index].name,
                        price: _products[index].price,
                        priceAfetDiscount: _products[index].discountedPrice !=
                                _products[index].price
                            ? _products[index].discountedPrice
                            : null,
                        dicountpercent: _products[index].hasDiscount
                            ? _products[index].discountPercent
                            : null,
                        press: () {
                          Navigator.pushNamed(
                              context, productDetailsScreenRoute,
                              arguments: _products[index]);
                        },
                      );
                    },
                    childCount: _products.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
