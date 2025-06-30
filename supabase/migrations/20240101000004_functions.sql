-- Database Functions and Stored Procedures

-- Function to get products with inventory and category info
CREATE OR REPLACE FUNCTION get_products_with_details(
    category_filter TEXT DEFAULT NULL,
    search_term TEXT DEFAULT NULL,
    limit_count INTEGER DEFAULT 20,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id TEXT,
    name TEXT,
    description TEXT,
    category_id TEXT,
    category_name TEXT,
    brand TEXT,
    price DECIMAL(10,2),
    unit unit_type,
    weight_volume TEXT,
    is_organic BOOLEAN,
    images TEXT[],
    tags TEXT[],
    available_quantity INTEGER,
    average_rating DECIMAL(3,2),
    review_count INTEGER,
    is_in_stock BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.description,
        p.category_id,
        c.name as category_name,
        p.brand,
        p.price,
        p.unit,
        p.weight_volume,
        p.is_organic,
        p.images,
        p.tags,
        COALESCE(i.quantity_available - i.reserved_quantity, 0) as available_quantity,
        COALESCE(AVG(pr.rating), 0)::DECIMAL(3,2) as average_rating,
        COUNT(pr.id)::INTEGER as review_count,
        CASE WHEN COALESCE(i.quantity_available - i.reserved_quantity, 0) > 0 THEN true ELSE false END as is_in_stock
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN inventory i ON p.id = i.product_id
    LEFT JOIN product_reviews pr ON p.id = pr.product_id AND pr.is_approved = true
    WHERE 
        p.is_active = true
        AND (category_filter IS NULL OR p.category_id = category_filter OR c.parent_id = category_filter)
        AND (search_term IS NULL OR p.name ILIKE '%' || search_term || '%' OR p.description ILIKE '%' || search_term || '%')
    GROUP BY p.id, c.name, i.quantity_available, i.reserved_quantity
    ORDER BY p.name
    LIMIT limit_count OFFSET offset_count;
END;
$$ LANGUAGE plpgsql;

-- Function to add item to cart
CREATE OR REPLACE FUNCTION add_to_cart(
    user_id_param UUID,
    product_id_param TEXT,
    quantity_param INTEGER
)
RETURNS JSON AS $$
DECLARE
    current_price DECIMAL(10,2);
    available_qty INTEGER;
    cart_item_id UUID;
    result JSON;
BEGIN
    -- Get current product price
    SELECT price INTO current_price FROM products WHERE id = product_id_param AND is_active = true;
    
    IF current_price IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Product not found or inactive');
    END IF;
    
    -- Check inventory availability
    SELECT (quantity_available - reserved_quantity) INTO available_qty
    FROM inventory WHERE product_id = product_id_param;
    
    IF available_qty < quantity_param THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient inventory');
    END IF;
    
    -- Insert or update cart item
    INSERT INTO shopping_cart (user_id, product_id, quantity, unit_price)
    VALUES (user_id_param, product_id_param, quantity_param, current_price)
    ON CONFLICT (user_id, product_id)
    DO UPDATE SET 
        quantity = shopping_cart.quantity + quantity_param,
        unit_price = current_price,
        updated_at = NOW()
    RETURNING id INTO cart_item_id;
    
    result := json_build_object(
        'success', true,
        'cart_item_id', cart_item_id,
        'message', 'Item added to cart successfully'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get cart items with product details
CREATE OR REPLACE FUNCTION get_cart_items(user_id_param UUID)
RETURNS TABLE (
    cart_id UUID,
    product_id TEXT,
    product_name TEXT,
    product_image TEXT,
    brand TEXT,
    unit_price DECIMAL(10,2),
    quantity INTEGER,
    total_price DECIMAL(10,2),
    available_quantity INTEGER,
    is_available BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sc.id as cart_id,
        p.id as product_id,
        p.name as product_name,
        CASE WHEN array_length(p.images, 1) > 0 THEN p.images[1] ELSE NULL END as product_image,
        p.brand,
        sc.unit_price,
        sc.quantity,
        (sc.unit_price * sc.quantity) as total_price,
        COALESCE(i.quantity_available - i.reserved_quantity, 0) as available_quantity,
        CASE WHEN COALESCE(i.quantity_available - i.reserved_quantity, 0) >= sc.quantity THEN true ELSE false END as is_available
    FROM shopping_cart sc
    JOIN products p ON sc.product_id = p.id
    LEFT JOIN inventory i ON p.id = i.product_id
    WHERE sc.user_id = user_id_param
    ORDER BY sc.created_at;
END;
$$ LANGUAGE plpgsql;

-- Function to create order from cart
CREATE OR REPLACE FUNCTION create_order_from_cart(
    user_id_param UUID,
    delivery_address_id_param UUID,
    delivery_zone_id_param TEXT,
    delivery_slot_id_param TEXT,
    scheduled_delivery_date_param DATE,
    payment_method_param payment_method,
    special_instructions_param TEXT DEFAULT NULL,
    promotion_id_param TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    order_id UUID;
    cart_total DECIMAL(10,2);
    delivery_fee DECIMAL(10,2);
    discount_amount DECIMAL(10,2) := 0;
    cart_item RECORD;
    result JSON;
BEGIN
    -- Validate cart is not empty
    SELECT SUM(unit_price * quantity) INTO cart_total
    FROM shopping_cart WHERE user_id = user_id_param;
    
    IF cart_total IS NULL OR cart_total = 0 THEN
        RETURN json_build_object('success', false, 'error', 'Cart is empty');
    END IF;
    
    -- Get delivery fee
    SELECT dz.delivery_fee INTO delivery_fee
    FROM delivery_zones dz WHERE dz.id = delivery_zone_id_param;
    
    -- Check minimum order requirement
    IF EXISTS (
        SELECT 1 FROM delivery_zones dz 
        WHERE dz.id = delivery_zone_id_param 
        AND dz.minimum_order > cart_total
    ) THEN
        RETURN json_build_object('success', false, 'error', 'Order does not meet minimum requirement');
    END IF;
    
    -- Apply promotion if provided
    IF promotion_id_param IS NOT NULL THEN
        SELECT calculate_promotion_discount(promotion_id_param, cart_total) INTO discount_amount;
    END IF;
    
    -- Create order
    INSERT INTO orders (
        user_id, 
        subtotal, 
        delivery_fee, 
        discount_amount,
        total_amount,
        payment_method,
        delivery_address_id,
        delivery_zone_id,
        delivery_slot_id,
        scheduled_delivery_date,
        special_instructions,
        promotion_id
    ) VALUES (
        user_id_param,
        cart_total,
        delivery_fee,
        discount_amount,
        cart_total + delivery_fee - discount_amount,
        payment_method_param,
        delivery_address_id_param,
        delivery_zone_id_param,
        delivery_slot_id_param,
        scheduled_delivery_date_param,
        special_instructions_param,
        promotion_id_param
    ) RETURNING id INTO order_id;
    
    -- Move cart items to order items
    FOR cart_item IN 
        SELECT product_id, quantity, unit_price 
        FROM shopping_cart 
        WHERE user_id = user_id_param
    LOOP
        INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price)
        VALUES (order_id, cart_item.product_id, cart_item.quantity, cart_item.unit_price, cart_item.quantity * cart_item.unit_price);
    END LOOP;
    
    -- Clear cart
    DELETE FROM shopping_cart WHERE user_id = user_id_param;
    
    -- Update promotion usage if applicable
    IF promotion_id_param IS NOT NULL THEN
        UPDATE promotions SET usage_count = usage_count + 1 WHERE id = promotion_id_param;
    END IF;
    
    result := json_build_object(
        'success', true,
        'order_id', order_id,
        'message', 'Order created successfully'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate promotion discount
CREATE OR REPLACE FUNCTION calculate_promotion_discount(
    promotion_id_param TEXT,
    order_amount DECIMAL(10,2)
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    promo RECORD;
    discount DECIMAL(10,2) := 0;
BEGIN
    SELECT * INTO promo FROM promotions 
    WHERE id = promotion_id_param 
    AND is_active = true 
    AND start_date <= NOW() 
    AND end_date >= NOW()
    AND (usage_limit IS NULL OR usage_count < usage_limit);
    
    IF promo IS NULL THEN
        RETURN 0;
    END IF;
    
    IF order_amount < promo.minimum_order_amount THEN
        RETURN 0;
    END IF;
    
    IF promo.discount_type = 'percentage' THEN
        discount := order_amount * (promo.discount_value / 100);
    ELSE
        discount := promo.discount_value;
    END IF;
    
    -- Apply maximum discount limit if set
    IF promo.maximum_discount_amount IS NOT NULL AND discount > promo.maximum_discount_amount THEN
        discount := promo.maximum_discount_amount;
    END IF;
    
    RETURN discount;
END;
$$ LANGUAGE plpgsql;

-- Function to get order details with items
CREATE OR REPLACE FUNCTION get_order_details(order_id_param UUID)
RETURNS JSON AS $$
DECLARE
    order_data JSON;
    items_data JSON;
BEGIN
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
        'delivery_address', json_build_object(
            'full_name', ca.full_name,
            'phone', ca.phone,
            'address_line_1', ca.address_line_1,
            'address_line_2', ca.address_line_2,
            'city', ca.city,
            'postal_code', ca.postal_code
        ),
        'delivery_zone', dz.name,
        'delivery_slot', json_build_object(
            'start_time', dts.start_time,
            'end_time', dts.end_time
        )
    ) INTO order_data
    FROM orders o
    LEFT JOIN customer_addresses ca ON o.delivery_address_id = ca.id
    LEFT JOIN delivery_zones dz ON o.delivery_zone_id = dz.id
    LEFT JOIN delivery_time_slots dts ON o.delivery_slot_id = dts.id
    WHERE o.id = order_id_param;
    
    -- Get order items
    SELECT json_agg(
        json_build_object(
            'product_id', oi.product_id,
            'product_name', p.name,
            'product_image', CASE WHEN array_length(p.images, 1) > 0 THEN p.images[1] ELSE NULL END,
            'brand', p.brand,
            'quantity', oi.quantity,
            'unit_price', oi.unit_price,
            'total_price', oi.total_price
        )
    ) INTO items_data
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    WHERE oi.order_id = order_id_param;
    
    RETURN json_build_object(
        'order', order_data,
        'items', items_data
    );
END;
$$ LANGUAGE plpgsql;

-- Function to search products with filters
CREATE OR REPLACE FUNCTION search_products(
    search_query TEXT DEFAULT NULL,
    category_ids TEXT[] DEFAULT NULL,
    min_price DECIMAL(10,2) DEFAULT NULL,
    max_price DECIMAL(10,2) DEFAULT NULL,
    is_organic_filter BOOLEAN DEFAULT NULL,
    in_stock_only BOOLEAN DEFAULT true,
    sort_by TEXT DEFAULT 'name', -- 'name', 'price_asc', 'price_desc', 'rating'
    limit_count INTEGER DEFAULT 20,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id TEXT,
    name TEXT,
    description TEXT,
    category_name TEXT,
    brand TEXT,
    price DECIMAL(10,2),
    unit unit_type,
    is_organic BOOLEAN,
    images TEXT[],
    available_quantity INTEGER,
    average_rating DECIMAL(3,2),
    review_count INTEGER
) AS $$
DECLARE
    sort_clause TEXT;
BEGIN
    -- Build sort clause
    CASE sort_by
        WHEN 'price_asc' THEN sort_clause := 'p.price ASC';
        WHEN 'price_desc' THEN sort_clause := 'p.price DESC';
        WHEN 'rating' THEN sort_clause := 'average_rating DESC NULLS LAST';
        ELSE sort_clause := 'p.name ASC';
    END CASE;

    RETURN QUERY EXECUTE format('
        SELECT
            p.id,
            p.name,
            p.description,
            c.name as category_name,
            p.brand,
            p.price,
            p.unit,
            p.is_organic,
            p.images,
            COALESCE(i.quantity_available - i.reserved_quantity, 0) as available_quantity,
            COALESCE(AVG(pr.rating), 0)::DECIMAL(3,2) as average_rating,
            COUNT(pr.id)::INTEGER as review_count
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN inventory i ON p.id = i.product_id
        LEFT JOIN product_reviews pr ON p.id = pr.product_id AND pr.is_approved = true
        WHERE
            p.is_active = true
            AND ($1 IS NULL OR p.name ILIKE ''%%'' || $1 || ''%%'' OR p.description ILIKE ''%%'' || $1 || ''%%'')
            AND ($2 IS NULL OR p.category_id = ANY($2))
            AND ($3 IS NULL OR p.price >= $3)
            AND ($4 IS NULL OR p.price <= $4)
            AND ($5 IS NULL OR p.is_organic = $5)
            AND ($6 = false OR COALESCE(i.quantity_available - i.reserved_quantity, 0) > 0)
        GROUP BY p.id, c.name, i.quantity_available, i.reserved_quantity
        ORDER BY %s
        LIMIT $7 OFFSET $8
    ', sort_clause)
    USING search_query, category_ids, min_price, max_price, is_organic_filter, in_stock_only, limit_count, offset_count;
END;
$$ LANGUAGE plpgsql;
