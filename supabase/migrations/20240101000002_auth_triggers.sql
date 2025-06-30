-- Auth triggers and user profile management

-- Function to create user profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        CASE 
            WHEN NEW.email = 'admin@grocerystore.com' THEN 'admin'::user_role
            ELSE 'customer'::user_role
        END
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update user profile when auth user is updated
CREATE OR REPLACE FUNCTION public.handle_user_update()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.user_profiles
    SET 
        email = NEW.email,
        updated_at = NOW()
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update profile when auth user is updated
CREATE TRIGGER on_auth_user_updated
    AFTER UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_user_update();

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = true THEN
        UPDATE customer_addresses 
        SET is_default = false 
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for default address management
CREATE TRIGGER ensure_single_default_address_trigger
    BEFORE INSERT OR UPDATE ON customer_addresses
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_address();

-- Function to update inventory when order is placed
CREATE OR REPLACE FUNCTION update_inventory_on_order()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status != 'confirmed') THEN
        -- Reserve inventory for confirmed orders
        UPDATE inventory 
        SET reserved_quantity = reserved_quantity + oi.quantity
        FROM order_items oi
        WHERE oi.order_id = NEW.id AND inventory.product_id = oi.product_id;
    ELSIF OLD.status = 'confirmed' AND NEW.status IN ('cancelled', 'refunded') THEN
        -- Release reserved inventory for cancelled/refunded orders
        UPDATE inventory 
        SET reserved_quantity = reserved_quantity - oi.quantity
        FROM order_items oi
        WHERE oi.order_id = NEW.id AND inventory.product_id = oi.product_id;
    ELSIF OLD.status = 'confirmed' AND NEW.status = 'delivered' THEN
        -- Reduce actual inventory for delivered orders
        UPDATE inventory 
        SET 
            quantity_available = quantity_available - oi.quantity,
            reserved_quantity = reserved_quantity - oi.quantity
        FROM order_items oi
        WHERE oi.order_id = NEW.id AND inventory.product_id = oi.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for inventory management
CREATE TRIGGER update_inventory_on_order_trigger
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_inventory_on_order();

-- Function to log order status changes
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (order_id, status, notes, changed_by)
        VALUES (NEW.id, NEW.status, 'Status changed from ' || COALESCE(OLD.status::text, 'null') || ' to ' || NEW.status::text, NEW.updated_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_by column to orders table for tracking who made changes
ALTER TABLE orders ADD COLUMN updated_by UUID REFERENCES user_profiles(id);

-- Trigger for order status logging
CREATE TRIGGER log_order_status_change_trigger
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();

-- Function to calculate order totals
CREATE OR REPLACE FUNCTION calculate_order_totals()
RETURNS TRIGGER AS $$
DECLARE
    order_subtotal DECIMAL(10,2);
    order_tax DECIMAL(10,2);
    order_delivery_fee DECIMAL(10,2);
    order_discount DECIMAL(10,2);
    order_total DECIMAL(10,2);
    tax_rate DECIMAL(5,4) := 0.12; -- 12% tax rate (adjust as needed)
BEGIN
    -- Calculate subtotal from order items
    SELECT COALESCE(SUM(total_price), 0) INTO order_subtotal
    FROM order_items
    WHERE order_id = NEW.id;
    
    -- Get delivery fee from zone
    SELECT COALESCE(dz.delivery_fee, 0) INTO order_delivery_fee
    FROM delivery_zones dz
    WHERE dz.id = NEW.delivery_zone_id;
    
    -- Calculate tax (on subtotal only, not delivery)
    order_tax := order_subtotal * tax_rate;
    
    -- Get discount amount (implement promotion logic here)
    order_discount := COALESCE(NEW.discount_amount, 0);
    
    -- Calculate total
    order_total := order_subtotal + order_tax + order_delivery_fee - order_discount;
    
    -- Update order with calculated values
    UPDATE orders
    SET 
        subtotal = order_subtotal,
        tax_amount = order_tax,
        delivery_fee = order_delivery_fee,
        total_amount = order_total,
        updated_at = NOW()
    WHERE id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to recalculate order totals when items change
CREATE TRIGGER calculate_order_totals_trigger
    AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION calculate_order_totals();

-- Function to validate product availability
CREATE OR REPLACE FUNCTION validate_product_availability()
RETURNS TRIGGER AS $$
DECLARE
    available_qty INTEGER;
BEGIN
    SELECT (quantity_available - reserved_quantity) INTO available_qty
    FROM inventory
    WHERE product_id = NEW.product_id;
    
    IF available_qty < NEW.quantity THEN
        RAISE EXCEPTION 'Insufficient inventory for product %. Available: %, Requested: %', 
            NEW.product_id, available_qty, NEW.quantity;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to validate availability when adding to cart or creating order items
CREATE TRIGGER validate_cart_availability_trigger
    BEFORE INSERT OR UPDATE ON shopping_cart
    FOR EACH ROW
    EXECUTE FUNCTION validate_product_availability();

CREATE TRIGGER validate_order_item_availability_trigger
    BEFORE INSERT OR UPDATE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION validate_product_availability();
