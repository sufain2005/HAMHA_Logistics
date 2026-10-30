const { query } = require('../config/db');

/**
 * Live Fleet Overview: Returns all drivers with real-time PostGIS coordinates and current activity
 */
exports.getLiveFleet = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT 
        u.id as driver_id,
        u.name as driver_name,
        u.phone as driver_phone,
        u.email as driver_email,
        v.id as vehicle_id,
        v.type as vehicle_type,
        v.plate_number,
        v.model as vehicle_model,
        v.is_online,
        v.is_available,
        ST_X(v.current_location::geometry) as current_lon,
        ST_Y(v.current_location::geometry) as current_lat,
        v.heading,
        v.speed_kmh,
        v.last_location_updated_at,
        o.id as current_order_id,
        o.order_code as current_order_code,
        o.status as order_status
       FROM users u
       JOIN vehicles v ON v.driver_id = u.id
       LEFT JOIN orders o ON o.driver_id = u.id AND o.status IN ('assigned', 'picked_up', 'in_transit')
       WHERE u.role = 'driver'
       ORDER BY v.is_online DESC, u.name ASC`
    );

    return res.json({
      success: true,
      fleetCount: result.rows.length,
      onlineCount: result.rows.filter(d => d.is_online).length,
      busyCount: result.rows.filter(d => !d.is_available).length,
      drivers: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Dispatch Management: List all shipments with filtering (status, search)
 */
exports.getAllOrders = async (req, res, next) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;

    let queryText = `
      SELECT 
        o.id, o.order_code, o.status, o.cargo_type, o.weight_kg,
        o.pickup_address,
        ST_X(o.pickup_location::geometry) as pickup_lon,
        ST_Y(o.pickup_location::geometry) as pickup_lat,
        o.dropoff_address,
        ST_X(o.dropoff_location::geometry) as dropoff_lon,
        ST_Y(o.dropoff_location::geometry) as dropoff_lat,
        o.fare_amount, o.distance_km, o.payment_status,
        o.created_at, o.assigned_at, o.delivered_at,
        c.id as customer_id, c.name as customer_name, c.phone as customer_phone,
        d.id as driver_id, d.name as driver_name, d.phone as driver_phone,
        v.plate_number
      FROM orders o
      JOIN users c ON c.id = o.customer_id
      LEFT JOIN users d ON d.id = o.driver_id
      LEFT JOIN vehicles v ON v.driver_id = d.id
    `;

    const params = [];
    if (status) {
      params.push(status);
      queryText += ` WHERE o.status = $${params.length}`;
    }

    queryText += ` ORDER BY o.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await query(queryText, params);

    return res.json({
      success: true,
      count: result.rows.length,
      orders: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Manual Dispatch / Assign driver to an order
 */
exports.manualDispatch = async (req, res, next) => {
  try {
    const { orderId, driverId } = req.body;

    if (!orderId || !driverId) {
      return res.status(400).json({ success: false, message: 'orderId and driverId are required.' });
    }

    const client = await (require('../config/db').pool).connect();
    try {
      await client.query('BEGIN');

      const orderCheck = await client.query('SELECT id, status, order_code FROM orders WHERE id = $1 FOR UPDATE', [orderId]);
      if (orderCheck.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ success: false, message: 'Order not found.' });
      }

      const driverCheck = await client.query('SELECT id, name FROM users WHERE id = $1 AND role = \'driver\'', [driverId]);
      if (driverCheck.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ success: false, message: 'Driver not found.' });
      }

      await client.query(
        `UPDATE orders 
         SET driver_id = $1, status = 'assigned', assigned_at = NOW(), updated_at = NOW() 
         WHERE id = $2`,
        [driverId, orderId]
      );

      await client.query('UPDATE vehicles SET is_available = FALSE WHERE driver_id = $1', [driverId]);

      await client.query('COMMIT');

      // Notify through Socket.io
      const io = req.app.get('io');
      if (io) {
        io.to(`driver:${driverId}`).emit('dispatch:assigned', {
          orderId,
          orderCode: orderCheck.rows[0].order_code,
        });

        io.to(`order:${orderId}`).emit('order:assigned', {
          orderId,
          driverId,
          driverName: driverCheck.rows[0].name,
        });

        io.to('admin:fleet').emit('order:updated', {
          orderId,
          status: 'assigned',
          driverId,
        });
      }

      return res.json({
        success: true,
        message: `Order assigned to ${driverCheck.rows[0].name}.`,
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
 * Admin Executive Stats
 */
exports.getAnalytics = async (req, res, next) => {
  try {
    const metrics = await query(`
      SELECT 
        (SELECT COUNT(*) FROM orders WHERE status = 'pending') AS pending_shipments,
        (SELECT COUNT(*) FROM orders WHERE status IN ('assigned', 'picked_up', 'in_transit')) AS active_shipments,
        (SELECT COUNT(*) FROM orders WHERE status = 'delivered' AND DATE(delivered_at) = CURRENT_DATE) AS delivered_today,
        (SELECT COALESCE(SUM(fare_amount), 0) FROM orders WHERE payment_status = 'paid' AND DATE(created_at) = CURRENT_DATE) AS revenue_today,
        (SELECT COUNT(*) FROM vehicles WHERE is_online = TRUE) AS online_drivers,
        (SELECT COUNT(*) FROM users WHERE role = 'driver') AS total_drivers,
        (SELECT COUNT(*) FROM users WHERE role = 'customer') AS total_customers
    `);

    return res.json({
      success: true,
      analytics: metrics.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

