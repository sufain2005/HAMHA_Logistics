-- ============================================================================
-- HAMHA LOGISTICS DATABASE SCHEMA
-- Target Database: Neon Serverless PostgreSQL with PostGIS
-- ============================================================================

-- 1. Enable PostGIS & UUID extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. Enumerated Types
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('customer', 'driver', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM (
        'pending', 
        'assigned', 
        'picked_up', 
        'in_transit', 
        'delivered', 
        'cancelled'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM (
        'pending', 
        'paid', 
        'failed', 
        'refunded'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE vehicle_type AS ENUM (
        'motorcycle', 
        'van', 
        'box_truck', 
        'heavy_freight'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Users Table (Customer, Driver, Fleet Owner/Admin)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role user_role NOT NULL DEFAULT 'customer',
    name VARCHAR(120) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(30) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    company_name VARCHAR(255),
    gstin VARCHAR(50),
    govt_id_type VARCHAR(50),
    govt_id_number VARCHAR(100),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure columns exist if table was previously created
ALTER TABLE users ADD COLUMN IF NOT EXISTS company_name VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS gstin VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS govt_id_type VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS govt_id_number VARCHAR(100);

-- 4. Vehicles Table (Commercial Fleet Directory & GPS Telematics)
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'van',
    tire_config VARCHAR(50),
    plate_number VARCHAR(30) UNIQUE NOT NULL,
    model VARCHAR(100) NOT NULL,
    color VARCHAR(50) DEFAULT 'White',
    rc_photo_url TEXT,
    max_weight_kg NUMERIC(10, 2) NOT NULL DEFAULT 1500.00,
    is_online BOOLEAN NOT NULL DEFAULT FALSE,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    -- Live PostGIS location (SRID 4326: WGS 84 GPS standard)
    current_location GEOGRAPHY(Point, 4326),
    heading NUMERIC(5, 2) DEFAULT 0.0,
    speed_kmh NUMERIC(5, 2) DEFAULT 0.0,
    last_location_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS tire_config VARCHAR(50);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS rc_photo_url TEXT;
ALTER TABLE vehicles ALTER COLUMN driver_id DROP NOT NULL;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'vehicles_driver_id_key'
    ) THEN
        ALTER TABLE vehicles ADD CONSTRAINT vehicles_driver_id_key UNIQUE (driver_id);
    END IF;
EXCEPTION
    WHEN duplicate_table OR duplicate_object THEN null;
END $$;

-- 5. Orders Table (Consignments)
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_code VARCHAR(16) UNIQUE NOT NULL, -- e.g., 'HMH-89241'
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status order_status NOT NULL DEFAULT 'pending',
    
    -- Cargo / Shipment specs
    cargo_type VARCHAR(100) NOT NULL,
    weight_kg NUMERIC(10, 2) NOT NULL,
    package_description TEXT,
    
    -- Pick-up point (Human address + PostGIS geography point)
    pickup_address TEXT NOT NULL,
    pickup_location GEOGRAPHY(Point, 4326) NOT NULL,
    pickup_contact_name VARCHAR(120),
    pickup_contact_phone VARCHAR(30),
    
    -- Drop-off point (Human address + PostGIS geography point)
    dropoff_address TEXT NOT NULL,
    dropoff_location GEOGRAPHY(Point, 4326) NOT NULL,
    dropoff_contact_name VARCHAR(120),
    dropoff_contact_phone VARCHAR(30),
    
    -- Routing & Financials
    fare_amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    distance_km NUMERIC(10, 2) NOT NULL,
    estimated_duration_min INT NOT NULL,
    payment_status payment_status NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50) DEFAULT 'UPI / Corporate Net Banking',
    
    -- Timestamps
    assigned_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure orders columns exist if table was previously created
ALTER TABLE orders ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'INR';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'UPI / Corporate Net Banking';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS package_description TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_contact_name VARCHAR(120);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_contact_phone VARCHAR(30);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS dropoff_contact_name VARCHAR(120);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS dropoff_contact_phone VARCHAR(30);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- 6. Transit Checkpoints Table (Consignment Milestone tracking)
CREATE TABLE IF NOT EXISTS transit_checkpoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    location VARCHAR(200) NOT NULL,
    district VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    timestamp_label VARCHAR(100) NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    order_index INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. System Tariffs & Dynamic Pricing Rules Table
CREATE TABLE IF NOT EXISTS system_tariffs (
    id VARCHAR(50) PRIMARY KEY DEFAULT 'active_tariffs',
    base_fee NUMERIC(10, 2) NOT NULL DEFAULT 350.00,
    per_km_rate NUMERIC(10, 2) NOT NULL DEFAULT 25.00,
    vehicle_rates JSONB NOT NULL DEFAULT '{"bike": 12.0, "mini_van": 22.0, "van": 32.0, "truck": 55.0, "heavy_4tire": 45.0, "heavy_6tire": 65.0, "heavy_8tire": 85.0, "heavy_12tire": 110.0}',
    weight_base_allowance_kg NUMERIC(10, 2) NOT NULL DEFAULT 10.00,
    per_kg_rate NUMERIC(10, 2) NOT NULL DEFAULT 18.00,
    heavy_weight_per_kg_rate NUMERIC(10, 2) NOT NULL DEFAULT 12.00,
    minimum_fare NUMERIC(10, 2) NOT NULL DEFAULT 250.00,
    gst_percent NUMERIC(5, 2) NOT NULL DEFAULT 18.00,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    updated_by VARCHAR(120) DEFAULT 'Fleet Owner',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default tariffs row if not exists
INSERT INTO system_tariffs (id, base_fee, per_km_rate, vehicle_rates, weight_base_allowance_kg, per_kg_rate, heavy_weight_per_kg_rate, minimum_fare, gst_percent, currency, updated_by, updated_at)
VALUES (
    'active_tariffs', 350.00, 25.00, 
    '{"bike": 12.0, "mini_van": 22.0, "van": 32.0, "truck": 55.0, "heavy_4tire": 45.0, "heavy_6tire": 65.0, "heavy_8tire": 85.0, "heavy_12tire": 110.0}',
    10.00, 18.00, 12.00, 250.00, 18.00, 'INR', 'HAMHA Fleet Owner', NOW()
) ON CONFLICT (id) DO NOTHING;

-- 8. Customer Disputes Table
CREATE TABLE IF NOT EXISTS disputes (
    id VARCHAR(50) PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    order_code VARCHAR(30) NOT NULL,
    customer_name VARCHAR(120) NOT NULL,
    customer_phone VARCHAR(30) NOT NULL,
    driver_name VARCHAR(120),
    driver_phone VARCHAR(30),
    type VARCHAR(100) NOT NULL,
    severity VARCHAR(30) NOT NULL DEFAULT 'medium',
    status VARCHAR(30) NOT NULL DEFAULT 'open',
    customer_rating INT DEFAULT 1,
    customer_complaint TEXT NOT NULL,
    driver_explanation TEXT,
    refund_amount NUMERIC(10, 2) DEFAULT 0.00,
    resolution_notes TEXT,
    filed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- 9. System Audit Logs Table
CREATE TABLE IF NOT EXISTS system_audit_logs (
    id VARCHAR(50) PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    admin_user VARCHAR(120) NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    target_entity VARCHAR(150) NOT NULL,
    details TEXT NOT NULL,
    ip_address VARCHAR(80) DEFAULT '127.0.0.1 (Web Control Tower)',
    security_hash VARCHAR(100)
);

-- 10. Driver Location Breadcrumb Logs (Audit & History tracking)
CREATE TABLE IF NOT EXISTS driver_location_logs (
    id BIGSERIAL PRIMARY KEY,
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    heading NUMERIC(5, 2) DEFAULT 0.0,
    speed_kmh NUMERIC(5, 2) DEFAULT 0.0,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- SPATIAL & PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_vehicles_current_location 
    ON vehicles USING GIST (current_location);

CREATE INDEX IF NOT EXISTS idx_orders_pickup_location 
    ON orders USING GIST (pickup_location);

CREATE INDEX IF NOT EXISTS idx_orders_dropoff_location 
    ON orders USING GIST (dropoff_location);

CREATE INDEX IF NOT EXISTS idx_driver_location_logs_location 
    ON driver_location_logs USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_vehicles_owner_id ON vehicles(owner_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_driver_id ON vehicles(driver_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_online_avail ON vehicles(is_online, is_available);
CREATE INDEX IF NOT EXISTS idx_checkpoints_order_id ON transit_checkpoints(order_id);

-- ============================================================================
-- HELPER FUNCTIONS & TRIGGERS
-- ============================================================================

DROP FUNCTION IF EXISTS update_timestamp_column CASCADE;
CREATE OR REPLACE FUNCTION update_timestamp_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp_column();

DROP TRIGGER IF EXISTS trg_vehicles_updated_at ON vehicles;
CREATE TRIGGER trg_vehicles_updated_at
    BEFORE UPDATE ON vehicles
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp_column();

DROP TRIGGER IF EXISTS trg_orders_updated_at ON orders;
CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp_column();

-- Geospatial function: Find active drivers within a radius (in meters)
DROP FUNCTION IF EXISTS find_nearby_available_drivers CASCADE;
CREATE OR REPLACE FUNCTION find_nearby_available_drivers(
    origin_lon DOUBLE PRECISION,
    origin_lat DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 10000
)
RETURNS TABLE (
    driver_id UUID,
    driver_name VARCHAR,
    phone VARCHAR,
    vehicle_type VARCHAR,
    plate_number VARCHAR,
    distance_meters DOUBLE PRECISION,
    current_lon DOUBLE PRECISION,
    current_lat DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id AS driver_id,
        u.name AS driver_name,
        u.phone,
        v.type::VARCHAR AS vehicle_type,
        v.plate_number,
        ST_Distance(
            v.current_location,
            ST_SetSRID(ST_MakePoint(origin_lon, origin_lat), 4326)::geography
        ) AS distance_meters,
        ST_X(v.current_location::geometry) AS current_lon,
        ST_Y(v.current_location::geometry) AS current_lat
    FROM vehicles v
    JOIN users u ON u.id = v.driver_id
    WHERE v.is_online = TRUE 
      AND v.is_available = TRUE
      AND v.current_location IS NOT NULL
      AND ST_DWithin(
          v.current_location,
          ST_SetSRID(ST_MakePoint(origin_lon, origin_lat), 4326)::geography,
          radius_meters
      )
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql;

-- 11. Truck Requirements Table (Owner Load Board / 3-Day Truck Search Broadcasts)
CREATE TABLE IF NOT EXISTS truck_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    owner_name VARCHAR(120) NOT NULL,
    owner_company VARCHAR(255),
    owner_phone VARCHAR(30) NOT NULL,
    owner_whatsapp VARCHAR(30),
    truck_type VARCHAR(50) NOT NULL DEFAULT 'box_truck',
    title VARCHAR(255) NOT NULL,
    cargo_type VARCHAR(100) NOT NULL,
    weight_tons NUMERIC(6, 2) NOT NULL DEFAULT 5.0,
    pickup_state VARCHAR(100) NOT NULL,
    pickup_city VARCHAR(100) NOT NULL,
    pickup_address TEXT NOT NULL,
    dropoff_state VARCHAR(100) NOT NULL,
    dropoff_city VARCHAR(100) NOT NULL,
    dropoff_address TEXT NOT NULL,
    offered_fare NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    distance_km NUMERIC(10, 2) DEFAULT 160.0,
    validity_days INT NOT NULL DEFAULT 3,
    posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '3 days'),
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_truck_req_state ON truck_requirements(pickup_state, status, expires_at);
CREATE INDEX IF NOT EXISTS idx_truck_req_owner ON truck_requirements(owner_id);

