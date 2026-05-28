import 'package:flutter_test/flutter_test.dart';
import 'package:smartqueue_staff_app/main.dart';

void main() {
  testWidgets('shows login screen', (tester) async {
    await tester.pumpWidget(const SmartQueueStaffApp());
    expect(find.text('Staff Login'), findsOneWidget);
  });
}
