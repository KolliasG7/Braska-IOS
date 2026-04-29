import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:braska/main.dart';
import 'package:braska/providers/connection_provider.dart';

void main() {
  testWidgets('shows Strawberry Manager connect screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ConnectionProvider(),
        child: const StrawberryManagerApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Strawberry Manager'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
