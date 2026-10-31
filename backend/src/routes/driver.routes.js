const express = require('express');
const router = express.Router();
const driverController = require('../controllers/driver.controller');
const { authenticateJWT, optionalAuthenticateJWT, requireRole } = require('../middleware/auth');

// Public/Demo accessible fleet owner contact info & state truck requirements search
router.get('/fleet-owner', optionalAuthenticateJWT, driverController.getFleetOwner);
router.get('/truck-requirements/search', optionalAuthenticateJWT, driverController.searchTruckRequirements);
router.post('/truck-requirements/:id/contact', optionalAuthenticateJWT, driverController.contactOwnerForRequirement);

// Active & Delivered Consignments (open to authenticated driver sessions)
router.get('/orders/current', optionalAuthenticateJWT, driverController.getCurrentOrder);
router.patch('/orders/:orderId/status', optionalAuthenticateJWT, driverController.updateOrderStatus);
router.put('/orders/:orderId/status', optionalAuthenticateJWT, driverController.updateOrderStatus);
router.get('/orders/delivered', optionalAuthenticateJWT, driverController.getDeliveredOrders);

// All operational driver endpoints strictly restricted to authenticated DRIVERS
router.use(authenticateJWT);
router.use(requireRole('driver'));

// Driver Onboarding & Vehicle setup
router.post('/vehicle', driverController.updateVehicle);
router.post('/toggle-online', driverController.toggleOnlineStatus);

// Order workflows
router.get('/orders/available', driverController.getAvailableOrders);
router.post('/orders/:orderId/accept', driverController.acceptOrder);

// Location ping fallback
router.post('/location', driverController.updateLocation);

module.exports = router;


