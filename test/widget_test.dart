import 'package:flutter_test/flutter_test.dart';
import 'package:pilahnusa_mobile/main.dart';

void main() {
  testWidgets('PilahNusaApp loads and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const PilahNusaApp());
    expect(find.text('PilahNusa AI'), findsOneWidget);
  });
}
