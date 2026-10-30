const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customer.controller');
const { authenticateJWT, requireRole } = require('../middleware/auth');

// All endpoints in this router are strictly restricted to authenticated CUSTOMERS
router.use(authenticateJWT);
router.use(requireRole('customer'));

// Cost Calculator for shipment creation
router.post('/calculate-quote', customerController.calculateQuote);

// Order creation and management
router.post('/orders', customerController.createOrder);
router.get('/orders', customerController.getMyOrders);
router.get('/orders/:id/track', customerController.getOrderTracking);
router.get('/orders/:id/invoice', customerController.getOrderInvoice);

module.exports = router;

