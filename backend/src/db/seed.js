const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');

async function seedDatabase() {
  console.log('🌱 Seeding HAMHA Logistics Neon database with verified Indian freight fleets, tariffs, and consignments...');
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const salt = await bcrypt.genSalt(10);
    const adminPass = await bcrypt.hash('Admin@123456', salt);
    const customerPass = await bcrypt.hash('Customer@123456', salt);
    const driverPass = await bcrypt.hash('Driver@123456', salt);

    // 1. Seed Users (Fleet Owner/Admin, Customer, Driver)
    const adminRes = await client.query(
      `INSERT INTO users (name, email, phone, password_hash, role, is_verified, company_name, gstin, govt_id_type, govt_id_number)
       VALUES ('Rajesh Singhania', 'admin@hamha.com', '+919820011223', $1, 'admin', TRUE, 'HAMHA Logistics Pvt Ltd', '27AAAAA0000A1Z5', 'PAN Card', 'AAACH1234F')
       ON CONFLICT (email) DO UPDATE SET password_hash = $1
       RETURNING id`,
      [adminPass]
    );

    const customerRes = await client.query(
      `INSERT INTO users (name, email, phone, password_hash, role, is_verified, company_name, gstin)
       VALUES ('Vikram Malhotra', 'customer@hamha.com', '+919876543210', $1, 'customer', TRUE, 'Apex Industrial Goods', '27AAACA9876Q1Z5')
       ON CONFLICT (email) DO UPDATE SET password_hash = $1
       RETURNING id`,
      [customerPass]
    );

    const driverRes = await client.query(
      `INSERT INTO users (name, email, phone, password_hash, role, is_verified)
       VALUES ('Suresh Kumar Yadav', 'driver@hamha.com', '+919820144556', $1, 'driver', TRUE)
       ON CONFLICT (email) DO UPDATE SET password_hash = $1
       RETURNING id`,
      [driverPass]
    );

    const adminId = adminRes.rows[0].id;
    const customerId = customerRes.rows[0].id;
    const driverId = driverRes.rows[0].id;

    // 2. Seed Driver Vehicles with live PostGIS coordinates (Bhiwandi / Mumbai MMR)
    // Longitude: 73.0544, Latitude: 19.2969
    await client.query(
      `INSERT INTO vehicles (
        owner_id, driver_id, type, tire_config, plate_number, model, color, max_weight_kg, 
        is_online, is_available, current_location, heading, speed_kmh
       ) VALUES (
        $1, $2, 'truck', '6 Tire', 'MH-04-TR-9081', 'Eicher Pro 2049 (6 Tire)', 'Crisp White', 3500.00,
        TRUE, FALSE, ST_SetSRID(ST_MakePoint(73.0544, 19.2969), 4326)::geography, 90.0, 48.0
       ) ON CONFLICT (plate_number) DO UPDATE SET
        is_online = TRUE,
        current_location = ST_SetSRID(ST_MakePoint(73.0544, 19.2969), 4326)::geography`,
      [adminId, driverId]
    );

    // Seed additional fleet vehicle for Owner
    await client.query(
      `INSERT INTO vehicles (
        owner_id, type, tire_config, plate_number, model, color, max_weight_kg, is_online, is_available
       ) VALUES (
        $1, 'van', '4 Tire', 'MH-04-AB-1290', 'Tata Ace Gold Super (4 Tire)', 'Silver Gray', 1200.00, FALSE, TRUE
       ) ON CONFLICT (plate_number) DO NOTHING`,
      [adminId]
    );

    // 3. Seed System Tariffs
    await client.query(
      `INSERT INTO system_tariffs (
        id, base_fee, per_km_rate, vehicle_rates, weight_base_allowance_kg,
        per_kg_rate, heavy_weight_per_kg_rate, minimum_fare, gst_percent, currency, updated_by
       ) VALUES (
        'active_tariffs', 350.00, 25.00,
        '{"bike": 12.0, "mini_van": 22.0, "van": 32.0, "truck": 55.0, "heavy_4tire": 45.0, "heavy_6tire": 65.0, "heavy_8tire": 85.0, "heavy_12tire": 110.0}',
        10.00, 18.00, 12.00, 250.00, 18.00, 'INR', 'HAMHA Fleet Owner'
       ) ON CONFLICT (id) DO NOTHING`
    );

    // 4. Seed Active In-Transit Consignment (Bhiwandi to Whitefield Bengaluru)
    const orderRes = await client.query(
      `INSERT INTO orders (
        order_code, customer_id, driver_id, status, cargo_type, weight_kg, package_description,
        pickup_address, pickup_location, pickup_contact_name, pickup_contact_phone,
        dropoff_address, dropoff_location, dropoff_contact_name, dropoff_contact_phone,
        fare_amount, currency, distance_km, estimated_duration_min, payment_status, assigned_at, picked_up_at
       ) VALUES (
        'HMH-89241', $1, $2, 'in_transit', 'Industrial Electronics & Sensor Kits', 28.5, '2x Reinforced Pelican Flight Cases',
        'Plot 45, Bhiwandi Logistics Park, Thane, Maharashtra', ST_SetSRID(ST_MakePoint(73.0544, 19.2969), 4326)::geography, 'Warehouse Dispatch Officer', '+919820112345',
        'Building B, Unit 302, Whitefield Tech Park, Bengaluru, Karnataka', ST_SetSRID(ST_MakePoint(77.7499, 12.9698), 4326)::geography, 'Receiving Dock Manager', '+919845099881',
        4850.00, 'INR', 984.0, 720, 'paid', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '1 hour'
       ) ON CONFLICT (order_code) DO NOTHING
       RETURNING id`,
      [customerId, driverId]
    );

    // Seed Milestones for In-Transit Consignment
    if (orderRes.rows.length > 0) {
      const orderId = orderRes.rows[0].id;
      await client.query(
        `INSERT INTO transit_checkpoints (order_id, location, district, state, timestamp_label, is_completed, order_index)
         VALUES 
          ($1, 'Bhiwandi Logistics Hub', 'Thane District', 'Maharashtra', 'Departed Hub 08:30 AM', TRUE, 1),
          ($1, 'Pune Bypass Expressway Corridor', 'Pune', 'Maharashtra', 'Passed Toll 11:15 AM', TRUE, 2),
          ($1, 'Kolhapur Freight Checkpost', 'Kolhapur', 'Maharashtra', 'In-Transit GPS Telematics Active', FALSE, 3),
          ($1, 'Whitefield Tech Park Consignee Gate', 'Bengaluru Urban', 'Karnataka', 'Estimated Delivery Today 07:45 PM', FALSE, 4)`,
        [orderId]
      );
    }

    // 5. Seed Customer Dispute
    await client.query(
      `INSERT INTO disputes (
        id, order_code, customer_name, customer_phone, driver_name, driver_phone,
        type, severity, status, customer_rating, customer_complaint, driver_explanation, refund_amount, filed_at
       ) VALUES (
        'DSP-802', 'HMH-44102', 'Fortis Health Net', '+919855566778', 'Sunil Jadhav', '+919820334567',
        'cargo_handling', 'high', 'open', 1,
        'Diagnostic sample container outer box showed compression marks on arrival at Asian Heart Institute.',
        'Package was placed securely in sealed cargo box with bubble wrapping. Seal intact on handover.',
        1150.00, NOW() - INTERVAL '5 hours'
       ) ON CONFLICT (id) DO NOTHING`
    );

    // 6. Seed System Audit Logs
    await client.query(
      `INSERT INTO system_audit_logs (id, admin_user, action_type, target_entity, details, ip_address, security_hash)
       VALUES 
        ('AUD-901', 'admin@hamha.com', 'MANUAL_DISPATCH_OVERRIDE', 'ORDER #HMH-31045', 'Admin manual override executed via Neon PostGIS ST_DWithin 10km radius. Assigned to Amit Patel (MH-04-TR-9081).', '127.0.0.1 (Web Control Tower)', 'SHA256:7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069'),
        ('AUD-902', 'admin@hamha.com', 'DRIVER_KYC_APPROVED', 'DRIVER: Suresh Kumar Yadav', 'Carrier verified. Commercial DL DL-MH04-2022-77881 and RC MH-04-TR-9081 validated.', '127.0.0.1 (Web Control Tower)', 'SHA256:4a8b7921c3d98ef01192e8a1bc883fa091c7810df661e892c90a1bc72e817921')
       ON CONFLICT (id) DO NOTHING`
    );

    await client.query('COMMIT');
    console.log(`
✅ Neon Database successfully seeded!
------------------------------------------------------------
🔑 DEMO & PRODUCTION CREDENTIALS:
- Fleet Owner: admin@hamha.com    | Password: Admin@123456
- Customer:    customer@hamha.com | Password: Customer@123456
- Driver:      driver@hamha.com   | Password: Driver@123456
------------------------------------------------------------
📦 ACTIVE CONSIGNMENT: HMH-89241 (In Transit, Eicher Pro 6T, Driver: Suresh Kumar Yadav)
💰 TARIFFS: Configured in INR (₹) and synchronized with Neon PostgreSQL!
------------------------------------------------------------
    `);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Seeding failed:', error.message);
    process.exit(1);
  } finally {
    client.release();
  }
}

seedDatabase().then(() => pool.end());
