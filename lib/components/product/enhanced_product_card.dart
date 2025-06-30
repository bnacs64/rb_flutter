import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants.dart';
import '../../models/product_model.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';
import '../../services/review_service.dart';
import '../network_image_with_loader.dart';
import 'quick_view_modal.dart';

class EnhancedProductCard extends StatefulWidget {
  const EnhancedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showQuickActions = true,
    this.showWishlistButton = true,
    this.showAddToCartButton = true,
    this.showStockStatus = true,
    this.showRating = true,
    this.showQuickView = true,
  });

  final Product product;
  final VoidCallback? onTap;
  final bool showQuickActions;
  final bool showWishlistButton;
  final bool showAddToCartButton;
  final bool showStockStatus;
  final bool showRating;
  final bool showQuickView;

  @override
  State<EnhancedProductCard> createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<EnhancedProductCard>
    with TickerProviderStateMixin {
  final WishlistService _wishlistService = WishlistService();
  final CartService _cartService = CartService();
  final ReviewService _reviewService = ReviewService();

  bool _isInWishlist = false;
  bool _isLoadingWishlist = false;
  bool _isLoadingCart = false;
  int _cartQuantity = 1;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  late AnimationController _wishlistAnimationController;
  late AnimationController _cartAnimationController;
  late Animation<double> _wishlistScaleAnimation;
  late Animation<double> _cartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _wishlistAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _cartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _wishlistScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _wishlistAnimationController,
      curve: Curves.elasticOut,
    ));

    _cartScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _cartAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadInitialData() async {
    try {
      // Load wishlist status
      final isInWishlist =
          await _wishlistService.isInWishlist(widget.product.id);

      // Load review summary
      final reviewSummary =
          await _reviewService.getReviewSummary(widget.product.id);

      if (mounted) {
        setState(() {
          _isInWishlist = isInWishlist;
          _averageRating = reviewSummary.averageRating;
          _reviewCount = reviewSummary.totalReviews;
        });
      }
    } catch (e) {
      // Handle errors silently for now
      debugPrint('Error loading product card data: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    if (_isLoadingWishlist) return;

    setState(() {
      _isLoadingWishlist = true;
    });

    try {
      final newStatus =
          await _wishlistService.toggleWishlist(widget.product.id);

      if (mounted) {
        setState(() {
          _isInWishlist = newStatus;
          _isLoadingWishlist = false;
        });

        // Animate wishlist button
        _wishlistAnimationController.forward().then((_) {
          _wishlistAnimationController.reverse();
        });

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(newStatus ? 'Added to wishlist' : 'Removed from wishlist'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWishlist = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    if (_isLoadingCart || !widget.product.isInStock) return;

    setState(() {
      _isLoadingCart = true;
    });

    try {
      await _cartService.addToCart(widget.product.id, _cartQuantity);

      if (mounted) {
        setState(() {
          _isLoadingCart = false;
        });

        // Animate cart button
        _cartAnimationController.forward().then((_) {
          _cartAnimationController.reverse();
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Added $_cartQuantity ${widget.product.name} to cart'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () {
                // Navigate to cart screen
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCart = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showQuickView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickViewModal(
        product: widget.product,
        averageRating: _averageRating,
        reviewCount: _reviewCount,
        isInWishlist: _isInWishlist,
        onWishlistToggle: _toggleWishlist,
        onAddToCart: _addToCart,
      ),
    );
  }

  Widget _buildStockIndicator() {
    if (!widget.showStockStatus) return const SizedBox.shrink();

    if (!widget.product.isInStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (widget.product.availableQuantity < 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Only ${widget.product.availableQuantity} left',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'In Stock',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRatingDisplay() {
    if (!widget.showRating || _reviewCount == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < _averageRating.floor() ? Icons.star : Icons.star_border,
              size: 12,
              color: Colors.amber,
            );
          }),
        ),
        const SizedBox(width: 4),
        Text(
          '($_reviewCount)',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _wishlistAnimationController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.product.hasDiscount;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(defaultBorderRadious),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with overlays
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Main product image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(defaultBorderRadious),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(defaultBorderRadious),
                      ),
                      child: NetworkImageWithLoader(
                        widget.product.images.isNotEmpty
                            ? widget.product.images.first
                            : '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: errorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.product.discountPercent}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist button
                  if (widget.showWishlistButton)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedBuilder(
                        animation: _wishlistScaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _wishlistScaleAnimation.value,
                            child: GestureDetector(
                              onTap: _toggleWishlist,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _isLoadingWishlist
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        _isInWishlist
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 16,
                                        color: _isInWishlist
                                            ? Colors.red
                                            : Colors.grey[600],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Stock status indicator
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _buildStockIndicator(),
                  ),

                  // Quick view button
                  if (widget.showQuickView)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _showQuickView,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product information
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand name
                    Text(
                      widget.product.brand.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Product name
                    Text(
                      widget.product.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Rating
                    _buildRatingDisplay(),

                    const Spacer(),

                    // Price and Add to Cart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount) ...[
                                Text(
                                  '\$${widget.product.discountedPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${widget.product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ] else
                                Text(
                                  '\$${widget.product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Add to Cart Button
                        if (widget.showAddToCartButton)
                          AnimatedBuilder(
                            animation: _cartScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _cartScaleAnimation.value,
                                child: GestureDetector(
                                  onTap: widget.product.isInStock
                                      ? _addToCart
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: widget.product.isInStock
                                          ? primaryColor
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: _isLoadingCart
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.add_shopping_cart,
                                            size: 16,
                                            color: widget.product.isInStock
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
