const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET || JWT_SECRET.length < 32) {
  throw new Error('JWT_SECRET must be configured with at least 32 characters.');
}

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

/**
 * Optional JWT Bearer token authentication - attaches decoded user if valid, continues if absent
 */
const optionalAuthenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      req.user = decoded;
    } catch (_) {
      req.user = null;
    }
  }
  next();
};

module.exports = {
  authenticateJWT,
  optionalAuthenticateJWT,
  requireRole,
  JWT_SECRET,
};

