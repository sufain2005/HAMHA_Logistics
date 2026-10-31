const http = require('http');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Server } = require('socket.io');
require('dotenv').config();

const { pool } = require('./config/db');
const { runMigration } = require('./db/migrate');
const { initializeSocketIO } = require('./sockets/socketHandler');
const errorHandler = require('./middleware/errorHandler');

// Route imports
const authRoutes = require('./routes/auth.routes');
const customerRoutes = require('./routes/customer.routes');
const driverRoutes = require('./routes/driver.routes');
const adminRoutes = require('./routes/admin.routes');

const app = express();
const server = http.createServer(app);

// Initialize Socket.io with CORS for Flutter apps (Web, Desktop, Mobile)
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE'],
  },
});

// Attach io instance to express app for access in controllers
app.set('io', io);

// Initialize Socket.io rooms and event handlers
initializeSocketIO(io);

// Security & Parsing Middlewares
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// API Health Check & PostGIS status
app.get('/api/health', async (req, res) => {
  try {
    const dbCheck = await pool.query('SELECT PostGIS_Version() as postgis, NOW() as current_time');
    res.json({
      status: 'online',
      service: 'HAMHA Logistics API Engine',
      environment: process.env.NODE_ENV || 'development',
      postgisVersion: dbCheck.rows[0].postgis,
      serverTime: dbCheck.rows[0].current_time,
    });
  } catch (err) {
    res.status(503).json({
      status: 'degraded',
      service: 'HAMHA Logistics API Engine',
      error: 'Database connection unavailable.',
    });
  }
});

// STRICTLY SEPARATE ROUTE ARCHITECTURE
app.use('/api/auth', authRoutes);
app.use('/api/customer', customerRoutes);
app.use('/api/driver', driverRoutes);
app.use('/api/admin', adminRoutes);

// 404 Route Catch-all
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Resource not found on HAMHA API: [${req.method}] ${req.originalUrl}`,
  });
});

// Centralized Error Handler
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.log(`\n⚡ Notice: Port ${PORT} is already active and serving HAMHA Logistics.`);
    console.log(`👉 Backend is live on http://localhost:${PORT}`);
    process.exit(0);
  } else {
    console.error('❌ Server startup error:', err);
    process.exit(1);
  }
});

server.listen(PORT, async () => {
  console.log(`
=====================================================
  🚚 HAMHA LOGISTICS BACKEND SERVICE
  ⚡ Server running on http://localhost:${PORT}
  📍 Distinct Interfaces:
     - Auth:     /api/auth
     - Customer: /api/customer
     - Driver:   /api/driver
     - Admin:    /api/admin
  🗺️  Socket.io: Live Mapbox Location Rooms Enabled
=====================================================
  `);

  // Auto-validate and synchronize Neon PostgreSQL database schema on startup
  try {
    await runMigration();
    console.log('📦 Neon PostgreSQL Database schema validated and ready.');
  } catch (err) {
    console.warn('⚠️ Non-fatal migration check warning on startup:', err.message);
  }
});

module.exports = { app, server };

