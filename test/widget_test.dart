import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:net_track/main.dart';
import 'package:net_track/providers/data_provider.dart';
import 'package:net_track/providers/theme_provider.dart';

void main() {
  testWidgets('NetTrackApp smoke test', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    final dataProvider = DataProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: dataProvider),
        ],
        child: const NetTrackApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    dataProvider.dispose();
    themeProvider.dispose();
    await tester.pump(const Duration(seconds: 2));
  });
}
