import 'package:dental_teeth_selector_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('dental_teeth_selector'), findsOneWidget);
  });
}
