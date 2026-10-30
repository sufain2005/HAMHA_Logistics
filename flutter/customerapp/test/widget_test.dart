import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';
import 'package:customer_app/features/auth/widgets/hamha_logo.dart';

void main() {
  testWidgets('Customer app renders splash screen with HamhaLogo', (WidgetTester tester) async {
    await tester.pumpWidget(const HamhaCustomerApp());
    expect(find.byType(HamhaLogo), findsOneWidget);
    expect(find.text('FAST • SECURE • NATIONWIDE FREIGHT'), findsOneWidget);

    // Pump past splash timer so no timers are pending
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
