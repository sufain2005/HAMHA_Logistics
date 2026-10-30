import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driverapp/main.dart';
import 'package:driverapp/features/auth/widgets/driver_hamha_logo.dart';
import 'package:driverapp/features/dashboard/screens/driver_main_shell.dart';
import 'package:driverapp/core/models/dispatch_offer_model.dart';
import 'package:driverapp/features/dispatch/widgets/dispatch_offer_modal.dart';
import 'package:driverapp/features/completion/screens/driver_pod_screen.dart';
import 'package:driverapp/features/completion/screens/driver_trip_success_screen.dart';

void main() {
  testWidgets('Driver app renders Welcome Screen with DriverHamhaLogo, CTA and Apply link', (WidgetTester tester) async {
    await tester.pumpWidget(const HamhaDriverApp());
    expect(find.byType(DriverHamhaLogo), findsOneWidget);
    expect(find.text('DRIVER & CARRIER FLEET'), findsOneWidget);
    expect(find.text('CONTINUE WITH PHONE'), findsOneWidget);
    expect(find.text('Apply & Register'), findsOneWidget);
  });

  testWidgets('Driver Main Shell renders 3 bottom tabs: Home, Live Tracking, Profile', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DriverMainShell(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify 3 bottom tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Live Tracking'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify Home Screen elements
    expect(find.text("Today's Shift Earnings"), findsOneWidget);
    expect(find.text('Completed Shipments'), findsOneWidget);
    expect(find.text('HMH-31045'), findsOneWidget);

    // Switch to Live Tracking Tab
    await tester.tap(find.text('Live Tracking'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('LIVE FLEET TELEMATICS'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);

    // Switch to Profile Tab
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Driver Profile & Fleet Hub'), findsOneWidget);
    expect(find.text('ASSIGNED VEHICLE & TELEMATICS'), findsOneWidget);
    expect(find.text('STATUTORY COMPLIANCE & LICENSES'), findsOneWidget);
  });

  testWidgets('Dispatch Offer Modal displays siren alert, countdown, payout and action buttons', (WidgetTester tester) async {
    final offer = DispatchOfferModel.sampleBhiwandiMumbaiOffer();
    bool accepted = false;
    bool declined = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DispatchOfferModal(
            offer: offer,
            onAccept: (_) => accepted = true,
            onDecline: () => declined = true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('INCOMING DISPATCH OFFER'), findsOneWidget);
    expect(find.text('HMH-89241'), findsOneWidget);
    expect(find.text('₹1850'), findsOneWidget);
    expect(find.text('15s'), findsOneWidget);
    expect(find.text('PASS / DECLINE'), findsOneWidget);
    expect(find.text('ACCEPT (₹1850)'), findsOneWidget);

    await tester.tap(find.text('ACCEPT (₹1850)'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(accepted, isTrue);
  });

  testWidgets('Phase 5 Proof of Delivery screen renders camera capture & swipe slider', (WidgetTester tester) async {
    final offer = DispatchOfferModel.sampleBhiwandiMumbaiOffer();

    await tester.pumpWidget(
      MaterialApp(
        home: DriverPodScreen(offer: offer),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Proof of Delivery (POD)'), findsOneWidget);
    expect(find.text('HMH-89241'), findsOneWidget);
    expect(find.text('PACKAGE PHOTO EVIDENCE'), findsOneWidget);
    expect(find.text('OPEN CAMERA'), findsOneWidget);
    expect(find.text('RECEIVING PERSON NAME / DESK'), findsOneWidget);
    expect(find.text('SWIPE TO COMPLETE DELIVERY'), findsOneWidget);
  });

  testWidgets('Phase 5 Success Screen renders checkmark, net payout and return button', (WidgetTester tester) async {
    final offer = DispatchOfferModel.sampleBhiwandiMumbaiOffer();

    await tester.pumpWidget(
      MaterialApp(
        home: DriverTripSuccessScreen(offer: offer),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Delivery Complete!'), findsOneWidget);
    expect(find.text('TOTAL FARE CREDITED TO DRIVER WALLET'), findsOneWidget);
    expect(find.text('₹2000.00'), findsOneWidget);
    expect(find.text('RETURN TO DRIVER DASHBOARD'), findsOneWidget);
  });
}
