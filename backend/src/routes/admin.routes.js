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

// Owner Truck Search / 3-Day Load Board Postings
router.post('/truck-requirements', adminController.postTruckRequirement);
router.get('/truck-requirements', adminController.getOwnerTruckRequirements);
router.delete('/truck-requirements/:id', adminController.deleteTruckRequirement);

module.exports = router;

