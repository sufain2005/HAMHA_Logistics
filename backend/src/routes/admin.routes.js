const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticateJWT, optionalAuthenticateJWT, requireRole } = require('../middleware/auth');

// Owner Truck Search / 3-Day Load Board Postings (Open to authenticated & authorized owner sessions)
router.post('/truck-requirements', optionalAuthenticateJWT, adminController.postTruckRequirement);
router.get('/truck-requirements', optionalAuthenticateJWT, adminController.getOwnerTruckRequirements);
router.put('/truck-requirements/:id', optionalAuthenticateJWT, adminController.updateTruckRequirement);
router.delete('/truck-requirements/:id', optionalAuthenticateJWT, adminController.deleteTruckRequirement);

// Dispatch Management & Direct Driver Requests (Open to authorized owner sessions)
router.get('/orders', optionalAuthenticateJWT, adminController.getAllOrders);
router.post('/orders/dispatch', optionalAuthenticateJWT, adminController.manualDispatch);
router.post('/orders/request-long-delivery', optionalAuthenticateJWT, adminController.requestLongDelivery);
router.get('/drivers/list', optionalAuthenticateJWT, adminController.getDriversList);

// All operational management endpoints below require strict admin role authentication
router.use(authenticateJWT);
router.use(requireRole('admin'));

// Live Fleet overview for Owner Mapbox screen
router.get('/fleet', adminController.getLiveFleet);
router.get('/drivers/nearby', adminController.getNearbyDrivers);

// Onboarding Approvals (KYC & Documents)
router.get('/drivers/approvals', adminController.getDriverApprovals);
router.post('/drivers/:driverId/approve', adminController.approveDriver);
router.post('/drivers/:driverId/reject', adminController.rejectDriver);

// Financial Transactions & Invoices (Phase 4)
router.get('/transactions', adminController.getTransactions);

// Tariffs & Dynamic Pricing Configuration (Admin Cost Engine)
router.get('/tariffs', adminController.getTariffs);
router.post('/tariffs', adminController.updateTariffs);
router.put('/tariffs', adminController.updateTariffs);

// Dispute & Audit Hub (Phase 4)
router.get('/disputes', adminController.getDisputes);
router.post('/disputes/:id/resolve', adminController.resolveDispute);
router.get('/audit-logs', adminController.getAuditLogs);

// Analytics
router.get('/analytics', adminController.getAnalytics);

module.exports = router;

