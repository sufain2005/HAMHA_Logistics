import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/main.dart';
import 'package:admin_dashboard/core/auth/admin_rbac.dart';
import 'package:admin_dashboard/features/auth/widgets/admin_hamha_logo.dart';
import 'package:admin_dashboard/features/dashboard/screens/admin_dashboard_shell.dart';
import 'package:admin_dashboard/features/fleet/widgets/floating_telemetry_card.dart';
import 'package:admin_dashboard/features/fleet/widgets/fleet_map_controls.dart';
import 'package:admin_dashboard/features/dispatch/screens/dispatch_matrix_screen.dart';
import 'package:admin_dashboard/features/approvals/screens/driver_approvals_screen.dart';
import 'package:admin_dashboard/features/finance/screens/financial_ledgers_screen.dart';
import 'package:admin_dashboard/features/disputes/screens/dispute_audit_hub_screen.dart';

void main() {
  testWidgets('Owner Panel Login Screen renders AdminHamhaLogo, Owner Sign In, Real OTP, and Registration toggle', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HamhaAdminApp());
    expect(find.byType(AdminHamhaLogo), findsOneWidget);
    expect(find.text('Owner Panel Sign In'), findsOneWidget);
    expect(find.text('OWNER EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('TWO-FACTOR OTP VERIFICATION'), findsOneWidget);
    expect(find.text('SIGN IN AS OWNER'), findsOneWidget);
    expect(find.textContaining('Have you registered as Owner? Register Here'), findsOneWidget);
  });

  testWidgets('Owner Registration Screen renders Full Name, Govt ID, GST Number, and Multi-Vehicle Fleet with Tire options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HamhaAdminApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Tap the registration toggle button at bottom
    final regBtn = find.textContaining('Have you registered as Owner? Register Here');
    expect(regBtn, findsOneWidget);
    await tester.ensureVisible(regBtn);
    await tester.tap(regBtn);
    await tester.pumpAndSettle();

    // Verify Owner Registration Form elements
    expect(find.text('Fleet Owner Registration'), findsOneWidget);
    expect(find.text('1. OWNER & STATUTORY IDENTIFICATION'), findsOneWidget);
    expect(find.text('FULL NAME (AS PER GOVT ID)'), findsOneWidget);
    expect(find.text('GOVT ID TYPE'), findsOneWidget);
    expect(find.text('GST NUMBER (GSTIN)'), findsOneWidget);

    // Multi-vehicle section
    expect(find.textContaining('2. FLEET VEHICLES DIRECTORY'), findsOneWidget);
    expect(find.text('ADD VEHICLE'), findsOneWidget);
    expect(find.text('Bike (2W)'), findsWidgets);
    expect(find.text('Mini Van'), findsWidgets);
    expect(find.text('Van'), findsWidgets);
    expect(find.text('Truck'), findsWidgets);
    expect(find.text('Other'), findsWidgets);

    // Tap "Other" to test tire selector
    final otherChip = find.text('Other').first;
    await tester.ensureVisible(otherChip);
    await tester.tap(otherChip);
    await tester.pumpAndSettle();

    expect(find.text('SPECIFY COMMERCIAL AXLE / TIRE CLASSIFICATION:'), findsOneWidget);
    expect(find.text('4 Tire'), findsWidgets);
    expect(find.text('6 Tire'), findsWidgets);
    expect(find.text('8 Tire'), findsWidgets);
    expect(find.text('12 Tire'), findsWidgets);

    // Document photo attachment & OTP
    expect(find.textContaining('RC & LICENSE PHOTO ATTACHED'), findsOneWidget);
    expect(find.text('COMPLETE OWNER REGISTRATION & ENTER OWNER PANEL'), findsOneWidget);
  });

  testWidgets('Admin Dashboard Shell renders Persistent Sidebar, Top Metrics, and Split-View Roster', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockAdmin = AdminUserModel(
      id: 'adm-test-01',
      name: 'Operations Commander',
      email: 'admin@hamha.com',
      role: 'admin',
      scope: AdminScope.fullAdmin,
      token: 'mock-token',
      lastLogin: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardShell(admin: mockAdmin, enableLiveSocket: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Sidebar items
    expect(find.text('Fleet Control Tower'), findsOneWidget);
    expect(find.text('Dispatch Matrix'), findsOneWidget);
    expect(find.text('Onboarding Approvals'), findsOneWidget);
    expect(find.text('OWNER'), findsOneWidget);

    // Top Metrics
    expect(find.text('NEON POSTGIS • SOCKET.IO V4 LIVE'), findsOneWidget);
    expect(find.text('18 / 24'), findsOneWidget);
    expect(find.text('7 In Transit'), findsOneWidget);

    // Split-view Roster
    expect(find.text('Active Fleet Roster'), findsOneWidget);
    expect(find.text('Rajesh Sharma'), findsNWidgets(2));
    expect(find.text('Amit Patel'), findsOneWidget);
  });

  testWidgets('Phase 2: Floating Telemetry Card displays live speed, battery, and dispatch controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockAdmin = AdminUserModel(
      id: 'adm-test-01',
      name: 'Operations Commander',
      email: 'admin@hamha.com',
      role: 'admin',
      scope: AdminScope.fullAdmin,
      token: 'mock-token',
      lastLogin: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardShell(admin: mockAdmin, enableLiveSocket: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Floating Telemetry Card should be present for selected driver
    expect(find.byType(FloatingTelemetryCard), findsOneWidget);
    expect(find.text('LIVE SPEED'), findsOneWidget);
    expect(find.text('DEVICE BATTERY'), findsOneWidget);
    expect(find.text('SHIFT DURATION'), findsOneWidget);
    expect(find.text('Center'), findsOneWidget);
    expect(find.text('Dispatch'), findsOneWidget);

    // Fleet Map Controls should be visible
    expect(find.byType(FleetMapControls), findsOneWidget);
    expect(find.byIcon(Icons.fence), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FleetMapControls),
        matching: find.byIcon(Icons.alt_route),
      ),
      findsOneWidget,
    );

    // Filter test: tap "Available" filter
    final availableTab = find.text('Available');
    expect(availableTab, findsOneWidget);
    await tester.tap(availableTab);
    await tester.pump(const Duration(milliseconds: 100));

    // Amit Patel is available, Rajesh Sharma is on-trip
    expect(find.text('Amit Patel'), findsOneWidget);
  });

  testWidgets('Phase 3: Active Dispatch Matrix renders data table, search, and PostGIS radius override modal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockAdmin = AdminUserModel(
      id: 'adm-test-01',
      name: 'Operations Commander',
      email: 'admin@hamha.com',
      role: 'admin',
      scope: AdminScope.fullAdmin,
      token: 'mock-token',
      lastLogin: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardShell(admin: mockAdmin, enableLiveSocket: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Navigate to Dispatch Matrix tab in sidebar
    final dispatchNav = find.text('Dispatch Matrix');
    expect(dispatchNav, findsOneWidget);
    await tester.tap(dispatchNav);
    await tester.pumpAndSettle();

    // Verify Dispatch Matrix elements
    expect(find.byType(DispatchMatrixScreen), findsOneWidget);
    expect(find.text('Active Dispatch Matrix'), findsOneWidget);
    expect(find.text('CONSIGNMENT CODE'), findsOneWidget);
    expect(find.text('TARIFF (INR)'), findsOneWidget);
    expect(find.text('#HMH-89241'), findsOneWidget);
    expect(find.text('#HMH-31045'), findsOneWidget);

    // Tap "Dispatch" on pending consignment HMH-31045
    final dispatchButtons = find.widgetWithText(ElevatedButton, 'Dispatch');
    expect(dispatchButtons, findsWidgets);
    await tester.ensureVisible(dispatchButtons.first);
    await tester.tap(dispatchButtons.first);
    await tester.pumpAndSettle();

    // Verify PostGIS Proximity Dispatch Matrix modal
    expect(find.text('PostGIS Proximity Dispatch Matrix'), findsOneWidget);
    expect(find.text('NEON POSTGIS RADIUS:'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('10 km'), findsOneWidget);
    expect(find.text('20 km'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'FORCE ASSIGN'), findsWidgets);
  });

  testWidgets('Phase 3: Onboarding Approvals renders applications, document inspector modal, and KYC checklist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockAdmin = AdminUserModel(
      id: 'adm-test-01',
      name: 'Operations Commander',
      email: 'admin@hamha.com',
      role: 'admin',
      scope: AdminScope.fullAdmin,
      token: 'mock-token',
      lastLogin: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardShell(admin: mockAdmin, enableLiveSocket: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Navigate to Onboarding Approvals tab in sidebar
    final approvalsNav = find.text('Onboarding Approvals');
    expect(approvalsNav, findsOneWidget);
    await tester.tap(approvalsNav);
    await tester.pumpAndSettle();

    // Verify Onboarding Approvals elements
    expect(find.byType(DriverApprovalsScreen), findsOneWidget);
    expect(find.text('Carrier Onboarding Approval Desk'), findsOneWidget);
    expect(find.text('Sachin Tendulkar Rao'), findsOneWidget);
    expect(find.text('PENDING REVIEW'), findsWidgets);
    expect(find.widgetWithText(ElevatedButton, 'Approve'), findsWidgets);
    expect(find.widgetWithText(ElevatedButton, 'Reject'), findsWidgets);

    // Tap "Inspect Docs"
    final inspectBtn = find.widgetWithText(OutlinedButton, 'Inspect Docs').first;
    await tester.tap(inspectBtn);
    await tester.pumpAndSettle();

    // Verify Document Modal Viewer
    expect(find.textContaining('KYC Document Verification'), findsOneWidget);
    expect(find.text('1. Driver License (CDL)'), findsOneWidget);
    expect(find.text('2. Registration (RC)'), findsOneWidget);
    expect(find.text('3. Insurance Policy'), findsOneWidget);
    expect(find.text('STATUTORY COMPLIANCE AUDIT'), findsOneWidget);
    expect(find.text('APPROVE'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);
  });

  testWidgets('Phase 4: Financial Ledgers renders metrics, transaction table, and PDF Invoice generator', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockAdmin = AdminUserModel(
      id: 'adm-test-01',
      name: 'Operations Commander',
      email: 'admin@hamha.com',
      role: 'admin',
      scope: AdminScope.fullAdmin,
      token: 'mock-token',
      lastLogin: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardShell(admin: mockAdmin, enableLiveSocket: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Navigate to Financial Ledgers in sidebar
    final financeNav = find.text('Financial Ledgers');
    expect(financeNav, findsOneWidget);
    await tester.tap(financeNav);
    await tester.pumpAndSettle();

    // Verify Financial Ledger screen elements
    expect(find.byType(FinancialLedgersScreen), findsOneWidget);
    expect(find.text('Financial Transactions & Invoices Ledger'), findsOneWidget);
    expect(find.text('GROSS FREIGHT REVENUE'), findsOneWidget);
    expect(find.text('PLATFORM COMMISSION (15%)'), findsOneWidget);
    expect(find.text('CARRIER PAYOUTS (85%)'), findsOneWidget);
    expect(find.text('INV-HMH-89241'), findsOneWidget);

    // Tap "Download Invoice"
    final invoiceButtons = find.widgetWithText(ElevatedButton, 'Download Invoice');
    expect(invoiceButtons, findsWidgets);
    await tester.ensureVisible(invoiceButtons.first);
    await tester.tap(invoiceButtons.first);
    await tester.pumpAndSettle();

    // Verify PDF Invoice Generator modal
    expect(find.text('HAMHA LOGISTICS INDIA PVT LTD'), findsOneWidget);
    expect(find.textContaining('GSTIN: 27AAACH2024H1Z4'), findsOneWidget);
    expect(find.textContaining('TAX INVOICE: INV-HMH-89241'), findsOneWidget);
    expect(find.text('PRINT / SAVE PDF INVOICE'), findsOneWidget);
  });

  testWidgets('Phase 4: Dispute & Audit Hub renders customer disputes, refunds, and system event logs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockAdmin = AdminUserModel(
      id: 'adm-test-01',
      name: 'Operations Commander',
      email: 'admin@hamha.com',
      role: 'admin',
      scope: AdminScope.fullAdmin,
      token: 'mock-token',
      lastLogin: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardShell(admin: mockAdmin, enableLiveSocket: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Navigate to Dispute & Audit Hub in sidebar
    final disputeNav = find.text('Dispute & Audit Hub');
    expect(disputeNav, findsOneWidget);
    await tester.tap(disputeNav);
    await tester.pumpAndSettle();

    // Verify Dispute Hub elements
    expect(find.byType(DisputeAuditHubScreen), findsOneWidget);
    expect(find.text('Dispute & System Audit Hub'), findsOneWidget);
    expect(find.text('Customer Disputes'), findsOneWidget);
    expect(find.text('System Audit Logs'), findsOneWidget);

    // Verify active dispute
    expect(find.textContaining('DISPUTE #DSP-801'), findsOneWidget);
    expect(find.text('CUSTOMER COMPLAINT'), findsWidgets);
    expect(find.widgetWithText(ElevatedButton, 'Issue Refund'), findsWidgets);

    // Switch to System Audit Logs tab
    final auditTab = find.text('System Audit Logs');
    await tester.tap(auditTab);
    await tester.pumpAndSettle();

    // Verify audit logs table
    expect(find.text('TIMESTAMP & ID'), findsOneWidget);
    expect(find.text('ACTION EVENT'), findsOneWidget);
    expect(find.text('SHA256 AUDIT SEAL'), findsOneWidget);
    expect(find.text('AUD-901'), findsOneWidget);
    expect(find.text('MANUAL_DISPATCH_OVERRIDE'), findsOneWidget);
  });
}
