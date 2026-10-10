import 'package:flutter_test/flutter_test.dart';
import 'package:campus_circle/main.dart';

void main() {
  testWidgets('Home renders 活动报名 section', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusCircleApp());
    await tester.pump();
    expect(find.text('活动报名'), findsOneWidget);
  });
}
