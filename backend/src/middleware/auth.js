const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'hamha_super_secret_jwt_key_2026_crimson_shield';

/**
 * Validates the JWT Bearer token and attaches decoded user to req.user
 */
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Access Denied: Missing or malformed Authorization header.',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // { id, role, email, name, phone }
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token.',
    });
  }
};

/**
 * Restricts access to one or more designated roles
 * @param {Array<string>|string} allowedRoles - 'customer', 'driver', or 'admin'
 */
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Authentication required.',
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Forbidden: This endpoint is restricted to [${allowedRoles.join(', ')}]. Current role is '${req.user.role}'.`,
      });
    }

    next();
  };
};

module.exports = {
  authenticateJWT,
  requireRole,
  JWT_SECRET,
};

