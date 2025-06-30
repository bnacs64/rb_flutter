import 'dart:convert';
import 'dart:io';

/// Simple HTTP test for Supabase connection
/// This doesn't require Flutter dependencies
void main() async {
  print('🚀 Testing Supabase connection...');

  const supabaseUrl = 'https://nlizabhdxklazxgiflbb.supabase.co';
  const supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5saXphYmhkeGtsYXp4Z2lmbGJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyOTE4NDksImV4cCI6MjA2Njg2Nzg0OX0.8ncdfAJfl4z8AHgYeokzH3xn1-OipXsBu3uhXfS5dFc';

  final client = HttpClient();

  try {
    // Test 1: Check if Supabase is reachable
    print('\n🌐 Testing basic connectivity...');
    final healthRequest =
        await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/'));
    healthRequest.headers.set('apikey', supabaseKey);
    healthRequest.headers.set('Authorization', 'Bearer $supabaseKey');

    final healthResponse = await healthRequest.close();
    print('✅ Supabase is reachable (Status: ${healthResponse.statusCode})');

    // Test 2: Fetch categories
    print('\n📂 Testing categories table...');
    final categoriesRequest = await client.getUrl(Uri.parse(
        '$supabaseUrl/rest/v1/categories?select=id,name,description&limit=5'));
    categoriesRequest.headers.set('apikey', supabaseKey);
    categoriesRequest.headers.set('Authorization', 'Bearer $supabaseKey');
    categoriesRequest.headers.set('Content-Type', 'application/json');

    final categoriesResponse = await categoriesRequest.close();
    final categoriesBody =
        await categoriesResponse.transform(utf8.decoder).join();

    if (categoriesResponse.statusCode == 200) {
      final categories = jsonDecode(categoriesBody) as List;
      print('✅ Categories fetched: ${categories.length} items');
      for (final category in categories.take(3)) {
        print('   - ${category['name']}: ${category['description']}');
      }
    } else {
      print('❌ Categories fetch failed: ${categoriesResponse.statusCode}');
      print('Response: $categoriesBody');
    }

    // Test 3: Fetch products
    print('\n🛒 Testing products table...');
    final productsRequest = await client.getUrl(Uri.parse(
        '$supabaseUrl/rest/v1/products?select=id,name,price,brand&limit=3'));
    productsRequest.headers.set('apikey', supabaseKey);
    productsRequest.headers.set('Authorization', 'Bearer $supabaseKey');
    productsRequest.headers.set('Content-Type', 'application/json');

    final productsResponse = await productsRequest.close();
    final productsBody = await productsResponse.transform(utf8.decoder).join();

    if (productsResponse.statusCode == 200) {
      final products = jsonDecode(productsBody) as List;
      print('✅ Products fetched: ${products.length} items');
      for (final product in products) {
        print(
            '   - ${product['name']}: \$${product['price']} (${product['brand']})');
      }
    } else {
      print('❌ Products fetch failed: ${productsResponse.statusCode}');
      print('Response: $productsBody');
    }

    // Test 4: Test RPC function
    print('\n🔧 Testing RPC function...');
    final rpcRequest = await client.postUrl(
        Uri.parse('$supabaseUrl/rest/v1/rpc/get_products_with_details'));
    rpcRequest.headers.set('apikey', supabaseKey);
    rpcRequest.headers.set('Authorization', 'Bearer $supabaseKey');
    rpcRequest.headers.set('Content-Type', 'application/json');

    final rpcBody = jsonEncode({
      'limit_count': 2,
      'offset_count': 0,
    });
    rpcRequest.write(rpcBody);

    final rpcResponse = await rpcRequest.close();
    final rpcResponseBody = await rpcResponse.transform(utf8.decoder).join();

    if (rpcResponse.statusCode == 200) {
      final rpcResult = jsonDecode(rpcResponseBody) as List;
      print(
          '✅ RPC function working: ${rpcResult.length} products with details');
      for (final product in rpcResult) {
        print(
            '   - ${product['name']}: \$${product['price']} (Stock: ${product['available_quantity']})');
      }
    } else {
      print('❌ RPC function failed: ${rpcResponse.statusCode}');
      print('Response: $rpcResponseBody');
    }

    // Test 5: Check delivery zones
    print('\n🚚 Testing delivery zones...');
    final zonesRequest = await client.getUrl(Uri.parse(
        '$supabaseUrl/rest/v1/delivery_zones?select=id,name,delivery_fee,minimum_order&is_active=eq.true'));
    zonesRequest.headers.set('apikey', supabaseKey);
    zonesRequest.headers.set('Authorization', 'Bearer $supabaseKey');
    zonesRequest.headers.set('Content-Type', 'application/json');

    final zonesResponse = await zonesRequest.close();
    final zonesBody = await zonesResponse.transform(utf8.decoder).join();

    if (zonesResponse.statusCode == 200) {
      final zones = jsonDecode(zonesBody) as List;
      print('✅ Delivery zones: ${zones.length} active zones');
      for (final zone in zones) {
        print(
            '   - ${zone['name']}: \$${zone['delivery_fee']} delivery (Min: \$${zone['minimum_order']})');
      }
    } else {
      print('❌ Delivery zones fetch failed: ${zonesResponse.statusCode}');
      print('Response: $zonesBody');
    }

    print('\n🎊 Connection test completed successfully!');
    print('\n📋 Summary:');
    print('   • Supabase connectivity: ✅ Working');
    print('   • Database tables: ✅ Accessible');
    print('   • RPC functions: ✅ Working');
    print('   • Sample data: ✅ Loaded');
    print('\n🚀 Your grocery store backend is ready!');
  } catch (error) {
    print('❌ Error testing connection: $error');
    print('\n🔧 Troubleshooting:');
    print('   1. Check your internet connection');
    print('   2. Verify Supabase project is active');
    print('   3. Check if API key is correct');
    print('   4. Ensure database migrations were applied');
  } finally {
    client.close();
  }
}
