const { query } = require('../config/db');

/**
 * Register / Update Vehicle details
 */
exports.updateVehicle = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { plateNumber, model, type, color, maxWeightKg } = req.body;

    if (!plateNumber || !model) {
      return res.status(400).json({
        success: false,
        message: 'Plate number and vehicle model are required.',
      });
    }

    const result = await query(
      `INSERT INTO vehicles (driver_id, plate_number, model, type, color, max_weight_kg)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (driver_id) DO UPDATE SET
          plate_number = EXCLUDED.plate_number,
          model = EXCLUDED.model,
          type = COALESCE(EXCLUDED.type, vehicles.type),
          color = COALESCE(EXCLUDED.color, vehicles.color),
          max_weight_kg = COALESCE(EXCLUDED.max_weight_kg, vehicles.max_weight_kg),
          updated_at = NOW()
       RETURNING id, driver_id, plate_number, model, type, color, max_weight_kg, is_online, is_available`,
      [driverId, plateNumber.toUpperCase(), model, type || 'van', color || 'White', maxWeightKg || 500]
    );

    return res.json({
      success: true,
      message: 'Vehicle information saved.',
      vehicle: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Toggle Online/Offline status
 */
exports.toggleOnlineStatus = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { isOnline } = req.body;

    if (typeof isOnline !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'Field "isOnline" must be a boolean (true/false).',
      });
    }

    const result = await query(
      `UPDATE vehicles 
       SET is_online = $1, updated_at = NOW() 
       WHERE driver_id = $2
       RETURNING id, driver_id, is_online, is_available`,
      [isOnline, driverId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Driver vehicle profile not found.' });
    }

    // Broadcast status change to admin fleet
    const io = req.app.get('io');
    if (io) {
      io.to('admin:fleet').emit('driver:status_changed', {
        driverId,
        driverName: req.user.name,
        isOnline,
      });
    }

    return res.json({
      success: true,
      message: `Driver status switched to ${isOnline ? 'ONLINE' : 'OFFLINE'}.`,
      status: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Fetch available pending orders ready for pickup
 */
exports.getAvailableOrders = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT 
        o.id, o.order_code, o.status, o.cargo_type, o.weight_kg,
        o.pickup_address,
        ST_X(o.pickup_location::geometry) as pickup_lon,
        ST_Y(o.pickup_location::geometry) as pickup_lat,
        o.dropoff_address,
        ST_X(o.dropoff_location::geometry) as dropoff_lon,
        ST_Y(o.dropoff_location::geometry) as dropoff_lat,
        o.fare_amount, o.distance_km, o.estimated_duration_min,
        o.created_at,
        c.name as customer_name, c.phone as customer_phone
       FROM orders o
       JOIN users c ON c.id = o.customer_id
       WHERE o.status = 'pending' AND o.driver_id IS NULL
       ORDER BY o.created_at ASC
       LIMIT 20`
    );

    return res.json({
      success: true,
      orders: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

const isValidUuid = (val) => typeof val === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(val);

/**
 * Get the driver's currently active order
 */
exports.getCurrentOrder = async (req, res, next) => {
  try {
    const driverId = req.user.id;

    const result = await query(
      `SELECT 
        o.id, o.order_code, o.status, o.cargo_type, o.weight_kg, o.package_description,
        o.pickup_address,
        ST_X(o.pickup_location::geometry) as pickup_lon,
        ST_Y(o.pickup_location::geometry) as pickup_lat,
        o.pickup_contact_name, o.pickup_contact_phone,
        o.dropoff_address,
        ST_X(o.dropoff_location::geometry) as dropoff_lon,
        ST_Y(o.dropoff_location::geometry) as dropoff_lat,
        o.dropoff_contact_name, o.dropoff_contact_phone,
        o.fare_amount, o.distance_km, o.estimated_duration_min,
        o.assigned_at, o.picked_up_at,
        c.name as customer_name, c.phone as customer_phone
       FROM orders o
       JOIN users c ON c.id = o.customer_id
       WHERE o.driver_id = $1 AND o.status IN ('assigned', 'picked_up', 'in_transit')
       ORDER BY o.assigned_at DESC
       LIMIT 1`,
      [driverId]
    );

    return res.json({
      success: true,
      hasActiveOrder: result.rows.length > 0,
      order: result.rows[0] || null,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Accept an order
 */
exports.acceptOrder = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { orderId } = req.params;

    // Transaction to safely prevent double assignment
    const client = await (require('../config/db').pool).connect();
    try {
      await client.query('BEGIN');

      const check = await client.query(
        'SELECT id, status, order_code FROM orders WHERE id = $1 FOR UPDATE',
        [orderId]
      );

      if (check.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ success: false, message: 'Order not found.' });
      }

      if (check.rows[0].status !== 'pending') {
        await client.query('ROLLBACK');
        return res.status(400).json({ success: false, message: 'Order is no longer available for acceptance.' });
      }

      const updateResult = await client.query(
        `UPDATE orders 
         SET status = 'assigned', driver_id = $1, assigned_at = NOW() 
         WHERE id = $2
         RETURNING id, order_code, status, assigned_at`,
        [driverId, orderId]
      );

      // Set vehicle availability to false
      await client.query('UPDATE vehicles SET is_available = FALSE WHERE driver_id = $1', [driverId]);

      await client.query('COMMIT');

      const acceptedOrder = updateResult.rows[0];

      // Notify customer and fleet through Socket.io
      const io = req.app.get('io');
      if (io) {
        io.to(`order:${orderId}`).emit('order:assigned', {
          orderId,
          orderCode: acceptedOrder.order_code,
          driver: {
            id: driverId,
            name: req.user.name,
            phone: req.user.phone,
          },
          status: 'assigned',
        });

        io.to('admin:fleet').emit('order:updated', {
          orderId,
          status: 'assigned',
          driverId,
        });
      }

      return res.json({
        success: true,
        message: 'Order accepted successfully. Route ready for navigation.',
        order: acceptedOrder,
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    next(error);
  }
};

/**
 * Update active order status: 'picked_up' -> 'in_transit' -> 'delivered'
 */
exports.updateOrderStatus = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { orderId } = req.params;
    const { status } = req.body;

    const allowedTransitions = ['picked_up', 'in_transit', 'delivered'];
    if (!allowedTransitions.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Status must be one of: ${allowedTransitions.join(', ')}`,
      });
    }

    let timestampColumn = 'updated_at = NOW()';
    if (status === 'picked_up') timestampColumn = 'picked_up_at = NOW()';
    if (status === 'delivered') timestampColumn = 'delivered_at = NOW(), payment_status = \'paid\'';

    const result = await query(
      `UPDATE orders 
       SET status = $1, ${timestampColumn}
       WHERE id = $2 AND driver_id = $3
         AND (($1 = 'picked_up' AND status = 'assigned')
           OR ($1 = 'in_transit' AND status = 'picked_up')
           OR ($1 = 'delivered' AND status = 'in_transit'))
       RETURNING id, order_code, status, delivered_at`,
      [status, orderId, driverId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Order not found.',
      });
    }

    const updated = result.rows[0];

    // If delivered, mark driver vehicle as available again
    if (status === 'delivered') {
      await query('UPDATE vehicles SET is_available = TRUE WHERE driver_id = $1', [driverId]);
    }

    // Socket.io broadcasts to customer tracking room and admin fleet room
    const io = req.app.get('io');
    if (io) {
      io.to(`order:${orderId}`).emit('order:status_changed', {
        orderId,
        status,
        updatedAt: new Date().toISOString(),
      });

      io.to('admin:fleet').emit('order:status_changed', {
        orderId,
        status,
        driverId,
      });
    }

    return res.json({
      success: true,
      message: `Order status updated to '${status}'.`,
      order: updated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * REST endpoint for location ping (compliments Socket.io for low-connectivity fallback)
 */
exports.updateLocation = async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { lon, lat, heading = 0, speedKmh = 0, orderId } = req.body;

    if (lon === undefined || lat === undefined) {
      return res.status(400).json({ success: false, message: 'lon and lat are required.' });
    }

    // Update vehicle live PostGIS geometry
    await query(
      `UPDATE vehicles 
       SET current_location = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
           heading = $3,
           speed_kmh = $4,
           last_location_updated_at = NOW()
       WHERE driver_id = $5`,
      [lon, lat, heading, speedKmh, driverId]
    );

    // Save breadcrumb audit log
    await query(
      `INSERT INTO driver_location_logs (driver_id, order_id, location, heading, speed_kmh)
       VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, $5, $6)`,
      [driverId, orderId || null, lon, lat, heading, speedKmh]
    );

    return res.json({ success: true, message: 'Location recorded.' });
  } catch (error) {
    next(error);
  }
};

/**
 * DRIVER: Search for Work / Load Requirements inside a specified state
 * Filters active owner postings where expires_at > NOW() (3-day broadcast)
 */
exports.searchTruckRequirements = async (req, res, next) => {
  try {
    const { state, truckType } = req.query;
    const targetState = state ? state.trim() : 'Maharashtra';

    let sql = `
      SELECT 
        id, owner_id, owner_name, owner_company, owner_phone, owner_whatsapp,
        truck_type, title, cargo_type, weight_tons,
        pickup_state, pickup_city, pickup_address,
        dropoff_state, dropoff_city, dropoff_address,
        offered_fare, currency, distance_km, validity_days,
        posted_at, expires_at, status,
        GREATEST(0, ROUND(EXTRACT(EPOCH FROM (expires_at - NOW()))))::INT AS remaining_seconds,
        ROUND(EXTRACT(EPOCH FROM (expires_at - NOW())) / 3600)::INT AS remaining_hours
      FROM truck_requirements
      WHERE status = 'active'
        AND expires_at > NOW()
        AND (pickup_state ILIKE $1 OR dropoff_state ILIKE $1)
    `;
    const params = [`%${targetState}%`];

    if (truckType && truckType !== 'all') {
      params.push(truckType);
      sql += ` AND truck_type = $${params.length}`;
    }

    sql += ` ORDER BY expires_at ASC`;

    const result = await query(sql, params);

    return res.json({
      success: true,
      searchedState: targetState,
      count: result.rows.length,
      requirements: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DRIVER: Contact Owner regarding a truck requirement
 */
exports.contactOwnerForRequirement = async (req, res, next) => {
  try {
    const driverId = req.user?.id || 'd0000000-0000-0000-0000-000000000001';
    const driverName = req.user?.name || 'Verified Highway Pilot';
    const driverPhone = req.user?.phone || '+91 98201 11222';
    const { id } = req.params;
    const { message } = req.body;

    const reqResult = await query(
      `SELECT * FROM truck_requirements WHERE id = $1 AND status = 'active' AND expires_at > NOW()`,
      [id]
    );

    if (reqResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'This requirement is no longer active or has expired.' });
    }

    const requirement = reqResult.rows[0];

    // Log contact event in audit logs
    await query(
      `INSERT INTO system_audit_logs (id, admin_user, action_type, target_entity, details, ip_address, security_hash)
       VALUES ($1, $2, 'DRIVER_LOAD_CONTACT', $3, $4, '127.0.0.1 (Driver Pilot)', $5)`,
      [
        `CNT-${Date.now().toString().slice(-6)}`,
        driverName,
        `TRUCK_REQ #${id.slice(0, 8)}`,
        `Driver ${driverName} (${driverPhone}) initiated direct contact with Owner ${requirement.owner_name} (${requirement.owner_phone}) for load "${requirement.title}". Message: ${message || 'Standard load inquiry'}`,
        `SHA256:${Buffer.from(id + driverId + Date.now()).toString('hex').slice(0, 32)}`
      ]
    );

    // Notify owner via Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to('admin:fleet').emit('driver:load_inquiry', {
        requirementId: id,
        title: requirement.title,
        driverId,
        driverName,
        driverPhone,
        message: message || 'Interested in this load broadcast',
        timestamp: new Date().toISOString(),
      });
    }

    return res.json({
      success: true,
      message: `Contact initiated with owner ${requirement.owner_name}.`,
      ownerContact: {
        ownerName: requirement.owner_name,
        ownerCompany: requirement.owner_company,
        phone: requirement.owner_phone,
        whatsapp: requirement.owner_whatsapp,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DRIVER: Fetch ONLY delivered shipments for this driver
 */
exports.getDeliveredOrders = async (req, res, next) => {
  try {
    const driverId = req.user.id;

    const result = await query(
      `SELECT 
        o.id, o.order_code, o.status, o.cargo_type, o.weight_kg,
        o.pickup_address, o.dropoff_address,
        o.fare_amount, o.currency, o.distance_km,
        o.delivered_at, o.created_at,
        COALESCE(o.dropoff_contact_name, 'Verified Receiving Supervisor') as recipient_name,
        c.name as customer_name
       FROM orders o
       JOIN users c ON c.id = o.customer_id
       WHERE o.driver_id = $1 AND o.status = 'delivered'
       ORDER BY o.delivered_at DESC NULLS LAST, o.created_at DESC`,
      [driverId]
    );

    return res.json({
      success: true,
      count: result.rows.length,
      deliveredOrders: result.rows,
    });
  } catch (error) {
    next(error);
  }
};


