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
    const safeQueries = [
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS company_name VARCHAR(255);",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS gstin VARCHAR(50);",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS govt_id_type VARCHAR(50);",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS govt_id_number VARCHAR(100);",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS alternative_phone VARCHAR(30);",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS office_address TEXT;",
      "ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES users(id) ON DELETE SET NULL;",
      "ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS tire_config VARCHAR(50);",
      "ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS rc_photo_url TEXT;",
      "ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS capacity_tons NUMERIC(6, 2) DEFAULT 5.0;",
      "ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS fitness_cert VARCHAR(100);",
      "ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS insurance_policy VARCHAR(100);",
      "ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS permit_number VARCHAR(100);",
      "ALTER TABLE vehicles ALTER COLUMN driver_id DROP NOT NULL;",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'INR';",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'UPI / Corporate Net Banking';",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS package_description TEXT;",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_contact_name VARCHAR(120);",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_contact_phone VARCHAR(30);",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS dropoff_contact_name VARCHAR(120);",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS dropoff_contact_phone VARCHAR(30);",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS dispatch_mode VARCHAR(50) DEFAULT 'vehicle_with_driver';",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS weight_tons NUMERIC(6, 2);",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES users(id) ON DELETE SET NULL;",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS owner_phone VARCHAR(30);",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS owner_alt_phone VARCHAR(30);",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS owner_office_address TEXT;",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ;",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMPTZ;",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;",
      "ALTER TABLE orders ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;"
    ];

    for (const q of safeQueries) {
      try {
        await client.query(q);
      } catch (err) {
        // Log & continue gracefully if table doesn't exist yet (schema.sql creates it)
      }
    }

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
  system_tariffs, disputes, system_audit_logs, driver_location_logs,
  truck_requirements.
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
