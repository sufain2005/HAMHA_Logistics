const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');

async function seedDatabase() {
  console.log('🌱 Seeding HAMHA Logistics database with demo users, vehicles, and orders...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const salt = await bcrypt.genSalt(10);
    const adminPass = await bcrypt.hash('Admin@123456', salt);
    const customerPass = await bcrypt.hash('Customer@123456', salt);
    const driverPass = await bcrypt.hash('Driver@123456', salt);

    // 1. Seed Users (Admin, Customer, Driver)
    const adminRes = await client.query(
      `INSERT INTO users (name, email, phone, password_hash, role, is_verified)
       VALUES ('Hamha Commander', 'admin@hamha.com', '+10000000001', $1, 'admin', TRUE)
       ON CONFLICT (email) DO UPDATE SET password_hash = $1
       RETURNING id`,
      [adminPass]
    );

    const customerRes = await client.query(
      `INSERT INTO users (name, email, phone, password_hash, role, is_verified)
       VALUES ('Alex Mercer', 'customer@hamha.com', '+10000000002', $1, 'customer', TRUE)
       ON CONFLICT (email) DO UPDATE SET password_hash = $1
       RETURNING id`,
      [customerPass]
    );

    const driverRes = await client.query(
      `INSERT INTO users (name, email, phone, password_hash, role, is_verified)
       VALUES ('Marcus Vance', 'driver@hamha.com', '+10000000003', $1, 'driver', TRUE)
       ON CONFLICT (email) DO UPDATE SET password_hash = $1
       RETURNING id`,
      [driverPass]
    );

    const adminId = adminRes.rows[0].id;
    const customerId = customerRes.rows[0].id;
    const driverId = driverRes.rows[0].id;

    // 2. Seed Driver Vehicle with live PostGIS coordinates (San Francisco / Urban Metro area)
    // Longitude: -122.4194, Latitude: 37.7749
    await client.query(
      `INSERT INTO vehicles (
        driver_id, type, plate_number, model, color, max_weight_kg, 
        is_online, is_available, current_location, heading, speed_kmh
       ) VALUES (
        $1, 'van', 'HMH-VAN-01', 'Mercedes-Benz Sprinter 2500', 'Crisp White', 1200.00,
        TRUE, FALSE, ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326)::geography, 45.0, 38.5
       ) ON CONFLICT (driver_id) DO UPDATE SET
        is_online = TRUE,
        current_location = ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326)::geography`,
      [driverId]
    );

    // 3. Seed Active In-Transit Order
    await client.query(
      `INSERT INTO orders (
        order_code, customer_id, driver_id, status, cargo_type, weight_kg, package_description,
        pickup_address, pickup_location, pickup_contact_name, pickup_contact_phone,
        dropoff_address, dropoff_location, dropoff_contact_name, dropoff_contact_phone,
        fare_amount, distance_km, estimated_duration_min, payment_status, assigned_at, picked_up_at
       ) VALUES (
        'HMH-89241', $1, $2, 'in_transit', 'Industrial Electronics', 24.5, '2x Reinforced Pelican Flight Cases',
        '750 Brannan St, San Francisco, CA', ST_SetSRID(ST_MakePoint(-122.4022, 37.7758), 4326)::geography, 'Alex Mercer', '+10000000002',
        '201 3rd St, San Francisco, CA', ST_SetSRID(ST_MakePoint(-122.4005, 37.7858), 4326)::geography, 'Tech Logistics Hub', '+10000000099',
        48.50, 4.2, 18, 'pending', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '15 minutes'
       ) ON CONFLICT (order_code) DO NOTHING`,
      [customerId, driverId]
    );

    // 4. Seed Pending Order (waiting in dispatch pool)
    await client.query(
      `INSERT INTO orders (
        order_code, customer_id, driver_id, status, cargo_type, weight_kg, package_description,
        pickup_address, pickup_location, pickup_contact_name, pickup_contact_phone,
        dropoff_address, dropoff_location, dropoff_contact_name, dropoff_contact_phone,
        fare_amount, distance_km, estimated_duration_min, payment_status
       ) VALUES (
        'HMH-31045', $1, NULL, 'pending', 'Medical Supplies', 8.2, 'Temperature-Controlled Insulated Box',
        '100 Potrero Ave, San Francisco, CA', ST_SetSRID(ST_MakePoint(-122.4069, 37.7685), 4326)::geography, 'SF General Clinic', '+10000000088',
        '1700 Owens St, San Francisco, CA', ST_SetSRID(ST_MakePoint(-122.3926, 37.7677), 4326)::geography, 'Mission Bay Research', '+10000000077',
        32.00, 2.8, 12, 'pending'
       ) ON CONFLICT (order_code) DO NOTHING`,
      [customerId]
    );

    await client.query('COMMIT');
    console.log(`
✅ Database successfully seeded!
------------------------------------------------------------
🔑 DEMO ACCOUNTS:
- Owner/Admin: admin@hamha.com    | Password: Admin@123456
- Customer:    customer@hamha.com | Password: Customer@123456
- Driver:      driver@hamha.com   | Password: Driver@123456
------------------------------------------------------------
📦 ACTIVE ORDER: HMH-89241 (In Transit, Driver: Marcus Vance)
📦 PENDING ORDER: HMH-31045 (In Dispatch Pool)
------------------------------------------------------------
    `);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Seeding failed:', error.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seedDatabase();

