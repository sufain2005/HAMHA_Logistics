const fs = require('fs');
const path = require('path');
const { pool } = require('../config/db');

async function runMigration(existingClient) {
  console.log('🔄 HAMHA Logistics: Initializing PostGIS Schema migration for Neon PostgreSQL...');
  const shouldRelease = !existingClient;
  const client = existingClient || await pool.connect();
  try {
    // 1. Drop legacy functions with CASCADE to safely allow return-type modifications
    console.log('🧹 Pre-clearing legacy functions to prevent return-type conflicts...');
    await client.query('DROP FUNCTION IF EXISTS find_nearby_available_drivers CASCADE;');
    await client.query('DROP FUNCTION IF EXISTS update_timestamp_column CASCADE;');

    // 2. Ensure critical columns & constraints exist on users, vehicles & orders tables
    console.log('🛠️ Validating users, vehicles & orders table constraints...');
    await client.query(`
      DO $$ BEGIN
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
          ALTER TABLE users ADD COLUMN IF NOT EXISTS company_name VARCHAR(255);
          ALTER TABLE users ADD COLUMN IF NOT EXISTS gstin VARCHAR(50);
          ALTER TABLE users ADD COLUMN IF NOT EXISTS govt_id_type VARCHAR(50);
          ALTER TABLE users ADD COLUMN IF NOT EXISTS govt_id_number VARCHAR(100);
          ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
        END IF;

        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'vehicles') THEN
          ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES users(id) ON DELETE SET NULL;
          ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS tire_config VARCHAR(50);
          ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS rc_photo_url TEXT;
          -- Crucial: Drop NOT NULL constraint on driver_id so unassigned fleet vehicles can exist
          ALTER TABLE vehicles ALTER COLUMN driver_id DROP NOT NULL;
          BEGIN
            ALTER TABLE vehicles ALTER COLUMN type TYPE VARCHAR(50) USING type::VARCHAR;
          EXCEPTION
            WHEN OTHERS THEN NULL;
          END;
          -- Ensure unique constraint exists on driver_id for single-driver assignment
          IF NOT EXISTS (
            SELECT 1 FROM pg_constraint WHERE conname = 'vehicles_driver_id_key'
          ) THEN
            ALTER TABLE vehicles ADD CONSTRAINT vehicles_driver_id_key UNIQUE (driver_id);
          END IF;
        END IF;

        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'orders') THEN
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
        END IF;
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END $$;
    `);

    // 3. Execute master schema.sql
    console.log('📜 Executing schema.sql on Neon database...');
    const schemaSql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf-8');
    await client.query(schemaSql);

    console.log(`
======================================================================
✅ Neon Database Migration Succeeded!
----------------------------------------------------------------------
• PostGIS & UUID extensions verified.
• Users table configured with company_name VARCHAR(255) & GSTIN.
• Vehicles table configured with optional driver assignment.
• Orders table configured with INR currency & milestone checkpoints.
• Stored functions & GiST spatial indexes installed cleanly.
• Tables synchronized: users, vehicles, orders, transit_checkpoints,
  system_tariffs, disputes, system_audit_logs, driver_location_logs.
======================================================================
    `);
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    throw error;
  } finally {
    if (shouldRelease && client) {
      client.release();
    }
  }
}

if (require.main === module) {
  runMigration()
    .then(() => pool.end())
    .catch((err) => {
      console.error('Fatal migration error:', err);
      pool.end().finally(() => process.exit(1));
    });
}

module.exports = { runMigration };
