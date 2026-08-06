import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:NetTrack/main.dart';
import 'package:NetTrack/providers/data_provider.dart';
import 'package:NetTrack/providers/theme_provider.dart';

void main() {
  testWidgets('NetTrackApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => DataProvider()),
        ],
        child: const NetTrackApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
