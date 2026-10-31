const express = require('express');
const router = express.Router();
const driverController = require('../controllers/driver.controller');
const { authenticateJWT, optionalAuthenticateJWT, requireRole } = require('../middleware/auth');

// Search for Work in State & Contact Owner (3-Day Load Board) - accessible for state querying
router.get('/truck-requirements/search', optionalAuthenticateJWT, driverController.searchTruckRequirements);
router.post('/truck-requirements/:id/contact', optionalAuthenticateJWT, driverController.contactOwnerForRequirement);

// All operational driver endpoints strictly restricted to authenticated DRIVERS
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

// Delivered Shipments History (Strictly Delivered Only)
router.get('/orders/delivered', driverController.getDeliveredOrders);

module.exports = router;


