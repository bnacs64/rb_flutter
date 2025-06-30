# Grocery Store Supabase Backend

This is a comprehensive Supabase backend for a grocery store application with admin interface capabilities.

## Features

- **Complete Database Schema**: Products, categories, inventory, orders, users, delivery management
- **Row Level Security (RLS)**: Comprehensive security policies for data protection
- **Admin Interface**: Full admin functions for store management
- **Authentication**: Role-based access control (customer, admin, store_manager, delivery_driver)
- **Inventory Management**: Real-time stock tracking with alerts
- **Order Processing**: Complete order lifecycle management
- **Delivery Management**: Zone-based delivery with time slots
- **Analytics**: Sales, customer, and inventory analytics
- **Promotions**: Discount and promotion system

## Quick Start

### 1. Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- [Docker](https://www.docker.com/) installed (for local development)

### 2. Your Supabase Project Details

**Project URL:** `https://nlizabhdxklazxgiflbb.supabase.co`
**Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5saXphYmhkeGtsYXp4Z2lmbGJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyOTE4NDksImV4cCI6MjA2Njg2Nzg0OX0.8ncdfAJfl4z8AHgYeokzH3xn1-OipXsBu3uhXfS5dFc`

### 3. Project Setup

```bash
# Your project is already linked and deployed!
# The database schema and seed data are already applied.

# To work with local development:
supabase start

# To make changes and deploy:
supabase db push
```

### 3. Apply Migrations

```bash
# Apply all migrations
supabase db reset

# Or apply migrations individually
supabase migration up
```

### 4. Seed Database

```bash
# Apply seed data
supabase db seed
```

### 5. Deploy to Production

```bash
# Link to your Supabase project
supabase link --project-ref your-project-ref

# Push migrations to production
supabase db push

# Apply seed data to production (optional)
supabase db seed --remote
```

## Database Schema Overview

### Core Tables

1. **user_profiles** - Extended user information with roles
2. **categories** - Hierarchical product categories
3. **products** - Product catalog with detailed information
4. **inventory** - Stock management with expiry tracking
5. **suppliers** - Supplier information
6. **orders** - Order management with status tracking
7. **order_items** - Individual items in orders
8. **shopping_cart** - User shopping carts
9. **customer_addresses** - Delivery addresses
10. **delivery_zones** - Geographic delivery areas
11. **delivery_time_slots** - Available delivery windows
12. **promotions** - Discount and promotion system
13. **product_reviews** - Customer reviews and ratings
14. **wishlist** - User wishlists

### User Roles

- **customer**: Regular shoppers
- **admin**: Full system access
- **store_manager**: Store operations management
- **delivery_driver**: Delivery management access

## API Functions

### Customer Functions

#### Products
```sql
-- Get products with details
SELECT * FROM get_products_with_details(
    category_filter := 'cat_fresh_produce',
    search_term := 'apple',
    limit_count := 20,
    offset_count := 0
);

-- Search products with filters
SELECT * FROM search_products(
    search_query := 'organic',
    category_ids := ARRAY['cat_fresh_produce'],
    min_price := 1.00,
    max_price := 10.00,
    is_organic_filter := true,
    in_stock_only := true,
    sort_by := 'price_asc',
    limit_count := 20,
    offset_count := 0
);
```

#### Shopping Cart
```sql
-- Add item to cart
SELECT add_to_cart(
    user_id_param := auth.uid(),
    product_id_param := 'prod_banana',
    quantity_param := 2
);

-- Get cart items
SELECT * FROM get_cart_items(auth.uid());
```

#### Orders
```sql
-- Create order from cart
SELECT create_order_from_cart(
    user_id_param := auth.uid(),
    delivery_address_id_param := 'address-uuid',
    delivery_zone_id_param := 'zone_downtown',
    delivery_slot_id_param := 'slot_morning_dt',
    scheduled_delivery_date_param := '2024-01-15',
    payment_method_param := 'credit_card',
    special_instructions_param := 'Leave at door',
    promotion_id_param := 'promo_welcome10'
);

-- Get order details
SELECT get_order_details('order-uuid');
```

#### Delivery
```sql
-- Get delivery zones for address
SELECT * FROM get_delivery_zones_for_address(49.2827, -123.1207);

-- Get available delivery slots
SELECT * FROM get_available_delivery_slots('zone_downtown', '2024-01-15');
```

### Admin Functions

#### Analytics
```sql
-- Get sales analytics
SELECT get_sales_analytics('2024-01-01', '2024-01-31');

-- Get customer analytics
SELECT get_customer_analytics('2024-01-01', '2024-01-31');

-- Generate sales report
SELECT admin_generate_sales_report('2024-01-01', '2024-01-31', 'day');
```

#### Inventory Management
```sql
-- Get inventory alerts
SELECT * FROM get_inventory_alerts();

-- Update product inventory
SELECT update_product_inventory(
    product_id_param := 'prod_banana',
    quantity_change := 50,
    cost_price_param := 1.50,
    supplier_id_param := 'sup_fresh_farm',
    batch_number_param := 'BATCH001',
    expiry_date_param := '2024-02-01',
    operation_type := 'restock'
);
```

#### Order Management
```sql
-- Get order management dashboard
SELECT get_order_management_dashboard();

-- Update order status
SELECT update_order_status(
    order_id_param := 'order-uuid',
    new_status := 'confirmed',
    notes_param := 'Order confirmed by admin',
    updated_by_param := auth.uid()
);

-- Get comprehensive order details
SELECT admin_get_order_details('order-uuid');
```

#### Product Management
```sql
-- Create/update product
SELECT admin_upsert_product('{
    "id": "prod_new_item",
    "name": "New Product",
    "description": "Product description",
    "category_id": "cat_fresh_produce",
    "brand": "Brand Name",
    "price": 5.99,
    "unit": "per_kg",
    "is_organic": true,
    "inventory": {
        "quantity_available": 100,
        "reorder_level": 20,
        "cost_price": 3.50,
        "supplier_id": "sup_fresh_farm"
    }
}'::JSON);

-- Bulk update prices
SELECT admin_bulk_update_prices('[
    {"product_id": "prod_banana", "new_price": 3.49},
    {"product_id": "prod_apple_red", "new_price": 5.49}
]'::JSON);
```

#### User Management
```sql
-- Get all users
SELECT * FROM get_all_users(
    role_filter := 'customer',
    is_active_filter := true,
    limit_count := 50,
    offset_count := 0
);

-- Update user role
SELECT update_user_role('user-uuid', 'store_manager');

-- Deactivate user account
SELECT deactivate_user_account('user-uuid', 'Policy violation');
```

## Security

### Row Level Security (RLS)

All tables have RLS enabled with appropriate policies:

- **Customers** can only access their own data
- **Admins** have full access to all data
- **Store Managers** have access to operational data
- **Public data** (products, categories) is readable by all authenticated users

### Authentication

- Email/password authentication
- Role-based access control
- Automatic profile creation on signup
- Admin email detection for role assignment

## Environment Variables

Set these in your Supabase project settings:

```bash
# Optional: OpenAI API key for AI features
OPENAI_API_KEY=your_openai_api_key

# Optional: External service integrations
TWILIO_AUTH_TOKEN=your_twilio_token
GOOGLE_CLIENT_SECRET=your_google_secret
```

## Local Development

```bash
# Start Supabase locally
supabase start

# View local dashboard
# Studio: http://localhost:54323
# API: http://localhost:54321

# Reset database (applies all migrations and seed data)
supabase db reset

# Generate TypeScript types
supabase gen types typescript --local > types/supabase.ts
```

## Production Deployment

```bash
# Link to production project
supabase link --project-ref your-production-ref

# Push schema changes
supabase db push

# Deploy edge functions (if any)
supabase functions deploy

# Generate production types
supabase gen types typescript > types/supabase.ts
```

## Monitoring and Maintenance

### Regular Tasks

1. **Monitor inventory alerts**: Check `get_inventory_alerts()` daily
2. **Review order status**: Use order management dashboard
3. **Analyze sales**: Generate weekly/monthly reports
4. **User management**: Monitor user activity and roles

### Database Maintenance

```sql
-- Clean up expired promotions
UPDATE promotions SET is_active = false WHERE end_date < NOW();

-- Archive old orders (example: older than 1 year)
-- Implement archiving strategy based on business needs

-- Update inventory for expired products
UPDATE inventory SET quantity_available = 0 WHERE expiry_date < CURRENT_DATE;
```

## Support

For issues and questions:

1. Check the function documentation in the migration files
2. Review RLS policies for permission issues
3. Use Supabase dashboard for real-time monitoring
4. Check logs in Supabase dashboard for errors

## License

This backend implementation is provided as-is for educational and commercial use.
