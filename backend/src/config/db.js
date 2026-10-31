const { Pool } = require('pg');
require('dotenv').config();

let connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.warn('⚠️ WARNING: DATABASE_URL is not set in environment variables. Set it in .env before executing database queries.');
} else {
  // Automatically eliminate libpq SSL security warning for Neon PostgreSQL connections
  if (connectionString.includes('sslmode=') && !connectionString.includes('uselibpqcompat=')) {
    connectionString += (connectionString.includes('?') ? '&' : '?') + 'uselibpqcompat=true';
  }
}

const pool = new Pool({
  connectionString,
  ssl: process.env.NODE_ENV === 'production' || (connectionString && connectionString.includes('neon.tech'))
    ? { rejectUnauthorized: false }
    : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (err) => {
  console.error('❌ Unexpected database pool error:', err);
});

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};

