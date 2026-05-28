import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartqueue_staff_app/main.dart';

void main() {
  testWidgets('shows login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SmartQueueStaffApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Sign in as staff or customer'), findsOneWidget);
  });
}
