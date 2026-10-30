const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { JWT_SECRET } = require('../middleware/auth');

const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * Helper to generate signed JWT token
 */
const generateToken = (user) => {
  return jwt.sign(
    {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
};

/**
 * Register a new user (Customer or Driver)
 */
exports.register = async (req, res, next) => {
  try {
    const { name, email, phone, password, role } = req.body;

    if (!name || !email || !phone || !password) {
      return res.status(400).json({ success: false, message: 'All fields (name, email, phone, password) are required.' });
    }

    const assignedRole = role && ['customer', 'driver'].includes(role.toLowerCase()) ? role.toLowerCase() : 'customer';

    // Check existing
    const existing = await query('SELECT id FROM users WHERE email = $1 OR phone = $2', [email.toLowerCase(), phone]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'A user with this email or phone number already exists.' });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const result = await query(
      `INSERT INTO users (name, email, phone, password_hash, role, is_verified) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       RETURNING id, name, email, phone, role, is_verified, created_at`,
      [name, email.toLowerCase(), phone, passwordHash, assignedRole, false]
    );

    const newUser = result.rows[0];

    // If registered as driver, create vehicle placeholder entry
    if (assignedRole === 'driver') {
      await query(
        `INSERT INTO vehicles (driver_id, plate_number, model) 
         VALUES ($1, $2, $3) ON CONFLICT (driver_id) DO NOTHING`,
        [newUser.id, `TEMP-${Math.floor(1000 + Math.random() * 9000)}`, 'Default Van']
      );
    }

    const token = generateToken(newUser);

    return res.status(201).json({
      success: true,
      message: `${assignedRole.toUpperCase()} registered successfully.`,
      user: newUser,
      token,
      // For immediate dev testing: Simulated OTP
      otpVerification: {
        required: true,
        mockCode: '889900',
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Login with role validation
 */
exports.login = async (req, res, next) => {
  try {
    const { email, password, expectedRole } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required.' });
    }

    const result = await query(
      'SELECT id, name, email, phone, password_hash, role, is_verified FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const user = result.rows[0];

    // Check role restriction if an expected role was specified (ensures customer can't log in to driver app)
    if (expectedRole && user.role !== expectedRole.toLowerCase()) {
      return res.status(403).json({
        success: false,
        message: `Account is registered as '${user.role}'. Access denied for '${expectedRole}' portal.`,
      });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const token = generateToken(user);

    delete user.password_hash;

    return res.json({
      success: true,
      message: 'Authentication successful.',
      user,
      token,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Verify OTP (Customer onboarding/verification)
 */
exports.verifyOtp = async (req, res, next) => {
  try {
    const { phone, otpCode } = req.body;

    if (!phone || !otpCode) {
      return res.status(400).json({ success: false, message: 'Phone and OTP code are required.' });
    }

    // Standard demo OTP validation (in production, integrate Twilio/MessageBird)
    if (otpCode !== '889900' && otpCode !== '123456') {
      return res.status(400).json({ success: false, message: 'Invalid verification code.' });
    }

    await query('UPDATE users SET is_verified = TRUE WHERE phone = $1', [phone]);

    return res.json({
      success: true,
      message: 'Phone number verified successfully.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Fetch Current Authenticated Profile
 */
exports.getMe = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT u.id, u.name, u.email, u.phone, u.role, u.is_verified, u.created_at,
              v.type as vehicle_type, v.plate_number, v.model, v.is_online, v.is_available,
              ST_X(v.current_location::geometry) as current_lon,
              ST_Y(v.current_location::geometry) as current_lat
       FROM users u
       LEFT JOIN vehicles v ON v.driver_id = u.id
       WHERE u.id = $1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    return res.json({
      success: true,
      user: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

