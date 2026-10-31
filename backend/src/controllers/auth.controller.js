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
 * Register a new Fleet Owner with multiple vehicles, GST, and Government ID
 */
exports.registerOwner = async (req, res, next) => {
  try {
    const {
      fullName,
      email,
      phone,
      password,
      govtIdType,
      govtIdNumber,
      companyName,
      gstNumber,
      vehicles,
    } = req.body;

    if (!fullName || !email || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Full Name, Email, Phone number, and Password are required.',
      });
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanPhone = phone.trim();

    // Check existing
    const existing = await query(
      'SELECT id FROM users WHERE email = $1 OR phone = $2',
      [cleanEmail, cleanPhone]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email or phone number already exists.',
      });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Insert user with role 'admin'
    const result = await query(
      `INSERT INTO users (name, email, phone, password_hash, role, is_verified) 
       VALUES ($1, $2, $3, $4, 'admin', true) 
       RETURNING id, name, email, phone, role, is_verified, created_at`,
      [fullName, cleanEmail, cleanPhone, passwordHash]
    );

    const newOwner = result.rows[0];

    // Insert registered vehicles if provided
    if (Array.isArray(vehicles) && vehicles.length > 0) {
      for (const v of vehicles) {
        const plate = v.plateNumber || `MH-${Math.floor(10 + Math.random() * 89)}-${Math.floor(1000 + Math.random() * 8999)}`;
        const model = v.model || v.tireCount || 'Commercial Vehicle';
        const vType = ['motorcycle', 'van', 'box_truck', 'heavy_freight'].includes(v.type) ? v.type : 'van';
        try {
          await query(
            `INSERT INTO vehicles (owner_id, driver_id, type, plate_number, model, is_available) 
             VALUES ($1, NULL, $2, $3, $4, true) 
             ON CONFLICT (plate_number) DO NOTHING`,
            [newOwner.id, vType, plate, model]
          );
        } catch (_) {}
      }
    }

    const token = generateToken(newOwner);

    return res.status(201).json({
      success: true,
      message: 'Fleet Owner registered successfully.',
      user: {
        ...newOwner,
        companyName: companyName || fullName,
        gstNumber: gstNumber || '',
        govtIdType: govtIdType || 'Aadhaar',
        govtIdNumber: govtIdNumber || '',
        vehiclesCount: Array.isArray(vehicles) ? vehicles.length : 0,
      },
      token,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Login with role validation (Supports Email & Phone authentication)
 */
exports.login = async (req, res, next) => {
  try {
    const { email, phone, password, expectedRole } = req.body;

    if ((typeof email !== 'string' && typeof phone !== 'string') ||
        typeof password !== 'string' || password.length === 0) {
      return res.status(400).json({ success: false, message: 'Email or phone and password are required.' });
    }
    if (!email && !phone) {
      return res.status(400).json({ success: false, message: 'Email or phone number is required.' });
    }

    const cleanEmail = email ? email.toLowerCase().trim() : '';
    const cleanPhone = phone ? phone.trim() : '';

    const result = await query(
      `SELECT id, name, email, phone, password_hash, role, is_verified 
       FROM users 
       WHERE (email = $1 AND $1 != '') 
          OR (phone = $2 AND $2 != '')
          OR (REPLACE(phone, ' ', '') = REPLACE($2, ' ', '') AND $2 != '')
       LIMIT 1`,
      [cleanEmail, cleanPhone]
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

    if (password) {
      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        return res.status(401).json({ success: false, message: 'Invalid email or password.' });
      }
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
 * Send Dummy OTP for phone verification
 */
exports.sendOtp = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone || typeof phone !== 'string' || phone.trim().length < 8) {
      return res.status(400).json({ success: false, message: 'Valid mobile number is required.' });
    }

    const cleanPhone = phone.trim();
    const dummyOtp = '123456';

    console.log(`📱 [DUMMY OTP DISPATCH] Sent SMS verification OTP to ${cleanPhone}: ${dummyOtp}`);

    return res.json({
      success: true,
      message: `Verification code sent to ${cleanPhone}`,
      otp: dummyOtp,
      mockCode: dummyOtp,
      otpVerification: {
        required: true,
        mockCode: dummyOtp,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Verify Dummy OTP and authenticate / register user
 */
exports.verifyOtp = async (req, res, next) => {
  try {
    const { phone, otp, otpCode, name, email, role = 'driver' } = req.body;
    const submittedOtp = (otp || otpCode || '').toString().trim();

    if (!phone || phone.trim().length < 8) {
      return res.status(400).json({ success: false, message: 'Phone number is required.' });
    }

    const cleanPhone = phone.trim();
    const acceptedOtps = ['123456', '889900', '112233'];

    if (!acceptedOtps.includes(submittedOtp)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP code. Please enter dummy OTP: 123456',
      });
    }

    // Lookup user by phone
    let userResult = await query(
      `SELECT id, name, email, phone, role, is_verified, avatar_url, company_name, gstin 
       FROM users 
       WHERE phone = $1 
          OR REPLACE(phone, ' ', '') = REPLACE($1, ' ', '')
          OR REPLACE(REPLACE(phone, ' ', ''), '+91', '') = REPLACE(REPLACE($1, ' ', ''), '+91', '')
       LIMIT 1`,
      [cleanPhone]
    );

    let user;

    if (userResult.rows.length > 0) {
      user = userResult.rows[0];
      await query('UPDATE users SET is_verified = TRUE WHERE id = $1', [user.id]);
      user.is_verified = true;
    } else {
      const salt = await bcrypt.genSalt(10);
      const defaultPass = await bcrypt.hash('Driver@123456', salt);
      const assignedName = name || (role === 'driver' ? 'Driver Partner' : 'Shipper');
      const assignedEmail = email || `${role}.${cleanPhone.replace(/[^0-9]/g, '').slice(-8)}@hamhadrive.com`;

      const insertRes = await query(
        `INSERT INTO users (name, email, phone, password_hash, role, is_verified)
         VALUES ($1, $2, $3, $4, $5, TRUE)
         ON CONFLICT (email) DO UPDATE SET phone = EXCLUDED.phone, is_verified = TRUE
         RETURNING id, name, email, phone, role, is_verified, avatar_url, created_at`,
        [assignedName, assignedEmail.toLowerCase(), cleanPhone, defaultPass, role]
      );
      user = insertRes.rows[0];

      if (role === 'driver') {
        const plate = `MH-${Math.floor(10 + Math.random() * 89)}-AB-${Math.floor(1000 + Math.random() * 8999)}`;
        await query(
          `INSERT INTO vehicles (driver_id, plate_number, model, type, is_online, is_available)
           VALUES ($1, $2, 'Tata Ace Gold 1.5T', 'truck', TRUE, TRUE)
           ON CONFLICT (driver_id) DO NOTHING`,
          [user.id, plate]
        );
      }
    }

    let vehicle = null;
    if (user.role === 'driver') {
      const vRes = await query('SELECT * FROM vehicles WHERE driver_id = $1 LIMIT 1', [user.id]);
      if (vRes.rows.length > 0) vehicle = vRes.rows[0];
    }

    const token = generateToken(user);

    return res.json({
      success: true,
      message: 'OTP verified successfully.',
      user,
      vehicle,
      token,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update Current Authenticated Profile (with Avatar URL persistence)
 */
exports.updateProfile = async (req, res, next) => {
  try {
    const { name, phone, email, avatarUrl, avatar_url, companyName, company_name, gstin } = req.body;
    const userId = req.user.id;
    const finalAvatar = avatarUrl || avatar_url;

    const result = await query(
      `UPDATE users 
       SET name = COALESCE($1, name),
           phone = COALESCE($2, phone),
           email = COALESCE($3, email),
           avatar_url = COALESCE($4, avatar_url),
           company_name = COALESCE($5, company_name),
           gstin = COALESCE($6, gstin),
           updated_at = NOW()
       WHERE id = $7
       RETURNING id, name, email, phone, role, is_verified, avatar_url, company_name, gstin, created_at`,
      [name, phone, email?.toLowerCase(), finalAvatar, companyName || company_name, gstin, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    return res.json({
      success: true,
      message: 'Profile updated successfully.',
      user: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

exports.getMe = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT u.id, u.name, u.email, u.phone, u.role, u.is_verified, u.avatar_url, u.company_name, u.gstin, u.created_at,
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

