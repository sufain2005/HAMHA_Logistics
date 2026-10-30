const fs = require('fs');
const path = require('path');
const { pool } = require('../config/db');

async function runMigration() {
  console.log('🔄 HAMHA Logistics: Initializing PostGIS Schema migration for Neon PostgreSQL...');
  let client;
  try {
    const schemaSql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf-8');
    client = await pool.connect();
    
    // Execute schema directly on Neon PostgreSQL
    await client.query(schemaSql);
    
    console.log(`
======================================================================
✅ Migration Succeeded!
----------------------------------------------------------------------
• PostGIS & UUID extensions verified.
• Tables created/updated: users, vehicles, orders, transit_checkpoints,
  system_tariffs, disputes, system_audit_logs, driver_location_logs.
• GiST spatial indexes active for real-time ST_DWithin radius matching.
• Default Freight Tariffs in INR (₹) synchronized into Neon DB.
======================================================================
    `);
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    if (client) client.release();
    await pool.end();
  }
}

runMigration();
