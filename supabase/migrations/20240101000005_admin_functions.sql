-- Admin-specific functions for store management

-- Function to get sales analytics
CREATE OR REPLACE FUNCTION get_sales_analytics(
    start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    end_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSON AS $$
DECLARE
    total_sales DECIMAL(12,2);
    total_orders INTEGER;
    avg_order_value DECIMAL(10,2);
    top_products JSON;
    sales_by_day JSON;
    result JSON;
BEGIN
    -- Get total sales and orders
    SELECT 
        COALESCE(SUM(total_amount), 0),
        COUNT(*)
    INTO total_sales, total_orders
    FROM orders
    WHERE created_at::DATE BETWEEN start_date AND end_date
    AND status NOT IN ('cancelled', 'refunded');
    
    -- Calculate average order value
    avg_order_value := CASE WHEN total_orders > 0 THEN total_sales / total_orders ELSE 0 END;
    
    -- Get top selling products
    SELECT json_agg(
        json_build_object(
            'product_id', oi.product_id,
            'product_name', p.name,
            'total_quantity', SUM(oi.quantity),
            'total_revenue', SUM(oi.total_price)
        ) ORDER BY SUM(oi.quantity) DESC
    ) INTO top_products
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    JOIN orders o ON oi.order_id = o.id
    WHERE o.created_at::DATE BETWEEN start_date AND end_date
    AND o.status NOT IN ('cancelled', 'refunded')
    GROUP BY oi.product_id, p.name
    LIMIT 10;
    
    -- Get sales by day
    SELECT json_agg(
        json_build_object(
            'date', sales_date,
            'total_sales', daily_sales,
            'order_count', daily_orders
        ) ORDER BY sales_date
    ) INTO sales_by_day
    FROM (
        SELECT 
            created_at::DATE as sales_date,
            SUM(total_amount) as daily_sales,
            COUNT(*) as daily_orders
        FROM orders
        WHERE created_at::DATE BETWEEN start_date AND end_date
        AND status NOT IN ('cancelled', 'refunded')
        GROUP BY created_at::DATE
    ) daily_stats;
    
    result := json_build_object(
        'period', json_build_object('start_date', start_date, 'end_date', end_date),
        'total_sales', total_sales,
        'total_orders', total_orders,
        'average_order_value', avg_order_value,
        'top_products', top_products,
        'sales_by_day', sales_by_day
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get inventory alerts
CREATE OR REPLACE FUNCTION get_inventory_alerts()
RETURNS TABLE (
    product_id TEXT,
    product_name TEXT,
    current_quantity INTEGER,
    reorder_level INTEGER,
    days_until_expiry INTEGER,
    alert_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as product_id,
        p.name as product_name,
        i.quantity_available as current_quantity,
        i.reorder_level,
        CASE 
            WHEN i.expiry_date IS NOT NULL 
            THEN (i.expiry_date - CURRENT_DATE)::INTEGER 
            ELSE NULL 
        END as days_until_expiry,
        CASE 
            WHEN i.quantity_available <= i.reorder_level THEN 'LOW_STOCK'
            WHEN i.expiry_date IS NOT NULL AND i.expiry_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'EXPIRING_SOON'
            WHEN i.expiry_date IS NOT NULL AND i.expiry_date <= CURRENT_DATE THEN 'EXPIRED'
            ELSE 'OK'
        END as alert_type
    FROM inventory i
    JOIN products p ON i.product_id = p.id
    WHERE 
        p.is_active = true
        AND (
            i.quantity_available <= i.reorder_level
            OR (i.expiry_date IS NOT NULL AND i.expiry_date <= CURRENT_DATE + INTERVAL '7 days')
        )
    ORDER BY 
        CASE 
            WHEN i.expiry_date IS NOT NULL AND i.expiry_date <= CURRENT_DATE THEN 1
            WHEN i.expiry_date IS NOT NULL AND i.expiry_date <= CURRENT_DATE + INTERVAL '3 days' THEN 2
            WHEN i.quantity_available <= i.reorder_level THEN 3
            ELSE 4
        END,
        i.expiry_date NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Function to update product inventory
CREATE OR REPLACE FUNCTION update_product_inventory(
    product_id_param TEXT,
    quantity_change INTEGER,
    cost_price_param DECIMAL(10,2) DEFAULT NULL,
    supplier_id_param TEXT DEFAULT NULL,
    batch_number_param TEXT DEFAULT NULL,
    expiry_date_param DATE DEFAULT NULL,
    operation_type TEXT DEFAULT 'restock' -- 'restock', 'adjustment', 'damage', 'return'
)
RETURNS JSON AS $$
DECLARE
    current_inventory RECORD;
    result JSON;
BEGIN
    -- Get current inventory
    SELECT * INTO current_inventory FROM inventory WHERE product_id = product_id_param;
    
    IF current_inventory IS NULL THEN
        -- Create new inventory record
        INSERT INTO inventory (
            product_id, 
            quantity_available, 
            cost_price, 
            supplier_id, 
            batch_number, 
            expiry_date,
            last_restocked
        ) VALUES (
            product_id_param,
            GREATEST(quantity_change, 0),
            cost_price_param,
            supplier_id_param,
            batch_number_param,
            expiry_date_param,
            CASE WHEN quantity_change > 0 THEN NOW() ELSE NULL END
        );
    ELSE
        -- Update existing inventory
        UPDATE inventory 
        SET 
            quantity_available = GREATEST(quantity_available + quantity_change, 0),
            cost_price = COALESCE(cost_price_param, cost_price),
            supplier_id = COALESCE(supplier_id_param, supplier_id),
            batch_number = COALESCE(batch_number_param, batch_number),
            expiry_date = COALESCE(expiry_date_param, expiry_date),
            last_restocked = CASE WHEN quantity_change > 0 THEN NOW() ELSE last_restocked END,
            updated_at = NOW()
        WHERE product_id = product_id_param;
    END IF;
    
    -- Log inventory transaction (you might want to create an inventory_transactions table)
    -- INSERT INTO inventory_transactions (product_id, quantity_change, operation_type, notes, created_by)
    -- VALUES (product_id_param, quantity_change, operation_type, 'Inventory updated via admin function', auth.uid());
    
    result := json_build_object(
        'success', true,
        'product_id', product_id_param,
        'quantity_change', quantity_change,
        'operation_type', operation_type,
        'message', 'Inventory updated successfully'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get order management dashboard
CREATE OR REPLACE FUNCTION get_order_management_dashboard()
RETURNS JSON AS $$
DECLARE
    pending_orders INTEGER;
    confirmed_orders INTEGER;
    preparing_orders INTEGER;
    out_for_delivery INTEGER;
    recent_orders JSON;
    result JSON;
BEGIN
    -- Count orders by status
    SELECT 
        COUNT(*) FILTER (WHERE status = 'pending'),
        COUNT(*) FILTER (WHERE status = 'confirmed'),
        COUNT(*) FILTER (WHERE status = 'preparing'),
        COUNT(*) FILTER (WHERE status = 'out_for_delivery')
    INTO pending_orders, confirmed_orders, preparing_orders, out_for_delivery
    FROM orders
    WHERE created_at >= CURRENT_DATE;
    
    -- Get recent orders
    SELECT json_agg(
        json_build_object(
            'id', o.id,
            'order_number', o.order_number,
            'customer_name', up.full_name,
            'status', o.status,
            'total_amount', o.total_amount,
            'created_at', o.created_at,
            'scheduled_delivery_date', o.scheduled_delivery_date
        ) ORDER BY o.created_at DESC
    ) INTO recent_orders
    FROM orders o
    JOIN user_profiles up ON o.user_id = up.id
    WHERE o.created_at >= CURRENT_DATE - INTERVAL '7 days'
    LIMIT 20;
    
    result := json_build_object(
        'order_counts', json_build_object(
            'pending', pending_orders,
            'confirmed', confirmed_orders,
            'preparing', preparing_orders,
            'out_for_delivery', out_for_delivery
        ),
        'recent_orders', recent_orders
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to update order status with validation
CREATE OR REPLACE FUNCTION update_order_status(
    order_id_param UUID,
    new_status order_status,
    notes_param TEXT DEFAULT NULL,
    updated_by_param UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    current_order RECORD;
    valid_transitions TEXT[];
    result JSON;
BEGIN
    -- Get current order
    SELECT * INTO current_order FROM orders WHERE id = order_id_param;
    
    IF current_order IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Order not found');
    END IF;
    
    -- Define valid status transitions
    CASE current_order.status
        WHEN 'pending' THEN valid_transitions := ARRAY['confirmed', 'cancelled'];
        WHEN 'confirmed' THEN valid_transitions := ARRAY['preparing', 'cancelled'];
        WHEN 'preparing' THEN valid_transitions := ARRAY['ready_for_delivery', 'cancelled'];
        WHEN 'ready_for_delivery' THEN valid_transitions := ARRAY['out_for_delivery'];
        WHEN 'out_for_delivery' THEN valid_transitions := ARRAY['delivered', 'cancelled'];
        WHEN 'delivered' THEN valid_transitions := ARRAY['refunded'];
        ELSE valid_transitions := ARRAY[]::TEXT[];
    END CASE;
    
    -- Check if transition is valid
    IF NOT (new_status::TEXT = ANY(valid_transitions)) THEN
        RETURN json_build_object(
            'success', false, 
            'error', format('Invalid status transition from %s to %s', current_order.status, new_status)
        );
    END IF;
    
    -- Update order status
    UPDATE orders 
    SET 
        status = new_status,
        updated_by = COALESCE(updated_by_param, auth.uid()),
        updated_at = NOW()
    WHERE id = order_id_param;
    
    -- Insert status history record
    INSERT INTO order_status_history (order_id, status, notes, changed_by)
    VALUES (order_id_param, new_status, notes_param, COALESCE(updated_by_param, auth.uid()));
    
    result := json_build_object(
        'success', true,
        'order_id', order_id_param,
        'old_status', current_order.status,
        'new_status', new_status,
        'message', 'Order status updated successfully'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get customer analytics
CREATE OR REPLACE FUNCTION get_customer_analytics(
    start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    end_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSON AS $$
DECLARE
    total_customers INTEGER;
    new_customers INTEGER;
    repeat_customers INTEGER;
    top_customers JSON;
    result JSON;
BEGIN
    -- Get total customers
    SELECT COUNT(*) INTO total_customers FROM user_profiles WHERE role = 'customer';
    
    -- Get new customers in period
    SELECT COUNT(*) INTO new_customers 
    FROM user_profiles 
    WHERE role = 'customer' AND created_at::DATE BETWEEN start_date AND end_date;
    
    -- Get repeat customers (customers with more than one order)
    SELECT COUNT(DISTINCT user_id) INTO repeat_customers
    FROM orders
    WHERE created_at::DATE BETWEEN start_date AND end_date
    AND user_id IN (
        SELECT user_id FROM orders GROUP BY user_id HAVING COUNT(*) > 1
    );
    
    -- Get top customers by order value
    SELECT json_agg(
        json_build_object(
            'customer_id', o.user_id,
            'customer_name', up.full_name,
            'customer_email', up.email,
            'total_orders', COUNT(o.id),
            'total_spent', SUM(o.total_amount)
        ) ORDER BY SUM(o.total_amount) DESC
    ) INTO top_customers
    FROM orders o
    JOIN user_profiles up ON o.user_id = up.id
    WHERE o.created_at::DATE BETWEEN start_date AND end_date
    AND o.status NOT IN ('cancelled', 'refunded')
    GROUP BY o.user_id, up.full_name, up.email
    LIMIT 10;
    
    result := json_build_object(
        'period', json_build_object('start_date', start_date, 'end_date', end_date),
        'total_customers', total_customers,
        'new_customers', new_customers,
        'repeat_customers', repeat_customers,
        'top_customers', top_customers
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
