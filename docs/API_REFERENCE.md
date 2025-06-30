# Grocery Store API Reference

This document provides comprehensive API reference for the Supabase backend functions.

## Authentication

All API calls require authentication unless specified otherwise. Use Supabase Auth to authenticate users.

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'YOUR_SUPABASE_URL',
  'YOUR_SUPABASE_ANON_KEY'
)

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password'
})
```

## Customer API

### Products

#### Get Products with Details
Retrieve products with inventory, category, and rating information.

```typescript
const { data, error } = await supabase.rpc('get_products_with_details', {
  category_filter: 'cat_fresh_produce', // optional
  search_term: 'apple',                 // optional
  limit_count: 20,                      // default: 20
  offset_count: 0                       // default: 0
})
```

**Response:**
```typescript
interface ProductWithDetails {
  id: string
  name: string
  description: string
  category_id: string
  category_name: string
  brand: string
  price: number
  unit: string
  weight_volume: string
  is_organic: boolean
  images: string[]
  tags: string[]
  available_quantity: number
  average_rating: number
  review_count: number
  is_in_stock: boolean
}
```

#### Search Products
Advanced product search with filters.

```typescript
const { data, error } = await supabase.rpc('search_products', {
  search_query: 'organic',                    // optional
  category_ids: ['cat_fresh_produce'],        // optional
  min_price: 1.00,                           // optional
  max_price: 10.00,                          // optional
  is_organic_filter: true,                   // optional
  in_stock_only: true,                       // default: true
  sort_by: 'price_asc',                      // 'name', 'price_asc', 'price_desc', 'rating'
  limit_count: 20,                           // default: 20
  offset_count: 0                            // default: 0
})
```

### Shopping Cart

#### Add to Cart
Add or update item in shopping cart.

```typescript
const { data, error } = await supabase.rpc('add_to_cart', {
  user_id_param: userId,
  product_id_param: 'prod_banana',
  quantity_param: 2
})
```

**Response:**
```typescript
interface AddToCartResponse {
  success: boolean
  cart_item_id?: string
  error?: string
  message?: string
}
```

#### Get Cart Items
Retrieve user's cart items with product details.

```typescript
const { data, error } = await supabase.rpc('get_cart_items', {
  user_id_param: userId
})
```

**Response:**
```typescript
interface CartItem {
  cart_id: string
  product_id: string
  product_name: string
  product_image: string
  brand: string
  unit_price: number
  quantity: number
  total_price: number
  available_quantity: number
  is_available: boolean
}
```

#### Update Cart Item
```typescript
const { error } = await supabase
  .from('shopping_cart')
  .update({ quantity: newQuantity })
  .eq('id', cartItemId)
```

#### Remove from Cart
```typescript
const { error } = await supabase
  .from('shopping_cart')
  .delete()
  .eq('id', cartItemId)
```

### Orders

#### Create Order from Cart
Convert shopping cart to order.

```typescript
const { data, error } = await supabase.rpc('create_order_from_cart', {
  user_id_param: userId,
  delivery_address_id_param: addressId,
  delivery_zone_id_param: 'zone_downtown',
  delivery_slot_id_param: 'slot_morning_dt',
  scheduled_delivery_date_param: '2024-01-15',
  payment_method_param: 'credit_card',
  special_instructions_param: 'Leave at door',
  promotion_id_param: 'promo_welcome10'  // optional
})
```

**Response:**
```typescript
interface CreateOrderResponse {
  success: boolean
  order_id?: string
  error?: string
  message?: string
}
```

#### Get Order Details
Retrieve comprehensive order information.

```typescript
const { data, error } = await supabase.rpc('get_order_details', {
  order_id_param: orderId
})
```

#### Get User Orders
```typescript
const { data, error } = await supabase
  .from('orders')
  .select(`
    *,
    order_items (
      *,
      products (name, images)
    )
  `)
  .eq('user_id', userId)
  .order('created_at', { ascending: false })
```

### Delivery

#### Get Delivery Zones
Find delivery zones for a specific address.

```typescript
const { data, error } = await supabase.rpc('get_delivery_zones_for_address', {
  latitude_param: 49.2827,
  longitude_param: -123.1207
})
```

#### Get Available Delivery Slots
Get available time slots for delivery.

```typescript
const { data, error } = await supabase.rpc('get_available_delivery_slots', {
  zone_id_param: 'zone_downtown',
  delivery_date: '2024-01-15'
})
```

### User Profile

#### Get User Profile
```typescript
const { data, error } = await supabase.rpc('get_user_profile')
```

#### Update User Profile
```typescript
const { error } = await supabase
  .from('user_profiles')
  .update({
    full_name: 'John Doe',
    phone: '+1234567890',
    preferences: { notifications: true }
  })
  .eq('id', userId)
```

### Addresses

#### Get User Addresses
```typescript
const { data, error } = await supabase
  .from('customer_addresses')
  .select('*')
  .eq('user_id', userId)
  .order('is_default', { ascending: false })
```

#### Add Address
```typescript
const { data, error } = await supabase
  .from('customer_addresses')
  .insert({
    user_id: userId,
    label: 'Home',
    full_name: 'John Doe',
    phone: '+1234567890',
    address_line_1: '123 Main St',
    city: 'Vancouver',
    postal_code: 'V6B 1A1',
    is_default: true
  })
```

### Reviews

#### Add Product Review
```typescript
const { data, error } = await supabase
  .from('product_reviews')
  .insert({
    product_id: 'prod_banana',
    user_id: userId,
    order_id: orderId,
    rating: 5,
    title: 'Great product!',
    comment: 'Fresh and delicious bananas.'
  })
```

#### Get Product Reviews
```typescript
const { data, error } = await supabase
  .from('product_reviews')
  .select(`
    *,
    user_profiles (full_name)
  `)
  .eq('product_id', productId)
  .eq('is_approved', true)
  .order('created_at', { ascending: false })
```

### Wishlist

#### Add to Wishlist
```typescript
const { data, error } = await supabase
  .from('wishlist')
  .insert({
    user_id: userId,
    product_id: productId
  })
```

#### Get Wishlist
```typescript
const { data, error } = await supabase
  .from('wishlist')
  .select(`
    *,
    products (
      id, name, price, images, brand,
      inventory (quantity_available, reserved_quantity)
    )
  `)
  .eq('user_id', userId)
```

## Admin API

### Analytics

#### Get Sales Analytics
```typescript
const { data, error } = await supabase.rpc('get_sales_analytics', {
  start_date: '2024-01-01',
  end_date: '2024-01-31'
})
```

#### Get Customer Analytics
```typescript
const { data, error } = await supabase.rpc('get_customer_analytics', {
  start_date: '2024-01-01',
  end_date: '2024-01-31'
})
```

#### Generate Sales Report
```typescript
const { data, error } = await supabase.rpc('admin_generate_sales_report', {
  start_date: '2024-01-01',
  end_date: '2024-01-31',
  group_by: 'day' // 'day', 'week', 'month'
})
```

### Inventory Management

#### Get Inventory Alerts
```typescript
const { data, error } = await supabase.rpc('get_inventory_alerts')
```

#### Update Product Inventory
```typescript
const { data, error } = await supabase.rpc('update_product_inventory', {
  product_id_param: 'prod_banana',
  quantity_change: 50,
  cost_price_param: 1.50,
  supplier_id_param: 'sup_fresh_farm',
  batch_number_param: 'BATCH001',
  expiry_date_param: '2024-02-01',
  operation_type: 'restock'
})
```

### Order Management

#### Get Order Management Dashboard
```typescript
const { data, error } = await supabase.rpc('get_order_management_dashboard')
```

#### Update Order Status
```typescript
const { data, error } = await supabase.rpc('update_order_status', {
  order_id_param: orderId,
  new_status: 'confirmed',
  notes_param: 'Order confirmed by admin',
  updated_by_param: adminUserId
})
```

#### Get Admin Order Details
```typescript
const { data, error } = await supabase.rpc('admin_get_order_details', {
  order_id_param: orderId
})
```

### Product Management

#### Create/Update Product
```typescript
const { data, error } = await supabase.rpc('admin_upsert_product', {
  product_data: {
    id: 'prod_new_item',
    name: 'New Product',
    description: 'Product description',
    category_id: 'cat_fresh_produce',
    brand: 'Brand Name',
    price: 5.99,
    unit: 'per_kg',
    is_organic: true,
    inventory: {
      quantity_available: 100,
      reorder_level: 20,
      cost_price: 3.50,
      supplier_id: 'sup_fresh_farm'
    }
  }
})
```

#### Bulk Update Prices
```typescript
const { data, error } = await supabase.rpc('admin_bulk_update_prices', {
  price_updates: [
    { product_id: 'prod_banana', new_price: 3.49 },
    { product_id: 'prod_apple_red', new_price: 5.49 }
  ]
})
```

### User Management

#### Get All Users
```typescript
const { data, error } = await supabase.rpc('get_all_users', {
  role_filter: 'customer',     // optional
  is_active_filter: true,      // optional
  limit_count: 50,             // default: 50
  offset_count: 0              // default: 0
})
```

#### Update User Role
```typescript
const { data, error } = await supabase.rpc('update_user_role', {
  target_user_id: userId,
  new_role: 'store_manager'
})
```

#### Deactivate User Account
```typescript
const { data, error } = await supabase.rpc('deactivate_user_account', {
  target_user_id: userId,
  reason: 'Policy violation'
})
```

## Error Handling

All functions return a consistent error format:

```typescript
interface ApiResponse<T> {
  data: T | null
  error: {
    message: string
    details?: string
    hint?: string
    code?: string
  } | null
}
```

## Rate Limiting

Supabase provides built-in rate limiting. For production applications, consider implementing additional rate limiting based on your needs.

## Real-time Subscriptions

Subscribe to real-time changes:

```typescript
// Subscribe to order status changes
const subscription = supabase
  .channel('order-changes')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'orders',
    filter: `user_id=eq.${userId}`
  }, (payload) => {
    console.log('Order updated:', payload)
  })
  .subscribe()

// Subscribe to inventory changes
const inventorySubscription = supabase
  .channel('inventory-changes')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'inventory'
  }, (payload) => {
    console.log('Inventory updated:', payload)
  })
  .subscribe()
```
