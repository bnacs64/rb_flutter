-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_cart ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role IN ('admin', 'store_manager')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is customer
CREATE OR REPLACE FUNCTION is_customer()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = auth.uid() AND role = 'customer'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- User Profiles Policies
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON user_profiles
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all profiles" ON user_profiles
    FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can insert profiles" ON user_profiles
    FOR INSERT WITH CHECK (is_admin());

-- Categories Policies (public read, admin write)
CREATE POLICY "Anyone can view active categories" ON categories
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can view all categories" ON categories
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins can manage categories" ON categories
    FOR ALL USING (is_admin());

-- Suppliers Policies (admin only)
CREATE POLICY "Admins can manage suppliers" ON suppliers
    FOR ALL USING (is_admin());

-- Products Policies (public read active, admin write)
CREATE POLICY "Anyone can view active products" ON products
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can view all products" ON products
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins can manage products" ON products
    FOR ALL USING (is_admin());

-- Inventory Policies (admin only)
CREATE POLICY "Admins can manage inventory" ON inventory
    FOR ALL USING (is_admin());

-- Customer Addresses Policies
CREATE POLICY "Users can view their own addresses" ON customer_addresses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own addresses" ON customer_addresses
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all addresses" ON customer_addresses
    FOR SELECT USING (is_admin());

-- Delivery Zones Policies (public read active, admin write)
CREATE POLICY "Anyone can view active delivery zones" ON delivery_zones
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage delivery zones" ON delivery_zones
    FOR ALL USING (is_admin());

-- Delivery Time Slots Policies (public read active, admin write)
CREATE POLICY "Anyone can view active time slots" ON delivery_time_slots
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage time slots" ON delivery_time_slots
    FOR ALL USING (is_admin());

-- Shopping Cart Policies
CREATE POLICY "Users can view their own cart" ON shopping_cart
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own cart" ON shopping_cart
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all carts" ON shopping_cart
    FOR SELECT USING (is_admin());

-- Promotions Policies (public read active, admin write)
CREATE POLICY "Anyone can view active promotions" ON promotions
    FOR SELECT USING (is_active = true AND start_date <= NOW() AND end_date >= NOW());

CREATE POLICY "Admins can manage promotions" ON promotions
    FOR ALL USING (is_admin());

-- Orders Policies
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pending orders" ON orders
    FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

CREATE POLICY "Admins can view all orders" ON orders
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins can manage all orders" ON orders
    FOR ALL USING (is_admin());

-- Order Items Policies
CREATE POLICY "Users can view items from their own orders" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert items to their own orders" ON order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
            AND orders.status = 'pending'
        )
    );

CREATE POLICY "Admins can manage all order items" ON order_items
    FOR ALL USING (is_admin());

-- Order Status History Policies
CREATE POLICY "Users can view status history of their orders" ON order_status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_status_history.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage order status history" ON order_status_history
    FOR ALL USING (is_admin());

-- Product Reviews Policies
CREATE POLICY "Anyone can view approved reviews" ON product_reviews
    FOR SELECT USING (is_approved = true);

CREATE POLICY "Users can view their own reviews" ON product_reviews
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create reviews for their purchases" ON product_reviews
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE oi.product_id = product_reviews.product_id
            AND o.user_id = auth.uid()
            AND o.status = 'delivered'
        )
    );

CREATE POLICY "Users can update their own reviews" ON product_reviews
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all reviews" ON product_reviews
    FOR ALL USING (is_admin());

-- Wishlist Policies
CREATE POLICY "Users can view their own wishlist" ON wishlist
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own wishlist" ON wishlist
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all wishlists" ON wishlist
    FOR SELECT USING (is_admin());
