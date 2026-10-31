const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticateJWT, requireRole } = require('../middleware/auth');

// Public Auth Endpoints
router.post('/register', authController.register);
router.post('/register-owner', authenticateJWT, requireRole('admin'), authController.registerOwner);
router.post('/login', authController.login);
router.post('/send-otp', authController.sendOtp);
router.post('/verify-otp', authController.verifyOtp);

// Authenticated Self Profile
router.get('/me', authenticateJWT, authController.getMe);
router.patch('/profile', authenticateJWT, authController.updateProfile);

module.exports = router;

