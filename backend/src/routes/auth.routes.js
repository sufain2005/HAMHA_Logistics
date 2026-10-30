const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticateJWT } = require('../middleware/auth');

// Public Auth Endpoints
router.post('/register', authController.register);
router.post('/register-owner', authController.registerOwner);
router.post('/login', authController.login);
router.post('/verify-otp', authController.verifyOtp);

// Authenticated Self Profile
router.get('/me', authenticateJWT, authController.getMe);
router.patch('/profile', authenticateJWT, authController.updateProfile);

module.exports = router;

