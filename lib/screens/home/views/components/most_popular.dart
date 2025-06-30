import 'package:flutter/material.dart';
import 'package:shop/components/product/secondary_product_card.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/components/skleton/product/secondery_produts_skelton.dart';

import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class MostPopular extends StatefulWidget {
  const MostPopular({
    super.key,
  });

  @override
  State<MostPopular> createState() => _MostPopularState();
}

class _MostPopularState extends State<MostPopular> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMostPopularProducts();
  }

  Future<void> _loadMostPopularProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final products = await _productService.getPopularProducts(limit: 10);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Most popular",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (_isLoading)
          const SeconderyProductsSkelton()
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Text(
              'Error loading most popular products: $_error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )
        else if (_products.isEmpty)
          const Padding(
            padding: EdgeInsets.all(defaultPadding),
            child: Text('No popular products found'),
          )
        else
          SizedBox(
            height: 114,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _products.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  left: defaultPadding,
                  right: index == _products.length - 1 ? defaultPadding : 0,
                ),
                child: SecondaryProductCard(
                  image: _products[index].primaryImage,
                  brandName: _products[index].brand,
                  title: _products[index].name,
                  price: _products[index].price,
                  priceAfetDiscount:
                      _products[index].discountedPrice != _products[index].price
                          ? _products[index].discountedPrice
                          : null,
                  dicountpercent: _products[index].hasDiscount
                      ? _products[index].discountPercent
                      : null,
                  press: () {
                    Navigator.pushNamed(context, productDetailsScreenRoute,
                        arguments: _products[index]);
                  },
                ),
              ),
            ),
          )
      ],
    );
  }
}
