-- Admin Interface Functions and Views

-- Create view for product management
CREATE OR REPLACE VIEW admin_products_view AS
SELECT 
    p.id,
    p.name,
    p.description,
    p.category_id,
    c.name as category_name,
    p.brand,
    p.sku,
    p.barcode,
    p.price,
    p.unit,
    p.weight_volume,
    p.is_organic,
    p.is_active,
    p.images,
    p.tags,
    p.created_at,
    p.updated_at,
    i.quantity_available,
    i.reserved_quantity,
    i.reorder_level,
    i.cost_price,
    i.expiry_date,
    s.name as supplier_name,
    COALESCE(AVG(pr.rating), 0)::DECIMAL(3,2) as average_rating,
    COUNT(pr.id) as review_count
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN inventory i ON p.id = i.product_id
LEFT JOIN suppliers s ON i.supplier_id = s.id
LEFT JOIN product_reviews pr ON p.id = pr.product_id AND pr.is_approved = true
GROUP BY p.id, c.name, i.quantity_available, i.reserved_quantity, i.reorder_level, i.cost_price, i.expiry_date, s.name;

-- Function to create or update product
CREATE OR REPLACE FUNCTION admin_upsert_product(
    product_data JSON
)
RETURNS JSON AS $$
DECLARE
    product_id TEXT;
    result JSON;
BEGIN
    -- Check admin permissions
    IF NOT check_user_permission('store_manager') THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient permissions');
    END IF;
    
    product_id := product_data->>'id';
    
    -- Insert or update product
    INSERT INTO products (
        id, name, description, category_id, brand, sku, barcode, price, unit,
        weight_volume, nutritional_info, ingredients, allergens, storage_instructions,
        origin_country, is_organic, is_active, images, tags
    ) VALUES (
        COALESCE(product_id, 'prod_' || generate_random_uuid()),
        product_data->>'name',
        product_data->>'description',
        product_data->>'category_id',
        product_data->>'brand',
        product_data->>'sku',
        product_data->>'barcode',
        (product_data->>'price')::DECIMAL(10,2),
        (product_data->>'unit')::unit_type,
        product_data->>'weight_volume',
        COALESCE((product_data->>'nutritional_info')::JSONB, '{}'::JSONB),
        product_data->>'ingredients',
        COALESCE((product_data->>'allergens')::TEXT[], ARRAY[]::TEXT[]),
        product_data->>'storage_instructions',
        product_data->>'origin_country',
        COALESCE((product_data->>'is_organic')::BOOLEAN, false),
        COALESCE((product_data->>'is_active')::BOOLEAN, true),
        COALESCE((product_data->>'images')::TEXT[], ARRAY[]::TEXT[]),
        COALESCE((product_data->>'tags')::TEXT[], ARRAY[]::TEXT[])
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        category_id = EXCLUDED.category_id,
        brand = EXCLUDED.brand,
        sku = EXCLUDED.sku,
        barcode = EXCLUDED.barcode,
        price = EXCLUDED.price,
        unit = EXCLUDED.unit,
        weight_volume = EXCLUDED.weight_volume,
        nutritional_info = EXCLUDED.nutritional_info,
        ingredients = EXCLUDED.ingredients,
        allergens = EXCLUDED.allergens,
        storage_instructions = EXCLUDED.storage_instructions,
        origin_country = EXCLUDED.origin_country,
        is_organic = EXCLUDED.is_organic,
        is_active = EXCLUDED.is_active,
        images = EXCLUDED.images,
        tags = EXCLUDED.tags,
        updated_at = NOW()
    RETURNING id INTO product_id;
    
    -- Update inventory if provided
    IF product_data ? 'inventory' THEN
        INSERT INTO inventory (
            product_id, quantity_available, reorder_level, max_stock_level,
            cost_price, supplier_id, expiry_date
        ) VALUES (
            product_id,
            COALESCE((product_data->'inventory'->>'quantity_available')::INTEGER, 0),
            COALESCE((product_data->'inventory'->>'reorder_level')::INTEGER, 10),
            COALESCE((product_data->'inventory'->>'max_stock_level')::INTEGER, 100),
            (product_data->'inventory'->>'cost_price')::DECIMAL(10,2),
            product_data->'inventory'->>'supplier_id',
            (product_data->'inventory'->>'expiry_date')::DATE
        )
        ON CONFLICT (product_id) DO UPDATE SET
            quantity_available = EXCLUDED.quantity_available,
            reorder_level = EXCLUDED.reorder_level,
            max_stock_level = EXCLUDED.max_stock_level,
            cost_price = EXCLUDED.cost_price,
            supplier_id = EXCLUDED.supplier_id,
            expiry_date = EXCLUDED.expiry_date,
            updated_at = NOW();
    END IF;
    
    result := json_build_object(
        'success', true,
        'product_id', product_id,
        'message', 'Product saved successfully'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to bulk update product prices
CREATE OR REPLACE FUNCTION admin_bulk_update_prices(
    price_updates JSON
)
RETURNS JSON AS $$
DECLARE
    update_item JSON;
    updated_count INTEGER := 0;
    result JSON;
BEGIN
    -- Check admin permissions
    IF NOT check_user_permission('store_manager') THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient permissions');
    END IF;
    
    -- Process each price update
    FOR update_item IN SELECT * FROM json_array_elements(price_updates)
    LOOP
        UPDATE products 
        SET 
            price = (update_item->>'new_price')::DECIMAL(10,2),
            updated_at = NOW()
        WHERE id = update_item->>'product_id' AND is_active = true;
        
        IF FOUND THEN
            updated_count := updated_count + 1;
        END IF;
    END LOOP;
    
    result := json_build_object(
        'success', true,
        'updated_count', updated_count,
        'message', format('%s products updated successfully', updated_count)
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get comprehensive order details for admin
CREATE OR REPLACE FUNCTION admin_get_order_details(order_id_param UUID)
RETURNS JSON AS $$
DECLARE
    order_data JSON;
    customer_data JSON;
    items_data JSON;
    status_history JSON;
    result JSON;
BEGIN
    -- Check admin permissions
    IF NOT check_user_permission('store_manager') THEN
        RETURN json_build_object('error', 'Insufficient permissions');
    END IF;
    
    -- Get order information
    SELECT json_build_object(
        'id', o.id,
        'order_number', o.order_number,
        'status', o.status,
        'subtotal', o.subtotal,
        'tax_amount', o.tax_amount,
        'delivery_fee', o.delivery_fee,
        'discount_amount', o.discount_amount,
        'total_amount', o.total_amount,
        'payment_method', o.payment_method,
        'payment_status', o.payment_status,
        'scheduled_delivery_date', o.scheduled_delivery_date,
        'special_instructions', o.special_instructions,
        'created_at', o.created_at,
        'updated_at', o.updated_at,
        'delivery_address', json_build_object(
            'full_name', ca.full_name,
            'phone', ca.phone,
            'address_line_1', ca.address_line_1,
            'address_line_2', ca.address_line_2,
            'city', ca.city,
            'postal_code', ca.postal_code,
            'delivery_instructions', ca.delivery_instructions
        ),
        'delivery_zone', json_build_object(
            'id', dz.id,
            'name', dz.name,
            'delivery_fee', dz.delivery_fee
        ),
        'delivery_slot', json_build_object(
            'id', dts.id,
            'start_time', dts.start_time,
            'end_time', dts.end_time
        )
    ) INTO order_data
    FROM orders o
    LEFT JOIN customer_addresses ca ON o.delivery_address_id = ca.id
    LEFT JOIN delivery_zones dz ON o.delivery_zone_id = dz.id
    LEFT JOIN delivery_time_slots dts ON o.delivery_slot_id = dts.id
    WHERE o.id = order_id_param;
    
    -- Get customer information
    SELECT json_build_object(
        'id', up.id,
        'full_name', up.full_name,
        'email', up.email,
        'phone', up.phone,
        'total_orders', COUNT(o2.id),
        'total_spent', COALESCE(SUM(o2.total_amount), 0)
    ) INTO customer_data
    FROM orders o
    JOIN user_profiles up ON o.user_id = up.id
    LEFT JOIN orders o2 ON up.id = o2.user_id AND o2.status NOT IN ('cancelled', 'refunded')
    WHERE o.id = order_id_param
    GROUP BY up.id, up.full_name, up.email, up.phone;
    
    -- Get order items
    SELECT json_agg(
        json_build_object(
            'product_id', oi.product_id,
            'product_name', p.name,
            'product_image', CASE WHEN array_length(p.images, 1) > 0 THEN p.images[1] ELSE NULL END,
            'brand', p.brand,
            'sku', p.sku,
            'quantity', oi.quantity,
            'unit_price', oi.unit_price,
            'total_price', oi.total_price,
            'current_stock', COALESCE(i.quantity_available, 0)
        )
    ) INTO items_data
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    LEFT JOIN inventory i ON p.id = i.product_id
    WHERE oi.order_id = order_id_param;
    
    -- Get status history
    SELECT json_agg(
        json_build_object(
            'status', osh.status,
            'notes', osh.notes,
            'changed_by', up.full_name,
            'created_at', osh.created_at
        ) ORDER BY osh.created_at
    ) INTO status_history
    FROM order_status_history osh
    LEFT JOIN user_profiles up ON osh.changed_by = up.id
    WHERE osh.order_id = order_id_param;
    
    result := json_build_object(
        'order', order_data,
        'customer', customer_data,
        'items', items_data,
        'status_history', status_history
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sales report
CREATE OR REPLACE FUNCTION admin_generate_sales_report(
    start_date DATE,
    end_date DATE,
    group_by TEXT DEFAULT 'day' -- 'day', 'week', 'month'
)
RETURNS JSON AS $$
DECLARE
    date_format TEXT;
    sales_data JSON;
    summary_data JSON;
    top_products JSON;
    result JSON;
BEGIN
    -- Check admin permissions
    IF NOT check_user_permission('store_manager') THEN
        RETURN json_build_object('error', 'Insufficient permissions');
    END IF;
    
    -- Set date format based on grouping
    CASE group_by
        WHEN 'week' THEN date_format := 'YYYY-"W"WW';
        WHEN 'month' THEN date_format := 'YYYY-MM';
        ELSE date_format := 'YYYY-MM-DD';
    END CASE;
    
    -- Get sales data grouped by period
    EXECUTE format('
        SELECT json_agg(
            json_build_object(
                ''period'', period,
                ''total_sales'', total_sales,
                ''order_count'', order_count,
                ''average_order_value'', average_order_value
            ) ORDER BY period
        )
        FROM (
            SELECT 
                TO_CHAR(created_at, %L) as period,
                SUM(total_amount) as total_sales,
                COUNT(*) as order_count,
                AVG(total_amount) as average_order_value
            FROM orders
            WHERE created_at::DATE BETWEEN %L AND %L
            AND status NOT IN (''cancelled'', ''refunded'')
            GROUP BY TO_CHAR(created_at, %L)
        ) grouped_sales
    ', date_format, start_date, end_date, date_format)
    INTO sales_data;
    
    -- Get summary data
    SELECT json_build_object(
        'total_sales', COALESCE(SUM(total_amount), 0),
        'total_orders', COUNT(*),
        'average_order_value', COALESCE(AVG(total_amount), 0),
        'unique_customers', COUNT(DISTINCT user_id)
    ) INTO summary_data
    FROM orders
    WHERE created_at::DATE BETWEEN start_date AND end_date
    AND status NOT IN ('cancelled', 'refunded');
    
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
    
    result := json_build_object(
        'period', json_build_object('start_date', start_date, 'end_date', end_date),
        'group_by', group_by,
        'summary', summary_data,
        'sales_data', sales_data,
        'top_products', top_products
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
