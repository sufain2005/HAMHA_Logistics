const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customer.controller');
const { authenticateJWT, optionalAuthenticateJWT, requireRole } = require('../middleware/auth');

// Cost Calculator and Corridor Route Discovery (Open / Optional Auth for instant quoting)
router.get('/tariffs', customerController.getTariffs);
router.post('/calculate-quote', customerController.calculateQuote);
router.get('/owner-corridors', optionalAuthenticateJWT, customerController.getMatchingOwnerCorridors);

// All endpoints below strictly restricted to authenticated CUSTOMERS
router.use(authenticateJWT);
router.use(requireRole('customer'));

// Order creation and management
router.post('/orders', customerController.createOrder);
router.get('/orders', customerController.getMyOrders);
router.get('/orders/:id/track', customerController.getOrderTracking);
router.get('/orders/:id/invoice', customerController.getOrderInvoice);

module.exports = router;


