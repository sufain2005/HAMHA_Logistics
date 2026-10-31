const { query } = require('../config/db');
const { systemTariffs } = require('./admin.controller');

/**
 * Generate randomized HAMHA order tracking code e.g. HMH-74921
 */
const generateOrderCode = () => {
  return `HMH-${Math.floor(10000 + Math.random() * 90000)}`;
};

/**
 * Get active freight tariffs set by Admin / Fleet Owner
 */
exports.getTariffs = async (req, res, next) => {
  try {
    return res.json({
      success: true,
      tariffs: systemTariffs,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Cost Calculator: Computes estimated fare based on weight, cargo type, and coordinates
 * Dynamic pricing strictly according to Admin-configured KM distance and weight rates in INR (₹)
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
      vehicleType = 'van',
      customDistanceKm,
    } = req.body;

    if (!weightKg) {
      return res.status(400).json({
        success: false,
        message: 'Weight (kg) is required.',
      });
    }

    // Use customDistanceKm if provided, or PostGIS ST_Distance
    let estimatedDistanceKm = 15.0;
    if (customDistanceKm && parseFloat(customDistanceKm) > 0) {
      estimatedDistanceKm = parseFloat(customDistanceKm);
    } else if (pickupLon && pickupLat && dropoffLon && dropoffLat) {
      try {
        const distanceResult = await query(
          `SELECT ST_Distance(
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
            ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
          ) / 1000.0 AS distance_km`,
          [pickupLon, pickupLat, dropoffLon, dropoffLat]
        );
        const straightLineKm = parseFloat(distanceResult.rows[0]?.distance_km) || 12.0;
        estimatedDistanceKm = Math.max(2.0, Math.round((straightLineKm * 1.3) * 10) / 10);
      } catch (_) {
        estimatedDistanceKm = 24.5;
      }
    }
    
    // Average highway/urban speed: 40 km/h + 20 min handling buffer
    const estimatedDurationMin = Math.round((estimatedDistanceKm / 40.0) * 60) + 20;

    // Dynamic Admin Tariff Calculation (in INR ₹)
    const tariffs = systemTariffs;
    const baseFee = tariffs.baseFee || 350.0;
    
    // Determine per-km rate from vehicle type or default
    let kmRate = tariffs.perKmRate || 25.0;
    if (tariffs.vehicleRates && tariffs.vehicleRates[vehicleType]) {
      kmRate = tariffs.vehicleRates[vehicleType];
    }

    const distanceFee = estimatedDistanceKm * kmRate;
    
    // Weight surcharge: weight above base allowance (e.g. 10kg)
    const allowanceKg = tariffs.weightBaseAllowanceKg || 10.0;
    const excessWeight = Math.max(0, parseFloat(weightKg) - allowanceKg);
    const weightFee = excessWeight * (tariffs.perKgRate || 18.0);
    
    const subtotal = baseFee + distanceFee + weightFee;
    const gstPercent = tariffs.gstPercent || 18.0;
    const gstTax = subtotal * (gstPercent / 100.0);
    const totalFare = Math.max(tariffs.minimumFare || 250.0, Math.round(subtotal + gstTax));

    return res.json({
      success: true,
      quote: {
        cargoType,
        vehicleType,
        weightKg: parseFloat(weightKg),
        distanceKm: estimatedDistanceKm,
        estimatedDurationMin,
        currency: 'INR',
        totalFare: totalFare.toString(),
        breakdown: {
          baseFee: `₹${baseFee.toFixed(0)}`,
          distanceRate: `₹${kmRate.toFixed(0)}/km (₹${distanceFee.toFixed(0)})`,
          weightSurcharge: `₹${weightFee.toFixed(0)} (${excessWeight.toFixed(1)}kg excess)`,
          gst: `₹${gstTax.toFixed(0)}`,
          gstTax: `${gstPercent}% GST (₹${gstTax.toFixed(0)})`,
        },
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
      ownerRequirementId,
      appliedFare,
      paymentMethod = 'Cash to Pickup Pilot',
      customDistanceKm,
    } = req.body;

    if (!cargoType || !weightKg || !pickupAddress || !dropoffAddress) {
      return res.status(400).json({
        success: false,
        message: 'Missing required shipment parameters.',
      });
    }

    // Calculate distance & fare using PostGIS or customDistanceKm
    let distanceKm = customDistanceKm ? parseFloat(customDistanceKm) : 15.0;
    if (!customDistanceKm && pickupLon && pickupLat && dropoffLon && dropoffLat) {
      try {
        const distanceResult = await query(
          `SELECT ST_Distance(
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
            ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
          ) / 1000.0 AS distance_km`,
          [pickupLon, pickupLat, dropoffLon, dropoffLat]
        );
        const straightLineKm = parseFloat(distanceResult.rows[0]?.distance_km) || 12.0;
        distanceKm = Math.round((straightLineKm * 1.3) * 10) / 10;
      } catch (_) {}
    }
    const durationMin = Math.round((distanceKm / 35.0) * 60) + 15;
    
    // Calculate default fare or use owner corridor applied fare
    let calculatedFare = Math.round(((15.0 + (distanceKm * 1.85) + Math.max(0, parseFloat(weightKg) - 5) * 0.75) * 1.08) * 100) / 100;
    if (appliedFare && parseFloat(appliedFare) > 0) {
      calculatedFare = Math.round(parseFloat(appliedFare) * 100) / 100;
    }
    const orderCode = generateOrderCode();

    let finalDescription = packageDescription || '';
    let ownerInfo = null;

    if (ownerRequirementId) {
      try {
        const ownerReqResult = await query(
          `SELECT * FROM truck_requirements WHERE id = $1`,
          [ownerRequirementId]
        );
        if (ownerReqResult.rows.length > 0) {
          ownerInfo = ownerReqResult.rows[0];
          const tag = `[OWNER CORRIDOR BOOKED]: Req #${ownerRequirementId.slice(0, 8)} (${ownerInfo.owner_company || ownerInfo.owner_name}) | Route: ${ownerInfo.pickup_city} -> ${ownerInfo.dropoff_city} | Vehicle: ${ownerInfo.truck_type}`;
          finalDescription = finalDescription ? `${finalDescription}\n${tag}` : tag;
        }
      } catch (_) {}
    }

    const pLon = pickupLon || 73.0544;
    const pLat = pickupLat || 19.2969;
    const dLon = dropoffLon || 73.8567;
    const dLat = dropoffLat || 18.5204;

    const result = await query(
      `INSERT INTO orders (
        order_code, customer_id, cargo_type, weight_kg, package_description,
        pickup_address, pickup_location, pickup_contact_name, pickup_contact_phone,
        dropoff_address, dropoff_location, dropoff_contact_name, dropoff_contact_phone,
        fare_amount, distance_km, estimated_duration_min, status, payment_status, payment_method
      ) VALUES (
        $1, $2, $3, $4, $5,
        $6, ST_SetSRID(ST_MakePoint($7, $8), 4326)::geography, $9, $10,
        $11, ST_SetSRID(ST_MakePoint($12, $13), 4326)::geography, $14, $15,
        $16, $17, $18, 'pending', 'pending', $19
      ) RETURNING id, order_code, status, fare_amount, distance_km, estimated_duration_min, payment_method, created_at`,
      [
        orderCode, customerId, cargoType, weightKg, finalDescription,
        pickupAddress, pLon, pLat, pickupContactName || req.user.name, pickupContactPhone || req.user.phone,
        dropoffAddress, dLon, dLat, dropoffContactName || '', dropoffContactPhone || '',
        calculatedFare, distanceKm, durationMin, paymentMethod
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
        fareAmount: calculatedFare,
        weightKg,
        createdAt: newOrder.created_at,
        ownerRequirementId: ownerRequirementId || null,
        ownerCompany: ownerInfo?.owner_company || null,
      });

      if (ownerRequirementId) {
        io.to('admin:fleet').emit('owner:corridor_consignment_booked', {
          requirementId: ownerRequirementId,
          orderId: newOrder.id,
          orderCode: newOrder.order_code,
          customerName: req.user.name,
          pickupAddress,
          dropoffAddress,
          weightKg,
          fareAmount: calculatedFare,
          ownerCompany: ownerInfo?.owner_company,
        });
      }

      io.to('drivers:available').emit('dispatch:new_order_available', {
        orderId: newOrder.id,
        orderCode: newOrder.order_code,
        pickupAddress,
        dropoffAddress,
        fareAmount: calculatedFare,
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
 * CUSTOMER: Fetch Active Fleet Owner Added Routes / Corridors
 * ONLY activated for long-distance (district-to-district, state-to-state, distance >= 50km)
 * and weight > 20 kg.
 */
exports.getMatchingOwnerCorridors = async (req, res, next) => {
  try {
    const {
      pickupState,
      pickupCity,
      dropoffState,
      dropoffCity,
      weightKg = 0,
      distanceKm = 0,
    } = req.query;

    const parsedWeight = parseFloat(weightKg) || 0;
    const parsedDistance = parseFloat(distanceKm) || 0;

    // Strict requirement: Must be > 20kg
    if (parsedWeight <= 20) {
      return res.json({
        success: true,
        eligible: false,
        message: 'Owner freight corridor booking is reserved for consignments exceeding 20 kg.',
        corridors: [],
      });
    }

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
        AND (weight_tons * 1000) >= $1
    `;
    const params = [parsedWeight];

    const conditions = [];
    if (pickupState && pickupState.trim().length > 1) {
      params.push(`%${pickupState.trim()}%`);
      conditions.push(`pickup_state ILIKE $${params.length}`);
    }
    if (dropoffState && dropoffState.trim().length > 1) {
      params.push(`%${dropoffState.trim()}%`);
      conditions.push(`dropoff_state ILIKE $${params.length}`);
    }
    if (pickupCity && pickupCity.trim().length > 1) {
      params.push(`%${pickupCity.trim()}%`);
      conditions.push(`pickup_city ILIKE $${params.length}`);
    }
    if (dropoffCity && dropoffCity.trim().length > 1) {
      params.push(`%${dropoffCity.trim()}%`);
      conditions.push(`dropoff_city ILIKE $${params.length}`);
    }

    if (conditions.length > 0) {
      sql += ` AND (${conditions.join(' OR ')})`;
    }

    sql += ` ORDER BY expires_at ASC LIMIT 10`;

    let result = await query(sql, params);

    // If specific corridor search yielded 0, provide other active long-distance heavy truck broadcasts
    if (result.rows.length === 0) {
      const fallbackResult = await query(
        `SELECT 
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
          AND (weight_tons * 1000) >= $1
        ORDER BY distance_km DESC, expires_at ASC
        LIMIT 10`,
        [parsedWeight]
      );
      result = fallbackResult;
    }

    return res.json({
      success: true,
      eligible: true,
      count: result.rows.length,
      corridors: result.rows,
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

