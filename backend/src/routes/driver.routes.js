const express = require('express');
const router = express.Router();
const driverController = require('../controllers/driver.controller');
const { authenticateJWT, requireRole } = require('../middleware/auth');

// All endpoints strictly restricted to authenticated DRIVERS
router.use(authenticateJWT);
router.use(requireRole('driver'));

// Driver Onboarding & Vehicle setup
router.post('/vehicle', driverController.updateVehicle);
router.post('/toggle-online', driverController.toggleOnlineStatus);

// Order workflows
router.get('/orders/available', driverController.getAvailableOrders);
router.get('/orders/current', driverController.getCurrentOrder);
router.post('/orders/:orderId/accept', driverController.acceptOrder);
router.patch('/orders/:orderId/status', driverController.updateOrderStatus);

// Location ping fallback
router.post('/location', driverController.updateLocation);

module.exports = router;

