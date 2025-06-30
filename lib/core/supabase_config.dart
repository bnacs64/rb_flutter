import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for the grocery store app
class SupabaseConfig {
  // Your Supabase project credentials
  static const String supabaseUrl = 'https://nlizabhdxklazxgiflbb.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5saXphYmhkeGtsYXp4Z2lmbGJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyOTE4NDksImV4cCI6MjA2Njg2Nzg0OX0.8ncdfAJfl4z8AHgYeokzH3xn1-OipXsBu3uhXfS5dFc';

  /// Initialize Supabase client
  /// Call this in your main() function before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 10,
      ),
    );
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get the current user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  static String? get currentUserId => currentUser?.id;

  /// Sign out the current user
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}

/// Extension to make Supabase client easily accessible throughout the app
extension SupabaseExtension on SupabaseClient {
  /// Quick access to auth
  GoTrueClient get authClient => auth;

  /// Quick access to database
  PostgrestClient get database => rest;

  /// Quick access to storage
  SupabaseStorageClient get storageClient => storage;

  /// Quick access to realtime
  RealtimeClient get realtimeClient => realtime;
}

/// Common Supabase error messages
class SupabaseErrors {
  static const String networkError =
      'Network error. Please check your connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String permissionError =
      'You don\'t have permission to perform this action.';
  static const String notFoundError = 'The requested resource was not found.';
  static const String serverError = 'Server error. Please try again later.';

  /// Get user-friendly error message from Supabase error
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred.';

    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      return networkError;
    } else if (errorMessage.contains('auth') ||
        errorMessage.contains('unauthorized')) {
      return authError;
    } else if (errorMessage.contains('permission') ||
        errorMessage.contains('forbidden')) {
      return permissionError;
    } else if (errorMessage.contains('not found') ||
        errorMessage.contains('404')) {
      return notFoundError;
    } else if (errorMessage.contains('server') ||
        errorMessage.contains('500')) {
      return serverError;
    }

    return error.toString();
  }
}

/// Supabase table names for easy reference
class SupabaseTables {
  static const String userProfiles = 'user_profiles';
  static const String categories = 'categories';
  static const String products = 'products';
  static const String inventory = 'inventory';
  static const String suppliers = 'suppliers';
  static const String shoppingCart = 'shopping_cart';
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
  static const String customerAddresses = 'customer_addresses';
  static const String deliveryZones = 'delivery_zones';
  static const String deliveryTimeSlots = 'delivery_time_slots';
  static const String promotions = 'promotions';
  static const String productReviews = 'product_reviews';
  static const String wishlist = 'wishlist';
  static const String orderStatusHistory = 'order_status_history';
}

/// Supabase RPC function names for easy reference
class SupabaseFunctions {
  // Customer functions
  static const String getProductsWithDetails = 'get_products_with_details';
  static const String searchProducts = 'search_products';
  static const String addToCart = 'add_to_cart';
  static const String getCartItems = 'get_cart_items';
  static const String createOrderFromCart = 'create_order_from_cart';
  static const String getOrderDetails = 'get_order_details';
  static const String getDeliveryZonesForAddress =
      'get_delivery_zones_for_address';
  static const String getAvailableDeliverySlots =
      'get_available_delivery_slots';
  static const String getUserProfile = 'get_user_profile';

  // Admin functions
  static const String getSalesAnalytics = 'get_sales_analytics';
  static const String getCustomerAnalytics = 'get_customer_analytics';
  static const String getInventoryAlerts = 'get_inventory_alerts';
  static const String updateProductInventory = 'update_product_inventory';
  static const String getOrderManagementDashboard =
      'get_order_management_dashboard';
  static const String updateOrderStatus = 'update_order_status';
  static const String adminGetOrderDetails = 'admin_get_order_details';
  static const String adminUpsertProduct = 'admin_upsert_product';
  static const String adminBulkUpdatePrices = 'admin_bulk_update_prices';
  static const String adminGenerateSalesReport = 'admin_generate_sales_report';
  static const String getAllUsers = 'get_all_users';
  static const String updateUserRole = 'update_user_role';
  static const String deactivateUserAccount = 'deactivate_user_account';
}
