import 'package:supabase_flutter/supabase_flutter.dart';

/// Quick test script to verify Supabase connection
/// Run this with: dart run test_supabase_connection.dart
void main() async {
  print('🚀 Testing Supabase connection...');
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://nlizabhdxklazxgiflbb.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5saXphYmhkeGtsYXp4Z2lmbGJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyOTE4NDksImV4cCI6MjA2Njg2Nzg0OX0.8ncdfAJfl4z8AHgYeokzH3xn1-OipXsBu3uhXfS5dFc',
    );
    
    final supabase = Supabase.instance.client;
    print('✅ Supabase client initialized successfully');
    
    // Test 1: Fetch categories
    print('\n📂 Testing categories fetch...');
    final categoriesResponse = await supabase
        .from('categories')
        .select('id, name, description')
        .limit(5);
    
    print('✅ Categories fetched: ${categoriesResponse.length} items');
    for (final category in categoriesResponse) {
      print('   - ${category['name']}: ${category['description']}');
    }
    
    // Test 2: Fetch products with details using RPC
    print('\n🛒 Testing products fetch with RPC...');
    final productsResponse = await supabase.rpc('get_products_with_details', params: {
      'limit_count': 3,
      'offset_count': 0,
    });
    
    print('✅ Products fetched: ${productsResponse.length} items');
    for (final product in productsResponse) {
      print('   - ${product['name']}: \$${product['price']} (Stock: ${product['available_quantity']})');
    }
    
    // Test 3: Fetch delivery zones
    print('\n🚚 Testing delivery zones...');
    final zonesResponse = await supabase
        .from('delivery_zones')
        .select('id, name, delivery_fee, minimum_order')
        .eq('is_active', true);
    
    print('✅ Delivery zones fetched: ${zonesResponse.length} zones');
    for (final zone in zonesResponse) {
      print('   - ${zone['name']}: \$${zone['delivery_fee']} (Min order: \$${zone['minimum_order']})');
    }
    
    // Test 4: Test search function
    print('\n🔍 Testing product search...');
    final searchResponse = await supabase.rpc('search_products', params: {
      'search_query': 'apple',
      'limit_count': 2,
      'offset_count': 0,
    });
    
    print('✅ Search results: ${searchResponse.length} items');
    for (final product in searchResponse) {
      print('   - ${product['name']}: \$${product['price']} (${product['brand']})');
    }
    
    // Test 5: Test promotions
    print('\n🎉 Testing promotions...');
    final promotionsResponse = await supabase
        .from('promotions')
        .select('id, name, description, discount_type, discount_value')
        .eq('is_active', true);
    
    print('✅ Active promotions: ${promotionsResponse.length} promotions');
    for (final promo in promotionsResponse) {
      print('   - ${promo['name']}: ${promo['discount_value']}${promo['discount_type'] == 'percentage' ? '%' : '\$'} off');
    }
    
    print('\n🎊 All tests passed! Your Supabase backend is working perfectly!');
    print('\n📋 Summary:');
    print('   • Database connection: ✅ Working');
    print('   • Categories: ✅ ${categoriesResponse.length} items');
    print('   • Products: ✅ ${productsResponse.length} items');
    print('   • Delivery zones: ✅ ${zonesResponse.length} zones');
    print('   • Search function: ✅ Working');
    print('   • Promotions: ✅ ${promotionsResponse.length} active');
    print('\n🚀 Ready to integrate with your Flutter app!');
    
  } catch (error) {
    print('❌ Error testing Supabase connection: $error');
    print('\n🔧 Troubleshooting:');
    print('   1. Check your internet connection');
    print('   2. Verify the Supabase URL and API key');
    print('   3. Ensure the database migrations were applied');
    print('   4. Check the Supabase dashboard for any issues');
  }
}
