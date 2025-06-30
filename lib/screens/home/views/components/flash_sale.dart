import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/components/skleton/product/products_skelton.dart';

import '/components/Banner/M/banner_m_with_counter.dart';
import '../../../../components/product/product_card.dart';
import '../../../../constants.dart';
import '../../../../models/product_model.dart';

class FlashSale extends StatefulWidget {
  const FlashSale({
    super.key,
  });

  @override
  State<FlashSale> createState() => _FlashSaleState();
}

class _FlashSaleState extends State<FlashSale> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFlashSaleProducts();
  }

  Future<void> _loadFlashSaleProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final products = await _productService.getFlashSaleProducts(limit: 10);

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
        // While loading show 👇
        // const BannerMWithCounterSkelton(),
        BannerMWithCounter(
          duration: const Duration(hours: 8),
          text: "Super Flash Sale \n50% Off",
          press: () {},
        ),
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Flash sale",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (_isLoading)
          const ProductsSkelton()
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Text(
              'Error loading flash sale products: $_error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )
        else if (_products.isEmpty)
          const Padding(
            padding: EdgeInsets.all(defaultPadding),
            child: Text('No flash sale products found'),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _products.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  left: defaultPadding,
                  right: index == _products.length - 1 ? defaultPadding : 0,
                ),
                child: ProductCard(
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
          ),
      ],
    );
  }
}
