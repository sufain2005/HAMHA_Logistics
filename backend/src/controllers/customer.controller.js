const { query } = require('../config/db');

/**
 * Generate randomized HAMHA order tracking code e.g. HMH-74921
 */
const generateOrderCode = () => {
  return `HMH-${Math.floor(10000 + Math.random() * 90000)}`;
};

/**
 * Cost Calculator: Computes estimated fare based on weight, cargo type, and coordinates
 */
exports.calculateQuote = async (req, res, next) => {
  try {
    const {
      weightKg,
      pickupLon,
      pickupLat,
      dropoffLon,
      dropoffLat,
      cargoType = 'Standard Package',
    } = req.body;

    if (!weightKg || !pickupLon || !pickupLat || !dropoffLon || !dropoffLat) {
      return res.status(400).json({
        success: false,
        message: 'Weight (kg) and both pickup/dropoff coordinates (lon, lat) are required.',
      });
    }

    // Use PostGIS ST_Distance to compute accurate great-circle ground distance in kilometers
    const distanceResult = await query(
      `SELECT ST_Distance(
        ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
        ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
      ) / 1000.0 AS distance_km`,
      [pickupLon, pickupLat, dropoffLon, dropoffLat]
    );

    const straightLineKm = parseFloat(distanceResult.rows[0].distance_km) || 1.0;
    // Real-world road distance multiplier (~1.3x straight-line)
    const estimatedDistanceKm = Math.round((straightLineKm * 1.3) * 10) / 10;
    
    // Average urban speed: 35 km/h + 15 min handling buffer
    const estimatedDurationMin = Math.round((estimatedDistanceKm / 35.0) * 60) + 15;

    // Pricing Model:
    // Base fee: $15.00
    // Distance rate: $1.85 / km
    // Weight surcharge: $0.75 / kg above 5kg
    const baseFee = 15.0;
    const distanceFee = estimatedDistanceKm * 1.85;
    const weightFee = Math.max(0, parseFloat(weightKg) - 5) * 0.75;
    const subtotal = baseFee + distanceFee + weightFee;
    const tax = subtotal * 0.08; // 8% sales tax
    const totalFare = Math.round((subtotal + tax) * 100) / 100;

    return res.json({
      success: true,
      quote: {
        cargoType,
        weightKg: parseFloat(weightKg),
        distanceKm: estimatedDistanceKm,
        estimatedDurationMin,
        breakdown: {
          baseFee: baseFee.toFixed(2),
          distanceRate: `$1.85 / km ($${distanceFee.toFixed(2)})`,
          weightSurcharge: `$${weightFee.toFixed(2)}`,
          tax: `$${tax.toFixed(2)}`,
        },
        currency: 'USD',
        totalFare: totalFare.toFixed(2),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Create Shipment (Order)
 */
exports.createOrder = async (req, res, next) => {
  try {
    const customerId = req.user.id;
    const {
      cargoType,
      weightKg,
      packageDescription,
      pickupAddress,
      pickupLon,
      pickupLat,
      pickupContactName,
      pickupContactPhone,
      dropoffAddress,
      dropoffLon,
      dropoffLat,
      dropoffContactName,
      dropoffContactPhone,
    } = req.body;

    if (!cargoType || !weightKg || !pickupAddress || !dropoffAddress || !pickupLon || !pickupLat || !dropoffLon || !dropoffLat) {
      return res.status(400).json({
        success: false,
        message: 'Missing required shipment parameters.',
      });
    }

    // Calculate distance & fare using PostGIS
    const distanceResult = await query(
      `SELECT ST_Distance(
        ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
        ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
      ) / 1000.0 AS distance_km`,
      [pickupLon, pickupLat, dropoffLon, dropoffLat]
    );

    const straightLineKm = parseFloat(distanceResult.rows[0].distance_km) || 1.0;
    const distanceKm = Math.round((straightLineKm * 1.3) * 10) / 10;
    const durationMin = Math.round((distanceKm / 35.0) * 60) + 15;
    const fare = Math.round(((15.0 + (distanceKm * 1.85) + Math.max(0, parseFloat(weightKg) - 5) * 0.75) * 1.08) * 100) / 100;
    const orderCode = generateOrderCode();

    const result = await query(
      `INSERT INTO orders (
        order_code, customer_id, cargo_type, weight_kg, package_description,
        pickup_address, pickup_location, pickup_contact_name, pickup_contact_phone,
        dropoff_address, dropoff_location, dropoff_contact_name, dropoff_contact_phone,
        fare_amount, distance_km, estimated_duration_min, status, payment_status
      ) VALUES (
        $1, $2, $3, $4, $5,
        $6, ST_SetSRID(ST_MakePoint($7, $8), 4326)::geography, $9, $10,
        $11, ST_SetSRID(ST_MakePoint($12, $13), 4326)::geography, $14, $15,
        $16, $17, $18, 'pending', 'pending'
      ) RETURNING id, order_code, status, fare_amount, distance_km, estimated_duration_min, created_at`,
      [
        orderCode, customerId, cargoType, weightKg, packageDescription || '',
        pickupAddress, pickupLon, pickupLat, pickupContactName || req.user.name, pickupContactPhone || req.user.phone,
        dropoffAddress, dropoffLon, dropoffLat, dropoffContactName || '', dropoffContactPhone || '',
        fare, distanceKm, durationMin
      ]
    );

    const newOrder = result.rows[0];

    // Emit event to Admin and available Drivers via Socket.io
    const io = req.app.get('io');
    if (io) {
      io.to('admin:fleet').emit('order:created', {
        orderId: newOrder.id,
        orderCode: newOrder.order_code,
        pickupAddress,
        dropoffAddress,
        fareAmount: fare,
        weightKg,
        createdAt: newOrder.created_at,
      });

      io.to('drivers:available').emit('dispatch:new_order_available', {
        orderId: newOrder.id,
        orderCode: newOrder.order_code,
        pickupAddress,
        dropoffAddress,
        fareAmount: fare,
        distanceKm,
        weightKg,
      });
    }

    return res.status(201).json({
      success: true,
      message: 'Shipment created successfully. Waiting for driver assignment.',
      order: newOrder,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get all orders created by the authenticated customer
 */
exports.getMyOrders = async (req, res, next) => {
  try {
    const customerId = req.user.id;
    const result = await query(
      `SELECT o.id, o.order_code, o.status, o.cargo_type, o.weight_kg,
              o.pickup_address, o.dropoff_address, o.fare_amount, o.distance_km,
              o.payment_status, o.created_at, o.delivered_at,
              u.name as driver_name, u.phone as driver_phone
       FROM orders o
       LEFT JOIN users u ON u.id = o.driver_id
       WHERE o.customer_id = $1
       ORDER BY o.created_at DESC`,
      [customerId]
    );

    return res.json({
      success: true,
      orders: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get single active order tracking details (including PostGIS coords & live driver position)
 */
exports.getOrderTracking = async (req, res, next) => {
  try {
    const customerId = req.user.id;
    const { id } = req.params;

    const result = await query(
      `SELECT 
        o.id, o.order_code, o.status, o.cargo_type, o.weight_kg, o.package_description,
        o.pickup_address,
        ST_X(o.pickup_location::geometry) as pickup_lon,
        ST_Y(o.pickup_location::geometry) as pickup_lat,
        o.dropoff_address,
        ST_X(o.dropoff_location::geometry) as dropoff_lon,
        ST_Y(o.dropoff_location::geometry) as dropoff_lat,
        o.fare_amount, o.distance_km, o.estimated_duration_min,
        o.payment_status, o.created_at, o.assigned_at, o.picked_up_at, o.delivered_at,
        d.id as driver_id, d.name as driver_name, d.phone as driver_phone, d.avatar_url as driver_avatar,
        v.plate_number, v.model as vehicle_model, v.type as vehicle_type,
        ST_X(v.current_location::geometry) as driver_lon,
        ST_Y(v.current_location::geometry) as driver_lat,
        v.heading as driver_heading,
        v.speed_kmh as driver_speed
       FROM orders o
       LEFT JOIN users d ON d.id = o.driver_id
       LEFT JOIN vehicles v ON v.driver_id = d.id
       WHERE o.id = $1 AND o.customer_id = $2`,
      [id, customerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Order not found.' });
    }

    return res.json({
      success: true,
      order: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Invoice details for post-order screen
 */
exports.getOrderInvoice = async (req, res, next) => {
  try {
    const customerId = req.user.id;
    const { id } = req.params;

    const result = await query(
      `SELECT 
        o.id, o.order_code, o.status, o.cargo_type, o.weight_kg,
        o.pickup_address, o.dropoff_address, o.fare_amount, o.distance_km,
        o.payment_status, o.payment_method, o.created_at, o.delivered_at,
        c.name as customer_name, c.email as customer_email, c.phone as customer_phone,
        d.name as driver_name, v.plate_number
       FROM orders o
       JOIN users c ON c.id = o.customer_id
       LEFT JOIN users d ON d.id = o.driver_id
       LEFT JOIN vehicles v ON v.driver_id = d.id
       WHERE o.id = $1 AND o.customer_id = $2`,
      [id, customerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Invoice not found.' });
    }

    const order = result.rows[0];
    const subtotal = Math.round((parseFloat(order.fare_amount) / 1.08) * 100) / 100;
    const tax = Math.round((parseFloat(order.fare_amount) - subtotal) * 100) / 100;

    return res.json({
      success: true,
      invoice: {
        invoiceNumber: `INV-${order.order_code}`,
        issuedAt: order.delivered_at || order.created_at,
        customer: {
          name: order.customer_name,
          email: order.customer_email,
          phone: order.customer_phone,
        },
        shipment: {
          orderCode: order.order_code,
          cargoType: order.cargo_type,
          weightKg: order.weight_kg,
          pickupAddress: order.pickup_address,
          dropoffAddress: order.dropoff_address,
          distanceKm: order.distance_km,
          driverName: order.driver_name || 'Assigned Driver',
          vehiclePlate: order.plate_number || 'N/A',
        },
        billing: {
          subtotal: subtotal.toFixed(2),
          tax: tax.toFixed(2),
          total: parseFloat(order.fare_amount).toFixed(2),
          paymentStatus: order.payment_status,
          paymentMethod: order.payment_method,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

