-- Extended Database Schema for Call Carl
-- This schema supports the full application functionality including:
-- - User management and households
-- - Task tracking and reminders
-- - Service provider management
-- - Quote comparison
-- - Supply ordering
-- - Subscription payments
-- - Appointment scheduling

-- ============================================
-- CORE TABLES (from database.py)
-- ============================================

-- Users table (already referenced in database.py)
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    phone_number TEXT NOT NULL UNIQUE,
    household_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_response_date TIMESTAMP WITH TIME ZONE,
    consecutive_missed_responses INTEGER DEFAULT 0,
    onboarding_complete BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_household ON users(household_id);

-- Households table
CREATE TABLE IF NOT EXISTS households (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    address TEXT NOT NULL,
    year_built INTEGER,
    hvac_type TEXT,
    hvac_age INTEGER,
    water_heater_type TEXT,
    water_heater_age INTEGER,
    has_fireplace BOOLEAN DEFAULT FALSE,
    has_septic BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_households_created ON households(created_at DESC);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    task_type TEXT NOT NULL,
    task_name TEXT NOT NULL,
    frequency_days INTEGER NOT NULL,
    instructions TEXT,
    is_custom BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    next_due_date TIMESTAMP WITH TIME ZONE,
    last_completed_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_household ON tasks(household_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(next_due_date) WHERE is_active = TRUE;

-- ============================================
-- SERVICE PROVIDER MANAGEMENT
-- ============================================

-- Service providers (plumbers, electricians, HVAC, etc.)
CREATE TABLE IF NOT EXISTS service_providers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    service_type TEXT NOT NULL, -- 'plumber', 'electrician', 'hvac', 'landscaping', etc.
    phone TEXT,
    email TEXT,
    address TEXT,
    website TEXT,
    notes TEXT, -- Why they like them, special pricing, etc.
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    is_preferred BOOLEAN DEFAULT FALSE,
    opt_out_marketing BOOLEAN DEFAULT FALSE, -- User preference for marketing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_providers_household ON service_providers(household_id);
CREATE INDEX IF NOT EXISTS idx_providers_type ON service_providers(service_type);
CREATE INDEX IF NOT EXISTS idx_providers_preferred ON service_providers(is_preferred) WHERE is_preferred = TRUE;

-- Service history (when they used a provider, what was done)
CREATE TABLE IF NOT EXISTS service_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES service_providers(id) ON DELETE SET NULL,
    service_type TEXT NOT NULL,
    description TEXT,
    service_date DATE NOT NULL,
    cost DECIMAL(10, 2),
    notes TEXT,
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_history_household ON service_history(household_id);
CREATE INDEX IF NOT EXISTS idx_service_history_provider ON service_history(provider_id);
CREATE INDEX IF NOT EXISTS idx_service_history_date ON service_history(service_date DESC);

-- ============================================
-- QUOTE MANAGEMENT
-- ============================================

-- Quotes received from service providers
CREATE TABLE IF NOT EXISTS quotes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES service_providers(id) ON DELETE SET NULL,
    service_type TEXT NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    quote_date DATE NOT NULL,
    expiration_date DATE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quotes_household ON quotes(household_id);
CREATE INDEX IF NOT EXISTS idx_quotes_provider ON quotes(provider_id);
CREATE INDEX IF NOT EXISTS idx_quotes_status ON quotes(status);
CREATE INDEX IF NOT EXISTS idx_quotes_date ON quotes(quote_date DESC);

-- ============================================
-- SUPPLY ORDERING
-- ============================================

-- Products/supplies that need regular ordering
CREATE TABLE IF NOT EXISTS maintenance_supplies (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    product_category TEXT, -- 'hvac_filter', 'water_filter', 'smoke_detector_battery', etc.
    brand TEXT,
    model_number TEXT,
    vendor_name TEXT,
    vendor_url TEXT,
    typical_price DECIMAL(10, 2),
    reorder_frequency_days INTEGER, -- How often to reorder
    last_ordered_date DATE,
    next_order_date DATE,
    auto_order_enabled BOOLEAN DEFAULT FALSE,
    quantity_per_order INTEGER DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_supplies_household ON maintenance_supplies(household_id);
CREATE INDEX IF NOT EXISTS idx_supplies_next_order ON maintenance_supplies(next_order_date) WHERE auto_order_enabled = TRUE;

-- Order history
CREATE TABLE IF NOT EXISTS supply_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    supply_id UUID REFERENCES maintenance_supplies(id) ON DELETE SET NULL,
    order_date DATE NOT NULL,
    vendor TEXT NOT NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2),
    order_number TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'ordered', 'shipped', 'delivered', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_household ON supply_orders(household_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON supply_orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_date ON supply_orders(order_date DESC);

-- ============================================
-- APPOINTMENTS & SERVICE REQUESTS
-- ============================================

-- Appointments with service providers
CREATE TABLE IF NOT EXISTS appointments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES service_providers(id) ON DELETE SET NULL,
    service_type TEXT NOT NULL,
    description TEXT,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_appointments_household ON appointments(household_id);
CREATE INDEX IF NOT EXISTS idx_appointments_provider ON appointments(provider_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);

-- Service request log (for tracking quote/booking requests)
CREATE TABLE IF NOT EXISTS service_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    service_type TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'quotes_requested', 'quotes_received', 'provider_selected', 'scheduled', 'completed', 'cancelled')),
    requested_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_requests_household ON service_requests(household_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_status ON service_requests(status);
CREATE INDEX IF NOT EXISTS idx_service_requests_date ON service_requests(requested_date DESC);

-- ============================================
-- SUBSCRIPTION & PAYMENTS
-- ============================================

-- Subscription plans
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    plan_name TEXT NOT NULL UNIQUE,
    description TEXT,
    price_monthly DECIMAL(10, 2) NOT NULL,
    price_yearly DECIMAL(10, 2),
    features JSONB, -- Array of features included
    max_households INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default plans
INSERT INTO subscription_plans (plan_name, description, price_monthly, price_yearly, features) VALUES
('free', 'Basic reminders only', 0, 0, '["basic_reminders", "2_tasks_max"]'),
('basic', 'Essential home maintenance', 4.99, 49.99, '["unlimited_reminders", "custom_tasks", "task_history"]'),
('premium', 'Full service with provider management', 9.99, 99.99, '["unlimited_reminders", "custom_tasks", "task_history", "provider_management", "quote_comparison", "supply_ordering"]')
ON CONFLICT (plan_name) DO NOTHING;

-- User subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'past_due')),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    auto_renew BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires ON user_subscriptions(expires_at) WHERE status = 'active';

-- Payment history
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    payment_method TEXT, -- 'card', 'paypal', etc.
    payment_provider TEXT, -- 'stripe', 'paypal', etc.
    transaction_id TEXT,
    status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_subscription ON payments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date DESC);

-- ============================================
-- USER PREFERENCES & SETTINGS
-- ============================================

-- User preferences
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    reminder_frequency TEXT DEFAULT 'normal' CHECK (reminder_frequency IN ('minimal', 'normal', 'frequent')),
    preferred_reminder_time TIME DEFAULT '09:00:00',
    timezone TEXT DEFAULT 'America/New_York',
    opt_out_marketing BOOLEAN DEFAULT FALSE,
    opt_out_service_provider_sharing BOOLEAN DEFAULT FALSE,
    notification_preferences JSONB DEFAULT '{"sms": true, "email": false, "push": false}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_preferences_user ON user_preferences(user_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_supplies ENABLE ROW LEVEL SECURITY;
ALTER TABLE supply_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Basic policies (you'll need to customize based on your auth setup)
-- For now, allow service_role full access

CREATE POLICY "Service role has full access" ON users
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON households
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON tasks
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON service_providers
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON service_history
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON quotes
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON maintenance_supplies
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON supply_orders
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON appointments
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON service_requests
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON user_subscriptions
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON payments
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY "Service role has full access" ON user_preferences
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER update_households_updated_at BEFORE UPDATE ON households
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_providers_updated_at BEFORE UPDATE ON service_providers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quotes_updated_at BEFORE UPDATE ON quotes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_supplies_updated_at BEFORE UPDATE ON maintenance_supplies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_requests_updated_at BEFORE UPDATE ON service_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- NOTES
-- ============================================

-- This schema supports:
-- ✅ Auto order supplies for maintenance (maintenance_supplies, supply_orders)
-- ✅ Remind users who they use for different services (service_providers, service_history)
-- ✅ Evaluate quotes received vs other vendors (quotes table with comparison)
-- ✅ Pay a subscription fee (subscription_plans, user_subscriptions, payments)
-- ✅ Opt out of marketing to service providers (user_preferences, service_providers.opt_out_marketing)
-- ✅ Call service providers to get quotes and book appointments (service_requests, appointments)

-- Future enhancements to consider:
-- - Add webhook integrations for payment processors (Stripe, PayPal)
-- - Add notification queue table for SMS/email management
-- - Add analytics tables for tracking user engagement
-- - Add referral program tables
-- - Add service provider reviews/ratings from multiple users
