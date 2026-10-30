const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticateJWT, requireRole } = require('../middleware/auth');

// All endpoints in this router are strictly restricted to authenticated OWNER/ADMIN
router.use(authenticateJWT);
router.use(requireRole('admin'));

// Live Fleet overview for Owner Mapbox screen
router.get('/fleet', adminController.getLiveFleet);

// Dispatch Management
router.get('/orders', adminController.getAllOrders);
router.post('/orders/dispatch', adminController.manualDispatch);

// Analytics
router.get('/analytics', adminController.getAnalytics);

module.exports = router;

