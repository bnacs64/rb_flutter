# 🛒 Grocery Store Setup Guide

Your Supabase backend is now fully deployed and ready to use! Here's everything you need to know.

## 🎯 Your Project Details

**Supabase Project URL:** `https://nlizabhdxklazxgiflbb.supabase.co`
**Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5saXphYmhkeGtsYXp4Z2lmbGJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyOTE4NDksImV4cCI6MjA2Njg2Nzg0OX0.8ncdfAJfl4z8AHgYeokzH3xn1-OipXsBu3uhXfS5dFc`

## ✅ What's Already Done

- ✅ **Database Schema**: All tables created (products, categories, orders, users, etc.)
- ✅ **Sample Data**: 10 categories, 6 products, suppliers, delivery zones loaded
- ✅ **Security**: Row Level Security policies applied
- ✅ **API Functions**: 20+ functions for customer and admin operations
- ✅ **Authentication**: Role-based access control configured
- ✅ **Flutter Config**: Supabase configuration files created

## 🚀 Quick Start

### 1. Test Your Backend

Run the connection test:
```bash
dart run test_supabase_connection.dart
```

### 2. Add Supabase to Flutter

The configuration is already added! Just install the dependency:

```yaml
# Add to pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
```

Then run:
```bash
flutter pub get
```

### 3. Create Your First Admin User

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard/project/nlizabhdxklazxgiflbb)
2. Navigate to Authentication > Users
3. Click "Add User"
4. Use email: `admin@grocerystore.com` (this will automatically get admin role)
5. Set a password

### 4. Test the API

Open your Supabase dashboard and try these SQL queries:

```sql
-- Get all products with details
SELECT * FROM get_products_with_details();

-- Get categories
SELECT * FROM categories WHERE is_active = true;

-- Get inventory alerts
SELECT * FROM get_inventory_alerts();

-- Get sales analytics
SELECT get_sales_analytics();
```

## 📱 Flutter Integration

### Basic Usage Example

```dart
import 'package:shop/core/supabase_config.dart';

// Get products
final products = await SupabaseConfig.client
    .rpc('get_products_with_details', params: {
  'limit_count': 20,
  'offset_count': 0,
});

// Add to cart (requires authentication)
final result = await SupabaseConfig.client
    .rpc('add_to_cart', params: {
  'user_id_param': SupabaseConfig.currentUserId,
  'product_id_param': 'prod_banana',
  'quantity_param': 2,
});
```

### Authentication Example

```dart
// Sign up
final authResponse = await SupabaseConfig.client.auth.signUp(
  email: 'customer@example.com',
  password: 'password123',
);

// Sign in
final signInResponse = await SupabaseConfig.client.auth.signInWithPassword(
  email: 'customer@example.com',
  password: 'password123',
);

// Get user profile
final profile = await SupabaseConfig.client.rpc('get_user_profile');
```

## 🛠️ Available Features

### Customer Features
- ✅ Product browsing with search and filters
- ✅ Shopping cart management
- ✅ Order placement and tracking
- ✅ User profiles and addresses
- ✅ Product reviews and ratings
- ✅ Wishlist functionality
- ✅ Delivery zone and time slot selection
- ✅ Promotion and discount system

### Admin Features
- ✅ Product management (CRUD operations)
- ✅ Inventory tracking with alerts
- ✅ Order management and status updates
- ✅ Sales analytics and reporting
- ✅ Customer management
- ✅ User role management
- ✅ Supplier management
- ✅ Promotion management

## 📊 Sample Data Included

### Categories (10 main + 6 subcategories)
- Fresh Produce (Fruits, Vegetables, Herbs)
- Dairy & Eggs (Milk, Cheese, Yogurt)
- Meat & Seafood
- Pantry Staples
- Beverages
- Snacks & Confectionery
- Frozen Foods
- Bakery
- Health & Beauty
- Household Items

### Products (6 sample items)
- Bananas (Fresh Farm, $2.99/kg)
- Red Apples (Orchard Fresh, $4.99/kg, Organic)
- Whole Milk (Dairy Best, $3.49/L)
- Whole Wheat Bread (Bakery Fresh, $2.79/loaf)
- Chicken Breast (Farm Fresh, $12.99/kg)
- Basmati Rice (Golden Grain, $8.99/5kg bag)

### Delivery Zones (3 zones)
- Downtown Core ($4.99 delivery, $25 minimum)
- Suburban Areas ($6.99 delivery, $35 minimum)
- Extended Areas ($9.99 delivery, $50 minimum)

### Promotions (3 active)
- Welcome 10% Off (first order)
- Fresh Produce $5 Off
- Dairy Special 15% Off

## 🔧 Development Commands

```bash
# Start local Supabase (optional)
npx supabase start

# Deploy changes
npx supabase db push

# Generate TypeScript types
npx supabase gen types typescript > types/supabase.ts

# Reset database (re-applies all migrations and seed data)
npx supabase db reset --linked
```

## 🔐 Security Notes

- **Row Level Security**: All tables have RLS enabled
- **Role-based Access**: Users are automatically assigned roles
- **Admin Detection**: Emails ending with specific domains get admin access
- **API Security**: All functions check user permissions

## 📚 Documentation

- **API Reference**: See `docs/API_REFERENCE.md`
- **Flutter Integration**: See `docs/FLUTTER_INTEGRATION.md`
- **Backend Details**: See `README_SUPABASE.md`

## 🆘 Troubleshooting

### Common Issues

1. **Connection Error**: Check your internet and Supabase status
2. **Permission Denied**: Ensure user is authenticated and has correct role
3. **Function Not Found**: Verify all migrations were applied
4. **Data Not Loading**: Check if seed data was applied correctly

### Getting Help

1. Check the [Supabase Dashboard](https://supabase.com/dashboard/project/nlizabhdxklazxgiflbb) logs
2. Run the test script: `dart run test_supabase_connection.dart`
3. Review the API documentation in `docs/`
4. Check the Flutter integration examples

## 🎉 Next Steps

1. **Customize Products**: Add your own grocery items
2. **Update Branding**: Change app name and colors
3. **Add Payment**: Integrate Stripe or other payment providers
4. **Deploy App**: Build and deploy your Flutter app
5. **Monitor Usage**: Use Supabase analytics to track usage

Your grocery store backend is ready to power a full-featured e-commerce app! 🚀
