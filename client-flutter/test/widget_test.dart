import 'package:flutter_test/flutter_test.dart';
import 'package:school_bus_client/main.dart';

void main() {
  testWidgets('BusCareParentApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BusCareParentApp());
    expect(find.byType(BusCareParentApp), findsOneWidget);
  });
}
