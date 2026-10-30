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

-- 3. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role user_role NOT NULL DEFAULT 'customer',
    name VARCHAR(120) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(30) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Vehicles Table (Dedicated to drivers)
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type vehicle_type NOT NULL DEFAULT 'van',
    plate_number VARCHAR(30) UNIQUE NOT NULL,
    model VARCHAR(100) NOT NULL,
    color VARCHAR(50),
    max_weight_kg NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
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

-- 5. Orders Table
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
    distance_km NUMERIC(10, 2) NOT NULL,
    estimated_duration_min INT NOT NULL,
    payment_status payment_status NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50) DEFAULT 'credit_card',
    
    -- Timestamps
    assigned_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Driver Location Breadcrumb Logs (Audit & History tracking)
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

-- Spatial GiST Indexes for rapid geo-queries
CREATE INDEX IF NOT EXISTS idx_vehicles_current_location 
    ON vehicles USING GIST (current_location);

CREATE INDEX IF NOT EXISTS idx_orders_pickup_location 
    ON orders USING GIST (pickup_location);

CREATE INDEX IF NOT EXISTS idx_orders_dropoff_location 
    ON orders USING GIST (dropoff_location);

CREATE INDEX IF NOT EXISTS idx_driver_location_logs_location 
    ON driver_location_logs USING GIST (location);

-- Standard lookup indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_vehicles_driver_id ON vehicles(driver_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_online_avail ON vehicles(is_online, is_available);

-- ============================================================================
-- HELPER FUNCTIONS & TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp function
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
CREATE OR REPLACE FUNCTION find_nearby_available_drivers(
    origin_lon DOUBLE PRECISION,
    origin_lat DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 10000
)
RETURNS TABLE (
    driver_id UUID,
    driver_name VARCHAR,
    phone VARCHAR,
    vehicle_type vehicle_type,
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
        v.type AS vehicle_type,
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

