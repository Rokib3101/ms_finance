import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ms_finance/main.dart';
import 'package:ms_finance/core/theme/theme_provider.dart';

void main() {
  testWidgets('MS Finance app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MSFinanceApp(),
      ),
    );

    // Verify that MS Finance title/app bar appears.
    expect(find.text('MS Finance'), findsWidgets);
  });
}
