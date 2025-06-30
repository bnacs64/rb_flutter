# 🎯 Next Iteration Tasks - UI-Backend Integration

## Overview
This document outlines the critical tasks needed to complete the integration between the Flutter UI and Supabase backend for the grocery store application.

## 🔥 **Priority 1: Critical Fixes (Week 1)**

### Task 1.1: Fix ProductService Issues
**Status:** 🔴 Critical  
**Estimated Time:** 2-3 days

**Issues to Fix:**
- [ ] Update `searchProducts()` method to match backend RPC signature
- [ ] Fix inconsistent data mapping between table queries and RPC functions
- [ ] Implement proper `getFlashSaleProducts()` method
- [ ] Fix `getBestSellersProducts()` to use actual sales data
- [ ] Add proper error handling for all RPC calls

**Implementation Details:**
```dart
// Update search function signature
Future<List<Product>> searchProducts(String query, {
  List<String>? categoryIds,
  double? minPrice,
  double? maxPrice,
  bool? isOrganic,
  bool inStockOnly = true,
  String sortBy = 'name_asc',
  int limit = 20,
}) async {
  final response = await _client.rpc('search_products', params: {
    'search_query': query,
    'category_ids': categoryIds,
    'min_price': minPrice,
    'max_price': maxPrice,
    'is_organic_filter': isOrganic,
    'in_stock_only': inStockOnly,
    'sort_by': sortBy,
    'limit_count': limit,
  });
}
```

### Task 1.2: Fix CartService Issues
**Status:** 🔴 Critical  
**Estimated Time:** 1-2 days

**Issues to Fix:**
- [ ] Fix `getCartItems()` return type mismatch
- [ ] Implement proper CartSummary calculation
- [ ] Add missing cart manipulation methods
- [ ] Fix error handling consistency

**Implementation Details:**
```dart
Future<CartSummary> getCartItems() async {
  final response = await _client.rpc('get_cart_items', params: {
    'user_id_param': userId,
  });
  
  final items = (response as List)
      .map((json) => CartItem.fromJson(json))
      .toList();
  
  return CartSummary.fromItems(items);
}
```

### Task 1.3: Update Product Model
**Status:** 🔴 Critical  
**Estimated Time:** 1 day

**Updates Needed:**
- [ ] Add missing fields (`averageRating`, `reviewCount`, `isInStock`, `availableQuantity`)
- [ ] Fix `fromJson()` to handle both table and RPC response formats
- [ ] Add validation for required fields
- [ ] Update `toJson()` method accordingly

## ⚡ **Priority 2: High Priority (Week 2)**

### Task 2.1: Create OrderService
**Status:** 🟡 High Priority  
**Estimated Time:** 3-4 days

**Methods to Implement:**
- [ ] `createOrderFromCart()` - Create order from current cart
- [ ] `getUserOrders()` - Get user's order history
- [ ] `getOrderDetails()` - Get detailed order information
- [ ] `cancelOrder()` - Cancel pending orders
- [ ] `trackOrder()` - Get order status and tracking info

### Task 2.2: Create AddressService
**Status:** 🟡 High Priority  
**Estimated Time:** 2-3 days

**Methods to Implement:**
- [ ] `getUserAddresses()` - Get user's saved addresses
- [ ] `addAddress()` - Add new delivery address
- [ ] `updateAddress()` - Update existing address
- [ ] `deleteAddress()` - Remove address
- [ ] `getDeliveryZones()` - Get available delivery zones
- [ ] `getAvailableSlots()` - Get delivery time slots

### Task 2.3: Create Missing Models
**Status:** 🟡 High Priority  
**Estimated Time:** 2 days

**Models to Create:**
- [ ] `Order` model with complete order information
- [ ] `OrderItem` model for individual order items
- [ ] `CustomerAddress` model for delivery addresses
- [ ] `DeliveryZone` model for delivery areas
- [ ] `DeliveryTimeSlot` model for scheduling
- [ ] `ProductReview` model for reviews and ratings

### Task 2.4: Update AuthService
**Status:** 🟡 High Priority  
**Estimated Time:** 1-2 days

**Methods to Add:**
- [ ] `getUserProfile()` using RPC function
- [ ] `updateUserProfile()` for profile updates
- [ ] `changePassword()` for password changes
- [ ] `resetPassword()` for password recovery
- [ ] `deleteAccount()` for account deletion

## 📱 **Priority 3: Medium Priority (Week 3)**

### Task 3.1: Enhance Product Cards
**Status:** 🟠 Medium Priority  
**Estimated Time:** 2-3 days

**Features to Add:**
- [ ] Wishlist toggle button with heart icon
- [ ] "Add to Cart" button with quantity selector
- [ ] Stock status indicator (In Stock/Out of Stock)
- [ ] Star ratings display
- [ ] Quick view modal for product details

### Task 3.2: Enhance Search Functionality
**Status:** 🟠 Medium Priority  
**Estimated Time:** 3-4 days

**Features to Add:**
- [ ] Advanced filters (price range, category, organic)
- [ ] Sorting options (price, rating, popularity)
- [ ] Search suggestions and autocomplete
- [ ] Recent searches history
- [ ] Search results pagination

### Task 3.3: Enhance Cart Screen
**Status:** 🟠 Medium Priority  
**Estimated Time:** 2-3 days

**Features to Add:**
- [ ] Quantity increment/decrement buttons
- [ ] Remove item functionality
- [ ] Delivery options selection
- [ ] Promo code input and validation
- [ ] Order summary with taxes and fees

### Task 3.4: Create ReviewService
**Status:** 🟠 Medium Priority  
**Estimated Time:** 2 days

**Methods to Implement:**
- [ ] `getProductReviews()` - Get reviews for a product
- [ ] `addReview()` - Add new product review
- [ ] `updateReview()` - Update existing review
- [ ] `deleteReview()` - Remove review
- [ ] `getMyReviews()` - Get user's reviews

### Task 3.5: Create WishlistService
**Status:** 🟠 Medium Priority  
**Estimated Time:** 1-2 days

**Methods to Implement:**
- [ ] `getWishlistItems()` - Get user's wishlist
- [ ] `addToWishlist()` - Add product to wishlist
- [ ] `removeFromWishlist()` - Remove from wishlist
- [ ] `isInWishlist()` - Check if product is in wishlist
- [ ] `clearWishlist()` - Clear entire wishlist

## 🎨 **Priority 4: Low Priority (Week 4)**

### Task 4.1: Implement State Management
**Status:** 🟢 Low Priority  
**Estimated Time:** 3-4 days

**Providers to Create:**
- [ ] `CartProvider` for cart state management
- [ ] `AuthProvider` for authentication state
- [ ] `ProductProvider` for product data caching
- [ ] `WishlistProvider` for wishlist management
- [ ] `OrderProvider` for order tracking

### Task 4.2: Add Error Handling & Loading States
**Status:** 🟢 Low Priority  
**Estimated Time:** 2-3 days

**Components to Add:**
- [ ] `ApiException` class for standardized errors
- [ ] `LoadingState<T>` wrapper for async operations
- [ ] Global error handling middleware
- [ ] Loading indicators for all async operations
- [ ] Retry mechanisms for failed requests

### Task 4.3: Performance Optimizations
**Status:** 🟢 Low Priority  
**Estimated Time:** 2-3 days

**Optimizations to Add:**
- [ ] `CacheService` for data caching
- [ ] Image caching for product images
- [ ] Pagination for large data sets
- [ ] Lazy loading for product lists
- [ ] Background sync for cart updates

### Task 4.4: Security Enhancements
**Status:** 🟢 Low Priority  
**Estimated Time:** 1-2 days

**Security Features:**
- [ ] Input validation for all forms
- [ ] SQL injection prevention
- [ ] Permission checks before sensitive operations
- [ ] Rate limiting for API calls
- [ ] Secure storage for sensitive data

## 📋 **Testing & Quality Assurance**

### Task 5.1: Integration Testing
**Status:** 🟢 Ongoing  
**Estimated Time:** 2-3 days

**Tests to Create:**
- [ ] Service integration tests with real Supabase backend
- [ ] UI widget tests for all components
- [ ] End-to-end user flow tests
- [ ] Performance tests for large datasets
- [ ] Error handling tests

### Task 5.2: Form Validation
**Status:** 🟢 Ongoing  
**Estimated Time:** 1-2 days

**Validations to Add:**
- [ ] Email validation for authentication
- [ ] Phone number validation for profiles
- [ ] Address validation for delivery
- [ ] Payment validation for checkout
- [ ] Product quantity validation

## 🎯 **Success Metrics**

### Week 1 Goals:
- [ ] All critical ProductService and CartService issues resolved
- [ ] Basic product browsing and cart functionality working

### Week 2 Goals:
- [ ] Order placement functionality complete
- [ ] Address management working
- [ ] User authentication fully functional

### Week 3 Goals:
- [ ] Enhanced UI components with full functionality
- [ ] Search and filtering working properly
- [ ] Review and wishlist features implemented

### Week 4 Goals:
- [ ] State management implemented
- [ ] Performance optimizations in place
- [ ] Comprehensive testing completed

## 📞 **Support & Resources**

- **Supabase Dashboard:** https://supabase.com/dashboard/project/nlizabhdxklazxgiflbb
- **API Documentation:** `docs/API_REFERENCE.md`
- **Backend Schema:** `README_SUPABASE.md`
- **Test Script:** `dart run test_supabase_connection.dart`

---

**Last Updated:** December 30, 2024  
**Next Review:** January 6, 2025
