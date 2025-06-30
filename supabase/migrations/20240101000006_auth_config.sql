-- Authentication and User Management Configuration

-- Note: Custom JWT claims are handled through Supabase Dashboard
-- or through custom hooks in production environments

-- Function to check if email is admin email
CREATE OR REPLACE FUNCTION is_admin_email(email_param TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN email_param IN (
        'admin@grocerystore.com',
        'manager@grocerystore.com',
        'support@grocerystore.com'
    );
END;
$$ LANGUAGE plpgsql;

-- Enhanced user profile creation with role assignment
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role user_role;
BEGIN
    -- Determine user role based on email
    IF is_admin_email(NEW.email) THEN
        user_role := 'admin';
    ELSE
        user_role := 'customer';
    END IF;
    
    INSERT INTO public.user_profiles (
        id, 
        email, 
        full_name, 
        role,
        phone
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        user_role,
        NEW.phone
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate user permissions
CREATE OR REPLACE FUNCTION check_user_permission(
    required_role user_role,
    user_id_param UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_id UUID;
    current_user_role user_role;
BEGIN
    current_user_id := COALESCE(user_id_param, auth.uid());
    
    IF current_user_id IS NULL THEN
        RETURN false;
    END IF;
    
    SELECT role INTO current_user_role 
    FROM user_profiles 
    WHERE id = current_user_id;
    
    -- Admin and store_manager can access everything
    IF current_user_role IN ('admin', 'store_manager') THEN
        RETURN true;
    END IF;
    
    -- Check specific role requirements
    CASE required_role
        WHEN 'customer' THEN
            RETURN current_user_role = 'customer';
        WHEN 'delivery_driver' THEN
            RETURN current_user_role = 'delivery_driver';
        WHEN 'store_manager' THEN
            RETURN current_user_role IN ('admin', 'store_manager');
        WHEN 'admin' THEN
            RETURN current_user_role = 'admin';
        ELSE
            RETURN false;
    END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user role (admin only)
CREATE OR REPLACE FUNCTION update_user_role(
    target_user_id UUID,
    new_role user_role
)
RETURNS JSON AS $$
DECLARE
    current_user_role user_role;
    result JSON;
BEGIN
    -- Check if current user is admin
    SELECT role INTO current_user_role FROM user_profiles WHERE id = auth.uid();
    
    IF current_user_role != 'admin' THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient permissions');
    END IF;
    
    -- Update user role
    UPDATE user_profiles 
    SET 
        role = new_role,
        updated_at = NOW()
    WHERE id = target_user_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    result := json_build_object(
        'success', true,
        'user_id', target_user_id,
        'new_role', new_role,
        'message', 'User role updated successfully'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user profile with permissions
CREATE OR REPLACE FUNCTION get_user_profile(user_id_param UUID DEFAULT NULL)
RETURNS JSON AS $$
DECLARE
    target_user_id UUID;
    profile_data JSON;
    permissions JSON;
BEGIN
    target_user_id := COALESCE(user_id_param, auth.uid());
    
    IF target_user_id IS NULL THEN
        RETURN json_build_object('error', 'User not authenticated');
    END IF;
    
    -- Get user profile
    SELECT json_build_object(
        'id', up.id,
        'email', up.email,
        'full_name', up.full_name,
        'phone', up.phone,
        'date_of_birth', up.date_of_birth,
        'role', up.role,
        'avatar_url', up.avatar_url,
        'is_active', up.is_active,
        'preferences', up.preferences,
        'created_at', up.created_at,
        'updated_at', up.updated_at
    ) INTO profile_data
    FROM user_profiles up
    WHERE up.id = target_user_id;
    
    IF profile_data IS NULL THEN
        RETURN json_build_object('error', 'User profile not found');
    END IF;
    
    -- Get user permissions based on role
    SELECT json_build_object(
        'can_manage_products', up.role IN ('admin', 'store_manager'),
        'can_manage_orders', up.role IN ('admin', 'store_manager'),
        'can_manage_users', up.role = 'admin',
        'can_view_analytics', up.role IN ('admin', 'store_manager'),
        'can_manage_inventory', up.role IN ('admin', 'store_manager'),
        'can_manage_promotions', up.role IN ('admin', 'store_manager'),
        'can_manage_delivery', up.role IN ('admin', 'store_manager', 'delivery_driver')
    ) INTO permissions
    FROM user_profiles up
    WHERE up.id = target_user_id;
    
    RETURN json_build_object(
        'profile', profile_data,
        'permissions', permissions
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to deactivate user account
CREATE OR REPLACE FUNCTION deactivate_user_account(
    target_user_id UUID,
    reason TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    current_user_role user_role;
    result JSON;
BEGIN
    -- Check if current user is admin
    SELECT role INTO current_user_role FROM user_profiles WHERE id = auth.uid();
    
    IF current_user_role != 'admin' THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient permissions');
    END IF;
    
    -- Deactivate user
    UPDATE user_profiles 
    SET 
        is_active = false,
        updated_at = NOW()
    WHERE id = target_user_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'User not found');
    END IF;
    
    -- Cancel any pending orders for the user
    UPDATE orders 
    SET 
        status = 'cancelled',
        updated_at = NOW()
    WHERE user_id = target_user_id AND status = 'pending';
    
    -- Clear shopping cart
    DELETE FROM shopping_cart WHERE user_id = target_user_id;
    
    result := json_build_object(
        'success', true,
        'user_id', target_user_id,
        'reason', reason,
        'message', 'User account deactivated successfully'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all users (admin only)
CREATE OR REPLACE FUNCTION get_all_users(
    role_filter user_role DEFAULT NULL,
    is_active_filter BOOLEAN DEFAULT NULL,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    email TEXT,
    full_name TEXT,
    phone TEXT,
    role user_role,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    last_order_date TIMESTAMPTZ,
    total_orders INTEGER,
    total_spent DECIMAL(12,2)
) AS $$
BEGIN
    -- Check if current user is admin
    IF NOT check_user_permission('admin') THEN
        RAISE EXCEPTION 'Insufficient permissions';
    END IF;
    
    RETURN QUERY
    SELECT 
        up.id,
        up.email,
        up.full_name,
        up.phone,
        up.role,
        up.is_active,
        up.created_at,
        MAX(o.created_at) as last_order_date,
        COUNT(o.id)::INTEGER as total_orders,
        COALESCE(SUM(o.total_amount), 0) as total_spent
    FROM user_profiles up
    LEFT JOIN orders o ON up.id = o.user_id AND o.status NOT IN ('cancelled', 'refunded')
    WHERE 
        (role_filter IS NULL OR up.role = role_filter)
        AND (is_active_filter IS NULL OR up.is_active = is_active_filter)
    GROUP BY up.id, up.email, up.full_name, up.phone, up.role, up.is_active, up.created_at
    ORDER BY up.created_at DESC
    LIMIT limit_count OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create indexes for better performance on user queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_active ON user_profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON user_profiles(created_at);
