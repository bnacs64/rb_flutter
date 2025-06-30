-- Seed data for grocery store
-- This file will be executed after migrations

-- Insert sample categories
INSERT INTO categories (id, name, description, image_url, parent_id, sort_order, is_active) VALUES
  ('cat_fresh_produce', 'Fresh Produce', 'Fresh fruits and vegetables', 'https://images.unsplash.com/photo-1542838132-92c53300491e', NULL, 1, true),
  ('cat_dairy', 'Dairy & Eggs', 'Milk, cheese, yogurt, and eggs', 'https://images.unsplash.com/photo-1563636619-e9143da7973b', NULL, 2, true),
  ('cat_meat_seafood', 'Meat & Seafood', 'Fresh meat, poultry, and seafood', 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba', NULL, 3, true),
  ('cat_pantry', 'Pantry Staples', 'Rice, pasta, canned goods, spices', 'https://images.unsplash.com/photo-1586201375761-83865001e31c', NULL, 4, true),
  ('cat_beverages', 'Beverages', 'Juices, soft drinks, water, coffee, tea', 'https://images.unsplash.com/photo-1544145945-f90425340c7e', NULL, 5, true),
  ('cat_snacks', 'Snacks & Confectionery', 'Chips, cookies, candy, nuts', 'https://images.unsplash.com/photo-1621939514649-280e2ee25f60', NULL, 6, true),
  ('cat_frozen', 'Frozen Foods', 'Frozen vegetables, meals, ice cream', 'https://images.unsplash.com/photo-1578662996442-48f60103fc96', NULL, 7, true),
  ('cat_bakery', 'Bakery', 'Fresh bread, pastries, cakes', 'https://images.unsplash.com/photo-1509440159596-0249088772ff', NULL, 8, true),
  ('cat_health_beauty', 'Health & Beauty', 'Personal care, vitamins, supplements', 'https://images.unsplash.com/photo-1556228720-195a672e8a03', NULL, 9, true),
  ('cat_household', 'Household Items', 'Cleaning supplies, paper products', 'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b', NULL, 10, true);

-- Insert subcategories
INSERT INTO categories (id, name, description, image_url, parent_id, sort_order, is_active) VALUES
  ('cat_fruits', 'Fruits', 'Fresh seasonal fruits', 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b', 'cat_fresh_produce', 1, true),
  ('cat_vegetables', 'Vegetables', 'Fresh vegetables', 'https://images.unsplash.com/photo-1540420773420-3366772f4999', 'cat_fresh_produce', 2, true),
  ('cat_herbs', 'Herbs & Spices', 'Fresh herbs and cooking spices', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4', 'cat_fresh_produce', 3, true),
  ('cat_milk', 'Milk & Cream', 'Various types of milk and cream', 'https://images.unsplash.com/photo-1550583724-b2692b85b150', 'cat_dairy', 1, true),
  ('cat_cheese', 'Cheese', 'Variety of cheeses', 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d', 'cat_dairy', 2, true),
  ('cat_yogurt', 'Yogurt', 'Greek, regular, and flavored yogurt', 'https://images.unsplash.com/photo-1571212515416-fef01fc43637', 'cat_dairy', 3, true);

-- Insert sample products
INSERT INTO products (id, name, description, category_id, brand, price, unit, weight_volume, nutritional_info, ingredients, allergens, storage_instructions, origin_country, is_organic, is_active) VALUES
  ('prod_banana', 'Bananas', 'Fresh yellow bananas, perfect for snacking', 'cat_fruits', 'Fresh Farm', 2.99, 'per_kg', '1 kg', '{"calories": 89, "carbs": 23, "fiber": 2.6, "sugar": 12, "protein": 1.1}', 'Bananas', '{}', 'Store at room temperature', 'Ecuador', false, true),
  ('prod_apple_red', 'Red Apples', 'Crisp and sweet red apples', 'cat_fruits', 'Orchard Fresh', 4.99, 'per_kg', '1 kg', '{"calories": 52, "carbs": 14, "fiber": 2.4, "sugar": 10, "protein": 0.3}', 'Apples', '{}', 'Refrigerate for longer freshness', 'USA', true, true),
  ('prod_milk_whole', 'Whole Milk', 'Fresh whole milk, 3.25% fat', 'cat_milk', 'Dairy Best', 3.49, 'per_liter', '1 L', '{"calories": 150, "fat": 8, "protein": 8, "carbs": 12, "calcium": "30% DV"}', 'Milk', '{milk}', 'Keep refrigerated at 4°C or below', 'Canada', false, true),
  ('prod_bread_whole_wheat', 'Whole Wheat Bread', 'Nutritious whole wheat bread loaf', 'cat_bakery', 'Bakery Fresh', 2.79, 'per_loaf', '675g', '{"calories": 80, "carbs": 15, "fiber": 3, "protein": 4, "sodium": 150}', 'Whole wheat flour, water, yeast, salt, honey', '{gluten,"may contain sesame"}', 'Store in cool, dry place', 'Canada', false, true),
  ('prod_chicken_breast', 'Chicken Breast', 'Fresh boneless, skinless chicken breast', 'cat_meat_seafood', 'Farm Fresh', 12.99, 'per_kg', '1 kg', '{"calories": 165, "protein": 31, "fat": 3.6, "carbs": 0}', 'Chicken breast', '{}', 'Keep refrigerated, use within 2 days', 'Canada', false, true),
  ('prod_rice_basmati', 'Basmati Rice', 'Premium long-grain basmati rice', 'cat_pantry', 'Golden Grain', 8.99, 'per_bag', '5 kg', '{"calories": 205, "carbs": 45, "protein": 4.3, "fiber": 0.6}', 'Basmati rice', '{}', 'Store in cool, dry place', 'India', false, true);

-- Insert suppliers first (needed for foreign key references)
INSERT INTO suppliers (id, name, contact_person, email, phone, address, city, postal_code, country, is_active) VALUES
  ('sup_fresh_farm', 'Fresh Farm Suppliers', 'John Smith', 'john@freshfarm.com', '+1-555-0101', '123 Farm Road', 'Vancouver', 'V6B 1A1', 'Canada', true),
  ('sup_orchard_fresh', 'Orchard Fresh Co.', 'Sarah Johnson', 'sarah@orchardfresh.com', '+1-555-0102', '456 Orchard Lane', 'Kelowna', 'V1Y 2B2', 'Canada', true),
  ('sup_dairy_best', 'Dairy Best Ltd.', 'Mike Wilson', 'mike@dairybest.com', '+1-555-0103', '789 Dairy Drive', 'Calgary', 'T2P 3C3', 'Canada', true),
  ('sup_bakery_fresh', 'Bakery Fresh Inc.', 'Lisa Brown', 'lisa@bakeryfresh.com', '+1-555-0104', '321 Baker Street', 'Toronto', 'M5V 4D4', 'Canada', true),
  ('sup_farm_fresh', 'Farm Fresh Meats', 'David Lee', 'david@farmfresh.com', '+1-555-0105', '654 Ranch Road', 'Edmonton', 'T5J 5E5', 'Canada', true),
  ('sup_golden_grain', 'Golden Grain Imports', 'Anna Chen', 'anna@goldengrain.com', '+1-555-0106', '987 Grain Avenue', 'Montreal', 'H3B 6F6', 'Canada', true);

-- Insert inventory records
INSERT INTO inventory (product_id, quantity_available, reorder_level, max_stock_level, cost_price, supplier_id, last_restocked, expiry_date) VALUES
  ('prod_banana', 150, 20, 200, 1.50, 'sup_fresh_farm', NOW(), NOW() + INTERVAL '7 days'),
  ('prod_apple_red', 100, 15, 150, 2.99, 'sup_orchard_fresh', NOW(), NOW() + INTERVAL '14 days'),
  ('prod_milk_whole', 80, 10, 120, 2.20, 'sup_dairy_best', NOW(), NOW() + INTERVAL '10 days'),
  ('prod_bread_whole_wheat', 50, 8, 80, 1.40, 'sup_bakery_fresh', NOW(), NOW() + INTERVAL '5 days'),
  ('prod_chicken_breast', 30, 5, 50, 8.99, 'sup_farm_fresh', NOW(), NOW() + INTERVAL '3 days'),
  ('prod_rice_basmati', 25, 3, 40, 5.99, 'sup_golden_grain', NOW(), NOW() + INTERVAL '365 days');

-- Insert delivery zones
INSERT INTO delivery_zones (id, name, description, delivery_fee, minimum_order, estimated_delivery_time, is_active, coverage_area) VALUES
  ('zone_downtown', 'Downtown Core', 'Central business district', 4.99, 25.00, 60, true, ST_GeomFromText('POLYGON((-123.13 49.28, -123.11 49.28, -123.11 49.30, -123.13 49.30, -123.13 49.28))', 4326)),
  ('zone_suburbs', 'Suburban Areas', 'Residential suburbs', 6.99, 35.00, 90, true, ST_GeomFromText('POLYGON((-123.15 49.25, -123.10 49.25, -123.10 49.32, -123.15 49.32, -123.15 49.25))', 4326)),
  ('zone_extended', 'Extended Areas', 'Outer city limits', 9.99, 50.00, 120, true, ST_GeomFromText('POLYGON((-123.20 49.20, -123.05 49.20, -123.05 49.35, -123.20 49.35, -123.20 49.20))', 4326));

-- Insert delivery time slots
INSERT INTO delivery_time_slots (id, zone_id, start_time, end_time, max_orders, is_active, days_of_week) VALUES
  ('slot_morning_dt', 'zone_downtown', '09:00:00', '12:00:00', 20, true, '{1,2,3,4,5,6,7}'),
  ('slot_afternoon_dt', 'zone_downtown', '13:00:00', '17:00:00', 25, true, '{1,2,3,4,5,6,7}'),
  ('slot_evening_dt', 'zone_downtown', '18:00:00', '21:00:00', 15, true, '{1,2,3,4,5,6,7}'),
  ('slot_morning_sub', 'zone_suburbs', '10:00:00', '13:00:00', 15, true, '{1,2,3,4,5,6}'),
  ('slot_afternoon_sub', 'zone_suburbs', '14:00:00', '18:00:00', 20, true, '{1,2,3,4,5,6}'),
  ('slot_morning_ext', 'zone_extended', '11:00:00', '15:00:00', 10, true, '{1,2,3,4,5}');

-- Create admin user profile (this would be created after user signs up)
-- Note: The actual user creation happens through Supabase Auth
-- This is just the profile data that would be inserted via trigger

-- Insert sample promotions
INSERT INTO promotions (id, name, description, discount_type, discount_value, minimum_order_amount, start_date, end_date, usage_limit, is_active, applicable_categories, applicable_products) VALUES
  ('promo_welcome10', 'Welcome 10% Off', 'Get 10% off your first order', 'percentage', 10.00, 30.00, NOW(), NOW() + INTERVAL '30 days', 1000, true, '{}', '{}'),
  ('promo_fresh50', 'Fresh Produce $5 Off', '$5 off fresh produce orders over $25', 'fixed_amount', 5.00, 25.00, NOW(), NOW() + INTERVAL '7 days', 500, true, '{cat_fresh_produce}', '{}'),
  ('promo_dairy15', 'Dairy Special', '15% off all dairy products', 'percentage', 15.00, 0.00, NOW(), NOW() + INTERVAL '14 days', 300, true, '{cat_dairy}', '{}');
