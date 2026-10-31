const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');
const { query } = require('../config/db');

/**
 * Socket.io Real-time Location and Room Dispatch Engine for HAMHA Logistics
 */
function initializeSocketIO(io) {
  // Authentication middleware for socket connections
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || 
                  socket.handshake.headers?.authorization?.replace('Bearer ', '');

    if (!token) {
      // In development, allow connection with guest/query fallback or reject
      return next(new Error('Authentication error: Missing token'));
    }

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      socket.user = decoded; // { id, name, role, email }
      next();
    } catch (err) {
      next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const { id: userId, role, name } = socket.user || {};
    console.log(`🔌 [Socket.io] Connected: ${name || 'User'} (${role}) | Socket ID: ${socket.id}`);

    // Automatic role-based default room joins
    if (role === 'admin') {
      socket.join('admin:fleet');
      console.log(`👑 [Socket.io] Admin joined room: admin:fleet`);
    } else if (role === 'driver') {
      socket.join(`driver:${userId}`);
      socket.join('drivers:available');
      console.log(`🚚 [Socket.io] Driver ${name} joined room: driver:${userId}`);
    } else if (role === 'customer') {
      socket.join(`customer:${userId}`);
    }

    /**
     * Join specific order tracking room (Customer, Driver, or Admin monitoring an order)
     */
    socket.on('order:join', async ({ orderId } = {}) => {
      if (!orderId) return;
      try {
        const result = await query(
          'SELECT id FROM orders WHERE id = $1 AND ($2 = \'admin\' OR customer_id = $3 OR driver_id = $3)',
          [orderId, role, userId]
        );
        if (!result.rows.length) return;
      } catch (_) {
        return;
      }
      const room = `order:${orderId}`;
      socket.join(room);
      console.log(`📍 [Socket.io] ${role} (${userId}) joined room: ${room}`);
      
      socket.emit('order:joined', {
        orderId,
        message: `Successfully connected to real-time feed for order ${orderId}`,
      });
    });

    /**
     * Leave order tracking room
     */
    socket.on('order:leave', ({ orderId } = {}) => {
      if (!orderId) return;
      socket.leave(`order:${orderId}`);
      console.log(`🚪 [Socket.io] User left room: order:${orderId}`);
    });

    /**
     * DRIVER LOCATION BROADCAST
     * Driver continually streams live Mapbox GPS coordinates
     */
    socket.on('driver:location_update', async (payload) => {
      try {
        if (role !== 'driver' || !payload) return;
        const { orderId, lon, lat, heading = 0, speedKmh = 0 } = payload;

        if (![lon, lat, heading, speedKmh].every(value => typeof value === 'number' && Number.isFinite(value)) ||
            lon < -180 || lon > 180 || lat < -90 || lat > 90 || speedKmh < 0) return;
        if (orderId) {
          const result = await query('SELECT id FROM orders WHERE id = $1 AND driver_id = $2', [orderId, userId]);
          if (!result.rows.length) return;
        }

        const updateData = {
          driverId: userId,
          driverName: name,
          orderId: orderId || null,
          lon: parseFloat(lon),
          lat: parseFloat(lat),
          heading: parseFloat(heading),
          speedKmh: parseFloat(speedKmh),
          timestamp: new Date().toISOString(),
        };

        // 1. Broadcast instantaneously to Customer tracking this order
        if (orderId) {
          socket.to(`order:${orderId}`).emit('order:driver_location', updateData);
        }

        // 2. Broadcast to Owner/Admin live fleet overview map
        socket.to('admin:fleet').emit('fleet:driver_location', updateData);

        // 3. Persist live PostGIS coordinates in Neon DB (async without blocking socket pipe)
        query(
          `UPDATE vehicles 
           SET current_location = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
               heading = $3,
               speed_kmh = $4,
               last_location_updated_at = NOW()
           WHERE driver_id = $5`,
          [lon, lat, heading, speedKmh, userId]
        ).catch((err) => console.error('Database location update error:', err.message));

      } catch (err) {
        console.error('Error handling driver:location_update:', err.message);
      }
    });

    /**
     * Driver toggles online/offline via socket
     */
    socket.on('driver:toggle_online', async ({ isOnline } = {}) => {
      try {
        if (role !== 'driver' || typeof isOnline !== 'boolean') return;
        await query(
          `UPDATE vehicles SET is_online = $1, updated_at = NOW() WHERE driver_id = $2`,
          [isOnline, userId]
        );

        if (isOnline) {
          socket.join('drivers:available');
        } else {
          socket.leave('drivers:available');
        }

        // Inform Admin Fleet
        io.to('admin:fleet').emit('fleet:driver_status', {
          driverId: userId,
          driverName: name,
          isOnline,
        });
      } catch (err) {
        console.error('Error handling driver:toggle_online:', err.message);
      }
    });

    socket.on('disconnect', () => {
      console.log(`🔌 [Socket.io] Disconnected: ${name || 'User'} (${socket.id})`);
    });
  });
}

module.exports = { initializeSocketIO };

